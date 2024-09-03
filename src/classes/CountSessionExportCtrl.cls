global without sharing class CountSessionExportCtrl {
	
	public static Integer QUERY_LIMIT_RECORDS = 2000;
	public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}

    public CountSessionExportCtrl() { 
		Application = GlobalController.GetResourceURL('Application');
    	Application_Images = GlobalController.GetResourceURL('Application_Images');
		Assests = GlobalController.GetResourceURL('Assests');
	}

	@RemoteAction
	global static String getCountSessionReportData(String countSessionId, String tabName, String uniqueFieldLastValue) {
		countSessionId = BPUtility.getDecodedString(countSessionId);
		tabName = BPUtility.getDecodedString(tabName);
		uniqueFieldLastValue = BPUtility.getDecodedString(uniqueFieldLastValue);
		
		List<Count_Session__c> countSessionRecList = PartCountSOQLUtil.getCountSessionDetailByFieldFilter(new Map<String, String>{'Id' => countSessionId});
    	if(countSessionRecList.size() > 0) {
			Map<String, String> fieldNameToValueMap = PartCountService.getFilterFieldsMap(countSessionId, tabName);
			List<Count_Session_Line_Item__c> countSessionLIRecList = getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, uniqueFieldLastValue);
			List<CountSessionLineItem> countSessionInfoList = getCountSessionInfoList(countSessionRecList[0], tabName);
			String lastRecordUniqueFieldValue = '';
			if(countSessionLIRecList.size() > 0) {
				lastRecordUniqueFieldValue = String.valueOf(countSessionLIRecList[countSessionLIRecList.size() - 1].Name);
			}
			return BPUtility.getEncodedString(System.JSON.serialize(new CountSessionReportWrapper(countSessionInfoList, lastRecordUniqueFieldValue, countSessionLIRecList, countSessionLIRecList.size() < QUERY_LIMIT_RECORDS), true));
		}
		return BPUtility.getEncodedString('Error');    	
    }

    private static List<CountSessionLineItem> getCountSessionInfoList(Count_Session__c countSessionRec, String lineItemTabName) {
		List<CountSessionLineItem> countSessionInfoList = new List<CountSessionLineItem>();
		countSessionRec.Name__c =  countSessionRec.Name__c != null ? countSessionRec.Name__c.escapeCsv() : '';
		String countDateStr = (countSessionRec.Count_Date__c != null) ? BPUtility.getFormatedDateTime(countSessionRec.Count_Date__c) : '';
		CountSessionLineItem csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Count session:';
		csObj.Description = countSessionRec.Name__c;
		countSessionInfoList.add(csObj);
		
		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Count ID#:';
		csObj.Description = countSessionRec.Name;
		countSessionInfoList.add(csObj);

		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Count date:';
		csObj.Description = countDateStr;
		countSessionInfoList.add(csObj);

		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Count type:';
		csObj.Description = countSessionRec.Type__c;
		countSessionInfoList.add(csObj);

		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Listing:';
		csObj.Description = lineItemTabName;
		countSessionInfoList.add(csObj);

		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Printed:';
		csObj.Description = BPUtility.getFormatedDateTime(Date.today());
		countSessionInfoList.add(csObj);

		csObj = new CountSessionLineItem();
		csObj.PartNumber = 'Total Adjustment:';
		csObj.Description = String.valueOf(countSessionRec.Total_Adjusted_Cost__c);
		countSessionInfoList.add(csObj);

		return countSessionInfoList;
    }
    
    private static List<Count_Session_Line_Item__c> getCountSessionLineItemsByFieldFilter(Map<String, String> fieldNameToValueMap, String uniqueFieldLastValue) {
    	String query;
        query = 'SELECT ';
        for(String fieldName : CountSessionLineItemWrapper.fieldsList()) {
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Count_Session_Line_Item__c ';
        String whereClause = PartCountSOQLUtil.getCountSessionLineItemWhereClause(fieldNameToValueMap);			//where Clause
        query += whereClause;
        if(uniqueFieldLastValue != null) {
            query += ' AND Name >\'' + uniqueFieldLastValue + '\'';
        } 
        query += ' Order By Name Asc ';
        query += ' LIMIT ' + QUERY_LIMIT_RECORDS;
        
        if(AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Count_Session_Line_Item__c> countSessionLineItemRecList = Database.query(query);
        return countSessionLineItemRecList;
    }
    
						
	public class CountSessionReportWrapper {
		public List<CountSessionLineItem> CountSessionInfo;
		public List<CountSessionLineItem> CountSessionLineItems;
		public String UniqueFieldLastValue;
		public Boolean IsProcessComplete;

		public CountSessionReportWrapper(List<CountSessionLineItem> countSessionInfoList, String uniqueFieldLastValue, List<Count_Session_Line_Item__c> countSessionLineItemRecList, Boolean isProcessComplete) {
			this.CountSessionInfo = countSessionInfoList;
			this.IsProcessComplete = isProcessComplete;
				
			this.UniqueFieldLastValue = uniqueFieldLastValue;
			this.CountSessionLineItems = new List<CountSessionLineItem>();
			for(Count_Session_Line_Item__c countSessionLIRec : countSessionLineItemRecList) {
				this.CountSessionLineItems.add(new CountSessionLineItem(countSessionLIRec));
			}
		}
	}

	public class CountSessionLineItem {
    	public String PartNumber;
	    public String Description;
	    public String VendorName;
	    public String Locations;
	    public Decimal QtyAvailable;
	    public Decimal CountedQty;
	    public Decimal Variance;
	    public Decimal Cost;
	    public Decimal NetAdjustment;
		public String IssueDescription;
		public Decimal TotalVariance;
	    public Decimal TotalCost;

		public CountSessionLineItem(){}
	    
	    public CountSessionLineItem(Count_Session_Line_Item__c countSessionLineItemRec) {
	    	
	    	this.PartNumber = countSessionLineItemRec.Part_Number_Formula__c != null ? countSessionLineItemRec.Part_Number_Formula__c : '';
	    	
	    	if(countSessionLineItemRec.Part__c != null) {
		    	this.Description = countSessionLineItemRec.Part__r.Description__c;
		    	this.VendorName = countSessionLineItemRec.Part__r.Vendor__r.Name;
	    	} else {
				this.Description = '';
		    	this.VendorName = '';
			}
	    	
	    	this.QtyAvailable = countSessionLineItemRec.Qty_Available__c != null ? countSessionLineItemRec.Qty_Available__c : 0;
	    	List<String> locationList = (LocationManagementService.getLocationsList(countSessionLineItemRec));
	    	this.Locations = ((locationList != null && locationList.size() > 0) ? String.join(locationList, ',') : '');
	    	this.CountedQty = countSessionLineItemRec.Counted_Qty__c != null ? countSessionLineItemRec.Counted_Qty__c : 0;
	    	this.Variance = countSessionLineItemRec.Variance__c;
	    	this.Cost = (countSessionLineItemRec.Cost__c != null) ? countSessionLineItemRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
	    	if(countSessionLineItemRec.Count_Session__r.Status__c != null && countSessionLineItemRec.Count_Session__r.Status__c.equalsIgnoreCase('Closed')) {
        		this.NetAdjustment = countSessionLineItemRec.Total_Cost_Adjustment__c != null ? 
        						countSessionLineItemRec.Total_Cost_Adjustment__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	} else {
        		this.NetAdjustment = countSessionLineItemRec.Net_Adjustment__c != null ? 
        						countSessionLineItemRec.Net_Adjustment__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	}
			if(countSessionLineItemRec.Issue_Indicator__c != null && PartCountService.issueIndicatorToIssueDescriptionMap.containsKey(countSessionLineItemRec.Issue_Indicator__c)) {
				this.IssueDescription = PartCountService.issueIndicatorToIssueDescriptionMap.get(countSessionLineItemRec.Issue_Indicator__c);
			} else {
				this.IssueDescription = '';
			}
			this.TotalVariance = this.Variance * this.Cost;
			this.TotalCost = this.QtyAvailable * this.Cost;
		}
	}	
}
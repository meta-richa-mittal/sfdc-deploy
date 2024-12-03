/**
 * Author: Nidhi Sharma
 * Since: August 28, 2019
 * Name: CountSessionWrapper
 * Description: 
**/
public without sharing class CountSessionWrapper {
	public String Id;
    public String CountSessionNumber;
    public String Name;
    public String Type;
    public String CountDate;
    public String CreatedOn;
    public String Modified;
    public Decimal Count;
    public Decimal CostAdjustment;
    public String AdjustmentCategoryId;
    public Boolean IsAdjustUncountedPartsToZeroQty;
    
    public String Status;
    public Decimal TotalCountedParts;
    public Decimal TotalUncountedParts;
    public Decimal TotalAdjustedParts;
    public Decimal IssuesToResolve;
	
    public List<String> SelectedVendorIds;
	public List<String> SelectedCategoryIds;
	public List<String> SelectedLocationNames;
	public List<String> SelectedVendorNames;
	public List<String> SelectedCategoryNames;
    
    public CountSessionWrapper(){}
    
    public CountSessionWrapper(Count_Session__c countSessionRec, Boolean isLandingPage) {
    	this.Id = countSessionRec.Id;
    	this.CountSessionNumber = countSessionRec.Name;
    	this.Name = countSessionRec.Name__c;
    	this.Type = countSessionRec.Type__c;
    	this.CountDate = (countSessionRec.Count_Date_Time__c != null) ? 
    						BPUtility.getFormatedDateTime(datetime.newInstance(countSessionRec.Count_Date_Time__c.year(), countSessionRec.Count_Date_Time__c.month(), 
    						countSessionRec.Count_Date_Time__c.day())) : '';
                            
    	this.CreatedOn = BPUtility.getFormatedDateTime(datetime.newInstance(countSessionRec.CreatedDate.year(), countSessionRec.CreatedDate.month(), 
    														countSessionRec.CreatedDate.day()));
		
		String modifiedDate;
		if(countSessionRec.Status__c == 'Closed' && countSessionRec.Finalized_Date__c != null) {
			modifiedDate = BPUtility.getFormatedDateTime(datetime.newInstance(countSessionRec.Finalized_Date__c.year(), countSessionRec.Finalized_Date__c.month(), countSessionRec.Finalized_Date__c.day()));
		} else {
			DateTime lastModifDate = BPUtility.getLastModifiedDate(countSessionRec);
			modifiedDate = BPUtility.getFormatedDateTime(datetime.newInstance(lastModifDate.year(), lastModifDate.month(), lastModifDate.day()));
		}	
		
		String userNameWhoFinalizedOrModified = (countSessionRec.Status__c == 'Closed' && String.isNotBlank(countSessionRec.Finalized_By__r.Name)) ? 
											countSessionRec.Finalized_By__r.Name : BPUtility.getLastModifiedBy(countSessionRec);
    	this.Modified = 'By ' + userNameWhoFinalizedOrModified + ' on ' + modifiedDate + ' ' + countSessionRec.LastModifiedDate.format('hh:mma');
    	this.Count = countSessionRec.Counted__c;
    	if(countSessionRec.Status__c.equalsIgnoreCase('Closed')) {
    		this.CostAdjustment = countSessionRec.Net_Adjustment_After_Finalize__c != null ? 
    															countSessionRec.Net_Adjustment_After_Finalize__c.setScale(2, RoundingMode.HALF_UP) : 0;
    	} else {
			this.CostAdjustment = countSessionRec.Total_Adjusted_Cost__c != null ? 
																countSessionRec.Total_Adjusted_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
    	}
    	this.Status = countSessionRec.Status__c;

    	if(isLandingPage) {
    		
    		if(countSessionRec.Type__c.toUpperCase() == 'RANDOM COUNT') {
    			this.SelectedLocationNames = new List<String>{'N/A'};
		    	this.SelectedVendorNames = new List<String>{'N/A'};
				this.SelectedCategoryNames = new List<String>{'N/A'};
				
    		} else if(countSessionRec.Type__c.toUpperCase() == 'CYCLE COUNT') {
	    		List<String> ids = TagUtil.convertStringIntoList((SObject)countSessionRec, 'Vendors__c');
	    		this.SelectedVendorNames = getNamesByIds(ids, 'Vendor');
	    		this.SelectedVendorNames = (this.SelectedVendorNames != null && this.SelectedVendorNames.size() > 0) ? this.SelectedVendorNames : new List<String>{'All'};
	    		ids.clear();

	    		ids = TagUtil.convertStringIntoList((SObject)countSessionRec, 'Categories__c');
	    		this.SelectedCategoryNames = getNamesByIds(ids, 'Category');
	    		this.SelectedCategoryNames = (this.SelectedCategoryNames != null && this.SelectedCategoryNames.size() > 0) ? this.SelectedCategoryNames : new List<String>{'All'};
	    		
	    		this.SelectedLocationNames = LocationManagementService.getLocationsList(countSessionRec);
				this.SelectedLocationNames = (this.SelectedLocationNames != null && this.SelectedLocationNames.size() > 0) ? this.SelectedLocationNames : new List<String>{'All'};
    		
    		} else if(countSessionRec.Type__c.toUpperCase() == 'FULL INVENTORY') {
    			this.SelectedLocationNames = new List<String>{'All'};
		    	this.SelectedVendorNames = new List<String>{'All'};
				this.SelectedCategoryNames = new List<String>{'All'};
    		}
    	}
    }
    
    private static List<String> getNamesByIds(List<String> idList, String objAPIName) {
    	List<String> nameList = new List<String>();
    	if(objAPIName != null && idList != null && idList.size() > 0) {
    		if(objAPIName == 'Vendor') {
    			List<Account> vendorList = [Select Id, Name from Account where Id In: idList];
    			for(Account vendorRec : vendorList) {
    				nameList.add(vendorRec.name);
    			}
    		} else if(objAPIName == 'Category') {
    			List<Category__c> categoryList = [Select Id, Name from Category__c where Id In: idList];
    			for(Category__c categoryRec : categoryList) {
    				nameList.add(categoryRec.Name);
    			}
    		}
    	}
    	
    	return nameList;
    }
    
    public static List<String> fieldsList(){
        return new List<String>{ 'Id',
	                            'Name',
	                            'Name__c',
	                            'Type__c',
	                            'Status__c',
	                            'Count_Date_Time__c',
	                            'CreatedDate',
	                            'Finalized_Date__c',
	                            'Finalized_By__r.Name',
	                            'LastModifiedBy.Name',
	                            'LastModifiedDate',
	                            'Counted__c',
	                            'Assigned_Location_1__c',
	                            'Assigned_Location_2__c',
	                            'Vendors__c',
	                            'Categories__c',
	                            'Total_Adjusted_Parts__c',
	                            'Total_Counted_Parts__c',
	                            'Total_Counted_Cost__c',
	                            'Total_Uncounted_Cost__c',
	                            'Total_Uncounted_Parts__c',
	                            'Total_Adjusted_Cost__c',
	                            'Total_Issues_To_Resolve__c',
	                            'Net_Adjustment_After_Finalize__c',
								'Count_Date__c',
								'Last_Modified_By__c',
								'Last_Modified_By__r.Name',
								'Last_Modified_Date__c'
        };
    }
}
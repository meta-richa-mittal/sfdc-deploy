public class PartMovementReportService {
 	
 	private static final Integer QUERY_LIMIT_RECORDS = 3000;
 	public static String PART_FIFO = 'Part FIFO';
 	public static String PART_FIFO_LI = 'Part FIFO Line Item';
	
 	public static Set<String> getPartIdsHavingActivity(String filterJSON) {
    														
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	Set<String> partIdSet = new Set<String>();
        Map<String,String> objectsWhereConditions = HomeSearchReportInterface.getWhereClauseForObjects(filterWrapperObj);
        
    	//Query parts with Part FIFO Bucket 
        String objQuery = ' SELECT Part__c FROM Part_FIFO_Bucket__c ' ;
    	String whereClause = objectsWhereConditions.get(PART_FIFO);
    	if(whereClause != null && whereClause.trim().length() != 0) {
			objQuery += ' ' + whereClause;
		}
		objQuery += ' AND Part__c != null ';
        system.debug(objQuery);
        List<Part_FIFO_Bucket__c> fifoList = (List<Part_FIFO_Bucket__c>)Database.query(objQuery);
        for(Part_FIFO_Bucket__c fifoRec : fifoList) {
    		partIdSet.add(fifoRec.Part__c);
    	}
    	
    	//Query parts with Part FIFO Bucket activity LI Query
        objQuery = ' SELECT Part__c FROM Part_FIFO_Bucket_Activity_Line_Item__c ' ;
    	whereClause = objectsWhereConditions.get(PART_FIFO_LI);
    	if(whereClause != null && whereClause.trim().length() != 0) {
			objQuery += ' ' + whereClause;
		}
        objQuery += ((partIdSet != null && partIdSet.size() > 0) ? ' AND Part__c NOT IN: partIdSet AND Part__c != null ' : '');
        system.debug(objQuery);
        List<Part_FIFO_Bucket_Activity_Line_Item__c> fifoliList  = (List<Part_FIFO_Bucket_Activity_Line_Item__c>)Database.query(objQuery);
        for(Part_FIFO_Bucket_Activity_Line_Item__c fifoliRec : fifoliList) {
    		partIdSet.add(fifoliRec.Part__c);
    	}
        return partIdSet;
	}
	
    public static String getPartMovementActivityReportData(String filterJSON, String idSet) {
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	Set<String> partIdSet = idSet != null ? (Set<String>) System.JSON.deserialize(idSet, Set<String>.class) : new Set<String>();
		return getPartFIFOReportingData(filterWrapperObj, partIdSet);
	}
	
	public static Map<String, List<sObject>> getReportRecords(HomeSearchFilterWrapper filterWrapperObj, Set<String> partIdSet) {
    	Map<String, List<sObject>> resultRecordsMap = new Map<String, List<sObject>>();
		Set<String> objectsSet = new Set<String>{PART_FIFO, PART_FIFO_LI};

    	Map<String,String> objectsWhereConditions = HomeSearchReportInterface.getWhereClauseForObjects(filterWrapperObj);
    	String whereClauseForPartId = ' AND Part__c IN: partIdSet';
    	system.debug('Query ' + objectsWhereConditions.get(PART_FIFO) + whereClauseForPartId + '\n\n' +
    									objectsWhereConditions.get(PART_FIFO_LI) + whereClauseForPartId);
    	for(String selectedObjName : objectsSet) {
	        String objAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(selectedObjName);
	        String objQuery = HomeSearchReportUtil.createSOQLForObject(objAPIName, 
                                                objectsWhereConditions.get(selectedObjName) + whereClauseForPartId,
                                                null, null, null, filterWrapperObj, null);
	    	
	    	//system.assert(false, objQuery);
			objQuery += ' ORDER BY Name ';
	    	system.debug('QUERYYYYYYY objAPIName: \n' + objQuery);
	    	resultRecordsMap.put(objAPIName, (List<sObject>)Database.query(objQuery));
            
        }
    	return resultRecordsMap;
    }
    
 	public static String getPartFIFOReportingData(HomeSearchFilterWrapper filterWrapperObj, Set<String> partIdSet) {
    	
    	Map<String, List<sObject>> resultRecordsMap = getReportRecords(filterWrapperObj, partIdSet);
        List<sObject> resultRecords = new List<sObject>((List<sObject>) resultRecordsMap.get('Part_FIFO_Bucket__c'));
        if(resultRecordsMap.containsKey('Part_FIFO_Bucket_Activity_Line_Item__c')) {
			resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Part_FIFO_Bucket_Activity_Line_Item__c') );
        }
    	
    	HomeSearchResultWrapper.getJSONForSObjectRecords( resultRecords, 
														  HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects), 
														  0,
														  HomeSearchFilterInterface.getFilterLabelList(filterWrapperObj),
                                                          false, false, false, filterWrapperObj.Type.Objects, filterWrapperObj 
														);
														
														
		return system.Json.serialize(HomeSearchResultWrapper.result, true);
    }
    
    public static String getPartMovementDataWithNoActivity(String filterJSON, String lastRecordUniqueFieldValue, String partFoundIdSet, Boolean isReportMode) {
    	Set<String> partWithNOActivityIDSet = (Set<String>)system.json.deserialize(partFoundIdSet, Set<String>.class);
    	
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	DateTime dtValue;
    	String dateStr;
    	Decimal totalPartFound = 0;
    	Decimal resultRecSize = 0;
    	
    	ReportWrapper resultData;
    	if(HomeSearchResultWrapper.validatePartFIFO(new HomeSearchResultWrapper.PartMovement(), filterWrapperObj)) {
	    	if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '1') {
	            dateStr = 'TODAY';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '2') {
	            dateStr = 'YESTERDAY';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '3') {
	            dateStr = 'LAST_N_DAYS:7';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '4') {
	            dateStr = 'LAST_N_DAYS:30';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '5' && filterWrapperObj.Part_FIFO_Date.Value1 != null) {
	    		dtValue = HomeSearchFilterInterface.getDateFromString(filterWrapperObj.Part_FIFO_Date.Value1);
	    	}
			Map<String, List<HomeSearchFilterInterface.FieldFilter>> objectFiltersMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
	    	
	    	String whereClause = '';
	    	if(String.isNotBlank(filterWrapperObj.Part_FIFO_Category) && filterWrapperObj.Part_FIFO_Category != '0') {
	            whereClause += ' AND Category__c = \'' + filterWrapperObj.Part_FIFO_Category + '\'';
	        }
	        if(String.isNotBlank(filterWrapperObj.Part_FIFO_Part_Type) && filterWrapperObj.Part_FIFO_Part_Type != '0') {
	            whereClause += ' AND Part_Type__c LIKE \'' + filterWrapperObj.Part_FIFO_Part_Type + '%\'';
	        }
	        if(String.isNotBlank(filterWrapperObj.Part_FIFO_Vendor)) {
	            whereClause += ' AND Vendor__r.Name LIKE \'' + filterWrapperObj.Part_FIFO_Vendor + '%\'';
	        }
			if(String.isNotBlank(filterWrapperObj.Part_FIFO_Part_Number)) {
				whereClause += ' AND Part_Number__c LIKE \'' + filterWrapperObj.Part_FIFO_Part_Number + '%\'';
			}
	        
	    	String query = 'SELECT Id, Name, Vendor__r.Name, Category__r.Name, Part_Type__c, Location__c, Status__c, Last_Sold__c, Last_Stocked__c, ' + 
	    			'Auto_reorder_Min__c, Auto_reorder_Max__c, Part_Number__c, Description__c, AvailableParts__c, '+
	    			'(SELECT Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c, CreatedDate, Qty_In__c, Cost__c ' +  
	 				 'FROM Part_FIFO_Buckets__r ' + 
	 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Is_FIFO_Bucket__c = true order BY CreatedDate desc limit 1), ' + 
	 				 '(SELECT Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c, CreatedDate, Qty_Out__c, Part_FIFO_Bucket__r.Cost__c ' +  
		 				 'FROM Part_FIFO_Bucket_Activity_Line_Items__r ' + 
		 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Part_FIFO_Bucket__r.Is_FIFO_Bucket__c = true order BY CreatedDate desc, Part_FIFO_Bucket__r.CreatedDate DESC limit 1) ' +   
	 				 'FROM Part__c ' + 
	 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Id NOT IN: partWithNOActivityIDSet AND Has_FIFO_Bucket__c = true ' + (whereClause.length() > 0 ? whereClause : '');
	    	query += String.isNotBlank(lastRecordUniqueFieldValue) ? 'AND Name >\'' + lastRecordUniqueFieldValue + '\'' : '';
	    	query += ' Order By Name ASC LIMIT ' + QUERY_LIMIT_RECORDS;
	    	
	    	system.debug(query);
	    	List<Part__c> partRecList = Database.query(query);
	    	partWithNOActivityIDSet.clear();
	    	lastRecordUniqueFieldValue = '';
	    	if(partRecList.size() > 0) {
	    		lastRecordUniqueFieldValue = partRecList[partRecList.size() - 1].Name;
	    	}
	    	resultRecSize = partRecList.size();
	    	
	    	for(Part__c partRec : partRecList) {
	    		if(getDetailsForPartNoFound(partRec, isReportMode)) {
	    			totalPartFound++;
	    		}
	    	}
	    	partRecList = null;
    	} else {
    		lastRecordUniqueFieldValue = null;
    		resultRecSize = 0;
    	}
    	if(!isReportMode) {
    		resultData = new ReportWrapper(totalOpeningQty, totalOpeningCost, totalPartFound, lastRecordUniqueFieldValue, (resultRecSize < QUERY_LIMIT_RECORDS));
    	} else {
    		resultData = new ReportWrapper(partMovementObjList, lastRecordUniqueFieldValue, (resultRecSize < QUERY_LIMIT_RECORDS));
    		partMovementObjList = null;
    	}
    	return system.Json.serialize(resultData);
	}
    
	private static Decimal totalOpeningQty = 0;
	private static Decimal totalOpeningCost = 0;
	private static List<HomeSearchResultWrapper.PartMovement> partMovementObjList = new List<HomeSearchResultWrapper.PartMovement>();
	private static Boolean getDetailsForPartNoFound(Part__c partRec, Boolean isReportMode) {
		Decimal qty = 0;
		Decimal cost = 0;
		if(partRec.Part_FIFO_Bucket_Activity_Line_Items__r.size() > 0 && partRec.Part_FIFO_Buckets__r.size() > 0 && partRec.Part_FIFO_Buckets__r[0].CreatedDate < partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].CreatedDate) {
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c : 0);
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c : 0);
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c : 0);
			Decimal bucketLICost = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__c != null && partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__r.Cost__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__r.Cost__c : 0);
			
			qty = partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c - partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c;
			cost = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c * partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c) - 
								  (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c * bucketLICost) ;
		} else if(partRec.Part_FIFO_Buckets__r.size() > 0) {
			partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c = (partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c != null ? partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Qty_In__c = (partRec.Part_FIFO_Buckets__r[0].Qty_In__c != null ? partRec.Part_FIFO_Buckets__r[0].Qty_In__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c = (partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c != null ? partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Cost__c = (partRec.Part_FIFO_Buckets__r[0].Cost__c != null ? partRec.Part_FIFO_Buckets__r[0].Cost__c : 0);
			
			qty =  partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c + partRec.Part_FIFO_Buckets__r[0].Qty_In__c;
			cost = partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c * partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c + 
						  partRec.Part_FIFO_Buckets__r[0].Qty_In__c * partRec.Part_FIFO_Buckets__r[0].Cost__c ;
		}
		if(qty != 0) {
			if(isReportMode) {
    			HomeSearchResultWrapper.PartMovement partMovementRec = new HomeSearchResultWrapper.PartMovement(partRec);
    			partMovementRec.Opening_Qty = partMovementRec.Closing_Qty = qty;
    			partMovementRec.Opening_Value = partMovementRec.Closing_Value= cost;
    			partMovementObjList.add(partMovementRec);
			} else {
				totalOpeningQty += qty;
				totalOpeningCost += cost;
			}
			return true;
		}
		return false;
	}
	
	public class ReportWrapper {
		public Decimal TotalOpeningQty;
		public Decimal TotalOpeningValue;
		public Decimal TotalPartFound;
    	public List<HomeSearchResultWrapper.PartMovement> ResultData;
    	public String LastRecordUniqueFieldValue;
    	public Boolean IsProcessCompleted;
    	
    	public ReportWrapper(Decimal totalOpeningQty, Decimal totalOpeningCost, Decimal totalPartFound, String lastRecordUniqueFieldValue, Boolean IsProcessCompleted) {
    		this.TotalOpeningQty = totalOpeningQty;
    		this.TotalOpeningValue = totalOpeningCost;
    		this.TotalPartFound = totalPartFound;
    		this.LastRecordUniqueFieldValue = lastRecordUniqueFieldValue;
    		this.IsProcessCompleted = IsProcessCompleted;
    	}
    	
    	public ReportWrapper(List<HomeSearchResultWrapper.PartMovement> ResultData, String lastRecordUniqueFieldValue, Boolean IsProcessCompleted) {
    		this.ResultData = ResultData;
    		this.LastRecordUniqueFieldValue = lastRecordUniqueFieldValue;
    		this.IsProcessCompleted = IsProcessCompleted;
    	}
    }
	    	
}
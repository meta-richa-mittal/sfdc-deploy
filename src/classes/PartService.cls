/** 
* Author: Nidhi Sharma
* Since: June 14, 2021 
* Name: PartService 
* Description: Apex class which contains reusable methods for Part entity.
**/
public without sharing class PartService {
	
	public static Integer limitRecord = 50;
	
    public static List<Part__c> getAllParts(PartFilterWrapper filterObj) {
    	String query = 'SELECT ' + String.join(PartWrapper.fieldsList(), ',') + ' FROM Part__c ' + getWhereClauseByFilterStr(filterObj);
    	query += ' ORDER BY Part_Number__c ASC '; 
    	if(filterObj.StartIndex != null && filterObj.RecordCount != null) {
    		query += SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
    	} else {
    		query += 'LIMIT ' + limitRecord;
    	}
    	List<SObject> sobjList = SOQLUtility.getQueryResults('Part__c', query);
    	
    	if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
    	}
    	return sobjList;
    }
    
    public static List<PartWrapper> getPartObjList(List<Part__c> partList) {
    	List<PartWrapper> wrapperList = new List<PartWrapper>();
        for(Part__c partRec : partList) {
            wrapperList.add(new PartWrapper(partRec));
        }
        return wrapperList;
    }
    
    private static String getWhereClauseByFilterStr(PartFilterWrapper filterObj) {
    	List<String> filterStrList = new List<String>{'Active__c = true'};
    	
    	if(filterObj != null) {
    		//Vendor
	    	if(filterObj.VendorList != null && !filterObj.VendorList.isEmpty()) {
	    		filterStrList.add('Vendor__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.VendorList));
	    	}
	    	//Tag
	    	String tagFilterStr = HomeSearchReportInterface.getAssignedTagClause('Parts', filterObj.TagList, 'Tag');
	    	if(String.isNotBlank(tagFilterStr)) {
    			filterStrList.add(tagFilterStr);
	    	}
	    	//Category
	    	if(filterObj.CategoryList != null && !filterObj.CategoryList.isEmpty()) {
	    		filterStrList.add('Category__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.CategoryList));
	    	}
	    	//Part Number OR description
	    	if(String.isNotBlank(filterObj.PartItemDesc) && String.isNotBlank(filterObj.PartItemDesc.trim())) {
	    		filterStrList.add('(Part_Number__c LIKE \'' + BPUtility.escapeSingleQuotes(filterObj.PartItemDesc.trim()) + '%\' OR Description__c LIKE \'%' + BPUtility.escapeSingleQuotes(filterObj.PartItemDesc.trim()) + '%\')');
	    	}
	    	//From created date
	    	if(String.isNotBlank(filterObj.StartDateCreated)) {
	    		DateTime createdDateTimeStart = HomeSearchFilterInterface.getDateFromString(filterObj.StartDateCreated);
	    		filterStrList.add('CreatedDate >= ' + createdDateTimeStart.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
	    	}
	    	//To created date
	    	if(String.isNotBlank(filterObj.EndDateCreated)) {
	    		DateTime createdDateTimeEnd = HomeSearchFilterInterface.getDateFromString(filterObj.EndDateCreated);
	    		filterStrList.add('CreatedDate < ' + createdDateTimeEnd.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
	    	}
	    	//Any Hardcoded where clause
            if(String.isNotBlank(filterObj.HardCodedWhereClause)) {
                filterStrList.add(filterObj.HardCodedWhereClause);
            }
    	}
    	return !filterStrList.isEmpty() ? ' WHERE ' + String.join(filterStrList, ' AND ') : '';
    }
}
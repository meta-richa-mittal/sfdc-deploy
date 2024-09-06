/**
 * Author: Nidhi Sharma
 * Since: August 28, 2019
 * Name: PartCountSOQLUtil
 * Description: 
**/
public without sharing class PartCountSOQLUtil {
	
    public static List<Count_Session__c> getCountSessionDetailByFieldFilter(Map<String, String> fieldNameToValueMap, String orderByStr) {
		String query;
        query = 'SELECT ';
        for(String fieldName : CountSessionWrapper.fieldsList()) {
            query += BPUtility.escapeSingleQuotes(fieldName) + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Count_Session__c ';
        Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToValueMap.keySet()) {
            if(isWhereClauseAdded) {
                query += ' AND ' + BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + fieldNameToValueMap.get(fieldName) + '\'';
            } else {
                query += ' WHERE ' + BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + fieldNameToValueMap.get(fieldName) + '\'';
                isWhereClauseAdded = true;
            }
        }
        query += ' ' + orderByStr + ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Count_Session__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Count_Session__c> countSessionRecList = Database.query(query);
        return countSessionRecList;
	}
	
    public static List<Count_Session__c> getCountSessionDetailByFieldFilter(Map<String, String> fieldNameToValueMap) {
    	return getCountSessionDetailByFieldFilter(fieldNameToValueMap, ' Order By Name ');
    }
    
    public static List<Count_Session_Line_Item__c> getCountSessionLineItemsByFieldFilter(Map<String, String> fieldNameToValueMap, 
																						PartCountService.PageInfoWrapper pageInfoObj) {
    	return getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, pageInfoObj, null);
    }
    
    public static List<Count_Session_Line_Item__c> getCountSessionLineItemsBySearchText(Map<String, String> fieldNameToValueMap, 
																						List<GenericSearchUtil.FieldFilter> fieldFilterList) {
    	return getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, null, fieldFilterList);
    }
    
    public static List<Count_Session_Line_Item__c> getCountSessionLineItemsByFieldFilter(Map<String, String> fieldNameToValueMap, PartCountService.PageInfoWrapper pageInfoObj, 
																						List<GenericSearchUtil.FieldFilter> fieldFilterList) {
    	String query;
        query = 'SELECT ';
        for(String fieldName : CountSessionLineItemWrapper.fieldsList()) {
            query += BPUtility.escapeSingleQuotes(fieldName) + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Count_Session_Line_Item__c ';
        String whereClause = getCountSessionLineItemWhereClause(fieldNameToValueMap);			//where Clause
        if(fieldFilterList != null && fieldFilterList.size() > 0) {
        	//Search by text
        	query += getCountSessionLineItemFilterClause(whereClause, fieldFilterList);
        } else {
        	query += whereClause;
        }
        query += ' Order By Part_Number_Formula__c ';
        if(pageInfoObj != null) {
            query += SOQLUtility.getLimitClause(((pageInfoObj.CurrentPage - 1) * pageInfoObj.PageSize), pageInfoObj.PageSize);
        } else {
        	query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        }
        List<SObject> sobjList = SOQLUtility.getQueryResults('Count_Session_Line_Item__c', query);
        if(pageInfoObj != null && ((pageInfoObj.CurrentPage - 1) * pageInfoObj.PageSize) > 2000 && pageInfoObj.PageSize != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, ((pageInfoObj.CurrentPage - 1) * pageInfoObj.PageSize));
    	}
        return (List<Count_Session_Line_Item__c>)sobjList;
    }
    
    public static List<Count_Session_Line_Item__c> getCountSessionLineItemsCountByFieldFilter(Map<String, String> fieldNameToValueMap) {
    	String query;
        query = 'SELECT Issue_Indicator__c FROM ' + Constants.NAMESPACE + 'Count_Session_Line_Item__c ';
        query += getCountSessionLineItemWhereClause(fieldNameToValueMap);			//where Clause
        
        if(AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (List<Count_Session_Line_Item__c>)Database.query(query);
    }
    
    public static String getCountSessionLineItemWhereClause(Map<String, String> fieldNameToValueMap) {
    	String whereClause = '';
    	Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToValueMap.keySet()) {
        	if(isWhereClauseAdded) {
        		whereClause += ' AND ';
        	} else {
        		whereClause += ' WHERE ';
        		isWhereClauseAdded = true;
        	}
            if(fieldName == 'Variance__c' || fieldName == 'Issue_Indicator__c') {
            	whereClause += BPUtility.escapeSingleQuotes(fieldName) + ' ' + BPUtility.escapeSingleQuotes(fieldNameToValueMap.get(fieldName));
            } else if(fieldName == 'Is_Counted__c' || fieldName == 'Is_Selected_Part__c') {
            	whereClause += BPUtility.escapeSingleQuotes(fieldName) + ' = ' + (fieldNameToValueMap.get(fieldName) == 'true' ? true : false);
            } else {
            	whereClause += BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToValueMap.get(fieldName)) + '\'';
            }
        }
        
        return whereClause;
    }
    
    public static List<Part__c> getSelectedPartInfo(String partId) {
    	String query = 'SELECT Id, Average_Cost__c, Last_Cost__c, Part_Number__c, Description__c, AvailableParts__c, Vendor__r.Name, Assigned_Location_1__c, ' +
    			 + 'Assigned_Location_2__c FROM Part__c ';
        query += ' where Id =: partId LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> partRecList = Database.query(query);
        return partRecList;
    }
    
    private static String getCountSessionLineItemFilterClause(String fixedWhereClause, List<GenericSearchUtil.FieldFilter> filterList) {
        String whereClause = '';
        for(GenericSearchUtil.FieldFilter fieldFilter : filterList) {
            if(fieldFilter.FieldName != null && fieldFilter.FieldName.trim().length() > 0) {
                String filterFieldName = fieldFilter.FieldName;
                whereClause += (fieldFilter.FieldName + ' ' + fieldFilter.Operator + ' ' + fieldFilter.FieldValue) + ' OR ';
            } else {
                whereClause += fieldFilter.FieldValue + ' OR ';
            }
        }
        whereClause = whereClause.subString(0, whereClause.length() - 4);
        
        whereClause = String.isNotBlank(fixedWhereClause) ? fixedWhereClause + ' AND (' + whereClause + ')' : ' WHERE (' + whereClause + ')';
        return whereClause;
    }
    
    public static List<Part__c> getPartByPartNumber(Set<String> partNumberSet) {
    	String query = 'SELECT Id, Part_ID__c, Average_Cost__c, Last_Cost__c, Part_Number__c, AvailableParts__c, Vendor__r.Name, Assigned_Location_1__c, ' +
    			 + 'Assigned_Location_2__c, SKU_Number__c FROM Part__c ';
        query += ' where (Part_ID__c IN: partNumberSet OR Part_Number__c IN: partNumberSet OR SKU_Number__c IN: partNumberSet) AND Active__c = true LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> partRecList = Database.query(query);
        return partRecList;
    }
    
    public static List<Count_Session_Line_Item__c> getPartialCountSessionLineItemsByFieldFilter(Map<String, String> fieldNameToValueMap, String uniqueFieldLastValue, 
        Integer queryRecordsLimit) {
        String query = 'SELECT ' + String.join(CountSessionLineItemWrapper.fieldsList(), ',');
        query += ' FROM ' + Constants.NAMESPACE + 'Count_Session_Line_Item__c ' + getCountSessionLineItemWhereClause(fieldNameToValueMap);
        if(uniqueFieldLastValue != null) {
            query += ' AND Name >\'' + uniqueFieldLastValue + '\'';
        } 
        query += ' Order By Name Asc LIMIT ' + queryRecordsLimit;
        
        if(!AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Count_Session_Line_Item__c> countSessionLineItemRecList = Database.query(query);
        return countSessionLineItemRecList;
    }
}
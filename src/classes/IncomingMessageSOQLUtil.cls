/** 
* Author: Nidhi Sharma
* Since: Nov 20, 2020
* Name: IncomingMessageSOQLUtil 
* Description: SOQL Util class for Incoming Message
**/
public without sharing class IncomingMessageSOQLUtil { 
    
    public static List<Message_Read_By__c> getMessageReadByRecords(Map<String, String> fieldNameToFieldValueMap, IncomingMessageService.SortingWrapper sortingObj) { 
        String query = 'SELECT ';
        for(String fieldName : IncomingMessageWrapper.getMsgReadByFieldList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Message_Read_By__c where Message__r.Sent_To__c != null '; 
        query += getWhereClause(fieldNameToFieldValueMap, true);
        query += ' ORDER BY Message__r.Incoming_SMS_Time__c ' + (sortingObj != null && sortingObj.SortDirForTimeRec != null ? sortingObj.SortDirForTimeRec : 'DESC');
        query += ' LIMIT ' + (sortingObj != null && sortingObj.NumberOfRecPerPage != null ? sortingObj.NumberOfRecPerPage : SOQLUtil.getAvailableQueryRowsLimit());
        if(AccessControl.ifObjectFieldIsAccessible('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query); 
    }
    
    
    public static List<CO_Header__c> getCOHeaderListByCustomerIds(Set<String> customerIdSet) { 
        String query = 'SELECT ';
        for(String fieldName : IncomingMessageWrapper.getCOFieldList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM CO_Header__c '; 
        query += 'WHERE Order_Status__c != \'Closed\' AND Customer__c IN: customerIdSet ';
        query += 'ORDER BY Name DESC ';
        query += 'LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query); 
    }
    
    public static String getWhereClause(Map<String, String> fieldNameToFieldValueMap, Boolean isWhereClauseAdded) { 
    	String whereClause = '';
        if(fieldNameToFieldValueMap.size() > 0) {
            for(String fieldName : fieldNameToFieldValueMap.keySet()) {
                if(!isWhereClauseAdded) {
                    whereClause += 'WHERE ';
                    isWhereClauseAdded = true;
                } else {
                    whereClause += 'AND ';
                }
        		if(fieldNameToFieldValueMap.get(fieldName) != null && (fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('false') || 
        						fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('true'))) {
                    whereClause += fieldName + ' = ' + fieldNameToFieldValueMap.get(fieldName) + ' ';
                } else {
                    whereClause += fieldName + ' = \'' + fieldNameToFieldValueMap.get(fieldName) + '\' ';
                }
            }
        }
        return whereClause;
    }
}
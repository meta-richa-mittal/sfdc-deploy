/**
* Author: Author: Nikhil Kumar Srivastava
* Since: May 22, 2019
* Name: BrandingLocationSOQLUtil
* Description: SOQL Apex class for Branding Location
**/
public without sharing class BrandingLocationSOQLUtil {
	
	// getBrandingLocationDetailList
    public static List<Branding_Location__c> getBrandingLocationDetailListByFilter(Map<String, String> fieldNameToFieldValueMap) {
    	String query = 'SELECT ';
        for(String fieldName : BrandingLocationWrapper.fieldsList()) {
            query += fieldName + ', ';  
        }
        query += ' (SELECT Id, ContentType, BodyLength, Description, Name FROM Attachments LIMIT 1) ';
        query += ' FROM Branding_Location__c ';
        query += getWhereClause(fieldNameToFieldValueMap);
        query += ' ORDER BY Name ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Branding_Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    private static String getWhereClause(Map<String, String> fieldNameToFieldValueMap) {
        String whereClause = '';
        Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            if(isWhereClauseAdded) {
                whereClause += ' AND ' + BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
            } else {
                whereClause += ' WHERE ' + BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
                isWhereClauseAdded = true;
            }
        }
        return whereClause;
    }
}
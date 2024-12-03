/**
 * Author: Richa Mittal
 * Since: April 02, 2020
 * Name: AutomatedPriceFileSOQLUtil
 * Description: AutomatedPriceFileSOQLUtil class.
**/
public without sharing class AutomatedPriceFileSOQLUtil {
    public static List<Vendor_Master__c> getVendorMasterList(List<String> fieldsList, Map<String, Object> fieldNameToFieldValueMap) {
    	String query = 'SELECT ';
    	fieldsList = (fieldsList != null && fieldsList.size() > 0) ? fieldsList : VendorMasterWrapper.getFieldList();
        for(String fieldName : fieldsList){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Vendor_Master__c ';
        if(fieldNameToFieldValueMap.size() > 0){
            query += SOQLUtil.getWhereClause(fieldNameToFieldValueMap);
            query += 'AND Vendor_Name__c != Null';
        } else {
            query += 'WHERE Vendor_Name__c != Null';
        }
        query += ' ORDER BY Vendor_Name__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Master__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static List<Price_File_Mapping__c> getPriceFileMappingList(List<String> fieldsList, Map<String, Object> fieldNameToFieldValueMap) {
    	fieldsList = (fieldsList != null && fieldsList.size() > 0) ? fieldsList : AutomatedPriceFileMappingWrapper.getFieldList();
        String query = 'SELECT ' + String.join(fieldsList, ',') + ', ';
        // Child Query - Escalators
        query += '(SELECT ' + String.join(Escalator.getFieldList(), ',');
        query += ' FROM Escalators__r)' ;
        query += ' FROM Price_File_Mapping__c ';
        query += SOQLUtil.getWhereClause(fieldNameToFieldValueMap);
        query += ' ORDER BY CreatedDate DESC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Price_File_Mapping__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
}
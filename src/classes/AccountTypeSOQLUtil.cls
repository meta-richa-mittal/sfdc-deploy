/**
 * Author: Rajat Jain
 * Since: October 8, 2018
 * Name: AccountTypeSOQLUtil
 * Description: SOQL Util class for Account Type
**/
public without sharing class AccountTypeSOQLUtil { 
    
    public static List<Account_Type__c> getAccountType(Map<String, String> fieldNameToFieldValueMap) { 
        String query = 'SELECT ';
        for(String fieldName : AccountTypeWrapper.getAccountTypeFields()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        // Child Query
        query += '(Select Id, Sales_Tax_Item__r.Name__c from Tax_Exemptions__r Where Sales_Tax_Item__r.Is_Removed__c = false), (Select Id from Accounts__r limit 1), (Select Id from Accounts1__r limit 1)';  
        query += ' FROM Account_Type__c';
        query += getWhereClause(fieldNameToFieldValueMap);
        query += ' ORDER BY Applies_To__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query); 
    }
     
    public static List<Account_Type__c> getTaxExemptionRecForAccType(Map<String, String> fieldNameToFieldValueMap) {
        String query = 'SELECT ';
        for(String fieldName : AccountTypeWrapper.getAccountTypeFields()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        // Child Query
        
        query += '(Select ';
        for(String fieldName : TaxExemptions.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' from Tax_Exemptions__r), ';
        query += ' (Select Id from Accounts__r limit 1), (Select Id from Accounts1__r limit 1)';
        query += ' FROM Account_Type__c';
        query += getWhereClause(fieldNameToFieldValueMap);
        if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Sales_Tax_Item__c> getAllSalesTaxItemWithExemptions() {
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String query;
        query = 'SELECT Name__c, Rate__c, Forms_Label__c, Tax_Type__c, Rate_Type__c, Tax_Rate_Tier_1__c, ' +
        				'Tax_Rate_Tier_2__c,Tax_Rate_Tier_3__c, Max_Taxable_Amount_Tier_1__c, Max_Taxable_Amount_Tier_2__c, ';
        
        // child Query - Tax Exemptions
        query += '(SELECT Id, Customer__c from Tax_Exemptions__r where Account_Type__c != null)'; 
        query += ' FROM ' + Constants.NAMESPACE + 'Sales_Tax_Item__c Where Is_Removed__c = false ';
        
        List<Sales_Tax_Item__c> salesTaxItemList = Database.query(query);
        return salesTaxItemList;  
    }
    private static String getWhereClause(Map<String, String> fieldNameToFieldValueMap) {
        String whereClause = '';
        Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            if(isWhereClauseAdded) {
            	if(BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) == 'true') {
            		whereClause += ' AND ' + fieldName + ' = ' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName));
            	} else {
            		whereClause += ' AND ' + fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
            	}
            } else {
            	if(BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) == 'true') {
            		whereClause += ' AND ' + fieldName + ' = ' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName));
            	} else {
	                whereClause += ' WHERE ' + fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
	                isWhereClauseAdded = true;
            	}
            }
        }
        return whereClause;
    }
    
}
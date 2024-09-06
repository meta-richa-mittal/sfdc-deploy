/**
 * Author: Nidhi Sharma
 * Since: 13 Nov, 2019
 * Name: TaxManagementSOQLUtil
 * Description: 
**/
public without sharing class TaxManagementSOQLUtil {
    
     public static List<Sales_Tax_Item__c> getAllTaxRates(Map<String, String> fieldNameToFieldValueMap) {
		String query = 'SELECT ';
        for(String fieldName : TaxRateWrapper.fieldsList()) {
            query += fieldName + ', ';  
        }
        query = query.subString(0, query.length() - 2);
        query += ' FROM Sales_Tax_Item__c';
        Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            if(isWhereClauseAdded) {
                query += ' AND ';
            } else {
                query += ' WHERE ';
                isWhereClauseAdded = true;
            }
            if(fieldNameToFieldValueMap.get(fieldName) != null && (fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('false') || 
        						fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('true'))) {
                query += fieldName + ' = ' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + ' ';
            } else {
                query += fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
            }
        }
        query += ' ORDER BY Name__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Sales_Tax__c> getAllSalesTaxes() {
		String query = 'SELECT ';
        for(String fieldName : TaxCodeWrapper.salesTaxFieldsList()) {
            query += fieldName + ', ';  
        }
        query = query.subString(0, query.length() - 2);
        query += ' FROM Sales_Tax__c WHERE Is_Removed__c = false ORDER BY Name__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Applicable_Taxes__c> getAllApplicableTaxes() {
        if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return [SELECT Sales_Tax__c, Sales_Tax_Item__c, Sales_Tax_Item__r.Active__c, Sales_Tax_Item__r.Forms_Label__c, Sales_Tax_Item__r.Minimum_Tax_Amount__c, 
        			Sales_Tax_Item__r.Maximum_Tax_Amount__c, Sales_Tax_Item__r.Category__r.Name, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Rate__c, 
        			Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Tax_Type__c, Sales_Tax_Item__r.Tax_Rate_Tier_1__c, Sales_Tax_Item__r.Tax_Rate_Tier_2__c,  
        			Sales_Tax_Item__r.Tax_Rate_Tier_3__c ,  Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c , Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c 
        			FROM Applicable_Taxes__c];
    }
    
    public static List<Sales_Tax__c> getSalesTaxWithAllRelatedEntities(String salesTaxId) {
    	String query;
		query = 'SELECT Id, '; 
		query += '( SELECT Id FROM Accounts1__r LIMIT 1)';
		query += ', ( SELECT Id FROM Customer_Owned_Units__r LIMIT 1)';
		query += ', ( SELECT Id FROM Fees__r LIMIT 1)';
		query += ', ( SELECT Id FROM Labour_Codes__r LIMIT 1)';
		query += ', ( SELECT Id FROM Parts__r LIMIT 1)';
		query += ', ( SELECT Id FROM Products__r LIMIT 1)';
		query += ', ( SELECT Id FROM Deals_Items__r LIMIT 1)';
		
		query += ' FROM Sales_Tax__c WHERE Id =: salesTaxId LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		
		if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		return Database.query(query);
    }
    
    public static List<Applicable_Taxes__c> getApplicableTaxListBySalesTaxIdList(List<Id> salesTaxIdList) {
    	if(!AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	return [SELECT Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax_Item__r.Name__c, 
        		Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c, Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c, Sales_Tax_Item__r.Maximum_Tax_Amount__c, 
        		Sales_Tax_Item__r.Minimum_Tax_Amount__c, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Tax_Rate_Tier_1__c, Sales_Tax_Item__r.Tax_Rate_Tier_2__c, 
        		Sales_Tax_Item__r.Tax_Rate_Tier_3__c, Sales_Tax_Item__r.Tax_Type__c, 
                Sales_Tax_Item__r.Rate__c from Applicable_Taxes__c where Sales_Tax__c IN : salesTaxIdList];
    }
    
    public static List<Applicable_Taxes__c> getApplicableTaxListBySalesTaxIdList(Set<Id> salesTaxIdSet) {
        return getApplicableTaxListBySalesTaxIdList(new List<Id>(salesTaxIdSet));
    }
}
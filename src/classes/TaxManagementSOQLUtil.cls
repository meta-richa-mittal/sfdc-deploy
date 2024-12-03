/**
 * Author: Nidhi Sharma
 * Since: 13 Nov, 2019
 * Name: TaxManagementSOQLUtil
 * Description: 
**/
public without sharing class TaxManagementSOQLUtil {

    public static List<Sales_Tax_Item__c> getTaxRates(Map<String, String> fieldNameToFieldValueMap, TaxManagementFilterWrapper filterObj) {
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
        query += addSearchKeywordFilter(filterObj, isWhereClauseAdded);
        query += ' ORDER BY Display_Order__c ASC, Name__c ASC ' + SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
        List<SObject> sobjList = SOQLUtility.getQueryResults('Sales_Tax_Item__c', query);

        if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
            sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
        }
        return sobjList;
    }
    
    public static List<Sales_Tax__c> getSalesTaxes(Map<String, String> fieldNameToFieldValueMap, TaxManagementFilterWrapper filterObj) {
		String query = 'SELECT ';
        for(String fieldName : TaxCodeWrapper.salesTaxFieldsList()) {
            query += fieldName + ', ';  
        }
        query = query.subString(0, query.length() - 2);
        query += ' FROM Sales_Tax__c';
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
        query += addSearchKeywordFilter(filterObj, isWhereClauseAdded);
        query += ' ORDER BY Name__c ASC ' + SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
        List<SObject> sobjList = SOQLUtility.getQueryResults('Sales_Tax__c', query);

        if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
            sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
        }
        return sobjList;
    }

    public static List<AggregateResult> getTaxRateCounts(TaxManagementFilterWrapper filterObj) {
        String query = 'SELECT Count(Id) TaxRateCount, Tax_Type__c FROM Sales_Tax_Item__c WHERE Is_Removed__c = false';
        query += addSearchKeywordFilter(filterObj, true);
        query += ' GROUP BY Tax_Type__c';
    	return SOQLUtility.getQueryResults('Sales_Tax_Item__c', query);
    }

    public static List<AggregateResult> getTaxCodeCounts(TaxManagementFilterWrapper filterObj) {
        String query = 'SELECT Count(Id) TaxCodeCount, Tax_Type__c FROM Sales_Tax__c WHERE Is_Removed__c = false';
        query += addSearchKeywordFilter(filterObj, true);
        query += ' GROUP BY Tax_Type__c';
    	return SOQLUtility.getQueryResults('Sales_Tax__c', query);
    }

    private static String addSearchKeywordFilter(TaxManagementFilterWrapper filterObj, Boolean isWhereClauseAdded) {
        String query = '';
        if(String.isNotBlank(filterObj.SearchKeyword)) {
            filterObj.SearchKeyword = BPUtility.escapeSingleQuotes(filterObj.SearchKeyword.trim());
            query += isWhereClauseAdded ? ' AND (Forms_Label__c LIKE \'%' + filterObj.SearchKeyword + '%\' OR Name__c LIKE \'%' + filterObj.SearchKeyword + '%\')' : ' WHERE (Forms_Label__c LIKE \'%' + filterObj.SearchKeyword + '%\' OR Name__c LIKE \'%' + filterObj.SearchKeyword + '%\')';
        }
        return query;
    }

    public static List<Applicable_Taxes__c> getAllApplicableTaxes(List<Sales_Tax__c> salesTaxList) {
        if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return [SELECT Sales_Tax__c, Sales_Tax_Item__c, Sales_Tax_Item__r.Active__c, Sales_Tax_Item__r.Forms_Label__c, Sales_Tax_Item__r.Minimum_Tax_Amount__c, 
        			Sales_Tax_Item__r.Maximum_Tax_Amount__c, Sales_Tax_Item__r.Category__r.Name, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Rate__c, 
        			Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Tax_Type__c, Sales_Tax_Item__r.Tax_Rate_Tier_1__c, Sales_Tax_Item__r.Tax_Rate_Tier_2__c,  
        			Sales_Tax_Item__r.Tax_Rate_Tier_3__c ,  Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c , Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c, 
                    Sales_Tax_Item__r.Is_Automated__c, Maximum_Taxable_Amount__c
        			FROM Applicable_Taxes__c WHERE Sales_Tax__c IN :salesTaxList];
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
    	return [SELECT Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Is_Automated__c, Sales_Tax_Item__r.Active__c, 
        		Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c, Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c, Sales_Tax_Item__r.Maximum_Tax_Amount__c, 
        		Sales_Tax_Item__r.Minimum_Tax_Amount__c, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Tax_Rate_Tier_1__c, Sales_Tax_Item__r.Tax_Rate_Tier_2__c, 
        		Sales_Tax_Item__r.Tax_Rate_Tier_3__c, Sales_Tax_Item__r.Tax_Type__c, Sales_Tax_Item__r.Rate__c, Maximum_Taxable_Amount__c,
                Sales_Tax_Item__r.Automated_Tax_Rate_Name__c 
                from Applicable_Taxes__c where Sales_Tax__c IN : salesTaxIdList];
    }
    
    public static List<Applicable_Taxes__c> getApplicableTaxListBySalesTaxIdList(Set<Id> salesTaxIdSet) {
        return getApplicableTaxListBySalesTaxIdList(new List<Id>(salesTaxIdSet));
    }
}
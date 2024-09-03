/**
 * Author: Tarun Khandelwal
 * Since: Oct. 10, 2014
 * Name: SalesTaxTriggerHelper
 * Description: Helper class for triggers on price level object
**/
public without sharing class SalesTaxTriggerHelper {
    
    // List to store trigger new list
    public static List<Sales_Tax__c> salesTaxNewList = new List<Sales_Tax__c>();
    
    // List to store trigger old list
    public static List<Sales_Tax__c> salesTaxOldList = new List<Sales_Tax__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Sales_Tax__c> salesTaxNewMap = new Map<Id, Sales_Tax__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Sales_Tax__c> salesTaxOldMap = new Map<Id, Sales_Tax__c>();
    
    // Boolean variable to check execution of trigger
    public static boolean runDefaultCheckBoxUpdate = true;
    private static String NO_TAX_TYPE = 'No tax type';
    
    /**
     * Name: updateDefaultField
     * Desc: If current record Default field is selected, Unselects Default field of all remaining records.
     * @param: 
     * @return: 
    **/
    public static void updateDefaultField() {
        if(AccessControl.ifObjectFieldIsUpdateable('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if( runDefaultCheckBoxUpdate ) {
            Boolean defaultFieldUpdated = false;
            for(Sales_Tax__c salesTax : salesTaxNewList) {
                if( trigger.isInsert ) {
                    if( salesTax.Default__c ) {
                       defaultFieldUpdated= true;
                    }
                }
                else if ( trigger.isUpdate ) {
                	if( salesTax.Default__c && (!salesTaxOldMap.get(salesTax.Id).Default__c) ) {
                    	defaultFieldUpdated = true;
                    }
                }
                
                if(defaultFieldUpdated) {
                    break;
                }
            }
            
            if(defaultFieldUpdated) {
            
                List<Sales_Tax__c> salesTaxToUpdate = new List<Sales_Tax__c>();
                if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Sales_Tax__c> defaultTaxList = [select Id, Default__c, Tax_Type__c from Sales_Tax__c where Default__c = true limit : Limits.getLimitDMLRows()];
                
                Map<String, List<Sales_Tax__c>> taxTypeToRelatedTaxListMap = new Map<String, List<Sales_Tax__c>>();
                
                for(Sales_Tax__c salesTaxRec : defaultTaxList) {
                	String taxType = salesTaxRec.Tax_Type__c != null ? salesTaxRec.Tax_Type__c : NO_TAX_TYPE;
                	if(!taxTypeToRelatedTaxListMap.containsKey(taxType)) {
                		taxTypeToRelatedTaxListMap.put(taxType, new List<Sales_Tax__c>());
                	}
                	taxTypeToRelatedTaxListMap.get(taxType).add(salesTaxRec);
                }
                defaultTaxList = null;
                
                for(Sales_Tax__c salesTax : salesTaxNewList) {
                    if(salesTax.Default__c) {
                    	String taxType = salesTax.Tax_Type__c != null ? salesTax.Tax_Type__c : NO_TAX_TYPE;
                    	if(taxTypeToRelatedTaxListMap.containsKey(taxType)) {
                    		for(Sales_Tax__c oldSalesTax : taxTypeToRelatedTaxListMap.get(taxType)) {
	                            if(oldSalesTax.Default__c) {
	                                oldSalesTax.Default__c = false;
	                                salesTaxToUpdate.add(oldSalesTax);
	                            }
	                        }
                    	}
                    }
                }
                
                if(salesTaxToUpdate.size() > 0) {
                    runDefaultCheckBoxUpdate = false;
                    DMLUtility.updateSobjectList('Sales_Tax__c', salesTaxToUpdate);
                }
            }
        }
    }
    
    /**
     * Name: validateBeforeDel
     * Desc: Validate the deleting record before deleting if it default and active record or not
     * @param: 
     * @return: 
    **/
    public static void validateBeforeDel() {
        for(Sales_Tax__c ST : salesTaxOldList) {
            ST.addError('Cannot delete a Sales Tax record.');
        }
    }
}
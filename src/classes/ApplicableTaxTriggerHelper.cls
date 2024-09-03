/**
 * Author: Tarun Khandelwal
 * Since: Oct. 11, 2014
 * Name: ApplicableTaxTriggerHelper
 * Description: Helper class for triggers on Applicable Tax object (Used In Kendo)
**/
public without sharing class ApplicableTaxTriggerHelper {
    
     // List to store trigger new list
    public static List<Applicable_Taxes__c> applicableTaxNewList = new List<Applicable_Taxes__c>();
    
    // List to store trigger old list
    public static List<Applicable_Taxes__c> applicableTaxOldList = new List<Applicable_Taxes__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Applicable_Taxes__c> applicableTaxNewMap = new Map<Id, Applicable_Taxes__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Applicable_Taxes__c> applicableTaxOldMap = new Map<Id, Applicable_Taxes__c>();
    
    /**
     * Name: updateRateFieldOnSalesTax
     * Desc: Update Rate field of Sales Tax object to the sum of corresponding Sales Tax Item Rate 
     * @param: 
     * @return: 
    **/
    public static void  updateRateFieldOnSalesTax() {
        Set<Id> salesTaxSet = new Set<Id>();
        List<Applicable_Taxes__c> appTaxList = (trigger.isInsert ? applicableTaxNewList : (trigger.isDelete ? applicableTaxOldList : new List<Applicable_Taxes__c>()));
        for(Applicable_Taxes__c appTax : appTaxList){
            salesTaxSet.add(appTax.Sales_Tax__c);
        }
        salesTaxSet.remove(null);
        if(!salesTaxSet.isEmpty()) {
            if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            List<Sales_Tax__c> stUpdateList = [Select Id, (SELECT Sales_Tax_Item__r.Rate__c from Applicable_Taxes__r WHERE Sales_Tax_Item__r.Rate__c != null) From Sales_Tax__c WHERE Id IN: salesTaxSet AND Is_Removed__c = false];
            for(Sales_Tax__c tax : stUpdateList) {
                tax.Rate__c = 0;
                for( Applicable_Taxes__c app : tax.Applicable_Taxes__r) {
                    tax.Rate__c += app.Sales_Tax_Item__r.Rate__c;      
                }
            }
            DMLUtility.updateSobjectList('Sales_Tax__c', stUpdateList);
        }
    }
}
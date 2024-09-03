/**
 * Author: Nidhi Sharma
 * Since: 13 May, 2024
 * Name: UPCAdjustmentDateBatch
 * Description: Batch for populating date stocked in on SKU
**/
global without sharing class SKUDateStockedInBatch extends PostInstallScriptBaseBatch {

    global SKUDateStockedInBatch() {
        this.scriptName = 'executeSKUDateStockedInBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Date_Stocked_In__c, CreatedDate from Customer_Owned_Unit__c WHERE Date_Stocked_In__c = null AND Unit_Type__c = \'STOCK\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> unitList) {
        for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>) unitList) {
            unitRec.Date_Stocked_In__c = unitRec.CreatedDate.date();
        }
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
/**
 * Author: Nidhi Sharma
 * Since: Oct 31, 2023
 * Name: ORDUAndUPCTaxableCostBatch
**/
global without sharing class ORDUAndUPCTaxableCostBatch extends PostInstallScriptBaseBatch {

    global ORDUAndUPCTaxableCostBatch() {
        this.scriptName = 'executeORDUAndUPCTaxableCostBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id, Total_Cost__c from Customer_Owned_Unit__c WHERE Unit_Type__c = \'ORDU\' AND Taxable_Cost__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> orduList) {
        for(Customer_Owned_Unit__c ordu : (List<Customer_Owned_Unit__c>) orduList) {
            ordu.Taxable_Cost__c = ordu.Total_Cost__c != null ? ordu.Total_Cost__c : 0;
        }
        List<Unit_Price_Cost__c> upcUpdateList = [Select Id FROM Unit_Price_Cost__c WHERE Customer_Owned_Unit__c IN :orduList];
        for(Unit_Price_Cost__c upc : upcUpdateList) {
            upc.Taxable__c = true;
        }
        DMLUtility.updateSobjectListWithRetry(upcUpdateList);
        DMLUtility.updateSobjectListWithRetry(orduList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
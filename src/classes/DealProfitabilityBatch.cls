/**
 * Author: Nidhi Sharma
 * Since: Oct 06, 2023
 * Name: DealProfitabilityBatch
 * Description: 
**/
global without sharing class DealProfitabilityBatch extends PostInstallScriptBaseBatch {

    global DealProfitabilityBatch() {
        this.scriptName = 'executeDealProfitabilityBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Invoice_Number__c, Total_Unit_Cost__c FROM Deal__c Where Invoice_Number__c != null AND Total_Unit_Cost__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealList) {
        for(Deal__c dealRec : (List<Deal__c>)dealList) {
            DealService.populateDealIndividualsCostTotalsAfterFinalize(dealRec.Invoice_Number__c);
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
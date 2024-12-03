/**
 * Author: Nidhi Sharma
 * Since: 09 October, 2024
 * Name: ORDUAddedOnDealResetBatch
**/
global without sharing class ORDUAddedOnDealResetBatch extends PostInstallScriptBaseBatch {

    global ORDUAddedOnDealResetBatch() {
        this.scriptName = 'executeORDUAddedOnDealResetBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id, (Select Id FROM Deals_Units_Junction__r WHERE Deal__r.Status__c != \'Quotation\' OR Customer_Owned_Unit__r.Status__c = \'Required\' LIMIT 1) from Customer_Owned_Unit__c WHERE Deal_Item__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> orduList) {
        List<Customer_Owned_Unit__c> orduUpdateList = new List<Customer_Owned_Unit__c>();
        for(Customer_Owned_Unit__c ordu: (List<Customer_Owned_Unit__c>) orduList) {
            if(!ordu.Deals_Units_Junction__r.isEmpty()) {
                ordu.Deal_Item__c = ordu.Deals_Units_Junction__r[0].Id;
                orduUpdateList.add(ordu);
            }
        }
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSObjectList('Customer_Owned_Unit__c', orduUpdateList);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
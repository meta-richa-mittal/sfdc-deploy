/** 
* Author: Manoj Sharma
* Since: Oct 25, 2024
* Name: RecalculateSOTaxesBatch 
* Description: Apex class to recalculate univoiced service job taxes.
**/
global without sharing class RecalculateSOTaxesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Service_Order_Header__c WHERE Transaction_Type__r.Type__c != \'Customer\' AND Invoice_Number__c = null ';
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<Service_Order_Header__c> soHeaderList) {
        CORecalculationWrapper recalculationObj = new CORecalculationWrapper();
        recalculationObj.COHeaderId = null;
        recalculationObj.CustomerId = null;
        recalculationObj.IsRecalculateTaxes = true;
        recalculationObj.IsResetPricing = false;

        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            recalculationObj.SOHeaderId = soHeaderRec.Id;
            ServiceJobService.refreshSOPricingAndTax(System.JSON.serialize(recalculationObj));
        }
    }

    global void finish(Database.batchableContext bc) {
        Database.executeBatch(new RecalculateCOTaxesBatch(), 1);
    }
}
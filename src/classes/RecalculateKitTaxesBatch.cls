/** 
* Author: Manoj Sharma
* Since: Oct 25, 2024
* Name: RecalculateKitTaxesBatch 
* Description: Apex class to recalculate univoiced kit taxes.
**/
global without sharing class RecalculateKitTaxesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Customer__c FROM CO_Header__c WHERE Order_status__c = \'Open\' ';
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderList) {
        CORecalculationWrapper recalculationObj = new CORecalculationWrapper();
        recalculationObj.SOHeaderId = null;
        recalculationObj.IsRecalculateTaxes = true;
        recalculationObj.IsResetPricing = false;

        for(CO_Header__c coHeaderRec : coHeaderList) {
            recalculationObj.COHeaderId = coHeaderRec.Id;
            recalculationObj.CustomerId = coHeaderRec.Customer__c;
            COService.refreshCOPricingAndTaxOnKit(System.JSON.serialize(recalculationObj));
        }
    }

    global void finish(Database.batchableContext bc) {}
}

/** 
* Author: Manoj Sharma
* Since: Oct 25, 2024
* Name: RecalculateCOTaxesBatch 
* Description: Apex class to recalculate open CO taxes.
**/
global without sharing class RecalculateCOTaxesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
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
            COService.refreshCOPricingAndTax(System.JSON.serialize(recalculationObj));
            COService.addInternalCommentToCO(recalculationObj.COHeaderId, 'BP Admin recalculated the taxes on this CO.');
        }
    }

    global void finish(Database.batchableContext bc) {
        Database.executeBatch(new RecalculateKitTaxesBatch(), 1);
    }
}
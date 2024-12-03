/*
    Apex class to sync unit price and costs with accounting server
*/
global without sharing class AccSync_UnitPriceAndCost_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Unit_Price_Cost__c> unitPriceAndCostListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Unit_Price_Cost__c> listUnitPriceAndCosts) {}
 
    global void finish(Database.batchableContext bc){}
}
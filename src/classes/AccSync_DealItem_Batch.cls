/*
    Apex class to sync trade in journal entry with accounting server
*/
global without sharing class AccSync_DealItem_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Deal_Item__c> dealItemListToUpdate;
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Deal_Item__c> listDealItems) {}
 
    global void finish(Database.batchableContext bc) {}
}
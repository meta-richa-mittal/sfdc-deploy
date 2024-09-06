/*
    Apex class to sync Store Credit with accounting server
*/
global without sharing class AccSync_StoreCreditJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Store_Credit__c> StoreCreditListToUpdate; 
    global List<Log__c> errorLogToInsert;

    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Store_Credit__c> listStoreCredits) {} 
 
    global void finish(Database.batchableContext bc){}
}
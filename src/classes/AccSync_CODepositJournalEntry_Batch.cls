/*
    Apex class to sync CO Deposit with accounting server
*/
global without sharing class AccSync_CODepositJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, 
             Database.Stateful {

    global List<CO_Deposit__c> CODepositListToUpdate; 
    global List<Log__c> errorLogToInsert;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<CO_Deposit__c> listCODeposits) {} 
 
    global void finish(Database.batchableContext bc) {}
}
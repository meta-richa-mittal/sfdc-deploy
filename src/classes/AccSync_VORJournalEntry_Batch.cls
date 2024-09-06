global without sharing class AccSync_VORJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Vendor_Receiving_Header__c> VORListToUpdate;  
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Vendor_Receiving_Header__c> listVORs) {}  
 
    global void finish(Database.batchableContext bc) {}
}
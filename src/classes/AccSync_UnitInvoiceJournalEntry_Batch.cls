global without sharing class AccSync_UnitInvoiceJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Customer_Owned_Unit__c> unitListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listCOUs) {}  
 
    global void finish(Database.batchableContext bc){}
}
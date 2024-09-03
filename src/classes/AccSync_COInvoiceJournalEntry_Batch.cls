global without sharing class AccSync_COInvoiceJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    global List<CO_Invoice_Header__c> customerInvoiceListToUpdate; 
    global List<Log__c> errorLogToInsert;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> listCustomerInvoices) {}  
 
    global void finish(Database.batchableContext bc){}
}
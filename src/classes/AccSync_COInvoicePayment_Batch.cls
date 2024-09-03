/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_COInvoicePayment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {

    global List<CO_Invoice_Payment__c> COInvoicePaymentListToUpdate;  
    global List<Log__c> errorLogToInsert;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Payment__c> listCOInvoicePayments) {} 
 
    global void finish(Database.batchableContext bc) {}
}
/*
    Apex class to sync Payment on Account with accounting server
*/
global without sharing class AccSync_ARPayment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Payment_on_Account__c> paymentOnAccountListToUpdate; 
    global List<Log__c> errorLogToInsert;   
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Payment_on_Account__c> paymentOnAccountList) {
        
    }  
 
    global void finish(Database.batchableContext bc) {
        
    }
}
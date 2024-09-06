/*
    Apex class to sync customer with accounting server
*/

global without sharing class AccSync_Customer_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, 
             Database.Stateful {
    global List<Account> accountListToUpdate;
    global List<Log__c> errorLogToInsert;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Account> listCustomers) {}
 
    global void finish(Database.batchableContext bc) {}
}
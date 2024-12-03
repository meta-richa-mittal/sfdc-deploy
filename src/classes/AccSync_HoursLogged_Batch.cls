/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_HoursLogged_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Hours_Logged__c> hoursLoggedListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Hours_Logged__c> hoursLoggedList) {}  
 
    global void finish(Database.batchableContext bc) {}
}
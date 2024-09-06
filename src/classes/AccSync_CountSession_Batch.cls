/*
    Apex class to sync Count Session with accounting server
*/
global without sharing class AccSync_CountSession_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Count_Session__c> countSessionListToUpdate; 
    global List<Log__c> errorLogToInsert;   
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Count_Session__c> countSessionList) {}  
 
    global void finish(Database.batchableContext bc) {}
}
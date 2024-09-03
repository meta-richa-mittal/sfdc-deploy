/*
    Apex class to sync part category with accounting server
*/
global without sharing class AccSync_PartCategory_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Part__c> partListToUpdate;
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> listParts) {}  
 
    global void finish(Database.batchableContext bc) {}
}
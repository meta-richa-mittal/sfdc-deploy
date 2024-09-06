global without sharing class AccSync_UnitConsignment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Customer_Owned_Unit__c> consUnitListToUpdate;
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listConsUnits) {}
 
    global void finish(Database.batchableContext bc) {}
}
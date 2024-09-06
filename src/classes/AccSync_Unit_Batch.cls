/**
 * Author: Richa Mittal
 * Since: Dec. 14, 2017
 * Name: AccSync_Unit_Batch
 * Description: Batch for AccSync Unit (QB Integration)
**/
global without sharing class AccSync_Unit_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Customer_Owned_Unit__c> COUListToUpdate;  
    global List<Log__c> errorLogToInsert;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listCOUs) {}
    
    global void finish(Database.batchableContext bc){}
}
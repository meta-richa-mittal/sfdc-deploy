/**
 * Author: Nidhi Sharma
 * Since: Nov 11, 2022
 * Name: AccSync_RVOVarianceJE_Batch
 * Description: Batch for RVO Variance JE (QB Integration)
**/
global without sharing class AccSync_RVOVarianceJE_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    global List<Return_VO_Header__c> rvoListToUpdate; 
    global List<Log__c> errorLogToInsert;
    
     
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Return_VO_Header__c> rvoList) {}  
 
    global void finish(Database.batchableContext bc) {}
    
}
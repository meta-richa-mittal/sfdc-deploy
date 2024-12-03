/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_FIFOBucket_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Part_FIFO_Bucket__c> partFIFOBucketListToUpdate; 
    global List<Log__c> errorLogToInsert;   
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null; 
    }
    
    global void execute(Database.batchableContext bc, List<Part_FIFO_Bucket__c> listPartFIFOBuckets) {}   
 
    global void finish(Database.batchableContext bc) {}
}
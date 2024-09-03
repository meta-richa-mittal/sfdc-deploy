/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_FIFOBucketActivityLineItem_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketActivityLineItemListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Part_FIFO_Bucket_Activity_Line_Item__c> listPartFIFOBucketActivityLineItems) {}  
 
    global void finish(Database.batchableContext bc) {}
}
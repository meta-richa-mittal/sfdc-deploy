/**
 * Author: Hitesh Gupta
 * Since: Oct 11, 2017
 * Name: AccSync_VendorReturn_Batch
 * Description: Batch for AccSync Vendor Return (QB Integration)
**/
global without sharing class AccSync_VendorReturn_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Return_VO_Header__c> RVOHeaderListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Return_VO_Header__c> listRVOHeaders) {}  
 
    global void finish(Database.batchableContext bc){}
}
/**
 * Author: Richa Mittal
 * Since: Apr 25, 2022
 * Name: QBVIVarianceJEService
 * Description: Batch for VI Variance JE (QB Integration)
**/
global without sharing class AccSync_VIVarianceJE_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Vendor_Invoicing_Header__c> viHeaderListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Vendor_Invoicing_Header__c> viHeaderList) {}  
 
    global void finish(Database.batchableContext bc){}
}
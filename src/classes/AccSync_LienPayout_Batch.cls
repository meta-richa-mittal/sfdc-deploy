/**
 * Author: Pooja Khandelwal
 * Since: Nov. 26, 2018
 * Name: AccSync_LienPayout_Batch
 * Description: Batch for AccSync Lien Payout (QB Integration)
**/
global without sharing class AccSync_LienPayout_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Deal_Item__c> dealItemListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Deal_Item__c> listdealItems) {}  
 
    global void finish(Database.batchableContext bc){}
}
/* 
    Not used. Instead of this new batch class is created "SyncVendorReturnCreditBatch"
*/
global without sharing class SyncVOReturnBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) { return null; }
    
    global void execute(Database.batchableContext bc, List<Return_VO_Header__c> voReturnList) {}
    
    global override void finish(Database.batchableContext bc) {}
}
/**
 * Author: Nidhi Sharma
 * Since: Nov 10, 2022
 * Name: SyncRVOVarianceJEBatch
 * Description: Not used. Instead of this new batch class is created "SyncReturnCRVarianceJEBatch"
**/
global without sharing class SyncRVOVarianceJEBatch extends BaseSyncingBatch { 
    
    global override Database.QueryLocator start(Database.BatchableContext bc) { return null; }
    
    global void execute(Database.batchableContext bc, List<Return_VO_Header__c> voReturnList) {}
  
    global override void finish(Database.batchableContext bc) {}
}
/**
 * Author: Richa Mittal
 * Since: Jun. 13, 2018
 * Name: AccSync_PartCategory_Batch_Scheduler
 * Description: Scheduler class for AccSync_PartCategory_Batch
**/
global without sharing class AccSync_PartCategory_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_PartCategory_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
    global void execute(SchedulableContext sc) {}
}
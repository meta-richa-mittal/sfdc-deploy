/**
 * Author: Pooja Khandelwal
 * Since: Dec. 26, 2016
 * Name: AccSync_Customer_Batch_Scheduler
 * Description: Scheduler class for AccSync_Customer_Batch
**/
global without sharing class AccSync_Customer_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_Customer_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
    global void execute(SchedulableContext sc) {}
}
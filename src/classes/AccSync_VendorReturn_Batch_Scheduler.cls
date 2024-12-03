/**
 * Author: Tarun Khandelwal
 * Since: May 22, 2018
 * Name: AccSync_VendorReturn_Batch_Scheduler
 * Description: Scheduler class for AccSync_VendorReturn_Batch
**/
global without sharing class AccSync_VendorReturn_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_VendorReturn_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
    global void execute(SchedulableContext sc) {}
}
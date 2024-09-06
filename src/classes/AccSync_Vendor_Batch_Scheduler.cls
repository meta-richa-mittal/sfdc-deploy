/**
 * Author: Richa Mittal
 * Since: Dec 26, 2016
 * Name: AccSync_Vendor_Batch_Scheduler
 * Description: Apex class to schedule AccSync_Vendor_Batch.
**/
global class AccSync_Vendor_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_Vendor_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize) {}
    
	global void execute(SchedulableContext SC) {}
}
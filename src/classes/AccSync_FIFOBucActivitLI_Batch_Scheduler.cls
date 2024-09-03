/**
 * Author: Richa Mittal
 * Since: Jan 18, 2017
 * Name: AccSync_FIFOBucActivitLI_Batch_Scheduler
 * Description: Apex class to schedule AccSync_FIFOBucketActivityLineItem_Batch.
**/
global class AccSync_FIFOBucActivitLI_Batch_Scheduler implements Schedulable {
	global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_FIFOBucActivitLI_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
    global void execute(SchedulableContext sc) {}
}
/**
 * Author: Richa Mittal
 * Since: Aug 24, 2017
 * Name: AccSync_StoreCreditJE_Batch_Scheduler
 * Description: Apex class to schedule AccSync_StoreCreditJE_Batch_Scheduler.
**/
global class AccSync_StoreCreditJE_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_StoreCreditJE_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
	global void execute(SchedulableContext SC) {}
}
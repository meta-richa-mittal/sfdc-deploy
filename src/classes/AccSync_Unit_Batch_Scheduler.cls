/**
 * Author: Richa Mittal
 * Since: Jan 19, 2017
 * Name: AccSync_Unit_Batch_Scheduler
 * Description: Apex class to schedule AccSync_Unit_Batch_Scheduler.
**/
global class AccSync_Unit_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_Unit_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}
    
	global void execute(SchedulableContext SC) {}
}
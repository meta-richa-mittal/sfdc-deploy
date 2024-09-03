/**
 * Author: Richa Mittal
 * Since: Jan 18, 2017
 * Name: AccSync_VORJournalEntry_Batch_Scheduler
 * Description: Apex class to schedule AccSync_VORJournalEntry_Batch.
**/
global class AccSync_VORJournalEntry_Batch_Scheduler implements Schedulable {
    
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_VORJournalEntry_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){
        this.recordIdSet = recordIdSet;
        this.batchSize = batchSize;
    }
    
    global void execute(SchedulableContext SC) {
        
    }
}
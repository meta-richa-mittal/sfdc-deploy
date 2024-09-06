/**
 * Author: Richa Mittal
 * Since: Jan 19, 2017
 * Name: AccSync_CODepositJE_Batch_Scheduler
 * Description: Apex class to schedule AccSync_CODepositJournalEntry_Batch.
**/
global class AccSync_CODepositJE_Batch_Scheduler implements Schedulable {
    
    global Set<Id> recordIdSet;
    global Integer batchSize;
    global Set<Id> alreadyRequestedAccountIdSet;  
    
    global AccSync_CODepositJE_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize){}

    global AccSync_CODepositJE_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize, Set<Id> alreadyRequestedAccountIdSet){}
    
    global void execute(SchedulableContext SC) {}
}
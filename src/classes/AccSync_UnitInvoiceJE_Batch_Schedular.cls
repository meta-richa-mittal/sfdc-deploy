/**
 * Author: Nidhi Sharma
 * Since: Sept 07, 2019
 * Name: AccSync_UnitInvoiceJE_Batch_Schedular
 * Description: Apex class to schedule AccSync_UnitInvoiceJournalEntry_Batch.
**/
global class AccSync_UnitInvoiceJE_Batch_Schedular implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_UnitInvoiceJE_Batch_Schedular(Set<Id> recordIdSet, Integer batchSize) {}
    
    global void execute(SchedulableContext sc) {}
}
/**
 * Author: Tarun Khandelwal
 * Since: May 21, 2018
 * Name: AccSync_COInvoiceJournalEntry_Batch_Sch
 * Description: Apex class to schedule AccSync_COInvoiceJournalEntry_Batch.
**/
global class AccSync_COInvoiceJournalEntry_Batch_Sch implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_COInvoiceJournalEntry_Batch_Sch(Set<Id> recordIdSet, Integer batchSize) {}
    
    global void execute(SchedulableContext sc) {}
}
/**
 * Author: Nidhi Sharma
 * Since: Sept 07, 2019
 * Name: AccSync_UnitInvoiceJE_Batch_Schedular
 * Description: Apex class to schedule AccSync_UnitInvoiceJournalEntry_Batch.
**/
global class AccSync_UnitInvoiceJE_Batch_Schedular implements Schedulable {
    
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_UnitInvoiceJE_Batch_Schedular(Set<Id> recordIdSet, Integer batchSize) {
        this.recordIdSet = recordIdSet;
        this.batchSize = batchSize;
    }
    
    global void execute(SchedulableContext sc) {
        AccSync_UnitInvoiceJournalEntry_Batch clsAccSyncBatch = new AccSync_UnitInvoiceJournalEntry_Batch();
        clsAccSyncBatch.setUnitIds = recordIdSet;
        system.debug('Invoice for AccSync_UnitInvoiceJournalEntry_Batch' + clsAccSyncBatch.setUnitIds);
        Database.executebatch(clsAccSyncBatch, batchSize);
    }
}
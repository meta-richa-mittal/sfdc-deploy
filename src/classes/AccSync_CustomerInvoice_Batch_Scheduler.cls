/**
 * Author: Pooja Khandelwal
 * Since: Dec. 26, 2016
 * Name: AccSync_CustomerInvoice_Batch_Scheduler
 * Description: Scheduler class for AccSync_CustomerInvoice_Batch
**/
global without sharing class AccSync_CustomerInvoice_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_CustomerInvoice_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize) {}
    
    global AccSync_CustomerInvoice_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize, Boolean updateCOInvoice) {}
    
    global void execute(SchedulableContext sc) {}
}
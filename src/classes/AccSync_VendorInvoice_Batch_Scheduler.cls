/**
 * Author: Richa Mittal
 * Since: Jan 19, 2017
 * Name: AccSync_VendorInvoice_Batch_Scheduler
 * Description: Apex class to schedule AccSync_VendorInvoice_Batch.
**/
global class AccSync_VendorInvoice_Batch_Scheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global Integer batchSize;
    
    global AccSync_VendorInvoice_Batch_Scheduler(Set<Id> recordIdSet, Integer batchSize) {}
    
	global void execute(SchedulableContext SC) {}
}
/**
 * Author: Balveer Choudhary
 * Since: Auguest 03, 2022
 * Name: SetQtyAndAvgCostOnFIFOBktAndLIQueueable
 * Description: Batch for Populating fields on part and vendor
**/
global without sharing class SetQtyAndAvgCostOnFIFOBktAndLIQueueable implements Queueable {
	
	public Set<String> recordIds;

	global SetQtyAndAvgCostOnFIFOBktAndLIQueueable(Set<String> recordIdSet) {
	    recordIds = recordIdSet;
	}

    global void execute(QueueableContext context) {
        if(recordIds.size() <= 0) return;
        Database.executeBatch(new SetQtyAndAvgCostOnFIFOBktAndLIBatch(recordIds), 100);
    }
}
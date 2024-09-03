/**
 * Author: Nidhi Sharma
 * Since: Sept 12, 2018
 * Name: SetQtyAndAvgCostOnFIFOBktAndLIBatch
 * Description: Batch for Populating fields on part and vendor
 * This is calling from queueable to avaoid Too many DML rows: 10001 - #18892
**/
global without sharing class SetQtyAndAvgCostOnFIFOBktAndLIBatch implements Database.Batchable<sobject> {
	
	private Set<String> recordIds;
	global Boolean isTriggerDisabled = false;
	global SetQtyAndAvgCostOnFIFOBktAndLIBatch() {}

	global SetQtyAndAvgCostOnFIFOBktAndLIBatch(Set<String> recordIdSet) {
	    recordIds = recordIdSet;
	}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String partStrQuery = 'SELECT Id FROM Part__c';
        if(recordIds != null && recordIds.size() > 0) {
            partStrQuery += ' Where Id IN: recordIds';
        }
        partStrQuery += ' Order By CreatedDate ASC';
	    return Database.getQueryLocator(partStrQuery);
	}
	
    global void execute(Database.batchableContext bc, List<sObject> scope) {
        List<Part__c> partList = [SELECT Id, (Select Id, CreatedDate, Cost__c, Qty_In__c, Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c FROM Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true Order By CreatedDate ASC) FROM Part__c WHERE Id IN :scope];
    	FIFOTransaction.updatePartFIFODetails(partList);
    }
    
    global void finish(Database.batchableContext bc) {}
}
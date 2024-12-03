/**
 * Author: Richa Mittal
 * Since: Jan 09, 2017
 * Name: PartFIFOBucketActivityLineItemTrigger
 * Description: Trigger executes on before insert and after insert events of Part_FIFO_Bucket_Activity_Line_Item__c object
**/
trigger PartFIFOBucketActivityLineItemTrigger on Part_FIFO_Bucket_Activity_Line_Item__c (before insert, after insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLINewList = Trigger.new;
    FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLIOldList = Trigger.old;
    FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLINewMap = Trigger.newMap;
    FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLIOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PartFIFOBucketActivityLineItemTrigger');

    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
    	FIFOBucketActivityLineItemTriggerHelper.populatePartOnFIFOBucketActivityLI();
    }
    if(Trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	FIFOBucketActivityLineItemTriggerHelper.populateInStockWhenCreated();	
    }
    	
    if(system.isBatch()) {
    	return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
    	FIFOBucketActivityLineItemTriggerHelper.populatesAccountingSyncFields();
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) { 
        if(!System.isFuture()) {
        	FIFOBucketActivityLineItemTriggerHelper.setPartFIFOBucketActivityLIDataForAccountSync();
    	}
    }
}
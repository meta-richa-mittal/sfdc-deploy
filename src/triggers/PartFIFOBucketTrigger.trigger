trigger PartFIFOBucketTrigger on Part_FIFO_Bucket__c (after insert, after update, before insert, before update, after delete) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
	PartFIFOBucketTriggerHelper.partFIFOBucketNewList = Trigger.new;
    PartFIFOBucketTriggerHelper.partFIFOBucketOldList = Trigger.old;
    PartFIFOBucketTriggerHelper.partFIFOBucketNewMap = Trigger.newMap;
    PartFIFOBucketTriggerHelper.partFIFOBucketOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PartFIFOBucketTrigger');

    if(Trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	PartFIFOBucketTriggerHelper.populateInStockWhenCreated();
    }
	
    if(Trigger.isBefore) {
        if(!system.isBatch() && trigger.isInsert && !utilObj.insertDisabled()) { //  || Trigger.isUpdate Changed 25/01/2017
            PartFIFOBucketTriggerHelper.populatesAccountingSyncFields();
        }
    }
    
    if(Trigger.isAfter) { 
        if(trigger.isInsert && !utilObj.insertDisabled()) {
	    	PartFIFOBucketTriggerHelper.afterInsertCalculation();
	    	if(!(system.isBatch() || PartFIFOBucketTriggerHelper.preventOnAccountingSync || System.isFuture())){
		    	PartFIFOBucketTriggerHelper.preventOnAccountingSync = true;
	            PartFIFOBucketTriggerHelper.setPartFIFOBucketDataForAccountSync();
	    	}
	    }
        if(trigger.isUpdate && !utilObj.updateDisabled()) {
	    	PartFIFOBucketTriggerHelper.afterUpdateCalculation();
	    }
        if(trigger.isDelete && !utilObj.deleteDisabled()) {
	    	PartFIFOBucketTriggerHelper.afterDeleteCalculation();
	    }
    }
}
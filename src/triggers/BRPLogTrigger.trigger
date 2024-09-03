trigger BRPLogTrigger on BRP_Log__c (after insert, before insert, before update) {
	
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('BRPLogTrigger');

	if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) { 
        BRPLogTriggerHelper.afterInsert(trigger.new);
   	}  
}
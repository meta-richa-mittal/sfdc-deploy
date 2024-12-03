trigger DealTrigger on Deal__c (after insert, before insert, before update, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(DealTriggerHelper.isForceStopTrigger) {
        return;
    }
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('DealTrigger');

	if(Trigger.isInsert && Trigger.isAfter && !utilObj.insertDisabled()) {
        DealTriggerHelper.onAfterInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        DealTriggerHelper.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isUpdate && Trigger.isAfter && !utilObj.updateDisabled() && !system.isBatch()) {
        DealTriggerHelper.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isDelete && Trigger.isAfter && !utilObj.deleteDisabled()) {
    	DealTriggerHelper.onAfterDelete(Trigger.old);
    }
}
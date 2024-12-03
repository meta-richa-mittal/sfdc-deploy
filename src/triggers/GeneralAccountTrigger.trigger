trigger GeneralAccountTrigger on General_Account__c (after update, after delete, before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('GeneralAccountTrigger');

    if(trigger.isAfter) {
        if(trigger.isUpdate && !utilObj.updateDisabled()) {
            GeneralAccountTriggerHelper.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if(trigger.isDelete && !utilObj.deleteDisabled()) {
            GeneralAccountTriggerHelper.afterDelete(Trigger.old, Trigger.oldMap);
        }
    }
}
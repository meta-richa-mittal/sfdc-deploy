trigger TechnicianTrigger on Technician__c (after update, before insert, before update) {

    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
        if(!BPTriggerHandler.isExecuteTrigger) {
			return;
		}
    }

    if(trigger.isAfter && trigger.isUpdate) {
        TechnicianTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
    }
}
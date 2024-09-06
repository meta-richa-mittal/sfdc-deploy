/**
 * Author: Nidhi Sharma
 * Since: November 11, 2020
 * Name: EventTrigger
 * Description: trigger on Event object
**/
trigger EventTrigger on Event__c (before insert, before update, after delete, before delete) {
	
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    if(EventTriggerHelper.isForceStopTrigger) {
    	return;
    }
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('EventTrigger');

	if(Trigger.isBefore) {
		if(Trigger.isInsert && !utilObj.insertDisabled()){
			EventTriggerHelper.beforeInsertOperation(Trigger.new);
		} else if(Trigger.isUpdate && !utilObj.updateDisabled()) {
			EventTriggerHelper.beforeUpdateOperation(Trigger.new, Trigger.newMap, Trigger.oldMap);
		} else if(Trigger.isDelete && !utilObj.deleteDisabled()) {
			EventTriggerHelper.beforeDeleteOperation(Trigger.old);
		}
	}

	if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
        EventTriggerHelper.afterDelete(trigger.old);
    }
}
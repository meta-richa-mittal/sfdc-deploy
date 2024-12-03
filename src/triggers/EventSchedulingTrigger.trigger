/**
 * Author: Nidhi Sharma
 * Since: Feb 26, 2021
 * Name: EventSchedulingTrigger
 * Description: Trigger executes on Event_Scheduling__c object
**/
trigger EventSchedulingTrigger on Event_Scheduling__c (after delete, after insert, after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(EventSchedulingTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('EventSchedulingTrigger');

    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
        EventSchedulingTriggerHelper.afterInsert(trigger.new);
    }
    
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
    	EventSchedulingTriggerHelper.afterUpdate(trigger.oldMap, trigger.new);
    }
    
    if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
        EventSchedulingTriggerHelper.afterDelete(trigger.old);
    }
}
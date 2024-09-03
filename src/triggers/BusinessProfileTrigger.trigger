/**
 * Author: Nidhi Sharma
 * Since: April 10, 2023
 * Name: BusinessProfileTrigger
 * Description: Trigger executes on event of Business_Profile__c object
**/
trigger BusinessProfileTrigger on Business_Profile__c (after insert, after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(BusinessProfileTriggerHelper.isForceStopTrigger) {
    	return;
    }

    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('BusinessProfileTrigger');
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
        BusinessProfileTriggerHelper.afterInsert(trigger.new);
    }
    
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
        BusinessProfileTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
    }
}
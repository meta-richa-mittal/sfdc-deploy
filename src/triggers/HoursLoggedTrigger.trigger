/**
 * Author: Tarun Khandelwal
 * Since: June 07, 2019
 * Name: HoursLoggedTrigger
 * Description: Trigger for Hours Logged object
**/
trigger HoursLoggedTrigger on Hours_Logged__c (before insert, after insert, before update, after update, before delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(HoursLoggedTriggerHelper.isForceStopTrigger) {
        return;
    }
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('HoursLoggedTrigger');

    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) { 
        HoursLoggedTriggerHelper.beforeInsert(trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) { 
        HoursLoggedTriggerHelper.beforeUpdate(trigger.new, trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) { 
        HoursLoggedTriggerHelper.afterInsert(trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) { 
        HoursLoggedTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
    }
	if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()) { 
        HoursLoggedTriggerHelper.beforeDelete(trigger.old);
    }
}
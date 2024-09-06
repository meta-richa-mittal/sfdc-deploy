/**
 * Author: Nidhi Sharma
 * Since: Sept 10, 2019
 * Name: CountSessionTrigger
 * Description: 
**/
trigger CountSessionTrigger on Count_Session__c (before insert, before update, after update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(CountSessionTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CountSessionTrigger');

    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        CountSessionTriggerHelper.populatesAccountingSyncFields(trigger.new, trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        CountSessionTriggerHelper.setCountSessionDataForAccountingSync(trigger.new);
    }
}
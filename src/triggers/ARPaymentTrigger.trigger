/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: ARPaymentTrigger
 * Description: Trigger executes on after trigger events of AR payment object
**/
trigger ARPaymentTrigger on AR_Payment__c (before insert, after insert, before update) {

    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
	if(ARPaymentTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ARPaymentTrigger');

    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) { 
        ARPaymentTriggerHelper.beforeInsert(trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) { 
        ARPaymentTriggerHelper.afterInsert(trigger.new);
    }
}
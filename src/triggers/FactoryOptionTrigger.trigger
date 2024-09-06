/**
 * Author: Nidhi Sharma
 * Since: January 04, 2021
 * Name: FactoryOptionTrigger
 * Description: Factory Option trigger
**/
trigger FactoryOptionTrigger on Factory_Option__c (before insert, before update) {
    
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
    if(FactoryOptionTriggerHelper.isForceStopTrigger) return;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('FactoryOptionTrigger');

    if(trigger.isBefore) {
    	if(trigger.isInsert) {
    		FactoryOptionTriggerHelper.beforeInsert(trigger.new);
    	} else if(trigger.isUpdate) {
    		FactoryOptionTriggerHelper.beforeUpdate(trigger.new);
    	}
    }
}
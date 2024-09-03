/**
 * Author: Richa Mittal
 * Since: July 18, 2019
 * Name: PaymentOnAccountTrigger
 * Description: Trigger executes on after trigger events of Payment on Account object
**/
trigger PaymentOnAccountTrigger on Payment_on_Account__c (after insert, before insert, after update, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(PaymentOnAccountTriggerHelper.isForceStopTrigger) {
    	return;
    }
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PaymentOnAccountTrigger');
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert && !utilObj.insertDisabled()) {
            PaymentOnAccountTriggerHelper.beforeInsert(trigger.new);
        }

        if(Trigger.isUpdate && !utilObj.updateDisabled()) {
            PaymentOnAccountTriggerHelper.beforeUpdate(trigger.new, trigger.oldMap);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert && !utilObj.insertDisabled()) {
            PaymentOnAccountTriggerHelper.afterInsert(trigger.new);
        }

        if(Trigger.isUpdate && !utilObj.updateDisabled()) {
            PaymentOnAccountTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
        }
    }
}
trigger COSalespersonTrigger on CO_Salesperson__c (after insert, after update, after delete, before insert, before update) {

    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(COSalespersonTriggerHelper.isForceStopTrigger) {return;}

    if(trigger.isAfter && trigger.isInsert) {
        COSalespersonTriggerHelper.afterInsert(trigger.new);
    }

    if(trigger.isAfter && trigger.isUpdate) {
        COSalespersonTriggerHelper.afterInsert(trigger.new);
    }

    if(trigger.isAfter && trigger.isDelete) {
        COSalespersonTriggerHelper.afterInsert(trigger.old);
    }
}
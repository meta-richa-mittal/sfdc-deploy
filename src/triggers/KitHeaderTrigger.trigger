/**
 * Author: Ashish Garg
 * Since: Dec. 1,
 * Name: KitHeaderTrigger
 * Description: Trigger executes on before insert, before update event of Kit Header object
**/
trigger KitHeaderTrigger on Kit_Header__c (before insert, before update, after insert, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    KitHeaderTriggerHelper.KHNewList    = Trigger.new;
    KitHeaderTriggerHelper.KHOldList    = Trigger.old;
    KitHeaderTriggerHelper.KHNewMap     = Trigger.newMap;
    KitHeaderTriggerHelper.KHOldMap     = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('KitHeaderTrigger');

    if (Trigger.isBefore) {
        if (Trigger.isUpdate && !utilObj.updateDisabled()) {
            KitHeaderTriggerHelper.processBeforeUpdate();
        }
    }
}
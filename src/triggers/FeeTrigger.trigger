trigger FeeTrigger on Fee__c (after insert, after update, after delete , before insert, before update, before delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    FeeTriggerHelper.FeeNewList = Trigger.new;
    FeeTriggerHelper.FeeOldList = Trigger.old;
    FeeTriggerHelper.FeeOldMap = Trigger.oldMap;

    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('FeeTrigger');

    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            FeeTriggerHelper.beforeUpdate();
        } else if(Trigger.isDelete){
            FeeTriggerHelper.beforeDelete();
        }
    }
    
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            FeeTriggerHelper.afterUpdate();
        }
    }
}
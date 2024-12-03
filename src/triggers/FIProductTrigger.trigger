trigger FIProductTrigger on F_I_Product__c (before insert, before update, after insert, after update, after delete) {
     
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(FIProductTriggerHelper.isForceStopTrigger) {
        return;
    }

    // Initialize List and Maps
    FIProductTriggerHelper.FIProductNewList = Trigger.new;
    FIProductTriggerHelper.FIProductOldList = Trigger.old;
    FIProductTriggerHelper.FIProductNewMap = Trigger.newMap; 
    FIProductTriggerHelper.FIProductOldMap = Trigger.oldMap; 
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('FIProductTrigger');

    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
    	FIProductTriggerHelper.beforeInsertCalculation();
    }
    
    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()) {
    	FIProductTriggerHelper.beforeUpdateCalculation();
    }
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	FIProductTriggerHelper.afterInsertCalculation();
    }
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
    	FIProductTriggerHelper.afterUpdateCalculation();
    }
    if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
    	FIProductTriggerHelper.afterDeleteCalculation();
    }
}
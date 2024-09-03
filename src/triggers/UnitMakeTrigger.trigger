trigger UnitMakeTrigger on Unit_Make__c (before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('UnitMakeTrigger');
    
    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
        UnitMakeTriggerHelper.onBeforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        UnitMakeTriggerHelper.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
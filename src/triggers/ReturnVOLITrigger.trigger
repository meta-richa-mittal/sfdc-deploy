trigger ReturnVOLITrigger on Return_VO_Line_Item__c (before insert, before update, after delete, after insert, after update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    ReturnVOLITriggerHelper.returnVOLINewList = Trigger.new;
    ReturnVOLITriggerHelper.returnVOLIOldList = Trigger.old;
    ReturnVOLITriggerHelper.returnVOLINewMap = Trigger.newMap;
    ReturnVOLITriggerHelper.returnVOLIOldMap = Trigger.oldMap;
    
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ReturnVOLITrigger');
    
    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
    	//ReturnVOLITriggerHelper.beforeUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	ReturnVOLITriggerHelper.afterUpdateOperation();
    }
    
    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()) {
    	ReturnVOLITriggerHelper.beforeUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
    	ReturnVOLITriggerHelper.afterUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isDelete &&  !utilObj.deleteDisabled()) {
    	ReturnVOLITriggerHelper.beforeDeleteOperation();
    }
}
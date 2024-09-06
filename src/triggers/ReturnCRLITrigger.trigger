trigger ReturnCRLITrigger on Return_CR_Line_Item__c (before insert, before update, after delete, after insert, after update) {
    ReturnCRLITriggerHelper.returnCRLINewList = Trigger.new;
    ReturnCRLITriggerHelper.returnCRLIOldList = Trigger.old;
    ReturnCRLITriggerHelper.returnCRLINewMap = Trigger.newMap;
    ReturnCRLITriggerHelper.returnCRLIOldMap = Trigger.oldMap;
    
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ReturnCRLITrigger');
    
    
    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
    	//ReturnCRLITriggerHelper.beforeInsertOperation();
    }
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	ReturnCRLITriggerHelper.afterInsertOperation();
    }
    
    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()) {
    	//ReturnCRLITriggerHelper.beforeUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
    	ReturnCRLITriggerHelper.afterUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
    	ReturnCRLITriggerHelper.afterDeleteOperation();
    }
}
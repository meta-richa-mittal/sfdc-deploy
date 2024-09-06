/**
 * Author: Tarun Khandelwal
 * Since: March 27, 2014
 * Name: COTrigger
 * Description: Trigger executes on after update event of CO Hearder object
**/
trigger COTrigger on CO_Header__c (before insert, after insert, before update, after update, after delete) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    if(COTriggerHelper.isForceStopTrigger) {
        return;
    }
    
    COTriggerHelper.COHeaderNewList = Trigger.new;
    COTriggerHelper.COHeaderOldList = Trigger.old;
    COTriggerHelper.COHeaderNewMap = Trigger.newMap;
    COTriggerHelper.COHeaderOldMap = Trigger.oldMap;
    COTriggerHelper.isTriggerExecute = false;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('COTrigger');
    
    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
        COTriggerHelper.beforeInsertOperation();
    }
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
        COTriggerHelper.afterInsertOperation();
    }

    if(trigger.isBefore && trigger.isUpdate  && !utilObj.updateDisabled()) {
        COTriggerHelper.beforeUpdateOperation();
    }
    
    if(trigger.isAfter && trigger.isUpdate  && !utilObj.updateDisabled()) {
        COTriggerHelper.afterUpdateCalculation();
        COTriggerHelper.updateAccountFieldsOnAfterUpdate();
    }

    if(trigger.isAfter && trigger.isDelete  && !utilObj.deleteDisabled()) {       
        COTriggerHelper.afterDeleteOperation();
    }
    
}
/**
 * Author: Tarun Khandelwal
 * Since: Nov. 29, 2014
 * Name: PartTrigger
 * Description: Trigger executes on before insert, before update and before delete events of Part object
**/
trigger PartTrigger on Part__c (before insert, after insert, before update, after update, before delete, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    if(Trigger.isBefore && Trigger.isUpdate) {
        PartTriggerHelper.setLastPriceUpdate(Trigger.new, Trigger.oldMap);
    }

    if(PartTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    PartTriggerHelper.PartNewList = Trigger.new;
    PartTriggerHelper.PartOldList = Trigger.old;
    PartTriggerHelper.PartNewMap = Trigger.newMap;
    PartTriggerHelper.PartOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PartTrigger');
    
    if(PartTriggerHelper.isDisableTriggerForSetQtyAndAvgCostOnFIFOBktAndLIBatch) {
    	return;	
    }
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            if(!utilObj.insertDisabled()) {
            PartTriggerHelper.populateDefaults();
            PartTriggerHelper.beforeInsert();
            }
            PartTriggerHelper.setSOMDefaultPartIndex();
        } else if(Trigger.isUpdate && !utilObj.updateDisabled()) {
             PartTriggerHelper.populateDefaults();
             PartTriggerHelper.setIntextDefaultPartIndex();
             if(!(system.isBatch() || System.isFuture() || PartTriggerHelper.preventOnAccountingSync)) {
                 PartTriggerHelper.populatesAccountingSyncFields();
             }
             PartTriggerHelper.beforeUpdate();
        } else if(Trigger.isDelete) {
            PartTriggerHelper.validatePartDeletion();   //Validate part deletion irrespective of trigger ON/Off
        }
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isUpdate && !utilObj.updateDisabled() && !PartTriggerHelper.isPreventOnDataLoad) {
        	PartTriggerHelper.afterUpdate();
        }
        
        if(Trigger.isInsert && !utilObj.insertDisabled()) {
        	PartTriggerHelper.AfterInsertOperation();
        }
    }
}
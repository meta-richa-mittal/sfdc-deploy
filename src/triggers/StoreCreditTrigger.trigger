/**
 * Author: Richa Mittal
 * Since: Aug 24, 2017
 * Name: StoreCreditTrigger
 * Description: Trigger executes on before insert and after insert events of Store_Credit__c object
**/
trigger StoreCreditTrigger on Store_Credit__c (after insert, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    StoreCreditTriggerHelper.StoreCreditNewList = Trigger.new;
    StoreCreditTriggerHelper.StoreCreditOldList = Trigger.old;
    StoreCreditTriggerHelper.StoreCreditNewMap = Trigger.newMap;
    StoreCreditTriggerHelper.StoreCreditOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('StoreCreditTrigger');

    if(system.isBatch()) {
    	return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
        StoreCreditTriggerHelper.populatesAccountingSyncFields();
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()){ 
    	if(!system.isFuture()){	
        	StoreCreditTriggerHelper.preventOnAccountingSync = true;
        	StoreCreditTriggerHelper.setStoreCreditDataForAccountSync();
    	}
    }
}
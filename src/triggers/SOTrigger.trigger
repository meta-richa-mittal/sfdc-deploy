/**
 * Author: Tarun Khandelwal
 * Since: March 08, 2016
 * Name: SOTrigger
 * Description: Trigger executes on after insert and after update events of SO Header object
**/
trigger SOTrigger on Service_Order_Header__c (before insert, after insert, before update, after update, before delete) {
	
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
	SOTriggerHelper.soHeaderNewList = Trigger.new;
	SOTriggerHelper.soHeaderOldList = Trigger.old;
	SOTriggerHelper.soHeaderNewMap = Trigger.newMap;
	SOTriggerHelper.soHeaderOldMap = Trigger.oldMap;
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('SOTrigger');

	if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()){
		SOTriggerHelper.forceValidationCheck();
	}

	if(SOTriggerHelper.isForceStopTrigger) {
    	return;
    }
	
	if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()){
		SOTriggerHelper.beforeInsertOperation();
	}

	if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()){
		SOTriggerHelper.afterInsertOperation();
	}
	
	if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()){
		SOTriggerHelper.beforeUpdateOperation();
	}
	
	if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()){
		SOTriggerHelper.afterUpdateInsertOperation();
	}
	
	if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()){
        SOTriggerHelper.beforeDeleteOperation();
    }
}
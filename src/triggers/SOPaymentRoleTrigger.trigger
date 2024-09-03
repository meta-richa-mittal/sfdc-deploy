/**
 * Author: Tarun Khandelwal
 * Since: May 31, 2016
 * Name: SOPaymentRoleTrigger
 * Description: Trigger executes on after insert and before delete events of SO_Payment_Role__c object
**/
trigger SOPaymentRoleTrigger on SO_Payment_Role__c (after insert, before delete, before insert, before update) {
	
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
	SOPaymentRoleTriggerHelper.soPaymentRoleNewList = Trigger.new;
	SOPaymentRoleTriggerHelper.soPaymentRoleOldList = Trigger.old;
	SOPaymentRoleTriggerHelper.soPaymentRoleNewMap = Trigger.newMap;
	SOPaymentRoleTriggerHelper.soPaymentRoleOldMap = Trigger.oldMap;
	SOPaymentRoleTriggerHelper.isTriggerRun = false;
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('SOPaymentRoleTrigger');

	if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
		SOPaymentRoleTriggerHelper.afterInsertOperation();
	}
	if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()) {
		SOPaymentRoleTriggerHelper.beforeDeleteOperation();
	}
}
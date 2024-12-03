/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: CashReconciliationTrigger
**/
trigger CashReconciliationTrigger on Cash_Reconciliation__c (before insert, before update, after update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    if(CashReconciliationTriggerHelper.isForceStopTrigger) {
    	return;
    }

    CashReconciliationTriggerHelper.CashReconNewList = Trigger.new;

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CashReconciliationTrigger');

    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        CashReconciliationTriggerHelper.afterUpdate();
    }
	
}
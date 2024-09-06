/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: TransactionTypeTrigger
**/
trigger TransactionTypeTrigger on Transaction_Type__c (before insert, before update) {
    TransactionTypeTriggerHelper.transTypeNewList = Trigger.new;
    TransactionTypeTriggerHelper.transTypeOldList = Trigger.old;
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('TransactionTypeTrigger');

    if(Trigger.isBefore && ((Trigger.isInsert && !utilObj.insertDisabled()) || (Trigger.isUpdate && !utilObj.updateDisabled()))) {
        TransactionTypeTriggerHelper.validateBeforeUpsert();
    }
	
}
/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: DealFinanceTrigger1
 * Description: DealFinanceTrigger trigger already exists which was deleted previously. Therefore created DealFinanceTrigger1
**/
trigger DealFinanceTrigger1 on Deal_Finance__c (before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('DealFinanceTrigger');

}
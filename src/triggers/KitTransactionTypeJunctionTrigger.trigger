/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: KitTransactionTypeJunctionTrigger
**/
trigger KitTransactionTypeJunctionTrigger on Kit_Transaction_Type_Junction__c (before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('KitTransactionTypeJunctionTrigger');

}
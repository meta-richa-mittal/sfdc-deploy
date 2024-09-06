/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: UserToGroupTrigger
**/
trigger UserToGroupTrigger on User_To_Group__c (before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('UserToGroupTrigger');
	
}
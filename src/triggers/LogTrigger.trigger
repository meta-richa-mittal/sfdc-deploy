/**
 * Author: Rajat Jain
 * Since: May 22, 2018
 * Name: LogTrigger
 * Description: Trigger executes after insert event of Log object
**/
trigger LogTrigger on Log__c (after insert, before insert, before update) {

    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(Trigger.isAfter && Trigger.isInsert) { 
        LogTriggerHelper.afterInsert(trigger.new);
   	}
}
/**
 * Author: Manoj Sharma
 * Since: Oct 27, 2020
 * Name: CountSessionLineItemTrigger
 * Description: 
**/
trigger CountSessionLineItemTrigger on Count_Session_Line_Item__c (before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(CountSessionLineItemTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CountSessionLineItemTrigger');

    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
        CountSessionLineItemTriggerHelper.beforeInsertCalculation(trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        CountSessionLineItemTriggerHelper.beforeUpdateCalculation(trigger.new);
    }
}
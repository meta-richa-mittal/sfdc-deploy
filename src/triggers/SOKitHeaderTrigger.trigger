/**
 * Author: Nidhi Sharma
 * Since: July 07, 2019
 * Name: SOKitHeaderTrigger
 * Description: Trigger executes on after insert event of SO Kit Header object
**/
trigger SOKitHeaderTrigger on Service_Order_Kit_Header__c (after insert, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(SOKitHeaderTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    // Initialize List and Maps
    SOKitHeaderTriggerHelper.soKitHeaderNewList = Trigger.new;
    SOKitHeaderTriggerHelper.soKitHeaderOldList = Trigger.old;
    SOKitHeaderTriggerHelper.soKitHeaderNewMap = Trigger.newMap;
    SOKitHeaderTriggerHelper.soKitHeaderOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('SOKitHeaderTrigger');

    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	SOKitHeaderTriggerHelper.afterInsert();
    }
}
/**
 * Author: Nidhi Sharma
 * Since: June 18, 2021
 * Name: WebsiteProductTrigger
 * Description: Trigger executes on event of Website_Product__c object
**/
trigger WebsiteProductTrigger on Website_Product__c (after insert, before insert, before update, after update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(WebsiteProductTriggerHelper.isForceStopTrigger) {return;}
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('WebsiteProductTrigger');

    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
        WebsiteProductTriggerHelper.afterInsert(trigger.new);
    }
    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()) {
        WebsiteProductTriggerHelper.beforeUpdate(trigger.new, trigger.oldMap);
    }
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
        WebsiteProductTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
    }
}
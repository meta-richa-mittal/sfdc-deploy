/**
 * Author: Nidhi Sharma
 * Since: March 04, 2020
 * Name: DealUnresolvedFulfillmentTrigger
 * Description: Trigger executes on trigger event of deal unresolved fulfillment object
**/
trigger DealUnresolvedFulfillmentTrigger on Deal_Unresolved_Fulfillment__c (after delete, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(DealUnresolvedFulfillmentTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    DealUnresolvedFulfillmentTriggerHelper.DealURFOldList = Trigger.old;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('DealUnresolvedFulfillmentTrigger');

    if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
        DealUnresolvedFulfillmentTriggerHelper.afterDelete();
    }
}
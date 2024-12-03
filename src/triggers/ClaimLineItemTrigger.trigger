/**
 * Author: Richa Mittal
 * Since: Jan. 23, 2019
 * Name: ClaimLineItemTrigger
 * Description: Trigger executes on after update event of Claim Line Item object
**/
trigger ClaimLineItemTrigger on Claim_Line_Item__c (after insert, after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    ClaimLineItemTriggerHelper.claimLineItemNewList = Trigger.new;
    ClaimLineItemTriggerHelper.claimLineItemOldList = Trigger.old;
    ClaimLineItemTriggerHelper.claimLineItemNewMap = Trigger.newMap;
    ClaimLineItemTriggerHelper.claimLineItemOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ClaimLineItemTrigger');
    
    if(Trigger.isAfter && (Trigger.isUpdate && !utilObj.updateDisabled())) {
        ClaimLineItemTriggerHelper.afterUpdate();
    }

    if(Trigger.isAfter && (Trigger.isInsert && !utilObj.insertDisabled())) {
        ClaimLineItemTriggerHelper.afterInsert();
    }
}
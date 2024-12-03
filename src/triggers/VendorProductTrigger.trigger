/**
 * Author: Nidhi Sharma
 * Since: June. 15, 2017
 * Name: VendorProductTrigger
 * Description: Trigger executes on before insert event of VendorProduct object
**/
trigger VendorProductTrigger on Product__c (after insert, after update, after delete, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    VendorProductTriggerHelper.vendorProductNewList = Trigger.new;
    VendorProductTriggerHelper.vendorProductOldList = Trigger.old;
    VendorProductTriggerHelper.vendorProductNewMap = Trigger.newMap;
    VendorProductTriggerHelper.vendorProductOldMap = Trigger.oldMap;

    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorProductTrigger');
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        VendorProductTriggerHelper.afterUpdateOperation();
    }
}
/**
 * Author: Ashish Garg
 * Since: Aug. 8, 2015
 * Name: VendorOrderHeaderTrigger
 * Description: Trigger executes on before insert, before insert, before update events of Vendor_Order_Line_Item_Group__c object
**/
trigger VendorOrderHeaderTrigger on Vendor_Order_Header__c (after insert, before insert, before update, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    VendorOrderHeaderTriggerHelper.newList = Trigger.new;
    VendorOrderHeaderTriggerHelper.oldList = Trigger.old;
    VendorOrderHeaderTriggerHelper.newMap = Trigger.newMap;
    VendorOrderHeaderTriggerHelper.oldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorOrderHeaderTrigger');

    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()){
        VendorOrderHeaderTriggerHelper.beforeUpdateOperations();
    }
}
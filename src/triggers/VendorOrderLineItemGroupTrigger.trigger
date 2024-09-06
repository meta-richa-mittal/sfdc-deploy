/**
 * Author: Ashish Garg
 * Since: Aug. 20, 2015
 * Name: VendorOrderLineItemGroupTrigger
 * Description: Trigger for Vendor_Order_Line_Item_Group__c
**/
trigger VendorOrderLineItemGroupTrigger on Vendor_Order_Line_Item_Group__c (before insert, before update, after update, before delete, after insert) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    if(VendorOrderLineItemGroupTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    VendorOrderLineItemGroupTriggerHelper.newList	= Trigger.new;
    VendorOrderLineItemGroupTriggerHelper.oldList	= Trigger.old;
    VendorOrderLineItemGroupTriggerHelper.newMap	= Trigger.newMap;
    VendorOrderLineItemGroupTriggerHelper.oldMap	= Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorOrderLineItemGroupTrigger');

    if(trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()){
        VendorOrderLineItemGroupTriggerHelper.updateLineItemsReceivedQty();
    }
    
    if(trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()){
        VendorOrderLineItemGroupTriggerHelper.updateLineItemsReceivedQty();
    }
    
    if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()) {
    	VendorOrderLineItemGroupTriggerHelper.beforeDeleteOperation(); 
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
    	VendorOrderLineItemGroupTriggerHelper.afterUpdateOperation();
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
    	VendorOrderLineItemGroupTriggerHelper.afterUpdateOperation();
    }
}
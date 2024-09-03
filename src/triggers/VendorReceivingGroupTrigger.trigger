/**
 * Author: Ashish Garg
 * Since: Aug. 20, 2015
 * Name: VendorReceivingGroupTrigger
 * Description: Trigger for Vendor_Receiving_Group__c
**/
trigger VendorReceivingGroupTrigger on Vendor_Receiving_Group__c (before delete, before insert, before update, after update, after insert, after delete) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
	if(VendorReceivingGroupTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    VendorReceivingGroupTriggerHelper.newList   = Trigger.new;
    VendorReceivingGroupTriggerHelper.oldList   = Trigger.old;
    VendorReceivingGroupTriggerHelper.newMap    = Trigger.newMap;
    VendorReceivingGroupTriggerHelper.oldMap    = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorReceivingGroupTrigger');

    if(trigger.isBefore && !Trigger.isInsert && !utilObj.updateDisabled() && !utilObj.deleteDisabled()){
        VendorReceivingGroupTriggerHelper.updateLineItemsReceivedQty();
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
    	VendorReceivingGroupTriggerHelper.beforeUpdateOperation();
    }
        
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
    	VendorReceivingGroupTriggerHelper.afterInsertOperation();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
    	VendorReceivingGroupTriggerHelper.afterUpdateOperation();
    }
    
    if(Trigger.isAfter && Trigger.isDelete && !utilObj.deleteDisabled()) {
    	VendorReceivingGroupTriggerHelper.afterDeleteOperation(); 
    }
}
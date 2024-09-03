/**
 * Author: Richa Mittal
 * Since: Jan 09, 2017
 * Name: VendorReceivingHeaderTrigger
 * Description: Trigger executes on before insert, before update and after update events of Vendor_Receiving_Header__c object
**/
trigger VendorReceivingHeaderTrigger on Vendor_Receiving_Header__c (after insert, after update, before insert, before update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    VendorReceivingHeaderTriggerHelper.receivingNewList = Trigger.new;
    VendorReceivingHeaderTriggerHelper.receivingOldList = Trigger.old;
    VendorReceivingHeaderTriggerHelper.receivingNewMap = Trigger.newMap;
    VendorReceivingHeaderTriggerHelper.receivingOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorReceivingHeaderTrigger');

    if(system.isBatch()) {
    	return;
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
    	VendorReceivingHeaderTriggerHelper.populatesAccountingSyncFields();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) { 
        if(!(VendorReceivingHeaderTriggerHelper.preventOnAccountingSync || System.isFuture())) {
        	VendorReceivingHeaderTriggerHelper.preventOnAccountingSync = true;
        	VendorReceivingHeaderTriggerHelper.setVendorReceivingDataForAccountSync();
    	}
        
    }
    
    
}
/**
 * Author: Pooja Khandelwal
 * Since: Dec. 23, 2014
 * Name: VendorInvoicingHeaderTrigger
 * Description: Trigger executes on before insert, before insert, before update and after update events of Vendor_Invoicing_Header object
**/
trigger VendorInvoicingHeaderTrigger on Vendor_Invoicing_Header__c(after insert, before insert, before update, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    VendorInvoicingHeaderTriggerHelper.invoiceNewList = Trigger.new;
    VendorInvoicingHeaderTriggerHelper.invoiceOldList = Trigger.old;
    VendorInvoicingHeaderTriggerHelper.invoiceNewMap = Trigger.newMap;
    VendorInvoicingHeaderTriggerHelper.invoiceOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorInvoicingHeaderTrigger');

    if(system.isBatch()) {
    	return;
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        VendorInvoicingHeaderTriggerHelper.populatesAccountingSyncFields();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) { 
    	if(!(VendorInvoicingHeaderTriggerHelper.preventOnAccountingSync || system.isFuture())) {
        	VendorInvoicingHeaderTriggerHelper.preventOnAccountingSync = true;
        	VendorInvoicingHeaderTriggerHelper.setVendorInvoiceDataForAccountSync();
    	}
    }
}
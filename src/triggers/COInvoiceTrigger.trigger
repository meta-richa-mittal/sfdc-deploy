/**
 * Author: Pooja Khandelwal
 * Since: Dec. 23, 2014
 * Name: COInvoiceTrigger
 * Description: Trigger executes on before insert, before update and after update events of COInvoice object
**/
trigger COInvoiceTrigger on CO_Invoice_Header__c(after insert, before insert, before update, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(COInvoiceTriggerHelper.isForceStopTrigger) {
    	return;
    }
    COInvoiceTriggerHelper.invoiceNewList = Trigger.new;
    COInvoiceTriggerHelper.invoiceOldList = Trigger.old;
    COInvoiceTriggerHelper.invoiceNewMap = Trigger.newMap;
    COInvoiceTriggerHelper.invoiceOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('COInvoiceTrigger');

    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        COInvoiceTriggerHelper.afterUpdate();
    }
    
    if(system.isBatch()) {
        return;
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        COInvoiceTriggerHelper.beforeUpdate();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        if(!(COInvoiceTriggerHelper.preventOnAccountingSync || System.isFuture())) {
            COInvoiceTriggerHelper.preventOnAccountingSync = true;
            COInvoiceTriggerHelper.setCOInvoiceDataForAccountSync();
        }
    }
}
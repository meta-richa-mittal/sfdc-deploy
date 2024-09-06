/**
 * Author: Pooja Khandelwal
 * Since: Jan. 13, 2017
 * Name: COInvoicePaymentTrigger
 * Description: Trigger executes on before insert, before update, after insert and after update events of CO_Invoice_Payment__c object
**/
trigger COInvoicePaymentTrigger on CO_Invoice_Payment__c ( after update, after insert, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    COInvoicePaymentTriggerHelper.COInvoicePaymentNewList = Trigger.new;
    COInvoicePaymentTriggerHelper.COInvoicePaymentOldList = Trigger.old;
    COInvoicePaymentTriggerHelper.COInvoicePaymentNewMap = Trigger.newMap;
    COInvoicePaymentTriggerHelper.COInvoicePaymentOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('COInvoicePaymentTrigger');
    
    if(system.isBatch()){
    	return;
    }

    if(Trigger.isBefore) {
    	if(Trigger.isInsert && !utilObj.insertDisabled()){ 
    		COInvoicePaymentTriggerHelper.populatesAccountingSyncFields();
            COInvoicePaymentTriggerHelper.convertAmountToDecimal();
            COInvoicePaymentTriggerHelper.beforeInsert();
    	}
        if(Trigger.isUpdate && !utilObj.updateDisabled()){ 
    		COInvoicePaymentTriggerHelper.convertAmountToDecimal();
    	}
    }
    
    if(Trigger.isAfter){ 
        if(Trigger.isInsert && !utilObj.insertDisabled()){ 
        	COInvoicePaymentTriggerHelper.afterInsert();
            COInvoicePaymentTriggerHelper.createStoreCredit();
        	//if(!(COInvoicePaymentTriggerHelper.preventOnAccountingSync || System.isFuture())){
        	if(!System.isFuture()){	
	        	COInvoicePaymentTriggerHelper.preventOnAccountingSync = true;
	        	COInvoicePaymentTriggerHelper.setCOInvoicePaymentDataForAccountSync();
        	}
        }
        
    }
    
}
/**
 * Author: Tarun Khandelwal
 * Since: Dec 23, 2015
 * Name: ServiceOrderLineItemTrigger
 * Description: Trigger executes on after update event of SO Line Item object
**/
trigger ServiceOrderLineItemTrigger on Service_Order_Line_Item__c (before insert, after insert, before update, after update, before delete, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop) {
        return;
    }
    ServiceOrderLineItemTriggerHelper.soliNewList = Trigger.new;
    ServiceOrderLineItemTriggerHelper.soliOldList = Trigger.old;
    ServiceOrderLineItemTriggerHelper.soliNewMap = Trigger.newMap;
    ServiceOrderLineItemTriggerHelper.soliOldMap = Trigger.oldMap; 
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ServiceOrderLineItemTrigger');

    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        ServiceOrderLineItemTriggerHelper.hoursLoggedCalculation();
    	ServiceOrderLineItemTriggerHelper.afterUpdateCalculation();
        ServiceOrderLineItemTriggerHelper.populateTotalsOnSOHeader();
        //to be calculated one all PL and ST calculation done
        ServiceOrderLineItemTriggerHelper.upsertRelatedClaimLineItems();
    }
    
    if(Trigger.isBefore && Trigger.isInsert && !utilObj.insertDisabled()) {
        ServiceOrderLineItemTriggerHelper.isInsertOperation = true;
        ServiceOrderLineItemTriggerHelper.beforeInsertCalculation();
    }
    
    if(Trigger.isAfter && Trigger.isDelete && !utilObj.deleteDisabled()) {
 		ServiceOrderLineItemTriggerHelper.hoursLoggedCalculation();
 		ServiceOrderLineItemTriggerHelper.populateTotalsOnSOHeader();
    }
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
        ServiceOrderLineItemTriggerHelper.isInsertOperation = true;
    	ServiceOrderLineItemTriggerHelper.hoursLoggedCalculation();
    }
    
    if(ServiceOrderLineItemTriggerHelper.isTriggerExecuted) {
        return;
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
        ServiceOrderLineItemTriggerHelper.isInsertOperation = true;
        ServiceOrderLineItemTriggerHelper.afterInsertCalculation();
        ServiceOrderLineItemTriggerHelper.populateTotalsOnSOHeader();
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        ServiceOrderLineItemTriggerHelper.beforeUpdateCalculation();
    }
    
    if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()) {
        ServiceOrderLineItemTriggerHelper.beforeDeleteCalculation();
        ServiceOrderLineItemTriggerHelper.processCOInvoiceItem();
    }
    
    if(Trigger.isAfter && Trigger.isDelete && !utilObj.deleteDisabled()) {
        ServiceOrderLineItemTriggerHelper.afterDelete();
    }
}
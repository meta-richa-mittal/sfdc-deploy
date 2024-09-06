/**
 * Author: Tarun Khandelwal
 * Since: Nov. 13, 2014
 * Name: CustomerTrigger
 * Description: Trigger executes on before insert, before update and before delete events of Customer object
**/
trigger CustomerTrigger on Account (before delete, after insert, after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    CustomerTriggerHelper.accountNewList = Trigger.new;
    CustomerTriggerHelper.accountOldList = Trigger.old;
    CustomerTriggerHelper.accountNewMap = Trigger.newMap;
    CustomerTriggerHelper.accountOldMap = Trigger.oldMap;

    if(CustomerTriggerHelper.isBypassValidation == null) {
        CustomerTriggerHelper.isBypassValidation = Trigger.isUpdate ? BPConfigurationsService.isBypassValidation() : true;
    }

    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CustomerTrigger');

    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        CustomerTriggerHelper.validateFXVendorOnUpdate();
        CustomerTriggerHelper.validateCustomerVendorForMarkingInactive();
    }

    if(CustomerTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert) {
        CustomerTriggerHelper.populatesFieldsBeforeInsert();
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) {
    	CustomerTriggerHelper.accountInsertOperation();
    }
    
    if(Trigger.isBefore && Trigger.isUpdate) {
    	if(!utilObj.updateDisabled() && !system.isBatch()) {
    		CustomerTriggerHelper.populatesAccountingSyncFields();
    	}
        CustomerTriggerHelper.populatesFieldsBeforeInsert();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !CustomerTriggerHelper.isTriggerRun && !utilObj.updateDisabled()) { 
    	CustomerTriggerHelper.afterUpdateCalculations();
    	if(!(CustomerTriggerHelper.preventOnAccountingSync || system.isFuture() || system.isBatch())) {
            CustomerTriggerHelper.preventOnAccountingSync = true;
            CustomerTriggerHelper.setCustomerAndVendorDataForAccountSync();
            CustomerTriggerHelper.updatePartIdTextField();
        }
    }

    if(Trigger.isBefore && Trigger.isDelete) {
        CustomerTriggerHelper.validateVendorDeletion();   //Validate vendor deletion irrespective of trigger ON/Off
    }
}
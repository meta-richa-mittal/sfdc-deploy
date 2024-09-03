trigger CustomerOwnedUnitTrigger on Customer_Owned_Unit__c(before insert, after insert, before update, after update, after delete, before delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(CustomerOwnedUnitTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
    CustomerOwnedUnitTriggerHelper.customerOwnerUnitNewList = Trigger.new;
    CustomerOwnedUnitTriggerHelper.customerOwnerUnitOldList = Trigger.old;
    CustomerOwnedUnitTriggerHelper.customerOwnerUnitNewMap = Trigger.newMap;
    CustomerOwnedUnitTriggerHelper.customerOwnerUnitOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CustomerOwnedUnitTrigger');
    if(Trigger.isBefore && Trigger.isInsert && CustomerOwnedUnitTriggerHelper.forcefullyRunPopulateUnitIdLogic) { 
        CustomerOwnedUnitTriggerHelper.beforeInsertOperations();
    }
    
    if(system.isBatch()) {
        return;
    }
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert && !utilObj.insertDisabled()){
            CustomerOwnedUnitTriggerHelper.beforeInsertOperations();
                CustomerOwnedUnitTriggerHelper.populatesAccountingSyncFields();
                CustomerOwnedUnitTriggerHelper.populatesDP360SyncFields();
        } else if(Trigger.isUpdate && !utilObj.updateDisabled() ) {
            CustomerOwnedUnitTriggerHelper.beforeUpdate();
            CustomerOwnedUnitTriggerHelper.populatesDP360SyncFields();
        } else if(Trigger.isDelete && !utilObj.deleteDisabled()) {
            CustomerOwnedUnitTriggerHelper.beforeDelete();
        }
    }   
    
    if(Trigger.isAfter) {
        if(trigger.isInsert && !utilObj.insertDisabled()) {
            if(!(CustomerOwnedUnitTriggerHelper.preventOnAccountingSync || system.isFuture())) {
                CustomerOwnedUnitTriggerHelper.setCOUDataForAccountSync();
                CustomerOwnedUnitTriggerHelper.setSKUDataForDP360Sync();
            }
        } else if(Trigger.isUpdate && !utilObj.updateDisabled()) {
            if(!(CustomerOwnedUnitTriggerHelper.preventOnAccountingSync || system.isFuture())) {
               	CustomerOwnedUnitTriggerHelper.afterUpdate();
            }
        }
    }
}
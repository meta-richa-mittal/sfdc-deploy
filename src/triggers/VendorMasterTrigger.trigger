trigger VendorMasterTrigger on Vendor_Master__c (before delete, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('VendorMasterTrigger');

    if(VendorMasterTriggerHelper.isForceStopTrigger) {
    	return;
    }

    VendorMasterTriggerHelper.vendorMasterOldList = Trigger.old;

    if(Trigger.isBefore && Trigger.isDelete && !utilObj.deleteDisabled()) {
        VendorMasterTriggerHelper.beforeDelete();
   	}

}
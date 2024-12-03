trigger PostInstallLogTrigger on Post_Install_Log__c(after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PostInstallLogTrigger');

    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) {
        PostInstallLogTriggerHelper.afterUpdate(Trigger.new);
    }
}
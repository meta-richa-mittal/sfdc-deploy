/**
 * Author: Richa Mittal
 * Since: Nov 30, 2023
 * Name: ReturnCRHeaderTrigger
 * Description: Trigger executes on before insert, before insert, before update and after update events of Return_CR_Header__c object
**/
trigger ReturnCRHeaderTrigger on Return_CR_Header__c (before insert, before update, after update) {
    
    ReturnCRHeaderTriggerHelper.returnCRNewList = Trigger.new;
    ReturnCRHeaderTriggerHelper.returnCROldList = Trigger.old;
    ReturnCRHeaderTriggerHelper.returnCRNewMap = Trigger.newMap;
    ReturnCRHeaderTriggerHelper.returnCROldMap = Trigger.oldMap; 
   
   	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ReturnCRHeaderTrigger');
    
    if(system.isBatch()) {
    	return;
    }

    if(Trigger.isBefore && Trigger.isUpdate && !utilObj.updateDisabled()) {
        ReturnCRHeaderTriggerHelper.populatesAccountingSyncFields();
    }
    
    if(Trigger.isAfter && Trigger.isUpdate && !utilObj.updateDisabled()) { 
    	if(!(ReturnCRHeaderTriggerHelper.preventOnAccountingSync || System.isFuture())) {
        	ReturnCRHeaderTriggerHelper.preventOnAccountingSync = true;
        	ReturnCRHeaderTriggerHelper.setReturnCreditDataForAccountSync();
    	}
    }
}
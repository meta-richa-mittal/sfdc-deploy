/**
 * Author: Richa Mittal
 * Since: Jan. 16, 2017
 * Name: CODepositTrigger
 * Description: Trigger executes on before insert and after insert events of CO_Deposit__c object
**/
trigger CODepositTrigger on CO_Deposit__c (after insert, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    CODepositTriggerHelper.CODepositNewList = Trigger.new;
    CODepositTriggerHelper.CODepositOldList = Trigger.old;
    CODepositTriggerHelper.CODepositNewMap = Trigger.newMap;
    CODepositTriggerHelper.CODepositOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CODepositTrigger');
    
    if(system.isBatch() || CODepositTriggerHelper.preventOnAccountingSync) {
    	return;
    }

    if(Trigger.isBefore) {
    	if(Trigger.isInsert && !utilObj.insertDisabled()){ 
    	    CODepositTriggerHelper.populatesAccountingSyncFields();
            CODepositTriggerHelper.convertAmountToDecimal();
    	}
        if(Trigger.isUpdate && !utilObj.updateDisabled()){ 
    		CODepositTriggerHelper.convertAmountToDecimal();
    	}
    }
    
    if(Trigger.isAfter && Trigger.isInsert && !utilObj.insertDisabled()) { 
        CODepositTriggerHelper.afterInsert();
    }
    
}
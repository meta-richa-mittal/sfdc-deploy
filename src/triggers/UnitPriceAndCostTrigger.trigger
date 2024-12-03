trigger UnitPriceAndCostTrigger on Unit_Price_Cost__c (before insert, after delete, after insert, after update, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    if(UnitPriceAndCostTriggerHelper.isForceStopTrigger) {
    	return;
    }
    
	UnitPriceAndCostTriggerHelper.unitPriceAndCostNewList = Trigger.new;
    UnitPriceAndCostTriggerHelper.unitPriceAndCostOldList = Trigger.old;
    UnitPriceAndCostTriggerHelper.unitPriceAndCostNewMap = Trigger.newMap;
    UnitPriceAndCostTriggerHelper.unitPriceAndCostOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('UnitPriceAndCostTrigger');

    if(system.isBatch()) {
        return;
    }
    
    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
    	UnitPriceAndCostTriggerHelper.beforeInsertCalculation();
    }
    
	if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
    	UnitPriceAndCostTriggerHelper.afterInsertCalculation();
    	if(!(UnitPriceAndCostTriggerHelper.preventOnAccountingSync || System.isFuture())){
	    	UnitPriceAndCostTriggerHelper.preventOnAccountingSync = true;
            UnitPriceAndCostTriggerHelper.setUnitPriceAndCostDataForAccountSync();
    	}
    }
     
    if(trigger.isDelete && !utilObj.deleteDisabled()) {
    	UnitPriceAndCostTriggerHelper.afterDeleteCalculation();
    }
    
    if(trigger.isUpdate && !utilObj.updateDisabled()) {
    	UnitPriceAndCostTriggerHelper.afterUpdateCalculation();
    	UnitPriceAndCostTriggerHelper.setUnitPriceAndCostDataForAccountSync();
    }
}
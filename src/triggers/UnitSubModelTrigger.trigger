trigger UnitSubModelTrigger on Unit_Sub_Model__c (before insert, before update) {
    
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
    UnitSubModelTriggerHelper.unitSubModelNewList = Trigger.new;
	UnitSubModelTriggerHelper.unitSubModelOldList = Trigger.old;
	UnitSubModelTriggerHelper.unitSubModelNewMap = Trigger.newMap;
	UnitSubModelTriggerHelper.unitSubModelOldMap = Trigger.oldMap;
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('UnitSubModelTrigger');

	if((trigger.isInsert && !utilObj.insertDisabled()) || (trigger.isUpdate && !utilObj.updateDisabled())) {
		UnitSubModelTriggerHelper.checkForUniqueSubModel();		
	}
}
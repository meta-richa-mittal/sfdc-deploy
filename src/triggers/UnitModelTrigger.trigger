trigger UnitModelTrigger on Unit_Model__c (before insert, before update) {
    
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
	
    UnitModelTriggerHelper.unitModelNewList = Trigger.new;
	UnitModelTriggerHelper.unitModelOldList = Trigger.old;
	UnitModelTriggerHelper.unitModelNewMap = Trigger.newMap;
	UnitModelTriggerHelper.unitModelOldMap = Trigger.oldMap;
	
	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('UnitModelTrigger');

	if((trigger.isInsert && !utilObj.insertDisabled()) || (trigger.isUpdate && !utilObj.updateDisabled())) {
		UnitModelTriggerHelper.checkForUniqueModelBasedOnMake();		
	}
}
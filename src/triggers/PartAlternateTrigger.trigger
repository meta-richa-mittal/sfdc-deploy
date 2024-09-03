trigger PartAlternateTrigger on Part_Alternates__c (before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */
    
    PartAlternateTriggerHelper.PartAlternateNewList = Trigger.new;
    PartAlternateTriggerHelper.PartAlternateOldList = Trigger.old;
    PartAlternateTriggerHelper.PartAlternateNewMap = Trigger.newMap;
    PartAlternateTriggerHelper.PartAlternateOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PartAlternateTrigger');

    if(Trigger.isBefore) {
        if(Trigger.isInsert && !utilObj.insertDisabled()) {
            PartAlternateTriggerHelper.validatiePartSelfRelation();
            PartAlternateTriggerHelper.populatePartRelationUniqueCheck();
        } else if(Trigger.isUpdate && !utilObj.updateDisabled()) {
        	PartAlternateTriggerHelper.validatiePartSelfRelation();
         	PartAlternateTriggerHelper.populatePartRelationUniqueCheck();
        }
    }       
}
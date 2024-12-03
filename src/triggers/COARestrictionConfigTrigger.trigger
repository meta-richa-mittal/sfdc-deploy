/**
 * Author: Nidhi Sharma
 * Since: April 22, 2021
 * Name: COARestrictionConfigTrigger
 * Description: COA_Restriction_Config__c Trigger
**/
trigger COARestrictionConfigTrigger on COA_Restriction_Config__c (after delete, after insert, after undelete, after update, before insert, before update) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('COARestrictionConfigTrigger');
    
    if(trigger.isAfter && trigger.isInsert && !utilObj.insertDisabled()) {
        COARestrictionConfigTriggerHelper.afterInsert();
    }
    
    if(trigger.isAfter && trigger.isUpdate && !utilObj.updateDisabled()) {
        COARestrictionConfigTriggerHelper.afterUpdate();
    }
    
    if(trigger.isAfter && trigger.isDelete && !utilObj.deleteDisabled()) {
        COARestrictionConfigTriggerHelper.afterDelete();
    }
    
    if(trigger.isAfter && trigger.isUndelete && !utilObj.undeleteDisabled()) {
        COARestrictionConfigTriggerHelper.afterUndelete();
    }
}
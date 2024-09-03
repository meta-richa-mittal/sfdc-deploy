/**
 * Author: Hitesh Gupta
 * Since: Oct, 10, 2017
 * Name: ReturnVOHeaderTrigger
 * Description: Trigger executes on before insert, before insert, before update and after update events of Return_VO_Header object
**/
trigger ReturnVOHeaderTrigger on Return_VO_Header__c (after insert, before insert, before update, after update, after delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    if(ReturnVOHeaderTriggerHelper.isForceStopTrigger) {
        return;
    }

    ReturnVOHeaderTriggerHelper.returnVONewList = Trigger.new;
    ReturnVOHeaderTriggerHelper.returnVOOldList = Trigger.old;
    ReturnVOHeaderTriggerHelper.returnVONewMap = Trigger.newMap;
    ReturnVOHeaderTriggerHelper.returnVOOldMap = Trigger.oldMap; 
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('ReturnVOHeaderTrigger');

    if(system.isBatch()) {
        return;
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        ReturnVOHeaderTriggerHelper.beforeUpdateCalculation();
    }
}
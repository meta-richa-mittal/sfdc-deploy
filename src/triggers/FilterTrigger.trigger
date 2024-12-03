/**
 * Author: Hitesh Gupta
 * Since: March 30, 2016
 * Name: FilterTrigger
 * Description: Trigger executes on after update and after insert event of filter object
**/
trigger FilterTrigger on Filter__c (before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	FilterTriggerHelper.FilterNewList = Trigger.new;
    FilterTriggerHelper.FilterOldList = Trigger.old;
    FilterTriggerHelper.FilterNewMap = Trigger.newMap;
    FilterTriggerHelper.FilterOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('FilterTrigger');
    
    if(!FilterTriggerHelper.runTrigger){
    	return;
    }

    if(trigger.isBefore && trigger.isInsert && !utilObj.insertDisabled()) {
    	FilterTriggerHelper.hashCodeCalculation();

        /* Start: Added by Ashish Garg #152 28/09/2016 */
        FilterTriggerHelper.ProcessIfPreviewReport();
        /* End: Added by Ashish Garg #152 28/09/2016 */
    }
     
    if(trigger.isBefore && trigger.isUpdate && !utilObj.updateDisabled()) {
    	FilterTriggerHelper.hashCodeCalculation();
    }  
}
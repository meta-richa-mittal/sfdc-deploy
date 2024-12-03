/**
 * Author: Richa Mittal
 * Since: Dec 11, 2023
 * Name: FusionLineItemToGLAccountJunctionTrigger
**/
trigger FusionLineItemToGLAccountJunctionTrigger on Fusion_Line_Item_To_GL_Account_Junction__c (before insert, before update) {
	
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('FusionLineItemToGLAccountJunctionTrigger');

}
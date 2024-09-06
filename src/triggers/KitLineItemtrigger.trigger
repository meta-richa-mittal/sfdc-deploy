/**
 * Author: Ashish Garg
 * Since: Dec. 1,
 * Name: KitLineItemtrigger
 * Description: Trigger executes on before delete, before insert, before update events of Kit Header Line Item object records
**/
trigger KitLineItemtrigger on Kit_Header_Line_Item__c (before insert, before update, before delete, after insert, after delete) {
	
	/* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

	KitLineItemtriggerHelper.newList	= Trigger.new;
	KitLineItemtriggerHelper.oldList	= Trigger.old;
	KitLineItemtriggerHelper.newMap		= Trigger.newMap;
	KitLineItemtriggerHelper.oldMap		= Trigger.oldMap;

	Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('KitLineItemtrigger');

	if (Trigger.isBefore) {
		if (Trigger.isInsert && !utilObj.insertDisabled()) {
			KitLineItemtriggerHelper.processBeforeInsert();
		} else if (Trigger.isUpdate && !utilObj.updateDisabled()) {
			KitLineItemtriggerHelper.processBeforeUpdate();
		} else if (Trigger.isDelete && !utilObj.deleteDisabled()) {
			KitLineItemtriggerHelper.processBeforeDelete();
		}
	}
	
	if (Trigger.isAfter) {
		if (Trigger.isInsert && !utilObj.insertDisabled()) {
			KitLineItemtriggerHelper.setDefaultFields();
		} else if (Trigger.isDelete && !utilObj.deleteDisabled()) {
			KitLineItemtriggerHelper.setDefaultFields();
		}
	}
}
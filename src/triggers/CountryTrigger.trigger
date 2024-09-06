/**
 * Author: Tarun Khandelwal
 * Since: Oct. 17, 2014
 * Name: CountryTrigger
 * Description: Trigger executes on before insert, before update and before delete events of Country object
**/
trigger CountryTrigger on Country__c (before insert, before update, before delete) {
    
    /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    	BPTriggerHandler.onBeforeUpdate();
    }
    if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
        return;
    }
    /* Last Modified by User changes */

    // Initializes List of helper classes
    CountryTriggerHelper.countryNewList = Trigger.new;
    CountryTriggerHelper.countryOldList = Trigger.old;
    CountryTriggerHelper.countryNewMap = Trigger.newMap;
    CountryTriggerHelper.countryOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('CountryTrigger');
    
    if(Trigger.isInsert && !utilObj.insertDisabled()) {
        CountryTriggerHelper.updateDefaultfield();
    }
    
    if(Trigger.isUpdate && !utilObj.updateDisabled()) {
        CountryTriggerHelper.updateDefaultfield();
    }
    
    if(Trigger.isDelete && !utilObj.deleteDisabled()) {
        CountryTriggerHelper.checkDefaultOnDelete();
    }
    
}
/**
 * Author: Tarun Khandelwal
 * Since: Oct. 10, 2014
 * Name: PriceLevelTrigger
 * Description: Trigger executes on before insert and before update events of Price Level object
**/
trigger PriceLevelTrigger on Price_Level__c (before insert, before update, before delete, after update) {
    
     /* Last Modified by User changes */
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
          BPTriggerHandler.onBeforeUpdate();
     }
     if(!BPTriggerHandler.isExecuteTrigger) { // This will be false only from post install script
          return;
     }
     /* Last Modified by User changes */
     
    // Initializes List of helper classes
    PriceLevelTriggerHelper.priceLevelNewList = Trigger.new;
    PriceLevelTriggerHelper.priceLevelOldList = Trigger.old;
    PriceLevelTriggerHelper.priceLevelNewMap = Trigger.newMap;
    PriceLevelTriggerHelper.priceLevelOldMap = Trigger.oldMap;
    
    Utility_TriggerSoftDisbale utilObj = new Utility_TriggerSoftDisbale('PriceLevelTrigger');

    if( Trigger.isBefore ) {
        
        if( Trigger.isInsert && !utilObj.insertDisabled()) {
             // Update default field if new record default field is selected
             PriceLevelTriggerHelper.updateDefaultField();
        }
        
        if( Trigger.isUpdate && !utilObj.updateDisabled()) {
             // Update default field if new record default field is selected
             PriceLevelTriggerHelper.updateDefaultField();
        }
        
        if( Trigger.isDelete && !utilObj.deleteDisabled()) {
             // Validate the deleting record before deleting if it default and active record or not
             PriceLevelTriggerHelper.validateBeforeDel();
        }
    }

    if(Trigger.isAfter ) {
         // To update kit line items if default price level changes
          if(Trigger.isUpdate && !utilObj.updateDisabled()) {
               PriceLevelTriggerHelper.updateKitLineItems();
          }
    }
}
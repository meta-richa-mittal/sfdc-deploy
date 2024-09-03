/**
 * Author: Richa Mittal
 * Since: Aug 24, 2023
 * Name: PopulateMileageOnDealItemsBatch
 * Description: 
**/
global without sharing class PopulateMileageOnDealItemsBatch extends PostInstallScriptBaseBatch {

    global PopulateMileageOnDealItemsBatch() {
        this.scriptName = 'executePopulateMileageOnDealItemsBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        return Database.getQueryLocator('Select Id, Customer_Owned_Unit__r.Mileage_Value__c, Customer_Owned_Unit__r.Mileage_Type__c from Deal_Item__c ' + 
                                            'WHERE Customer_Owned_Unit__c != null AND (Customer_Owned_Unit__r.Mileage_Value__c != null OR Customer_Owned_Unit__r.Mileage_Type__c != null)');
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItemList) {
        for(Deal_Item__c dealItemRec: (List<Deal_Item__c>)dealItemList) {
            dealItemRec.Mileage__c = dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c;
            dealItemRec.Mileage_Type__c = dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c;
        }

        DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemList);
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
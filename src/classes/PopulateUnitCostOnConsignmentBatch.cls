global without sharing class PopulateUnitCostOnConsignmentBatch extends PostInstallScriptBaseBatch{
    global PopulateUnitCostOnConsignmentBatch() {
        this.scriptName = 'executePopulateUnitCostOnConsignmentBatch()';
    }
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Unit_Cost__c , Customer_Owned_Unit__r.Agreed_Payout__c From Deal_Item__c where Customer_Owned_Unit__c != null and Customer_Owned_Unit__r.Consignment__c = true';
        return Database.getQueryLocator(strQuery); 
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItemList) {
        
        for(Deal_Item__c dealItemRec: (List<Deal_Item__c>)dealItemList) {
            dealItemRec.Unit_Cost__c = dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c;
        }

        DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemList);
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        
    }
}

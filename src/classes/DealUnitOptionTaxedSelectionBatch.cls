/**
 * Author: Nidhi Sharma
 * Since: March 15, 2023
 * Name: DealUnitOptionTaxedSelectionBatch
 * Description: Batch for Populating Unit_Tax_Applicable_On__c fields on deal items
**/
global without sharing class DealUnitOptionTaxedSelectionBatch extends PostInstallScriptBaseBatch {

    global DealUnitOptionTaxedSelectionBatch() {
        this.scriptName = 'executeDealUnitOptionTaxedSelectionBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Override_Tax_For_All_Line_Items__c FROM Deal_Item__c WHERE Unit_Tax_Applicable_On__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItems) {
        for(Deal_Item__c dealItemRec : (List<Deal_Item__c>) dealItems) {
			if(dealItemRec.Override_Tax_For_All_Line_Items__c) {
                dealItemRec.Unit_Tax_Applicable_On__c = DealUtil.UNIT_TAX_APPLICABLE_ALL;
            } else {
                dealItemRec.Unit_Tax_Applicable_On__c = DealUtil.UNIT_TAX_APPLICABLE_DEFAULT;
            }
		}
        DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItems);
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
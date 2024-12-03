/**
 * Author: Richa Mittal
 * Since: Sep 16, 2024
 * Name: CorrectDealItemReportFieldsForProfBatch
 * Description: Batch for Populating fields on deal item
**/
global without sharing class CorrectDealItemReportFieldsForProfBatch extends PostInstallScriptBaseBatch {

    global CorrectDealItemReportFieldsForProfBatch() {
        this.scriptName = 'executeCorrectDealItemReportFieldsForProfBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Agreed_Payout__c, ' + 
        '(SELECT Id, Qty__c, Price__c, Fee__r.Is_Include_In_Profit_Calculation__c FROM Options_Fees__r ' +
        'WHERE Price__c != null AND Price__c != 0 AND Fee__c != null) FROM Deal_Item__c WHERE Type__c = \'Unit\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItemRecList) {
        for(Deal_Item__c dealItemRec: (List<Deal_Item__c>) dealItemRecList) {
            dealItemRec.Fee_Total_Included_In_Profitability__c = 0;
            for(Option_Fee__c ofRec : dealItemRec.Options_Fees__r) {
                ofRec.Qty__c = (ofRec.Qty__c != null) ? ofRec.Qty__c : 0;
                Decimal price = (ofRec.Qty__c * ofRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                dealItemRec.Fee_Total_Included_In_Profitability__c += (ofRec.Fee__r.Is_Include_In_Profit_Calculation__c ? price : 0);
            }
            if(dealItemRec.Customer_Owned_Unit__r.Unit_Type__c != null && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase('COU')) {
                dealItemRec.Unit_Cost__c = dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c != null ? dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP) : null;
            }
        }
		DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemRecList);
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
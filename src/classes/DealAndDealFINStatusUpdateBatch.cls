/**
 * Author: Nidhi Sharma
 * Since: Dec 26, 2022
 * Name: DealAndDealFINStatusUpdateBatch
 * Description: Batch for Populating status fields on deal and deal finance
**/
global without sharing class DealAndDealFINStatusUpdateBatch extends PostInstallScriptBaseBatch {

    global DealAndDealFINStatusUpdateBatch() {
        this.scriptName = 'executeDealAndDealFINStatusUpdateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Total_Finance_Commission__c, Status__c, CO_Header__c, Amount_Financed__c, Invoice_Number__c, Invoice_Number__r.Total_Finance_Commission__c, (Select Id, Total_Commission__c, Status__c FROM Deal_Finances__r) FROM Deal__c WHERE Type__c = \'Financed\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealRecList) {
        List<Deal_Finance__c> dfinUpdateList = new List<Deal_Finance__c>();
    	List<Deal__c> dealUpdateList = new List<Deal__c>();
        List<CO_Invoice_Header__c> coInvoiceHeaderUpdateList = new List<CO_Invoice_Header__c>();

        Map<Id, Decimal> coIdToAmountPaidByFINMap = getCOIdToAmountPaidByFINMap((List<Deal__c>)dealRecList);

    	for(Deal__c dealRec : (List<Deal__c>)dealRecList) {
			if(!dealRec.Deal_Finances__r.isEmpty()) {
                Boolean isDealModified = false;
                if(dealRec.Status__c.equalsIgnoreCase('Invoiced')) {
                    dealRec.Deal_Finances__r[0].Status__c = 'Funded';
                    dfinUpdateList.add(dealRec.Deal_Finances__r[0]);
                } else {
                    Decimal dueFromFinancing = dealRec.Amount_Financed__c - coIdToAmountPaidByFINMap.get(dealRec.CO_Header__c);
                    if(dueFromFinancing == 0) {
                        dealRec.Deal_Finances__r[0].Status__c = 'Funded';
                        dfinUpdateList.add(dealRec.Deal_Finances__r[0]);
                    }
                    if(dueFromFinancing == 0 || dealRec.Deal_Finances__r[0].Status__c.equalsIgnoreCase('Approved')) {
                        dealRec.Status__c = 'Approved';
                        isDealModified = true;
                    }
                }
                if(dealRec.Deal_Finances__r[0].Total_Commission__c != null && dealRec.Deal_Finances__r[0].Total_Commission__c != dealRec.Total_Finance_Commission__c) {
                    dealRec.Total_Finance_Commission__c = dealRec.Deal_Finances__r[0].Total_Commission__c.setScale(2, RoundingMode.HALF_UP);
                    isDealModified = true;

                    if(dealRec.Invoice_Number__c != null) {
                        CO_Invoice_Header__c invHeaderRec = dealRec.Invoice_Number__r;
                        invHeaderRec.Total_Finance_Commission__c = dealRec.Total_Finance_Commission__c;
                        coInvoiceHeaderUpdateList.add(invHeaderRec);
                    }
                }
                if(isDealModified) {
                    dealUpdateList.add(dealRec);
                }
            }
		}
		DealTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Finance__c', dfinUpdateList);
        DMLUtility.updateSobjectList('Deal__c', dealUpdateList);
        DealTriggerHelper.isForceStopTrigger = false;
        
        COInvoiceTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoiceHeaderUpdateList);
        COInvoiceTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Map<Id, Decimal> getCOIdToAmountPaidByFINMap(List<Deal__c> dealRecList) {
        Map<Id, Decimal> coIdToFinanceAmountPaidMap = new Map<Id, Decimal>();
        for(Deal__c dealRec : dealRecList) {
            coIdToFinanceAmountPaidMap.put(dealRec.CO_Header__c, 0);
        }
        for(CO_Invoice_Payment__c coipRec : [Select CO_Invoice_Header__r.CO_Header__c, Amount__c FROM CO_Invoice_Payment__c WHERE CO_Invoice_Header__r.CO_Header__c IN: coIdToFinanceAmountPaidMap.keySet() AND Payment_Method__c = 'Financing' AND Amount__c != null Order By CO_Invoice_Header__r.CO_Header__c]) {
            coIdToFinanceAmountPaidMap.put(coipRec.CO_Invoice_Header__r.CO_Header__c, coIdToFinanceAmountPaidMap.get(coipRec.CO_Invoice_Header__r.CO_Header__c) + coipRec.Amount__c);
        }
        for(CO_Deposit__c codnRec : [Select Deal__r.CO_Header__c, Amount__c FROM CO_Deposit__c WHERE Payment_Method__c = 'Financing' AND Amount__c != null AND Deal__c IN: dealRecList]) {
            coIdToFinanceAmountPaidMap.put(codnRec.Deal__r.CO_Header__c, coIdToFinanceAmountPaidMap.get(codnRec.Deal__r.CO_Header__c) + codnRec.Amount__c);
        }
        return coIdToFinanceAmountPaidMap;
    }
}
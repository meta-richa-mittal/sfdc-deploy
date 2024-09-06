
/**
 * Author: Richa Mittal
 * Since: Oct 21, 2021
 * Name: PopulateDealConfirmedSaleDateBatch
 * Description: Batch for Populating confirmed sale date on all deals
**/
global with sharing class PopulateDealConfirmedSaleDateBatch implements Database.Batchable<sobject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Deal__c Where CO_Header__c != null AND Confirmed_Sale_Date__c = null');
    }
    
    global void execute(Database.batchableContext bc, List<Deal__c> dealList) {
        populateDealConfirmedSaleDate(dealList);
    }

    global void finish(Database.batchableContext bc) {}

    private void populateDealConfirmedSaleDate(List<Deal__c> dealList) {
        List<Deal__c> dealListWithDeposits = [SELECT Delivery_Date__c, Status__c, LastModifiedDate, Invoice_Number__r.Invoice_Date_Formula__c,  
                                                (SELECT Amount__c, Payment_Date__c FROM CO_Deposits__r ORDER BY CreatedDate ASC) 
                                                FROM Deal__c Where Id IN :dealList];
        for(Deal__c dealRec: dealListWithDeposits) {
            Decimal totalDeposit = 0;
            for(CO_Deposit__c coDepositRec: dealRec.CO_Deposits__r) {
                totalDeposit += (coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0);
            }
            if(dealRec.Delivery_Date__c != null) {
                dealRec.Confirmed_Sale_Date__c = dealRec.Delivery_Date__c;
            } else if(dealRec.Status__c == 'Quotation' && totalDeposit == 0) {
                dealRec.Confirmed_Sale_Date__c = null;
            } else if(totalDeposit != 0) {
                dealRec.Confirmed_Sale_Date__c = (dealRec.CO_Deposits__r.size() > 0 ? dealRec.CO_Deposits__r[0].Payment_Date__c : null);
            } else if(dealRec.Status__c == 'Invoiced') {
                dealRec.Confirmed_Sale_Date__c = dealRec.Invoice_Number__r.Invoice_Date_Formula__c;
            } else {
                dealRec.Confirmed_Sale_Date__c = dealRec.LastModifiedDate.date();
            }
        }
        DealTriggerHelper.isForceStopTrigger = true;
        update dealListWithDeposits;
        DealTriggerHelper.isForceStopTrigger = false;
    }
}
/**
 * Author: Balveer Choudhary
 * Since: Nov 17, 2021
 * Name: PopulateCustomerOnPaymentBatch
 * Description: Batch for Populating Customer Name field on COIP And CO Deposit
**/                       
global with sharing class PopulateCustomerOnPaymentBatch implements Database.Batchable<sobject> {
    
    public String paymentType;

    global PopulateCustomerOnPaymentBatch(String paymentType) {
        this.paymentType = paymentType;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery;
        if(this.paymentType == 'CODeposit') {
            BPScriptUtility.disbaleTrigger('CODepositTrigger');
            strQuery = 'SELECT Id, CO_Header__r.Customer__c FROM CO_Deposit__c WHERE Customer_Name__c = null';
        } else {
            BPScriptUtility.disbaleTrigger('COInvoicePaymentTrigger');
            strQuery = 'SELECT Id, CO_invoice_Header__r.CO_Header__r.Customer__c FROM CO_Invoice_Payment__c WHERE Customer_Name__c = null';
        }
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.batchableContext bc, List<sObject> scope) {
        Id recordId;
        CO_Deposit__c coDeposit;
        CO_Invoice_Payment__c coInvoicePayment;
        List<sObject> sObjectToUpdateList = new List<sObject>();

        for(sObject sobj : scope) {
            recordId = String.valueOf(sobj.get('Id'));
            if(recordId.getSObjectType().getDescribe().getName() == Constants.Namespace + 'CO_Deposit__c') {
                coDeposit = (CO_Deposit__c)sobj;
                sObjectToUpdateList.add(new CO_Deposit__c(Id = coDeposit.Id, Customer_Name__c = coDeposit.CO_Header__r.Customer__c));
            } else {
                coInvoicePayment = (CO_Invoice_Payment__c)sobj;
                sObjectToUpdateList.add(new CO_Invoice_Payment__c(Id = coInvoicePayment.Id, Customer_Name__c = coInvoicePayment.CO_invoice_Header__r.CO_Header__r.Customer__c));
            }
        }
        if(sObjectToUpdateList.size() > 0) {
            update sObjectToUpdateList;
        }
    }

    public void finish(Database.batchableContext bc) {
        if(this.paymentType == 'CODeposit') {
            BPScriptUtility.enableTrigger('CODepositTrigger');
        } else {
            BPScriptUtility.enableTrigger('COInvoicePaymentTrigger');
        }
    }
}
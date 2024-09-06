/**
 * Author: Manoj Sharma
 * Since: Aug 28, 2023
 * Name: PopulateInvoiceARBalanceBatch
 * Description: Batch class to populated accounting AR balance.
**/
global without sharing class PopulateInvoiceARBalanceBatchScheduler implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful, Schedulable  {
    private BaseIntegrationService integrationRec;
    public Integer batchSize = 30;
    private Set<WebService_Log__c> webServiceLogsSet = new Set<WebService_Log__c>();

    global PopulateInvoiceARBalanceBatchScheduler(){}

    global PopulateInvoiceARBalanceBatchScheduler(Integer batchSize) {
    	this.batchSize = batchSize;
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PopulateInvoiceARBalanceBatchScheduler(), this.batchSize);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, AccountingId__c, Xero_Accounting_Id__c, Invoice_Number__c, Total__c FROM CO_Invoice_Header__c WHERE (AccountingId__c != null OR Xero_Accounting_Id__c != null) AND Total_Charge_On_Account__c != 0 AND AR_Balance__c != 0 ';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> invoiceList) {
        try {
            if(integrationRec == null) {
                integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
            }
            List<CO_Invoice_Header__c> invoiceUpdateList = new List<CO_Invoice_Header__c>();
            Map<String, Decimal> invoiceIdToARBalanceMap = AccountingUtil.getCOInvoicesIdToARBalanceMap(invoiceList, integrationRec);
            for(String invoiceId : invoiceIdToARBalanceMap.keySet()) {
                invoiceUpdateList.add(new CO_Invoice_Header__c(Id = invoiceId, AR_Balance__c = invoiceIdToARBalanceMap.get(invoiceId)));
            }
            if(!invoiceUpdateList.isEmpty()) {
                COInvoiceTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('CO_Invoice_Header__c', invoiceUpdateList);
                COInvoiceTriggerHelper.isForceStopTrigger = false;
            }
            if(BaseIntegration.webServiceLogs != null) webServiceLogsSet.addAll(BaseIntegration.webServiceLogs);
        } catch(Exception e) {
            new LogService().createErrorLog('PopulateInvoiceARBalanceBatchScheduler', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                String.valueOf(invoiceList), '', true, 'Info');
        }
    }

    global void finish(Database.batchableContext bc) {
        if(integrationRec != null) {
            QBCalloutManager.updateRecords(integrationRec.integrationConfigRec);
        }
        if(!webServiceLogsSet.isEmpty()) {
            DMLUtility.insertSobjectList('WebService_Log__c',  new List<WebService_Log__c>(webServiceLogsSet));
        }
    }

    global static void executeScheduler() {
	    String CRON_EXP = '0 0 0 * * ? *';
	    system.schedule('Accounting AR Balance Scheduler', CRON_EXP, new PopulateInvoiceARBalanceBatchScheduler() );
    }
}
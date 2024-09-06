global without sharing class AccountingScriptUtil {
    private static final Integer MAX_SCHEDULABLE_JOB = 100;
    public static Integer batchSize = 10;
    
    public static void scheduleJobs(List<sObject> recordList, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec,
                                            String entityType, Integer schedulerInterval) {
        
        String scheduleJobName = IntegrationServiceFactory.getActiveAccountingIntegrationName() + ' ' + entityType + ' Sync';
        AccountingUtil.abortScheduleJobs(scheduleJobName);
        Integer maxPossibleJobsToSchedule = getMaxPossibleJobsToSchedule();
        if(maxPossibleJobsToSchedule <= 1) {
            throw new BlackPurlException('No additional jobs can be scheduled at this time. Please wait for the current jobs to complete and try again later.');
        }
        for(Integer i = 0; i < Math.ceil(recordList.size() / Decimal.valueOf(maxNumberOfRecord)) && i < (maxPossibleJobsToSchedule - 1); i++) {
            String cronExp = AccountingUtil.getCronExpForGivenTime(schedulerInterval + AccountingUtil.scheduleAfterSeconds + (i * timeIntervalForJobsInSec));
            Set<Id> recordIdSet = new Set<Id>();
            for(Integer j = (i * maxNumberOfRecord); (j < ((i + 1) * maxNumberOfRecord) && j < recordList.size()); j++) {
                recordIdSet.add(recordList[j].Id);
            }
            system.debug('Record Id Set for Scheduling ' + (i + 1) + '  ' + recordIdSet);
            
            if(entityType == 'CO Invoice JE Update') {
                system.schedule(scheduleJobName + ' ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.CO_INVOICE_JE, true));       
            } else if(entityType == IntegrationUtility.INVOICE) {
                system.schedule(scheduleJobName + ' ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, 
                    entityType, new List<String>{IntegrationUtility.INVOICE, IntegrationUtility.CO_INVOICE_JE, IntegrationUtility.INVOICE_PAYMENT}));                    
            } else if(entityType == IntegrationUtility.VO_INVOICE) {
                system.schedule(scheduleJobName + ' ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, 
                    entityType, new List<String>{IntegrationUtility.VO_INVOICE, IntegrationUtility.VO_INVOICE_VARIANCE_JE}));                    
            } else if(entityType == IntegrationUtility.VO_RETURN) {
                system.schedule(scheduleJobName + ' ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, 
                    entityType, new List<String>{IntegrationUtility.VO_RETURN, IntegrationUtility.VO_RETURN_VARIANCE_JE}));                    
            } else {
                system.schedule(scheduleJobName + ' ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, entityType));
            }
        }
   }

    private static Integer getMaxPossibleJobsToSchedule() {
        return (MAX_SCHEDULABLE_JOB - ([Select Id from CronTrigger where NextFireTime != null]).size());
    }

    private static void syncEntity(String objectAPIName, String whereClauseStr, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, String entityName) {
        List<SObject> entityList = Database.query(getQueryString(entityName, objectAPIName, whereClauseStr));
        scheduleJobs(entityList, maxNumberOfRecord, timeIntervalForJobsInSec, entityName, 0);
    }

    private static String getQueryString(String entityName, String objectAPIName, String whereClauseStr) {
        String query = 'SELECT Id FROM ' + objectAPIName + ' WHERE ' + IntegrationUtility.getSyncFlagAPIName(entityName) + 
                        ' = true' + (String.isNotBlank(whereClauseStr) ? (' AND ' + whereClauseStr) : '') + 
                        ' Order by CreatedDate DESC';
        return query;
    }

    global static void syncCustomers(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Account', '(Is_Customer__c = true OR (Is_Vendor__c = true AND Claims_for_Service_Work__c = true))', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.CUSTOMER);
    }       

    global static void syncBulkCustomers(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchChunkSize) {
        batchSize = batchChunkSize;
        syncEntity('Account', '(Is_Customer__c = true OR (Is_Vendor__c = true AND Claims_for_Service_Work__c = true))', maxNumberOfRecord, timeIntervalForJobsInSec, (QBUtil.isQBEnabled() ? IntegrationUtility.BATCH_CUSTOMER : IntegrationUtility.CUSTOMER));
    } 

    global static void syncVendors(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Account', 'Is_Vendor__c = true', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VENDOR);
    }

    global static void syncBulkVendors(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchChunkSize) {
        batchSize = batchChunkSize;
        syncEntity('Account', 'Is_Vendor__c = true', maxNumberOfRecord, timeIntervalForJobsInSec, (QBUtil.isQBEnabled() ? IntegrationUtility.BATCH_VENDOR : IntegrationUtility.VENDOR));
    }

    global static void syncCategory(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Category__c', '', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.ITEM_CATEGORY);
    }

    global static void syncUnitInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Customer_Owned_Unit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.UNIT_INVOICE);
    }

    global static void syncCODeposit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Deposit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.CO_DEPOSIT);
    }

    global static void syncCashReconciliation(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Cash_Reconciliation__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.CASH_RECONCILIATION);
    }

    global static void syncCOInvoicePaymentJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Invoice_Payment__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.CO_INVOICE_PAYMENT);
    }

    global static void syncCOInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Invoice_Header__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.CO_INVOICE_JE);
    }

    global static void updateCOInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Invoice_Header__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, 'CO Invoice JE Update');
    }

    global static void syncUnitInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Customer_Owned_Unit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.UNIT_INVOICE_JE);
    }

    global static void syncCountSessionJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Count_Session__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.COUNT_SESSION_JE);
    }

    global static void syncARPayments(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        if(QBUtil.isQBEnabled()) {
            syncEntity('Payment_on_Account__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.QB_AR_PAYMENT);
        } else {
            syncEntity('AR_Payment__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.AR_Payment);
        }
    }

    global static void syncPaymentsOnAccount(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Payment_on_Account__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.PAYMENT_ON_ACCOUNT);
    }

    global static void syncUnitAdjustments(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Unit_Price_Cost__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.UNIT_PRICE_COST);
    }

    global static void syncCOInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Invoice_Header__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.INVOICE);
    }

    global static void updateCOInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('CO_Invoice_Header__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, 'Update CO Invoice');
    }

    global static void syncCOInvoicePayment(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        if(QBUtil.isQBEnabled()) {
            syncEntity('CO_Invoice_Header__c', 'AccountingId__c != null', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.INVOICE_PAYMENT);
        } else {
            syncEntity('CO_Invoice_Header__c', 'Xero_Accounting_Id__c != null', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.INVOICE_PAYMENT);
        }
    }

    global static void syncFIFOBuckets(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        String whereClauseStr = '((Is_FIFO_Bucket__c = true AND Vendor_Receiving_Header__c = null ' + 
                                'AND Customer_Return__c = null AND Source_Name__c != \'Oversold\') OR (Is_FIFO_Bucket__c = false AND Source_Name__c = \'' + LogService.REOPEN_INVOICE + '\'))';
        syncEntity('Part_FIFO_Bucket__c', whereClauseStr, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.PART_FIFO);
    }

    global static void syncFIFOBucketLineItems(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        String whereClauseStr = 'Part_FIFO_Bucket__r.Is_FIFO_Bucket__c = true AND CO_Invoice_Header__c = null';
        syncEntity('Part_FIFO_Bucket_Activity_Line_Item__c', whereClauseStr, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM);
    }

    global static void syncVRJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        String whereClauseStr = '(Status__c = \'Stocked\' OR Status__c = \'Invoiced\')';
        syncEntity('Vendor_Receiving_Header__c', whereClauseStr, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VENDOR_RECEIVING);
    }

    global static void syncVendorReturn(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        system.assert(false, 'Use script syncVendorCredit().');
    }

    global static void syncVendorCredit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Return_CR_Header__c', 'Status__c = \'Credited\'', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VO_RETURN);
    }

    global static void syncVendorCreditVarianceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Return_CR_Header__c', 'Status__c = \'Credited\'', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VO_RETURN_VARIANCE_JE);
    }

    global static void syncVendorInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Vendor_Invoicing_Header__c', 'Status__c = \'Invoiced\'', maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VO_INVOICE);
    }

    global static void syncStoreCredits(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Store_Credit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.STORE_CREDIT);
    }

    global static void syncHoursLogged(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Hours_Logged__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.HOURS_LOGGED);
    }

    global static void syncUnitNITCJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Customer_Owned_Unit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.UNIT_NITC_JE);
    }

    global static void syncConsignmentUnit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Customer_Owned_Unit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.UNIT_CONSIGNMENT);
    }

    global static void syncVIVarianceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Vendor_Invoicing_Header__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.VO_INVOICE_VARIANCE_JE);
    }

    global static void syncLienPayouts(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Deal_Item__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.LIEN_PAYOUT);
    }

    global static void createXeroIFWConfigAndLineItems() {
        List<IFW_IntegrationConfig__c> ifwConfigUpsertList = IFW_SOQLUtil.getIntegrationConfigWithItems(new Map<String, Object>{'Integration_Name__c' => XeroUtility.XERO});
        List<IFW_IntegrationConfigItem__c> ifwConfigItemUpsertList = new List<IFW_IntegrationConfigItem__c>();
        if(!ifwConfigUpsertList.isEmpty()) {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', ifwConfigUpsertList[0].IFW_IntegrationConfigItems__r);
        } else {
            ifwConfigUpsertList.add(new IFW_IntegrationConfig__c());
        }
        ifwConfigUpsertList[0].Integration_Name__c = XeroUtility.XERO;
        ifwConfigUpsertList[0].Enabled__c = true;
        ifwConfigUpsertList[0].Auth_Scheme__c = 'OAuth2.0';
        ifwConfigUpsertList[0].Integration_Type__c = 'Accounting';
        ifwConfigUpsertList[0].Timeout__c = 120000;
        DMLUtility.upsertSobjectList('IFW_IntegrationConfig__c', ifwConfigUpsertList);
        
        for(String entityName: XeroUtility.entityNameToAccEndPointMap.keySet()) {
            string endpointURL;
            if(entityName == 'Connection') {
                endpointURL = 'https://api.xero.com/';
            } else {
                endpointURL = XeroUtility.XERO_END_POINT_URL;
            }
            if(XeroUtility.entityNameToAccEntityDetailsMap.containsKey(entityName)) {
                for(String httpMethod: XeroUtility.entityNameToAccEntityDetailsMap.get(entityName).keySet()) {
                    IFW_IntegrationConfigItem__c ifwItemRec = new IFW_IntegrationConfigItem__c();
                    ifwItemRec.IFW_IntegrationConfig__c = ifwConfigUpsertList[0].Id;
                    ifwItemRec.Entity_Name__c = entityName;
                    ifwItemRec.Endpoint_URL__c = endpointURL + XeroUtility.entityNameToAccEndPointMap.get(entityName);
                    ifwItemRec.Entity_Action__c = XeroUtility.entityNameToAccEntityDetailsMap.get(entityName).get(httpMethod);
                    ifwItemRec.HTTP_Method__c = httpMethod;
                    ifwItemRec.Timeout__c = 5000;
                    ifwConfigItemUpsertList.add(ifwItemRec);
                }
            }
        }
        DMLUtility.upsertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItemUpsertList);
    }
    
    global static void syncPartCategory(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Part__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.PART_CATEGORY);
    }

    global static void syncUnitCategory(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Customer_Owned_Unit__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.STOCK_UNIT_CATEGORY);
    }

    global static void syncStockedTradeInJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        syncEntity('Deal_Item__c', null, maxNumberOfRecord, timeIntervalForJobsInSec, IntegrationUtility.STOCK_TRADE_IN);
    }
}
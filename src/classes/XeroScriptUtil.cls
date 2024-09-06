/**
 * Author: Nikhil Kumar Srivastava
 * Since: April 04, 2019
 * Name: XeroScriptUtil
 * Description: Apex class for all scripts related to Xero
**/
global class XeroScriptUtil {
	
	public static Map<String, String> entityNameToSyncingEntityNameMap = new Map<String, String> {
	    'CO Invoice' => IntegrationUtility.INVOICE,
	    'FIFO Buckets' => IntegrationUtility.PART_FIFO,
	    'FIFO Buckets Line Items' => IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM,
	    'VR JE' => IntegrationUtility.VENDOR_RECEIVING,
	    'Vendor Return' => IntegrationUtility.VO_RETURN,
	    'Vendor Invoice' => IntegrationUtility.VO_INVOICE,
        'Store Credit' => IntegrationUtility.STORE_CREDIT,
        'Hours Logged' => IntegrationUtility.HOURS_LOGGED,
        'Unit NITC JE' => IntegrationUtility.UNIT_NITC_JE,
        'Unit Consignment' => IntegrationUtility.UNIT_CONSIGNMENT
    };
    
	public static void scheduleJobs(List<sObject> recordList, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize,
                                            String entityType) { 
        scheduleJobs(recordList, maxNumberOfRecord, timeIntervalForJobsInSec, batchSize, entityType, 0);
    }

    public static void scheduleJobs(List<sObject> recordList, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize,
                                            String entityType, Integer schedulerInterval) {
        for(Integer i = 0; i < Math.ceil(recordList.size() / Decimal.valueOf(maxNumberOfRecord)) && i < 99; i++) {
            String cronExp = QBUtil.getCronExpForGivenTime(schedulerInterval + 10 + (i * timeIntervalForJobsInSec));
            Set<Id> recordIdSet = new Set<Id>();
            for(Integer j = (i * maxNumberOfRecord); (j < ((i + 1) * maxNumberOfRecord) && j < recordList.size()); j++) {
                recordIdSet.add(recordList[j].Id);
            }
            system.debug('Record Id Set for Scheduling ' + (i + 1) + '  ' + recordIdSet);
            
            if(entityType == IntegrationUtility.CUSTOMER) {
                QBUtil.abortAlreadyScheduleJobs('Xero Customer Sync ' + i);
                system.schedule('Xero Customer Sync ' + i, cronExp, new AccountingCustomerBatchScheduler(recordIdSet, batchSize));
            } else if(entityType == IntegrationUtility.VENDOR) {
                QBUtil.abortAlreadyScheduleJobs('Xero Vendor Sync ' + i);
                system.schedule('Xero Vendor Sync ' + i, cronExp, new AccountingVendorBatchScheduler(recordIdSet, batchSize));
            } else if(entityType == IntegrationUtility.UNIT_INVOICE) {
                QBUtil.abortAlreadyScheduleJobs('Xero Unit Invoice Sync ' + i);
                system.schedule('Xero Unit Invoice Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.UNIT_INVOICE));
            } else if(entityType == IntegrationUtility.CO_DEPOSIT) {
                QBUtil.abortAlreadyScheduleJobs('Xero CO Deposit Sync ' + i);
                system.schedule('Xero CO Deposit Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.CO_DEPOSIT));
            } else if(entityType == IntegrationUtility.CO_INVOICE_PAYMENT) {
                QBUtil.abortAlreadyScheduleJobs('Xero CO Payment JE Sync ' + i);
                system.schedule('Xero CO Payment JE Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.CO_INVOICE_PAYMENT));
            } else if(entityType == IntegrationUtility.CO_INVOICE_JE) {
                QBUtil.abortAlreadyScheduleJobs('Xero CO Invoice JE Sync ' + i);
                system.schedule('Xero CO Invoice JE Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.CO_INVOICE_JE));
            } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
                QBUtil.abortAlreadyScheduleJobs('Xero Unit Invoice JE Sync ' + i);
                system.schedule('Xero Unit Invoice JE Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.UNIT_INVOICE_JE));
            } else if(entityType == IntegrationUtility.COUNT_SESSION_JE) {
                QBUtil.abortAlreadyScheduleJobs('Xero Count Session JE Sync ' + i);
                system.schedule('Xero Count Session JE Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.COUNT_SESSION_JE));
            } else if(entityType == IntegrationUtility.AR_Payment) {
                QBUtil.abortAlreadyScheduleJobs('AR Payment Sync ' + i);
                system.schedule('AR Payment Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.AR_Payment));
            } else if(entityType == IntegrationUtility.UNIT_PRICE_COST) {
                QBUtil.abortAlreadyScheduleJobs('Xero Unit Adjustment Sync ' + i);
                system.schedule('Xero Unit Adjustment Sync ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.UNIT_PRICE_COST));
            } else if(entityType == 'CO Invoice JE Update') {
                QBUtil.abortAlreadyScheduleJobs('Xero CO Invoice JE Update ' + i);
                system.schedule('Xero CO Invoice JE Update ' + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, IntegrationUtility.CO_INVOICE_JE, true));       
            } else {
                String scheduleJobName = 'Xero ' + entityType + ' Sync ';
                QBUtil.abortAlreadyScheduleJobs(scheduleJobName + i);
                if(entityType == IntegrationUtility.INVOICE) {
                    system.schedule(scheduleJobName + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, 
                        entityType, new List<String>{IntegrationUtility.INVOICE, IntegrationUtility.CO_INVOICE_JE, IntegrationUtility.INVOICE_PAYMENT}));                    
                } else {
                    system.schedule(scheduleJobName + i, cronExp, new AccountingBatchScheduler(recordIdSet, batchSize, entityType));
                }
            }
        }
   }             
            
    global static void syncCustomers(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {
        List<Account> customerList = [Select Id from Account where Is_Customer__c = true AND Available_For_Xero_Customer_Sync__c = true
                                            Order by CreatedDate DESC];
        scheduleJobs(customerList, maxNumberOfRecord, timeIntervalForJobsInSec, batchSize, IntegrationUtility.CUSTOMER, 0);
    }       
    
    global static void syncVendors(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {
        List<Account> vendorList = [Select Id from Account where Is_Vendor__c = true AND Available_For_Xero_Vendor_Sync__c = true 
                                            Order by CreatedDate ASC];
        scheduleJobs(vendorList, maxNumberOfRecord, timeIntervalForJobsInSec, batchSize, IntegrationUtility.VENDOR, 0);
    } 
    
    global static void syncUnitInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Customer_Owned_Unit__c> unitList = 
            [SELECT Id FROM Customer_Owned_Unit__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(unitList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.UNIT_INVOICE, 0);
    }
    
    global static void syncCODeposit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Deposit__c> coDepositList = 
            [SELECT Id FROM CO_Deposit__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coDepositList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.CO_DEPOSIT, 0);
    }
    
    global static void syncCOInvoicePaymentJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Payment__c> coInvoicePaymentList = 
            [SELECT Id FROM CO_Invoice_Payment__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoicePaymentList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.CO_INVOICE_PAYMENT, 0);
    }
    
    global static void syncCOInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c where Available_For_Xero_CO_Invoice_JE_Sync__c = true Order by CreatedDate ASC];
        system.debug('RecOrds' + coInvoiceHeaderList);
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.CO_INVOICE_JE, 0);
    }
    global static void updateCOInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c where Available_For_Xero_CO_Invoice_JE_Sync__c = true Order by CreatedDate ASC ];
            scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, 'CO Invoice JE Update', 0);
    }
    global static void syncUnitInvoiceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Customer_Owned_Unit__c> unitList = 
            [SELECT Id FROM Customer_Owned_Unit__c where Available_For_Xero_Unit_Invoice_JE_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(unitList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.UNIT_INVOICE_JE, 0);
    }
    
    global static void syncCountSessionJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Count_Session__c> countSessionList = 
            [SELECT Id FROM Count_Session__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC]; 
        scheduleJobs(countSessionList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.COUNT_SESSION_JE, 0);
    }
    
    global static void syncARPayments(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<AR_Payment__c> arPaymentList = 
            [SELECT Id FROM AR_Payment__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC]; 
        scheduleJobs(arPaymentList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.AR_Payment, 0);
    }
    
    global static void syncUnitAdjustments(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Unit_Price_Cost__c> unitPriceAndCostList = 
            [SELECT Id FROM Unit_Price_Cost__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(unitPriceAndCostList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.UNIT_PRICE_COST, 0);
    }
    
    global static void syncCOInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c WHERE Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.INVOICE, 0);
    }
    
    global static void syncCOInvoicePayment(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c WHERE Available_For_Xero_Invoice_Payment_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.INVOICE_PAYMENT, 0);
    }
    
    global static void syncFIFOBuckets(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Part_FIFO_Bucket__c> FIFOBucketsList = 
            [SELECT Id FROM Part_FIFO_Bucket__c WHERE Available_For_Xero_Sync__c = true AND Is_FIFO_Bucket__c = true AND Vendor_Receiving_Header__c = null 
                    AND Customer_Return__c = null AND Source_Name__c != 'Oversold' Order by CreatedDate ASC];
        scheduleJobs(FIFOBucketsList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.PART_FIFO, 0);
    }
    
    global static void syncFIFOBucketLineItems(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Part_FIFO_Bucket_Activity_Line_Item__c> FIFOBucketLineItemsList = 
            [SELECT Id FROM Part_FIFO_Bucket_Activity_Line_Item__c where Available_For_Xero_Sync__c = true AND 
                    Part_FIFO_Bucket__r.Is_FIFO_Bucket__c = true AND CO_Invoice_Header__c = null Order by CreatedDate ASC];
        scheduleJobs(FIFOBucketLineItemsList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM, 0);
    }
    
    global static void syncVRJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Vendor_Receiving_Header__c> vrhList = 
            [SELECT Id FROM Vendor_Receiving_Header__c where Available_For_Xero_Sync__c = true AND 
                (Status__c = 'Stocked' OR Status__c = 'Invoiced') Order by CreatedDate ASC];
        scheduleJobs(vrhList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.VENDOR_RECEIVING, 0);
    }
    
    global static void syncVendorReturn(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Return_VO_Header__c> vendorReturnList = [SELECT Id FROM Return_VO_Header__c where Available_For_Xero_Sync__c = true 
                                                        AND Status__c = 'Credited' Order by CreatedDate ASC];
        scheduleJobs(vendorReturnList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.VO_RETURN, 0);
    }
    
    global static void syncVendorInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Vendor_Invoicing_Header__c> vendorInvoiceList = 
                        [SELECT Id FROM Vendor_Invoicing_Header__c WHERE Status__c = 'Invoiced' AND Available_For_Xero_Sync__c = true 
                            Order by CreatedDate ASC];
        scheduleJobs(vendorInvoiceList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.VO_INVOICE, 0);
    }
    
    global static void syncStoreCredits(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Store_Credit__c> storeCreditList = [SELECT Id FROM Store_Credit__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(storeCreditList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.STORE_CREDIT, 0);
    }
    
    global static void syncHoursLogged(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Hours_Logged__c> hoursLogged = [SELECT Id FROM Hours_Logged__c where Available_For_Xero_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(hoursLogged, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.HOURS_LOGGED, 0);
    }
    
    global static void syncUnitNITCJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Customer_Owned_Unit__c> hoursLogged = [SELECT Id FROM Customer_Owned_Unit__c where Available_For_Xero_NITC_JE_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(hoursLogged, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, IntegrationUtility.UNIT_NITC_JE, 0);
    }
    
    global static void syncConsignmentUnit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<Customer_Owned_Unit__c> hoursLogged = [SELECT Id FROM Customer_Owned_Unit__c where Available_For_Xero_Consignment_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(hoursLogged, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, 'Unit Consignment');
    }
}
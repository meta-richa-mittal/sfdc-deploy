global class BRPScriptUtil {
    
    public static void scheduleJobs(List<sObject> recordList, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, String entityType) {
        List<Id> recordIdSet = new List<Id>();
        for(Integer j = 0; j < recordList.size(); j++) {
            recordIdSet.add(recordList[j].Id);
        }            
        scheduleBatchJobs(recordIdSet, maxNumberOfRecord, timeIntervalForJobsInSec, entityType, null);
    }

    public static void scheduleBatchJobs(List<Id> recordIdSet, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, String entityType, Integer retryAttemptNumber) {
        for(Integer i = 0; i < Math.ceil(recordIdSet.size() / Decimal.valueOf(maxNumberOfRecord)) && i < 90; i++) {
            String cronExp = AccountingUtil.getCronExpForGivenTime(BRPUtility.SchedulerTimeInterval + 10 + (i * timeIntervalForJobsInSec));
            Set<Id> recIdSet= new Set<Id>();
            for(Integer j = (i * maxNumberOfRecord); (j < ((i + 1) * maxNumberOfRecord) && j < recordIdSet.size()); j++) {
                recIdSet.add(recordIdSet[j]);
            }            
            if(entityType == 'Parts Invoice') {
                AccountingUtil.abortAlreadyScheduleJobs('BRP Parts Invoice Sync ' + i);
                system.schedule('BRP Parts Invoice Sync ' + i, cronExp, new BRPBatchScheduler(recIdSet, entityType, retryAttemptNumber));
            } else if(entityType == 'Repair Order') {
                AccountingUtil.abortAlreadyScheduleJobs('BRP Repair Order Sync ' + i);
                system.schedule('BRP Repair Order Sync ' + i, cronExp, new BRPBatchScheduler(recIdSet, entityType, retryAttemptNumber));
            } else if(entityType == 'Retail Delivery Reporting') {
                AccountingUtil.abortAlreadyScheduleJobs('BRP Retail Delivery Reporting Sync ' + i);
                system.schedule('BRP Retail Delivery Reporting Sync ' + i, cronExp, new BRPBatchScheduler(recIdSet, entityType, retryAttemptNumber));
            }
        }
    }

    global static void syncBRPPartsInvoice(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c where Available_For_BRP_Parts_Invoice_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, 'Parts Invoice');
    }

    global static void syncBRPRepairOrder(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c where Available_For_BRP_Repair_Order_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, 'Repair Order');
    }

    global static void syncBRPRetailDeliveryReporting(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceHeaderList = 
            [SELECT Id FROM CO_Invoice_Header__c where Available_For_BRP_RDR_Sync__c = true Order by CreatedDate ASC];
        scheduleJobs(coInvoiceHeaderList, maxNumberOfRecord, timeIntervalForJobsInSec, 'Retail Delivery Reporting');
    }
}
global class BRPScriptUtil {
    
    private static void scheduleJobs(List<sObject> recordList, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, String entityType) {
        for(Integer i = 0; i < Math.ceil(recordList.size() / Decimal.valueOf(maxNumberOfRecord)) && i < 90; i++) {
            String cronExp = QBUtil.getCronExpForGivenTime(10 + (i * timeIntervalForJobsInSec));
            Set<Id> recordIdSet = new Set<Id>();
            for(Integer j = (i * maxNumberOfRecord); (j < ((i + 1) * maxNumberOfRecord) && j < recordList.size()); j++) {
                recordIdSet.add(recordList[j].Id);
            }            
            if(entityType == 'Parts Invoice') {
                QBUtil.abortAlreadyScheduleJobs('BRP Parts Invoice Sync ' + i);
                system.schedule('BRP Parts Invoice Sync ' + i, cronExp, new BRPBatchScheduler(recordIdSet, entityType));
            } else if(entityType == 'Repair Order') {
                QBUtil.abortAlreadyScheduleJobs('BRP Repair Order Sync ' + i);
                system.schedule('BRP Repair Order Sync ' + i, cronExp, new BRPBatchScheduler(recordIdSet, entityType));
            } else if(entityType == 'Retail Delivery Reporting') {
                QBUtil.abortAlreadyScheduleJobs('BRP Retail Delivery Reporting Sync ' + i);
                system.schedule('BRP Retail Delivery Reporting Sync ' + i, cronExp, new BRPBatchScheduler(recordIdSet, entityType));
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
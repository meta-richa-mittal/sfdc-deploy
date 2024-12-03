/**
 * Author: Manoj Sharma
 * Since: Sept 17, 2025
 * Name: SyncAccountingTransactionsScheduler
 * Description: Scheduler class to sync failed accounting transactions
**/ 
global without sharing class SyncAccountingTransactionsScheduler implements Database.Batchable<Object>, Schedulable, Database.Stateful {
    public List<String> failedEntityNameList = new List<String>();
    public List<String> resyncEntityNameList;
    
    global SyncAccountingTransactionsScheduler() {
        this.resyncEntityNameList = new List<String>();
    }

    global SyncAccountingTransactionsScheduler(List<String> resyncEntityNames) {
        this.resyncEntityNameList = resyncEntityNames;
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncAccountingTransactionsScheduler(), 1);
    }

    global Iterable<Object> start(Database.BatchableContext bc) {
        List<AdminAccountingSyncFailureWrapper.SyncFailureWrapper> syncFailures = AdminConfigService.getAccountingSyncFailureDetails(true);
        return syncFailures;
    }
    
    global void execute(Database.batchableContext bc, List<Object> syncFailures) {
        if(this.resyncEntityNameList != null && !this.resyncEntityNameList.isEmpty()) {
            for(String entityName : this.resyncEntityNameList) {
                AdminConfigService.executeAccountingScript(entityName);
            }
            this.resyncEntityNameList = new List<String>();
        } else {
            List<AdminAccountingSyncFailureWrapper.SyncFailureWrapper> syncFailuresList = (List<AdminAccountingSyncFailureWrapper.SyncFailureWrapper>) syncFailures;
            if(!syncFailuresList.isEmpty()) {
                for(AdminAccountingSyncFailureWrapper.SyncFailureWrapper syncFailure : syncFailuresList) {
                    if(String.isNotBlank(syncFailure.FailureCount) && syncFailure.FailureCount != '0') {
                        try {
                            AdminConfigService.executeAccountingScript(syncFailure.EntityName);
                        } catch(Exception e) {
                            this.failedEntityNameList.add(syncFailure.EntityName);
                        }
                    }
                }
            }
        }
    }
    

    global void finish(Database.batchableContext bc) {
        if(this.failedEntityNameList != null && !this.failedEntityNameList.isEmpty()) {
            System.enqueueJob(new SyncAccountingTransactionsQueueable(this.failedEntityNameList), 10);
        } 
    }
    
    global static void executeScheduler() {
        ScheduleJobService.scheduleJobs(new Set<String> {ScheduleJobService.SYNC_ACCOUNTING_TRANSACTIONS_SCHEDULER});
    }
}
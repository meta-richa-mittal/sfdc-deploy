/**
 * Author: Nidhi Sharma
 * Since: March 26, 2024
 * Name: TaxActivityAndSettingCtrl
 * Description: 
**/
public without sharing class ScheduleJobService {

    public static final String SHOPIFY_FETCH_ORDERS = 'Shopify Fetch Orders';

    public static final String INTEGRATION_INTEGRITY_CHECK_SCHEDULER = 'Integration Integrity Check Scheduler'; //Old QB/XERO job name
    public static final String INTEGRITY_CHECK_FOR_QBO = 'Integrity Check For QuickBooks Online'; //Old QB job name
    public static final String INTEGRITY_CHECK_FOR_XERO = 'Integrity Check For Xero'; //Old QB job name
    
    public static final String ACCOUNTING_INTEGRITY_CHECK_SCHEDULER = 'Accounting Integrity Check Scheduler';
    public static final String INTEGRITY_CHECK_FOR_BRP = 'Integrity Check For BRP';
    public static final String INTEGRITY_CHECK_FOR_SHOPIFY = 'Shopify Integration Integrity Check Scheduler';
    
    public static final String SOM = 'SOM';
    public static final String PAYROLL_JOB_CLOCKING_AUTO_CLOCK_OFF_SCHEDULER = 'Payroll/Job Clocking Auto Clock Off Scheduler';

    public static final String SEND_DMS_INFO_TO_BRP = 'SendDMSInfoToBRP';
    public static final String BRP_PART_INVENTORY_SCHEDULER = 'BRP Part Inventory Scheduler';
    public static final String BRP_PARTS_MASTER_SCHEDULER = 'BRP Parts Master Scheduler';

    public static final String ACCOUNTING_RECONCILITAION = 'Accounting Reconciliation';
    public static final String ACCOUNTING_RECONCILITAION_NOTIFICATION = 'Accounting Reconciliation Notification';

    public static final String PART_SYNC_AGE_BATCH_SCHEDULAR = 'PartSyncAgeBatch_Schedular';
    public static final String ACCOUNTING_AR_BALANCE_SCHEDULER = 'Accounting AR Balance Scheduler';
    public static final String OUTDATED_DATA_CLEANUP_BATCH_SCH = 'OutdatedDataCleanupBatchSch';
    public static final String XE_CURRENCY_CONVERSION_SCH = 'XE Currency Rate Conversion Schedular';
    public static final String ARCHIVE_DELETE_QUOTE_CO_SCHEDULER = 'Archive/Delete Quote CO Scheduler';
    public static final String DELETE_QUOTED_VOLI_SCHEDULER = 'Delete quoted VOLI Scheduler';
    public static final String INCORRECT_COMMITTED_PARTS_ALERT = 'Incorrect Committed Parts Alert';
    public static final String APF_IMPORT_SCHEDULER = 'APF Import Scheduler';
    public static final String SYNC_ACCOUNTING_TRANSACTIONS_SCHEDULER = 'Sync Accounting Transactions Scheduler';

    public static Map<String, String> jobNameToCronExpMap = new Map<String, String>{
        //SHOPIFY_FETCH_ORDERS => '0 0 22 ? * * *',
        ACCOUNTING_INTEGRITY_CHECK_SCHEDULER => '0 0 20 ? * * *',
        INTEGRITY_CHECK_FOR_BRP => '0 0 21 ? * * *',
        INTEGRITY_CHECK_FOR_SHOPIFY => '0 30 21 ? * * *',
        //SOM => '0 0 22 ? * * *',
        PAYROLL_JOB_CLOCKING_AUTO_CLOCK_OFF_SCHEDULER => '0 0 23 ? * * *',
        SEND_DMS_INFO_TO_BRP => '0 0 23 ? * * *',
        BRP_PART_INVENTORY_SCHEDULER => '0 15 23 ? * * *',
        BRP_PARTS_MASTER_SCHEDULER => '0 30 23 ? * * *',
        ACCOUNTING_RECONCILITAION => '0 0 1 ? * * *',
        ACCOUNTING_RECONCILITAION_NOTIFICATION => '0 30 1 ? * * *',
        PART_SYNC_AGE_BATCH_SCHEDULAR => '0 0 2 ? * * *',
        ACCOUNTING_AR_BALANCE_SCHEDULER => '0 0 3 ? * * *',
        OUTDATED_DATA_CLEANUP_BATCH_SCH => '0 0 4 ? * * *',
        XE_CURRENCY_CONVERSION_SCH => '0 15 4 ? * * *',
        ARCHIVE_DELETE_QUOTE_CO_SCHEDULER => '0 30 4 ? * * *',
        DELETE_QUOTED_VOLI_SCHEDULER => '0 0 5 ? * * *',
        INCORRECT_COMMITTED_PARTS_ALERT => '0 30 22 ? * * *',
        SYNC_ACCOUNTING_TRANSACTIONS_SCHEDULER => '0 30 19 ? * * *'
    };

    private static Map<String, Type> jobNameToScheduleableClassMap = new Map<String, Type>{
        INCORRECT_COMMITTED_PARTS_ALERT => SupportAlertScheduler.class,
        SYNC_ACCOUNTING_TRANSACTIONS_SCHEDULER => SyncAccountingTransactionsScheduler.class
    };

    public static void rescheduleJobs(Set<String> jobNames) {
        //abort given jobs and resync aborted one only
        List<String> alreadyScheduledJobNames = abortAlreadyScheduledJobs(jobNames);
        for(String jobName : jobNames) {
            if(alreadyScheduledJobNames.contains(jobName.toLowerCase())) {
                try {
                	scheduleJob(jobName);
                } catch(AsyncException e) {
                    if(!e.getMessage().containsIgnoreCase('is already scheduled for execution.')) {
                        throw e;
                    }
                }
            }
        }
    }
    
    //For new orgs
    public static void scheduleJobsOnNewOrgs() {
        //ACCOUNTING_RECONCILITAION, ACCOUNTING_RECONCILITAION_NOTIFICATION,
        BPScriptManager.scheduleAccountingReconciliations();
        Set<String> jobNames = new Set<String>{
            PAYROLL_JOB_CLOCKING_AUTO_CLOCK_OFF_SCHEDULER, ARCHIVE_DELETE_QUOTE_CO_SCHEDULER, DELETE_QUOTED_VOLI_SCHEDULER,
            PART_SYNC_AGE_BATCH_SCHEDULAR, OUTDATED_DATA_CLEANUP_BATCH_SCH
        };
        scheduleJobs(jobNames);
    }

    public static void scheduleJobs(Set<String> jobNames) {
        //abort given jobs and sync all given jobs
        abortAlreadyScheduledJobs(jobNames);
        for(String jobName : jobNames) {
            scheduleJob(jobName);
        }
    }

    public static void scheduleJob(String jobName) {
        if(String.isNotBlank(jobName)) {
            if(jobName.equalsIgnoreCase(ACCOUNTING_INTEGRITY_CHECK_SCHEDULER) || jobName.equalsIgnoreCase(INTEGRATION_INTEGRITY_CHECK_SCHEDULER) ||
            jobName.equalsIgnoreCase(INTEGRITY_CHECK_FOR_QBO) || jobName.equalsIgnoreCase(INTEGRITY_CHECK_FOR_XERO)) {
                String newJobName = ACCOUNTING_INTEGRITY_CHECK_SCHEDULER;
                if(QBUtil.isQBEnabled()) {
                    system.schedule(newJobName, getAdjustedCronExpByJobName(newJobName), new IntegrityCheckForQBScheduler());
                } else if(XeroUtility.isXeroEnabled()) {
                    system.schedule(newJobName, getAdjustedCronExpByJobName(newJobName), new IntegrityCheckForAccIntegrationSch());
                }
            } else if(jobName.equalsIgnoreCase(INTEGRITY_CHECK_FOR_BRP)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new IntegrityCheckForBRPScheduler());
            } else if(jobName.equalsIgnoreCase(INTEGRITY_CHECK_FOR_SHOPIFY)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new IntegrationIntegrityCheckScheduler());
            } else if(jobName.equalsIgnoreCase(PAYROLL_JOB_CLOCKING_AUTO_CLOCK_OFF_SCHEDULER)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new PayrollAndJobClockingAutoClockOffBatch());
            } else if(jobName.equalsIgnoreCase(ACCOUNTING_RECONCILITAION)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new AccountingReconciliationScheduler());
            } else if(jobName.equalsIgnoreCase(ACCOUNTING_RECONCILITAION_NOTIFICATION)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new AccountingReconciliationAlertScheduler());
            } else if(jobName.equalsIgnoreCase(PART_SYNC_AGE_BATCH_SCHEDULAR)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new PartSyncAgeBatch_Schedular());
            } else if(jobName.equalsIgnoreCase(SEND_DMS_INFO_TO_BRP)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new BRPSendDMSInfoScheduler() );
            } else if(jobName.equalsIgnoreCase(BRP_PART_INVENTORY_SCHEDULER)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new BRPPartInventoryScheduler(null) );
            } else if(jobName.equalsIgnoreCase(BRP_PARTS_MASTER_SCHEDULER)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new BRPPartsMasterBatch() );
            } else if(jobName.equalsIgnoreCase(ACCOUNTING_AR_BALANCE_SCHEDULER)) {
                BPScriptManager.schedulePopulateInvoiceARBalanceScheduler();
            } else if(jobName.equalsIgnoreCase(OUTDATED_DATA_CLEANUP_BATCH_SCH)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new OutdatedDataCleanupBatchSch('File'));
            } else if(jobName.equalsIgnoreCase(XE_CURRENCY_CONVERSION_SCH)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new FXCurrencyConversionScheduler());
            } else if(jobName.equalsIgnoreCase(ARCHIVE_DELETE_QUOTE_CO_SCHEDULER)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new ArchiveDeleteCOBatchScheduler());
            } else if(jobName.equalsIgnoreCase(DELETE_QUOTED_VOLI_SCHEDULER)) {
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), new DeleteScheduler());
            } else if(jobNameToScheduleableClassMap.containsKey(jobName)) {
                Schedulable classInstance = (Schedulable)jobNameToScheduleableClassMap.get(jobName).newInstance(); // Create schedulable interface instance
                system.schedule(jobName, getAdjustedCronExpByJobName(jobName), classInstance);
            }
        }
    }

    public static String getAdjustedCronExpByJobName(String jobName) {
        String cronExp = '0 0 22 ? * * *';
        if(jobNameToCronExpMap.containsKey(jobName)) {
            cronExp = jobNameToCronExpMap.get(jobName);
        }
        return adjustCronExpression(cronExp);
    }

    public static String adjustCronExpression(String cronExpression) {
        DateTime currentDateTime = System.Now();
        System.TimeZone corePackageTZ = UserInfo.getTimeZone();
        Integer corePackageUserOffset = corePackageTZ.getOffset(currentDateTime) / (1000 * 60);

        String bpAdminTZSIDKey = [SELECT Id, TimeZoneSidKey FROM User WHERE Profile.Name = 'System Administrator' Order By CreatedDate LIMIT 1].TimeZoneSidKey;
        Integer bpAdminUserOffset = (System.Timezone.getTimeZone(bpAdminTZSIDKey)).getOffset(currentDateTime) / (1000 * 60); 

        String[] cronParts = cronExpression.split(' ');
        Integer hour = Integer.valueOf(cronParts[2]);
        Integer minute = Integer.valueOf(cronParts[1]);
        Integer second = Integer.valueOf(cronParts[0]);
        Integer totalOffset = (corePackageUserOffset - bpAdminUserOffset);
        
        System.debug('corePackageUserOffset: ' + corePackageUserOffset);
        System.debug('bpAdminUserOffset: ' + bpAdminUserOffset);
        System.debug('totalOffset: ' + totalOffset);
        
        if(totalOffset != 0) {
            totalOffset += (minute + hour*60);
            hour = Math.Mod((totalOffset / 60), 24);
            minute = Math.Mod(totalOffset, 60);
            if(minute < 0) {
                hour--;
                minute = 60 + minute;
            }
            if(hour < 0) {
                hour = 24 + hour;
            }
        }
        System.debug('hour: ' + hour);
        System.debug('minute: ' + minute);
        System.debug('second: ' + second);

        // Build the adjusted cron expression
        String adjustedCronExpression = second + ' ' + minute + ' ' + hour + ' ' + cronParts[3] + ' ' + cronParts[4] + ' ' + cronParts[5];
        System.debug('adjustedCronExpression: ' + adjustedCronExpression);
        return adjustedCronExpression;
    }

    private static List<String> abortAlreadyScheduledJobs(Set<String> jobNames) {
        List<String> alreadyScheduledJobNames = new List<String>();
        if(jobNames != null && !jobNames.isEmpty()) {
            for(CronTrigger alreadyScheduledJob : [Select Id, CronJobDetail.Name from CronTrigger where CronJobDetail.Name IN: jobNames]) {
                alreadyScheduledJobNames.add(alreadyScheduledJob.CronJobDetail.Name.toLowerCase());
                system.abortJob(alreadyScheduledJob.Id);    
            }
        }
        return alreadyScheduledJobNames;
    }

    public static void scheduleAPFJobs() {
        String jobName = APF_IMPORT_SCHEDULER + '%';
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name Like :jobName LIMIT 1];
        if(alreadyScheduledJobs.isEmpty()) {
            Integer count = 1;
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 0 * * * ?', new APFImportScheduler());
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 10 * * * ?', new APFImportScheduler());
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 20 * * * ?', new APFImportScheduler());
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 30 * * * ?', new APFImportScheduler());
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 40 * * * ?', new APFImportScheduler());
            System.schedule(APF_IMPORT_SCHEDULER + ' ' + count++, '0 50 * * * ?', new APFImportScheduler());
        }
    }
}
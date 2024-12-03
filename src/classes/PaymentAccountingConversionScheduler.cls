global without sharing class PaymentAccountingConversionScheduler implements Schedulable {
    public static String scheduleJobName = 'Payment Accounting Conversion Scheduler';
    global void execute(SchedulableContext sc) { 
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Use_New_Payment_Accounting__c = true;
        generalConfig.New_Payment_Accounting_Enable_Time__c = System.now();
        DMLUtility.updateSobjectList('General_Configurations__c', generalConfig);
        BPUtility.abortAlreadyScheduleJobs(scheduleJobName);

    }
}
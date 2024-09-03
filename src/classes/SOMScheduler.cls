/**
 * Author: Nidhi Sharma
 * Since: Nov 28, 2019
 * Name: SOMScheduler
 * Description: Scheduler class for SOM file generation
**/
global without sharing class SOMScheduler implements Schedulable {
    
    global Integer batchSize;
    global Date exportDate;
    
    global SOMScheduler(Integer batchSize) {
        this.batchSize = (batchSize != null) ? batchSize : 500;
    }
    
    global SOMScheduler(Date exportDate) {
        this.exportDate = exportDate;
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DisableSOMFlagOnPartBatch(system.today()), 2000);
    }
    
    public static void runNextJobAt10PM(Date dateToRun) {
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'SOM file generation'];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
        String CRON_EXP = '0 0 22 ? * * *';
        system.schedule('SOM file generation', CRON_EXP, new SOMScheduler(dateToRun));
    }
}
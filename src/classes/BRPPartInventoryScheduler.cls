/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: BRPPartInventoryScheduler 
* Description: Apex class to Schedule BRP part inventory posting batch.
**/
global without sharing class BRPPartInventoryScheduler implements Schedulable {
    global Date exportDate;
    
    global BRPPartInventoryScheduler(Date exportDate) {
        this.exportDate = exportDate;
    }
    
    global void execute(SchedulableContext sc) {
        if(!BRPUtility.isBRPEnabled()) {
            runNextJobAt10PM(exportDate.addDays(1));
            return;
        }
        this.exportDate = (exportDate != null) ? exportDate : system.today();
        Set<String> brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        List<Part__c> brpPartList = [SELECT Name, BRP_Part_Index__c FROM Part__c WHERE BRP_Part_Index__c != 1 AND Vendor__c IN :brpVendorsIdSet LIMIT 1];
        if(brpPartList.size() > 0) {
        	SetBRPPartIndexBatch brpPartIndexBatchObj = new SetBRPPartIndexBatch(1, this.exportDate);
        	brpPartIndexBatchObj.isExecutePartInvBatch = true;
            Database.executeBatch(brpPartIndexBatchObj, 2000);
        } else {
            Database.executeBatch(new DisableFlagOnPartForBRP(this.exportDate), 2000);
        }
    }
    
    public static void runNextJobAt10PM() {
        runNextJobAt10PM(null);
    }
    
    public static void runNextJobAt10PM(Date dateToRun) {
        String jobName = ScheduleJobService.BRP_PART_INVENTORY_SCHEDULER;

        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
	    system.schedule(jobName, ScheduleJobService.getAdjustedCronExpByJobName(jobName), new BRPPartInventoryScheduler(dateToRun));
    }
}
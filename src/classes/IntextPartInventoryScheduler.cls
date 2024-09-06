/** 
* Author: Richa Mittal
* Since: Dec 07, 2020 
* Name: IntextPartInventoryScheduler 
* Description: Apex class to Schedule Intext part inventory posting batch.
**/
global without sharing class IntextPartInventoryScheduler implements Schedulable {
    global Date exportDate;
    
    global IntextPartInventoryScheduler(Date exportDate) {
        this.exportDate = exportDate;
    }
    
    global void execute(SchedulableContext sc) {
        this.exportDate = (exportDate != null) ? exportDate : system.today();
        List<Part__c> intextPartList = [SELECT Name, Intext_Part_Index__c FROM Part__c WHERE Intext_Part_Index__c = null AND Publish_In_Feeds__c = true LIMIT 1];
        if(intextPartList.size() > 0) {
        	SetIntextPartIndexBatch intextPartIndexBatchObj = new SetIntextPartIndexBatch(1, this.exportDate);
        	intextPartIndexBatchObj.isExecutePartInvBatch = true;
            Database.executeBatch(intextPartIndexBatchObj, 2000);
        } else {
            Database.executeBatch(new DisableFlagOnPartForIntext(this.exportDate), 2000);
        }
    }
    
    public static void runNextJobAt5PM() {
        runNextJobAt5PM(null);
    }
    
    public static void runNextJobAt5PM(Date dateToRun) {
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Intext Part Inventory Scheduler'];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
        
        String cronExp = '0 0 17 ? * * *';
        system.schedule('Intext Part Inventory Scheduler', cronExp, new IntextPartInventoryScheduler(dateToRun));
    }
}
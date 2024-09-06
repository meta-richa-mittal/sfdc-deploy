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
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'BRP Part Inventory Scheduler'];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
        
        String cronExp = BRPUtility.getCronExpression();
        system.schedule('BRP Part Inventory Scheduler', cronExp, new BRPPartInventoryScheduler(dateToRun));
    }
}
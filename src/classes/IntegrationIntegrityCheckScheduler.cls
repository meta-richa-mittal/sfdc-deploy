/** 
* Author: Manoj Sharma
* Since: July 29, 2021
* Name: IntegrationIntegrityCheckScheduler 
* Description: Commonn Scheduler class for Scheduling nightly support notification for async records.
**/
global without sharing class IntegrationIntegrityCheckScheduler implements Schedulable {    
    
    public void execute(SchedulableContext sc) {
        IntegrationIntegrityCheckService.checkIFWForIntegrityMail(); 
    }
     
    global void executeEmailScheduler() { 
        String CRON_EXP = '0 0 0 * * ? *';
	    system.schedule('Integration Integrity Check Scheduler' , CRON_EXP, new IntegrationIntegrityCheckScheduler());
    }
}
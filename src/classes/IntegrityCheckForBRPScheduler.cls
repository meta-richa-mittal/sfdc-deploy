/** 
* Author: Reena Singh
* Since: July 09, 2020 
* Name: IntegrityCheckForBRPScheduler 
* Description: Apex class to integrity check for BRP.
**/
global without sharing class IntegrityCheckForBRPScheduler implements Schedulable {
	
    global void execute(SchedulableContext sc) {
    	new IntegrityCheckForBRPCtrl().sendIntegrityCheckMailToSupportTeam();
    }
    
    global void executeEmailScheduler() {
	    String jobName = ScheduleJobService.INTEGRITY_CHECK_FOR_BRP;
	    system.schedule(jobName, ScheduleJobService.jobNameToCronExpMap.get(jobName), new IntegrityCheckForBRPScheduler() );
    }
}
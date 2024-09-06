/**
 * Author: Rajat Jain
 * Since: May 30, 2018
 * Name: IntegrityCheckForQBScheduler
 * Description: Scheduler class for IntegrityCheckForQBScheduler
**/ 
global without sharing class IntegrityCheckForQBScheduler implements Schedulable {
	
    global void execute(SchedulableContext sc) {
    	new IntegrityCheckForQBCtrl().sendIntegrityCheckMailToSupportTeam();
    }
    
    global void executeEmailScheduler() {
        String jobName = ScheduleJobService.ACCOUNTING_INTEGRITY_CHECK_SCHEDULER;
	    system.schedule(jobName, ScheduleJobService.jobNameToCronExpMap.get(jobName), new IntegrityCheckForQBScheduler());
    }
}
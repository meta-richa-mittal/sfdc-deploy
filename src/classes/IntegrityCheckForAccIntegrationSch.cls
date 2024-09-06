/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 14, 2019
 * Name: IntegrityCheckForAccIntegrationSch
 * Description: Scheduler class for IntegrityCheckForAccIntegrationSch
**/ 
global without sharing class IntegrityCheckForAccIntegrationSch implements Schedulable {
    
    public String accountingIntegrationName;
    
    global IntegrityCheckForAccIntegrationSch() {
    	accountingIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
    }
    
    global void execute(SchedulableContext sc) {
    	if(accountingIntegrationName.equalsIgnoreCase('XERO')) {
    		new IntegrityCheckForActiveAccIntegrtionCtrl().sendIntegrityCheckMailToSupportTeam();
    	}
    }
     
    global void executeEmailScheduler() { 
	    if(accountingIntegrationName.equalsIgnoreCase('XERO')) {
			String jobName = ScheduleJobService.ACCOUNTING_INTEGRITY_CHECK_SCHEDULER;
	    	system.schedule(jobName, ScheduleJobService.jobNameToCronExpMap.get(jobName), new IntegrityCheckForAccIntegrationSch());
	   	}
    }
}
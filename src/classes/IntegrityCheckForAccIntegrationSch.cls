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
	    String CRON_EXP = '0 0 0 * * ? *'; 
	   	if(accountingIntegrationName.equalsIgnoreCase('XERO')) {
	    	system.schedule('Integrity Check For Xero', CRON_EXP, new IntegrityCheckForAccIntegrationSch());
	   	}
    }
}
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
	    String CRON_EXP = '0 10 0 * * ? *';
	    system.schedule('Integrity Check For BRP', CRON_EXP, new IntegrityCheckForBRPScheduler() );
    }
}
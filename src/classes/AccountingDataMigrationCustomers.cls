/**
 * Author: Ashish Garg
 * Since: Dec. 18, 2015
 * Name: AccountingDataMigrationCustomers
 * Description: Class is used for migration of Customer object records to  Accounting Software
**/
global without sharing class AccountingDataMigrationCustomers implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationCustomers() {}
	global AccountingDataMigrationCustomers(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationCustomers(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationCustomers(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	 
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;} 
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
	
}
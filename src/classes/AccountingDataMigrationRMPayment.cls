/**
 * Author: Ashish Garg
 * Since: Dec. 23, 2015
 * Name: AccountingDataMigrationRMPayment
 * Description: Class is used for migration of Payment records to  Accounting Software
**/
global without sharing class AccountingDataMigrationRMPayment implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationRMPayment() {}
	global AccountingDataMigrationRMPayment(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationRMPayment(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationRMPayment(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
    global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
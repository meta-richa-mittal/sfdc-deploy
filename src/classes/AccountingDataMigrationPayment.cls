/**
 * Author: Ashish Garg
 * Since: Dec. 23, 2015
 * Name: AccountingDataMigrationPayment
 * Description: Class is used for migration of Payment records to  Accounting Software
**/
global without sharing class AccountingDataMigrationPayment implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationPayment() {}
	global AccountingDataMigrationPayment(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationPayment(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationPayment(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Iterable<Sobject> start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
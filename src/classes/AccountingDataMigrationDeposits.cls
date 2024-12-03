/**
 * Author: Ashish Garg
 * Since: Dec. 18, 2015
 * Name: AccountingDataMigrationDeposits
 * Description: Class is used for migration of Deposit records to  Accounting Software
**/
global without sharing class AccountingDataMigrationDeposits implements Database.batchable<sObject>, Database.Stateful {
	
	global AccountingDataMigrationDeposits() {}
	global AccountingDataMigrationDeposits(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationDeposits(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationDeposits(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
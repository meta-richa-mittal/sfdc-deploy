/**
 * Author: Ashish Garg
 * Since: Jan. 12, 2016
 * Name: AccountingDataMigrationVendors
 * Description: Class is used for migration of Supplier object records to  Accounting Software
 * Class not in Use. Can't remove from Package due to it's Global nature.
**/
global without sharing class AccountingDataMigrationVendors implements Database.batchable<sObject>, Database.Stateful {
	
	global AccountingDataMigrationVendors() {}
	global AccountingDataMigrationVendors(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationVendors(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
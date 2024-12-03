/**
 * Author: Ashish Garg
 * Since: Dec. 18, 2015
 * Name: AccountingDataMigrationSalesInvoice
 * Description: Class is used for migration of Sales Invoice (Customer Order Invoice) records to  Accounting Software
**/
global without sharing class AccountingDataMigrationSalesInvoice implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationSalesInvoice() {}
	global AccountingDataMigrationSalesInvoice(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationSalesInvoice(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationSalesInvoice(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
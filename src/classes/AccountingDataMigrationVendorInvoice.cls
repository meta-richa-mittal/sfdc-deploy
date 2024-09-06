/**
 * Author: Ashish Garg
 * Since: Jan. 13, 2015
 * Name: AccountingDataMigrationVendorInvoice
 * Description: Class is used for migration of Vendor Invoice (Vendor Order Invoice) records to  Accounting Software
**/
global without sharing class AccountingDataMigrationVendorInvoice implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationVendorInvoice() {}
	global AccountingDataMigrationVendorInvoice(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationVendorInvoice(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationVendorInvoice(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
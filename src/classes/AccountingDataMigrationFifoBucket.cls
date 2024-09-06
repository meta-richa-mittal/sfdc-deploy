global without sharing class AccountingDataMigrationFifoBucket implements Database.batchable<sObject>,Database.Stateful {
	
	global AccountingDataMigrationFifoBucket() {}
	global AccountingDataMigrationFifoBucket(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationFifoBucket(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccountingDataMigrationFifoBucket(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {return null;} 
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
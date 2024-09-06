global without sharing class AccDataMigrationFIFOBkt implements Database.batchable<sObject>,Database.Stateful {
	
	global AccDataMigrationFIFOBkt() {}
	global AccDataMigrationFIFOBkt(List<Id> recordIds, boolean exportAllData) {}
	global AccDataMigrationFIFOBkt(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	global AccDataMigrationFIFOBkt(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
	
	global Iterable<Sobject> start(Database.BatchableContext BC) {return null;}
	global void execute(Database.BatchableContext BC, List<sObject> scope) {}
	global void finish(Database.BatchableContext BC) {}
}
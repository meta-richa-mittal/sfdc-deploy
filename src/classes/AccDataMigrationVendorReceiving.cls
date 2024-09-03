/**
 * Author: Nikhil Kumar Srivastava
 * Since: Dec. 26, 2018
 * Name: AccDataMigrationVendorReceiving
 * Description: Class is used for migration of Vendor Receiving object records to  Accounting Software(MYOB)
**/ 
global without sharing class AccDataMigrationVendorReceiving implements Database.batchable<sObject>, Database.Stateful {
    
    global AccDataMigrationVendorReceiving() {}
	global AccDataMigrationVendorReceiving(List<Id> recordIds, boolean exportAllData) {}
	global AccDataMigrationVendorReceiving(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
	
    global AccDataMigrationVendorReceiving(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
    
   	global Iterable<Sobject> start(Database.BatchableContext BC) {return null;}
    global void execute(Database.BatchableContext BC, List<sObject> scope) {}
    global void finish(Database.BatchableContext BC) {}
}
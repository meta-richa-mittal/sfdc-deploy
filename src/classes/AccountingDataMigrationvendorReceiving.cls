/**
 * Author: Ashish Garg
 * Since: Jan. 13, 2015
 * Name: AccountingDataMigrationvendorReceiving
 * Description: Class is used for migration of Vendor Receiving object records to  Accounting Software
**/ 
global without sharing class AccountingDataMigrationvendorReceiving implements Database.batchable<sObject>, Database.Stateful {
    
    global AccountingDataMigrationvendorReceiving() {}
	global AccountingDataMigrationvendorReceiving(List<Id> recordIds, boolean exportAllData) {}
	global AccountingDataMigrationvendorReceiving(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
    global AccountingDataMigrationVendorReceiving(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {} 
    
    global Database.QueryLocator start(Database.BatchableContext BC) {return null;}
    global void execute(Database.BatchableContext BC, List<sObject> scope) {}
    global void finish(Database.BatchableContext BC) {}
    
}
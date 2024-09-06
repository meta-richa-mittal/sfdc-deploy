/**
 * Author: Nidhi Sharma
 * Since: Sep. 05, 2018
 * Name: MYOBSalesInvoice
 * Description: Class is used for migration of Sales Invoice (Customer Order Invoice) records to  Accounting Software
**/
global without sharing class MYOBSalesInvoice implements Database.batchable<sObject>,Database.Stateful {
    
    global MYOBSalesInvoice() {}
    global MYOBSalesInvoice(List<Id> recordIds, boolean exportAllData) {}
    global MYOBSalesInvoice(List<Id> recordIds, boolean exportAllData, String timePeriod, DateTime fromDate, DateTime toDate) {}
    global MYOBSalesInvoice(List<Id> recordIds, String timePeriod, DateTime fromDate, DateTime toDate, String objNameToExport) {}
    
    global Iterable<Sobject> start(Database.BatchableContext BC) {return null;}
    global void execute(Database.BatchableContext BC, List<sObject> scope) {}
    global void finish(Database.BatchableContext BC) {}
}
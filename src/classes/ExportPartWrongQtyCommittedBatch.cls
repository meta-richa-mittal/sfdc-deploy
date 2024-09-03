/**
 * Author: Namarta Gocher
 * Since: December 19, 2022
 * Name: ExportPartWrongQtyCommittedBatch
 * Description: Email Parts with negative Committed Qty.
**/
global without sharing class ExportPartWrongQtyCommittedBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String fileData = '';
    private List<Log__c> logList = new List<Log__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	return Database.getQueryLocator('SELECT Id, Part_Number__c, Vendor_Name__c, Qty_Committed__c FROM Part__c WHERE Qty_Committed__c < 0');
    }

    global void execute(Database.batchableContext bc, List<sObject> partList) {
        try {
            for(Part__c partRec: (List<Part__c>)partList) {
                fileData += partRec.Part_Number__c + ',';
                fileData += partRec.Vendor_Name__c + ',';
                fileData += String.valueOf(partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0) + ',';
                fileData += (System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + partRec.Id) + '\n';
            }
        } catch(Exception e) {
            logList.add(new LogService().createErrorLog('ExportPartWrongQtyCommittedBatch', 'execute()', e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), partList.toString(), null, false));
        }
    }

    global void finish(Database.batchableContext bc) {
    	try {
            if(String.isNotBlank(fileData)) { ExportPartWrongQtyCommittedService.sendEmailWithAttachment(fileData); }
            DMLUtility.insertSobjectList('Log__c', logList);
    	} catch(Exception e) {
            new LogService().createErrorLog('ExportPartWrongQtyCommittedBatch', 'finish()', e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), null, null, true);
        }
    }
}
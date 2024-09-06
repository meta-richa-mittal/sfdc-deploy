/**
 * Author: Pooja Khandelwal
 * Since: Jan. 6, 2017
 * Name: AccSync_VendorInvoice_Batch
 * Description: Batch for AccSync Vendor Invoice (QB Integration)
**/
global without sharing class AccSync_VendorInvoice_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Vendor_Invoicing_Header__c> VIHeaderListToUpdate; 
    global List<Log__c> errorLogToInsert;
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null; 
    }

    global void execute(Database.batchableContext bc, List<Vendor_Invoicing_Header__c> listVIHeaders) {}  
 
    global void finish(Database.batchableContext bc){}
}
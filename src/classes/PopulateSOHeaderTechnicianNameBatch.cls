/**
 * Author: Manoj Sharma
 * Since: Aug 22, 2020 
 * Name: PopulateSOHeaderTechnicianNameBatch
 * Description: Used to populate technician name on Service order header
**/
global without sharing class PopulateSOHeaderTechnicianNameBatch implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id FROM Service_Order_Header__c WHERE Work_Status__c != \'Invoiced\' ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Service_Order_Header__c> soHeaderList) {
        Set<String> soHeaderIdSet = new Set<String>();
        for(Service_Order_Header__c soHeader : soHeaderList) {
            soHeaderIdSet.add(soHeader.Id);
        }
        TechnicianService.populateSOHeaderTechnicianName(soHeaderIdSet);
    }
    
    global void finish(Database.batchableContext bc) {
        
    }
}
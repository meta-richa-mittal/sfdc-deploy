/** 
* Author: Nidhi Sharma
* Since: June 28, 2023
* Name: ResetSalespersonNameOnCOBatch 
**/
global without sharing class ResetSalespersonNameOnCOBatch implements Database.Batchable<sobject> {
	    
    private Set<Id> technicianIds = new Set<Id>();

    global ResetSalespersonNameOnCOBatch(Set<Id> technicianIdSet) {
        if(technicianIdSet != null) {
            technicianIds = technicianIdSet; 
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'Select Deal__c, Service_Order_Header__c, CO_Header__c FROM CO_Salesperson__c WHERE Technician__c != null AND Technician__c IN: technicianIds';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<SObject> salespersonList) {
        COSalespersonTriggerHelper.setSalespersonNameOnCO((List<CO_Salesperson__c>) salespersonList);
    }
    
    global void finish(Database.batchableContext bc) {}
}
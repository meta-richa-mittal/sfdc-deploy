/**
 * Author: Richa Mittal
 * Since: Aug 06, 2021
 * Name: PartFieldsRecalculationBatch
 * Description: Batch for Populating correct qty committed on parts
**/
global without sharing class PartFieldsRecalculationBatch implements Database.Batchable<sobject> {
    public Boolean recalculateQtyCommitted = false;
    
    global PartFieldsRecalculationBatch() {}
    
    global PartFieldsRecalculationBatch(Boolean recalculateQtyCommitted) {
    	if(recalculateQtyCommitted != null) {
    		this.recalculateQtyCommitted = recalculateQtyCommitted;
    	}
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Part__c';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        List<Part__c> partListToUpdate = new List<Part__c>();
        if(recalculateQtyCommitted) {
            partListToUpdate = PartQtyCommittedRecalculationBatch.updatePartQtyCommitted(partList);
        }
        
        if(!partListToUpdate.isEmpty()) {
        	DMLUtility.updateSobjectList('Part__c', partListToUpdate); // do not stop trigger as change in qty available create/delete Required for stock VOLI
        }
    }
    
    global void finish(Database.batchableContext bc) {
        Database.executeBatch(new ExportPartWrongQtyCommittedBatch());
    }
}
/** 
* Author: Richa Mittal
* Since: Dec 12, 2019
* Name: UpdateSupersessionFieldsOnPartBatch 
* Description: Batch class to update Supersession Fields on Part record
**/
global without sharing class UpdateSupersessionFieldsOnPartBatch implements Database.Batchable<sobject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	BPScriptUtility.disbaleTrigger('PartTrigger');
        String strQuery = 'SELECT Alternate_Part_ID__c, Relation__c, Part_ID__c ' + 
        					'FROM Part_Alternates__c WHERE Relation__c = \'Replaced By\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Part_Alternates__c> partAlternatesList) {
        List<Part__c> partListToUpdate = new List<Part__c>();
        for(Part_Alternates__c partAlternateRec: partAlternatesList) {
        	partListToUpdate.add(new Part__c(Id = partAlternateRec.Part_ID__c, Is_Superseded__c = true, Superseded_To__c = partAlternateRec.Alternate_Part_ID__c));
        }
        if(partListToUpdate.size() > 0) {
    		update partListToUpdate;
    	}
    }
    
    global void finish(Database.batchableContext bc) {
    	BPScriptUtility.enableTrigger('PartTrigger');
    }
}
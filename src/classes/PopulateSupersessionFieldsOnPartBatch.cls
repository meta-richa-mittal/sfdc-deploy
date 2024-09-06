/** 
* Author: Richa Mittal
* Since: Jan 28, 2020
* Name: UpdateSupersessionFieldsOnPartBatch 
* Description: Batch class to update Supersession Fields on Part record
**/
global without sharing class PopulateSupersessionFieldsOnPartBatch implements Database.Batchable<sobject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	BPScriptUtility.disbaleTrigger('PartTrigger');
        String strQuery = 'SELECT Id FROM Part__c WHERE Id IN (select Part_ID__c FROM Part_Alternates__c WHERE Relation__c = \'Replaced By\')';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partsList) {
    	List<Part__c> partWithPartAlternatesList = [SELECT Id, (SELECT Alternate_Part_ID__c, Relation__c, Part_ID__c 
    													FROM Part_Alternates__r WHERE Relation__c = 'Replaced By' 
    													ORDER BY LastModifiedDate DESC LIMIT 1)
    													FROM Part__c WHERE Id IN :partsList];
        List<Part__c> partListToUpdate = new List<Part__c>();
        for(Part__c partRec: partWithPartAlternatesList) {
        	if(partRec.Part_Alternates__r.size() > 0) {
        		partListToUpdate.add(new Part__c(Id = partRec.Id, Is_Superseded__c = true, Superseded_To__c = partRec.Part_Alternates__r[0].Alternate_Part_ID__c));
        	}
        }
        if(partListToUpdate.size() > 0) {
    		update partListToUpdate;
    	}
    }
    
    global void finish(Database.batchableContext bc) {
    	BPScriptUtility.enableTrigger('PartTrigger');
    }
}
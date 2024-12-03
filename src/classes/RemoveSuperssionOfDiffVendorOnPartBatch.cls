/** 
* Author: Nidhi Sharma
* Since: April 06, 2021
* Name: RemoveSuperssionOfDiffVendorOnPartBatch 
**/
global without sharing class RemoveSuperssionOfDiffVendorOnPartBatch implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id FROM Part__c WHERE Superseded_To__c != null';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        partList = [SELECT Id, Vendor__c, Is_Superseded__c, Superseded_To__c, Superseded_To__r.Vendor__c, 
                    (SELECT Id, Alternate_Part_ID__c FROM Part_Alternates__r WHERE Relation__c = 'Replaced By'), 
                    (SELECT Id, Part_ID__c FROM Part_Alternates1__r WHERE Relation__c = 'Replaces') FROM Part__c
                    WHERE Superseded_To__c != null AND Id IN: partList];

    	List<Part__c> partUpdateList = new List<Part__c>();
        List<Part_Alternates__c> partAlternateDeleteList = new List<Part_Alternates__c>();
        
        for(Part__c partRec : partList) {
        	if(partRec.Vendor__c != partRec.Superseded_To__r.Vendor__c) {
	    		partRec.Is_Superseded__c = false;
	    		partRec.Superseded_To__c = null;
	    		partUpdateList.add(partRec);
	    		
	    		if(partRec.Part_Alternates__r.size() > 0) {
	    			partAlternateDeleteList.addAll(partRec.Part_Alternates__r);
	    			partAlternateDeleteList.addAll(partRec.Part_Alternates1__r);
	    		}
	    	}
        }
        if(partAlternateDeleteList.size() > 0) {
            DMLUtility.deleteSobjectList('Part_Alternates__c', partAlternateDeleteList);
        }
        if(partUpdateList.size() > 0) {
            PartTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Part__c', partUpdateList);
            PartTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    global void finish(Database.batchableContext bc) {}
    
}
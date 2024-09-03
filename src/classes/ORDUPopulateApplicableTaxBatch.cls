/** 
* Author: Nidhi Sharma
* Since: Sept 28, 2021
* Name: ORDUPopulateApplicableTaxBatch 
* Description: Batch Apex class which populated applicable purchase tax on ORDUs.
**/
global without sharing class ORDUPopulateApplicableTaxBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id, Vendor__r.Purchase_Tax__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c = \'ORDU\' AND Unit_Purchase_Tax__c = null AND Vendor__r.Purchase_Tax__c != null ORDER BY LastModifiedDate ASC';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> orduList) {
        for(Customer_Owned_Unit__c orduRec : orduList) {
        	orduRec.Unit_Purchase_Tax__c = orduRec.Vendor__r.Purchase_Tax__c;
        }

        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', orduList);
    }
    
    global void finish(Database.batchableContext bc) {}
}
/** 
* Author: Nidhi Sharma
* Since: Oct 21, 2021
* Name: OptonAndFeeStatusBatch 
* Description: Batch Apex class to update options and fee Status.
**/
global without sharing class OptonAndFeeStatusBatch implements Database.Batchable<sobject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'SELECT Id, CO_Line_Item__c, Service_Order_Line_Item__c, CO_Line_Item__r.Invoice_Number__c, Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c, Status__c, Fee__c, Part__c, Labour_Code__c, Product__c, ' +
        'Deal__r.Status__c, Product__r.Type__c, Deal_Kit_Header__c FROM Option_Fee__c Order by LastModifiedDate ASC';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Option_Fee__c> optionAddFeeList) {
    	updateStatus(optionAddFeeList);
    }
    
    public void updateStatus(List<Option_Fee__c> optionAddFeeList) {
        List<Option_Fee__c> optionAndFeeUpdateList = new List<Option_Fee__c>();
    	for(Option_Fee__c optionRec : optionAddFeeList) {
            String status = optionRec.Status__c;
            Boolean isOptionCommitable = DealService.isOptionCommitable(optionRec);
            
            if(!isOptionCommitable && optionRec.Deal__c != null && optionRec.Deal__r.Status__c == 'Invoiced') {
                status = Constants.FULFILLED;
            } else if(isOptionCommitable && (
                (optionRec.CO_Line_Item__c != null && optionRec.CO_Line_Item__r.Invoice_Number__c != null) || 
                (optionRec.Service_Order_Line_Item__c != null && optionRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null))) {
                status = Constants.FULFILLED;
            } else if(!isOptionCommitable || (optionRec.CO_Line_Item__c != null || optionRec.Service_Order_Line_Item__c != null)) {
                status = Constants.COMMITTED;
            } else {
                status = Constants.UNCOMIITTED;
            }
            if(optionRec.Status__c != status) {
                optionRec.Status__c = status;
                optionAndFeeUpdateList.add(optionRec);
            }
        }
        DMLUtility.updateSobjectList('Option_Fee__c', optionAndFeeUpdateList);
    }
    
    global void finish(Database.batchableContext bc) {}
}
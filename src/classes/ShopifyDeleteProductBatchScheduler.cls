/** 
* Author: Nidhi Sharma
* Since: July 2, 2021
* Name: ShopifyDeleteProductBatchScheduler 
* Description: Batch Apex class which delete products in shopify store.
**/
global without sharing class ShopifyDeleteProductBatchScheduler implements Database.Batchable<sobject>, Database.AllowsCallouts, Schedulable {
	
	public List<String> websiteProductIdDeleteList = new List<String>();
	
	global ShopifyDeleteProductBatchScheduler(){}
	global ShopifyDeleteProductBatchScheduler(List<String> productIdsToDeleteList) {
		websiteProductIdDeleteList = productIdsToDeleteList != null ? productIdsToDeleteList : new List<String>();
	}
	
	// Scheduler Execute method
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ShopifyDeleteProductBatchScheduler(websiteProductIdDeleteList), 1);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'SELECT Id, Retry_Attempt_Counter__c, Product_Id__c, Variant_Id__c FROM Website_Product__c WHERE ';
    	query += websiteProductIdDeleteList.size() > 0 ? ' Id IN: websiteProductIdDeleteList' : ' Delete_Pending__c = true AND ' +
    		'(Retry_Attempt_Counter__c = null OR Retry_Attempt_Counter__c <= '+ ShopifyUtil.MAX_RETRY + ')';	
    	query += ' ORDER BY Product_Id__c, Internal_Product_Id__c, CreatedDate ASC';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Website_Product__c> websiteProductRecList) {
    	List<Website_Product__c> webProductDeleteList = new List<Website_Product__c>();
    	List<Website_Product__c> webProductUpdateList = new List<Website_Product__c>();
    	
    	//Since delete is not a bulk API, batch size should not be more than 20 (as there are additional retry attempts for each entry), so only processing 20 recs
    	for(Website_Product__c websiteProductDeleteRec : websiteProductRecList) {
    		try {
	    		ShopifyService.deleteWebsiteProductFromShopify(websiteProductDeleteRec);
	    		if(websiteProductDeleteRec.Delete_Pending__c != null && !websiteProductDeleteRec.Delete_Pending__c) {
	    			webProductDeleteList.add(websiteProductDeleteRec);
	    		} else {
    				webProductUpdateList.add(websiteProductDeleteRec);
	    		}
    		} catch(Exception e) {
    			system.debug('ShopifyDeleteProductBatchScheduler - Exception while deleting products::' + e.getMessage());
    			break;
    		}
    	}
    	DMLUtility.deleteSobjectList('Website_Product__c', webProductDeleteList, false);
    	DMLUtility.updateSobjectList('Website_Product__c', webProductUpdateList, false); 
    }
    
    global void finish(Database.batchableContext bc) {}
}
/** 
* Author: Nidhi Sharma
* Since: Dec 17, 2020
* Name: SyncPartsWithShopifyBatch 
* Description: Batch Apex class which sync parts to shopify store.
**/
global without sharing class SyncPartsWithShopifyBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Schedulable {
	
	private Boolean isFirstTimeSync;
	Set<Id> partIdSet;
	global SyncPartsWithShopifyBatch(Boolean isFirstTimeSync) {
		this.isFirstTimeSync = isFirstTimeSync;
		this.partIdSet = new Set<Id>();
	}

	global SyncPartsWithShopifyBatch(Set<Id> partIdSet) {
		this.isFirstTimeSync = false;
		this.partIdSet = partIdSet;
	}
	
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT ' + String.join(ShopifyProductWrapper.getFieldsToQuery(), ',') + ' FROM Part__c ';
        if(isFirstTimeSync) {
        	strQuery += ' WHERE Publish_In_Feeds__c = true AND Shopify_Id__c = null ';
        } else {
        	strQuery += ' WHERE Id IN: partIdSet';
        }
        strQuery += ' ORDER BY Name ASC';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
    	/*if(ShopifyUtil.isIntegrationActive) {
			ShopifyService.errorLogs = new List<Log__c>();
	    	List<ShopifyProductWrapper> shopifyProductObjList = new List<ShopifyProductWrapper>();
	    	Map<String, Part__c> productUIDtoPartRecMap = new Map<String, Part__c>();
	    	
	    	for(Part__c partRec : partList) {
	    		ShopifyProductWrapper product = new ShopifyProductWrapper(partRec);
	    		shopifyProductObjList.add(product);
	    		productUIDtoPartRecMap.put(product.productNumber + ShopifyUtil.productAndVendorCodeConnectorKey + product.vendorCode, partRec);
	    	}
	    	Boolean isSuccess = ShopifyService.saveProduct(system.JSON.serialize(shopifyProductObjList), productUIDtoPartRecMap);
	    	if(isSuccess) {
	    		PartTriggerHelper.isForceStopTrigger = true;
	    		update productUIDtoPartRecMap.values();
	    		PartTriggerHelper.isForceStopTrigger = false;
	    	}
    	} else {
    		ShopifyService.errorLogs.add(new LogService().createErrorLog('SyncPartsWithShopifyBatch', 'execute()', 'Integration is inactive', LogService.NOT_APPLICABLE, null, 
                                              '', LogService.SHOPIFY, false, 'Error'));
    	}
    	ShopifyService.updateValues();*/
    }
    
    global void finish(Database.batchableContext bc) {}
    
    global void execute(SchedulableContext sc) {
		if(isFirstTimeSync){
		Database.executeBatch(new SyncPartsWithShopifyBatch(isFirstTimeSync), 50);
		} else {
			Database.executeBatch(new SyncPartsWithShopifyBatch(partIdSet), 50);
		}
    }
}
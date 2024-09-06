/** 
* Author: Nidhi Sharma
* Since: June 21, 2021
* Name: ShopifyCreateProductsBatch 
* Description: Batch Apex class which create website products to shopify store.
* THIS BATCH IS NOT IN USE, NOW USE ShopifySyncWebsiteProductBatch
**/
global without sharing class ShopifyCreateProductsBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful, Schedulable {
	
	public Set<String> processedProductIdSet = new Set<String>();
	public List<Website_Product__c> productList = new List<Website_Product__c>();
	
	global ShopifyCreateProductsBatch(){}
	global ShopifyCreateProductsBatch(List<Website_Product__c> productListToSync) {
		productList = productListToSync;
	}
	
	// Scheduler Execute method
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ShopifyCreateProductsBatch(productList), 50);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'SELECT ' + String.join(ShopifyProductWrapper.getWebsiteProductFieldList(), ',') + ' FROM Website_Product__c WHERE Part__c != null AND ' + 
    			'Delete_Pending__c = false AND ';
    	query += productList.size() > 0 ? ' Id IN: productList' : ' Status__c = \'' + WebsiteProductManagementUtil.STATUS_ERROR + '\' AND ' + 
    		'(Retry_Attempt_Counter__c = null OR Retry_Attempt_Counter__c <= ' + ShopifyUtil.MAX_RETRY + ')';
    	query += ' ORDER BY Product_Id__c, Internal_Product_Id__c, CreatedDate ASC';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Website_Product__c> websiteProductRecList) {
    	postProductToShopify(websiteProductRecList);
    }
    
    public void postProductToShopify(List<Website_Product__c> websiteProductRecList) {
    	if(ShopifyUtil.isIntegrationActive) {
			ShopifyService.errorLogs = new List<Log__c>();
	    	
	    	Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap = new Map<String, Website_Product__c>();
	    	Map<String, List<Website_Product__c>> productGroupIdToWebsiteProductListMap = new Map<String, List<Website_Product__c>>();
	    	
	    	for(Website_Product__c websiteProductRec : websiteProductRecList) {
	    		String groupId = String.isNotBlank(websiteProductRec.Internal_Product_Id__c) ? websiteProductRec.Internal_Product_Id__c : websiteProductRec.Product_Id__c;
		    	if(String.isNotBlank(groupId) && !processedProductIdSet.contains(groupId)) {
		    		processedProductIdSet.add(groupId);
	    			productGroupIdToWebsiteProductListMap.put(groupId, new List<Website_Product__c>());
		    	}
	    	}
	    	Set<String> groupIdSet = productGroupIdToWebsiteProductListMap.keySet();
	    	String query = 'SELECT ' + String.join(ShopifyProductWrapper.getWebsiteProductFieldList(), ',') + ' FROM Website_Product__c' + 
    			' WHERE (Product_Id__c IN: groupIdSet OR Internal_Product_Id__c IN: groupIdSet) ' +
    			' ORDER BY Product_Id__c, Variant_Position__c, CreatedDate ASC';
	    	for(Website_Product__c websiteProductRec : Database.query(query)) {
	    		String groupId = String.isNotBlank(websiteProductRec.Internal_Product_Id__c) ? websiteProductRec.Internal_Product_Id__c : websiteProductRec.Product_Id__c;
		    	productGroupIdToWebsiteProductListMap.get(groupId).add(websiteProductRec);
	    		productUIDtoWebsiteProductRecMap.put(websiteProductRec.Part__r.Part_Number__c + 
	    				ShopifyUtil.productAndVendorCodeConnectorKey + websiteProductRec.Part__r.Vendor_Code__c, websiteProductRec);
	    	}
	    	
	    	List<ShopifyProductWrapper> shopifyProductObjList = new List<ShopifyProductWrapper>();
	    	for(String groupId : productGroupIdToWebsiteProductListMap.keySet()) {
	    		shopifyProductObjList.add(new ShopifyProductWrapper(productGroupIdToWebsiteProductListMap.get(groupId)));
	    	}
	    	ShopifyService.createProducts(system.JSON.serialize(shopifyProductObjList), productUIDtoWebsiteProductRecMap);
    		DMLUtility.updateSobjectList('Website_Product__c', productUIDtoWebsiteProductRecMap.values());
    		clearPartSparseUpdateFields(productUIDtoWebsiteProductRecMap.values());
    	} else {
    		ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifyCreateProductsBatch', 'execute()', 'Integration is inactive', LogService.NOT_APPLICABLE, null, 
                                              '', LogService.SHOPIFY, false, 'Error'));
    	}
    	ShopifyService.updateValues();
    }
    
    private void clearPartSparseUpdateFields(List<Website_Product__c> productList) {
        List<Part__c> partList = new List<Part__c>();
        for(Website_Product__c product : productList) {
            if(String.isNotBlank(product.Part__r.Shopify_Sparse_Update_Fields__c)) {
                product.Part__r.Shopify_Sparse_Update_Fields__c = null;
                partList.add(product.Part__r);
            }
        }
        if(partList.size() > 0) {
            PartTriggerHelper.isForceStopTrigger = true;
            try {
				update partList;
			} catch(Exception e) {
				if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
					try {
						BPUtility.setTimeout(2);
						update partList;
					} catch(Exception exe) {
						ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifyCreateProductsBatch', 'clearPartSparseUpdateFields()', exe.getMessage(), LogService.NOT_APPLICABLE, null, 
						String.valueOf(partList), LogService.SHOPIFY, false, 'Error'));
					}
				} else {
					ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifyCreateProductsBatch', 'clearPartSparseUpdateFields()', e.getMessage(), LogService.NOT_APPLICABLE, null, 
					String.valueOf(partList), LogService.SHOPIFY, false, 'Error'));
				}
			}
            PartTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    global void finish(Database.batchableContext bc) {}
}
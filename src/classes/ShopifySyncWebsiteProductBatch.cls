/** 
* Author: Richa Mittal
* Since: Nov 22, 2021
* Name: ShopifySyncWebsiteProductBatch 
* Description: Batch Apex class with GET and POST to/from shopify.
**/
global without sharing class ShopifySyncWebsiteProductBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful, Schedulable {
    
    public List<Website_Product__c> productList = new List<Website_Product__c>();
    private Map<Integer, Set<String>> retryIntervalToProductIdSetMap = new Map<Integer, Set<String>>();
    private Integer retryAttemptNumber;
    
    global ShopifySyncWebsiteProductBatch(List<Website_Product__c> productListToSync) {
		this.productList = productListToSync;
        this.retryAttemptNumber = 1;
	}
    global ShopifySyncWebsiteProductBatch(List<Website_Product__c> productListToSync, Integer retryAttemptNumber) {
		this.productList = productListToSync;
        this.retryAttemptNumber = retryAttemptNumber != null ? retryAttemptNumber : 1;
	}

    global Iterable<String> start(Database.BatchableContext bc) {
        if(this.productList.size() > 0) {
            String query = 'SELECT Group_Id__c FROM Website_Product__c WHERE Part__c != null AND Delete_Pending__c = false AND Id IN: productList';
            query += ' ORDER BY Product_Id__c, Internal_Product_Id__c, CreatedDate ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
            Set<String> groupIdSet = new Set<String>();
            for(Website_Product__c productRec: Database.query(query)) {
                groupIdSet.add(productRec.Group_Id__c);
            }
            return new List<String>(groupIdSet);
        }
        return new List<String>();
    }

    global void execute(SchedulableContext sc) {
		Database.executeBatch(new ShopifySyncWebsiteProductBatch(this.productList, this.retryAttemptNumber), 1);
	}

    global void execute(Database.batchableContext bc, List<String> iterableList) {
        Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap = new Map<String, Website_Product__c>();
        try {
            if(ShopifyUtil.isIntegrationActive) {
                ShopifyService.errorLogs = new List<Log__c>();
                ShopifyService.processingProductSFIdList = new List<String>();
                
                Map<String, List<Website_Product__c>> productGroupIdToWebsiteProductListMap = new Map<String, List<Website_Product__c>>();

                String query = 'SELECT ' + String.join(ShopifyProductWrapper.getWebsiteProductFieldList(), ',') + ' FROM Website_Product__c' + 
                    ' WHERE Group_Id__c IN: iterableList ORDER BY Product_Id__c, Variant_Position__c, CreatedDate ASC';
                List<Website_Product__c> wpList = Database.query(query);
                for(Website_Product__c websiteProductRec : wpList) {
                    ShopifyService.processingProductSFIdList.add(websiteProductRec.Id);
                }
                
                for(Website_Product__c websiteProductRec : wpList) {
                    String groupId = websiteProductRec.Group_Id__c;
                    if(String.isNotBlank(groupId)) {
                        if(!productGroupIdToWebsiteProductListMap.containsKey(groupId)) {
                            productGroupIdToWebsiteProductListMap.put(groupId, new List<Website_Product__c>());
                        }

                        productGroupIdToWebsiteProductListMap.get(groupId).add(websiteProductRec);
                        productUIDtoWebsiteProductRecMap.put(websiteProductRec.Part__r.Part_Number__c + 
                                ShopifyUtil.productAndVendorCodeConnectorKey + websiteProductRec.Part__r.Vendor_Code__c, websiteProductRec);

                        if(websiteProductRec.Product_Id__c == null && websiteProductRec.Website_API_Response__c != null) {
                            ShopifyProductService.getProductByProductNumAndVendorCode(websiteProductRec, retryIntervalToProductIdSetMap, this.retryAttemptNumber);
                        }
                    }
                }
                system.debug('&&&& productUIDtoWebsiteProductRecMap' + productUIDtoWebsiteProductRecMap);
                List<ShopifyProductWrapper> shopifyProductObjList = new List<ShopifyProductWrapper>();
                for(String groupId : productGroupIdToWebsiteProductListMap.keySet()) {
                    shopifyProductObjList.add(new ShopifyProductWrapper(productGroupIdToWebsiteProductListMap.get(groupId)));
                }
                ShopifyService.createProducts(system.JSON.serialize(shopifyProductObjList), productUIDtoWebsiteProductRecMap, retryIntervalToProductIdSetMap, retryAttemptNumber);
                clearPartSparseUpdateFields(productUIDtoWebsiteProductRecMap.values());
            } else {
                ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifySyncWebsiteProductBatch', 'execute()', 'Integration is inactive', LogService.NOT_APPLICABLE, null, 
                                                '', LogService.SHOPIFY, false, 'Error'));
            }
        } catch(Exception e) {
            if(e.getMessage() == ('retry ' + ShopifyUtil.SHOPIFY_PRODUCT_BY_DETAILS)) {
                ShopifyService.saveErrorResponse(this.retryAttemptNumber, productUIDtoWebsiteProductRecMap.values());
            } else if(e.getMessage().startsWith('retry') || this.retryAttemptNumber == ShopifyUtil.MAX_RETRY) {
                ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifySyncWebsiteProductBatch', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
			        String.valueOf(productUIDtoWebsiteProductRecMap), LogService.SHOPIFY, false, 'Error'));
            }
        }
        DMLUtility.updateSobjectList('Website_Product__c', productUIDtoWebsiteProductRecMap.values());
    	ShopifyService.updateValues();
    }

    global void finish(Database.batchableContext bc) {
        if(retryIntervalToProductIdSetMap.size() > 0 && ++this.retryAttemptNumber <= ShopifyUtil.MAX_RETRY) {
			ShopifyService.retrySyncProducts(retryIntervalToProductIdSetMap, 'POST', this.retryAttemptNumber);
		}
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
						ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifySyncWebsiteProductBatch', 'clearPartSparseUpdateFields()', exe.getMessage(), LogService.NOT_APPLICABLE, null, 
						String.valueOf(partList), LogService.SHOPIFY, false, 'Error'));
					}
				} else {
					ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifySyncWebsiteProductBatch', 'clearPartSparseUpdateFields()', e.getMessage(), LogService.NOT_APPLICABLE, null, 
					String.valueOf(partList), LogService.SHOPIFY, false, 'Error'));
				}
			}
            PartTriggerHelper.isForceStopTrigger = false;
        }
    }
}
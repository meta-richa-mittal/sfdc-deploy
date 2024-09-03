/** 
* Author: Nidhi Sharma
* Since: June 02, 2021
* Name: ShopifyFetchProductsBatchScheduler 
* Description: Batch Apex class which sync products from shopify store to BP.
**/
global without sharing class ShopifyFetchProductsBatchScheduler implements Database.Batchable<Object>, Database.AllowsCallouts, Schedulable, Database.Stateful {
    
    private static final String JOB_NAME = 'Shopify fetch products';
    private static Integer rescheduleIntervalInSeconds = GeneralConfiguration.getShopifyProductRescheduleInternalInMins() * 60;
    public String previousCursor;
    public String cursor;
    public static Integer batchSize = 100;
    
    global ShopifyFetchProductsBatchScheduler(String cursorVal) {
    	this.previousCursor = this.cursor = cursorVal;
    }
		
    global Iterable<Object> start(Database.BatchableContext bc) {
    	return new List<Object>{'1'};
    }
    
    global void execute(Database.batchableContext bc, List<Object> iterableList) {
		ShopifyService.ShopifyResponseWrapper shopifyResponseObj = ShopifyService.getPaginatedProductsJsonByCursor(this.cursor);
    	if(shopifyResponseObj != null) {
            if(shopifyResponseObj != null && shopifyResponseObj.hasNextPage && String.isNotBlank(shopifyResponseObj.cursor)) {
            	this.cursor = shopifyResponseObj.cursor != this.previousCursor ? shopifyResponseObj.cursor : null;
            }
        	createShopifyProductsInBP(shopifyResponseObj.products);
    	} else if(String.isBlank(this.cursor)) {
			this.cursor = this.previousCursor = 'Error';
    	}
    	if(!Test.isRunningTest()) {
    		ShopifyService.updateValues();
    	}
    }

    global void finish(Database.batchableContext bc) {
    	if(String.isNotBlank(this.cursor)) {
	    	if(this.cursor != this.previousCursor) {
	    	    BPUtility.setTimeoutInMiliSecond(200);
	    		Database.executeBatch(new ShopifyFetchProductsBatchScheduler(this.cursor), batchSize);
	    	} else {
	    		updatePollingIndicator(false);
	    	}
    	} else {
    		updatePollingIndicator(false);
			rescheduleAfterSpecifiedSeconds(rescheduleIntervalInSeconds);
    	}
    }
    
    private static void createShopifyProductsInBP(List<ShopifyFetchProductWrapper> shopifyProductList) {
    	try {
	    	if(shopifyProductList != null && shopifyProductList.size() > 0) {
		        List<Website_Product__c> websiteProductInsertList = new List<Website_Product__c>();
		        Set<String> shopifyIdSet = ShopifyProductService.getShopifyIds(shopifyProductList);
		        Set<String> existingProductWithShopifyIds = getExistingProductWithShopifyIds(shopifyIdSet);
		        for(ShopifyFetchProductWrapper shopifyProduct : shopifyProductList) {
		        	try {
		                if(!existingProductWithShopifyIds.contains(shopifyProduct.shopifyId)) {
		                    websiteProductInsertList.add(ShopifyProductService.createWebsiteProduct(shopifyProduct, shopifyProduct.shopifyId.substringBefore('.'), shopifyProduct.shopifyId.substringAfter('.')));
                            existingProductWithShopifyIds.add(shopifyProduct.shopifyId);
		                }
		        	} catch(Exception e) {
		        		createErrorLog(e, String.valueOf(shopifyProduct));
		        	}
		        }
		    	DMLUtility.insertSobjectList('Website_Product__c', websiteProductInsertList, false);
	    	}
    	} catch(Exception e) {
    		createErrorLog(e, null);
		}
    }
    
    private static Log__c createErrorLog(Exception e, String reqBody) {
    	return new LogService().createErrorLog('ShopifyFetchProductsBatchScheduler', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                    reqBody, LogService.SHOPIFY, true, 'Error');
    }

    private static Set<String> getExistingProductWithShopifyIds(Set<String> productIdSet) {
        Set<String> existingProductWithShopifyIds = new Set<String>();
        if(productIdSet.size() > 0) {
	        for(Website_Product__c productRec : [SELECT Unique_Id__c FROM Website_Product__c WHERE Unique_Id__c IN :productIdSet]) {
	            existingProductWithShopifyIds.add(productRec.Unique_Id__c);
	        }
        }
        return existingProductWithShopifyIds;
    }
        
    // Scheduler Execute method
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ShopifyFetchProductsBatchScheduler(this.cursor), batchSize);
    }
    
    //To turn off manual polling action
    public static void updatePollingIndicator(Boolean isManualPolling) {
    	isManualPolling = isManualPolling != null ? isManualPolling : false;
    	
    	Shopify_Configuration__c shopifyConfig = Shopify_Configuration__c.getOrgDefaults();
    	shopifyConfig.Polling_In_Progress__c = shopifyConfig.Polling_In_Progress__c != null ? shopifyConfig.Polling_In_Progress__c : false;
    	
    	if(isManualPolling != shopifyConfig.Polling_In_Progress__c) {
    		shopifyConfig.Polling_In_Progress__c = isManualPolling;
			DMLUtility.upsertSobjectList('Shopify_Configuration__c', shopifyConfig);
    	}
    }
    
    public static void rescheduleAfterSpecifiedSeconds(Integer rescheduleInSecs) {
    	rescheduleAfterSpecifiedSeconds(rescheduleInSecs, null);
    }
    
    public static void rescheduleAfterSpecifiedSeconds(Integer rescheduleInSecs, String cursor) {
    	abortExisting();
    	if(rescheduleInSecs == null || rescheduleInSecs == 0) {
	    	Database.executeBatch(new ShopifyFetchProductsBatchScheduler(cursor), batchSize);
    	} else {
    		String CRON_EXP = BPUtility.getCronExpForGivenTime(rescheduleInSecs);
	    	system.schedule(JOB_NAME, CRON_EXP, new ShopifyFetchProductsBatchScheduler(cursor));
    	}
    }
    
    public static void abortExisting() {
    	BPUtility.abortScheduledJobByJobName(JOB_NAME);
    	BPUtility.abortApexBatchJobByName('ShopifyFetchProductsBatchScheduler');
    }
}
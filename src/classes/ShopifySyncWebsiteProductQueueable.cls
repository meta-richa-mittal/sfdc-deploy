/** 
* Author: Balveer Choudhary
* Since: Aug 03, 2022
* Name: ShopifySyncWebsiteProductQueueable 
* Description: Queueable Apex class with GET and POST to/from shopify.
**/
global without sharing class ShopifySyncWebsiteProductQueueable implements Queueable, Database.AllowsCallouts {
    
    public List<Website_Product__c> productList = new List<Website_Product__c>();
    private Map<Integer, Set<String>> retryIntervalToProductIdSetMap = new Map<Integer, Set<String>>();
    private Integer retryAttemptNumber;
    
    global ShopifySyncWebsiteProductQueueable(List<Website_Product__c> productListToSync) {
		this.productList = productListToSync;
        this.retryAttemptNumber = 1;
	}
    global ShopifySyncWebsiteProductQueueable(List<Website_Product__c> productListToSync, Integer retryAttemptNumber) {
		this.productList = productListToSync;
        this.retryAttemptNumber = retryAttemptNumber != null ? retryAttemptNumber : 1;
	}

    private String getQueryString() {
        String query = 'SELECT Group_Id__c FROM Website_Product__c' 
                        +' WHERE Part__c != null AND Delete_Pending__c = false AND Id IN: productList'
                        +' ORDER BY Product_Id__c, Internal_Product_Id__c, CreatedDate ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return query;
    }

    global void execute(QueueableContext context) {
        Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap = new Map<String, Website_Product__c>();
                Set<String> groupIdSet = new Set<String>();
                for(Website_Product__c productRec: Database.query(getQueryString())) {
                    groupIdSet.add(productRec.Group_Id__c);
                }
        try {
            ShopifyService.shopifySyncWebsiteProductExecute(new List<String> (groupIdSet), productUIDtoWebsiteProductRecMap, retryIntervalToProductIdSetMap, retryAttemptNumber);            
        } catch(Exception e) {
            if(e.getMessage() == ('retry ' + ShopifyUtil.SHOPIFY_PRODUCT_BY_DETAILS)) {
                ShopifyService.saveErrorResponse(this.retryAttemptNumber, productUIDtoWebsiteProductRecMap.values());
            } else if(e.getMessage().startsWith('retry') || this.retryAttemptNumber == ShopifyUtil.MAX_RETRY) {
                ShopifyService.errorLogs.add(new LogService().createErrorLog('ShopifySyncWebsiteProductQueueable', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
			        String.valueOf(productUIDtoWebsiteProductRecMap), LogService.SHOPIFY, false, 'Error'));
            }
        }
        DMLUtility.updateSobjectList('Website_Product__c', productUIDtoWebsiteProductRecMap.values());
    	ShopifyService.updateValues();

        finishAction();
    }
    
    private void finishAction() {
        if(retryIntervalToProductIdSetMap.size() > 0 && ++this.retryAttemptNumber <= ShopifyUtil.MAX_RETRY) {
            ShopifyService.retrySyncProducts(retryIntervalToProductIdSetMap, 'POST', this.retryAttemptNumber, false);
        }
    }
}
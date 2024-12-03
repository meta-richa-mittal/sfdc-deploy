/** 
* Author: Richa Mittal
* Since: Nov 22, 2021
* Name: ShopifySyncWebsiteProductBatch 
* Description: Batch Apex class with GET and POST to/from shopify.
* This batch is only used for bulk Part processing using APF, PF, BRP Get Part Master and count session, USE ShopifySyncWebsiteProductQueueable for single record update
**/
global without sharing class ShopifySyncWebsiteProductBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful, Schedulable {
    
    public List<Website_Product__c> productList = new List<Website_Product__c>();
    private Map<Integer, Set<String>> retryIntervalToProductIdSetMap = new Map<Integer, Set<String>>();
    private Integer retryAttemptNumber;
    private Boolean isBulkProcess;
    
    global ShopifySyncWebsiteProductBatch(Boolean isBulkProcess) {
        this.retryAttemptNumber = 1;
        this.isBulkProcess = isBulkProcess;
    }
    global ShopifySyncWebsiteProductBatch(List<Website_Product__c> productListToSync) {
		this.productList = productListToSync;
        this.retryAttemptNumber = 1;
	}
    global ShopifySyncWebsiteProductBatch(List<Website_Product__c> productListToSync, Integer retryAttemptNumber) {
		this.productList = productListToSync;
        this.retryAttemptNumber = retryAttemptNumber != null ? retryAttemptNumber : 1;
	}

    global Iterable<String> start(Database.BatchableContext bc) {
        String query = 'SELECT Group_Id__c FROM Website_Product__c WHERE Part__c != null AND Delete_Pending__c = false';
        if(this.productList.size() > 0) {
            query += ' AND Id IN: productList';
        } else if(this.isBulkProcess) {
            query += ' AND Part__r.Available_For_Shopify_Sync__c = true';
        }
        query += ' ORDER BY Product_Id__c, Internal_Product_Id__c, CreatedDate ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        Set<String> groupIdSet = new Set<String>();
        for(Website_Product__c productRec: Database.query(query)) {
            groupIdSet.add(productRec.Group_Id__c);
        }
        return new List<String>(groupIdSet);
    }

    global void execute(SchedulableContext sc) {
		Database.executeBatch(new ShopifySyncWebsiteProductBatch(true), ShopifyUtil.BulkProcessBatchSize);
	}

    global void execute(Database.batchableContext bc, List<String> iterableList) {
        Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap = new Map<String, Website_Product__c>();
        try {
            ShopifyService.shopifySyncWebsiteProductExecute(iterableList, productUIDtoWebsiteProductRecMap, retryIntervalToProductIdSetMap, retryAttemptNumber);            
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
        updatePartShopifySyncFlag(productUIDtoWebsiteProductRecMap.values());
    }

    global void finish(Database.batchableContext bc) {
        if(retryIntervalToProductIdSetMap.size() > 0 && ++this.retryAttemptNumber <= ShopifyUtil.MAX_RETRY) {
            ShopifyService.retrySyncProducts(retryIntervalToProductIdSetMap, 'POST', this.retryAttemptNumber, true);
		}
    }

    private void updatePartShopifySyncFlag(List<Website_Product__c> wpList) {
        Set<Id> partIdSet = new Set<Id>();
        for(Website_Product__c wpRec: wpList) {
            if(wpRec.Status__c == WebsiteProductManagementUtil.STATUS_LINKED) {
                partIdSet.add(wpRec.Part__c);
            }
        }
        List<Part__c> partListToUpdate = [SELECT Id FROM Part__c WHERE id IN :partIdSet];
        for(Part__c partRec : partListToUpdate) {
            partRec.Available_For_Shopify_Sync__c = false;
					}
        DMLUtility.updateSobjectList('Website_Product__c', partListToUpdate);
    }
}
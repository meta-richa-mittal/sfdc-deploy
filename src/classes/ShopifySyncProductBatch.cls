/** 
* Author: Nidhi Sharma
* Since: Oct 30, 2021
* Name: ShopifySyncProductBatch 
* Description: Batch Apex class which sync website products to/from shopify store.
* THIS BATCH IS NOT IN USE, NOW USE ShopifySyncWebsiteProductBatch
**/
global without sharing class ShopifySyncProductBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
	
	public List<Website_Product__c> productList = new List<Website_Product__c>();
	public List<Website_Product__c> productToSyncList = new List<Website_Product__c>();
	
	global ShopifySyncProductBatch(List<Website_Product__c> productListToSync) {
		productList = productListToSync;
	}
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'Select Id, Title__c, Part__r.Part_Number__c, Product_Id__c, ' +
            'Part__r.Vendor_Code__c from Website_Product__c WHERE Part__c != null AND ' +
            'Delete_Pending__c = false';
        if(productList != null && productList.size() > 0) {
            query += ' AND Id IN: productList';
        } else {
            Set<String> statusToSyncSet = new Set<String>{WebsiteProductManagementUtil.STATUS_ERROR};
            query += ' AND Status__c IN: Status__c IN :WebsiteProductManagementUtil.statusToSyncSet';
        }
        query += ' Order By Internal_Product_Id__c, Variant_Position__c, CreatedDate ASC';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Website_Product__c> websiteProductRecList) {
    	syncWithShopify(websiteProductRecList);
    }
    
    public void syncWithShopify(List<Website_Product__c> websiteProductRecList) {
        List<Website_Product__c> productFoundUpdateList = new List<Website_Product__c>();
        for(Website_Product__c productRec : websiteProductRecList) {
            if(productRec.Product_Id__c == null) {
                ShopifyProductService.getProductByProductNumAndVendorCode(productRec);
                if(productRec.Product_Id__c != null) {
                    productFoundUpdateList.add(productRec);
                } else {
                    productToSyncList.add(productRec);
                }
            } else {
                productToSyncList.add(productRec);
            }
        }
        if(productFoundUpdateList.size() > 0) {
            update productFoundUpdateList;
        }
        try {
            ShopifyService.updateValues();
        } catch(Exception e) {
            system.debug('Exception while inserting logs ' + e.getMessage());
        }
    }

    global void finish(Database.batchableContext bc) {
        if(productToSyncList.size() > 0) {
            Database.executeBatch(new ShopifyCreateProductsBatch(productToSyncList));
        }
    }
}
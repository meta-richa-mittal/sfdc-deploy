/**
 * Author: Nidhi Sharma
 * Since: June 18, 2021
 * Name: WebsiteProductTrigger
 * Description: Trigger helper class
**/
public without sharing class WebsiteProductTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    
    public static void afterInsert(List<Website_Product__c> newList) {
    	validateProducts(newList, null);
    	populatePartFields(newList, null);
		validatePartDuplicacy(newList);	
    }
    
    public static void beforeUpdate(List<Website_Product__c> newList, Map<Id, Website_Product__c> oldMap) {
        populateSparseUpdateFields(newList, oldMap);
    }
    
    public static void afterUpdate(List<Website_Product__c> newList, Map<Id, Website_Product__c> oldMap) {
    	validateProducts(newList, oldMap);
    	populatePartFields(newList, oldMap);
		validatePartDuplicacy(newList);	
    }
    
    private static void validateProducts(List<Website_Product__c> productList, Map<Id, Website_Product__c> oldMap) {
		Set<String> productGroupIdSet = new Set<String>();
		for(Website_Product__c webProduct : productList) {
			if(webProduct.Part__c != null && (oldMap == null || webProduct.Part__c != oldMap.get(webProduct.Id).Part__c)) {
				String groupId = String.isNotBlank(webProduct.Internal_Product_Id__c) ? webProduct.Internal_Product_Id__c : webProduct.Product_Id__c;
				productGroupIdSet.add(groupId);
			}
		}
		if(!productGroupIdSet.isEmpty()) {
			Map<String, String> productGroupIdToVendorIdMap = new Map<String, String>();
			for(Website_Product__c webProduct : [Select Internal_Product_Id__c, Product_Id__c, Part__r.Vendor__c from Website_Product__c where Group_Id__c IN: productGroupIdSet AND Part__c != null]) {
				String groupId = String.isNotBlank(webProduct.Internal_Product_Id__c) ? webProduct.Internal_Product_Id__c : webProduct.Product_Id__c;
				if(!productGroupIdToVendorIdMap.containsKey(groupId)) {
					productGroupIdToVendorIdMap.put(groupId, webProduct.Part__r.Vendor__c);
				} else if(productGroupIdToVendorIdMap.get(groupId) != webProduct.Part__r.Vendor__c) {
					throw new BlackPurlException('Incorrect part mappings. All variants of a product must be mapped to the parts from same vendor. Please review all the variants mapped for these products.');
				}
			}
		}
	}
    
    private static void populatePartFields(List<Website_Product__c> productList, Map<Id, Website_Product__c> oldMap) {
    	Map<Id, Part__c> partIdToRecUpdateMap = new Map<Id, Part__c>();
    	Set<Id> oldPartIdSet = new Set<Id>();
    	for(Website_Product__c webProduct : productList) {
    		if(trigger.isInsert && webProduct.Part__c != null) {
    			partIdToRecUpdateMap.put(webProduct.Part__c, new Part__c(Id = webProduct.Part__c, Shopify_Product__c = webProduct.Id));
    		} else if(trigger.isUpdate && webProduct.Part__c != oldMap.get(webProduct.Id).Part__c) {
    			if(webProduct.Part__c != null) {
					partIdToRecUpdateMap.put(webProduct.Part__c, new Part__c(Id = webProduct.Part__c, Shopify_Product__c = webProduct.Id));
    			}
				if(oldMap.get(webProduct.Id).Part__c != null && !partIdToRecUpdateMap.containsKey(oldMap.get(webProduct.Id).Part__c)) {
					oldPartIdSet.add(oldMap.get(webProduct.Id).Part__c);
				}
    		}
		}
		if(oldPartIdSet.size() > 0) {
			List<Website_Product__c> webProductList = [Select Id, Part__c from Website_Product__c where Part__c IN: oldPartIdSet];
			for(Website_Product__c productRec : webProductList) {
				partIdToRecUpdateMap.put(productRec.Part__c, new Part__c(Id = productRec.Part__c, Shopify_Product__c = productRec.Id));
				oldPartIdSet.remove(productRec.Part__c);
			}
			for(String partId : oldPartIdSet) {
				partIdToRecUpdateMap.put(partId, new Part__c(Id = partId, Shopify_Product__c = null));
			}
		}
		DMLUtility.updateSobjectList('Part__c', partIdToRecUpdateMap.values());
    }
    
    public static void populateSparseUpdateFields(List<Website_Product__c> newList, Map<Id, Website_Product__c> oldMap) {
        List<String> fieldAPINameList = new List<String>{'Title__c'};
        for(Website_Product__c product : newList) {
            if(product.Product_Id__c != null) {
                BPUtility.updateSparseFieldForRecord(product, oldMap.get(product.Id), 'Shopify_Sparse_Update_Fields__c', fieldAPINameList);
				if(!product.Shopify_Sparse_Update_Fields__c.containsIgnoreCase('Title__c') && product.Part__c != null && product.Part__c != oldMap.get(product.Id).Part__c && String.isBlank(product.Option_Value_1__c) && String.isBlank(product.Option_Value_2__c) && String.isBlank(product.Option_Value_3__c) && GeneralConfiguration.getConfigurationByName(GeneralConfiguration.INCLUDE_PARTNUM_IN_WEBSITE_PRODUCT_NAME) == 'true') {
					product.Shopify_Sparse_Update_Fields__c = String.isBlank(product.Shopify_Sparse_Update_Fields__c) ? 'Title__c' : (product.Shopify_Sparse_Update_Fields__c + ',Title__c');
				}
            }
        }
    }

	private static void validatePartDuplicacy(List<Website_Product__c> productList ){
		Set<Id> newWebProdPartIdSet = new Set<Id>();
		for(Website_Product__c webProObj : productList){
			if(webProObj.Part__c != null){
				newWebProdPartIdSet.add(webProObj.Part__c);
			}
		}
		if(newWebProdPartIdSet.size() > 0) {
			List<AggregateResult> WebProdList = [Select count(Id), Part__c From Website_Product__c Where Part__c In: newWebProdPartIdSet GROUP BY Part__c HAVING count(Id) > 1];
			if(WebProdList.size() > 0){
				throw new BlackpurlException('Some parts already mapped with another website products');
			}
		}	
	}
}
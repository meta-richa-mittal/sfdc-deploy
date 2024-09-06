/**
 * Author: Nidhi Sharma
 * Since: June 18, 2021
 * Name: WebsiteProductTrigger
 * Description: Trigger helper class
**/
public without sharing class WebsiteProductTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    
    public static void afterInsert(List<Website_Product__c> productList) {
    	populatePartFields(productList, null);
    }
    
    public static void beforeUpdate(List<Website_Product__c> newList, Map<Id, Website_Product__c> oldMap) {
        populateSparseUpdateFields(newList, oldMap);
    }
    
    public static void afterUpdate(List<Website_Product__c> productList, Map<Id, Website_Product__c> oldMap) {
    	populatePartFields(productList, oldMap);
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
            }
        }
    }
}
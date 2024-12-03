/** 
* Author: Nidhi Sharma
* Since: Nov 07, 2023
* Name: ShopifyProductMapAndSyncBatch 
**/
global without sharing class ShopifyProductMapAndSyncBatch implements Database.Batchable<sobject>, Database.AllowsCallouts {
	
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Group_Id__c, SKU__c, Part__r.Vendor__c FROM Website_Product__c WHERE Part__c = null AND SKU__c != null AND Delete_Pending__c = false' +
            ' ORDER BY Group_Id__c, CreatedDate ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Website_Product__c> unlinkedProductList) {
        try {
            if(ShopifyUtil.isIntegrationActive) {
                Map<String, List<Website_Product__c>> productGroupIdToAllRecListMap = new Map<String, List<Website_Product__c>>();
                for(Website_Product__c websiteProductRec : unlinkedProductList) {
                    productGroupIdToAllRecListMap.put(websiteProductRec.Group_Id__c, new List<Website_Product__c>());
                }
                //query website product where group id in productGroupIdToAllRecListMap keyset and create a map of group id to list of website product
                Set<String> skuIdSet = new Set<String>();
                for(Website_Product__c websiteProductRec : [SELECT Id, Group_Id__c, SKU__c, Part__r.Vendor__c FROM Website_Product__c WHERE Group_Id__c IN :productGroupIdToAllRecListMap.keySet()]) {
                    productGroupIdToAllRecListMap.get(websiteProductRec.Group_Id__c).add(websiteProductRec);
                    skuIdSet.add(websiteProductRec.SKU__c);
                }

                //query part__c where part number in skuIdSet and create a map of part number to list of part__c
                Map<String, List<Part__c>> partNumberToRecListMap = new Map<String, List<Part__c>>();
                for(Part__c partRec : [SELECT Id, Name, Part_Number__c, Vendor__c FROM Part__c WHERE Part_Number__c IN :skuIdSet]) {
                    if(!partNumberToRecListMap.containsKey(partRec.Part_Number__c)) {
                        partNumberToRecListMap.put(partRec.Part_Number__c, new List<Part__c>());
                    }
                    partNumberToRecListMap.get(partRec.Part_Number__c).add(partRec);
                }
                
                //match product list sku__c in partnumber map and if more than 1 value found then continue loop
                Map<String, List<Website_Product__c>> productGroupIdToLinkedRecListMap = new Map<String, List<Website_Product__c>>();
                for(String groupId : productGroupIdToAllRecListMap.keySet()) {
                    for(Website_Product__c websiteProductRec : productGroupIdToAllRecListMap.get(groupId)) {
                        if(websiteProductRec.Part__c == null && websiteProductRec.SKU__c != null && partNumberToRecListMap.containsKey(websiteProductRec.SKU__c)) {
                            if(partNumberToRecListMap.get(websiteProductRec.SKU__c).size() == 1) {
                                //if only 1 value found then update website product record with part__c
                                websiteProductRec.Part__c = partNumberToRecListMap.get(websiteProductRec.SKU__c)[0].Id;
                                websiteProductRec.Part__r = partNumberToRecListMap.get(websiteProductRec.SKU__c)[0];
                                productGroupIdToLinkedRecListMap.put(websiteProductRec.Group_Id__c, new List<Website_Product__c>());
                            }
                        }
                    }
                    for(Website_Product__c websiteProductRec : productGroupIdToAllRecListMap.get(groupId)) {
                        if(websiteProductRec.Part__c != null && productGroupIdToLinkedRecListMap.containsKey(websiteProductRec.Group_Id__c)) {
                            productGroupIdToLinkedRecListMap.get(websiteProductRec.Group_Id__c).add(websiteProductRec);
                        }
                    }
                }
                List<Website_Product__c> mappedWebsiteProducts = validatePartMappings(productGroupIdToLinkedRecListMap);
                DMLUtility.updateSobjectList('Website_Product__c', mappedWebsiteProducts);
            }
        } catch(Exception e) {
            createLogs(e, unlinkedProductList, 'execute');
        }
    }

    private static List<Website_Product__c> validatePartMappings(Map<String, List<Website_Product__c>> productGroupIdToLinkedRecListMap) {
        List<Website_Product__c> mappedWebsiteProducts = new List<Website_Product__c>();
        //validate vendor id of all products under a group id in productGroupIdToLinkedRecListMap
        for(String groupId : productGroupIdToLinkedRecListMap.keySet()) {
            List<Website_Product__c> websiteProductRecList = productGroupIdToLinkedRecListMap.get(groupId);
            String vendorId = websiteProductRecList[0].Part__r.Vendor__c;
            Boolean allProductMatched = true;
            system.debug(websiteProductRecList);
            for(Website_Product__c websiteProductRec : websiteProductRecList) {
                system.debug(vendorId + '    ' + websiteProductRec.Part__r.Vendor__c);
                if(websiteProductRec.Part__r.Vendor__c != vendorId) {
                    allProductMatched = false;
                    break;
                }
            }
            system.debug('allProductMatched    ' + allProductMatched);
            if(allProductMatched) {
                mappedWebsiteProducts.addAll(websiteProductRecList);
            }
        }
        return mappedWebsiteProducts;
    }
    
    global void finish(Database.batchableContext bc) {
        Integer limitRows = SOQLUtil.getAvailableQueryRowsLimit();
        List<Website_Product__c> websiteProductRecList = [SELECT Id FROM Website_Product__c WHERE SKU__c != null AND Part__c != null AND Status__c = 'New' AND Delete_Pending__c = false ORDER BY Group_Id__c, CreatedDate ASC LIMIT :limitRows];
        if(!websiteProductRecList.isEmpty()) Database.executeBatch(new ShopifySyncWebsiteProductBatch(websiteProductRecList), 1);
    }
    
    private void createLogs(Exception e, List<Website_Product__c> unlinkedProductList, String methodName) {
    	String webProductIds = '';
        for(Website_Product__c webProductRec : unlinkedProductList) {
        	webProductIds += webProductRec.Id + ';';
        }
        new LogService().createErrorLog('ShopifyProductMapAndSyncBatch', methodName, e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
        webProductIds, 'Website product mapping', true, 'Error');
    }
}
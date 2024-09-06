/** 
* Author: Nidhi Sharma
* Since: October 9, 2021 
* Name: ShopifyProductService 
* Description: Apex class which contains service methods related to Shopify APIs.
**/
public without sharing class ShopifyProductService {

    public static void syncBPProductWithStoreProductByProductId(String websiteProductId) {
		HTTPResponse response = ShopifyService.getProductByProductId(websiteProductId);
        if(response != null && response.getBody() != null) {
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                handleGetProductResponse(response.getBody());
            } else if(response.getStatusCode() == 400 && response.getBody().containsIgnoreCase('The product Id ' + websiteProductId + ' is not found')) {
                DMLUtility.deleteSobjectList('Website_Product__c', [Select Id from Website_Product__c WHERE Product_Id__c = :websiteProductId]);
            }
        }
	}
	
	private static void handleGetProductResponse(String responseBody) {
        if(String.isNotBlank(responseBody)) {
            List<ShopifyFetchProductWrapper> products = (List<ShopifyFetchProductWrapper>)System.JSON.deserialize(responseBody, List<ShopifyFetchProductWrapper>.class);
            saveShopifyProductsInBP(products);
        }
    }

    public static Set<String> getShopifyIds(List<ShopifyFetchProductWrapper> shopifyProductList) {
        Set<String> shopifyIdSet = new Set<String>();
        for(ShopifyFetchProductWrapper shopifyProductObj : shopifyProductList) {
            shopifyIdSet.add(shopifyProductObj.shopifyId);
        }
        return shopifyIdSet;
    }

    public static Set<String> getShopifyProductIds(List<ShopifyFetchProductWrapper> shopifyProductList) {
        Set<String> shopifyProductIdSet = new Set<String>();
        for(ShopifyFetchProductWrapper shopifyProductObj : shopifyProductList) {
            shopifyProductIdSet.add(shopifyProductObj.shopifyId.substringBefore('.'));
        }
        return shopifyProductIdSet;
    }

    public static Website_Product__c createWebsiteProduct(ShopifyFetchProductWrapper shopifyProductObj, String productId, String variantId) {
        Website_Product__c webProduct = new Website_Product__c();
        webProduct.Title__c = String.isNotBlank(shopifyProductObj.titleProduct) ? shopifyProductObj.titleProduct : shopifyProductObj.title;
        webProduct.Status__c = WebsiteProductManagementUtil.STATUS_NEW;
        webProduct.Product_Vendor__c = shopifyProductObj.vendor;
        webProduct.Option_Label_1__c = shopifyProductObj.optionName1;
        webProduct.Option_Label_2__c = shopifyProductObj.optionName2;
        webProduct.Option_Label_3__c = shopifyProductObj.optionName3;
        webProduct.Option_Value_1__c = shopifyProductObj.optionValue1;
        webProduct.Option_Value_2__c = shopifyProductObj.optionValue2;
        webProduct.Option_Value_3__c = shopifyProductObj.optionValue3;
        webProduct.Product_Id__c = productId;
        webProduct.Variant_Id__c = variantId;
        webProduct.Variant_Position__c = shopifyProductObj.position;
        webProduct.SKU__c = shopifyProductObj.sku;
        return webProduct;
    }

    private static void saveShopifyProductsInBP(List<ShopifyFetchProductWrapper> shopifyProductList) {
    	try {
	    	if(shopifyProductList != null) {
		        List<Website_Product__c> websiteProductUpsertList = new List<Website_Product__c>();
		        Set<String> shopifyProductIdSet = getShopifyProductIds(shopifyProductList);
		        Map<String, Map<String, Website_Product__c>> productIdToVariantIdToWebsiteProductRecMap = getExistingWebProductWithVariantsByProductIds(shopifyProductIdSet);
		        
		        for(ShopifyFetchProductWrapper shopifyProduct : shopifyProductList) {
		        	try {
                        Website_Product__c webProduct = createWebsiteProduct(shopifyProduct, shopifyProduct.shopifyId.substringBefore('.'), shopifyProduct.shopifyId.substringAfter('.'));
                        if(productIdToVariantIdToWebsiteProductRecMap.containsKey(webProduct.Product_Id__c)) {
                            Map<String, Website_Product__c> uniqueIdToWebProductRecMap = productIdToVariantIdToWebsiteProductRecMap.get(webProduct.Product_Id__c);
                            if(uniqueIdToWebProductRecMap.containsKey(shopifyProduct.shopifyId)) {
                                webProduct.Id = uniqueIdToWebProductRecMap.get(shopifyProduct.shopifyId).Id;
                                webProduct.Status__c = uniqueIdToWebProductRecMap.get(shopifyProduct.shopifyId).Status__c;
                                uniqueIdToWebProductRecMap.remove(shopifyProduct.shopifyId);
                            }
                        }
                        websiteProductUpsertList.add(webProduct);
		        	} catch(Exception e) {
                        new LogService().createErrorLog('ShopifyProductService', 'saveShopifyProductsInBP()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                            String.valueOf(shopifyProductList), LogService.SHOPIFY, true, 'Error');
		        	}
		        }

                List<Website_Product__c> websiteProductDeleteList = new List<Website_Product__c>();
		        for(String productId : productIdToVariantIdToWebsiteProductRecMap.keySet()) {
                    websiteProductDeleteList.addAll(productIdToVariantIdToWebsiteProductRecMap.get(productId).values());
                }
		    	DMLUtility.upsertSobjectList('Website_Product__c', websiteProductUpsertList, false);
                DMLUtility.deleteSobjectList('Website_Product__c', websiteProductDeleteList, false);
	    	}
    	} catch(Exception e) {
            new LogService().createErrorLog('ShopifyProductService', 'saveShopifyProductsInBP()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                String.valueOf(shopifyProductList), LogService.SHOPIFY, true, 'Error');
		}
    }

    private static Map<String, Map<String, Website_Product__c>> getExistingWebProductWithVariantsByProductIds(Set<String> productIdSet) {
        Map<String, Map<String, Website_Product__c>> productIdToVariantIdToWebsiteProductRecMap = new Map<String, Map<String, Website_Product__c>>();
        if(productIdSet.size() > 0) {
	        for(Website_Product__c productRec : [SELECT Id, Status__c, Product_Id__c, Unique_Id__c FROM Website_Product__c WHERE Product_Id__c IN :productIdSet]) {
	            if(!productIdToVariantIdToWebsiteProductRecMap.containsKey(productRec.Product_Id__c)) {
                    productIdToVariantIdToWebsiteProductRecMap.put(productRec.Product_Id__c, new Map<String, Website_Product__c>());
                }
                productIdToVariantIdToWebsiteProductRecMap.get(productRec.Product_Id__c).put(productRec.Unique_Id__c, productRec);
	        }
        }
        return productIdToVariantIdToWebsiteProductRecMap;
	}

    public static void getProductByProductNumAndVendorCode(Website_Product__c productRec) {
        if(productRec != null && productRec.Product_Id__c == null && productRec.Part__c != null) {
            HTTPResponse response = ShopifyService.getProductByProductNumAndVendorCode(productRec, null, null);
            if(response != null && response.getBody() != null) {
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    parseResponseAndSetShopifyId(response.getBody(), productRec);
                }
            }
        }
    }

    public static void getProductByProductNumAndVendorCode(Website_Product__c productRec, Map<Integer, Set<String>> retryIntervalToProductIdSetMap, Integer retryAttemptNumber) {
        if(productRec != null && productRec.Product_Id__c == null && productRec.Part__c != null) {
            HTTPResponse response = ShopifyService.getProductByProductNumAndVendorCode(productRec, retryIntervalToProductIdSetMap, retryAttemptNumber);
            if(response != null && response.getBody() != null) {
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    parseResponseAndSetShopifyId(response.getBody(), productRec);
                } else {
                    productRec.Website_API_Response__c = response.getBody().abbreviate(32768);
                    productRec.Status__c = WebsiteProductManagementUtil.STATUS_ERROR;
                }
            }
        }
	}

    private static void parseResponseAndSetShopifyId(String response, Website_Product__c productRec) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        List<Object> productsJson = (List<Object>) JSON.deserializeUntyped(system.Json.serialize(responseMap.get('products')));
        String shopifyId;
        if(productsJson.size() == 1) {
            Map<String, Object> productObj = (Map<String, Object>) JSON.deserializeUntyped(system.Json.serialize(productsJson[0]));
            shopifyId = String.valueOf(productObj.get('shopifyId'));
        } else if(productsJson.size() > 1) {
            Integer titleMatchedCount = 0;
            for(Object obj : productsJson) {
                Map<String, Object> productObj = (Map<String, Object>) JSON.deserializeUntyped(system.Json.serialize(obj));
                String title;
                if(productObj.containsKey('titleProduct')) {
                    title = String.valueOf(productObj.get('titleProduct'));
                } else if(productObj.containsKey('title')){
                    title = String.valueOf(productObj.get('title'));
                }
                if(String.isNotBlank(title) && title == productRec.Title__c) {
                    if(titleMatchedCount == 0 || (productObj.get('status') != null && 
                    String.valueOf(productObj.get('status')).equalsIgnoreCase('Active'))) {
                        shopifyId = String.valueOf(productObj.get('shopifyId'));
                    }
                    titleMatchedCount++;
                }
            }
        }
        if(String.isNotBlank(shopifyId)) {
            productRec.Product_Id__c = shopifyId.substringBefore('.');
            productRec.Variant_Id__c = shopifyId.substringAfter('.');
            productRec.Status__c = WebsiteProductManagementUtil.STATUS_LINKED;
            productRec.Website_API_Response__c = null;
        }
    }
}
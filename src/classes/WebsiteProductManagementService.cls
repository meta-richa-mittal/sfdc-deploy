/** 
* Author: Richa Mittal
* Since: June 2, 2021 
* Name: WebsiteProductManagementService 
* Description: Apex class which contains all service methods related to Website Product Management Ctrl.
**/
public without sharing class WebsiteProductManagementService {
	
    // To return Json of all shopify products based on filter conditions excluding delete Pending products
    public static List<WebsiteProductWrapper> getAllProducts(String filterString) {
    	WebsiteProductFilterWrapper filterObj = (WebsiteProductFilterWrapper) System.JSON.deserialize(filterString, WebsiteProductFilterWrapper.class);
    	return getProductsObjList(WebsiteProductManagementSOQLUtil.getAllProducts(filterObj));
    }
    
    //To return website product count based on filter conditions excluding delete Pending products
    public static Map<String, String> getProductStatics(String filterString) {
    	WebsiteProductFilterWrapper filterObj = (WebsiteProductFilterWrapper) System.JSON.deserialize(filterString, WebsiteProductFilterWrapper.class);
    	
    	Map<String, String> keyToValueMap = new Map<String, String>();
    	if(filterObj.statusList == null || filterObj.statusList.size() == 0 || (new Set<String>(filterObj.statusList)).contains('All')) {
    		keyToValueMap.put('DateTimeWhenSearchExecuted', String.valueOf(system.now()));
    	}
    	
    	List<AggregateResult> aggList = WebsiteProductManagementSOQLUtil.getProductStatics(filterObj);
    	keyToValueMap.put('ProductCount', String.valueOf((aggList.size() > 0) ? (Integer) aggList[0].get('ProductCount') : 0));
    	
    	return keyToValueMap;
    }
    
    //To return website info if shopify integration is enabled
    public static WebsiteInfoWrapper getWebsiteInfo() {
    	return new WebsiteInfoWrapper();
    }
    
    //To save product variant with part lookup, update status to syncing and shopiy product lookup on part
    public static void saveProductAndVariants(String productVariantJSON) {
    	WebsiteProductVariantWrapper productObj = (WebsiteProductVariantWrapper) System.JSON.deserialize(productVariantJSON, WebsiteProductVariantWrapper.class);
    	List<Website_Product__c> productInsertList = new List<Website_Product__c>();
    	String guid = GuidUtil.generateGuid();
    	for(WebsiteProductVariantWrapper.VariantWrapper variantObj : productObj.VariantOptionList) {
    		productInsertList.add(setProductVariantSObjectList(variantObj, productObj.Title, productObj.IsPublishAsDraft, guid, productObj.ProductId));
    	}
    	productInsertList = DMLUtility.upsertSobjectList('Website_Product__c', productInsertList);
        Database.executeBatch(new ShopifySyncWebsiteProductBatch(productInsertList), 1);    
    }
    
    //To delete product variant from website and BP, if failed to delete in BP turn on delete pending flag on product
    public static void deleteProductVariant(String productId) {
    	ShopifyService.deleteProductByBPProductId(productId);
    }
    
    //To product vendor name list	
    public static List<String> getProductVendor(String searchKeyword) {
    	return WebsiteProductManagementSOQLUtil.getProductVendor(BPUtility.escapeSingleQuotes(searchKeyword));
    }
    
    //Polling action
    public static void pollProductsFromWebsite() {
    	ShopifyFetchProductsBatchScheduler.updatePollingIndicator(true);
    	ShopifyFetchProductsBatchScheduler.rescheduleAfterSpecifiedSeconds(0);
    }
    
    //Return true/false if polling in progress
    public static Boolean isPollingInProgress() {
    	return Shopify_Configuration__c.getOrgDefaults().Polling_In_Progress__c;
    }
    
    //To search Parts with various filters
    public static List<PartWrapper> searchPartWithFilters(String searchQueryJsonStr) {
    	PartFilterWrapper filterObj = (PartFilterWrapper) System.JSON.deserialize(searchQueryJsonStr, PartFilterWrapper.class);
    	filterObj.HardCodedWhereClause = 'Shopify_Product__c = null';
    	return PartService.getPartObjList(PartService.getAllParts(filterObj));
    }
    
    //To search Parts with various filters
    public static String getTotalParts(String searchQueryJsonStr) {
        PartFilterWrapper filterObj = (PartFilterWrapper) System.JSON.deserialize(searchQueryJsonStr, PartFilterWrapper.class);
        filterObj.HardCodedWhereClause = 'Shopify_Product__c = null';
        PartService.limitRecord = 1001;
        List<Part__c> partList = PartService.getAllParts(filterObj);
        return ((partList.size() > 1000) ? '1000+' : String.valueOf(partList.size()));
    }
    
    //To search active vendor by startwith name 
    public static List<Vendor> searchBPVendors(String searchKeyword) {
    	List<Vendor> vendorList = new List<Vendor>();
    	if(String.isNotBlank(searchKeyword) && searchKeyword.trim().length() >= 3) {
    		List<FilterJSON> filerObjList = new List<FilterJSON>{
    			new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
    			new FilterJSON('Name', SOQLUtility.STARTS_WITH, searchKeyword)
    		};
	    	vendorList = VendorSearchService.getVendorObjList(VendorSearchService.getVendorsByName(null, filerObjList));
    	}
    	return vendorList;
    }
    
    //To search tags by name and fetch matching active tages
    public static List<TagWrapper> searchTags(String searchKeyword) {
    	List<TagWrapper> tagList = new List<TagWrapper>();
    	if(String.isNotBlank(searchKeyword) && searchKeyword.trim().length() >= 3) {
    		List<FilterJSON> filerObjList = new List<FilterJSON>{
    			new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
    			new FilterJSON('Name__c', SOQLUtility.STARTS_WITH, searchKeyword)
    		};
	    	tagList = TagService.getTagObjList(TagService.getFilteredTagList(filerObjList));
    	}
    	return tagList;
    }
    
    //To search categories by name and fetch matching active categories
    public static List<CategoryService.CategoryWrapper> searchCategories(String searchKeyword) {
    	List<CategoryService.CategoryWrapper> categoryList = new List<CategoryService.CategoryWrapper>();
    	if(String.isNotBlank(searchKeyword) && searchKeyword.trim().length() >= 3) {
    		List<FilterJSON> filerObjList = new List<FilterJSON>{
    			new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
    			new FilterJSON('Type__c', SOQLUtility.EQUALS, Constants.CATEGORY_TYPE_PART),
    			new FilterJSON('Name', SOQLUtility.STARTS_WITH, searchKeyword)
    		};
	    	categoryList = CategoryService.getCategoryObjList(CategoryService.getFilteredCategoryList(filerObjList));
    	}
    	return categoryList;
    }
    
    //Save products
    public static void saveProducts(String productsJson) {
    	List<WebsiteProductWrapper> productObjList = (List<WebsiteProductWrapper>) System.JSON.deserialize(productsJson, List<WebsiteProductWrapper>.class);
    	List<Website_Product__c> productInsertList = DMLUtility.upsertSobjectList(
    		'Website_Product__c', setProductSObjectList(productObjList, WebsiteProductManagementUtil.STATUS_SYNCING)
		);
        Database.executeBatch(new ShopifySyncWebsiteProductBatch(productInsertList), 1);
    }
    
    // Method to get Website Product wrapper object from sObjectList
    private static List<WebsiteProductWrapper> getProductsObjList(List<Website_Product__c> productList) {
    	List<WebsiteProductWrapper> productsObjList = new List<WebsiteProductWrapper>();
    	for(Website_Product__c productRec: productList) {
    		productsObjList.add(new WebsiteProductWrapper(productRec));
    	}
    	return productsObjList;
    }
    
    private static List<Website_Product__c> setProductSObjectList(List<WebsiteProductWrapper> productObjList, String status) {
    	List<Website_Product__c> productRecList = new List<Website_Product__c>();
    	if(productObjList != null) {
    		for(WebsiteProductWrapper productObj : productObjList) {
    			productRecList.add(setProductFields(productObj, status));
    		}
    	}
    	return productRecList;
    }
    
    private static Website_Product__c setProductFields(WebsiteProductWrapper productObj, String status) {
    	Website_Product__c productRec = new Website_Product__c(Id = productObj.Id);
    	productRec.Title__c = productObj.Title;
    	productRec.Product_Vendor__c = productObj.ProductVendor;
    	productRec.Part__c = productObj.PartId;
    	if(productObj.IsPublishAsDraft != null) {
			productRec.Publish_as_Draft__c = productObj.IsPublishAsDraft;
    	}
		productRec.Status__c = status;
		if(String.isBlank(productObj.Id)) {
		    productRec.Internal_Product_Id__c = GuidUtil.generateGuid();
		}
    	if(productObj.IsIgnored != null && productObj.IsIgnored) {
    		productRec.Part__c = null;
    		productRec.Status__c = WebsiteProductManagementUtil.STATUS_IGNORED;
    	} /*else if(String.isBlank(status) && String.isNotBlank(productObj.Status)) {
    		productRec.Status__c = productObj.Status;
    	}*/
    	return productRec;
    }
    
    private static Website_Product__c setProductVariantSObjectList(WebsiteProductVariantWrapper.VariantWrapper variantObj, String title, 
                                                                    Boolean isPublishAsDraft, String groupId, String productId) {
    	Website_Product__c productRec = new Website_Product__c(Id = variantObj.Id);
    	productRec.Title__c = String.isNotBlank(title) ? title : variantObj.PartDesc;
    	productRec.Part__c = variantObj.PartId;
    	productRec.Option_Label_1__c = variantObj.Label1;
    	productRec.Option_Label_2__c = variantObj.Label2;
		productRec.Option_Label_3__c = variantObj.Label3;
		productRec.Option_Value_1__c = variantObj.Value1;
    	productRec.Option_Value_2__c = variantObj.Value2;
		productRec.Option_Value_3__c = variantObj.Value3;
		productRec.Internal_Product_Id__c = groupId;
		if(variantObj.VariantPosition != null) {
			productRec.Variant_Position__c = variantObj.VariantPosition;
		}
		if(isPublishAsDraft != null) {
            productRec.Publish_as_Draft__c = isPublishAsDraft;
		}
		productRec.Product_Vendor__c = variantObj.ProductVendor;
		productRec.Status__c = WebsiteProductManagementUtil.STATUS_SYNCING;
		if(variantObj.Id == null) {
            productRec.Product_Id__c = productId;
		}
    	return productRec;
    }
    
    public static WebsiteProductVariantWrapper getProductVariantList(String websiteProductId) {
        return new WebsiteProductVariantWrapper(WebsiteProductManagementSOQLUtil.getProductVariantsByProductId(websiteProductId));
    }

	public static WebsiteProductVariantWrapper getProductVariantsByPartId(String partId) {
		return new WebsiteProductVariantWrapper(WebsiteProductManagementSOQLUtil.getProductVariantsByPartId(partId));
	}
	
	//Fetch product with variants by product id from store and save/delete in BP to sync with store
	public static ResponseWrapper syncBPProductWithStoreProductByProductId(String websiteProductId) {
        ShopifyProductService.syncBPProductWithStoreProductByProductId(websiteProductId);
        String query = 'Select Id, Title__c, Part__c, Variant_Id__c from Website_Product__c where Delete_Pending__c = false AND Product_Id__c = \'' + BPUtility.escapeSingleQuotes(websiteProductId) + '\'';
        List<Website_Product__c> webProducts = SOQLUtility.getQueryResults('Website_Product__c', query);
		
		ResponseWrapper responseObj = new ResponseWrapper(200, 'Success');
		if(webProducts.size() == 0) {
			responseObj = new ResponseWrapper(202, 'The item you are trying to manage no longer exists in the shopify store.');
		} else {
			for(Website_Product__c productRec : webProducts) {
				if(productRec.Part__c == null) {
					Map<String, String> body = new Map<String, String>{
						'Title' => productRec.Title__c,
						'ProductId' => websiteProductId
					};
					if(String.isNotBlank(productRec.Variant_Id__c)) {
						body.put('Message', 'Some variants are unlinked. Please link each variant with a part before managing variants.');
					} else {
						body.put('Message', 'The item you are trying to manage is now a no variant product. Please link with a part before managing product.');
					}
					responseObj = new ResponseWrapper(300, System.JSON.serialize(body));
					break;
				}
			}
		}
		return responseObj;
    }
}
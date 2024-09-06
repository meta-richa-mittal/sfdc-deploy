/** 
* Author: Nidhi Sharma
* Since: Dec 17, 2020
* Name: ShopifyService 
* Description: Apex class which contains Shopify integration methods.
**/
public without sharing class ShopifyService {
	
    public static List<Log__c> errorLogs = new List<Log__c>();
    public static IFW_IntegrationConfig__c parent; 
    public static String previousBearerToken;
    public static Integer retryAttemptNumber = 0;
	public static String httpRequestFailedErrorMsg; // used in batch class to save error to all records of an execute
	public static List<String> processingProductSFIdList = new List<String>();
	
	public static HTTPResponse getProductByProductId(String websiteProductId) {
		IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.SHOPIFY_PRODUCT_BY_ID, 'GET', ShopifyUtil.integrationName);
		child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{{product_id}}', websiteProductId);
		HTTPResponse response = doCalloutWithErrorHandling(child, null, null);
		updateValues();
		return response;
	}

	public static HTTPResponse getProductByProductNumAndVendorCode(Website_Product__c productRec, Map<Integer, Set<String>> retryIntervalToProductIdSetMap, Integer retryAttemptNumber) {
		if(String.isBlank(productRec.Part__r.Part_Number__c) || String.isBlank(productRec.Part__r.Vendor_Code__c)) {
			throw new BlackPurlException('Product Number and vendor code must not be blank');
		}
		IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.SHOPIFY_PRODUCT_BY_DETAILS, 'GET', ShopifyUtil.integrationName);
		Map<String, String> urlParamMap = new Map<String, String>{
			'productNumber' =>  productRec.Part__r.Part_Number__c.replaceAll(' ', '+'),
			'vendorCode' => productRec.Part__r.Vendor_Code__c
		};
		return doCalloutWithErrorHandling(child, urlParamMap, null, retryIntervalToProductIdSetMap, retryAttemptNumber, new List<Website_Product__c>{productRec});
	}

	//Not in use
    public static Boolean saveProduct(String body, Map<String, Part__c> productUIDtoPartRecMap) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT, 'POST', ShopifyUtil.integrationName);
        HTTPResponse response = doCalloutWithErrorHandling(child, new Map<String, String>(), body);
        return handleProductResponse(response, productUIDtoPartRecMap);
    }

	public static void createProducts(String body, Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT, 'POST', ShopifyUtil.integrationName);
        HTTPResponse response = doCalloutWithErrorHandling(child, new Map<String, String>(), body);
        handleProductResponse(response, productUIDtoWebsiteProductRecMap);
    }

	public static void createProducts(String body, Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap, Map<Integer, 
										Set<String>> retryIntervalToProductIdSetMap, Integer retryAttemptNumber) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT, 'POST', ShopifyUtil.integrationName);
        HTTPResponse response = doCalloutWithErrorHandling(child, new Map<String, String>(), body, retryIntervalToProductIdSetMap, retryAttemptNumber, productUIDtoWebsiteProductRecMap.values());
		handleProductResponse(response, productUIDtoWebsiteProductRecMap, retryAttemptNumber, retryIntervalToProductIdSetMap);
    }
    
	//Not in use
    public static Boolean handleProductResponse(HTTPResponse response, Map<String, Part__c> productUIDtoPartRecMap) {
    	List<ShopifyProductResponseWrapper> productList = new List<ShopifyProductResponseWrapper>();
    	if(response != null) {
    		if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
	    		try {
	    			productList = (List<ShopifyProductResponseWrapper>) System.JSON.deserialize(response.getBody(), List<ShopifyProductResponseWrapper>.class);
	    		} catch(Exception e) {
	    			system.debug('Create shopify product response :: ' + response);
	    		}
	    	} else {
	    		httpRequestFailedErrorMsg = (response.getStatusCode() + '-' + response.getBody()).abbreviate(32768);
	    	}
    	}
		for(ShopifyProductResponseWrapper product : productList) {
			if(productUIDtoPartRecMap.containsKey(product.productNumber + ShopifyUtil.productAndVendorCodeConnectorKey + product.vendorCode)) {
				Part__c partRec = productUIDtoPartRecMap.get(product.productNumber + ShopifyUtil.productAndVendorCodeConnectorKey + product.vendorCode);
	            partRec.Shopify_ID__c = product.shopifyId;
	            partRec.Available_For_Shopify_Sync__c = false;
			}
		}
    	return true;
    }

	public static void handleProductResponse(HTTPResponse response, Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap) {
		handleProductResponse(response, productUIDtoWebsiteProductRecMap, null, null);
	}
    
    public static void handleProductResponse(HTTPResponse response, Map<String, Website_Product__c> productUIDtoWebsiteProductRecMap, Integer retryAttemptNumber, Map<Integer, Set<String>> retryIntervalToProductIdSetMap) {
    	List<ShopifyProductResponseWrapper> productList = new List<ShopifyProductResponseWrapper>();
    	if(response != null) {
    		if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
	    		try {
	    			productList = (List<ShopifyProductResponseWrapper>) System.JSON.deserialize(response.getBody(), List<ShopifyProductResponseWrapper>.class);
	    		} catch(Exception e) {
	    			system.debug('Create shopify product response :: ' + response);
	    		}
	    	} else {
	    		httpRequestFailedErrorMsg = (response.getStatusCode() + '-' + response.getBody()).abbreviate(32768);
	    	}
    	}
    	Map<String, ShopifyProductResponseWrapper> uniqueKeyToProductObjMap = new Map<String, ShopifyProductResponseWrapper>();
    	for(ShopifyProductResponseWrapper productObj : productList) {
		    String uniqueKey = (productObj.productNumber + ShopifyUtil.productAndVendorCodeConnectorKey + productObj.vendorCode);
		    uniqueKeyToProductObjMap.put(uniqueKey, productObj);
    	}
		String guid;
    	for(String uniqueKey : productUIDtoWebsiteProductRecMap.keySet()) {
			if(uniqueKey.contains('null' + ShopifyUtil.productAndVendorCodeConnectorKey)) {
				continue;
			}
    		Website_Product__c websiteProductRec = productUIDtoWebsiteProductRecMap.get(uniqueKey);
    		if(uniqueKeyToProductObjMap.containsKey(uniqueKey)) {
    			ShopifyProductResponseWrapper product = uniqueKeyToProductObjMap.get(uniqueKey);
    			if(product.shopifyId != null && product.shopifyId.contains('.')) {
				    websiteProductRec.Product_Id__c = product.shopifyId.substringBefore('.');
				    websiteProductRec.Variant_Id__c = product.shopifyId.substringAfter('.');
				} else {
				    websiteProductRec.Product_Id__c = product.shopifyId;
				}
				if(String.isNotBlank(websiteProductRec.Product_Id__c) && isSuccessfullySynced(product.userErrors)) {
    				websiteProductRec.Status__c = WebsiteProductManagementUtil.STATUS_LINKED;
					websiteProductRec.Website_API_Response__c = null;
					websiteProductRec.Shopify_Sparse_Update_Fields__c = null;
				} else {
					setErrorFields(String.valueOf(product.userErrors), retryAttemptNumber, websiteProductRec);
					Boolean isRecreate = includeInRecreateProductMap(websiteProductRec, product.userErrors, retryIntervalToProductIdSetMap);
					if(isRecreate) {
						if(String.isBlank(websiteProductRec.Internal_Product_Id__c)) {
							guid = String.isBlank(guid) ? GuidUtil.generateGuid() : guid;
							websiteProductRec.Internal_Product_Id__c = guid;
						}
					}
				}
    		} else  {
    			setErrorFields(httpRequestFailedErrorMsg, retryAttemptNumber, websiteProductRec);
    		}
    	}
    }

	private static Boolean isSuccessfullySynced(List<ShopifyProductResponseWrapper.ErrorMessageWrapper> userErrors) {
		Boolean isSuccessfullySynced = userErrors == null ? true : false;
		if(!isSuccessfullySynced) {
			if(userErrors.size() == 1 && String.isNotBlank(userErrors[0].message)) {
				if(userErrors[0].message.startsWithIgnoreCase('The variant Id ') && userErrors[0].message.endsWithIgnoreCase(' is not found, a new variant will be created')) {
					isSuccessfullySynced = true;
				}
			}
		}
		return isSuccessfullySynced;
	}

	private static Boolean includeInRecreateProductMap(Website_Product__c websiteProductRec, List<ShopifyProductResponseWrapper.ErrorMessageWrapper> userErrors, Map<Integer, Set<String>> retryIntervalToProductIdSetMap) {
		if(retryIntervalToProductIdSetMap != null && userErrors != null && userErrors.size() > 0 && websiteProductRec != null) {
			for(ShopifyProductResponseWrapper.ErrorMessageWrapper userError : userErrors) {
				if(String.isNotBlank(websiteProductRec.Product_Id__c) && String.isNotBlank(userError.message) && 
					(userError.message.containsIgnoreCase('Title can\'t be blank') || 
					(userError.message.startsWithIgnoreCase('The product Id ') && userError.message.endsWithIgnoreCase(' is not found, a new product will be created')))
				) {
					websiteProductRec.Product_Id__c = websiteProductRec.Variant_Id__c = null;
					
					Integer retryIntervalValue = 0;
					if(!retryIntervalToProductIdSetMap.containsKey(retryIntervalValue)) {
						retryIntervalToProductIdSetMap.put(retryIntervalValue, new Set<String>());
					}
					retryIntervalToProductIdSetMap.get(retryIntervalValue).add(websiteProductRec.Id);
					return true;
				}
			}
		}
		return false;
	}
    
    public static void deleteProductByBPProductId(String bpProductId) {
    	List<Website_Product__c> webProductList = [SELECT Id, Retry_Attempt_Counter__c, Product_Id__c, Variant_Id__c FROM Website_Product__c WHERE Id =: bpProductId];
    	if(webProductList.size() > 0) {
    		deleteWebsiteProductFromShopify(webProductList[0]);
    		if(webProductList[0].Delete_Pending__c != null && webProductList[0].Delete_Pending__c) {
				webProductList[0].Retry_Attempt_Counter__c = retryAttemptNumber;
    			DMLUtility.updateSobjectList('Website_Product__c', webProductList[0]);
    		} else {
    			DMLUtility.deleteSobjectList('Website_Product__c', webProductList[0]);
    		}
    	}
    }
    
    public static void deleteWebsiteProductFromShopify(Website_Product__c websiteProductRec) {
    	if(websiteProductRec != null && String.isNotBlank(websiteProductRec.Id)) {
    	    HTTPResponse response;
    	    if(String.isNotBlank(websiteProductRec.Variant_Id__c) || String.isNotBlank(websiteProductRec.Product_Id__c)) {
    	    	websiteProductRec.Delete_Pending__c = true;
	    		try {
		    		if(String.isNotBlank(websiteProductRec.Variant_Id__c)) {
		    			response = deleteProductVariant(websiteProductRec.Variant_Id__c);
		    		} else if(String.isNotBlank(websiteProductRec.Product_Id__c)) {
		    			response = deleteProduct(websiteProductRec.Product_Id__c);
		    		}
		    		updateValues();
		    		
		    		if(response != null) {
			    		if(response.getStatusCode() == 200 || response.getStatusCode() == 201 || (response.getStatusCode() == 400 && 
			    			(response.getBody().containsIgnoreCase('Product variant does not exist')) || response.getBody().containsIgnoreCase('Product does not exist'))) {
				    		websiteProductRec.Delete_Pending__c = false;
			    		} else {
							websiteProductRec.Retry_Attempt_Counter__c = websiteProductRec.Retry_Attempt_Counter__c != null ? 
                                                                    ++websiteProductRec.Retry_Attempt_Counter__c : retryAttemptNumber;
			    			websiteProductRec.Website_API_Response__c = (response != null ? response.getStatusCode() + ' - ' + response.getBody() : 
			    				websiteProductRec.Website_API_Response__c).abbreviate(32768);
			    		}
			    	}
		    	} catch(Exception e) {
		    		websiteProductRec.Website_API_Response__c = e.getMessage().abbreviate(32768);
		    	}
    	    } else {
    	    	websiteProductRec.Delete_Pending__c = false;
    	    }
    	}
    }
    
    public static HttpResponse deleteProduct(String productId) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT, 'DELETE', ShopifyUtil.integrationName);
        Map<String, String> urlParamMap = new Map<String, String>{'productId' =>  productId};
        return doCalloutWithErrorHandling(child, urlParamMap, null);
    }
    
    public static HttpResponse deleteProductVariant(String variantId) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT_VARIANT, 'DELETE', ShopifyUtil.integrationName);
        Map<String, String> urlParamMap = new Map<String, String>{'variantId' =>  variantId};
        return doCalloutWithErrorHandling(child, urlParamMap, null);
    }
    
    public static ShopifyResponseWrapper getPaginatedProductsJsonByCursor(String cursor) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.PRODUCT, 'GET', ShopifyUtil.integrationName);
        Map<String, String> urlParamMap = String.isNotBlank(cursor) ? new Map<String, String>{'cursor' =>  cursor} : null;
        String responseBody = parseResponse(doCalloutWithErrorHandling(child, urlParamMap, null));
        if(String.isNotBlank(responseBody)) {
        	return (ShopifyResponseWrapper)System.JSON.deserialize(responseBody, ShopifyResponseWrapper.class);
        }
        return null;  
    }
    
    public static List<ShopifyOrderWrapper> getOrdersByOrderNumber(String orderNumber) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.SHOPIFY_ORDER, 'GET', ShopifyUtil.integrationName);
        Map<String, String> urlParamMap = new Map<String, String>{'orderNumber' =>  orderNumber};
        return handleOrderResponse(doCallout(child, urlParamMap));
    }
    
    public static List<ShopifyOrderWrapper> getOrdersByDate(String startDate, String endDate) {
        return getPaginatedOrdersByDate(startDate, endDate, null);
    }
    
    public static List<ShopifyOrderWrapper> getPaginatedOrdersByDate(String startDate, String endDate, String cursor) {
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(ShopifyUtil.SHOPIFY_ORDER, 'GET', ShopifyUtil.integrationName);
        Map<String, String> urlParamMap = new Map<String, String>{'startDate' =>  startDate, 'endDate' =>  endDate};
        if(String.isNotBlank(cursor)) {
            urlParamMap.put('cursor', cursor);
        }
        
        List<ShopifyOrderWrapper> shopifyOrderList = new List<ShopifyOrderWrapper>();
        ShopifyResponseWrapper shopifyResponseObj;
        do {
            String reponseBody = doCallout(child, urlParamMap);
            if(String.isNotBlank(reponseBody)) {
	            shopifyResponseObj = (ShopifyResponseWrapper)System.JSON.deserialize(reponseBody, ShopifyResponseWrapper.class);
	            if(shopifyResponseObj.orders != null && shopifyResponseObj.orders.size() > 0) {
	                shopifyOrderList.addAll(shopifyResponseObj.orders);
	            }
	            if(String.isNotBlank(shopifyResponseObj.cursor)) {
	                urlParamMap.put('cursor', shopifyResponseObj.cursor);
	            }
	        } else {
				shopifyResponseObj = null;
			}
        } while(shopifyResponseObj != null && shopifyResponseObj.hasNextPage); //Discussed with TK to remove:: && counter < 10
        updateValues();
        if(shopifyResponseObj == null && shopifyOrderList.size() == 0) {
			return null;
		}
        return shopifyOrderList;
    }
    
    public static List<ShopifyOrderWrapper> handleOrderResponse(String reponseBody) {
        List<ShopifyOrderWrapper> shopifyOrderList = new List<ShopifyOrderWrapper>();
        if(String.isNotBlank(reponseBody)) {
            ShopifyResponseWrapper shopifyResponseObj = (ShopifyResponseWrapper)System.JSON.deserialize(reponseBody, ShopifyResponseWrapper.class);
            if(shopifyResponseObj.orders != null && shopifyResponseObj.orders.size() > 0) {
                shopifyOrderList.addAll(shopifyResponseObj.orders);
            }
        }
        return shopifyOrderList;
    }
    
    public class ShopifyResponseWrapper {
        public String cursor;
	    public Boolean hasNextPage = false;
	    public List<ShopifyOrderWrapper> orders;
	    public List<ShopifyFetchProductWrapper> products;
    }
    
    public static String doCallout(IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap) {
        return doCallout(child, urlParamMap, null);
    }
    
    public static String doCallout(IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap, String body) {
    	return parseResponse(doCalloutWithErrorHandling(child, urlParamMap, body));
    }

	public static HttpResponse doCalloutWithErrorHandling(IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap, String body) {
		return doCalloutWithErrorHandling(child, urlParamMap, body, null, null, null);
	}
    
    public static HttpResponse doCalloutWithErrorHandling(IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap, String body, 
															Map<Integer, Set<String>> retryIntervalToProductIdSetMap, Integer retryAttemptNumber, List<Website_Product__c> productList) {
        HttpResponse response;
		httpRequestFailedErrorMsg = null;
        urlParamMap = (urlParamMap == null) ? new Map<String, String>() : urlParamMap;
    	try {
            // Validation checks for API reuqest and setting default values
            validateConfigAndSetDefaultValues(child, urlParamMap);
            
            // Perform callout
            response = BaseIntegration.performCallout(parent, child, body, getHeaderList(), urlParamMap, null);
        	
			// retry if request is unsuccessful
			if(!isRequestSuccessful(response, child) && retryIntervalToProductIdSetMap != null) {
				retryRequest(response.getBody(), child, urlParamMap, body, retryIntervalToProductIdSetMap, retryAttemptNumber, productList);
			}
        } catch (Exception e) {
			httpRequestFailedErrorMsg = e.getMessage();

			// retry - retryIntervalToProductIdSetMap: this is the map passed from batch for which retry is to be performed
			if(retryIntervalToProductIdSetMap != null) {
				retryRequest(e.getMessage(), child, urlParamMap, body, retryIntervalToProductIdSetMap, retryAttemptNumber, productList);
			}
            errorLogs.add(new LogService().createErrorLog('ShopifyService', 'doCallout()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
				String.valueOf(child) + String.valueOf(urlParamMap) + body, LogService.SHOPIFY, false, 'Error'));
        }
		return response;
    }

    private static void validateConfigAndSetDefaultValues(IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap) {
        if(!ShopifyUtil.isIntegrationActive) {
            throw new BlackpurlException('Shopify Integration is not active.');
        } else if(child == null) {
            throw new BlackpurlException('IFW Config Item record does not exists.');
        }
        if(parent == null) {
            parent = IntegrationServiceFactory.getIFWConfigByIntegrationName(ShopifyUtil.integrationName); 
            previousBearerToken = parent.Bearer_Token__c;
        }
        if(!urlParamMap.containsKey('shop')) {
            urlParamMap.put('shop', getShopName());
        }
    }
	
    private static String getShopName() {
        String shopName = Shopify_Configuration__c.getOrgDefaults().Shop_Name__c;
		shopName = shopName.replaceAll(' ', '-');
		String shopifyDomain = '.myshopify.com';
		if(!shopName.endsWith(shopifyDomain)) {
		    shopName += shopifyDomain;
		}
        return shopName;
    }
    
    private static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', 'application/json'));
        return headerList;
    }
    
    private static String parseResponse(HttpResponse response) {
        String responseString;
        if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 201)) {
            responseString = response.getBody();
            system.debug('== responseString == ' + responseString);
        }
        return responseString;
    }

	public static void saveErrorResponse(Integer retryAttemptNumber, List<Website_Product__c> productList) {
		for(Website_Product__c productRec: productList) {
			setErrorFields(httpRequestFailedErrorMsg, retryAttemptNumber, productRec);
		}
	}

	private static void setErrorFields(String errorMsg, Integer retryAttemptNumber, Website_Product__c productRec) {
		productRec.Status__c = WebsiteProductManagementUtil.STATUS_ERROR;
		productRec.Website_API_Response__c = (errorMsg != null && errorMsg.length() > 32768) ? errorMsg.subString(0, 32768) : errorMsg;
	}

	private static HttpResponse retryRequest(String errorMsg, IFW_IntegrationConfigItem__c child, Map<String, String> urlParamMap, String reqBody, 
												Map<Integer, Set<String>> retryIntervalToProductIdSetMap, Integer retryAttemptNumber, List<Website_Product__c> productList) {
		httpRequestFailedErrorMsg = errorMsg;
		saveErrorResponse(retryAttemptNumber, productList);
		Integer retryIntervalInSec = getRetryIntervalByErrorMsg(errorMsg);
		if(retryIntervalInSec != null) {
			if(child.Entity_Name__c.equalsIgnoreCase(ShopifyUtil.PRODUCT) || child.Entity_Name__c.equalsIgnoreCase(ShopifyUtil.SHOPIFY_PRODUCT_BY_DETAILS)) {
				if(processingProductSFIdList.size() > 0) {
					Integer retryIntervalValue = retryIntervalInSec <= 10 ? 0 : retryIntervalInSec;
					if(!retryIntervalToProductIdSetMap.containsKey(retryIntervalValue)) {
						retryIntervalToProductIdSetMap.put(retryIntervalValue, new Set<String>());
					}
					retryIntervalToProductIdSetMap.get(retryIntervalValue).addAll(processingProductSFIdList);
					processingProductSFIdList = new List<String>();
					system.debug('::retryIntervalToProductIdSetMap value - ' + retryIntervalToProductIdSetMap);
					throw new BlackPurlException('retry ' + child.Entity_Name__c);
				}
			}
		}
		return new HttpResponse();
	}
    
    private static Boolean isRequestSuccessful(HttpResponse response, IFW_IntegrationConfigItem__c child) {
    	if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 201 || 
    	       (child.HTTP_Method__c.equalsIgnoreCase('DELETE') && response.getStatusCode() == 400 && 
    	           (response.getBody().containsIgnoreCase(ShopifyUtil.RETRY_BYPASSED_ERROR_MSG_1) || 
    	               response.getBody().containsIgnoreCase(ShopifyUtil.RETRY_BYPASSED_ERROR_MSG_2))))) {
	    	return true;							 	
		}
		return false;
    }
    
    private static Integer getRetryIntervalByErrorMsg(String errorMsg) {
    	Integer retryInterval;
    	Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(ShopifyUtil.integrationName);
    	for(Integration_Error_Handling_Config__mdt retryConfig : errorTypeToRetryConfigListMap.values()) {
    		if(errorMsg.containsIgnoreCase(retryConfig.Error__c)) {
    			return retryConfig.Retry_After_sec__c != null ? Integer.valueOf(retryConfig.Retry_After_sec__c) : 0;
    		}
    	}
    	return retryInterval;
    }
    
    public static void updateValues() {
        if(parent != null && previousBearerToken != parent.Bearer_Token__c) {
            update parent;
        }
        if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
			DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        if(errorLogs != null && errorLogs.size() > 0) {
			DMLUtility.insertSobjectList('Log__c', errorLogs);
        }
    }

	public static void retrySyncProducts(Map<Integer, Set<String>> retryIntervalToProductIdSetMap, String actionName, Integer retryAttemptNumber) {
		for(Integer retryInterval : retryIntervalToProductIdSetMap.keySet()) {
			List<String> productIdList = new List<String>(retryIntervalToProductIdSetMap.get(retryInterval));
			if(productIdList.size() == 0) return;
			
			if(retryInterval == 0) {
				if(actionName.equalsIgnoreCase('POST')) {
					List<Website_Product__c> productList = getProductRecordList(productIdList);
					Database.executeBatch(new ShopifySyncWebsiteProductBatch(productList, retryAttemptNumber), 1);
				}
			} else {
				//Delete Product
				if(actionName.equalsIgnoreCase('DELETE')) {
					/*String jobName = 'Shopify delete retry scheduler';
					BPUtility.abortScheduledJobByJobName(jobName);
					system.schedule(jobName, BPUtility.getCronExpForGivenTime(retryInterval), new ShopifyDeleteProductBatchScheduler(productIdList));*/
				//Save Product	
				} else if(actionName.equalsIgnoreCase('POST')) {
					String jobName = 'Shopify post retry scheduler';
					BPUtility.abortScheduledJobByJobName(jobName);
					List<Website_Product__c> productList = getProductRecordList(productIdList);
					system.schedule(jobName, BPUtility.getCronExpForGivenTime(retryInterval), new ShopifySyncWebsiteProductBatch(productList, retryAttemptNumber));
				} else if(actionName.equalsIgnoreCase('GET')) {
					/*String cursor = urlParamMap != null && urlParamMap.containsKey('cursor') ? urlParamMap.get('cursor') : null;
					ShopifyFetchProductsBatchScheduler.rescheduleAfterSpecifiedSeconds(retryIntervalInSec, cursor);*/
				}
			}
		}
	}

	private static List<Website_Product__c> getProductRecordList(List<String> productIdList) {
		List<Website_Product__c> productList = new List<Website_Product__c>();
		for(String productId: productIdList) {
			productList.add(new Website_Product__c(Id = productId));
		}
		return productList;
	}
}
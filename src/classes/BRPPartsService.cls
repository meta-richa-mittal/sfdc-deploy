/** 
* Author: Richa Mittal
* Since: June 06, 2024 
* Name: BRPPartsService 
* Description: service class Parts API V4
**/
public without sharing class BRPPartsService {
	
	public static HttpResponse getParts(String pageNumber, String partNumber) {
		String entityName = 'Parts';
		Map<String, String> endPointExchangeParam;
		String currCode = BRP_Settings__c.getOrgDefaults().Currency_Code__c;
		Map<String, String> parameters = new Map<String, String>{  'sales_org' => currencyToSalesOrgMap.get(currCode),
																	'currency' =>  currCode
																};
		if(String.isNotBlank(partNumber)) {
			entityName = 'Part';
			endPointExchangeParam = new Map<String, String>{'{{product_code}}' => partNumber};
		} else {
			String lastChangedDate = BRPUtility.partMasterEffectiveDate != null ? BRPUtility.partMasterEffectiveDate.format('yyyy-MM-dd') : null;
			parameters.put('last_changed_date', (lastChangedDate != null ? lastChangedDate : '1900-01-01'));
			parameters.put('limit', '200');
			parameters.put('page', (String.isNotBlank(pageNumber) ? pageNumber : '1'));

		}
		return BRPUtility.syncToBRP(entityName, null, 'GET', parameters, endPointExchangeParam);
	}

	public static String handleSuccessResponse(String pageNumber, HttpResponse response, Map<String, String> pfCategoryNameToIdMap, Price_File_Mapping__c pfMappingRec, 
												AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj, 
												AutomatedPriceFileImportService.ResultWrapper importResults) {
		if(BRPUtility.getAPIVersion() == BRPUtility.API_VERSION_V2) {
			return BRPPartsMasterService.handleSuccessResponse(pageNumber, response, pfCategoryNameToIdMap, pfMappingRec, fieldMappingObj, importResults);
		}
		
		if(response.getBody().containsIgnoreCase('items')) {
			BRPPartsWrapper resObj = (BRPPartsWrapper)System.JSON.deserialize(response.getBody().replace('"currency":', '"currencyType":'), BRPPartsWrapper.class);
			if(resObj != null && !resObj.items.isEmpty()) {
				importParts(pageNumber, resObj.items, pfCategoryNameToIdMap, pfMappingRec, fieldMappingObj, importResults);
			}
			return getNextPageNumber(resObj.links.next);
		} else {
			BRPPartsWrapper.ItemWrapper resItemObj = (BRPPartsWrapper.ItemWrapper)System.JSON.deserialize(response.getBody().replace('"currency":', '"currencyType":'), BRPPartsWrapper.ItemWrapper.class);
			if(resItemObj != null) {
				importParts(pageNumber, new List<BRPPartsWrapper.ItemWrapper>{resItemObj}, pfCategoryNameToIdMap, pfMappingRec, fieldMappingObj, importResults);
			}
		}
		return null;
	}

	public static String handleErrorResponse(String errorMsg, String requestBody, HttpResponse response) {
		if(BRPUtility.getAPIVersion() == BRPUtility.API_VERSION_V2) {
			return BRPPartsMasterService.handleAPIError(errorMsg, requestBody, response);
		}

		BRPErrorHandler.ErrorMessageWrapper errorMessageObj = BRPErrorHandler.getMessageFromErrorPayload(response);
		BRPLogService obj = new BRPLogService('Parts API', requestBody, null, null, errorMessageObj.code, errorMessageObj.title, 'Error', 'BRPPartsService', 'handleErrorResponse');
		return errorMsg;
	}

	private static void importParts(String pageNumber, List<BRPPartsWrapper.ItemWrapper> itemsList, 
										Map<String, String> pfCategoryNameToIdMap, Price_File_Mapping__c pfMappingRec, 
										AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj, 
										AutomatedPriceFileImportService.ResultWrapper importResults) {
		try {
			List<AutomatedPriceFileImportService.PriceFileWrapper> priceFileRecordList = getAPFPartJson(itemsList, pfCategoryNameToIdMap, pfMappingRec);
			if(!priceFileRecordList.isEmpty()) {
				AutomatedPriceFileImportService.ResultWrapper results = AutomatedPriceFileImportService.importFile(fieldMappingObj, priceFileRecordList);
				importResults.NewParts += results.newParts != null ? results.newParts : 0;
				importResults.UpdatedParts += results.updatedParts != null ? results.updatedParts : 0;
				importResults.FailedParts += results.failedParts != null ? results.failedParts : 0;
			}
		} catch(Exception e) {
			importResults.FailedParts += itemsList.size();
			BRPLogService obj = new BRPLogService('Parts API', 'pageNumber - ' + pageNumber, null, null, null, e.getMessage() + ' - ' + e.getStackTraceString(), 'Error', 'BRPPartsService', 'importParts');
			obj.createLog();
			system.debug('Error in creating APF json or importing process ' + e.getMessage());
		}
	}

	private static List<AutomatedPriceFileImportService.PriceFileWrapper> getAPFPartJson(List<BRPPartsWrapper.ItemWrapper> itemsList, 
																							Map<String, String> pfCategoryNameToIdMap, Price_File_Mapping__c pfMappingRec) {
		List<AutomatedPriceFileImportService.PriceFileWrapper> priceFileRecordList = new List<AutomatedPriceFileImportService.PriceFileWrapper>();

		Map<String, Escalator__c> fieldNameToEscalatorRecMap = new Map<String, Escalator__c>();
		if(pfMappingRec != null) {
			for(Escalator__c escalatorRec: pfMappingRec.Escalators__r) {
				fieldNameToEscalatorRecMap.put(escalatorRec.Type__c, escalatorRec);
			}
		}

		for(BRPPartsWrapper.ItemWrapper partObj: itemsList) {
			system.debug('partObj - ' + partObj);
		
			AutomatedPriceFileImportService.PriceFileWrapper pfObj = new AutomatedPriceFileImportService.PriceFileWrapper();
			pfObj.PartNumber = partObj.product_code;
			pfObj.Description = partObj.product_descr;
			
			for(BRPPartsWrapper.PricingWrapper pricingObj: partObj.pricings) {
				if(String.isNotBlank(pricingObj.price_type)) {
					pricingObj.price_price_uom = pricingObj.price_price_uom != null ? pricingObj.price_price_uom : 0; // price for 1 item
					pricingObj.price_sales_uom = pricingObj.price_sales_uom != null ? pricingObj.price_sales_uom : 0; // price for the product
					Decimal price, cost;
					if(pricingObj.price_type.containsIgnoreCase('dealer')) {
						cost =  pricingObj.price_price_uom;
					} else if(pricingObj.price_type.containsIgnoreCase('retail')) {
						price = pricingObj.price_price_uom;
					}

					pfObj.PackageUnit = partObj.sales_uom;
					if(String.isNotBlank(partObj.sales_uom) && 
						(partObj.sales_uom.equalsIgnoreCase('PAC') || partObj.sales_uom.equalsIgnoreCase('CS')) 
						&& pricingObj.price_type.containsIgnoreCase('dealer')) {
						if(pricingObj.price_price_uom != 0) {
							pfObj.PackageQty = (pricingObj.price_sales_uom/pricingObj.price_price_uom).setScale(2, RoundingMode.HALF_UP).toString();
						} else {
							pfObj.PackageQty = pricingObj.in_package.quantity.toString();
						}
					}
					
					if(price != null && (pfMappingRec == null ||  
							pfMappingRec.Retail_Based_On_Value__c == null || pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('price'))) {
						pfObj.Retail = BRPPartsMasterService.applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
					} else if(cost != null && pfMappingRec != null && pfMappingRec.Retail_Based_On_Value__c != null && pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('cost')) {
						pfObj.Retail = BRPPartsMasterService.applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
					}
					
					if(price != null && (pfMappingRec == null ||  
							pfMappingRec.MSRP_Based_On_Value__c == null || pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('price'))) {
						pfObj.MSRP = BRPPartsMasterService.applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
					} else if(cost != null && pfMappingRec != null && pfMappingRec.MSRP_Based_On_Value__c != null && pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('cost')) {
						pfObj.MSRP = BRPPartsMasterService.applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
					}
					
					if(cost != null && (pfMappingRec == null ||  
							pfMappingRec.Cost_Based_On_Value__c == null || pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('cost'))) {
						pfObj.ItemCost = BRPPartsMasterService.applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
					} else if(price != null && pfMappingRec != null && pfMappingRec.Cost_Based_On_Value__c != null && pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('price')) {
						pfObj.ItemCost = BRPPartsMasterService.applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
					}
				}
			}
			
			if(partObj.supersessions != null) {
				for(BRPPartsWrapper.SupersessionWrapper supersedingObj: partObj.supersessions) {
					if(String.isNotBlank(supersedingObj.superseded_product) 
								&& pfObj.PartNumber == supersedingObj.superseded_product 
								&& supersedingObj.superseding_product != null && String.isNotBlank(supersedingObj.superseding_product)) {
						pfObj.ReplacedByPart = supersedingObj.superseding_product;
					}
				}
			}
			Set<String> tagsSet = new Set<String>();
			if(partObj.product_lines != null && !partObj.product_lines.isEmpty()) {
				tagsSet.addAll(partObj.product_lines);
			}
			if(String.isNotBlank(partObj.sales_status_code) && salesStatusCodeToTagValueMap.containsKey(partObj.sales_status_code)) {
				tagsSet.add(salesStatusCodeToTagValueMap.get(partObj.sales_status_code));
			}

			if(!tagsSet.isEmpty()) {
				pfObj.AssignedTags = tagsSet;
			}

			if(String.isNotBlank(partObj.product_type) && pfCategoryNameToIdMap != null && !pfCategoryNameToIdMap.isEmpty() && 
							pfCategoryNameToIdMap.containsKey(productTypeCodeToNameMap.get(partObj.product_type).trim().toLowerCase())) {
				pfObj.CategoryId = pfCategoryNameToIdMap.get(productTypeCodeToNameMap.get(partObj.product_type).trim().toLowerCase());
			}
			
			priceFileRecordList.add(pfObj);
		}
		return priceFileRecordList;
	}

	private static String getNextPageNumber(String pageUrl) {
		if(String.isBlank(pageUrl)) return null;
		return pageUrl.substringAfter('page=').substringBefore('&');
	}

	private static Map<String, String> productTypeCodeToNameMap = new Map<String, String> {
		'10' => 'Vehicle',
		'20' => 'Engine',
		'30' => 'Parts',
		'40' => 'Accessories',
		'50' => 'Clothing',
		'60' => 'Licensing & Play',
		'90' => 'Trailer',
		'100' => 'Rebuilt',
		'110' => 'Oil & Chemicals',
		'NA' => ''
	};

	private static Map<String, String> salesStatusCodeToTagValueMap = new Map<String, String>{
																								'7' => 'vintage',
																								'E' => 'phase out',
																								'H' => 'obsolete'
																							};

	private static map<String, String> currencyToSalesOrgMap = new Map <String, String>{ 
																						'CAD' => '1010',
																						'USD' => '3020'
																					};
}
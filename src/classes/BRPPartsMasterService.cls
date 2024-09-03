/** 
* Author: Richa Mittal
* Since: Apr 02, 2021 
* Name: BRPPartsMasterService 
* Description: service class to create request body for get Parts Master API
**/
public without sharing class BRPPartsMasterService {
	
	public static String methodType = 'GetPartsMaster';

	public static HttpResponse getParts(String recordSetReferenceId) {
		String requestBody = createRequestBody(recordSetReferenceId);
		return BRPUtility.syncToBRP('GetPartsMaster', requestBody);
	}
	
	public static String createRequestBody(String recordSetReferenceId) {
		BRPUtility.release = '5.13.4';
		return createXMLPayload(recordSetReferenceId);
	}
	
	private static String createXMLPayload(String recordSetReferenceId) {
    	DOM.Document doc = new DOM.Document();
    	dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, methodType);
    	createGetPartsMasterDataAreaNode(root, recordSetReferenceId);
        return doc.toXmlString();
    }
    
    private static void createGetPartsMasterDataAreaNode(dom.XmlNode root, String recordSetReferenceId) {
    	dom.XmlNode partsMasterDataArea = BRPUtility.addChildElement(root, 'GetPartsMasterDataArea');
    	dom.XmlNode getNode;
    	getNode = BRPUtility.addAttributeElementWithoutValue(partsMasterDataArea, 'Get', 'recordSetReferenceId', recordSetReferenceId);
		
		String partMasterEffectiveDateStr = BRPUtility.partMasterEffectiveDate != null ? BRPUtility.partMasterEffectiveDate.format('yyyy-MM-dd') : '1900-01-01';
		String countryCode = BRPUtility.currencyCodeToCountryCodeMap.containsKey(BRPUtility.CurrencyCode) ? BRPUtility.currencyCodeToCountryCodeMap.get(BRPUtility.CurrencyCode) : 'CA';

		BRPUtility.addChildElementWithPrefix(getNode, 'Expression', BRPUtility.nameSpace, 'oagis', 'expressionLanguage', 'EffectiveDate', partMasterEffectiveDateStr);
		BRPUtility.addChildElementWithPrefix(getNode, 'Expression', BRPUtility.nameSpace, 'oagis', 'expressionLanguage', 'CountryCode', countryCode);
		BRPUtility.addChildElementWithPrefix(getNode, 'Expression', BRPUtility.nameSpace, 'oagis', 'expressionLanguage', 'ItemID', '');

        dom.XmlNode partsMasterNode = BRPUtility.addChildElement(partsMasterDataArea, 'PartMaster');
        createPartsMasterHeaderNode(partsMasterNode);
    }
    
    private static void createPartsMasterHeaderNode(dom.XmlNode partsMasterNode) {
    	dom.XmlNode partsMasterHeaderNode = BRPUtility.addChildElement(partsMasterNode, 'PartMasterHeader');
    	dom.XmlNode documentIdentificationGroupNode = BRPUtility.addChildElement(partsMasterHeaderNode, 'DocumentIdentificationGroup');
        dom.XmlNode documentIdentificationNode = BRPUtility.addChildElement(documentIdentificationGroupNode, 'DocumentIdentification');
        
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'DocumentID', MethodType);
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'AgencyRoleCode', 'Manufacturer');
        
        dom.XmlNode partsMasterLineNode = BRPUtility.addChildElement(partsMasterNode, 'PartMasterLine');
        BRPUtility.addChildElementWithValue(partsMasterLineNode, 'PartsProductItem', null);
    }
    
    public static String getRecordSetReferenceId(HttpResponse res) {
    	XmlStreamReader reader = res.getXmlStreamReader();
    	while(reader.hasNext()) {
		    if (reader.getEventType() == XmlTag.START_ELEMENT && 
		       reader.getLocalName() == 'Show') {
		        return reader.getAttributeValue('', 'recordSetReferenceId');
		    }
		    reader.next();
		}
    	return '';
    }
    
    //Import Parts
    public static void importParts(List<BRPShowPartsMasterWrapper.PartMasterLine> partMasterLines, Map<String, String> pfCategoryNameToIdMap, 
    			Price_File_Mapping__c pfMappingRec, AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj, 
    			AutomatedPriceFileImportService.ResultWrapper importResults) {
		if(partMasterLines != null && partMasterLines.size() > 0) {
			try {
	    		List<AutomatedPriceFileImportService.PriceFileWrapper> priceFileRecordList = getAPFPartJson(partMasterLines, pfCategoryNameToIdMap, pfMappingRec);
	    		if(priceFileRecordList.size() > 0) {
					AutomatedPriceFileImportService.ResultWrapper results = AutomatedPriceFileImportService.importFile(fieldMappingObj, priceFileRecordList);
					importResults.NewParts += results.newParts != null ? results.newParts : 0;
		            importResults.UpdatedParts += results.updatedParts != null ? results.updatedParts : 0;
					importResults.FailedParts += results.failedParts != null ? results.failedParts : 0;
	    		}
			} catch(Exception e) {
				importResults.FailedParts += partMasterLines.size();
				BRPLogService obj = new BRPLogService('GetPartsMaster', null, null, null, null, e.getMessage() + ' - ' + e.getStackTraceString(), 'Error', 'BRPPartsMasterService', 'importParts');
				obj.createLog();
				system.debug('Error in creating APF json or importing process ' + e.getMessage());
			}
		}
    }
    
    private static List<AutomatedPriceFileImportService.PriceFileWrapper> getAPFPartJson(List<BRPShowPartsMasterWrapper.PartMasterLine> partMasterLines, 
    														Map<String, String> pfCategoryNameToIdMap, Price_File_Mapping__c pfMappingRec) {
    															
        List<AutomatedPriceFileImportService.PriceFileWrapper> priceFileRecordList = new List<AutomatedPriceFileImportService.PriceFileWrapper>();
		system.debug('Price file mapping rec - ' + pfMappingRec);
		system.debug('Total part master lines - ' + partMasterLines.size());
		
		Map<String, Escalator__c> fieldNameToEscalatorRecMap = new Map<String, Escalator__c>();
		if(pfMappingRec != null) {
			for(Escalator__c escalatorRec: pfMappingRec.Escalators__r) {
				fieldNameToEscalatorRecMap.put(escalatorRec.Type__c, escalatorRec);
			}
		}

		for(BRPShowPartsMasterWrapper.PartMasterLine partMasterObj : partMasterLines) {
			system.debug('partMasterObj - ' + partMasterObj);
		
			AutomatedPriceFileImportService.PriceFileWrapper pfObj = new AutomatedPriceFileImportService.PriceFileWrapper();
			pfObj.PartNumber = partMasterObj.PartsProductItem.ItemIdentificationGroup.ItemIdentification[0].ItemID;
	    	pfObj.Description = partMasterObj.PartsProductItem.PartItemDescription;
			// New logic for packaged qty - Ticket #15935
			if(partMasterObj.PartsProductItem.MinimumBuyQuantity > partMasterObj.PartsProductItem.PackageQuantity && partMasterObj.PartsProductItem.UnitCodeForPackageQty == 'pac'){
				pfObj.PackageQty = partMasterObj.PartsProductItem.MinimumBuyQuantity;
			} else {
				pfObj.PackageQty = partMasterObj.PartsProductItem.PackageQuantity;
			}
			pfObj.PackageUnit = partMasterObj.PartsProductItem.UnitCodeForPackageQty;
			
	    	
			for(BRPShowPartsMasterWrapper.PartMasterPricing pricingObj: partMasterObj.PartMasterPricing) {
	    		if(String.isNotBlank(pricingObj.PartMasterPriceTypeString)) {
	    			Decimal price, cost;
	    			if(pricingObj.UnitPriceAmount != null) {
	    				if(pricingObj.PartMasterPriceTypeString.containsIgnoreCase('Dealer Invoice')) {
		    				cost =  pricingObj.UnitPriceAmount != null ? Decimal.valueOf(pricingObj.UnitPriceAmount) : 0;
		    			} else if(pricingObj.PartMasterPriceTypeString.containsIgnoreCase(EscalatorUtil.TYPE_MSRP)) {
	    					price = pricingObj.UnitPriceAmount != null ? Decimal.valueOf(pricingObj.UnitPriceAmount) : 0;
		    			}
	    			}
	    			
	    			if(price != null && (pfMappingRec == null ||  
	    					pfMappingRec.Retail_Based_On_Value__c == null || pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('price'))) {
	    				pfObj.Retail = applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
	    			} else if(cost != null && pfMappingRec != null && pfMappingRec.Retail_Based_On_Value__c != null && pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('cost')) {
	    				pfObj.Retail = applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
	    			}
	    			
	    			if(price != null && (pfMappingRec == null ||  
	    					pfMappingRec.MSRP_Based_On_Value__c == null || pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('price'))) {
	    				pfObj.MSRP = applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
	    			} else if(cost != null && pfMappingRec != null && pfMappingRec.MSRP_Based_On_Value__c != null && pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('cost')) {
	    				pfObj.MSRP = applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
	    			}
	    			
	    			if(cost != null && (pfMappingRec == null ||  
	    					pfMappingRec.Cost_Based_On_Value__c == null || pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('cost'))) {
	    				pfObj.ItemCost = applyMarkup(cost, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
	    			} else if(price != null && pfMappingRec != null && pfMappingRec.Cost_Based_On_Value__c != null && pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('price')) {
	    				pfObj.ItemCost = applyMarkup(price, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
	    			}
	    		}
	    	}
	    	
			if(partMasterObj.SupersedingPartGroup != null) {
                for(BRPShowPartsMasterWrapper.SupersedingPartGroup supersedingObj: partMasterObj.SupersedingPartGroup) {
                    if(supersedingObj.SupersededPartDetail != null && String.isNotBlank(supersedingObj.SupersededPartDetail.SupersedingPartNumberID) 
								&& pfObj.PartNumber == supersedingObj.SupersededPartDetail.SupersedingPartNumberID 
								&& supersedingObj.SupersedingPartDetail != null && String.isNotBlank(supersedingObj.SupersedingPartDetail.SupersedingPartNumberID)) {
                        pfObj.ReplacedByPart = supersedingObj.SupersedingPartDetail.SupersedingPartNumberID;
                    }
                }
            }
	    	if(partMasterObj.ProductLineCode != null && partMasterObj.ProductLineCode.size() > 0) {
	    		pfObj.AssignedTags = new Set<String>(partMasterObj.ProductLineCode);
	    	}
	    	if(String.isNotBlank(partMasterObj.PartCategoryCode) && pfCategoryNameToIdMap != null && pfCategoryNameToIdMap.size() > 0 && 
	    					pfCategoryNameToIdMap.containsKey(partMasterObj.PartCategoryCode.trim().toLowerCase())) {
	    		pfObj.CategoryId = pfCategoryNameToIdMap.get(partMasterObj.PartCategoryCode.trim().toLowerCase());
	    	}
	    	
	    	priceFileRecordList.add(pfObj);
		}
		
		return priceFileRecordList;
    }
    
    public static String applyMarkup(Decimal amount, Price_File_Mapping__c pfMappingRec, String fieldName, Escalator__c escalatorRec) {
    	if(amount != null && amount != 0 && pfMappingRec != null && String.isNotBlank(fieldName) && escalatorRec != null) {
			Decimal markupPercent = EscalatorService.getMarkupValue(amount, escalatorRec);
			amount = amount * (1 + markupPercent/100);
			
			if(fieldName.equalsIgnoreCase(EscalatorUtil.TYPE_MSRP) && pfMappingRec.Is_MSRP_Rounded__c != null && pfMappingRec.Is_MSRP_Rounded__c && pfMappingRec.MSRP_Round_To__c != null) {
				amount = calculateRoundedValue(pfMappingRec.MSRP_Round_To__c, amount);
			} else if(fieldName.equalsIgnoreCase(EscalatorUtil.TYPE_RETAIL) && pfMappingRec.Is_Retail_Rounded__c != null && pfMappingRec.Is_Retail_Rounded__c && pfMappingRec.Retail_Round_To__c != null) {
				amount = calculateRoundedValue(pfMappingRec.Retail_Round_To__c, amount);
			}
    	}
    	return String.valueOf(amount);
    }
    
    public static Decimal calculateRoundedValue(Decimal roundingValue, Decimal calculatedValue) {
        if(calculatedValue != null && calculatedValue != 0 && roundingValue != null) {
        	roundingValue = roundingValue/100;
        	Integer beforeDecimal = Integer.valueOf(calculatedValue);
    		if((calculatedValue - beforeDecimal) > roundingValue) {
    			calculatedValue = beforeDecimal + 1 + roundingValue;
    		} else {
    			calculatedValue = beforeDecimal + roundingValue;
    		}
        } 
        return calculatedValue;         
    }

	public static String handleSuccessResponse(String pageNumber, HttpResponse response, Map<String, String> pfCategoryNameToIdMap, Price_File_Mapping__c pfMappingRec, 
											AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj, 
											AutomatedPriceFileImportService.ResultWrapper importResults) {
		String nextPageNumber;
		if(response.getBody().containsIgnoreCase('ShowPartsMaster')) {
			nextPageNumber = getRecordSetReferenceId(response);
			try {
				Set<String> multipleKeysSet = new Set<String>{'PartMasterLine', 'SupersedingPartGroup', 'ProductLineCode', 'PartMasterPricing', 'ItemIdentification'};
		
				BRPResponseWrapper responseObj = BRPUtility.parseXMLResponse(response.getBody(), multipleKeysSet);
				if(responseObj != null && responseObj.ShowPartsMaster != null && responseObj.ShowPartsMaster.ShowPartsMasterDataArea != null && 
							responseObj.ShowPartsMaster.ShowPartsMasterDataArea.PartMaster != null) {	
					importParts(responseObj.ShowPartsMaster.ShowPartsMasterDataArea.PartMaster.PartMasterLine, 
							pfCategoryNameToIdMap, pfMappingRec, fieldMappingObj, importResults);
				}
				System.debug('responseObj...'+ System.JSON.serialize(responseObj));
				System.debug('response.getBody()...'+response.getBody());
				
				BRPLogService obj = new BRPLogService('GetPartsMaster', 'pageNumber - ' + pageNumber, null, null, null, response.getBody(), 'Info', 'BRPPartsMasterBatch', 'execute');
				obj.createLog();
			} catch(Exception e) {
					BRPLogService obj = new BRPLogService('GetPartsMaster', 'pageNumber - ' + pageNumber, null, null, null, 
							e.getMessage() + ' - ' + response.getBody(), 'Error', 'BRPPartsMasterBatch', 'execute');
					obj.createLog();
			}
		} else if(response.getBody().containsIgnoreCase('ConfirmBOD') && 
			response.getBody().containsIgnoreCase('No changes to Parts Master catalog since previous update request')) {
			BRPLogService obj = new BRPLogService('GetPartsMaster', 'pageNumber - ' + pageNumber, null, null, String.valueOf(response.getStatusCode()), response.getBody(), 'Info', 'BRPPartsMasterBatch', 'execute');
			obj.createLog();
		} else {
			handleAPIError(BRPPartsMasterBatch.ErrorMsg, 'pageNumber - ' + pageNumber, response);
		}
		return nextPageNumber;
	}

	public static String handleAPIError(String recordSetRefId, String requestBody, HttpResponse response) {
		BRP_log__c brpLogRec = BRPUtility.handleResponse('GetPartsMaster', requestBody, response);
        brpLogRec.Apex_Class__c = 'BRPPartsMasterBatch';
        System.debug('brpLogRec..'+brpLogRec);
		DMLUtility.insertSobjectList('BRP_log__c', brpLogRec);
		return recordSetRefId;
	}
}
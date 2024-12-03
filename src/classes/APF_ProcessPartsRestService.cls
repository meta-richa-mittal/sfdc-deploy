@RestResource(urlMapping = '/apf/processParts/*')
global without sharing class APF_ProcessPartsRestService {

    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest req = RestContext.request;
        RequestWrapper requestObj = (RequestWrapper)JSON.deserialize(req.requestBody.toString(), RequestWrapper.class);
        ResponseWrapper response = processParts(requestObj);
        return response;
    }

    private static ResponseWrapper processParts(RequestWrapper requestObj) {
        AutomatedPriceFileImportService.ResultWrapper importResults = new AutomatedPriceFileImportService.ResultWrapper(0, 0, 0, new Set<Id>());
        if(requestObj != null && String.isNotBlank(requestObj.vendorMasterId) && requestObj.parts != null && !requestObj.parts.isEmpty()) {
            system.debug('Total Parts in request :: ' + requestObj.parts.size());
            List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), new Map<String, Object>{'Id' => requestObj.vendorMasterId});
            if(!vendorMasterList.isEmpty()) {
                List<Price_File_Mapping__c> priceFileMappingList = AutomatedPriceFileSOQLUtil.getPriceFileMappingList(new List<String>(), 
                    new Map<String, Object>{'Vendor_Master__c' => requestObj.vendorMasterId});
                Price_File_Mapping__c pfMappingRec = !priceFileMappingList.isEmpty() ? priceFileMappingList[0] : null;
                
                AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj = setFieldMappingObj(vendorMasterList[0], pfMappingRec);

                try {
                    AutomatedPriceFileImportService.summaryLogId = requestObj.requestId;
                    List<AutomatedPriceFileImportService.PriceFileWrapper> priceFileRecordList = setAPFPartListWapper(vendorMasterList[0], pfMappingRec, requestObj);
                    system.debug('Total Parts in importFile method :: ' + priceFileRecordList.size());
                    if(!priceFileRecordList.isEmpty()) {
                        importResults = AutomatedPriceFileImportService.importFile(fieldMappingObj, priceFileRecordList);
                    }
                } catch(Exception e) {
                    importResults.failedParts = requestObj.parts.size();
                    BRPLogService obj = new BRPLogService('APF Process Parts', null, null, null, null, e.getMessage() + ' - ' + e.getStackTraceString(), 'Error', 'APF_ProcessPartsRestService', 'processParts');
                    obj.createLog();
                    system.debug('Error in creating APF json or importing process ' + e.getMessage());
                }
                updateSummaryRecord(requestObj, importResults);
            }
        }
        return new ResponseWrapper(importResults);
    }

    private static void updateSummaryRecord(RequestWrapper requestObj, AutomatedPriceFileImportService.ResultWrapper importResults) {
        if(String.isNotBlank(requestObj.requestId)) {

            for(Summary_Log__c logRec : [Select Id, Total_Records__c, Inserted_Record_Count__c, Updated_Record_Count__c, Failed_Record_Count__c From Summary_Log__c Where Id = :requestObj.requestId]) {
                if(requestObj.totalPartsInFile != null) logRec.Total_Records__c = requestObj.totalPartsInFile;
                if(importResults.NewParts != null) {
                    logRec.Inserted_Record_Count__c = logRec.Inserted_Record_Count__c != null ? logRec.Inserted_Record_Count__c : 0;
                    logRec.Inserted_Record_Count__c += importResults.NewParts;
                }
                if(importResults.UpdatedParts != null) {
                    logRec.Updated_Record_Count__c = logRec.Updated_Record_Count__c != null ? logRec.Updated_Record_Count__c : 0;
                    logRec.Updated_Record_Count__c += importResults.FailedParts;
                }
                if(importResults.FailedParts != null) {
                    logRec.Failed_Record_Count__c = logRec.Failed_Record_Count__c != null ? logRec.Failed_Record_Count__c : 0;
                    logRec.Failed_Record_Count__c += importResults.FailedParts;
                }
                update logRec;
            }
        }
    }

    private static AutomatedPriceFileImportService.FieldMappingWrapper setFieldMappingObj(Vendor_Master__c vendorMasterRec, Price_File_Mapping__c priceFileMappingRec) {
        AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj = new AutomatedPriceFileImportService.FieldMappingWrapper();
        fieldMappingObj = new AutomatedPriceFileImportService.FieldMappingWrapper();
        fieldMappingObj.IsMfgNumberMapped = vendorMasterRec.Mfg_Num__c;
        fieldMappingObj.IsSKUNumberMapped = vendorMasterRec.SKU_Num__c;
        fieldMappingObj.IsReplacedByMapped = vendorMasterRec.Replaced_By__c;
        fieldMappingObj.IsReplacesMapped = vendorMasterRec.Replaces__c;
        fieldMappingObj.IsPackageQtyMapped = vendorMasterRec.Pkg_Qty__c;
        fieldMappingObj.VendorId = vendorMasterRec.Blackpurl_Vendor__c;

        if(priceFileMappingRec != null) {
            //this.pfMappingRec = priceFileMappingRec;
            fieldMappingObj.PriceFileFieldMappingId = priceFileMappingRec.Id;
            fieldMappingObj.OverridePartPkgSetting = priceFileMappingRec.Is_Packaged_Part__c;
            fieldMappingObj.IsForcedCategory = priceFileMappingRec.Is_Forced_Category__c;
            
        } else if(fieldMappingObj.IsPackageQtyMapped) {
            fieldMappingObj.OverridePartPkgSetting = true;
        }
        return fieldMappingObj;
    }

    private static Map<String, String> createCategoryMap(Price_File_Mapping__c pfMappingRec) {
        Map<String, String> pfCategoryNameToIdMap = new Map<String, String>();
    	if(pfMappingRec != null && String.isNotBlank(pfMappingRec.Category__c)) {
    		List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper> categoryMappingList = String.isBlank(pfMappingRec.Category__c) ? 
    						new List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>() : 
    						(List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>) System.JSON.deserialize(pfMappingRec.Category__c, 
    							List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>.class);
    		
    		for(AutomatedPriceFileMappingWrapper.CategoryMappingWrapper catObj : categoryMappingList) {
    			if(String.isNotBlank(catObj.Key)) pfCategoryNameToIdMap.put(catObj.Key.toLowerCase().trim(), catObj.Value);
    		}
        }
        return pfCategoryNameToIdMap;
    }

    private static List<AutomatedPriceFileImportService.PriceFileWrapper> setAPFPartListWapper(Vendor_Master__c vendorMasterRec, Price_File_Mapping__c pfMappingRec, RequestWrapper requestObj) {
        List<AutomatedPriceFileImportService.PriceFileWrapper> priceFilePartList = new List<AutomatedPriceFileImportService.PriceFileWrapper>();
        
        Map<String, Escalator__c> fieldNameToEscalatorRecMap = new Map<String, Escalator__c>();
        String descriptionLang = 'English';
		if(pfMappingRec != null) {
			for(Escalator__c escalatorRec: pfMappingRec.Escalators__r) {
				fieldNameToEscalatorRecMap.put(escalatorRec.Type__c, escalatorRec);
			}
            if(String.isNotBlank(pfMappingRec.Description__c)) {
                descriptionLang = pfMappingRec.Description__c;
            } else if(vendorMasterRec != null && vendorMasterRec.Description_FR__c) {
                descriptionLang = 'French';
            }
		}
        Map<String, String> pfCategoryNameToIdMap = createCategoryMap(pfMappingRec);

        for(PartWrapper partObj : requestObj.parts) {
            AutomatedPriceFileImportService.PriceFileWrapper pfObj = new AutomatedPriceFileImportService.PriceFileWrapper();
            pfObj.PartNumber = partObj.partNumber;
            pfObj.Description = descriptionLang.equalsIgnoreCase('French') ? partObj.descriptionFR : partObj.descriptionEN;
            pfObj.MfgNumber = partObj.mfgNumber;
            pfObj.SKUNumber = partObj.skuNumber;
            pfObj.ReplacedByPart = partObj.replacedByPart;
            pfObj.ReplacesPart = partObj.replacesPart;
            pfObj.PackageQty = partObj.pkgQty != null ? String.valueOf(partObj.pkgQty) : null;

            if(vendorMasterRec.Blackpurl_Vendor__c != null && vendorMasterRec.Blackpurl_Vendor__r.Is_Foreign_Vendor__c && vendorMasterRec.Blackpurl_Vendor__r.Country__c != null) {
                partObj.cost = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(partObj.cost, vendorMasterRec.Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
                partObj.otherCost = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(partObj.otherCost, vendorMasterRec.Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
                partObj.price = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(partObj.price, vendorMasterRec.Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
                partObj.otherPrice = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(partObj.otherPrice, vendorMasterRec.Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
            }
            if(partObj.Price != null && (pfMappingRec == null ||  
                    pfMappingRec.Retail_Based_On_Value__c == null || pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('price'))) {
                pfObj.Retail = BRPPartsMasterService.applyMarkup(partObj.Price, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
            } else if(partObj.Cost != null && pfMappingRec != null && pfMappingRec.Retail_Based_On_Value__c != null && pfMappingRec.Retail_Based_On_Value__c.containsIgnoreCase('cost')) {
                pfObj.Retail = BRPPartsMasterService.applyMarkup(partObj.Cost, pfMappingRec, EscalatorUtil.TYPE_RETAIL, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_RETAIL));
            }

            if(partObj.Price != null && (pfMappingRec == null ||  
                    pfMappingRec.MSRP_Based_On_Value__c == null || pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('price'))) {
                pfObj.MSRP = BRPPartsMasterService.applyMarkup(partObj.Price, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
            } else if(partObj.Cost != null && pfMappingRec != null && pfMappingRec.MSRP_Based_On_Value__c != null && pfMappingRec.MSRP_Based_On_Value__c.containsIgnoreCase('cost')) {
                pfObj.MSRP = BRPPartsMasterService.applyMarkup(partObj.Cost, pfMappingRec, EscalatorUtil.TYPE_MSRP, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_MSRP));
            }
            
            if(partObj.Cost != null && (pfMappingRec == null ||  
                    pfMappingRec.Cost_Based_On_Value__c == null || pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('cost'))) {
                pfObj.ItemCost = BRPPartsMasterService.applyMarkup(partObj.Cost, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
            } else if(partObj.Price != null && pfMappingRec != null && pfMappingRec.Cost_Based_On_Value__c != null && pfMappingRec.Cost_Based_On_Value__c.containsIgnoreCase('price')) {
                pfObj.ItemCost = BRPPartsMasterService.applyMarkup(partObj.Price, pfMappingRec, EscalatorUtil.TYPE_COST, fieldNameToEscalatorRecMap.get(EscalatorUtil.TYPE_COST));
            }

            String partCat = partObj.category.toLowerCase().trim();
            if(String.isNotBlank(partObj.category) && pfCategoryNameToIdMap != null && pfCategoryNameToIdMap.get(partCat) != null) {
				pfObj.CategoryId = pfCategoryNameToIdMap.get(partCat);
			}
            priceFilePartList.add(pfObj);
        }
        return priceFilePartList;
    }
    
    global class RequestWrapper {
        public String vendorMasterId;
        public String requestId;
        public Integer totalPartsInFile;
       	public List<PartWrapper> parts; 
	}

    global class PartWrapper {
        public String partNumber;
        public String descriptionEN;
        public String descriptionFR;
        public String mfgNumber;
        public String skuNumber;
        public String replacedByPart;
        public String replacesPart;
        public Decimal price;
        public Decimal cost;
        public Decimal otherPrice;
        public Decimal otherCost;
        public Decimal pkgQty;
        public String category;
	}

    global class ResponseWrapper {
        public Integer createdParts;
        public Integer updatedParts;
        public Integer failedParts;

        public ResponseWrapper(AutomatedPriceFileImportService.ResultWrapper importResults) {
            this.createdParts = importResults.NewParts;
            this.updatedParts = importResults.UpdatedParts;
            this.failedParts = importResults.FailedParts;
        }
	}
}
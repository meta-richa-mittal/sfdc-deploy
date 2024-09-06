/**
 * Author: Richa Mittal
 * Since: April 02, 2020
 * Name: AutomatedPriceFileService
 * Description: AutomatedPriceFileService class.
**/
public without sharing class AutomatedPriceFileService {
	public static List<Log__c> logListToInsert = new List<Log__c>();
    
    public static Boolean isUpdateAvailableForPriceFiles() {
    	List<String> fieldsList = new List<String>{'Id'};
    	Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Is_Update_Available__c' => true};
    	return AutomatedPriceFileSOQLUtil.getVendorMasterList(fieldsList, fieldNameToFieldValueMap).size() > 0;
	}
	
	public static List<VendorMasterWrapper> getVendorMasterList() {
    	List<String> fieldList = new List<String>{'Id',
                                                'Vendor_Name__c',
                                                'Is_Update_Available__c',
                                                'Last_Imported_Date__c',
                                                'Blackpurl_Vendor__r.Vendor_Number__c',
                                                'Blackpurl_Vendor__r.Name',
												'Vendor_Master_Type__c'};
                                                
        List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(fieldList, new Map<String, Object>());
        List<VendorMasterWrapper> VendorMasterWrapperList = new List<VendorMasterWrapper>();
        for(Vendor_Master__c vendorMasterRec : vendorMasterList) {
            VendorMasterWrapperList.add(new VendorMasterWrapper(vendorMasterRec, 'Automated Price Files Screen'));
		}
		return VendorMasterWrapperList;
	}

	public static String skipUpdateForVendorMaster(String vendorMasterId) {
		String successFlag = 'Update Failed';
    	List<String> fieldList = new List<String>{'Id',
                                                'Vendor_Name__c',
                                                'Is_Update_Available__c'
                                               	};
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Id' => vendorMasterId};
		List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
		for(Vendor_Master__c vendorMasterRec : vendorMasterList) {
			vendorMasterRec.Is_Update_Available__c = false;
		}
		if(vendorMasterList.size() > 0) {
			if(AccessControl.ifObjectIsUpdateable('Vendor_Master__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
			Database.SaveResult[] Result = database.update(vendorMasterList,false);
			for(Database.SaveResult res : Result){
				successFlag = (res.isSuccess()) ? 'Update Successful' : 'Update Failed';
		   }
		}
		return successFlag;
	}
	
	public static List<VendorMasterWrapper> getVendorMasterDetailsById(String vendorMasterId) {
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Id' => vendorMasterId};
        List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
        List<VendorMasterWrapper> VendorMasterWrapperList = new List<VendorMasterWrapper>();
        for(Vendor_Master__c vendorMasterRec : vendorMasterList) {
            VendorMasterWrapperList.add(new VendorMasterWrapper(vendorMasterRec, null));
        }
		return VendorMasterWrapperList;
	}

	private static void setLastImportedDateById(String vendorMasterId, String priceFileLocation) {
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Id' => vendorMasterId};
        List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
        for(Vendor_Master__c vendorMasterRec : vendorMasterList) {
			vendorMasterRec.Price_File_Location_URL__c = priceFileLocation;
        }
		if(vendorMasterList.size() > 0) {
			update vendorMasterList;
		}
	}
	
	public static List<AutomatedPriceFileMappingWrapper> getPriceFileMappingByVendorMasterId(String vendorMasterId) {
		
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Vendor_Master__c' => vendorMasterId};
        List<Price_File_Mapping__c> priceFileMappingList = AutomatedPriceFileSOQLUtil.getPriceFileMappingList(new List<String>(), fieldNameToFieldValueMap);
        List<AutomatedPriceFileMappingWrapper> automatedPriceFileMappingWrapperList = new List<AutomatedPriceFileMappingWrapper>();
        if(priceFileMappingList.size() > 0) {
            for(Price_File_Mapping__c priceFileMappingRec : priceFileMappingList) {
                automatedPriceFileMappingWrapperList.add(new AutomatedPriceFileMappingWrapper(priceFileMappingRec));
            }
        } else {
            automatedPriceFileMappingWrapperList.add(new AutomatedPriceFileMappingWrapper(vendorMasterId));
        }
		return automatedPriceFileMappingWrapperList;
	}
	
	public static String saveAutomatedPriceFileMapping(String recordJSON) {
		String successFlag;
		AutomatedPriceFileMappingWrapper apfmRec = (AutomatedPriceFileMappingWrapper) System.JSON.deserialize(recordJSON, AutomatedPriceFileMappingWrapper.class);
        apfmRec.IsMSRPRounded = (apfmRec.IsMSRPRounded == null) ? false : apfmRec.IsMSRPRounded;
        apfmRec.IsRetailRounded = (apfmRec.IsRetailRounded == null) ? false : apfmRec.IsRetailRounded;
        
        Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Vendor_Master__c' => apfmRec.VendorMasterId};
        List<Price_File_Mapping__c> priceFileMappingList = AutomatedPriceFileSOQLUtil.getPriceFileMappingList(new List<String>(), fieldNameToFieldValueMap);
		priceFileMappingList = setPriceFileMapping(priceFileMappingList, apfmRec);
        String priceFileMappingId;
        if(priceFileMappingList.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Price_File_Mapping__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsCreateable('Price_File_Mapping__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
			Database.UpsertResult [] cr  = Database.upsert(priceFileMappingList ,false);
			for(Database.UpsertResult Result : cr){
				successFlag = result.isSuccess() ? 'Success' : 'Failure'; 
		    }
		    priceFileMappingId = priceFileMappingList[0].Id;
		}
		return (successFlag == 'Success' ? '{"Id" : "' + priceFileMappingId + '"}' : System.JSON.serialize(successFlag));
	}

	public static List<CategoryService.CategoryWrapper> getPartCategories(String vendorMasterId) {
		List<CategoryService.CategoryWrapper> categoriesList = CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_PART});
		List<String> fieldList = new List<String>{'Id',
                                                'Blackpurl_Vendor__c'};
                                                
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Id' => vendorMasterId};
		List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
		String vendorDefaultCategoryId = AutomatedPriceFileImportService.getDefaultCategory(vendorMasterList[0].Blackpurl_Vendor__c);
		for(CategoryService.CategoryWrapper categoryWrapperRec : categoriesList) {
			if(categoryWrapperRec.Id == vendorDefaultCategoryId) {
				categoryWrapperRec.IsDefaultVendorCategory = true;
			}
		}
		return categoriesList;
	}

	private static List<Price_File_Mapping__c> setPriceFileMapping(List<Price_File_Mapping__c> priceFileMappingList, AutomatedPriceFileMappingWrapper apfmRec) {
		if(priceFileMappingList.size() <= 0) {
			Price_File_Mapping__c priceFileMappingRec = new Price_File_Mapping__c();
			priceFileMappingRec.Vendor_Master__c = apfmRec.VendorMasterId;
			priceFileMappingList.add(priceFileMappingRec);
		}
    	for(Price_File_Mapping__c priceFileMappingRec : priceFileMappingList) {
            priceFileMappingRec.Category__c = System.JSON.serialize(apfmRec.CategoryMappingList);
            priceFileMappingRec.Description__c = apfmRec.Description;
            priceFileMappingRec.Cost_Based_On_Value__c = apfmRec.CostBasedOnValue;
            priceFileMappingRec.Cost_Markup_Tier_1__c = apfmRec.CostMarkupTier1;
            priceFileMappingRec.Cost_Markup_Tier_2__c = apfmRec.CostMarkupTier2;
            priceFileMappingRec.Cost_Markup_Tier_3__c = apfmRec.CostMarkupTier3;
            priceFileMappingRec.Cost_Max_Markup_Amount_Tier_1__c = apfmRec.CostMaxMarkupAmountTier1;
            priceFileMappingRec.Cost_Max_Markup_Amount_Tier_2__c = apfmRec.CostMaxMarkupAmountTier2;
            priceFileMappingRec.Is_Packaged_Part__c = apfmRec.IsPackagedPart != null ? apfmRec.IsPackagedPart : true;	
			priceFileMappingRec.Is_Forced_Category__c = apfmRec.IsForcedCategory != null ? apfmRec.IsForcedCategory : false;		
            priceFileMappingRec.MSRP_Based_On_Value__c = apfmRec.MSRPBasedOnValue;
            priceFileMappingRec.MSRP_Markup_Tier_1__c = apfmRec.MSRPMarkupTier1;
            priceFileMappingRec.MSRP_Markup_Tier_2__c = apfmRec.MSRPMarkupTier2;
            priceFileMappingRec.MSRP_Markup_Tier_3__c = apfmRec.MSRPMarkupTier3;
            priceFileMappingRec.MSRP_Max_Markup_Amount_Tier_1__c = apfmRec.MSRPMaxMarkupAmountTier1;
            priceFileMappingRec.MSRP_Max_Markup_Amount_Tier_2__c = apfmRec.MSRPMaxMarkupAmountTier2;
            priceFileMappingRec.Is_MSRP_Rounded__c = apfmRec.IsMSRPRounded;
            priceFileMappingRec.MSRP_Round_To__c = apfmRec.MSRPRoundToValue;
            priceFileMappingRec.Retail_Based_On_Value__c = apfmRec.RetailBasedOnValue;
            priceFileMappingRec.Retail_Markup_Tier_1__c = apfmRec.RetailMarkupTier1;
            priceFileMappingRec.Retail_Markup_Tier_2__c = apfmRec.RetailMarkupTier2;
            priceFileMappingRec.Retail_Markup_Tier_3__c = apfmRec.RetailMarkupTier3;
            priceFileMappingRec.Retail_Max_Markup_Amount_Tier_1__c = apfmRec.RetailMaxMarkupAmountTier1;
            priceFileMappingRec.Retail_Max_Markup_Amount_Tier_2__c = apfmRec.RetailMaxMarkupAmountTier2;
            priceFileMappingRec.Is_Retail_Rounded__c = apfmRec.IsRetailRounded;
            priceFileMappingRec.Retail_Round_To__c = apfmRec.RetailRoundToValue;
		}
		return priceFileMappingList;
	}

	public static List<VendorMasterWrapper> getPriceFileLocationFromPartnerOrg(Set<String> vendorMasterNameSet, String vendorMasterId) {
		
		List<VendorMasterWrapper> vendorMasterObjList = new List<VendorMasterWrapper>();

        try {
            List<VendorMasterImportPriceFileService.SubscriberResponseWrapper> responseObjList = VendorMasterImportPriceFileService.sendPriceFileDetailsRequest(new List<String>(vendorMasterNameSet));
            vendorMasterObjList = VendorMasterImportPriceFileService.handleResponse(new List<String>(vendorMasterNameSet), responseObjList);
			if(vendorMasterObjList.size() > 0) {
				setLastImportedDateById(vendorMasterId, vendorMasterObjList[0].PriceFileLocation);
			}
		} catch(Exception e) {
            // insert log with strResponse exception
            logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'getPriceFileLocationFromPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(vendorMasterNameSet), LogService.AUTOMATED_PRICE_FILE, false));
        }
        
        if(logListToInsert.size() > 0) {
        	insert logListToInsert;
		}
		return vendorMasterObjList;
	}
	
	public static String updateVendorMasterSubscriberPartnerOrg(Set<String> vendorMasterNameSet, String vendorMasterId) {
		
		String successResponse = 'Failed';
        try {
            List<VendorMasterSubscriberUpdateService.SubscriberResponseWrapper> responseObjList = VendorMasterSubscriberUpdateService.sendVMSUpdateRequest(new List<String>(vendorMasterNameSet));
			if(responseObjList[0].Message == 'Success') {
				setImportSuccessfulFlagById(vendorMasterId);
				successResponse = 'Success';
			} else if(responseObjList[0].Message == 'error') {
                // insert log with error message
                logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'updateVendorMasterSubscriberPartnerOrg()', responseObjList[0].ResponseStr, LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(responseObjList), LogService.AUTOMATED_PRICE_FILE, false));
            }
		} catch(Exception e) {
            // insert log with strResponse exception
            logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'updateVendorMasterSubscriberPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(vendorMasterNameSet), LogService.AUTOMATED_PRICE_FILE, false));
        }
        
        if(logListToInsert.size() > 0) {
        	insert logListToInsert;
		}
		return successResponse;
	}
	
	private static void setImportSuccessfulFlagById(String vendorMasterId) {
		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Id' => vendorMasterId};
        List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
        for(Vendor_Master__c vendorMasterRec : vendorMasterList) {
			vendorMasterRec.Is_Import_Successful__c = true;
			vendorMasterRec.Last_Imported_Date__c = System.now();
			vendorMasterRec.Is_Update_Available__c = false;
        }
		if(vendorMasterList.size() > 0) {
			update vendorMasterList;
		}
	}
	
	public static void createFileReadErrorLog(String errorJson) {
        try {
        	FileReadErrorWrapper errorObj = (FileReadErrorWrapper)System.JSON.deserialize(errorJson, FileReadErrorWrapper.class);
            logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'createFileReadErrorLog()', errorObj.Message, errorObj.Status, errorObj.StatusText, 
                                                  errorObj.Code, LogService.AUTOMATED_PRICE_FILE, false));
		} catch(Exception e) {
            logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'createFileReadErrorLog()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(errorJson), LogService.AUTOMATED_PRICE_FILE, false));
        }
        
        if(logListToInsert.size() > 0) {
        	insert logListToInsert;
		}
	}
	
	public class FileReadErrorWrapper {
        public Integer Status;
        public String StatusText;
        public String Code;
        public String Message;
    }
}
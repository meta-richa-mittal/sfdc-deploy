global without sharing class AutomatedPriceFileImportService {
    
    public static Boolean isOverridePartPkgSetting;
    public static Boolean isForcedCategory;
    public static String vendorId;
    public static String priceFileFieldMappingId;
    public static Integer failedRecords = 0;
    
    public static ResultWrapper importFile(String mappingJSON, String records) {
        FieldMappingWrapper fieldMappingObj = (FieldMappingWrapper) System.JSON.deserialize(mappingJSON, FieldMappingWrapper.class);
        List<PriceFileWrapper> priceFileRecordList = (List<PriceFileWrapper>) System.JSON.deserialize(records, List<PriceFileWrapper>.class);
        return importFile(fieldMappingObj, priceFileRecordList);
    }
    
    public static ResultWrapper importFile(FieldMappingWrapper fieldMappingObj, List<PriceFileWrapper> priceFileRecordList) {
        vendorId = fieldMappingObj.VendorId;
        isOverridePartPkgSetting = (fieldMappingObj.OverridePartPkgSetting != null) ? fieldMappingObj.OverridePartPkgSetting : false;
        isForcedCategory = (fieldMappingObj.isForcedCategory != null) ? fieldMappingObj.isForcedCategory : false;
        priceFileFieldMappingId = fieldMappingObj.PriceFileFieldMappingId;
        
        List<Part__c> existingPartList = getExistingPartList(priceFileRecordList, vendorId);
        Map<String, Part__c> partNumberToPartMap = getPartNumberToPartMap(existingPartList);
        
        String defaultCategoryId = getDefaultCategory(vendorId); 
        String defaultSalesTaxId = getDefaultSalesTax(vendorId);
        
        List<String> tagList = new List<String>();
        List<Part__c> partListToUpsert = new List<Part__c>();
        Set<String> processedPartNumberSet = new Set<String>();
        for(PriceFileWrapper record : priceFileRecordList) {
            try {
                Part__c priceFilePartRec = setPartFieldsFromPriceFile(fieldMappingObj, record, partNumberToPartMap.containsKey(record.PartNumber));
                if(partNumberToPartMap.containsKey(record.PartNumber) && !processedPartNumberSet.contains(record.PartNumber)) {
                    priceFilePartRec.Id = partNumberToPartMap.get(record.PartNumber).Id;
                    priceFilePartRec = setPartPricesAndCosts(priceFilePartRec, partNumberToPartMap.get(record.PartNumber));
                    priceFilePartRec = setTags(record, priceFilePartRec, partNumberToPartMap.get(record.PartNumber), tagList);
                    priceFilePartRec.Old_Replaced_By_Part__c = partNumberToPartMap.get(record.PartNumber).Replaced_By_Part__c;
                } else {
                    priceFilePartRec.Taxable__c = true;
                    priceFilePartRec.Vendor__c = vendorId;
                    priceFilePartRec.Applicable_Tax__c = defaultSalesTaxId;
                    priceFilePartRec.Category__c = (priceFilePartRec.Category__c == null) ? defaultCategoryId : priceFilePartRec.Category__c;
                    
                    priceFilePartRec = setTags(record, priceFilePartRec, null, tagList);
                }
                priceFilePartRec.Is_Processed_By_APF__c = true;
                if(!processedPartNumberSet.contains(record.PartNumber)) {
                    partListToUpsert.add(priceFilePartRec);
                }
                processedPartNumberSet.add(record.PartNumber);                
            } catch(exception ex) {
                failedRecords++;
                errorLogsList.add(setErrorData('', ex.getMessage(), record.PartNumber));
            }
        }
        try {
        	createTags(tagList);
        } catch(Exception e) {
        	system.debug(e.getMessage());
        }
        PartTriggerHelper.isFromAutomatedPriceFile = true;
        if(!AccessControl.ifObjectFieldIsCreateable('Part__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
        if(!AccessControl.ifObjectFieldIsUpdateable('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        List<Database.UpsertResult> upsertResultList = DMLUtility.upsertSobjectListAndGetResult('Part__c', partListToUpsert, false);
        return handleErrorLogs(upsertResultList, partListToUpsert);
    }
    
    private static Part__c setPartFieldsFromPriceFile(FieldMappingWrapper fieldMappingObj, PriceFileWrapper priceFileObj, Boolean isPartExist) {
        Part__c partRec = new Part__c();
        partRec.Part_Number__c = priceFileObj.PartNumber;
        partRec.Description__c = (priceFileObj.Description != null && priceFileObj.Description.length() > 255) ? priceFileObj.Description.abbreviate(255) : priceFileObj.Description;
        
        if(fieldMappingObj.IsMfgNumberMapped) {
            partRec.Mfg_Part__c = priceFileObj.MfgNumber;
        }
        if(fieldMappingObj.IsSKUNumberMapped) {
            partRec.SKU_Number__c = priceFileObj.SKUNumber;
        }
        if(fieldMappingObj.IsReplacedByMapped) {
            partRec.Replaced_By_Part__c = priceFileObj.ReplacedByPart; 
        }
        if(fieldMappingObj.IsReplacesMapped) {
            partRec.Replaces_Part__c = priceFileObj.ReplacesPart;
        }
        if(String.isNotBlank(priceFileObj.CategoryId) && (!isPartExist || fieldMappingObj.isForcedCategory)) {
            partRec.Category__c = priceFileObj.CategoryId;
        } 
        
        partRec.Retail_Price__c = String.isNotBlank(priceFileObj.Retail) ? Decimal.valueof(priceFileObj.Retail) : 0;
        partRec.MSRP__c = String.isNotBlank(priceFileObj.MSRP) ? Decimal.valueof(priceFileObj.MSRP) : 0;
        partRec.Last_Cost__c = String.isNotBlank(priceFileObj.ItemCost) ? Decimal.valueof(priceFileObj.ItemCost) : 0;
        
        if(fieldMappingObj.IsPackageQtyMapped && priceFileObj.PackageQty != null && Decimal.valueof(priceFileObj.PackageQty) > 1 && priceFileObj.PackageQty.length() <= 16) {
            partRec.Packaged_Part__c = true;
            partRec.Package_Unit__c = 'PKG';
            partRec.Package_Qty__c = (Decimal.valueof(priceFileObj.PackageQty)).round().intValue();
            partRec.Package_Cost__c = partRec.Last_Cost__c * partRec.Package_Qty__c;
        } else {
            partRec.Packaged_Part__c = false; 
            partRec.Package_Unit__c = ''; 
            partRec.Package_Qty__c = 1;
            partRec.Package_Cost__c = 0;
        }
        return partRec;
    }
    
    private static Part__c setPartPricesAndCosts(Part__c priceFilePart, Part__c existingPart) {
        if(priceFilePart.Id != null) {
            if(!isOverridePartPkgSetting) {
                priceFilePart = setPartValuesBasedOnPackagePartFlag(priceFilePart, existingPart);
            }           
            
            //Ticket# 9017 - Issue #2
            if(String.isNotBlank(priceFilePart.Replaced_By_Part__c)) {
                if(priceFilePart.Package_Cost__c == 0 && priceFilePart.Packaged_Part__c) {
                    priceFilePart.Package_Cost__c = existingPart.Package_Cost__c;
                } 
                if(priceFilePart.Last_Cost__c == 0) {
                    priceFilePart.Last_Cost__c = existingPart.Last_Cost__c;
                }
                if(priceFilePart.Retail_Price__c == 0) {
                    priceFilePart.Retail_Price__c = existingPart.Retail_Price__c;
                }
                if(priceFilePart.MSRP__c == 0) {
                    priceFilePart.MSRP__c = existingPart.MSRP__c;
                }
            }
        }
        return priceFilePart;
    }
    
    
    private static Part__c setPartValuesBasedOnPackagePartFlag(Part__c priceFilePart, Part__c existingPart) {
        if(existingPart.Packaged_Part__c && !priceFilePart.Packaged_Part__c) {
            priceFilePart.MSRP__c = (priceFilePart.MSRP__c / existingPart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Retail_Price__c = (priceFilePart.Retail_Price__c / existingPart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Package_Cost__c = priceFilePart.Last_Cost__c.setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Packaged_Part__c = existingPart.Packaged_Part__c;
            priceFilePart.Package_Qty__c = existingPart.Package_Qty__c;
            priceFilePart.Last_Cost__c = (priceFilePart.Package_Cost__c/priceFilePart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            
        } else if(!existingPart.Packaged_Part__c && priceFilePart.Packaged_Part__c) {
            priceFilePart.MSRP__c = (priceFilePart.MSRP__c * priceFilePart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Retail_Price__c = (priceFilePart.Retail_Price__c * priceFilePart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Last_Cost__c = priceFilePart.Package_Cost__c.setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Package_Cost__c = 0;
            priceFilePart.Packaged_Part__c = existingPart.Packaged_Part__c;
            priceFilePart.Package_Qty__c = existingPart.Package_Qty__c;
            
        } else if(priceFilePart.Packaged_Part__c && existingPart.Packaged_Part__c && priceFilePart.Package_Qty__c != existingPart.Package_Qty__c) {
            priceFilePart.MSRP__c = ((priceFilePart.MSRP__c * priceFilePart.Package_Qty__c) / existingPart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Retail_Price__c = ((priceFilePart.Retail_Price__c * priceFilePart.Package_Qty__c) / existingPart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Package_Cost__c = (priceFilePart.Last_Cost__c * priceFilePart.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
            priceFilePart.Package_Qty__c = existingPart.Package_Qty__c;
        }
        return priceFilePart;
    }
    
    private static ResultWrapper handleErrorLogs(List<Database.UpsertResult> upsertResultList, List<Part__c> partListToUpsert) {
        Integer newRecords = 0;
        Integer updatedRecords = 0;
        Set<Id> importedPartIdSet = new Set<Id>();
        for(Integer i = 0; i < upsertResultList.size(); i++) {
            if(upsertResultList[i].isSuccess()) {
                if(upsertResultList[i].isCreated()) {
                    newRecords++;
                } else {
                    updatedRecords++;
                }
                //importedPartIdSet.add(upsertResultList[i].Id);
            } else {
                addErrorToList(upsertResultList[i].getErrors(), (i < partListToUpsert.size() ? partListToUpsert[i].Part_Number__c : ''));
                failedRecords++;
            }
        }
        if(errorLogsList.size() > 0) {
            DMLUtility.insertSobjectList('Price_File_Error_Log__c', errorLogsList);
        }
        return new ResultWrapper(newRecords, updatedRecords, failedRecords, importedPartIdSet);
    }
    
    private static List<Price_File_Error_Log__c> errorLogsList = new List<Price_File_Error_Log__c>();
    
    private static void addErrorToList(List<Database.Error> errorList, String partNumber) {
        if(errorList.size() > 0) {
            errorLogsList.add(setErrorData(String.join(errorList[0].getFields(), ','), errorList[0].getMessage(), partNumber));
        }
    }
    
    private static Price_File_Error_Log__c setErrorData(String fieldName, String errorMessage, String partNumber) {
        Price_File_Error_Log__c errorLog = new Price_File_Error_Log__c();
        errorLog.Error_Field_Name__c = fieldName;
        errorLog.Error_Messages__c = errorMessage;
        errorLog.Part_Number__c = partNumber;
        errorLog.Vendor__c = vendorId;
        errorLog.Price_File_Mapping__c = priceFileFieldMappingId;
        return errorLog;
    }
    
    public static String getDefaultCategory(String vendorId) {
        String defaultCategoryId;
        if(String.isNotBlank(vendorId)) {
            if(!AccessControl.ifObjectFieldIsAccessible('Account')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Account> vendorList = [SELECT Part_Category_Default__c FROM Account WHERE Id =: vendorId];
            if(vendorList.size() > 0) {
                defaultCategoryId = vendorList[0].Part_Category_Default__c;
            }
        }
        if(String.isBlank(defaultCategoryId)) {
            if(!AccessControl.ifObjectFieldIsAccessible('Category__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Category__c> categoryList = [SELECT Name FROM Category__c WHERE Default__c = true AND Type__c = 'Part'];
            if(categoryList.size() > 0) {
                defaultCategoryId = categoryList[0].Id;
            }
        }
        return defaultCategoryId;
    }
    
    private static String getDefaultSalesTax(String vendorId) {
        String defaultSalesTaxId = Configurations__c.getOrgDefaults().Default_Tax_on_Part__c;
        if(String.isBlank(defaultSalesTaxId)){
            if(!AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Sales_Tax__c> salesTaxList = [SELECT Id FROM Sales_Tax__c WHERE Default__c = true];
            if(salesTaxList.size() > 0) {
                defaultSalesTaxId = salesTaxList[0].Id;
            }
        }
        return defaultSalesTaxId;
    }
    
    private static Set<String> getPartNumberSet(List<PriceFileWrapper> priceFileList) {
        Set<String> partNumberSet = new Set<String>();
        for(PriceFileWrapper priceFileRec : priceFileList) {
        	if(String.isNotBlank(priceFileRec.PartNumber)) {
        		partNumberSet.add(priceFileRec.PartNumber.trim());
        	}
        }
        partNumberSet.remove(null);
        return partNumberSet;
    }
    
    private static List<Part__c> getExistingPartList(List<PriceFileWrapper> priceFileList, String vendorId) {
        Set<String> partNumberSet = getPartNumberSet(priceFileList);
        if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return [SELECT Part_Number__c, Packaged_Part__c, Package_Cost__c, Package_Qty__c, Retail_Price__c, MSRP__c, Last_Cost__c, Assigned_Tag_1__c, Assigned_Tag_2__c, Replaced_By_Part__c  
                    FROM Part__c WHERE Part_Number__c IN: partNumberSet AND Vendor__c =: vendorId];
    }
    
    private static Account getVendorDetail(String vendorId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Account')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account> vendorList = [SELECT Is_Calculate_Part_Retail_Price__c, Retail_Base_Value__c, Retail_Rate__c, Retail_Rounding__c, Retail_Round_To__c FROM Account WHERE Id =: vendorId];
        return (vendorList.size() > 0 ? vendorList[0] : new Account()); 
    }
    
    private static Map<String, Part__c> getPartNumberToPartMap(List<Part__c> partList) {
        Map<String, Part__c> partNumberToPartIdMap = new Map<String, Part__c>();
        for(Part__c partRec : partList) {
            partNumberToPartIdMap.put(partRec.Part_Number__c, partRec);
        }
        return partNumberToPartIdMap;
    }
    
    public static String getLastErrorLogNumber() {
        if(!AccessControl.ifObjectFieldIsAccessible('Price_File_Error_Log__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Price_File_Error_Log__c> errorList = [SELECT Name FROM Price_File_Error_Log__c order by Name DESC limit 1];
        return (errorList.size() > 0 ? errorList[0].Name : '');
    }
    
    public static Part__c setTags(PriceFileWrapper record, Part__c priceFilePart, Part__c existingPart, List<String> tagList) {
    	Set<String> newTagSet = new Set<String>();
    
        if(record.AssignedTags != null && record.AssignedTags.size() > 0)
        {
            for(String tag : record.AssignedTags) {
                if(String.isNotBlank(tag)) {
                    newTagSet.add(tag.trim().toLowerCase());
                }
            }
            List<String> allTagsForPartList = new List<String>();
			if(existingPart != null) {
	    		allTagsForPartList = TagUtil.getTagsList(existingPart);
	    		
		    	for(String tag : allTagsForPartList) {
		    		if(String.isNotBlank(tag) && newTagSet.contains(tag.trim().toLowerCase())) {
		    			newTagSet.remove(tag.trim().toLowerCase());
		    		}
		    	}
	    	}
	    	List<String> newTagList = new List<String>(newTagSet);
			allTagsForPartList.addAll(newTagList);
			if(allTagsForPartList != null && allTagsForPartList.size() > 0) {
	        	List<String> tagStrListForFields = TagUtil.convertTagListIntoTagString(allTagsForPartList);
	        	if(tagStrListForFields.size() == 2) {
	        		priceFilePart.Assigned_Tag_1__c = tagStrListForFields[0];
	        		priceFilePart.Assigned_Tag_2__c = tagStrListForFields[1];
	        	}
	        } else {
	        	priceFilePart.Assigned_Tag_1__c = priceFilePart.Assigned_Tag_2__c = '';
	        }
	        
	        tagList.addAll(newTagList);
        }	
    	return priceFilePart;
    }
    
    public static void createTags(List<String> tagList) {
    	if(tagList != null && tagList.size() > 0) {
	    	Set<String> tagSet = new Set<String>();
	    	for(String tag : tagList) {
	    		if(String.isNotBlank(tag)) {
	    			tagSet.add(tag.trim().toLowerCase());
	    		}
	    	}
	    	if(tagSet.size() > 0) {
		    	List<Tag__c> alreadyCreatedTags = [Select Id, Name__c from Tag__c where Name__c IN: tagSet];
		    	for(Tag__c tagRec : alreadyCreatedTags) {
		    		if(tagSet.contains(tagRec.Name__c.trim().toLowerCase())) {
		    			tagSet.remove(tagRec.Name__c.trim().toLowerCase());
		    		}
		    	}
		    	List<Tag__c> tagInsertList = new List<Tag__c>();
		    	for(String tag : tagSet) {
		    		Tag__c tagRec = new Tag__c(
		    			Name__c = tag, 
		    			Active__c = true
					);
		    		tagInsertList.add(tagRec);
		    	}
		    	if(tagInsertList.size() > 0) {
                    DMLUtility.insertSobjectList('Tag__c', tagInsertList);
		    	}
	    	}
    	}
    }
    
    public class PriceFileWrapper {
        public String PartNumber;
        public String Description;
        public String MfgNumber;
        public String SKUNumber;
        public String ReplacedByPart;
        public String ReplacesPart; 
        public String CategoryId;
        
        public String MSRP;
        public String Retail;
        public String ItemCost;
        public String PackageQty;
        public Set<String> AssignedTags;
    }
    
    public class FieldMappingWrapper {
        public String VendorId;
        public Boolean IsMfgNumberMapped;
        public Boolean IsSKUNumberMapped;
        public Boolean IsReplacedByMapped;
        public Boolean IsReplacesMapped;
        public Boolean IsPackageQtyMapped;
        public String PriceFileFieldMappingId;
        public Boolean OverridePartPkgSetting;
        public Boolean isForcedCategory;
    }
    
    global class ResultWrapper {
        public Integer NewParts;
        public Integer UpdatedParts;
        public Integer FailedParts;
        public Integer TotalParts;
        public Set<Id> ImportedPartIdSet;
        
        public ResultWrapper(Integer newParts, Integer updatedParts, Integer failedParts, Set<Id> importedPartIdSet) {
            this.NewParts = newParts;
            this.UpdatedParts = updatedParts;
            this.FailedParts = failedParts;
            this.TotalParts = this.NewParts + this.UpdatedParts + this.FailedParts;
            this.ImportedPartIdSet = importedPartIdSet;
        }
    }
}
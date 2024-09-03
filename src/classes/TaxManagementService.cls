/**
 * Author: Nidhi Sharma
 * Since: 13 Nov, 2019
 * Name: TaxManagementService
 * Description: 
**/
public without sharing class TaxManagementService {
    
    
    public static final String FIXED_RATE = 'Fixed rate';
    public static final String ESCALATING_RATE = 'Escalating rate';
    public static final String TIERED_RATE = 'Tiered rate';
    
    public static final String MULTIPLE_RATES = 'Multiple rates';
    
    public static String getTaxRatesAndCodes(TaxManagementFilterWrapper filterObj) {
        if(filterObj.IsTaxRate) {
            return BPUtility.getEncodedString(System.JSON.serialize(getTaxRates(filterObj)));
        } else if(filterObj.IsTaxCode) {
            return BPUtility.getEncodedString(System.JSON.serialize(getTaxCodes(filterObj)));
        }
        return null;
   	}

    public static TaxRateWrapper getTaxRates(TaxManagementFilterWrapper filterObj) {
        List<Sales_Tax_Item__c> salesTaxItemRecList = new List<Sales_Tax_Item__c>();
        Map<String, String> fieldNameToFieldValueMap = new Map<String, String>{'Is_Removed__c' => 'false'};
        if(!(filterObj.IncludeAutomatedRates != null && filterObj.IncludeAutomatedRates)) {
            fieldNameToFieldValueMap.put('Is_Automated__c', 'false');
        }
        if(!(filterObj.IncludeInactive != null && filterObj.IncludeInactive)) {
            fieldNameToFieldValueMap.put('Active__c', 'true');
        }
        if(String.isNotBlank(filterObj.TransectionType)) {
            fieldNameToFieldValueMap.put('Tax_Type__c', filterObj.TransectionType);
            salesTaxItemRecList.addAll(TaxManagementSOQLUtil.getTaxRates(fieldNameToFieldValueMap, filterObj));
        } else {
            fieldNameToFieldValueMap.put('Tax_Type__c', 'Sell');
            salesTaxItemRecList.addAll(TaxManagementSOQLUtil.getTaxRates(fieldNameToFieldValueMap, filterObj));
            fieldNameToFieldValueMap.put('Tax_Type__c', 'Purchase');
            salesTaxItemRecList.addAll(TaxManagementSOQLUtil.getTaxRates(fieldNameToFieldValueMap, filterObj));
        }
        salesTaxItemRecList = TaxActivityAndSettingService.getUpdatedSalesTaxItems(salesTaxItemRecList);
        return new TaxRateWrapper(salesTaxItemRecList);
    }

    public static TaxCodeWrapper getTaxCodes(TaxManagementFilterWrapper filterObj) {
        List<Sales_Tax__c> salesTaxList = new List<Sales_Tax__c>();
        Map<String, String> fieldNameToFieldValueMap = new Map<String, String>{'Is_Removed__c' => 'false'};
        if(!(filterObj.IncludeInactive != null && filterObj.IncludeInactive)) {
            fieldNameToFieldValueMap.put('Active__c', 'true');
        }
        if(String.isNotBlank(filterObj.TransectionType)) {
            fieldNameToFieldValueMap.put('Tax_Type__c', filterObj.TransectionType);
            salesTaxList.addAll(TaxManagementSOQLUtil.getSalesTaxes(fieldNameToFieldValueMap, filterObj));
        } else {
            fieldNameToFieldValueMap.put('Tax_Type__c', 'Sell');
            salesTaxList.addAll(TaxManagementSOQLUtil.getSalesTaxes(fieldNameToFieldValueMap, filterObj));
            fieldNameToFieldValueMap.put('Tax_Type__c', 'Purchase');
            salesTaxList.addAll(TaxManagementSOQLUtil.getSalesTaxes(fieldNameToFieldValueMap, filterObj));
        }
        List<Applicable_Taxes__c> applicableTaxesList = TaxManagementSOQLUtil.getAllApplicableTaxes(salesTaxList);
        Map<Id, List<Applicable_Taxes__c>> salesTaxToAppTaxesListMap = new Map<Id, List<Applicable_Taxes__c>>();
        for(Applicable_Taxes__c appTax: applicableTaxesList) {
            if(!salesTaxToAppTaxesListMap.containskey(appTax.Sales_Tax__c)) {
                salesTaxToAppTaxesListMap.put(appTax.Sales_Tax__c, new List<Applicable_Taxes__c>());
            }
            salesTaxToAppTaxesListMap.get(appTax.Sales_Tax__c).add(appTax);
        }
        return new TaxCodeWrapper(salesTaxList, salesTaxToAppTaxesListMap);
   }

    public static Map<String, String> getTaxRatesAndCodesCount(TaxManagementFilterWrapper filterObj) {
        if(filterObj.IsTaxRate) {
            return getTaxRateCounts(filterObj);
        } else if(filterObj.IsTaxCode) {
            return getTaxCodeCounts(filterObj);
        }
        return null;
    }

    public static Map<String, String> getTaxRateCounts(TaxManagementFilterWrapper filterObj) {
        Map<String, String> keyToValueMap = new Map<String, String>();
        List<AggregateResult> aggList = TaxManagementSOQLUtil.getTaxRateCounts(filterObj);
        for(AggregateResult aggRec : aggList) {
            if(aggRec.get(Constants.NAMESPACE + 'Tax_Type__c') == 'Sell') {
                keyToValueMap.put('SalesTaxRateCount', String.valueOf((Integer)aggRec.get('TaxRateCount')));
            } else if(aggRec.get(Constants.NAMESPACE + 'Tax_Type__c') == 'Purchase') {
                keyToValueMap.put('PurchaseTaxRateCount', String.valueOf((Integer)aggRec.get('TaxRateCount')));
            }
        }
        return keyToValueMap;
    }

    public static Map<String, String> getTaxCodeCounts(TaxManagementFilterWrapper filterObj) {
        Map<String, String> keyToValueMap = new Map<String, String>();
        List<AggregateResult> aggList = TaxManagementSOQLUtil.getTaxCodeCounts(filterObj);
        for(AggregateResult aggRec : aggList) {
            if(aggRec.get(Constants.NAMESPACE + 'Tax_Type__c') == 'Sell') {
                keyToValueMap.put('SalesTaxCodeCount', String.valueOf((Integer)aggRec.get('TaxCodeCount')));
            } else if(aggRec.get(Constants.NAMESPACE + 'Tax_Type__c') == 'Purchase') {
                keyToValueMap.put('PurchaseTaxCodeCount', String.valueOf((Integer)aggRec.get('TaxCodeCount')));
            }
        }
        return keyToValueMap;
    }

    public static void deleteTaxRate(String taxRateId) {
    	List<Applicable_Taxes__c> appTaxList = [Select Id from Applicable_Taxes__c where Sales_Tax_Item__c =: taxRateId LIMIT 1];
    	if(appTaxList.size() > 0) {
    		throw new BlackpurlException('Cannot delete: tax rate is being used in a tax code');
    	}
    	if(AccessControl.ifObjectIsUpdateable('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		update new Sales_Tax_Item__c(Id = taxRateId, Is_Removed__c = true);
    }
    
    public static void saveTaxRate(String taxRateJSONString) {
    	TaxRateWrapper.TaxRate taxRateObj = (TaxRateWrapper.TaxRate) System.JSON.deserialize(taxRateJSONString, TaxRateWrapper.TaxRate.class);
        try {
            if(String.isNotBlank(taxRateObj.TaxName)) {
            	validateDuplicateTaxRate(taxRateObj);
                Sales_Tax_Item__c taxRateRec = new Sales_Tax_Item__c(Id = taxRateObj.Id);
                taxRateRec.Name__c = taxRateObj.TaxName;
                taxRateRec.Category__c = taxRateObj.CategoryId;
                taxRateRec.Rate_Type__c = taxRateObj.RateType;
                taxRateRec.Forms_Label__c = taxRateObj.FormsLabel;
                taxRateRec.Tax_Type__c = taxRateObj.TaxType;
                taxRateRec.Minimum_Tax_Amount__c = taxRateObj.MinimumTaxAmount;
                taxRateRec.Maximum_Tax_Amount__c = taxRateObj.MaximumTaxAmount;
                if(taxRateRec.Rate_Type__c.equalsIgnoreCase(ESCALATING_RATE) || taxRateRec.Rate_Type__c.equalsIgnoreCase(TIERED_RATE)) {
                	taxRateRec.Rate__c = 0;
                	saveRateTable(taxRateRec, taxRateObj);
                } else {
                	taxRateRec.Rate__c = taxRateObj.TaxRate;
                }
                
                if(!AccessControl.ifObjectFieldIsUpdateable('Sales_Tax_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                if(!AccessControl.ifObjectFieldIsCreateable('Sales_Tax_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                upsert taxRateRec;
            } else {
            	throw new BlackPurlException(BlackPurlException.getErrorMessage('Tax name is required', null));
            }
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void validateDuplicateTaxRate(TaxRateWrapper.TaxRate taxRateObj) {
    	List<Sales_Tax_Item__c> taxRateList = new List<Sales_Tax_Item__c>();
    	if(String.isBlank(taxRateObj.Id)) {
            if(!AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            taxRateList = [SELECT Name__c FROM Sales_Tax_Item__c WHERE Name__c =: taxRateObj.TaxName];
        } else {
        	if(!AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            taxRateList = [SELECT Name__c FROM Sales_Tax_Item__c WHERE Name__c =: taxRateObj.TaxName AND Id !=: taxRateObj.Id];
        }
        if(taxRateList.size() > 0) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage('Duplicate tax rate', null));
        }
    }
    
    private static void saveRateTable(Sales_Tax_Item__c taxRateRec, TaxRateWrapper.TaxRate taxRateObj) {
    	Integer counter = 0;
    	for(Integer i = 0; i < taxRateObj.RateTable.size(); i++) {
    		counter++;
    		if(counterToTierTaxRateFieldAPINameMap.containsKey(counter)) {
    			taxRateRec.put(counterToTierTaxRateFieldAPINameMap.get(counter), taxRateObj.RateTable[i].TaxRate);
    		}
    		if(counterToTierMaxTaxableAmountFieldAPINameMap.containsKey(counter)) {
    			taxRateRec.put(counterToTierMaxTaxableAmountFieldAPINameMap.get(counter), taxRateObj.RateTable[i].MaximumTaxableAmount);
    		}
    	}
    }

    public static void saveTaxCode(String taxCodeJSONString) {
    	TaxCodeWrapper.TaxCode taxCodeObj = (TaxCodeWrapper.TaxCode) System.JSON.deserialize(taxCodeJSONString, TaxCodeWrapper.TaxCode.class);
        try {
            if(String.isNotBlank(taxCodeObj.Name)) {
            	validateDuplicateTaxCode(taxCodeObj);
            	Sales_Tax__c taxCodeRec = new Sales_Tax__c(Id = taxCodeObj.Id);
            	if(String.isNotBlank(taxCodeObj.Id) && !taxCodeObj.IsActive) {
            		taxCodeRec = [SELECT Id, Active__c FROM Sales_Tax__c WHERE Id =: taxCodeObj.Id];
            		if(taxCodeRec.Active__c &&  isTaxCodeInUse(taxCodeObj.Id)) {
			    		throw new BlackpurlException('Cannot deactivate: tax code is being used in use');
			    	}
            	}
                taxCodeRec.Name__c = taxCodeObj.Name;
                taxCodeRec.Forms_List_Taxes__c = taxCodeObj.IsListRatesOnForms;
                taxCodeRec.Forms_Label__c = taxCodeObj.FormsLabel;
                taxCodeRec.Tax_Type__c = taxCodeObj.TaxType;
                taxCodeRec.Active__c = taxCodeObj.IsActive;
                taxCodeRec.Default__c = taxCodeObj.IsDefault;
                
                if(!AccessControl.ifObjectFieldIsUpdateable('Sales_Tax__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                if(!AccessControl.ifObjectFieldIsCreateable('Sales_Tax__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                upsert taxCodeRec;
                taxCodeObj.Id = taxCodeRec.Id;
            } else {
            	throw new BlackPurlException(BlackPurlException.getErrorMessage('Tax name is required', null));
            }
            assignTaxRates(taxCodeObj);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void validateDuplicateTaxCode(TaxCodeWrapper.TaxCode taxCodeObj) {
    	List<Sales_Tax__c> taxCodeList = new List<Sales_Tax__c>();
    	if(String.isBlank(taxCodeObj.Id)) {
            if(!AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            taxCodeList = [SELECT Name__c FROM Sales_Tax__c WHERE Name__c =: taxCodeObj.Name];
        } else {
        	if(!AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            taxCodeList = [SELECT Name__c FROM Sales_Tax__c WHERE Name__c =: taxCodeObj.Name AND Id !=: taxCodeObj.Id];
        }
        if(taxCodeList.size() > 0) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage('Duplicate tax code', null));
        }
    }

    private static void assignTaxRates(TaxCodeWrapper.TaxCode taxCodeObj) {
        List<Applicable_Taxes__c> appTaxList = [SELECT Id, Maximum_Taxable_Amount__c, Sales_Tax__c, Sales_Tax_Item__c FROM Applicable_Taxes__c WHERE Sales_Tax__c =: taxCodeObj.Id];
        Map<String, Applicable_Taxes__c> salesTaxItemIdToAppTaxMap = new Map<String, Applicable_Taxes__c>();
        for(Applicable_Taxes__c appTaxRec: appTaxList) {
            salesTaxItemIdToAppTaxMap.put(appTaxRec.Sales_Tax_Item__c, appTaxRec);
        }

        List<Sales_Tax_Item__c> otherDistrictSTIList;
        Decimal maximumTaxableAmountForDistrictTax;
        List<Applicable_Taxes__c> appTaxListToUpsert = new List<Applicable_Taxes__c>();
        for(TaxRateWrapper.TaxRate taxRateObj: taxCodeObj.TaxRateList) {
            if(GeneralConfiguration.getConfigurations().Automatic_tax_rates__c && taxRateObj.TaxType == 'Sell' && taxRateObj.IsAutomated && taxRateObj.TaxName == ZipTaxUtil.DISTRICT_TAX) {
                maximumTaxableAmountForDistrictTax = taxRateObj.MaximumTaxableAmount;
                otherDistrictSTIList = TaxActivityAndSettingService.getAllOtherDistrictTaxRates(taxRateObj.Id, null);
            }
            if(salesTaxItemIdToAppTaxMap.containsKey(taxRateObj.Id)) {
                if(taxRateObj.IsAutomated && salesTaxItemIdToAppTaxMap.get(taxRateObj.Id).Maximum_Taxable_Amount__c != taxRateObj.MaximumTaxableAmount) {
                    salesTaxItemIdToAppTaxMap.get(taxRateObj.Id).Maximum_Taxable_Amount__c = taxRateObj.MaximumTaxableAmount;
                    appTaxListToUpsert.add(salesTaxItemIdToAppTaxMap.get(taxRateObj.Id));
                }
                salesTaxItemIdToAppTaxMap.remove(taxRateObj.Id);
            } else {
                appTaxListToUpsert.add(new Applicable_Taxes__c(Sales_Tax__c = taxCodeObj.Id, Sales_Tax_Item__c = taxRateObj.Id, Maximum_Taxable_Amount__c = taxRateObj.MaximumTaxableAmount));
            }
        }

        if(otherDistrictSTIList != null && !otherDistrictSTIList.isEmpty()) {
            for(Sales_Tax_Item__c stiRec: otherDistrictSTIList) {
                if(salesTaxItemIdToAppTaxMap.containsKey(stiRec.Id)) {
                    if(stiRec.Is_Automated__c && salesTaxItemIdToAppTaxMap.get(stiRec.Id).Maximum_Taxable_Amount__c != maximumTaxableAmountForDistrictTax) {
                        salesTaxItemIdToAppTaxMap.get(stiRec.Id).Maximum_Taxable_Amount__c = maximumTaxableAmountForDistrictTax;
                        appTaxListToUpsert.add(salesTaxItemIdToAppTaxMap.get(stiRec.Id));
                    }
                    salesTaxItemIdToAppTaxMap.remove(stiRec.Id);
                } else {
                    appTaxListToUpsert.add(new Applicable_Taxes__c(Sales_Tax__c = taxCodeObj.Id, Sales_Tax_Item__c = stiRec.Id, Maximum_Taxable_Amount__c = maximumTaxableAmountForDistrictTax));
                }
            }
        }
        DMLUtility.upsertSObjectList('Applicable_Taxes__c', appTaxListToUpsert);
        DMLUtility.deleteSObjectList('Applicable_Taxes__c', salesTaxItemIdToAppTaxMap.values());
    }
    
    public static void assignTaxRates(String taxCodeJSONString) {
        TaxCodeWrapper.TaxCode taxCodeObj = (TaxCodeWrapper.TaxCode) System.JSON.deserialize(taxCodeJSONString, TaxCodeWrapper.TaxCode.class);
        assignTaxRates(taxCodeObj);
    }
    
    public static void deleteTaxCode(String taxCodeId) {
    	if(isTaxCodeInUse(taxCodeId)) {
    		throw new BlackpurlException('Cannot delete: tax code is being used.');
    	}
    	if(AccessControl.ifObjectIsUpdateable('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		update new Sales_Tax__c(Id = taxCodeId, Is_Removed__c = true);
    }
    
    private static Boolean isTaxCodeInUse(String taxCodeId) {
    	List<Sales_Tax__c> salesTaxList = TaxManagementSOQLUtil.getSalesTaxWithAllRelatedEntities(taxCodeId);
    	Configurations__c config = Configurations__c.getOrgDefaults();
    	List<String> defaultTaxSettingList = new List<String>{
    															config.Default_Sales_Tax_on_Internal_Service__c,
    															config.Default_Tax_on_Fee__c,
    															config.Default_Tax_on_Labor__c,
    															config.Default_Tax_on_Part__c,
    															config.Default_Tax_on_Unit__c,
    															config.Default_Tax_on_Vendor_Product__c
    														};
    	for(Sales_Tax__c salesTaxRec: salesTaxList) {
    		if((salesTaxRec.Accounts1__r.size() > 0
				|| salesTaxRec.Customer_Owned_Units__r.size() > 0
				|| salesTaxRec.Fees__r.size() > 0
				|| salesTaxRec.Labour_Codes__r.size() > 0
				|| salesTaxRec.Parts__r.size() > 0
				|| salesTaxRec.Products__r.size() > 0)
				|| salesTaxRec.Deals_Items__r.size() > 0
				|| defaultTaxSettingList.contains(salesTaxRec.Id)) {
					return true;
			}
    	}
    	return false;
    }
    
    public static Map<Integer, String> counterToTierTaxRateFieldAPINameMap = new Map<Integer, String>{
    																							1	=>	'Tax_Rate_Tier_1__c',
    																							2	=>	'Tax_Rate_Tier_2__c',
    																							3	=>	'Tax_Rate_Tier_3__c'
    																						};
    																						
    public static Map<Integer, String> counterToTierMaxTaxableAmountFieldAPINameMap = new Map<Integer, String>{
    																							1	=>	'Max_Taxable_Amount_Tier_1__c',
    																							2	=>	'Max_Taxable_Amount_Tier_2__c'
    																						};
}
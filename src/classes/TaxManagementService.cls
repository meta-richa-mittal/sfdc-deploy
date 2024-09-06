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
    
    public static TaxRateWrapper getAllTaxRates() {
    	 List<TaxRateWrapper> taxRateObjList = new  List<TaxRateWrapper>();
    	 List<Sales_Tax_Item__c> salesTaxItemRecList = TaxManagementSOQLUtil.getAllTaxRates(new Map<String, String>{'Is_Removed__c' => 'false'});
    	 return new TaxRateWrapper(salesTaxItemRecList);
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
                if(taxRateRec.Rate_Type__c.equalsIgnoreCase(ESCALATING_RATE) || taxRateRec.Rate_Type__c.equalsIgnoreCase(TIERED_RATE)) {
                	taxRateRec.Rate__c = 0;
                	taxRateRec.Minimum_Tax_Amount__c = taxRateObj.MinimumTaxAmount;
                	taxRateRec.Maximum_Tax_Amount__c = taxRateObj.MaximumTaxAmount;
                	saveRateTable(taxRateRec, taxRateObj);
                } else {
                	taxRateRec.Rate__c = taxRateObj.TaxRate;
                	taxRateRec.Minimum_Tax_Amount__c = 0;
                	taxRateRec.Maximum_Tax_Amount__c = 0;
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
    
    public static TaxCodeWrapper getAllTaxCodes() {
    	 List<Sales_Tax__c> salesTaxList = TaxManagementSOQLUtil.getAllSalesTaxes();
    	 List<Applicable_Taxes__c> applicableTaxesList = TaxManagementSOQLUtil.getAllApplicableTaxes();
    	 Map<Id, List<Applicable_Taxes__c>> salesTaxToAppTaxesListMap = new Map<Id, List<Applicable_Taxes__c>>();
    	 for(Applicable_Taxes__c appTax: applicableTaxesList) {
    	 	if(!salesTaxToAppTaxesListMap.containskey(appTax.Sales_Tax__c)) {
    	 		salesTaxToAppTaxesListMap.put(appTax.Sales_Tax__c, new List<Applicable_Taxes__c>());
    	 	}
    	 	salesTaxToAppTaxesListMap.get(appTax.Sales_Tax__c).add(appTax);
    	 }
    	 return new TaxCodeWrapper(salesTaxList, salesTaxToAppTaxesListMap);
    }
    
    public static List<TaxRateWrapper.TaxRate> getTaxRatesBasedOnTaxType(String taxType) {
    	 List<TaxRateWrapper.TaxRate> taxRateList = new  List<TaxRateWrapper.TaxRate>();
    	 if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	 List<Sales_Tax_Item__c> salesTaxItemRecList = TaxManagementSOQLUtil.getAllTaxRates(new Map<String, String>{'Tax_Type__c' => taxType});
    	 for(Sales_Tax_Item__c salesTaxRec: salesTaxItemRecList) {
    	 	taxRateList.add(new TaxRateWrapper.TaxRate(salesTaxRec));
    	 }
    	 return taxRateList;
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
            } else {
            	throw new BlackPurlException(BlackPurlException.getErrorMessage('Tax name is required', null));
            }
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
    
    public static void assignTaxRates(String taxCodeJSONString) {
    	TaxCodeWrapper.TaxCode taxCodeObj = (TaxCodeWrapper.TaxCode) System.JSON.deserialize(taxCodeJSONString, TaxCodeWrapper.TaxCode.class);
        try {
            List<Applicable_Taxes__c> appTaxList = [SELECT Id, Sales_Tax__c, Sales_Tax_Item__c FROM Applicable_Taxes__c WHERE Sales_Tax__c =: taxCodeObj.Id];
            Map<String, Applicable_Taxes__c> salesTaxItemIdToAppTaxMap = new Map<String, Applicable_Taxes__c>();
            for(Applicable_Taxes__c appTaxRec: appTaxList) {
            	salesTaxItemIdToAppTaxMap.put(appTaxRec.Sales_Tax_Item__c, appTaxRec);
            }
            
            List<Applicable_Taxes__c> appTaxListToInsert = new List<Applicable_Taxes__c>();
            for(TaxRateWrapper.TaxRate taxRateObj: taxCodeObj.TaxRateList) {
            	if(salesTaxItemIdToAppTaxMap.containsKey(taxRateObj.Id)) {
            		salesTaxItemIdToAppTaxMap.remove(taxRateObj.Id);
            	} else {
            		appTaxListToInsert.add(new Applicable_Taxes__c(Sales_Tax__c = taxCodeObj.Id, Sales_Tax_Item__c = taxRateObj.Id));
            	}
            }
            
            if(!AccessControl.ifObjectFieldIsCreateable('Applicable_Taxes__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert appTaxListToInsert;
            
            if(AccessControl.ifObjectIsDeletable('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete salesTaxItemIdToAppTaxMap.values();
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
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
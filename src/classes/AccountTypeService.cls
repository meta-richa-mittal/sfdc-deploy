/** 
* Author: Rajat Jain
* Since: Oct 7, 2018 
* Name: AccountTypeService 
* Description: Apex class which contains all methods related to Account Type.
**/
public without sharing class AccountTypeService { 
	/** Method to get data of all account type present in appication
    * CtrlClass -AccountTypeCtrl
    * @Return - list of account type wrapper(Json containing all account type data)
    */
    public static List<AccountTypeWrapper> getAllAccountTypeData() {
        List<AccountTypeWrapper> accountsData = new List<AccountTypeWrapper>();
        
        String query = 'SELECT ' + String.join(AccountTypeWrapper.getAccountTypeFields(), ',') + ' FROM Account_Type__c ORDER BY Applies_To__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
    	List<Account_Type__c> accountTypeList = SOQLUtility.getQueryResults('Account_Type__c', query);
        if(!accountTypeList.isEmpty()) {
            Map<Id, List<Tax_Exemption__c>> accTypeIdToExemptionsMap = new Map<Id, List<Tax_Exemption__c>>();
            for(Tax_Exemption__c taxEmpRec : [Select Account_Type__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Tax_Type__c, Sales_Tax_Item__r.Is_Automated__c FROM Tax_Exemption__c WHERE Account_Type__c IN: accountTypeList AND Sales_Tax_Item__r.Is_Removed__c = false]) {
                if(!accTypeIdToExemptionsMap.containsKey(taxEmpRec.Account_Type__c)) {
                    accTypeIdToExemptionsMap.put(taxEmpRec.Account_Type__c, new List<Tax_Exemption__c>());
                }
                accTypeIdToExemptionsMap.get(taxEmpRec.Account_Type__c).add(taxEmpRec);
            }
            for(Account_Type__c accTypeRec : accountTypeList) {
                accountsData.add(new AccountTypeWrapper(accTypeRec, accTypeIdToExemptionsMap.get(accTypeRec.Id)));
            }
        }
    	return accountsData;
    }

    public static List<AccountTypeWrapper> getAllAccountTypeOnlyForCustomer() {
    	return populateAccountTypeWrapperData(AccountTypeSOQLUtil.getAccountTypeOnly(new Map<String,String>{'Applies_To__c' => 'Customers', 'Active__c' => 'true'}));
    }
    
    /** Method to get data of all account type present in appication
    * CtrlClass -AccountTypeCtrl
    * @Return - list of account type wrapper(Json containing all account type data)
    */
    public static List<AccountTypeWrapper> getAllAccountTypeForCustomer() {
    	if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Account_Type__c> accountTypeList = AccountTypeSOQLUtil.getAccountType(new Map<String,String>{'Applies_To__c' => 'Customers', 'Active__c' => 'true'});
    	return populateAccountTypeWrapperData(accountTypeList);
    }
    
    /** Method to get data of all account type present in appication
    * CtrlClass -AccountTypeCtrl
    * @Return - list of account type wrapper(Json containing all account type data)
    */
    public static List<AccountTypeWrapper> getAllAccountTypeForVendor() {
    	if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Account_Type__c> accountTypeList = AccountTypeSOQLUtil.getAccountType(new Map<String,String>{'Applies_To__c' => 'Vendors', 'Active__c' => 'true'});
    	return populateAccountTypeWrapperData(accountTypeList);
    }
    
    /** Method to populate account type wrapper list with account type obj data
    * CtrlClass -AccountTypeCtrl
    * @Return - list of account type wrapper(Json containing all account type data)
    */
    
    private static List<AccountTypeWrapper> populateAccountTypeWrapperData(List<Account_Type__c> accountTypeList) {
    	List<AccountTypeWrapper> accountsData = new List<AccountTypeWrapper>();
    	if(accountTypeList.size() > 0) {
    		for(Account_Type__c accTypeRec : accountTypeList) {
    			accountsData.add(new AccountTypeWrapper(accTypeRec));
    		}
    	} 
    	return accountsData;
    }
    /** Method to get data of all Active Sales Tax i.e invoked when new record is about to be created
    * CtrlClass -AccountTypeCtrl
    * @Return - list of tax exemptions(Json containing all sales tax data)
    */
    
    public static List<TaxExemptions> getAllActiveSalesTax() {
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Sales_Tax_Item__c> salesTaxItemList = AccountTypeSOQLUtil.getAllSalesTaxItemWithExemptions();
        List<TaxExemptions> taxExemptionsList = new List<TaxExemptions>();  
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = getAppliesToList(salesTaxItemList);
        salesTaxItemList = TaxActivityAndSettingService.getUpdatedSalesTaxItems(salesTaxItemList);
        for(Sales_Tax_Item__c salesTaxItemRec : salesTaxItemList) {
            taxExemptionsList.add(new TaxExemptions(salesTaxItemRec, salesTaxItemIdToAppliesToList.get(salesTaxItemRec.Id), 'Account type'));
        }
        return taxExemptionsList;
    }
    
    /** Method to get data of all AppliesToList
    * CtrlClass -AccountTypeCtrl
    * @Return - Map<Id, List<String>>
    */
    
    private static Map<Id, List<String>> getAppliesToList(List<Sales_Tax_Item__c> salesTaxItemList) {
        Set<Id> salesTaxItemIdSet = new Set<Id>();
        for(Sales_Tax_Item__c salesTaxItemRec : salesTaxItemList) {
            salesTaxItemIdSet.add(salesTaxItemRec.Id);
        }
        
        if(salesTaxItemIdSet.size() == 0) {
            return new Map<Id, List<String>>();
        }
        if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = new Map<Id, List<String>>(); 
        List<Applicable_Taxes__c> appTaxList = [select Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax__r.Name__c from Applicable_Taxes__c
                                                    where Sales_Tax_Item__c IN: salesTaxItemIdSet];
        
        for(Applicable_Taxes__c appTaxRec : appTaxList) {
            if(appTaxRec.Sales_Tax__c != null) {
                List<String> appliesToList;
                if(!salesTaxItemIdToAppliesToList.containsKey(appTaxRec.Sales_Tax_Item__c)) {
                    salesTaxItemIdToAppliesToList.put(appTaxRec.Sales_Tax_Item__c, new List<String>());
                }
                salesTaxItemIdToAppliesToList.get(appTaxRec.Sales_Tax_Item__c).add(appTaxRec.Sales_Tax__r.Name__c);
            }
        }
        return salesTaxItemIdToAppliesToList;
    }
    
    /** Method to save new Account Type i.e new record insertion
    * CtrlClass -AccountTypeCtrl
    * @Return - String ->Id of newly created account type
    */
    
    public static String addEditAccountType(String accountTypeJsonStr) { 
    	if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	if(AccessControl.ifObjectIsUpdateable('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	AccountTypeWrapper rec = (AccountTypeWrapper)JSON.deserialize(accountTypeJsonStr, AccountTypeWrapper.class);
    	if(rec.IsDefault) {
    		validateIsDefaultRecType(rec);
    	}
		
		Account_Type__c accTypeObj = new Account_Type__c();
		accTypeObj.Id = rec.Id;
		accTypeObj.Name = rec.AccountType;
		accTypeObj.Applies_To__c = rec.AppliesTo;
		accTypeObj.Default__c = rec.IsDefault != null ? rec.IsDefault : false;
		accTypeObj.Active__c = rec.IsActive != null ? rec.IsActive : false;
		upsert accTypeObj;
		
        saveTaxExemptionList(accTypeObj.Id, rec.TaxExemptionsList);
		return accTypeObj.Id;
    }
    private static void validateIsDefaultRecType(AccountTypeWrapper rec) {
    	Account_Type__c accTypeObj = [Select Id,Default__c from Account_Type__c where Default__c = true And Applies_To__c =: rec.AppliesTo];
    	if(accTypeObj.Id != rec.Id ) {
    		accTypeObj.Default__c = false;
    		update accTypeObj;
    	}
    }
    
    private static void saveTaxExemptionList(String accTypeObjId, List<TaxExemptions> taxExemptionObjList) {
        if(AccessControl.ifObjectFieldIsCreateable('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        
        Tax_Exemption__c districtTaxExeptionRec;
        List<Tax_Exemption__c> taxExemptionListToUpsert = new List<Tax_Exemption__c>();
        for(TaxExemptions taxExemptionObj : taxExemptionObjList) {
            Tax_Exemption__c taxExemptionRec = new Tax_Exemption__c();
            Boolean isExempted = (taxExemptionObj.IsSelected != null && taxExemptionObj.IsSelected);
            if(taxExemptionObj.SalesTaxItemId != null && (isExempted || taxExemptionObj.RateOverride != null)) {
                taxExemptionRec.Id = taxExemptionObj.TaxExemptionId;
                taxExemptionRec.Account_Type__c = accTypeObjId;
                taxExemptionRec.Sales_Tax_Item__c = taxExemptionObj.SalesTaxItemId;
                taxExemptionRec.Rate_Override__c = (!isExempted ? taxExemptionObj.RateOverride : null);
                taxExemptionListToUpsert.add(taxExemptionRec);
                if(GeneralConfiguration.getConfigurations().Automatic_tax_rates__c && taxExemptionObj.TaxType == 'Sell' && taxExemptionObj.RateStr == 'Automated' && taxExemptionObj.SalesTaxName == ZipTaxUtil.DISTRICT_TAX) {
                    districtTaxExeptionRec = taxExemptionRec;
                }
            } 
        }

        if(districtTaxExeptionRec != null) {
            List<Sales_Tax_Item__c> otherDistrictSTIList = TaxActivityAndSettingService.getAllOtherDistrictTaxRates(districtTaxExeptionRec.Sales_Tax_Item__c, accTypeObjId);
            for(Sales_Tax_Item__c stiRec: otherDistrictSTIList) {
                if(stiRec.Tax_Exemptions__r.isEmpty()) {
                    Tax_Exemption__c otherExemptionRec = new Tax_Exemption__c();
                    otherExemptionRec.Account_Type__c = accTypeObjId;
                    otherExemptionRec.Sales_Tax_Item__c = stiRec.Id;
                    otherExemptionRec.Rate_Override__c = districtTaxExeptionRec.Rate_Override__c;
                    taxExemptionListToUpsert.add(otherExemptionRec);
                } else {
                    stiRec.Tax_Exemptions__r[0].Rate_Override__c = districtTaxExeptionRec.Rate_Override__c;
                    taxExemptionListToUpsert.add(stiRec.Tax_Exemptions__r[0]);
                }
            }
        }
        DMLUtility.upsertSobjectList('Tax_Exemption__c', taxExemptionListToUpsert);
        DMLUtility.deleteSobjectList('Tax_Exemption__c', [Select Id FROM Tax_Exemption__c WHERE Account_Type__c =: accTypeObjId AND Id NOT IN: taxExemptionListToUpsert]);
    }
    
   /** Method to get Record of a particular Account Type which is needed before this record is updated
    * CtrlClass -AccountTypeCtrl
    * @Return - account type wrapper object
    */
    
    public static AccountTypeWrapper getRecForAccountType(String accTypeId) {
        List<Account_Type__c> accTypeRec = AccountTypeSOQLUtil.getTaxExemptionRecForAccType(new Map<String,String>{'Id' => accTypeId});
        Map<Id, TaxExemptions> taxRateIdToTaxExemptionsMap = new Map<Id, TaxExemptions>();  
        List<Sales_Tax_Item__c> salesTaxItemList = new List<Sales_Tax_Item__c>();
        List<Tax_Exemption__c> taxExemptionItemList = new List<Tax_Exemption__c>();
        if(accTypeRec[0].Tax_Exemptions__r.size() > 0) {
	        for(Tax_Exemption__c tax : accTypeRec[0].Tax_Exemptions__r) {
				if(tax.Sales_Tax_Item__r != null && tax.Sales_Tax_Item__r.Name__c != null && String.isNotBlank(tax.Sales_Tax_Item__r.Name__c)) {
			    	taxExemptionItemList.add(tax);
			    	salesTaxItemList.add(tax.Sales_Tax_Item__r);
				}
			}
        }
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = getAppliesToList(salesTaxItemList);
        for(Tax_Exemption__c taxExemptionRec : taxExemptionItemList) {
            taxRateIdToTaxExemptionsMap.put(taxExemptionRec.Sales_Tax_Item__c, new TaxExemptions(taxExemptionRec, salesTaxItemIdToAppliesToList.get(taxExemptionRec.Sales_Tax_Item__c), 'Account Type'));
        } 
        return populateTaxExemptionList(taxRateIdToTaxExemptionsMap, accTypeRec[0]);
    }
    
    /** Method to populate all the sales tax present with sales tax present on the record
    * CtrlClass -AccountTypeCtrl
    * @Return - account type wrapper object
    */
    private static AccountTypeWrapper populateTaxExemptionList(Map<Id, TaxExemptions> taxRateIdToTaxExemptionsPresentMap, Account_Type__c accTypeRec) {
    	List<TaxExemptions> allTaxesExemptionList =  getAllActiveSalesTax();
    	for(TaxExemptions taxes : allTaxesExemptionList) {
            if(taxRateIdToTaxExemptionsPresentMap.containsKey(taxes.SalesTaxItemId)) {
                taxes.isSelected = taxRateIdToTaxExemptionsPresentMap.get(taxes.SalesTaxItemId).IsSelected;
                taxes.RateOverride = taxRateIdToTaxExemptionsPresentMap.get(taxes.SalesTaxItemId).RateOverride;
                if(taxes.isSelected || taxes.RateOverride != null) taxes.TaxExemptionId = taxRateIdToTaxExemptionsPresentMap.get(taxes.SalesTaxItemId).TaxExemptionId;
            }
        }
        return new AccountTypeWrapper(accTypeRec, allTaxesExemptionList);
    }
    
    public static String getDefaultAccoutTypeRecId(String appliesTo) {
        if(String.isNotBlank(appliesTo)) {
            if(AccessControl.ifObjectFieldIsAccessible('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            for(Account_Type__c accType : [SELECT Id FROM Account_Type__c WHERE Default__c = true AND Applies_To__c = :appliesTo LIMIT 1]) {
                return accType.Id;
            }
        }
        return null;
    }
}
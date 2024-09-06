/**
 * Author: Tarun Khandelwal
 * Since: July 4, 2015
 * Name: ViewPartCtrl
 * Description: Controller Class of Part Detail Page.
**/
global without sharing class ViewVendorCtrl {
    
    
    public String MapAPIKey {get{return GeneralConfiguration.getMapAPIKey();} private set;}
    
    global ViewVendorCtrl (NewHomePageCtrl controller){}
    public ViewVendorCtrl() {}
    /**
     * Name: getVendorInfo
     * Desc: To get Vendor Inforamtion used in View Vendor Page
     * @param: (1) vendorId - String - Id of Vendor
     * @return: String - JSON string of Vendor Info. 
    **/
    @RemoteAction 
    global static String getVendorInfo(String vendorId) {
        vendorId = BPUtility.getDecodedString(vendorId);
        
        try{
            Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Is_Vendor__c' => true, 'Id' => vendorId};
            List<Account> vendors = SOQLUtil.getVendorDetailsWithEscalators(null, fieldNameToFieldValueMap);
            List<Tax_Exemption__c> taxExemptionList = SOQLUtil.getTaxExemptionList(vendorId, new Map<String, String>());
            List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
	        String taxExemptions;
	        if(vendors[0].Vendor_Account_Type__r.Id != null) {
	        	AccountTypeWrapper accRec = AccountTypeService.getRecForAccountType(vendors[0].Vendor_Account_Type__r.Id);
	        	taxExemptions = accRec != null ? accRec.TaxExemptions : ''; 
	        }
            String JSONString = '{}';
            if(vendors.size() > 0) {
                VendorDetail vendorDetailObj = new VendorDetail(vendors[0], taxExemptionList, businessProfileList, taxExemptions);
                if(vendorDetailObj.VendorDetailRec != null) {
                    vendorDetailObj.VendorDetailRec.IsCustomExportFormatDefined = ([SELECT Id FROM GE_File_Config__c WHERE Vendor__c = :vendorId].size() > 0);
                }
	            JSONString = System.JSON.serialize(vendorDetailObj);
            }
            return BPUtility.getEncodedString(JSONString);
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        }
    }
    
    public static VendorDetailWrapper getVendorDetails(String vendorId) {
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String query = 'SELECT ';
        for(String fieldName : VendorDetailWrapper.fieldsList()) {
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Account WHERE Id = :vendorId';
        List<Account> vendorList = Database.query(query);
        if(vendorList.size() > 0) {
            Boolean isCustomExportFormatDefined = ([SELECT Id FROM GE_File_Config__c WHERE Vendor__c = :vendorId].size() > 0);
            return new VendorDetailWrapper(vendorList[0], isCustomExportFormatDefined);
        }
        return new VendorDetailWrapper();
    }
    
    /**
    * Name: getCOHeaderDetails
    * Desc: 
    * @param:  
    * @return: 
    **/
    @RemoteAction
    global static String getAllLookupFieldsJSON(){
        try{
            List<Country__c> countryList = SOQLUtil.getAllCountry();
            List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();
            List<Sales_Tax__c> salesTaxList = SOQLUtil.getSalesTax(new List<Id>());
            List<Price_Level__c> priceLevelList = SOQLUtil.getPriceLevel(new List<Id>());
            List<Category__c> categoryList = SOQLUtil.getPartCategory(new List<Id>());
            
            COUFieldWrapper cOUFieldWrapperObj = new COUFieldWrapper(countryList, countryWrapperList, salesTaxList, priceLevelList, 
                                                                        new List<Unit_Make__c>(), new List<Unit_Make__c>(), categoryList);
            return BPUtility.getEncodedString(System.JSON.serialize(cOUFieldWrapperObj));
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        } 
    }
    
    
    /**
    * Name: saveVendor
    * Desc: 
    * @param:  
    * @return: 
    **/
    @RemoteAction
    global static String saveVendor(String jsonString){
        jsonString = BPUtility.getDecodedString(jsonString);
        
        try{
            if(AccessControl.ifObjectFieldIsCreateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            
            Vendor vendorObj = Vendor.parse(jsonString);

            if(vendorObj != null && vendorObj.IsForeignVendor != null && vendorObj.IsForeignVendor && vendorObj.IsClaimsForServiceWork != null && vendorObj.IsClaimsForServiceWork) {
                throw new BlackPurlException(Constants.restrictionErrorForForeignVendor);
            }

            // check if vendor can be deactivated or not
            String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
            if(activeIntegrationName != null) {
                BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
                IFW_IntegrationConfig__c ifwConfigRec;
                if(integrationRec != null && integrationRec.integrationConfigRec != null) ifwConfigRec = integrationRec.integrationConfigRec;

                if(ifwConfigRec != null) {
                    ResponseWrapper openBalanceFromAccAppRes = AccountingUtil.getVendorOpenBalanceInfoForAccApp(vendorObj.Id, vendorObj.Active, ifwConfigRec, activeIntegrationName);
                    if(openBalanceFromAccAppRes.responseStatus == 'error') {
                        QBCalloutManager.updateRecords(ifwConfigRec); // This method will work for both QB/Xero as it is only updating IFW record and saving web service logs.
                        return BPUtility.getEncodedString(System.JSON.serialize(openBalanceFromAccAppRes));
                    } else if(vendorObj.IsClaimsForServiceWork) {
                        openBalanceFromAccAppRes = AccountingUtil.getCustomerOpenBalanceInfoForAccApp(vendorObj.Id, vendorObj.Active, ifwConfigRec, activeIntegrationName); // ifwConfigRec will be updated in getOpenBalanceInfoForAccApp method because it calls getCustomerOpenBalanceInfoForAccApp method internally
                        if(openBalanceFromAccAppRes.responseStatus == 'error') {
                            if(String.isNotBlank(openBalanceFromAccAppRes.response)) openBalanceFromAccAppRes.response = openBalanceFromAccAppRes.response.replace('Customer', 'Third-Party Provider');
                            return BPUtility.getEncodedString(System.JSON.serialize(openBalanceFromAccAppRes));
                        }
                    }
                }
            }
            
            // To set Purchase tax when vendor is created
            if(vendorObj.PurchaseTaxLevelId == null && vendorObj.Id == null) {
                vendorObj.PurchaseTaxLevelId = GeneralConfiguration.getOrderingTaxRate();
                if(String.isBlank(vendorObj.PurchaseTaxLevelId)) {
                    if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    List<Sales_Tax__c> salesTaxList = [select Id from Sales_Tax__c where default__c = true AND Active__c = true limit 1];
                    if(salesTaxList.size() > 0) {
                        vendorObj.PurchaseTaxLevelId = salesTaxList[0].Id;
                    }
                }
            }
            Account vendorToInsert = new Account();
            vendorToInsert = (Account) setVendorFields(vendorObj);
            
            List<Account> vendorList = [SELECT Id FROM Account WHERE Id =: vendorToInsert.Id AND Claims_for_Service_Work__c = true limit 1];
            if (vendorList.size() > 0 && !vendorObj.IsClaimsForServiceWork) {
                List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c WHERE Provider__c =: vendorToInsert.Id AND SO_Status__c != 'Invoiced' limit 1];
                if (soHeaderList.size() > 0 ) {
                    throw new BlackpurlException('Vendor has active third-party jobs, cannot change this setting.'); 
                }
            } 
            if(vendorToInsert.Name != null ) {
                Boolean isInsert = String.isBlank(vendorToInsert.Id);
                if(!isInsert) {
                    CustomerTriggerHelper.isBypassValidation = true;
                }
                upsert vendorToInsert;

                // upsert markup data
			    upsertReatilMarkupData(vendorToInsert.Id, vendorObj);
                
                // Create Activity History in case of Insert.
                if(isInsert && !Test.isRunningTest()) {
                    ActivityHistory.createActivityHistory('Add Vendor', 'Vendor', vendorToInsert.Id, 'Vendor', vendorToInsert.Id, null);
                }
            }
            String vendorId = vendorToInsert.Id;
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('Id', vendorId);
            gen.writeStringField('VendorName', vendorToInsert.Name);
            gen.writeEndObject();
            return BPUtility.getEncodedString(gen.getAsString());
        }catch(exception ex){
            if(ex.getMessage().containsIgnoreCase(Constants.restrictionErrorForFXCodeChanges)) {
                throw new BlackPurlException(Constants.restrictionErrorForFXCodeChanges);
            } else {
                throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
            }
        } 
    }

    private static void upsertReatilMarkupData(String vendorId, Vendor vendorObj) {
        if(vendorObj.RetailEscalator == null || !vendorObj.IsCalculatePartRetailPrice) return;
        List<Escalator__c> escList = [SELECT Type__c FROM Escalator__c WHERE Vendor__c = :vendorId AND Type__c = :EscalatorUtil.TYPE_RETAIL LIMIT 1];
		Escalator__c escRecToUpsert = EscalatorService.setMarkupData(vendorObj.RetailEscalator, (escList.size() > 0 ? escList[0] : null), null, vendorId, EscalatorUtil.TYPE_RETAIL);
		if(escRecToUpsert != null) DMLUtility.upsertSobjectList('Escalator__c', escRecToUpsert);
    }
    
    /**
     * Name: getOtherSimilarVendor
     * Desc: 
     * @param:  
     * @return:  
    **/
   @RemoteAction
    global static String getOtherSimilarVendor(String vendorJSONString){
        vendorJSONString = BPUtility.getDecodedString(vendorJSONString);
        
        try{
            Vendor vendorObj = (Vendor) System.JSON.deserialize(vendorJSONString, Vendor.class);
            Account vendorRecordFilterValue = (Account) setVendorFields(vendorObj);
            List<Account> vendors = SOQLUtil.getOtherSimilarVendor(vendorRecordFilterValue);
            List<VendorSuggestion> vendorSuggestionList = new List<VendorSuggestion>();
            for(Account vendorRec : vendors) {
                if(vendorRecordFilterValue.Name != null && vendorRec.Name ==  vendorRecordFilterValue.Name) {
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 1));
                    continue;
                } else if(vendorRecordFilterValue.Name != null && vendorRecordFilterValue.Name.length() > 1 && vendorRec.Name.subString(0,1) == vendorRecordFilterValue.Name.subString(0,1)) {
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 2));
                    continue;
                }
                if((vendorRec.Work_Email__c != null && vendorRec.Work_Email__c != '' && (vendorRec.Work_Email__c == vendorRecordFilterValue.Work_Email__c ||
                                                                                                  vendorRec.Work_Email__c == vendorRecordFilterValue.Other_Email__c)) ||
                            
                        (vendorRec.Other_Email__c != null && vendorRec.Other_Email__c != '' && (vendorRec.Other_Email__c == vendorRecordFilterValue.Other_Email__c ||
                                                                                                     vendorRec.Other_Email__c == vendorRecordFilterValue.Work_Email__c))) {
                    
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 3));
                    continue;
                }
                if( (vendorRec.Work_Number__c != null && vendorRec.Work_Number__c != '' && (vendorRec.Work_Number__c == vendorRecordFilterValue.Work_Number__c || 
                                                                                                    vendorRec.Work_Number__c == vendorRecordFilterValue.Mobile__c))  ||
                                                                                                     
                        (vendorRec.Mobile__c != null && vendorRec.Mobile__c != '' && (vendorRec.Mobile__c == vendorRecordFilterValue.Mobile__c ||
                                                                                          vendorRec.Mobile__c == vendorRecordFilterValue.Work_Number__c ))) {
                            
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 4));
                    continue;
                }
                if((vendorRec.Facebook__c != null && vendorRec.Facebook__c != '' && vendorRec.Facebook__c == vendorRecordFilterValue.Facebook__c) || 
                        (vendorRec.Twitter__c != null && vendorRec.Twitter__c != '' && vendorRec.Twitter__c == vendorRecordFilterValue.Twitter__c) || 
                        (vendorRec.LinkedIn__c != null && vendorRec.LinkedIn__c != '' && vendorRec.LinkedIn__c == vendorRecordFilterValue.LinkedIn__c)) {
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 5));
                    continue;
                }
                String billingStreet = (vendorRec.BillingStreet == null ) ? '' : vendorRec.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                String filterBillingStreet = (vendorRecordFilterValue.BillingStreet == null ) ? '' : vendorRecordFilterValue.BillingStreet;
                List<String> filterBSList = filterBillingStreet.split('\n');
                String filterBillingStreet1 = (filterBSList.size() > 0) ? filterBSList[0] : '';
                if(filterBillingStreet1 != '' && filterBillingStreet1 != null && filterBillingStreet1 != 'null' && filterBillingStreet1 == billingStreet1) {
                    vendorSuggestionList.add(new VendorSuggestion(vendorRec, 6));
                }
            }
            vendorSuggestionList.sort();
            Integer listSizeLimit = 7;
            if(vendorSuggestionList.size() > listSizeLimit) {
                List<VendorSuggestion> vendorSuggestionLimitedList = new List<VendorSuggestion>();
                for(Integer i = 0 ; i < listSizeLimit ; i++) {
                    vendorSuggestionLimitedList.add(vendorSuggestionList[i]);
                }
                vendorSuggestionList = new List<VendorSuggestion>();
                vendorSuggestionList.addAll(vendorSuggestionLimitedList);
            }
            return BPUtility.getEncodedString(System.JSON.serialize(vendorSuggestionList));
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        } 
    }
    
    
    /**
     * Name: setCustomerfields
     * Desc: 
     * @param:  
     * @return:  
    **/
    private static Sobject setVendorFields(Vendor vendorObj){
        try{
            SObject vendorToInsert = new Account();
            vendorToInsert.put('Name', vendorObj.VendorName);
            vendorToInsert.put('Email__c', vendorObj.HomeEmail);
            vendorToInsert.put('Work_Email__c', vendorObj.WorkEmail);
            vendorToInsert.put('Other_Email__c', vendorObj.OtherEmail);
            vendorToInsert.put('Home_Number__c', vendorObj.HomeNumber);
            vendorToInsert.put('Mobile__c', vendorObj.OtherPhone);
            vendorToInsert.put('Work_Number__c', vendorObj.WorkNumber);
            vendorToInsert.put('Fax', vendorObj.Fax);
            vendorToInsert.put('Active__c', vendorObj.Active);
            vendorToInsert.put('Is_Vendor__c', vendorObj.IsVendor);
            vendorToInsert.put('SA_same_as_BA__c', vendorObj.IsBothAddressSame);
            vendorToInsert.put('Home_Number_SMS__c', vendorObj.HomeNumberSMS);
            vendorToInsert.put('Work_Number_SMS__c', vendorObj.WorkNumberSMS);
            vendorToInsert.put('Mobile_Number_SMS__c', vendorObj.MobileNumberSMS);
            
            vendorToInsert.put('Is_Calculate_Part_Retail_Price__c', vendorObj.IsCalculatePartRetailPrice);
            vendorToInsert.put('Retail_Base_Value__c', vendorObj.RetailBaseValue);
            vendorToInsert.put('Retail_Rounding__c', vendorObj.RetailRounding);
	    	vendorToInsert.put('Retail_Round_To__c', vendorObj.RetailRoundTo);
	    	vendorToInsert.put('Vendor_Account_Type__c', vendorObj.AccountTypeId);
            
            if(vendorObj.PreferredEmail == 'HomeEmail') {
                vendorToInsert.put('Preferred_Email__c', vendorObj.HomeEmail);
            } else if(vendorObj.PreferredEmail == 'WorkEmail') {
                vendorToInsert.put('Preferred_Email__c', vendorObj.WorkEmail);
            } else if(vendorObj.PreferredEmail == 'OtherEmail') {
                vendorToInsert.put('Preferred_Email__c', vendorObj.OtherEmail);
            } else if(vendorObj.PreferredEmail == '') {
                vendorToInsert.put('Preferred_Email__c', null);
            }
            
            if(vendorObj.PreferredPhone == 'HomeNumber') {
                vendorToInsert.put('Preferred_Phone__c', vendorObj.HomeNumber);
            } else if(vendorObj.PreferredPhone == 'OtherPhone') {
                vendorToInsert.put('Preferred_Phone__c', vendorObj.OtherPhone);
            } else if(vendorObj.PreferredPhone == 'WorkNumber') {
                vendorToInsert.put('Preferred_Phone__c', vendorObj.WorkNumber);
            } else if(vendorObj.PreferredPhone == '') {
                vendorToInsert.put('Preferred_Phone__c', null);
            } 
            
            if(vendorObj.PreferredSMS == 'HomeNumber') {
                vendorToInsert.put('Preferred_SMS__c', vendorObj.HomeNumber);
            } else if(vendorObj.PreferredSMS == 'OtherPhone') {
                vendorToInsert.put('Preferred_SMS__c', vendorObj.OtherPhone);
            } else if(vendorObj.PreferredSMS == 'WorkNumber') {
                vendorToInsert.put('Preferred_SMS__c', vendorObj.WorkNumber);
            } else if(vendorObj.PreferredSMS == '') {
                vendorToInsert.put('Preferred_SMS__c', null);
            } 
            
            vendorToInsert.put('Facebook__c', vendorObj.FacebookLink);
            vendorToInsert.put('Twitter__c', vendorObj.TwitterLink);
            vendorToInsert.put('LinkedIn__c', vendorObj.LinkedInLink);
            vendorToInsert.put('Website', vendorObj.Website);
            
            if(vendorObj.BillingStreet1 == null && vendorObj.BillingStreet2 != null) {
                vendorToInsert.put('BillingStreet', '\n' + vendorObj.BillingStreet2);
            } else if(vendorObj.BillingStreet2 == null && vendorObj.BillingStreet1 != null) {
                vendorToInsert.put('BillingStreet', vendorObj.BillingStreet1);
            } else if(vendorObj.BillingStreet1 != null && vendorObj.BillingStreet2 != null) {
                vendorToInsert.put('BillingStreet', vendorObj.BillingStreet1 + '\n' + vendorObj.BillingStreet2);
            }
            vendorToInsert.put('BillingCity', vendorObj.BillingCity);
            vendorToInsert.put('BillingCountry', vendorObj.BillingCountry);
            vendorToInsert.put('BillingState', vendorObj.BillingState);
            vendorToInsert.put('BillingPostalCode', vendorObj.BillingPostalCode);
            
            if(!vendorObj.IsBothAddressSame) {
                if(vendorObj.ShippingStreet1 == null && vendorObj.ShippingStreet2 != null) {
                    vendorToInsert.put('ShippingStreet', '\n' + vendorObj.ShippingStreet2);
                } else if(vendorObj.ShippingStreet2 == null && vendorObj.ShippingStreet1 != null) {
                    vendorToInsert.put('ShippingStreet', vendorObj.ShippingStreet1 + '\n');
                } else if(vendorObj.ShippingStreet1 != null && vendorObj.ShippingStreet2 != null) {
                    vendorToInsert.put('ShippingStreet', vendorObj.ShippingStreet1 + '\n' + vendorObj.ShippingStreet2);
                }
                vendorToInsert.put('ShippingCity', vendorObj.ShippingCity);
                vendorToInsert.put('ShippingCountry', vendorObj.ShippingCountry);
                vendorToInsert.put('ShippingState', vendorObj.ShippingState);
                vendorToInsert.put('ShippingPostalCode', vendorObj.ShippingPostalCode);
            } else {
                vendorToInsert.put('ShippingStreet', vendorToInsert.get('BillingStreet'));
                vendorToInsert.put('ShippingCity', vendorObj.BillingCity);
                vendorToInsert.put('ShippingCountry', vendorObj.BillingCountry);
                vendorToInsert.put('ShippingState', vendorObj.BillingState);
                vendorToInsert.put('ShippingPostalCode', vendorObj.BillingPostalCode);
            }
            
            vendorToInsert.put('Price_Level__c', vendorObj.SalesPriceLevelId);
            vendorToInsert.put('Sales_Tax__c', vendorObj.SalesTaxLevelId);
            vendorToInsert.put('Purchase_Tax__c', vendorObj.PurchaseTaxLevelId);
            vendorToInsert.put('Part_Category_Default__c', vendorObj.PartCategoryId);
            vendorToInsert.put('Merchandise_Category_Default__c', vendorObj.MerchandiseCategoryId);
	    	// Boolean Checkbox
            vendorToInsert.put('Claims_for_Service_Work__c', vendorObj.IsClaimsForServiceWork);
            vendorToInsert.put('Flooring_Company__c', vendorObj.IsFlooringCompany);
            vendorToInsert.put('Part_Purchases__c', vendorObj.IsPartPurchases);
            vendorToInsert.put('Merchandise_Purchases__c', vendorObj.IsMerchandisePurchases);
	    	vendorToInsert.put('Sublet_Purchases__c', vendorObj.IsSubletPurchases);
            vendorToInsert.put('Unit_Purchases__c', vendorObj.IsUnitPurchases);
            vendorToInsert.put('Warranty_Plan_Sales_on_Unit_Deals__c', vendorObj.IsWarrantyPlans);
            vendorToInsert.put('Finance_Company__c', vendorObj.IsFinanceCompany);
            if(vendorObj.IsFinanceCompany != null && vendorObj.IsFinanceCompany && GeneralConfiguration.getConfigurations().DF_commission_in_FI_company_payments__c && vendorObj.IsCommissionNotIncludedInFIPayments != null) {
                vendorToInsert.put('Commissions_not_in_finance_payments__c', vendorObj.IsCommissionNotIncludedInFIPayments);
            } else {
                vendorToInsert.put('Commissions_not_in_finance_payments__c', false);
            }
            vendorToInsert.put('Financing_Products__c', vendorObj.IsFinancingProducts);
            vendorToInsert.put('AccountNumber', vendorObj.VendorAccountNumber);
            vendorToInsert.put('Vendor_Tax_Id__c', vendorObj.VendorTaxId);
            if(vendorObj.IsForeignVendor != null) {
                vendorToInsert.put('Country__c', vendorObj.VendorCountry);
                vendorToInsert.put('Is_Foreign_Vendor__c', vendorObj.IsForeignVendor);
            }
            
            if(vendorObj.Id != null && vendorObj.Id != '') {
                
                vendorToInsert.put('Id', vendorObj.Id);
            }   
            return vendorToInsert;
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        }   
    }
	/** Method to get data of all account type present in appication
	   * CtrlClass -AccountTypeCtrl
	   * @Return - String(Json containing all account type data)
	   */
	   @RemoteAction
	   public static String getAllAccountTypeForVendor() {
	    try {
	       return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllAccountTypeForVendor()));
	    } catch(Exception e) {
	           throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
	       }
	   }

    @RemoteAction
    public static String saveCustomVOExport(String customVOExportJSON) {
        return BPUtility.getEncodedString(VendorOrderService.saveCustomVOExport(BPUtility.getDecodedString(customVOExportJSON)));
    }

    @RemoteAction
    global static String getCustomVOExportByVendorId(String vendorId) {
        return BPUtility.getEncodedString(VendorOrderService.getVOExportByVendorId(BPUtility.getDecodedString(vendorId)));
    }

    @RemoteAction
    global static String getBPExportFormatList() {
        return BPUtility.getEncodedString(GenericExportService.getBPExportFormatList());
    }

    @RemoteAction
    global static String getBPColumnNameList() {
        return BPUtility.getEncodedString(GenericExportService.getBPColumnNameList('VO'));
    }

    @RemoteAction
    global static String saveDefaultVOExportFormat(String vendorId, String exportFormatId) {
        return BPUtility.getEncodedString(VendorOrderService.saveDefaultVOExportFormat(BPUtility.getDecodedString(vendorId), BPUtility.getDecodedString(exportFormatId)));
    }
    
    @RemoteAction
    global static String getActiveForeignCurrencyList() {
        return BPUtility.getEncodedString(system.JSON.serialize(ForeignExchangeUtil.getActiveForeignCurrencyList()));
    }
}
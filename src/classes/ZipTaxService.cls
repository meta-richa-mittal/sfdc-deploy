public without sharing class ZipTaxService {

    public static List<TaxRateWrapper.TaxRate> getTaxRates(String customerId) {
        ZipTaxWrapper zipTaxResObj;
        Map<String, String> params;
        if(String.isNotBlank(customerId)) {
            List<Account> customerList = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingState, BillingCountry FROM Account WHERE Id = :customerId];
            if(customerList.isEmpty()) throw new BlackPurlException('Customer not found');
            if(String.isNotBlank(customerList[0].BillingStreet) && String.isNotBlank(customerList[0].BillingPostalCode) && String.isNotBlank(customerList[0].BillingCity) && (String.isNotBlank(customerList[0].BillingState))) {
                List<String> bsList = customerList[0].BillingStreet.split('\n');
                String BillingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                string address = BillingStreet1 + ', ' + customerList[0].BillingCity + ', ' + customerList[0].BillingState + ' ' + customerList[0].BillingPostalCode;
                address = (address.replace('\n', ', ')).replace(' ', '%20');
                params = new Map<String, String>{'address' => address};
            } else if (String.isNotBlank(customerList[0].BillingPostalCode)) {
                params = new Map<String, String>{'postalcode' => customerList[0].BillingPostalCode};
            }
        } else {
            List<Business_Profile__c> businessProfileList = [SELECT Id, Business_Street_Address1__c, Business_Postal_Code__c, Business_City__c, Business_State__r.Display_Name__c FROM Business_Profile__c];
            if(businessProfileList.isEmpty()) throw new BlackPurlException('Business Profile not found');
            if(String.isNotBlank(businessProfileList[0].Business_Street_Address1__c) && String.isNotBlank(businessProfileList[0].Business_Postal_Code__c) && String.isNotBlank(businessProfileList[0].Business_City__c) && String.isNotBlank(businessProfileList[0].Business_State__c)) {
                string address = (String.isNotBlank(businessProfileList[0].Business_Street_Address1__c) ? businessProfileList[0].Business_Street_Address1__c +  ', ' : '') + businessProfileList[0].Business_City__c + ', ' + businessProfileList[0].Business_State__r.Display_Name__c + ' ' + businessProfileList[0].Business_Postal_Code__c;
                address = (address.replace('\n', ', ')).replace(' ', '%20');
                params = new Map<String, String>{'address' => address};
            } else if (String.isNotBlank(businessProfileList[0].Business_Postal_Code__c)) {
                params = new Map<String, String>{'postalcode' => businessProfileList[0].Business_Postal_Code__c};
            } else {
                throw new BlackPurlException('Business Profile address is not valid. Please correct business profile address.');
            }
        }
        if(params != null) {
            HTTPResponse response = doCallout(params);
            zipTaxResObj = handleResponse(response);
        }
        
        return getTaxRateListByZipTaxObj(zipTaxResObj);
    }

    public static void populateStoreAutomatedTaxRates() {
        DMLUtility.upsertSobjectList('Sales_Tax_Item__c', createTaxRateRecFromAutomatedTaxRates(getTaxRates(null)));
    }

    public static List<Sales_Tax_Item__c> createTaxRateRecFromAutomatedTaxRates(List<TaxRateWrapper.TaxRate> zipTaxRates) {
        if(zipTaxRates.isEmpty()) throw new BlackPurlException('No tax rates found for the given store address.'); 

        List<Sales_Tax_Item__c> salesTaxRateListToUpsert = new List<Sales_Tax_Item__c>();

        Map<String, Sales_Tax_Item__c> salesTaxNameToRecMap = new Map<String, Sales_Tax_Item__c>();
        for(Sales_Tax_Item__c salesTaxRec : [SELECT Id, Name__c, Active__c, Rate_Type__c, Rate__c, Category__c, Category__r.Name, Tax_Type__c, Is_Automated__c, Automated_Tax_Rate_Name__c FROM Sales_Tax_Item__c WHERE Is_Automated__c = true]) {
            salesTaxRec.Active__c = false;
            salesTaxNameToRecMap.put(salesTaxRec.Name__c, salesTaxRec);
        }

        for(TaxRateWrapper.TaxRate taxRate : zipTaxRates) {
            if(salesTaxNameToRecMap.containsKey(taxRate.TaxName)) {
                Sales_Tax_Item__c salesTaxRec = salesTaxNameToRecMap.get(taxRate.TaxName);
                salesTaxRec.Rate__c = taxRate.TaxRate;
                salesTaxRec.Automated_Tax_Rate_Name__c = taxRate.AutomatedTaxName;
                salesTaxRec.Active__c = true;
                salesTaxNameToRecMap.remove(taxRate.TaxName);
                salesTaxRateListToUpsert.add(salesTaxRec);
            } else if(taxRate.TaxRate != null) {
                Sales_Tax_Item__c salesTaxRec = new Sales_Tax_Item__c();
                salesTaxRec.Name__c = taxRate.TaxName;
                salesTaxRec.Forms_Label__c = (taxRate.TaxName).containsIgnoreCase(ZipTaxUtil.DISTRICT_TAX_PREFIX) ? ZipTaxUtil.DISTRICT_TAX : taxRate.TaxName;
                salesTaxRec.Active__c = true;
                salesTaxRec.Rate_Type__c = taxRate.RateType;
                salesTaxRec.Rate__c = taxRate.TaxRate;
                salesTaxRec.Category__c = taxRate.CategoryId;
                salesTaxRec.Tax_Type__c = taxRate.TaxType;
                salesTaxRec.Is_Automated__c = true;
                salesTaxRec.Automated_Tax_Rate_Name__c = taxRate.AutomatedTaxName;
                salesTaxRateListToUpsert.add(salesTaxRec);
            }
        }
        if(salesTaxNameToRecMap != null && !salesTaxNameToRecMap.isEmpty()) {
            salesTaxRateListToUpsert.addAll(salesTaxNameToRecMap.values());
        }
        return salesTaxRateListToUpsert;
    }

    private static List<TaxRateWrapper.TaxRate> getTaxRateListByZipTaxObj(ZipTaxWrapper zipTaxResObj) {
        List<TaxRateWrapper.TaxRate> taxRateList = new List<TaxRateWrapper.TaxRate>();
        if(zipTaxResObj != null) {
            String defaultTaxCatId;
            List<Category__c> defaultTaxCatList = CategoryService.getFilteredCategory(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_TAX});
            if(!defaultTaxCatList.isEmpty()) defaultTaxCatId = defaultTaxCatList[0].Id;
            if(zipTaxResObj.stateSalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.STATE_TAX, (zipTaxResObj.stateSalesTax * 100) , zipTaxResObj.geoState, defaultTaxCatId));
            if(zipTaxResObj.countySalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.COUNTY_TAX, (zipTaxResObj.countySalesTax * 100) , (String.isNotBlank(zipTaxResObj.geoState) ? (zipTaxResObj.geoState + ';' + zipTaxResObj.geoCounty) : zipTaxResObj.geoCounty), defaultTaxCatId));
            String cityTaxName = String.isNotBlank(zipTaxResObj.geoState) ? (zipTaxResObj.geoState) : '';
            cityTaxName += String.isNotBlank(zipTaxResObj.geoCounty) ? (';' + zipTaxResObj.geoCounty) : '';
            cityTaxName += String.isNotBlank(zipTaxResObj.geoCity) ? (';' + zipTaxResObj.geoCity) : '';
            if(zipTaxResObj.citySalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.CITY_TAX, (zipTaxResObj.citySalesTax * 100) , cityTaxName, defaultTaxCatId));
            if(zipTaxResObj.district1SalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.DISTRICT_1_TAX, (zipTaxResObj.district1SalesTax * 100) , cityTaxName + ';' + zipTaxResObj.district1Code, defaultTaxCatId));
            if(zipTaxResObj.district2SalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.DISTRICT_2_TAX, (zipTaxResObj.district2SalesTax * 100) , cityTaxName + ';' + zipTaxResObj.district2Code, defaultTaxCatId));
            if(zipTaxResObj.district3SalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.DISTRICT_3_TAX, (zipTaxResObj.district3SalesTax * 100) , cityTaxName + ';' + zipTaxResObj.district3Code, defaultTaxCatId));
            if(zipTaxResObj.district4SalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.DISTRICT_4_TAX, (zipTaxResObj.district4SalesTax * 100) , cityTaxName + ';' + zipTaxResObj.district4Code, defaultTaxCatId));
            if(zipTaxResObj.district5SalesTax != null) taxRateList.add(getTaxRateObject(ZipTaxUtil.DISTRICT_5_TAX, (zipTaxResObj.district5SalesTax * 100) , cityTaxName + ';' + zipTaxResObj.district5Code, defaultTaxCatId));
        }
        return taxRateList;
    }

    private static TaxRateWrapper.TaxRate getTaxRateObject(String taxName, Decimal taxRate, String automatedTaxName, String categoryId) {
        TaxRateWrapper.TaxRate taxRateWrapper = new TaxRateWrapper.TaxRate();
		taxRateWrapper.TaxName = taxName;
		taxRateWrapper.IsActive = true;
		taxRateWrapper.RateType = 'Fixed rate';
		taxRateWrapper.TaxRate = taxRate;
		taxRateWrapper.CategoryId = categoryId;
		taxRateWrapper.TaxType = 'Sell';
		taxRateWrapper.IsAutomated = true;
		taxRateWrapper.AutomatedTaxName = automatedTaxName;
        return taxRateWrapper;
    }

    public static HTTPResponse doCallout(Map<String, String> params) {
        List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(ZipTaxUtil.ZIP_TAX, new Map<String, String>{ZipTaxUtil.FETCH_TAX => null}, false);
        if(ifwList.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');
        if(params != null) {
            params.put('key', ifwList[0].Consumer_Key__c);
        }
        if(ifwList[0].IFW_IntegrationConfigItems__r.isEmpty()) throw new BlackPurlException('IFW Config items for Organization not defined');
        return BaseIntegration.performCallout(ifwList[0], ifwList[0].IFW_IntegrationConfigItems__r[0], null, getReqHeaders(), params, ZipTaxUtil.FETCH_TAX);        
        
    }


    public static ZipTaxWrapper handleResponse(HTTPResponse response) {
        DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        if(response.getStatusCode() == 200) {
            ZipTaxResponseWrapper zipTaxResObj = (ZipTaxResponseWrapper) JSON.deserialize(response.getBody(), ZipTaxResponseWrapper.class);
            if(zipTaxResObj != null && zipTaxResObj.results != null && !zipTaxResObj.results.isEmpty()) {
                if(zipTaxResObj.results.size() == 1) {
                    if(String.isBlank(zipTaxResObj.results[0].geoState) && String.isBlank(zipTaxResObj.results[0].geoPostalCode)) {
                        new LogService().createErrorLog('ZipTaxService' , 'handleResponse()', 'No results found for the given address', null, null, null, ZipTaxUtil.ZIP_TAX, true, 'info');
                    } else {
                        return zipTaxResObj.results[0];
                    }
                } else {
                    new LogService().createErrorLog('ZipTaxService' , 'handleResponse()', 'Multiple results found for the given address', null, null, null, ZipTaxUtil.ZIP_TAX, true, 'info');
                }
            } else {
                new LogService().createErrorLog('ZipTaxService' , 'handleResponse()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, ZipTaxUtil.ZIP_TAX, true, 'Error');
            }
        } else {
            new LogService().createErrorLog('ZipTaxService' , 'handleResponse()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, ZipTaxUtil.ZIP_TAX, true, 'Error');
        }
        return null;
    }

    public static List<CustomHttpHeaderWrapper> getReqHeaders () {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(new CustomHttpHeaderWrapper('Content-Type', 'application/json'));
        return headerList;
    }

    public class ZipTaxResponseWrapper {
        public String version;
        public String rCode;
        public List<ZipTaxWrapper> results;
    }
}
/**
 * Author: Nidhi Sharma
 * Since: 13 Nov, 2019
 * Name: TaxManagementCtrl
 * Description: 
**/
global without sharing class TaxManagementCtrl {
    
    global TaxManagementCtrl (NewHomePageCtrl controller){}
    public TaxManagementCtrl() {}
    
    @RemoteAction
    global static String getAllTaxRates() {
        return 'Success';
    }

    @RemoteAction
    global static String getTaxRatesAndCodes(String filterString) {
        try {
            TaxManagementFilterWrapper filterObj = (TaxManagementFilterWrapper) System.JSON.deserialize(BPUtility.getDecodedString(filterString), TaxManagementFilterWrapper.class);
            return TaxManagementService.getTaxRatesAndCodes(filterObj);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getTaxRatesAndCodesCount(String filterString) {
        try {
            TaxManagementFilterWrapper filterObj = (TaxManagementFilterWrapper) System.JSON.deserialize(BPUtility.getDecodedString(filterString), TaxManagementFilterWrapper.class);
            return BPUtility.getEncodedString(System.JSON.serialize(TaxManagementService.getTaxRatesAndCodesCount(filterObj)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String deleteTaxRate(String taxRateId) {
    	taxRateId = BPUtility.getDecodedString(taxRateId);
        try {
        	TaxManagementService.deleteTaxRate(taxRateId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveTaxRate(String taxRateJSONString) {
    	taxRateJSONString = BPUtility.getDecodedString(taxRateJSONString);
        try {
        	TaxManagementService.saveTaxRate(taxRateJSONString);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getTaxCategories() {
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_TAX})));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getAllTaxCodes() {
        return 'Success';
    }
    
    @RemoteAction
    global static String saveTaxCode(String taxCodeJSONString) {
    	taxCodeJSONString = BPUtility.getDecodedString(taxCodeJSONString);
        try {
        	TaxManagementService.saveTaxCode(taxCodeJSONString);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String assignTaxRates(String taxCodeJSONString) {
    	taxCodeJSONString = BPUtility.getDecodedString(taxCodeJSONString);
        try {
        	TaxManagementService.assignTaxRates(taxCodeJSONString);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String deleteTaxCode(String taxCodeId) {
    	taxCodeId = BPUtility.getDecodedString(taxCodeId);
        try {
        	TaxManagementService.deleteTaxCode(taxCodeId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
}
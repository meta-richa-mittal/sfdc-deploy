/**
 * Author: Nidhi Sharma
 * Since: March 26, 2024
 * Name: TaxActivityAndSettingCtrl
 * Description: 
**/
global without sharing class TaxActivityAndSettingCtrl {
    
    global TaxActivityAndSettingCtrl (NewHomePageCtrl controller){}
    public TaxActivityAndSettingCtrl() {}

    @RemoteAction
    public static String getTaxActivityReportByEntityName(String filterJson) {
        return BPUtility.getEncodedString(System.Json.serialize(TaxActivityAndSettingService.getTaxActivityReportByEntityName(BPUtility.getDecodedString(filterJson))));
    }
    
    @RemoteAction
    public static String getTaxSettingMasterData() {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getTaxSettingMasterData()));
    }

    @RemoteAction
    public static String getAllActiveSalesTaxWithExemptions() {
        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllActiveSalesTax()));
    }
    
    @RemoteAction
    public static String getAccountTypeDetailsById(String accTypeId) {
        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getRecForAccountType(BPUtility.getDecodedString(accTypeId))));
    }

    @RemoteAction
    public static String getAllAccountTypeData() {
        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllAccountTypeData()));
    }
    
    @RemoteAction
    public static String getGeneralTaxSettings() {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getGeneralTaxSettings()));
    }
    
    @RemoteAction
    public static String getAutomaticTaxRateControls() {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getAutomaticTaxRateControls()));
    }
    
    @RemoteAction
    public static String getAccruedTaxControls() {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getAccruedTaxControls()));
    }
    
    @RemoteAction
    public static String getDefaultApplicableTaxSettings() {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getDefaultApplicableTaxSettings()));
    }

    @RemoteAction
    public static void saveTaxControlsAndSettings(String taxSettingJsonString) {
        TaxActivityAndSettingService.saveTaxControlsAndSettings(BPUtility.getDecodedString(taxSettingJsonString));
    }

    @RemoteAction
    public static void saveAccountType(String accountTypeJsonStr) {
        AccountTypeService.addEditAccountType(BPUtility.getDecodedString(accountTypeJsonStr));
    }

    @RemoteAction
    global static String getTaxRates(String filterString) {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxManagementService.getTaxRates((TaxManagementFilterWrapper) System.JSON.deserialize(BPUtility.getDecodedString(filterString), TaxManagementFilterWrapper.class))));
    }

    @RemoteAction
    global static String deleteTaxRate(String taxRateId) {
    	TaxManagementService.deleteTaxRate(BPUtility.getDecodedString(taxRateId));
        return '';
    }
    
    @RemoteAction
    global static String saveTaxRate(String taxRateJSONString) {
    	TaxManagementService.saveTaxRate(BPUtility.getDecodedString(taxRateJSONString));
        return '';
    }

    @RemoteAction
    global static String getTaxCodes(String filterString) {
        return BPUtility.getEncodedString(System.JSON.serialize(TaxManagementService.getTaxCodes((TaxManagementFilterWrapper) System.JSON.deserialize(BPUtility.getDecodedString(filterString), TaxManagementFilterWrapper.class))));
    }

    @RemoteAction
    global static void deleteTaxCode(String taxCodeId) {
    	TaxManagementService.deleteTaxCode(BPUtility.getDecodedString(taxCodeId));
    }
    
    @RemoteAction
    global static void saveTaxCode(String taxCodeJSONString) {
    	TaxManagementService.saveTaxCode(BPUtility.getDecodedString(taxCodeJSONString));
    }

    // deprecated
    @RemoteAction
    global static void deleteAssignedTaxRate(String taxCodeId, String taxRateId) {}

    @RemoteAction
    global static String getTaxCategories() {
       return BPUtility.getEncodedString(System.JSON.serialize(CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_TAX})));
    }

    @RemoteAction
    global static String refreshAutomatedTaxRates() {
        ZipTaxService.populateStoreAutomatedTaxRates();
        return BPUtility.getEncodedString(System.JSON.serialize(TaxActivityAndSettingService.getAutomaticTaxRateControls()));
    }

    global static void enableAutomaticTaxRates() {
        ZipTaxUtil.createZipTaxIfwAndItem();
        TaxActivityAndSettingService.enableAutomaticTaxRates();
    }
}
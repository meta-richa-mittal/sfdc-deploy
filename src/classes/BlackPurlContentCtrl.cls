/**
 * Author: Ashish Garg
 * Since: Sept. 24, 2014
 * Name: BlackPurlContentCtrl
 * Description: Conroller class for BlackPurlContent page
**/
global without sharing class BlackPurlContentCtrl {
    
    global BlackPurlContentCtrl(){}
    
    @RemoteAction
    global static String getCategoryPicklistValues() {return '';}
    
    @RemoteAction
    global static String getPriceLevelPriceBookPicklistValues() {return '';}
    
    @RemoteAction
    global static String getCategoryTypePicklistValues() {return '';}
    
    @RemoteAction
    global static String getJSONForAllSalesTax() {return '';}
    
    @RemoteAction
    global static String getJSONForSalesTaxWrapper(String SalesTaxId) {return '';}
    
    @RemoteAction
    global static String generateJSONForCountries(Integer currentNoOfCountryInGrid) {return '';}
    
    @RemoteAction
    global static String getJSONForStateByCountry(String countryId) {return '';}
    
    @RemoteAction
    global static String generateJSONForAllCountries() {return '';}
    
    @RemoteAction
    global static String getJSONForAllPriceLevels() {return '';}
    
    @RemoteAction
    global static String getJSONForAllCustomer(Integer currentNoOfCustomersInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String getJSONForParts(Integer currentNoOfPartsInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    public static String getJSONForPartByPartId(String partId) {return '';}
    
    @RemoteAction
    global static String getJSONForObjectPicklistField(String objName, String fieldName) {return '';}
    
    @RemoteAction
    global static String getJSONForObjectRecordsPicklist(String objName, String displayFieldName) {return '';}
    
    @RemoteAction
    global static String getJSONForCategories(Integer currentNoOfCategoriesInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String getJSONForVendor(Integer currentNoOfVendorsInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String getJSONForUnitMakes(Integer currentNoOfUnitMakesInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String getJSONForUnitModelByUnitMakeId(String unitMakeId, Integer currentNoOfUnitModelsInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static boolean deleteSalesTax(String stId) {return null;}
    
    @RemoteAction 
    global static String deleteSalesTaxItem(String stiId) {return '';}
    
    @RemoteAction
    global static boolean deletePriceLevel(String plId) {return null;}
    
    @RemoteAction
    global static void saveSalesTaxJSON(String JSONString) {}
    
    @RemoteAction
    global static String saveSalesTaxJSONData(String JSONString) {return '';}
    
    @RemoteAction
    global static void savePriceLevelJSON(String JSONString) {}
    
    @RemoteAction
    global static String saveSalesTaxItemJSON(String JSONString) {return '';}
    
    @RemoteAction
    global static void saveCountryJSON(String JSONString) {}
    
    @RemoteAction
    global static void saveStateJSON(String JSONString) {}
    
    @RemoteAction
    global static string savePartJSON(String JSONString) {return '';}
    
    @RemoteAction
    global static Id saveCustomerJSON(String customerId, String typeOfCustomer, String JSONString) {return null;}
    
    @RemoteAction
    global static Id saveVendorJSON(String JSONString) {return null;}
    
    @RemoteAction
    global static void saveCategoryJSON(String JSONString) {}
    
    @RemoteAction
    global static void saveUnitMakeJSON(String JSONString) {}
    
    @RemoteAction
    global static void deleteUnitMakeJSON(String JSONString) {}
    
    @RemoteAction
    global static void saveUnitModelJSON(String JSONString) {}
    
    @RemoteAction
    global static String saveUnitModelSubmodelJSON(String JSONString) {return '';}
    
    @RemoteAction
    global static void deleteUnitModelJSON(String JSONString) {}
    
    @RemoteAction
    global static String increaseCountries(Integer currentCountryInGrid) {return '';}
    
    @RemoteAction
    global static String increaseCustomer(Integer currentCustomerInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String increaseVendor(Integer currentVendorInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String increaseParts(Integer currentPartsInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String increaseCategories(Integer currentCategoriesInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String increaseUnitMakes(Integer currentUnitMakesInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String increaseUnitModels(String unitMakeId, Integer currentUnitModelsInGrid, Integer dropDownNumber, Boolean isInactiveIncluded, String filterJSON) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredCustomer(String searchString, String fieldName, Boolean isInactiveIncluded) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredParts(String searchString, String fieldName) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredCategory(String searchString, String fieldName) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredVendor(String searchString, String fieldName, Boolean isInactiveIncluded) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredUnitMakes(String searchString, String fieldName, Boolean isInactiveIncluded) {return '';}
    
    @RemoteAction
    global static String getJSONForFilteredUnitModels(String unitMakeId, String searchString, String fieldName, Boolean isInactiveIncluded) {return '';}
}
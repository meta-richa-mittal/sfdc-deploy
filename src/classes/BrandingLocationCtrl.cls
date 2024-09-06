/**
* Author: Author: Nikhil Kumar Srivastava
* Since: May 22, 2019
* Name: BrandingLocationCtrl
* Description: Ctrl Apex class for Branding Location
**/
global without sharing class BrandingLocationCtrl {
	
	public BrandingLocationCtrl() {}
	global BrandingLocationCtrl(NewHomePageCtrl controller) {} 
	
	@RemoteAction
    global static String getDefaultBrandingLocation() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(BrandingLocationService.getDefaultBrandingLocation(), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
	
	@RemoteAction 
    global static String getBrandingLocationMasterData() { 
    	List<Country__c> countryList = SOQLUtil.getAllCountry();
        List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();
        
        COUFieldWrapper masterDataObj = new COUFieldWrapper(countryList, countryWrapperList, new List<Sales_Tax__c>(), 
        													new List<Price_Level__c>(), new List<Unit_Make__c>(), 
        													new List<Unit_Make__c>(), new List<Category__c>());
        return BPUtility.getEncodedString(System.JSON.serialize(masterDataObj, true));
    } 
     
	@RemoteAction
    global static String getAllBrandingLocationDetailList() {
    	
    	return null;
    }    
    @RemoteAction
    global static String getBusinessDetailOfAllBrandingLocations() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(BrandingLocationService.getBrandingLocation(new Map<String, String>(), true), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
	
    @RemoteAction
    global static String saveBrandingLocation(String brandingLocationJson) {
    	brandingLocationJson = BPUtility.getDecodedString(brandingLocationJson);
    	try {
	        return BPUtility.getEncodedString(BrandingLocationService.saveBrandingLocation(brandingLocationJson));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String deleteBrandingLocation(String brandingLocationId) {
    	brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
    	try {
	        return BPUtility.getEncodedString(BrandingLocationService.deleteBrandingLocation(brandingLocationId));  
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getBrandingLocationRecordById(String recordId) {
    	recordId = BPUtility.getDecodedString(recordId); 
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(BrandingLocationService.getBrandingLocation(new Map<String, String>{'Id' => recordId}, false), true));
    	} catch(Exception e) { 
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String isBrandingLocationActive() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(BrandingLocationService.getDefaultBrandingLocation(), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveLogoDimensions(String logoJson) {
    	logoJson = BPUtility.getDecodedString(logoJson);
    	try {
	        BrandingLocationService.saveLogoDimensions(logoJson);
            return BPUtility.getEncodedString('success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }  
}
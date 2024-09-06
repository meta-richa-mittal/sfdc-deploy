global without sharing class SystemSettingsController {
	
    @RemoteAction
    global static String getJSONForAllSalesTax() {return '';}
    
    @RemoteAction
    global static String getJSONForSalesTax(String salesTaxId) {return '';}
    
    @RemoteAction
    global static String getJSONForAllSalesTaxItem() {return '';}
    
    @RemoteAction
    global static String getJSONForSalesTaxItem(String salesTaxItemId) {return '';}
    
    @RemoteAction
    global static String getJSONForAllPriceLevels() {return '';}
    
    @RemoteAction
    global static String getJSONForRecentItem() {return '';}
    
    @RemoteAction
    global static String getJSONForSalesTaxWrapper(String salesTaxId) {return '';}
}
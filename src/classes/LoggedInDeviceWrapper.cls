/** 
* Author: Nidhi Sharma
* Since: Dec 17, 2018
* Name: LoggedInDeviceWrapper 
* Description: Wrapper class for Logged in device object.
**/
public without sharing class LoggedInDeviceWrapper {
    
    public String Id;
    public String UUID;
    public String CashDrawerId;
    public String CashDrawerName;
    public String BusinessLocationId;
    public String BusinessLocationName;
    
    public LoggedInDeviceWrapper(Logged_In_Device__c loggedInDeviceRec, String entity) {
    	this.Id = loggedInDeviceRec.Id;
    	this.UUID = loggedInDeviceRec.Name;
    	if(entity == Constants.BRANDING_LOCATION && String.isNotBlank(loggedInDeviceRec.Branding_Location__c)) {
    		this.BusinessLocationId = loggedInDeviceRec.Branding_Location__c;
    		this.BusinessLocationName = loggedInDeviceRec.Branding_Location__r.Business_Location_Name__c;
    	} else if(entity == Constants.CASH_DRAWER && String.isNotBlank(loggedInDeviceRec.Cash_Drawer__c) && loggedInDeviceRec.Cash_Drawer__r.Active__c) {
    		this.CashDrawerId = loggedInDeviceRec.Cash_Drawer__c;
    		this.CashDrawerName = loggedInDeviceRec.Cash_Drawer__r.Name;
    	}
    }
    
    public LoggedInDeviceWrapper(Logged_In_Device__c loggedInDeviceRec) {
    	this.Id = loggedInDeviceRec.Id;
    	this.UUID = loggedInDeviceRec.Name;
    	if(String.isNotBlank(loggedInDeviceRec.Cash_Drawer__c) && loggedInDeviceRec.Cash_Drawer__r.Active__c) {
    	this.CashDrawerId = loggedInDeviceRec.Cash_Drawer__c;
    	this.CashDrawerName = loggedInDeviceRec.Cash_Drawer__r.Name;
    }
    	if(String.isNotBlank(loggedInDeviceRec.Branding_Location__c)) {
    		this.BusinessLocationId = loggedInDeviceRec.Branding_Location__c;
    		this.BusinessLocationName = loggedInDeviceRec.Branding_Location__r.Business_Location_Name__c;
    	}
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> getLoggedInDeviceFieldsList(){
        List<String> coInvoicePaymentFields = new List<String>{ 'Name',
	                                                        'Cash_Drawer__c',
	                                                        'Cash_Drawer__r.Name',
	                                                        'Branding_Location__c',
	                                                        'Branding_Location__r.Name'
	                                               		 };
        return coInvoicePaymentFields;
    }
}
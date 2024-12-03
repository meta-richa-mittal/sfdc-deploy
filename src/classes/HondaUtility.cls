/** 
* Author: Tarun Khandelwal
* Since: Dec 11, 2019
* Name: HondaUtility 
* Description: Utility class for all Honda common functions.
**/
public without sharing class HondaUtility {
    
    public static Boolean isHondaIntegrationEnabled() {
        return Honda_Configuration__c.getOrgDefaults().Honda_Web_API__c;
    }
    
    public static String getDealerNumber() {
        return Honda_Configuration__c.getOrgDefaults().Dealer_Number__c;
    }
    
    public static String getWebKeyNumber() {
        return Honda_Configuration__c.getOrgDefaults().Web_Key_Number__c;
    }
    
    public static String getHondaVendorCode() {
        return Honda_Configuration__c.getOrgDefaults().Honda_Vendor_Code__c;
    }
    
    public static String getHondaVendorSFId() {
        List<Account> accList = [SELECT Id FROM Account WHERE Is_Vendor__c = true AND Vendor_Code__c =: getHondaVendorCode()];
        return ( (accList.size() > 0) ? accList[0].Id : null);
    }
    
    public static IFW_IntegrationConfig__c getHondaIFWConfigRecord() {
        List<IFW_IntegrationConfig__c> configList = BaseIntegration.getParentByName('Honda');
        return ( (configList.size() > 0) ? configList[0] : null);
    }
    
    public static IFW_IntegrationConfigItem__c getHondaIFWConfigItemByAction(String actionName) {
        List<IFW_IntegrationConfigItem__c> configItemList = BaseIntegration.getChild(new Map<String, String>{'Entity_Name__c' => actionName});
        return ( (configItemList.size() > 0) ? configItemList[0] : null);
    }
    
    public static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', 'application/json'));
        return headerList;
    }
    
    public static String sendRequest(String entityName, String body) {
        HttpResponse response = doCallout(entityName, body);
        String responseBody;
        if(response.getStatusCode() == 200) {
            responseBody = response.getBody();
        }
        return responseBody;
    }
    
    public static HttpResponse doCallout(String entityName, String body) {
        List<CustomHttpHeaderWrapper> headerList = getHeaderList();
        IFW_IntegrationConfig__c config = getHondaIFWConfigRecord();
        IFW_IntegrationConfigItem__c configItem = getHondaIFWConfigItemByAction(entityName);
        
        HttpResponse response = new HttpResponse();
        if(config != null && configItem != null) {
            try {
                response = BaseIntegration.performCallout(config, configItem, body, headerList, new Map<String, String>(), null);
                if(BaseIntegration.webServiceLogs != null) {
                    DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
                }
            } catch (System.Exception c) {
                new LogService().createErrorLog('HondaUtility', 'doCallout()', 'Error While calling API = ' + configItem.Endpoint_URL__c, 
                                                LogService.NOT_APPLICABLE, null, entityName, LogService.HONDA, true, 'Error');
            }
        } else {
             new LogService().createErrorLog('HondaUtility', 'doCallout()', 'No Config records found', 
                                LogService.NOT_APPLICABLE, null, entityName, LogService.HONDA, true, 'Error');
        }
        return response;
    }
}
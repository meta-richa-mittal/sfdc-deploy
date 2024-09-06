public without sharing class IntegrationServiceFactory {
	
    public static String getActiveAccountingIntegrationName() {
        return (QBUtil.isQBEnabled() ? 'QuickBooks Online' : getActiveIntegrationNameByType('Accounting'));
    }
    
    public static String getActiveIntegrationNameByType(String integrationType) {
        List<IFW_IntegrationConfig__c> configList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Type__c' => integrationType,
                                                                                                                'Accounting_Enabled__c' => true});
        String activeIntegrationName;
        if(configList.size() > 0) {
            activeIntegrationName = configList[0].Integration_Name__c;
        }
        return activeIntegrationName;
    }
    
    public static BaseIntegrationService getIntegrationServiceInstance(String integrationType) {
        if(integrationType == 'Accounting') {
            return getAccountingServiceInstance();
        }
        return null;
    }
    
    private static BaseIntegrationService getAccountingServiceInstance() {
        List<IFW_IntegrationConfig__c> configList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Type__c' => 'Accounting',
        											'Accounting_Enabled__c' => true});
        if(configList.size() > 0) {
            if(configList[0].Integration_Name__c == 'Xero') { // Constant
                return new XeroService(configList[0]);
            }
        } else {
            //throw new BlackpurlException('No Integration active');
        }
        return null;
    }
    
    public static IFW_IntegrationConfig__c getIFWConfigByIntegrationName(String integrationName) {
    	if(String.isNotBlank(integrationName)) {
	    	List<IFW_IntegrationConfig__c> ifwList = BaseIntegration.getParentByName(integrationName);
	        if(ifwList.size() > 0) {
	            if(!ifwList[0].Accounting_Enabled__c) {
		            throw new BlackpurlException(integrationName + ' integration is not Enabled');
		        }
		        return ifwList[0];
	        } else {
	            throw new BlackpurlException(integrationName + ' integration config does not exists');
	        }
    	}
    	return null;
    }
    
    public static IFW_IntegrationConfigItem__c getIFWConfigItemByEntityName(String entityName, String methodType, String integrationName) {
        if(AccessControl.ifObjectIsAccessible('IFW_IntegrationConfigItem__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<IFW_IntegrationConfigItem__c> configItemList = 
                [SELECT Entity_Name__c, IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c FROM IFW_IntegrationConfigItem__c 
               		WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType
                    AND IFW_IntegrationConfig__r.Integration_Name__c =: integrationName];
        if(configItemList.size() > 0) {
            return configItemList[0];
        }
        return null;
    }
}
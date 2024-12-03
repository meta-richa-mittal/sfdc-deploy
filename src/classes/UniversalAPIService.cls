public without sharing class UniversalAPIService {

    public static HTTPResponse doCallout(String requestBody) {
        try {
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.CONNECTION => null}, false);
            if(ifwList.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');
            if(ifwList[0].IFW_IntegrationConfigItems__r.isEmpty()) throw new BlackPurlException('IFW Config items for Organization not defined');
            return BaseIntegration.performCallout(ifwList[0], ifwList[0].IFW_IntegrationConfigItems__r[0], requestBody, getReqHeaders(), new Map<String, String>(), UniversalAPIUtility.CONNECTION);        
        } catch (Exception e) {
            throw new BlackPurlException(universalAPIUtility.connectionError);
        }
    }

    public static HTTPResponse doCallout(List<IFW_IntegrationConfig__c> ifwList, String requestBody) {
        return doCallout(ifwList, requestBody, null);
    }

    public static HTTPResponse doCallout(List<IFW_IntegrationConfig__c> ifwList, String requestBody, List<CustomHttpHeaderWrapper> customReqHeaders) {
        try {
            if(ifwList.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');
            if(ifwList[0].IFW_IntegrationConfigItems__r.isEmpty()) throw new BlackPurlException('IFW Config items for Organization not defined');
            List<CustomHttpHeaderWrapper> reqHeaders = getReqHeaders();
            if(customReqHeaders != null) reqHeaders.addAll(customReqHeaders);
            return BaseIntegration.performCallout(ifwList[0], ifwList[0].IFW_IntegrationConfigItems__r[0], requestBody, reqHeaders, new Map<String, String>(), UniversalAPIUtility.CONNECTION);        
        } catch (Exception e) {
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static String generateJWTToken() {
        try {
            String requestBody = System.JSON.serialize(new UniversalAPIWrapper.JWTTokenWrapper());
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.JWT_TOKEN => null}, false);
            if(ifwList.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');
            if(ifwList[0].IFW_IntegrationConfigItems__r.isEmpty()) throw new BlackPurlException('IFW Config items for Organization not defined');
            HTTPResponse response = BaseIntegration.performCallout(ifwList[0], ifwList[0].IFW_IntegrationConfigItems__r[0], requestBody, new List<CustomHttpHeaderWrapper>{new CustomHttpHeaderWrapper('Authorization', 'Bearer ' + UserInfo.getSessionId()), new CustomHttpHeaderWrapper('Content-Type', 'application/json')}, new Map<String, String>(), UniversalAPIUtility.JWT_TOKEN);   
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                return response.getBody();
            } else {
                throw new BlackPurlException(response.getBody());
            }     
        } catch (Exception e) {
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static List<CustomHttpHeaderWrapper> getReqHeaders () {
        String id = 'https://login.salesforce.com/id/'+ UserInfo.getOrganizationId() + '/' + UserInfo.getUserId();
     
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(new CustomHttpHeaderWrapper('id', id));
        headerList.add(new CustomHttpHeaderWrapper('instance_url', URL.getOrgDomainUrl().toExternalForm()));
        headerList.add(new CustomHttpHeaderWrapper('access_token', UserInfo.getSessionId()));
        headerList.add(new CustomHttpHeaderWrapper('namespace', (GeneralConfiguration.getNamespace() == null ? '' : (GeneralConfiguration.getNamespace()).replace('__', ''))));
        headerList.add(new CustomHttpHeaderWrapper('Content-Type', 'application/json'));
        return headerList;
    }

    public static void createIFWConfigAndConfigItemsForUniversalAPI(Boolean isFromAdminConfig) {
        List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(new Map<String, Object>{'Integration_Name__c' => UniversalAPIUtility.UNIVERSAL_API});
        if(isFromAdminConfig && !ifwList.isEmpty()) return;
        List<IFW_IntegrationConfig__c> ifwConfigUpsertList = new List<IFW_IntegrationConfig__c>();
        List<IFW_IntegrationConfigItem__c> ifwConfigItemUpsertList = new List<IFW_IntegrationConfigItem__c>();
        if(!ifwList.isEmpty()) {
            ifwConfigUpsertList = ifwList;
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', ifwList[0].IFW_IntegrationConfigItems__r);
        } else {
            IFW_IntegrationConfig__c ifwConfig = IntegrationServiceFactory.createIFWConfig(false, UniversalAPIUtility.UNIVERSAL_API,'Basic', null, null, null);
            ifwConfigUpsertList.add(ifwConfig);
            ifwConfigUpsertList = DMLUtility.upsertSobjectList('IFW_IntegrationConfig__c', ifwConfigUpsertList);
        }

        if(!ifwConfigUpsertList.isEmpty()) {
            for(String entityName : UniversalAPIUtility.getEntityNameToURLMap().keySet()) {
                IFW_IntegrationConfigItem__c ifwConfigItem = IntegrationServiceFactory.createIFWConfigItem(ifwConfigUpsertList[0].Id, entityName, UniversalAPIUtility.getEntityNameToURLMap().get(entityName), 'POST');
                ifwConfigItemUpsertList.add(ifwConfigItem);
            }
            DMLUtility.upsertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItemUpsertList);
        }
    }
}
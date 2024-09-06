public without sharing class DP360Service {
    
    public static String previousBearerToken;
    public static List<Log__c> errorLogs = new List<Log__c>();
    public static Boolean isEnabled;
    public static Integer dealerId;
    public static Integer leadId;
    
    public static Boolean isDP360Enabled() {
        if(isEnabled == null) {
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => 'DP360'});
            isEnabled = (ifwList.size() > 0);
        }
        return isEnabled;
    }
    
    public static Integer getDealerId() {
        if(dealerId == null) {
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => 'DP360'});
            if(ifwList.size() > 0) {
                dealerId = (ifwList[0].Company_Id__c != null ? Integer.valueOf(ifwList[0].Company_Id__c) : null);
            }
        }
        return dealerId;
    }
    
    public static List<SearchLeadResultWrapper.LeadWrapper> getAllOpenLeads() {
        Map<String, String> urlParamMap = new Map<String, String>();
        Decimal numberOfdays = GeneralConfiguration.getDP360OpenLeadFetchingPeriodInDays();
        
        if(numberOfdays != null && numberOfdays > 0) {
            urlParamMap.put('modified_start', String.valueOfGMT(system.now().addDays(Integer.valueOf(numberOfdays) * -1)));
            urlParamMap.put('modified_end',  String.valueOfGMT(system.now()));
        }
            
        List<SearchLeadResultWrapper.LeadWrapper> leadObjList = searchLead(urlParamMap);
        List<SearchLeadResultWrapper.LeadWrapper> openLeadList = new List<SearchLeadResultWrapper.LeadWrapper>();
        if(leadObjList != null && leadObjList.size() > 0) {
            for(SearchLeadResultWrapper.LeadWrapper lead : leadObjList) {
                if(lead.status == 'Open') {
                    openLeadList.add(lead);
                }
            }
        }
        return openLeadList;
    }
    
    public static List<SearchLeadResultWrapper.LeadWrapper> searchLead(Map<String, String> urlParamMap) {
        Id IFW_ItemId = BaseIntegration.getIFWConfigItemByEntityName('Search Lead', 'GET', 'DP360');
        String response = doCallout(IFW_ItemId, urlParamMap);
        List<SearchLeadResultWrapper.LeadWrapper> leadObjList;
        if(String.isNotBlank(response)) {
            SearchLeadResultWrapper leadResObj = SearchLeadResultWrapper.parse(response);
            leadObjList = leadResObj.data;
        }
        return leadObjList;
    }
    
    public static String createUnit(String body) {
        Id IFW_ItemId = BaseIntegration.getIFWConfigItemByEntityName('Create Unit', 'POST', 'DP360');
        String response = doCallout(IFW_ItemId, body);
        return response;
    }
    
    public static String updateLead(String body, Integer lead_id) {
        leadId = lead_id;
        Id IFW_ItemId = BaseIntegration.getIFWConfigItemByEntityName('Update Lead', 'PUT', 'DP360');
        String response = doCallout(IFW_ItemId, body);
        return response;
    }
    
    public static String doCallout(Id IFW_ItemId, String body) {
        return doCallout(IFW_ItemId, new Map<String, String>(), body);
    }
    
    public static String doCallout(Id IFW_ItemId, Map<String, String> urlParamMap) {
        return doCallout(IFW_ItemId, urlParamMap, '');
    }
    
    public static String doCallout(Id IFW_ItemId, Map<String, String> urlParamMap, String body) {
        IFW_IntegrationConfigItem__c child = BaseIntegration.getChild(IFW_ItemId);
        IFW_IntegrationConfig__c parent = BaseIntegration.getParent(child.IFW_IntegrationConfig__c);
        previousBearerToken = parent.Bearer_Token__c;
        replaceMergeField(child);
        
        List<CustomHttpHeaderWrapper> headerList = getHeaderList(parent.Company_Id__c);
        HttpResponse response = new HttpResponse();
        String responseString;
        try {
            if(!parent.Enabled__c) {
                throw new BlackpurlException('DP360 Integration is not Enabled');
            }
            response = BaseIntegration.performCallout(parent, child, body, headerList, urlParamMap, null);
            responseString = handleResponse(response);
        } catch (Exception e) {
            errorLogs.add(new LogService().createErrorLog('DP360Service', 'doCallout()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              '', LogService.DP360, false, 'Error'));
        }
        updateValues(new List<IFW_IntegrationConfig__c>{parent});
        return responseString;
    }
    
    
    private static void replaceMergeField(IFW_IntegrationConfigItem__c child) {
        if(child.Endpoint_URL__c.contains('{{lead_id}}')) {
            child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{{lead_id}}', String.valueOf(leadId));
        }
    }
    
    private static String handleResponse(HttpResponse response) {
        String responseString;
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            responseString = response.getBody();
        }
        return responseString;
    }
    
    private static List<CustomHttpHeaderWrapper> getHeaderList(String dealerId) {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', 'application/json'));
        headerList.add(BRPUtility.buildCustomHttpHeader('DealerId', dealerId));
        return headerList;
    }
    
    public static void updateValues(List<IFW_IntegrationConfig__c> parentList) {
        if(parentList.size() == 0) return;
        if(previousBearerToken != parentList[0].Bearer_Token__c) {
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', parentList);
        }
        if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
            DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        if(DP360Service.errorLogs != null && DP360Service.errorLogs.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', DP360Service.errorLogs);
        }
    }
}
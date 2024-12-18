public without sharing class XeroFusionReportService {
	public static String accessToken;
	public static String refreshToken;
    
    public static Map<String, Decimal> getReportData(String startDate, String endDate, String reportObject, Set<String> objKeyToFindSet) {
        XeroResponseWrapper responseWrapper = getReportData(startDate, endDate, reportObject);
        return parseReportResponse(responseWrapper, objKeyToFindSet);
    }

    public static XeroResponseWrapper getReportData(String startDate, String endDate, String reportObject) {
        XeroResponseWrapper responseWrapper;
        List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
        if(integrationConfigList.size() > 0) {
        	if(XeroUtility.isXeroEnabled()) {
        		if(accessToken != null) integrationConfigList[0].Access_Token__c = accessToken;
        		if(refreshToken != null) integrationConfigList[0].Refresh_Token__c = refreshToken;
        	}
            List<IFW_IntegrationConfigItem__c> configItemList =
                    IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigList[0].Id,
                                                                     'Entity_Name__c' => reportObject});
            Map<String, String> urlParamMap = new Map<String, String>{};
            if(reportObject == 'BalanceSheet') {
                urlParamMap.put('date', endDate);
            } else {
                urlParamMap.put('fromDate', startDate);
                urlParamMap.put('toDate', endDate);
            }
            HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
            if(XeroUtility.isXeroEnabled()) {
	    		accessToken = integrationConfigList[0].Access_Token__c;
	    		refreshToken = integrationConfigList[0].Refresh_Token__c;
	    	}
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                responseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
            }
        }
        return responseWrapper;
    }
    
    public static Map<String, Decimal> parseReportResponse(XeroResponseWrapper responseObj, Set<String> objKeyToFindSet) {
        Map<String, Decimal> objKeyToAmountMap = new Map<String, Decimal>();
        if(responseObj != null && responseObj.Reports != null && responseObj.Reports.size() > 0 && responseObj.Reports[0].Rows != null) {
            for(XeroReportWrapper.cls_Rows rowObj : responseObj.Reports[0].Rows) {
                if(rowObj != null && rowObj.Rows != null) {
                    for(XeroReportWrapper.cls_InnerRows innerRow : rowObj.Rows) {
                        if(innerRow.Cells != null && innerRow.Cells.size() >= 2 && 
                                    (objKeyToFindSet == null || objKeyToFindSet.size() == 0 || objKeyToFindSet.contains(innerRow.Cells[0].Value.toLowerCase()))) {
                            Decimal amount = (String.isNotBlank(innerRow.Cells[1].Value)) ? Decimal.valueOf(innerRow.Cells[1].Value) : 0;
                            objKeyToAmountMap.put(innerRow.Cells[0].Value.toLowerCase(), amount);
                        }
                    }
                }
            }
        }
        return objKeyToAmountMap;
    }
}
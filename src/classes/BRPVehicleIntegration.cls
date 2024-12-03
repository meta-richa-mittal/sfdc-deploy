public without sharing class BRPVehicleIntegration {

    public static final String GET_ARTICLE = 'GetArticle';
    public static final String GET_CAMPAIGNS = 'GetCampaigns';

    public static BRPArticleResponseWrapper getArticleByArticleNo(String articleNo) {
        BRPArticleResponseWrapper responseObj = new BRPArticleResponseWrapper();
        if(String.isNotBlank(articleNo)) {
            IFW_IntegrationConfigItem__c child = BRPUtility.getIFWConfigItem(GET_ARTICLE, 'GET', 'BRP');
            if(child == null) throw new BlackPurlException('IFW Config item for Articles is not defined.');
            child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{article-no}', articleNo);
            IFW_IntegrationConfig__c parent = BaseIntegration.getParent(child.IFW_IntegrationConfig__c);

            List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
            headerList.add(BRPUtility.buildCustomHttpHeader('Authorization', 'Bearer ' + BRPUtility.getBRPOauth2AccessToken()));
            headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', 'application/json'));

            HttpResponse response = BaseIntegration.performCallout(parent, child, null, headerList);
            responseObj.StatusCode = response.getStatusCode();
            try {
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    responseObj.successResponse = (BRPArticleResponseWrapper.SuccessWrapper) System.JSON.deserialize(response.getBody(), BRPArticleResponseWrapper.SuccessWrapper.class);
                } else if(response.getStatusCode() == 500) {
                    throw new BlackPurlException(BRPUtility.BRP_ERROR_STRING + 'BRP Internal server error::' + response.getBody());
                } else if(response.getBody().contains('invalid_grant')) {
                    throw new BlackPurlException(BRPUtility.BRP_ERROR_STRING + 'BRP Authentication failure::' + response.getBody());
                } else {
                    responseObj.errorResponse = (BRPArticleResponseWrapper.FailureWrapper) System.JSON.deserialize(response.getBody(), BRPArticleResponseWrapper.FailureWrapper.class);
                }
                insertLogs();
            } catch(JSONException e) {
                throw new BlackPurlException(BRPUtility.BRP_ERROR_STRING + 'Error parsing response ('+response.getStatusCode()+')::' + response.getBody());
            }
        } else {
            throw new BlackPurlException('Article number can\'t be blank.');
        }
        return responseObj;
    }

    public static BRPCampaignResponseWrapper getCampaignsByVIN(String vin) {
        BRPCampaignResponseWrapper responseObj = new BRPCampaignResponseWrapper();
        if(String.isNotBlank(vin)) {
            IFW_IntegrationConfigItem__c child = BRPUtility.getIFWConfigItem(GET_CAMPAIGNS, 'GET', 'BRP');
            if(child == null) throw new BlackPurlException('IFW Config item for Campaigns is not defined.');
            child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{vin}', vin.toUpperCase());
            IFW_IntegrationConfig__c parent = BaseIntegration.getParent(child.IFW_IntegrationConfig__c);

            List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
            headerList.add(BRPUtility.buildCustomHttpHeader('Authorization', 'Bearer ' + BRPUtility.getBRPOauth2AccessToken()));
            headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', 'application/json'));
            
            HttpResponse response = BaseIntegration.performCallout(parent, child, null, headerList);
            responseObj.StatusCode = response.getStatusCode();
            system.debug('****' + response.getBody());
            try {
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    responseObj.successResponse = (BRPCampaignResponseWrapper.SuccessWrapper) System.JSON.deserialize(response.getBody(), BRPCampaignResponseWrapper.SuccessWrapper.class);
                } else if(response.getStatusCode() == 500) {
                    throw new BlackPurlException('BRP Internal server error::' + response.getBody());
                } else if(response.getBody().contains('invalid_grant')) {
                    throw new BlackPurlException('BRP Authentication failure::' + response.getBody());
                } else {
                    responseObj.errorResponse = (BRPCampaignResponseWrapper.FailureWrapper) System.JSON.deserialize(response.getBody(), BRPCampaignResponseWrapper.FailureWrapper.class);
                }
                responseObj.ButtonName = getButtonNameByBRPResponse(responseObj);
                insertLogs();
            } catch(JSONException e) {
                throw new BlackPurlException('Error parsing response ('+response.getStatusCode()+')::' + response.getBody());
            }
        } else {
            throw new BlackPurlException('VIN number can\'t be blank.');
        }
        return responseObj;
    }

    private static void insertLogs() {
        if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
			DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
    }

    public static String getVehicleSpecification(String vin) {
        List<CustomHttpHeaderWrapper> headerList = getHeaderList();
        Map<String, String> paramsMap = new Map<String, String>();
        if(vin != null) {
        	vin = vin.replace(' ','%20');
        }
        paramsMap.put('VehicleID', vin);
        
        Id IFW_Id = BRPUtility.getIFWConfigItemByEntityName('GetVehicleSpecification', 'GET', 'BRP');
        return parseXML(BaseIntegration.performCallout(IFW_Id, '', headerList, paramsMap));
    }

    private static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Language', 'en-US'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Connection', 'Keep-Alive'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Charset', 'UTF-8'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Encoding', 'gzip'));
        headerlist.add(BRPUtility.buildCustomHttpHeader('X-STAR-DealerNumberID', BRPUtility.getDealerId())); 
        headerlist.add(BRPUtility.buildCustomHttpHeader('X-STAR-AuthorizationID', 'asmith01')); 
        headerlist.add(BRPUtility.buildCustomHttpHeader('X-STAR-SenderNameCode', 'BP')); 
        headerlist.add(BRPUtility.buildCustomHttpHeader('X-STAR-releaseID', '5.8.1')); 
        headerlist.add(BRPUtility.buildCustomHttpHeader('X-STAR-BODID', '0a58ef11-eb78-4104-81eb-9cf474d2b7ac')); 
        return headerList;
    }
    
    private static String parseXML(String xmlString) {
        String jsonString;
        BRPVehicleResponseWrapper vehicleObj = (BRPVehicleResponseWrapper)new XMLSerializer().deSerialize(xmlString, BRPVehicleResponseWrapper.class);
        if(vehicleObj.ShowVehicleSpecifications != null && vehicleObj.ShowVehicleSpecifications.ShowVehicleSpecificationsDataArea != null && 
            vehicleObj.ShowVehicleSpecifications.ShowVehicleSpecificationsDataArea.VehicleSpecifications != null && 
            vehicleObj.ShowVehicleSpecifications.ShowVehicleSpecificationsDataArea.VehicleSpecifications.VehicleSpecificationsLine != null &&
            vehicleObj.ShowVehicleSpecifications.ShowVehicleSpecificationsDataArea.VehicleSpecifications.VehicleSpecificationsLine.Vehicle != null) {
            jsonString = system.JSON.serialize(vehicleObj.ShowVehicleSpecifications.ShowVehicleSpecificationsDataArea.VehicleSpecifications.VehicleSpecificationsLine.Vehicle);
        } else {
            jsonString = system.JSON.serialize(new ResponseWrapper(400, 'No such vehicle found'));
        }
        return jsonString;
    }

    private static String getButtonNameByBRPResponse(BRPCampaignResponseWrapper responseObj) {
        String buttonName;
        if(responseObj.successResponse != null) {
            for(BRPCampaignResponseWrapper.Campaign campaignObj : responseObj.successResponse.campaigns) {
                if(campaignObj.articles != null && campaignObj.articles.size() > 0 && buttonName != 'BRP Safety') {
                    buttonName = 'BRP articles';
                }
                if(campaignObj.type_descr == 'Safety' && !campaignObj.is_claimed) {
                    buttonName = 'BRP Safety';
                    break;
                }
            }
            if(String.isBlank(buttonName)) {
                buttonName = 'No BRP articles';
            }
        } else if (responseObj.errorResponse != null) {
            if(responseObj.errorResponse.errors.size() > 0 && responseObj.errorResponse.errors[0].code == 'not_found') {
                if(responseObj.errorResponse.errors[0].title.contains('does not have any campaigns')) {
                    buttonName = 'No BRP campaigns';
                } else {
                    buttonName = 'Invalid BRP VIN';
                }
            } else {
                buttonName = 'BRP: Not found';
            }
        }
        return buttonName;
    }
}
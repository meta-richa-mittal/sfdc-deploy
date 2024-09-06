public without sharing class BRPAPIManager {
    
    public static String apiVersion = BRPUtility.getAPIVersion();
    
    public static String getPartLocator(String partId, Integer quantity, String searchType) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            if(searchType == 'Supplier') {
                return BRPPartInventoryService.getPartInventory(partId, quantity);
            } else {
                return BRPDealerPartLocatorService.getPartsLocator(partId, quantity, searchType);
            }
        } else {
            return BRPPartsIntegration.getPartsLocator(partId, quantity, searchType);
        }
    }

    public static String getDealer(String dealerNo) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPDealerIntegration.getDealer(dealerNo);
        } else {
            return BRPDealerIntegration.getDealersList();
        }
    }

    public static String getVehicleSpecification(String vin) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPUnitSpecificationsService.getUnitSpecification(vin);
        } else {
            return BRPVehicleIntegration.getVehicleSpecification(vin);
        }
    }

    public static BRPArticleResponseWrapper getArticleByArticleNo(String articleNo) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPUnitSpecificationsService.getArticleByArticleNo(articleNo);
        } else {
            return BRPVehicleIntegration.getArticleByArticleNo(articleNo);
        }
    }

    public static HttpResponse getParts(String pageNumber, String partNumber) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPPartsService.getParts(pageNumber, partNumber);
        } else {
            return BRPPartsMasterService.getParts(pageNumber);
        }
    }

    public static BRPCampaignResponseWrapper getCampaignsByVIN(String vin) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPUnitSpecificationsService.getCampaignsByVIN(vin);
        } else {
            return BRPVehicleIntegration.getCampaignsByVIN(vin);
        }
    }

    public static Pagereference authorizeBRP() {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return new Pagereference(new BRPDealerAuthorizationService().authorizeBRP());
        } else {
            return new Pagereference(new BRPAuthorizationService().authorizeBRP());
        }
    }

    public static String saveAccessToken(String urlParams) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPDealerAuthorizationService.saveAccessToken(urlParams);
        } else {
            return BRPAuthorizationService.saveAccessToken(urlParams);
        }
    }

    public static HttpResponse refreshBRPAccessTokenAndPerformCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> parameters) {
        if(apiVersion == BRPUtility.API_VERSION_V4) {
            return BRPDealerAuthorizationService.refreshBRPAccessTokenAndPerformCallout(parent, child, body, headerList, parameters);
        } else {
            return BRPAuthorizationService.refreshBRPAccessTokenAndPerformCallout(parent, child, body, headerList, parameters);
        }
    }
}
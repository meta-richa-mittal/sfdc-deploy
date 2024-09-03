global with sharing class YamahaAusQtyOnHandScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        callUniversalAPI();
    }

    @future(callout=true)
    public static void callUniversalAPI() {
        try {
            String username = GeneralConfiguration.getConfigurationByName('YAMAHA_AUS_USERNAME');
            String password = GeneralConfiguration.getConfigurationByName('YAMAHA_AUS_PASSWORD');
            UniversalApiWrapper reqWrapper = new UniversalApiWrapper(new UniversalApiWrapper.YamahaAusApiReqWrapper(username, password));
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.UNIVERSAL_INTERNAL => null}, false);
            HTTPResponse response = UniversalAPIService.doCallout(ifwList, system.JSON.serialize(reqWrapper.yamahaAusReqData));
            
            handleResponse(response);
            if(BaseIntegration.webServiceLogs != null) {
                insert BaseIntegration.webServiceLogs;
            } 

        } catch (Exception e) {
            new LogService().createErrorLog('YamahaAusQtyOnHandScheduler', 'callUniversalAPI()', e.getMessage(), null, null, null, UniversalAPIUtility.UNIVERSAL_API, true, 'Error');
        }
    }

    private static void handleResponse(HTTPResponse response) {
        String logType = 'Info';
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            UniversalAPIWrapper.UniversalApiResWrapper resObj = (UniversalAPIWrapper.UniversalApiResWrapper) JSON.deserialize(response.getBody(), UniversalAPIWrapper.UniversalApiResWrapper.class);
            if(resObj.errors != null && resObj.errors.size() > 0) {
                logType = 'Error';
            }
        } else {
            logType = 'Error';
        }
        new LogService().createErrorLog('YamahaAusQtyOnHandScheduler', 'callUniversalAPI()', response.getBody(), String.valueOf(response.getStatusCode()), null, null, UniversalAPIUtility.UNIVERSAL_API, true, logType);
    }
}
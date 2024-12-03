/** 
* Author: Nidhi Sharma
* Since: October 13, 2024
* Name: APFGenerationScheduler 
* Description: Scheduler Apex class that calls microservice to generate price file for specific vendor
**/
global without sharing class APFGenerationScheduler implements Schedulable {
    
    private static List<Log__c> logListToInsert = new List<Log__c>();
    public static final String JOB_NAME = 'Generate Price File';

    global void execute(SchedulableContext sc) {
        callMSToGenerateAutomatedPriceFiles_future();
    }

    @future(callout=true)
    private static void callMSToGenerateAutomatedPriceFiles_future() {
        for(Vendor_Master__c vendorMasterRec : [SELECT Partner_Vendor_Master_Identifier__c, Price_File_Location_URL__c FROM Vendor_Master__c WHERE Vendor_Master_Type__c =: Label.VM_Automated Order By LastModifiedDate]) {
            calloutAPFGenerateMicroservice(vendorMasterRec);
        }
        DMLUtility.insertSObjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        DMLUtility.insertSObjectList('Log__c', logListToInsert);

    }

    private static void calloutAPFGenerateMicroservice(Vendor_Master__c vendorMasterRec) {
        if(vendorMasterRec != null) {
            try {
                UniversalApiWrapper reqWrapper = new UniversalApiWrapper(new UniversalApiWrapper.ApfGenerateApiReqWrapper(vendorMasterRec));
                List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.UNIVERSAL_INTERNAL => null}, false);
                HTTPResponse response = UniversalAPIService.doCallout(ifwList, system.JSON.serialize(reqWrapper.apfGenerateReqData), getReqHeaders());
                if(response.getStatusCode() == 200) {
                    UniversalApiWrapper.UniversalApiResWrapper apiResObj = (UniversalApiWrapper.UniversalApiResWrapper) System.json.deserialize(response.getBody(), UniversalApiWrapper.UniversalApiResWrapper.class);
                    vendorMasterRec.Generate_PF_MS_Job_Id__c = apiResObj.data.asyncJobCreate.id;
                    vendorMasterRec.Generate_PF_Webhook_Response__c = null;
                    DMLUtility.updateSObjectList('Vendor_Master__c', vendorMasterRec);
                }
            } catch(Exception e) {
                logListToInsert.add(new LogService().createErrorLog('APFGenerationScheduler', 'calloutAPFGenerateMicroservice()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                System.Json.serialize(vendorMasterRec), 'Generate Price File', false));
            }
        }
    }

    private static List<CustomHttpHeaderWrapper> getReqHeaders() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(new CustomHttpHeaderWrapper('client_id', GeneralConfiguration.getConfigurationByName('Turn14 Client Id')));
        headerList.add(new CustomHttpHeaderWrapper('client_secret', GeneralConfiguration.getConfigurationByName('Turn14 Client Secret')));
        return headerList;
    }
}
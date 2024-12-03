/** 
* Author: Nidhi Sharma
* Since: August 13, 2024
* Name: APFImportScheduler 
* Description: Scheduler Apex class that calls microservice for "Queued for Import" vendor master records
**/
global without sharing class APFImportScheduler implements Schedulable {
    
    private static List<Log__c> logListToInsert = new List<Log__c>();
    private static final String IMPORT_IN_PROGRESS_STATUS = 'Import in progress';
    public static String fileFolder = '/pricefiles.blackpurl.com/';
    public static final String JOB_NAME = 'APF Import';

    global void execute(SchedulableContext sc) {
        importPriceFileForQueuedVendorMaster_future();
    }

    @future(callout=true)
    private static void importPriceFileForQueuedVendorMaster_future() {
        if(!isAPFUploadInProgress()) {
            //check if any vendor mater is queue for import
            for(Vendor_Master__c vendorMasterRec : [SELECT Partner_Vendor_Master_Identifier__c, Vendor_Master_Type__c, Price_File_Location_URL__c, (Select Id FROM Summary_Logs__r WHERE Type__c = 'APF' Order By CreatedDate DESC LIMIT 1) FROM Vendor_Master__c WHERE Price_File_Import_Status__c = 'Queued for import' Order By LastModifiedDate LIMIT 1]) {
                calloutAPFImportMicroservice(vendorMasterRec);
            }
        }
    }

    private static Boolean isAPFUploadInProgress() {
        return ([SELECT Id FROM Vendor_Master__c WHERE Price_File_Import_Status__c =: IMPORT_IN_PROGRESS_STATUS LIMIT 1].size() > 0);
    }

    public static void calloutAPFImportMicroservice(Vendor_Master__c vendorMasterRec) {
        List<VendorMasterWrapper> vendorMasterObjList = getPriceFileLocationFromPartnerOrg(vendorMasterRec.Partner_Vendor_Master_Identifier__c);
        if(!vendorMasterObjList.isEmpty()) {
            UniversalApiWrapper reqWrapper = new UniversalApiWrapper(new UniversalApiWrapper.ApfImportApiReqWrapper(vendorMasterRec, vendorMasterObjList[0]));
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.UNIVERSAL_INTERNAL => null}, false);
            try {
                HTTPResponse response = UniversalAPIService.doCallout(ifwList, system.JSON.serialize(reqWrapper.apfImportReqData));
                if(response.getStatusCode() == 200) {
                    UniversalApiWrapper.UniversalApiResWrapper apiResObj = (UniversalApiWrapper.UniversalApiResWrapper) System.json.deserialize(response.getBody(), UniversalApiWrapper.UniversalApiResWrapper.class);
                    if(!vendorMasterRec.Summary_Logs__r.isEmpty()) {
                        vendorMasterRec.Summary_Logs__r[0].MS_Job_Id__c = apiResObj.data.asyncJobCreate.id;
                        DMLUtility.updateSObjectList('Summary_Log__c', vendorMasterRec.Summary_Logs__r[0]);
                    }
                    if(String.isBlank(vendorMasterRec.Vendor_Master_Type__c) || !vendorMasterRec.Vendor_Master_Type__c.equalsIgnoreCase(Label.VM_Automated)) {
                        vendorMasterRec.Price_File_Location_URL__c = vendorMasterObjList[0].priceFileLocation;
                    }
                    vendorMasterRec.Price_File_Import_Status__c = IMPORT_IN_PROGRESS_STATUS;
                    DMLUtility.updateSObjectList('Vendor_Master__c', vendorMasterRec);
                }
            } catch(Exception e) {
                logListToInsert.add(new LogService().createErrorLog('APFImportScheduler', 'calloutAPFImportMicroservice_future()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                System.Json.serialize(vendorMasterRec), LogService.AUTOMATED_PRICE_FILE, false));
            }
            DMLUtility.insertSObjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        DMLUtility.insertSObjectList('Log__c', logListToInsert);
    }

    private static List<VendorMasterWrapper> getPriceFileLocationFromPartnerOrg(String partnerVendorMasterName) {
		List<VendorMasterWrapper> vendorMasterObjList = new List<VendorMasterWrapper>();
        try {
            List<VendorMasterImportPriceFileService.SubscriberResponseWrapper> responseObjList = VendorMasterImportPriceFileService.sendPriceFileDetailsRequest(new List<String>{partnerVendorMasterName});
            vendorMasterObjList = VendorMasterImportPriceFileService.handleResponse(new List<String>{partnerVendorMasterName}, responseObjList);
		} catch(Exception e) {
            logListToInsert.add(new LogService().createErrorLog('APFImportScheduler', 'getPriceFileLocationFromPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
            partnerVendorMasterName, LogService.AUTOMATED_PRICE_FILE, false));
        }
		return vendorMasterObjList;
	}

    public class APFMicroserviceRequestWrapper {
        public String accessKeyId;
        public String secretAccessKey;
        public String priceFileBucketName;
        public String region;
        public String filePath;
        public String orgId;
        public String vendorMasterId;
        public String requestId;
        public String namespace;
        public Integer chunkSize;
    }
}
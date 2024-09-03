/** 
* Author: Nidhi Sharma
* Since: August 13, 2024
* Name: APFImportScheduler 
* Description: Scheduler Apex class that calls microservice for "Queued for Import" vendor master records
**/
global without sharing class APFImportScheduler implements Schedulable {
    
    private static List<Log__c> logListToInsert = new List<Log__c>();
    public static String fileFolder = '/pricefiles.blackpurl.com/';

    global void execute(SchedulableContext sc) {
        importPriceFileForQueuedVendorMaster();
    }

    private static void importPriceFileForQueuedVendorMaster() {
        //check if any vendor mater is queue for import
        for(Vendor_Master__c vendorMasterRec : [SELECT Partner_Vendor_Master_Identifier__c, (Select Id FROM Summary_Logs__r Order By CreatedDate DESC LIMIT 1) FROM Vendor_Master__c WHERE Price_File_Import_Status__c = 'Queued for import' Order By LastModifiedDate LIMIT 1]) {
            calloutAPFImportMicroservice(vendorMasterRec);
        }
    }

    private static void calloutAPFImportMicroservice(Vendor_Master__c vendorMasterRec) {
        List<VendorMasterWrapper> vendorMasterObjList = getPriceFileLocationFromPartnerOrg(vendorMasterRec.Partner_Vendor_Master_Identifier__c, vendorMasterRec.Id);
        if(!vendorMasterObjList.isEmpty()) {
            UniversalApiWrapper reqWrapper = new UniversalApiWrapper(new UniversalApiWrapper.ApfImportApiReqWrapper(vendorMasterRec, vendorMasterObjList[0]));
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(UniversalAPIUtility.UNIVERSAL_API, new Map<String, String>{UniversalAPIUtility.UNIVERSAL_INTERNAL => null}, false);
            HTTPResponse response = UniversalAPIService.doCallout(ifwList, system.JSON.serialize(reqWrapper.apfImportReqData));
            if(response.getStatusCode() == 200) {
                vendorMasterRec.Price_File_Location_URL__c = vendorMasterObjList[0].priceFileLocation;
                vendorMasterRec.Price_File_Import_Status__c = 'Import in progress';
                update vendorMasterRec;
            }
            DMLUtility.insertSObjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        DMLUtility.insertSObjectList('Log__c', logListToInsert);
    }

    private static List<VendorMasterWrapper> getPriceFileLocationFromPartnerOrg(String partnerVendorMasterName, String vendorMasterId) {
		List<VendorMasterWrapper> vendorMasterObjList = new List<VendorMasterWrapper>();
        try {
            List<VendorMasterImportPriceFileService.SubscriberResponseWrapper> responseObjList = VendorMasterImportPriceFileService.sendPriceFileDetailsRequest(new List<String>{partnerVendorMasterName});
            vendorMasterObjList = VendorMasterImportPriceFileService.handleResponse(new List<String>{partnerVendorMasterName}, responseObjList);
		} catch(Exception e) {
            logListToInsert.add(new LogService().createErrorLog('AutomatedPriceFileService', 'getPriceFileLocationFromPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
            partnerVendorMasterName, LogService.AUTOMATED_PRICE_FILE, false));
        }
		return vendorMasterObjList;
	}

    public static void scheduleJob() {
        Integer count = 1;
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 0 * * * ?', new APFImportScheduler());
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 10 * * * ?', new APFImportScheduler());
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 20 * * * ?', new APFImportScheduler());
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 30 * * * ?', new APFImportScheduler());
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 40 * * * ?', new APFImportScheduler());
        System.schedule(ScheduleJobService.APF_IMPORT_SCHEDULER + ' ' + count++, '0 50 * * * ?', new APFImportScheduler());
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
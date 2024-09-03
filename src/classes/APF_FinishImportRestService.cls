@RestResource(urlMapping = '/apf/finishImport/*')
global without sharing class APF_FinishImportRestService {
    
    @HttpPost
    global static String doPost() {
        RequestWrapper requestObj = (RequestWrapper)JSON.deserialize(RestContext.request.requestBody.toString(), RequestWrapper.class);
        finishImport(requestObj);
        return 'Price file import has been completed successfully. Inserted parts: ' + requestObj.createdParts + ', Updated parts: ' + requestObj.updatedParts + ', Failed parts: ' + requestObj.failedParts;
    }

    private static void finishImport(APF_FinishImportRestService.RequestWrapper requestObj) {
        if(String.isNotBlank(requestObj.vendorMasterId)) {
            for(Vendor_Master__c vendorMasterRec : [SELECT Blackpurl_Vendor__c, Partner_Vendor_Master_Identifier__c, (Select Id FROM Summary_Logs__r WHERE Id =: requestObj.requestId) FROM Vendor_Master__c WHERE Id = :requestObj.vendorMasterId]) {
                requestObj.createdParts = requestObj.createdParts != null ? requestObj.createdParts : 0;
                requestObj.updatedParts = requestObj.updatedParts != null ? requestObj.updatedParts : 0;
                requestObj.failedParts = requestObj.failedParts != null ? requestObj.failedParts : 0;
                if(!vendorMasterRec.Summary_Logs__r.isEmpty()) {
                    vendorMasterRec.Summary_Logs__r[0].Inserted_Record_Count__c = requestObj.createdParts;
                    vendorMasterRec.Summary_Logs__r[0].Updated_Record_Count__c = requestObj.updatedParts;
                    vendorMasterRec.Summary_Logs__r[0].Failed_Record_Count__c = requestObj.failedParts;
                    DMLUtility.updateSobjectList('Summary_Log__c', vendorMasterRec.Summary_Logs__r[0]);
                }
                vendorMasterRec.Price_File_Import_Status__c = (requestObj.failedParts > 0 ? 'Failed to import' : 'Review import');
                DMLUtility.updateSobjectList('Vendor_Master__c', vendorMasterRec);

                if(!Test.isRunningTest()) {
                    ActivityHistory.createActivityHistory('Price File Import', 'Vendor', vendorMasterRec.Blackpurl_Vendor__c, 'Vendor', vendorMasterRec.Blackpurl_Vendor__c, null);
                }
                AutomatedPriceFileService.updateVendorMasterSubscriberPartnerOrg(new Set<String>{vendorMasterRec.Partner_Vendor_Master_Identifier__c}, vendorMasterRec.Id);
                ImportSupersessionPart_Batch batchObj = new ImportSupersessionPart_Batch(null, 200);
            }
        } else {
            throw new BlackpurlException('Vendor Master Id is required.');
        }
    }
    
    global class RequestWrapper {
        public String vendorMasterId;
        public String requestId;
        public Integer createdParts;
        public Integer updatedParts;
        public Integer failedParts;
    }
}
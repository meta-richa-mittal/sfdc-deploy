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
            try {
                for(Vendor_Master__c vendorMasterRec : [SELECT Blackpurl_Vendor__c, Partner_Vendor_Master_Identifier__c, (Select Id FROM Summary_Logs__r WHERE Id =: requestObj.requestId) FROM Vendor_Master__c WHERE Id = :requestObj.vendorMasterId]) {
                    updateVendorMasterSubscriberPartnerOrg(new Set<String>{vendorMasterRec.Partner_Vendor_Master_Identifier__c});
                    
                    requestObj.createdParts = requestObj.createdParts != null ? requestObj.createdParts : 0;
                    requestObj.updatedParts = requestObj.updatedParts != null ? requestObj.updatedParts : 0;
                    requestObj.failedParts = requestObj.failedParts != null ? requestObj.failedParts : 0;
                    if(!vendorMasterRec.Summary_Logs__r.isEmpty()) {
                        vendorMasterRec.Summary_Logs__r[0].Inserted_Record_Count__c = requestObj.createdParts;
                        vendorMasterRec.Summary_Logs__r[0].Updated_Record_Count__c = requestObj.updatedParts;
                        vendorMasterRec.Summary_Logs__r[0].Failed_Record_Count__c = requestObj.failedParts;
                        DMLUtility.updateSobjectList('Summary_Log__c', vendorMasterRec.Summary_Logs__r[0]);
                    }

                    vendorMasterRec.Price_File_Import_Status__c = (requestObj.failedParts > 0 ? 'Review errors' : 'Review import');
                    vendorMasterRec.Is_Import_Successful__c = true;
                    vendorMasterRec.Last_Imported_Date__c = System.now();
                    vendorMasterRec.Is_Update_Available__c = false;
                    DMLUtility.updateSobjectList('Vendor_Master__c', vendorMasterRec);

                    if(!Test.isRunningTest()) {
                        ActivityHistory.createActivityHistory('Price File Import', 'Vendor', vendorMasterRec.Blackpurl_Vendor__c, 'Vendor', vendorMasterRec.Blackpurl_Vendor__c, null);
                    }
                    ImportSupersessionPart_Batch batchObj = new ImportSupersessionPart_Batch(null, 200);
                }
            } catch(Exception e) {
                new LogService().createErrorLog('APF_FinishImportRestService', 'finishImport()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(requestObj), LogService.AUTOMATED_PRICE_FILE, true);
            }
        } else {
            throw new BlackpurlException('Vendor Master Id is required.');
        }
    }
    
    private static void updateVendorMasterSubscriberPartnerOrg(Set<String> vendorMasterNameSet) {
        List<Log__c> logListToInsert = new List<Log__c>();
        try {
            List<VendorMasterSubscriberUpdateService.SubscriberResponseWrapper> responseObjList = VendorMasterSubscriberUpdateService.sendVMSUpdateRequest(new List<String>(vendorMasterNameSet));
			if(responseObjList[0].Message == 'error') {
                // insert log with error message
                logListToInsert.add(new LogService().createErrorLog('APF_FinishImportRestService', 'updateVendorMasterSubscriberPartnerOrg()', responseObjList[0].ResponseStr, LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(responseObjList), LogService.AUTOMATED_PRICE_FILE, false));
            }
		} catch(Exception e) {
            // insert log with strResponse exception
            logListToInsert.add(new LogService().createErrorLog('APF_FinishImportRestService', 'updateVendorMasterSubscriberPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(vendorMasterNameSet), LogService.AUTOMATED_PRICE_FILE, false));
        }

        if(!logListToInsert.isEmpty()) {
            insert logListToInsert;
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
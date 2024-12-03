@RestResource(urlMapping='/v1/webhook/*')
global without sharing class WebhookManager {
    
    @HttpPost
    global static void doPost() {
        try {
            RestRequest request = RestContext.request;  
            WebhookWrapper webhookObj = (WebhookWrapper)JSON.deserialize(request.requestBody.toString(), WebhookWrapper.class);
            handleWebhookResponse(webhookObj);
        } catch (Exception e) {
            handleErrorResponse(String.valueOf(e.getMessage()), LogService.ERROR);
        }
    }

    public static void handleWebhookResponse(WebhookWrapper webhookObj) {
        if(webhookObj != null && webhookObj.result != null) {
            if (webhookObj.result.errors != null) {
                handleWebhookResponseWithErrors(webhookObj, LogService.ERROR);
            } else if (webhookObj.result.data != null) {
                if (webhookObj.result.data.soqlToFtp != null && webhookObj.result.data.soqlToFtp.status != null) {
                    handleSuccessResponse(webhookObj.result.data.soqlToFtp.status, webhookObj.result.data.soqlToFtp.filepath, LogService.FTP);
                } else if (webhookObj.result.data.soqlToSftp != null && webhookObj.result.data.soqlToSftp.status != null) {
                    handleSuccessResponse(webhookObj.result.data.soqlToSftp.status, webhookObj.result.data.soqlToSftp.filepath, LogService.FTPS);
                } else if (webhookObj.result.data.somCreateJob != null 
                            && webhookObj.result.data.somCreateJob.invStatus != null 
                            && webhookObj.result.data.somCreateJob.pooStatus != null 
                            && webhookObj.result.data.somCreateJob.psiStatus != null) { 
                    handleSuccessResponse(webhookObj.result.data.somCreateJob.invStatus, webhookObj.result.data.somCreateJob.invFileName, LogService.SOM);
                    handleSuccessResponse(webhookObj.result.data.somCreateJob.pooStatus, webhookObj.result.data.somCreateJob.pooFileName, LogService.SOM);
                    handleSuccessResponse(webhookObj.result.data.somCreateJob.psiStatus, webhookObj.result.data.somCreateJob.psiFileName, LogService.SOM);
                }
            } else {
                handleErrorResponse(String.valueOf(webhookObj), LogService.ERROR);
            }
        } else {
            handleErrorResponse(String.valueOf(webhookObj), LogService.ERROR);
        }
    }

    public static void handleSuccessResponse(String status, String fileName, String integrationType) {
        if (status == WebhookUtility.COMPLETED) {
            new LogService().createErrorLog('Webhook', 'handleSuccessResponse()', status, null, null, fileName, integrationType, true, LogService.INFO);
        } else {
            new LogService().createErrorLog('Webhook', 'handleSuccessResponse()', status, null, null, fileName, integrationType, true, LogService.ERROR);
        }
    }

    public static void handleErrorResponse(String errMsg, String logType) {
        new LogService().createErrorLog('Webhook', 'handleErrorResponse()', errMsg, null, null, '', 'Webhook', true, logType);
    }
    
    public static void handleWebhookResponseWithErrors(WebhookWrapper webhookObj, String logType) {
        String jobId = getJobIdFromWebhookResponse(webhookObj);
        String jobName = getJobNameFromWebhookResponse(webhookObj);
        String errorMessage = getErrMsgFromWebhookResponse(webhookObj);
        handleWebhookFailure(jobId, jobName, errorMessage);
        new LogService().createErrorLog('Webhook', 'handleErrorResponse()', errorMessage, 'N/A', null, 
                                                  ('MS Job Id : ' + jobId + ', MS Job Name : ' + jobName), 'APF', true);
    }

    //handle webhook failure
    public static void handleWebhookFailure(String jobId, String jobName, String errorMessage) {
        if(String.isNotBlank(jobId)) {
            if(String.isNotBlank(jobName) && jobName.equalsIgnoreCase(APFImportScheduler.JOB_NAME)) {
                List<Vendor_Master__c> vmUpdateList = new List<Vendor_Master__c>();
                List<Summary_Log__c> apfLogUpdateList = [Select Vendor_Master__r.Price_File_Import_Status__c FROM Summary_Log__c 
                WHERE MS_Job_Id__c =: jobId AND Vendor_Master__r.Price_File_Import_Status__c = 'Import in progress' Order By CreatedDate DESC LIMIT 1];
                if(!apfLogUpdateList.isEmpty()) {
                    apfLogUpdateList[0].Webhook_Response__c = errorMessage;
                    DMLUtility.updateSObjectList('Summary_Log__c', apfLogUpdateList);
                    DMLUtility.updateSObjectList('Vendor_Master__c', new Vendor_Master__c(Id = apfLogUpdateList[0].Vendor_Master__c, Price_File_Import_Status__c = getImportStatusBasedOnErrorMessage(errorMessage)));
                }
            } else {
                List<Vendor_Master__c> vmRecList = [Select Id FROM Vendor_Master__c WHERE Generate_PF_MS_Job_Id__c =: jobId LIMIT 1];
                if(!vmRecList.isEmpty()) {
                    vmRecList[0].Generate_PF_Webhook_Response__c = errorMessage;
                    DMLUtility.updateSObjectList('Vendor_Master__c', vmRecList[0]);
                }
            }
        }
    }

    private static String getImportStatusBasedOnErrorMessage(String errorMessage) {
        Set<String> retryImportErrors = new Set<String>{'Read timed out'};
        for(String errMsg : retryImportErrors) {
            if(errorMessage.toUpperCase().contains(errMsg.toUpperCase())) {
                return 'Queued for import';
            }
        }
        return 'Failed to import';
    }

    private static String getJobIdFromWebhookResponse(WebhookWrapper webhookObj) {
        return (webhookObj != null && webhookObj.meta != null ? webhookObj.meta.jobId : '');
    }

    private static String getJobNameFromWebhookResponse(WebhookWrapper webhookObj) {
        return (webhookObj != null && webhookObj.meta != null ? webhookObj.meta.jobName : '');
    }

    private static String getErrMsgFromWebhookResponse(WebhookWrapper webhookObj) {
        return (webhookObj != null && webhookObj.result != null && webhookObj.result.errors != null ? String.valueOf(webhookObj.result.errors) : '');
    }
}
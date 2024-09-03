public without sharing class SOMService {

    private static final String WEBHOOK_STATUS_COMPLETED = 'COMPLETED';

    public static void doFilePost(String invFileName, String psiFileName, String pooFileName, Boolean includeAllSubmittedClaimItems,
                                    String orgCode, String filePath, Boolean onlySendAllDataInPsiFile) {
        UniversalApiWrapper.SOMApiReqWrapper somApiReqObj = new UniversalApiWrapper.SOMApiReqWrapper(invFileName, psiFileName, pooFileName, includeAllSubmittedClaimItems, orgCode, filePath, onlySendAllDataInPsiFile);
        somApiReqObj.dateRangeFilterForPSI = getPSIDateRangeFilterValue();
        UniversalApiWrapper reqWrapper = new UniversalApiWrapper(somApiReqObj);
        HTTPResponse response = UniversalAPIService.doCallout(JSON.serialize(reqWrapper.SOMReqData));
        handleResponse(response);
    }

    public static void handleResponse(HTTPResponse response) {
        if(response.getStatusCode() == 200) {
            UniversalAPIWrapper.UniversalApiResWrapper SOMApiResObj = (UniversalAPIWrapper.UniversalApiResWrapper) JSON.deserialize(response.getBody(), UniversalAPIWrapper.UniversalApiResWrapper.class);
            if(SOMApiResObj != null && SOMApiResObj.data != null && SOMApiResObj.data.asyncJobCreate != null && SOMApiResObj.data.asyncJobCreate.id != null) {
                BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
                bpConfig.JobRequestId__c = SOMApiResObj.data.asyncJobCreate.id;
                DMLUtility.upsertSobjectList('BP_Configurations__c', bpConfig);
            } else {
                new LogService().createErrorLog('SOMService' , 'doFilePost()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, LogService.SOM, true, 'Error');
            }
        } else {
            new LogService().createErrorLog('SOMService' , 'doFilePost()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, LogService.SOM, true, 'Error');
        }
    }

    private static String getPSIDateRangeFilterValue() {
        List<Log__c> webhookLogList = [SELECT CreatedDate, Log_Info__c, Method_Params__c FROM Log__c WHERE Integration_Type__c = :LogService.SOM AND Type__c = 'Info' AND Apex_Class__c = 'Webhook' ORDER BY CreatedDate DESC];
        Log__c psiLogRec;

        for(Log__c logRec: webhookLogList) {
            if(logRec.Method_Params__c != null && logRec.Method_Params__c.contains(SOMJobScheduler.PART_SALES) && 
                logRec.Log_Info__c != null && logRec.Log_Info__c.equalsIgnoreCase(WEBHOOK_STATUS_COMPLETED)) {
                psiLogRec = logRec;
                break;
            }
        }
        if(psiLogRec != null) {
            Integer daysCount = (psiLogRec.CreatedDate.date()).daysBetween(System.today());
            return (daysCount == 1 || daysCount == 0) ? 'TODAY' : 'LAST_N_DAYS:' + daysCount;
        }
        return '';
    }
}
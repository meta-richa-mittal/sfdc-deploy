public with sharing class KenectService {
    
    public static Boolean isKenectEnable() {
        String kenectConfigValue = GeneralConfiguration.getConfigurationByName(UniversalAPIUtility.featureToggleName);
        return (kenectConfigValue == null ? false : Boolean.valueOf(kenectConfigValue));
    }

    public static String sendMessage(String phoneNumber, Message_History__c msgRec) {
        msgRec.Phone__c = '+' + phoneNumber;
        UniversalApiWrapper.kenectApiReqWrapper kenectApiReqObj = new UniversalApiWrapper.kenectApiReqWrapper(msgRec);
        kenectApiReqObj.locationId = Integer.valueOf(SMS_Configuration__c.getOrgDefaults().Kenect_Location_Id__c != null ? SMS_Configuration__c.getOrgDefaults().Kenect_Location_Id__c : 0);
        UniversalApiWrapper reqWrapper = new UniversalApiWrapper(kenectApiReqObj);
        HTTPResponse response = UniversalAPIService.doCallout(JSON.serialize(reqWrapper.data));
        return handleResponse(response);
    }

    public static String handleResponse(HTTPResponse response) {
        if(response.getStatusCode() == 200) {
            UniversalAPIWrapper.kenectApiResWrapper kenectApiResObj = (UniversalAPIWrapper.kenectApiResWrapper) JSON.deserialize(response.getBody(), UniversalAPIWrapper.kenectApiResWrapper.class);
            if(kenectApiResObj.data != null && kenectApiResObj.data.kenectPushMessageToKenect != null && kenectApiResObj.errors == null) {
                UniversalAPIUtility.messageUUID = kenectApiResObj.data.kenectPushMessageToKenect.messageUUID;
                return 'Success';
            } else {
                createErrorLog(response.getStatus() +' '+ response.getBody());
            }
        } else {
            createErrorLog(response.getStatus() +' '+ response.getBody());
        }
        return UniversalAPIUtility.errorMessage;
    }

    public static void createErrorLog(String response) {
        Log__c logRec = new Log__c(Integration_Type__c = 'Kenect', Log_Info__c = response,
                                Method_Params__c = '', Method__c = 'sendMessage()', 
                                Apex_Class__c = 'KenectService', Type__c = 'Error');
        insert logRec;
    }
}
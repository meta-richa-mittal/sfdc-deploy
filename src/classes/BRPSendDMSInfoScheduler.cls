/**
 * Author: Balveer Choudhary
 * Since: March 10, 2022
 * Name: BRPSendDMSInfoScheduler
 * Description: Scheduler class for send DMS information to BRP server
**/
global without sharing class BRPSendDMSInfoScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        sendDMSInfoToBRP();
    }
    public static String dealerID = BRPUtility.getDealerId();

    @future (callout=true)
    public static void sendDMSInfoToBRP() {
        String requestBody = '{"items": [{"dealer_no": "'+dealerID+'","data_sharing_consent": true}]}';
        HttpResponse response = BRPUtility.syncToBRP('DMSInfo', requestBody);
        insertBRPLog('DMSInfo', requestBody, response);
    }

    public static void insertBRPLog(String entityName, String requestBody, HttpResponse response) {
        BRP_log__c brpLog = BRPUtility.handleResponse(entityName, requestBody, response);
        brpLog.Apex_Class__c = 'BRPSendDMSInfoScheduler';
        DMLUtility.insertSobjectList('BRP_log__c', new List<BRP_log__c>{brpLog});
    }
}
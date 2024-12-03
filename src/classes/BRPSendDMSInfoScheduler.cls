/**
 * Author: Balveer Choudhary
 * Since: March 10, 2022
 * Name: BRPSendDMSInfoScheduler
 * Description: Scheduler class for send DSP information to BRP server. This class is currently using both versions of API - v2 and v4
 * After the certification of v4, only v4 will be used.
 * Script for v2 - 
 *      String CRON_EXP = '0 0 3 * * ? *';
        system.schedule('SendDMSInfoToBRP', CRON_EXP, new BlackPurlCore.BRPSendDMSInfoScheduler('v2'));
 * Script for v4 - 
 *      String CRON_EXP = '0 0 11 * * ? *';
        system.schedule('SendDMSInfoToBRP', CRON_EXP, new BlackPurlCore.BRPSendDMSInfoScheduler());
**/
global without sharing class BRPSendDMSInfoScheduler implements Schedulable {
    
    public String apiVersion;
    global BRPSendDMSInfoScheduler(){}
    global BRPSendDMSInfoScheduler(String apiVersion) {
        this.apiVersion = apiVersion;
    }

    global void execute(SchedulableContext sc) {
        if(BRPUtility.isBRPEnabled()) sendDMSInfoToBRP(this.apiVersion);
    }

    @future(callout=true)
    public static void sendDMSInfoToBRP(String apiVersion) {
        String requestBody = '{"items": [{"dealer_no": "'+BRPUtility.getDealerId()+'", "data_sharing_consent": true}]}';
        String apiName = (apiVersion == 'v4') ? 'DSP Info' : 'DMSInfo';
        HttpResponse response = BRPUtility.syncToBRP(apiName, requestBody);
        BRPUtility.insertBRPLog(apiName, requestBody, response, 'BRPSendDMSInfoScheduler');
    }
}
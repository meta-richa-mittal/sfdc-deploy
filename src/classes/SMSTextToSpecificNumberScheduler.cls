/**
* Author : Manoj Sharma
* Since : May 24, 2023
* Name : SMSTextToSpecificNumberScheduler
* Description : Scheduler class to send sms on specific number.
**/
global without sharing class SMSTextToSpecificNumberScheduler implements Schedulable  {
    public static String phoneNumber = '17192294983';
    global void execute(SchedulableContext sc) {
       if(!KenectService.isKenectEnable() && GeneralConfiguration.isSMSPhoneNumberConfigured()) sendSMSToNumber();
    }

    @future (callout=true)
    global static void sendSMSToNumber() {
        List<Log__c> logListToInsert = new List<Log__c>();
        try {
            String messageText = 'Hi, This is the monthly testing message from the Blackpurl.';
            String response = SendMessage.sendUsingPlivo(phoneNumber, messageText);
            if(response == 'Success') {
                Message_History__c msgRec = new Message_History__c();
                msgRec.Sent_By__c = UserInfo.getUserId();
                msgRec.Phone__c = phoneNumber;
                msgRec.SMS_Body__c = messageText;
                DMLUtility.insertSobjectList('Message_History__c', msgRec);
            } else {
                logListToInsert.add(new Log__c(Integration_Type__c = 'Plivo', Log_Info__c = response,
                                Method_Params__c = 'Phone Number ' + phoneNumber, Method__c = 'sendSMSToNumber()', 
                                Apex_Class__c = 'SMSTextToSpecificNumberScheduler', Type__c = 'Error'));
            }
        } catch (Exception e) {
            logListToInsert.add(new Log__c(Integration_Type__c = 'Plivo', Log_Info__c = e.getMessage(),
	        				Method_Params__c = 'Phone Number ' + phoneNumber, Method__c = 'sendSMSToNumber()', 
							Apex_Class__c = 'SMSTextToSpecificNumberScheduler', Type__c = 'Error'));
        }
        DMLUtility.insertSobjectList('Log__c', logListToInsert);
    }
}
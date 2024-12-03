/** 
* Author: Nidhi Sharma
* Since: Nov 24, 2020
* Name: TextMessageTemplateCtrl 
* Description: Apex class which contains Text message template methods.
**/
global without sharing class TextMessageTemplateCtrl {
    
    global TextMessageTemplateCtrl(NewHomePageCtrl controller){} 
    public TextMessageTemplateCtrl() {}
    
    @RemoteAction
    global static String getSMSTemplateVariables() {
        return BPUtility.getEncodedString(System.JSON.serialize(TextMessageTemplateService.getSMSTemplateVariables(), true));
    }
    
    @RemoteAction
    global static String getAllSMSTemplates() {
        return BPUtility.getEncodedString(System.JSON.serialize(TextMessageTemplateService.getAllSMSTemplates(), true));
    }
    
    @RemoteAction
    global static String saveSMSTemplate(String smsTemplateJsonStr) {
    	smsTemplateJsonStr = BPUtility.getDecodedString(smsTemplateJsonStr);
        TextMessageTemplateService.saveSMSTemplate(smsTemplateJsonStr);
        return 'Success';
    }
    
    @RemoteAction
    global static String deleteSMSTemplateById(String smsTemplateId) {
    	smsTemplateId = BPUtility.getDecodedString(smsTemplateId);
    	TextMessageTemplateService.deleteSMSTemplateById(smsTemplateId);
        return 'Success';
    }
}
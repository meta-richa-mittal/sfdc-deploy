/** 
* Author: Nidhi Sharma
* Since: Nov 24, 2020
* Name: TextMessageTemplateCtrlTest 
* Description: Test class
**/
@isTest
private class TextMessageTemplateCtrlTest {
    
    @testSetup
    private static void setupTestData() {
        Text_Message_Template__c smsTemplateRec = new Text_Message_Template__c();
    	smsTemplateRec.Template_Name__c = 'Test';
    	smsTemplateRec.Template_Body__c = 'Message';
		insert smsTemplateRec;
    }
    
    @isTest
    static void getSMSTemplateVariablesTest() {
    	String response = BPUtility.getDecodedString(TextMessageTemplateCtrl.getSMSTemplateVariables());
    	List<TextMessageTemplateService.TemplateVariable> smsTemplateVarLabelList = (List<TextMessageTemplateService.TemplateVariable>)System.JSON.deserialize(response, List<TextMessageTemplateService.TemplateVariable>.class);
    	system.assertEquals(7, smsTemplateVarLabelList.size());
    }
    
    @isTest
    static void getAllSMSTemplatesTest() {
    	String response = BPUtility.getDecodedString(TextMessageTemplateCtrl.getAllSMSTemplates());
    	List<SMSTemplateWrapper> smsTemplateObjList = (List<SMSTemplateWrapper>)System.JSON.deserialize(response, List<SMSTemplateWrapper>.class);
    	system.assertEquals(1, smsTemplateObjList.size());
    }
    
    @isTest
    static void deleteSMSTemplateByIdTest() {
    	Test.startTest();
	    	List<Text_Message_Template__c> smsTemplateList = [Select Id from Text_Message_Template__c];
	    	system.assertEquals(1, smsTemplateList.size());
	    	TextMessageTemplateCtrl.deleteSMSTemplateById(BPUtility.getEncodedString(smsTemplateList[0].Id));
    	Test.stopTest();
    	smsTemplateList = [Select Id from Text_Message_Template__c];
    	system.assertEquals(0, smsTemplateList.size());
    }
    
    @isTest
    static void saveSMSTemplateTest() {
    	String updatedMessage = 'Updated Message';
    	Test.startTest();
	    	String response = BPUtility.getDecodedString(TextMessageTemplateCtrl.getAllSMSTemplates());
	    	List<SMSTemplateWrapper> smsTemplateObjList = (List<SMSTemplateWrapper>)System.JSON.deserialize(response, List<SMSTemplateWrapper>.class);
	    	smsTemplateObjList[0].Message = updatedMessage;
	    	TextMessageTemplateCtrl.saveSMSTemplate(BPUtility.getEncodedString(System.JSON.serialize(smsTemplateObjList[0])));
    	Test.stopTest();
    	List<Text_Message_Template__c> smsTemplateList = [Select Id, Template_Body__c from Text_Message_Template__c];
    	system.assertEquals(updatedMessage, smsTemplateList[0].Template_Body__c);
    }
}
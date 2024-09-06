@isTest
public without sharing class PlivoIncomingMessageRestAPITest {
    @testSetup
    private static void setupTestData() {
        Account customer = new Account();
        customer.Name = 'Test Plivo' ;
        customer.Email__c = 'Test@gmail.com';
        customer.BillingCity ='Test Billing City';
        customer.Is_Customer__c = true;
        customer.Mobile__c = '17787694433';
        insert customer;
    }
    
    @isTest
    public static void doPostTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();    
        req.requestURI = '/services/apexrest/PlivoIncomingMessageRestAPI/';
        req.httpMethod = 'POST';
        PlivoIncomingMessageService.MessageWrapper messageObj = new PlivoIncomingMessageService.MessageWrapper();
        messageObj.CustomerPhone = '17787694433';
        messageObj.DealershipPhone = '16052913126';
        messageObj.MessageUUID = 'Text message for test';
        messageObj.MessageText = '32646646';
        req.requestBody =  Blob.valueOf(System.JSON.serialize(messageObj));
        RestContext.request= req;
        RestContext.response= res;
        Test.startTest();
        PlivoIncomingMessageRestAPI.doPost();
        Test.stopTest();
        List<Message_History__c> messageList = [Select Id From Message_History__c];
        system.assertEquals(1, messageList.size());
        List<Log__c> logList = [Select Id From Log__c];
        system.assertEquals(0, logList.size());
    }
    
    @isTest
    public static void doPostContainsNoCustomerTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();    
        req.requestURI = '/services/apexrest/PlivoIncomingMessageRestAPI/';
        req.httpMethod = 'POST';
        PlivoIncomingMessageService.MessageWrapper messageObj = new PlivoIncomingMessageService.MessageWrapper();
        messageObj.CustomerPhone = '17787694422';
        messageObj.DealershipPhone = '16052913126';
        messageObj.MessageUUID = 'Text message for test';
        messageObj.MessageText = '32646646';
        req.requestBody =  Blob.valueOf(System.JSON.serialize(messageObj));
        RestContext.request= req;
        RestContext.response= res;
        Test.startTest();
        PlivoIncomingMessageRestAPI.doPost();
        Test.stopTest();
        List<Message_History__c> messageList = [Select Id From Message_History__c];
        system.assertEquals(1, messageList.size());
        List<Log__c> logList = [Select Id From Log__c];
        system.assertEquals(0, logList.size());
    }
}
@isTest
public without sharing class AttachmentBodyRestServiceTest {
    
    @testSetup
    private static void setupTestData() { 
        Document__c document = new Document__c();
        insert document;
        Attachment attach = new Attachment();   	
    	attach.Name='Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=document.id;
        insert attach;
    }

    @isTest
    static void testAttachmentBodyRestService() {
        Attachment attachList = [SELECT Body FROM Attachment limit 1][0];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/GetAttachmentBody/'+attachList.id; //Request URL
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
            String actual = AttachmentBodyRestService.doGet();
        Test.stopTest();
        System.assertEquals('Test Attachment Body', EncodingUtil.base64Decode(actual).toString());
    }
}
@isTest
private class CreatePublicURLForUnitImagesBatchTest {
    @TestSetup
    private static void setup(){
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.Bypass_Validation__c = true;
        bpConfig.Is_Enable_Image_Public_URL__c = true;
        insert bpConfig;
        insert new General_Configurations__c();
        Document__c document = new Document__c();
        insert document;
        Attachment attach = new Attachment();   	
    	attach.Name='Test Attachment';
    	Blob bodyBlob = Blob.valueOf('Test Attachment Body');
    	attach.body = bodyBlob;
        attach.parentId = document.id;
        insert attach;
    }

    @isTest
    private static void testCreatePublicURLForUnitImagesBatchMethods() {
        Test.startTest();
        Database.executebatch(new CreatePublicURLForUnitImagesBatch());
        Test.stopTest();
        list<Attachment> result = [SELECT id from Attachment limit 1];
        system.assertEquals(1, result.size());
    }
}
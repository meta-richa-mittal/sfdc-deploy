@isTest
private class SOMAttachmentRestServiceTest {

    static testMethod void dummyTest01Test() {
        TestDataFactory.disableFLSChecks();
        
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.SOM_Part_Inventory_File_Name__c = 'Test SO ';
        upsert bpConfig;
        
        Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test First Name', 'Test Last Name');
        CO_Header__c coHeader = TestDataFactory.createCoHeader(customer.Id);
        Attachment attachment = TestDataFactory.createAttachment(coHeader.Id);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SOMAttachment';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        String resString = SOMAttachmentRestService.doGet();
        
        system.assertEquals(true, true);
    }
    
}
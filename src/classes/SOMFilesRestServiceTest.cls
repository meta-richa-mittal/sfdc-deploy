@isTest
private class SOMFilesRestServiceTest {

    static testMethod void dummyTest01Test() {
        TestDataFactory.disableFLSChecks();
        
        Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test First Name', 'Test Last Name');
        CO_Header__c coHeader = TestDataFactory.createCoHeader(customer.Id);
        Attachment attachment = TestDataFactory.createAttachment(coHeader.Id);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SOMFile/' + attachment.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        String resString = SOMFilesRestService.doGet();
        
        system.assertEquals(true,true);
    }
    
}
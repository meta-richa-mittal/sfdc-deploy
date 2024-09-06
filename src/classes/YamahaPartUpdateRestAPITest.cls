@isTest
public without sharing class YamahaPartUpdateRestAPITest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        Account vendor1 = TestUtil.createVendor(true, 'Yamaha');
        vendor1.Vendor_Code__c = 'YAM';
        update vendor1;
        Account vendor2 = TestUtil.createVendor(true, 'Honda');
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.Yamaha_Vendor_Code__c = vendor1.Vendor_Code__c;
        upsert bpConfig;
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        List<Part__c> partListToInsert = new List<Part__c>();
        for(integer i = 0; i < 3; i++) {
            partListToInsert.add(TestUtil.createPart(false, '123-4567' + i, vendor1.Id, 'Test Part Yamaha ' + i, testCategory.Id, 10, 20, 50, 100, 100));
        }
        partListToInsert.add(TestUtil.createPart(false, '123-45673', vendor2.Id, 'Test Part Honda', testCategory.Id, 10, 20, 50, 100, 100));
        insert partListToInsert;
    }
    
    @isTest
    public static void doPostTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();    
        req.requestURI = '/services/apexrest/YamahaPartUpdate';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        List<Part__c> partRecs = [SELECT Part_Number__c FROM Part__c ORDER BY Part_Number__c ASC];
        req.requestBody =  Blob.valueOf('[{"partNumber":"Aw0YFC9n3fgXlIVpKyzbGh_mGVOOg2-DuMIBWdXVmCXnfZzF","qty":123},{"partNumber":"'+ partRecs[1].Part_Number__c +'","qty":2},{"partNumber":"'+ partRecs[2].Part_Number__c +'","qty":33},{"partNumber":"'+ partRecs[3].Part_Number__c +'","qty":37}]');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        YamahaPartUpdateRestAPI.ResponseWrapper responseWrapperObj = YamahaPartUpdateRestAPI.doPost();
        Test.stopTest();
        List<Part__c> partList = [SELECT Part_Number__c, Cassons_SOH__c FROM Part__c ORDER BY Part_Number__c ASC];
        system.assertEquals(200, responseWrapperObj.responseCode);
        system.assertEquals('Parts updated successfully', responseWrapperObj.response);
    }

    @isTest
    public static void doPostTest1() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();    
        req.requestURI = '/services/apexrest/YamahaPartUpdate';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        List<Part__c> partRecs = [SELECT Part_Number__c FROM Part__c ORDER BY Part_Number__c ASC];
        req.requestBody =  Blob.valueOf('[{"partNumber":"'+ partRecs[0].Part_Number__c +'","qty":123},{"partNumber":"'+ partRecs[1].Part_Number__c +'","qty":2},{"partNumber":"'+ partRecs[2].Part_Number__c +'","qty":33},{"partNumber":"'+ partRecs[3].Part_Number__c +'","qty":37}]');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        YamahaPartUpdateRestAPI.ResponseWrapper responseWrapperObj = YamahaPartUpdateRestAPI.doPost();
        Test.stopTest();
        List<Part__c> partList = [SELECT Part_Number__c, Cassons_SOH__c FROM Part__c ORDER BY Part_Number__c ASC];
        system.assertEquals(500, responseWrapperObj.responseCode);
    }

}
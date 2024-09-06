@isTest
private class CassonsUtilityTest {
    @TestSetup
    private static void setup(){
        CASSONS_Vendor_List__c cassonsVendorList = new CASSONS_Vendor_List__c(Active__c = true, name = 'vendor 1');
        insert cassonsVendorList;
        CASSONS_Configuration__c cassonsConfiguration = new CASSONS_Configuration__c();
        cassonsConfiguration.Parts_Per_Request__c = 5000;
        cassonsConfiguration.Heroku_End_Point_URL__c = 'https://blackpurl-cassons.herokuapp.com';
        insert cassonsConfiguration;
    }
    @isTest
    private static void testCassonsUtility() {
        Test.startTest();
        CassonsUtility.getAllCassonsVendorsIdSet();
        CassonsUtility.getPartsPerRequest();
        String herokuEndPointURL = CassonsUtility.getHerokuEndPoint();
        CassonsUtility.getSchedulerInterval();
        system.assertEquals('https://blackpurl-cassons.herokuapp.com', herokuEndPointURL);
        Test.stopTest();
    }
}
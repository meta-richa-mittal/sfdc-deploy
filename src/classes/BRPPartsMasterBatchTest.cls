/**
 * Author: Raghav Khandelwal
 * Since: April 09, 2021
 * Name: BRPPartsMasterBatchTest
 * Description: BRPPartsMasterBatch Test class.
**/
@isTest
private class BRPPartsMasterBatchTest {
    
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        TestUtil.createBRPSettings();
        BRP_Vendors_List__c brpVendorListRec = TestUtil.createBRPVendorList(vendor);
        brpVendorListRec.Is_Used_For_Parts_Master__c = true;
        update brpVendorListRec;
        Vendor_Master__c testVendorMaster = TestUtil.createVendorMaster(true, 'Honda us', true, true, true, true, vendor);
        testVendorMaster.Vendor_Master_Type__c = 'BRP Parts Master';
        update testVendorMaster;
        IFW_IntegrationConfig__c ifwConfigRec = TestUtil.createIFWConfigForBRP();
        TestUtil.createIFWConfigItemBRP('GetPartsMaster', ifwConfigRec.Id); 
		Price_File_Mapping__c testPriceFileMapping = TestUtil.createPricefileMapping(true, testVendorMaster.Id);
    }

    @isTest
    private static void testSummaryLogs() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Database.executeBatch(new BRPPartsMasterBatch());
        Test.stopTest();
        List<Summary_Log__c> summaryLog = [Select id from Summary_Log__c];
        system.assertEquals(1, summaryLog.size());
    }

    @isTest
    private static void testErrorLogs() {
        List<BRP_Vendors_List__c> brpVendorListRec = [Select id,Is_Used_For_Parts_Master__c From BRP_Vendors_List__c];
        brpVendorListRec[0].Is_Used_For_Parts_Master__c = false;
        Test.startTest();
        update brpVendorListRec;
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Database.executeBatch(new BRPPartsMasterBatch());
        Test.stopTest();
        List<BRP_log__c> brpLogs = [Select id from BRP_log__c];
        system.assertEquals(1, brpLogs.size());
    }

 
}
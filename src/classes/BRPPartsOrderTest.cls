/**
 * Author: Raghav Khandelwal
 * Since: June 15, 2021
 * Name: BRPPartsOrderTest
 * Description: Test class to validate BRPPartsOrder API
**/
@isTest
public with sharing class BRPPartsOrderTest {

    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks();
        Account testVendor = TestUtil.createVendor(true, 'Test Vendor');
        //TestUtil.createBRPSettings();
        insert new BRP_Settings__c(Dealer_Id__c = '0000691784', Radius_Measure__c = 'mile', Radius__c = 100);
        BRP_Vendors_List__c brpVendorListRec = TestUtil.createBRPVendorList(testVendor);
        brpVendorListRec.Is_Used_For_Parts_Master__c = true;
        update brpVendorListRec;

        IFW_IntegrationConfig__c ifwConfigRec = TestUtil.createIFWConfigForBRP();
        TestUtil.createIFWConfigItemBRP('BRPPartsOrder', ifwConfigRec.Id);

        Category__c categoryRec = TestUtil.createCategory(true, 'Honda');
        Part__c testPartRec = TestUtil.createPart(true, '123456', testVendor.Id, 'part for test', categoryRec.Id);
        
        Vendor_Order_Header__c voHeaderRec = TestUtil.createVendorOrderHeader(true, testVendor.Id);
        Vendor_Order_Line_Item_Group__c voliRec = TestUtil.createVendorOrderLineItemGroup(true, voHeaderRec.Id, testPartRec.Id);
       
    }

    @isTest
    private static void testBRPResponse() {
        Test.startTest();
        List<Vendor_Order_Header__c> voHeaderRec = [SELECT Id FROM Vendor_Order_Header__c LIMIT 1];
        List<Account> vendorRec = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        String result = VendorOrderService.processBRPPartsOrder(voHeaderRec[0].Id,vendorRec[0].Id,'Create');
        Test.stopTest();
        System.assertEquals(true, result.length() > 0);
    }

    @isTest
    private static void getBRPPartsOrderDetailsTest() {
        Test.startTest();
        List<Vendor_Order_Header__c> voHeaderRec = [SELECT Id FROM Vendor_Order_Header__c LIMIT 1];
        List<Account> vendorRec = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        VendorOrderService.processBRPPartsOrder(voHeaderRec[0].Id,vendorRec[0].Id,'Create');
        Test.stopTest();
        String result = VendorOrderService.getBRPPartsOrderDetails(voHeaderRec[0].Id);
        System.assertEquals(null, result);
    }
}
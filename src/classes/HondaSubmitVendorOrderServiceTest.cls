/** 
 * Author: Manoj Sharma
 * Since: Jan 20, 2020 
 * Name: HondaSubmitVendorOrderServiceTest 
 * Description: Test class for Honda Submit Vendor Order Service class
**/
@isTest
public without sharing class HondaSubmitVendorOrderServiceTest {
    public Static Id voHeaderId;
    @testSetup
    private static void testSetup() {
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForHonda();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForHonda('Honda Vendor Order', ifwConfig.Id);
        Honda_Configuration__c hondaConfig = TestDataFactory.createHondaConfig('abc');

        Account testVendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c categoryRec = TestUtil.createCategory(true, 'Honda');
        Part__c testPartRec = TestUtil.createPart(true, '123456', testVendor.Id, 'part for test', categoryRec.Id);
        
        Vendor_Order_Header__c voHeaderRec = TestUtil.createVendorOrderHeader(true, testVendor.Id);
        voHeaderId = voHeaderRec.Id;
        Vendor_Order_Line_Item_Group__c voliRec = TestUtil.createVendorOrderLineItemGroup(true, voHeaderRec.Id, testPartRec.Id);
    }
  
    @isTest
    private static void testSend() {
        Test.setMock(HttpCalloutMock.class, new HondaMockResponseGenerator());
        Test.startTest();
        boolean sendFlag = false;
        List<Vendor_Order_Header__c> voHeaderList = [SELECT Id, name FROM Vendor_Order_Header__c];
        if(voHeaderList.size() > 0) {
            sendFlag = HondaSubmitVendorOrderService.send(voHeaderList.get(0).Id, 'Daily order');
        }
        Test.stopTest();   
        //System.assertEquals(true, sendFlag);     
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());  
    }

    @isTest
    private static void testSendNegative() {
        Test.setMock(HttpCalloutMock.class, new HondaMockResponseGenerator());
        Test.startTest();
        try {
            HondaSubmitVendorOrderService.send('12354885', 'Daily order');
        } catch (Exception e) {
            String message = e.getMessage();
            System.assertEquals('Vendor order list is empty', e.getMessage());
        }
        Test.stopTest();   
    }
}
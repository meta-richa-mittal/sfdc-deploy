/** 
* Author: Tarun Khandelwal
* Since: Dec 27, 2019 
* Name: HondaVendorInvoiceServiceTest 
* Description: Test class for Honda Vendor Invoice Service class
**/
@isTest
public without sharing class HondaVendorInvoiceServiceTest {
    
    @testSetup
    private static void testSetup() {
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForHonda();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForHonda('Honda All Vendor Invoices', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem2 = TestDataFactory.createIFWConfigItemForHonda('Honda Vendor Invoice', ifwConfig.Id);
        Honda_Configuration__c hondaConfig = TestDataFactory.createHondaConfig('abc');
    }
    
    @isTest
    private static void testGetInvoices() {
        Test.setMock(HttpCalloutMock.class, new HondaMockResponseGenerator());
        
        Test.startTest();
        List<String> hondaInvoiceList = HondaVendorInvoiceService.getInvoices();
        Test.stopTest();
        system.assertEquals(3, hondaInvoiceList.size());
    }

    @isTest
    private static void testGetInvoiceData() {
        Test.setMock(HttpCalloutMock.class, new HondaMockResponseGenerator());

        Test.startTest();
        HondaVendorInvoiceService.InvoiceResponseWrapper invoiceData = HondaVendorInvoiceService.getInvoiceData('0012v00002bCZoPAAW');
        Test.stopTest();        
        system.assertEquals('TestVendor', invoiceData.CustomerReference);
    }
}
/**
 * Author: Richa Mittal
 * updated: Jan 13, 2020
 * Name: HondaServiceDataBatchTest
 * Description: It includes scenario based test cases for Honda Service Data Batch class.
**/
@isTest
public without sharing class HondaServiceDataBatchTest {
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForHonda();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForHonda('Honda Service Data', ifwConfig.Id);
        Honda_Configuration__c hondaConfig = TestDataFactory.createHondaConfig('abc');
        Account testCustomer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, false,'Individual');
        testCustomer.Is_Customer__c = true;
        insert testCustomer;
        CO_Header__c coHeader = TestUtil.createCOHeader(true, testCustomer.Id);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, testCustomer.Id, UnitMake.Id, UnitModel.Id, null);
        CO_Invoice_Header__c coInvoiceHeaderRec = new CO_Invoice_Header__c();
        coInvoiceHeaderRec.CO_Header__c = coHeader.Id;
        coInvoiceHeaderRec.Invoice_Status__c = 'Closed';
        Datetime myDateTime = Datetime.newInstance(1960, 2, 17);
        coInvoiceHeaderRec.Invoice_Date__c = myDateTime;
        insert coInvoiceHeaderRec;
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c();
        soHeaderRec.Name__c = 'Test SO Header';
        soHeaderRec.CO_Header__c = coHeader.Id;
        soHeaderRec.Invoice_Number__c = coInvoiceHeaderRec.Id;
        soHeaderRec.Customer_Owned_Unit__c = customerOwnedUnit.Id;
        soHeaderRec.Is_Uploaded_to_Honda__c = false;
        insert soHeaderRec;
    }
    
    @isTest
    private static void testHondaServiceDataBatch() {
        Test.setMock(HttpCalloutMock.class, new HondaMockResponseGenerator());
        
        Test.startTest();
        HondaServiceDataBatch hondaServiceRec = new HondaServiceDataBatch();
        Id batchId = Database.executeBatch(hondaServiceRec);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Service_Order_Header__c WHERE Invoice_Number__c != null AND Invoice_Number__r.Invoice_Status__c = 'Closed']);
    }
}
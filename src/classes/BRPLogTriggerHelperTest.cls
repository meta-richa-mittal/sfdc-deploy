@isTest
public without sharing class BRPLogTriggerHelperTest {
    @testSetup
    private static void setupTestData() {
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForBRP(); 
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPRepairOrder' , IFWConfigObj.Id);
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        TestUtil.createBRPSettings();
        TestUtil.createBRPVendorList(vendor);
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'MSRP', 10 , true, true);
        defaultPriceLevel.Labour_Rate__c = 60 ;
        insert defaultPriceLevel;
        Sales_Tax__c salestax =  TestUtil.createSalesTax(true, 'HST');
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);

        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        SOHeaderWrapper soHeaderObj = (SOHeaderWrapper)Json.deserialize(soHeader,SOHeaderWrapper.class);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnitRec = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnitRec.Unit_Type__c = 'STOCK';
        customerOwnedUnitRec.Status__c = 'Available';
        customerOwnedUnitRec.Vendor__c = vendor.Id;
        insert customerOwnedUnitRec;
        
        update new Service_Order_Header__c(Id = soHeaderObj.SOList[0].SOHeaderInfo.Id, Customer_Owned_Unit__c = customerOwnedUnitRec.Id);
        
        Part__c testpart = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        String soHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(testPart.id),BPUtility.getEncodedString(soHeaderObj.SOList[0].SOHeaderInfo.id),BPUtility.getEncodedString(coHeader.id),BPUtility.getEncodedString(customer.Id)));
  
    }
	
	static testMethod void BRPLogTriggerHelperTestBRP() {
		CO_Header__c coHeaderRec = [Select Id from CO_Header__c];
	    List<CO_Invoice_Header__c> coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c];
        Test.startTest();
       	String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderRec[0].Id)));
        String closedOrder = BPUtility.getDecodedString(CustomerOrderCtrl.closedorderAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeaderRec.Id), BPUtility.getEncodedString('Internal')));
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.stopTest();
        coInvoiceHeaderRec = [Select Available_For_BRP_Repair_Order_Sync__c, Invoice_Number__c, Status__c, Invoice_Date__c from CO_Invoice_Header__c];
        system.assertEquals('Closed',coInvoiceHeaderRec[0].Status__c);
        // if failure
	    BRP_log__c brpLogRec = [Select Id, Apex_Class__c, Response_Code__c, Error_Messages__c, Type__c FROM BRP_log__c ];
	    system.assertEquals(true, coInvoiceHeaderRec[0].Available_For_BRP_Repair_Order_Sync__c);
	    system.assertNotEquals(null, brpLogRec.Error_Messages__c);
	    system.assertEquals('400', brpLogRec.Response_Code__c);
	    system.assertEquals('Error', brpLogRec.Type__c);
	}
}
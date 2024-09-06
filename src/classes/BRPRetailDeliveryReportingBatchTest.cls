/**
 * Author: Reena Singh
 * Since: Jul 10, 2020
 * Name: BRPRetailDeliveryReportingBatchTest test
 * Description: BRP Retail Delivery Reporting Test class.
**/
@isTest
private class BRPRetailDeliveryReportingBatchTest {
    @testSetup
    private static void testSetup() { 
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForBRP(); 
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPRetailDeliveryReporting' , IFWConfigObj.Id);
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        TestUtil.createBRPSettings();
        TestUtil.createBRPVendorList(vendor);
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c testPart1 = TestUtil.createPart(true, 'Part11', vendor.Id, 'Test Part1', testCategory.Id);
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, null, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'Stock';
        customerOwnedUnit.Status__c = 'Available';
        customerOwnedUnit.Vendor__c = vendor.Id;
        insert customerOwnedUnit;
        
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert coHeader;
        
        Deal__c dealRec = new Deal__c(CO_Header__c = coHeader.Id, Status__c = Constants.QUOTATION, Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert dealRec;
        List<Deal__c> dealList = new List<Deal__c>{dealRec};
        
        String dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl.addUnitToDeal(BPUtility.getEncodedString(null),BPUtility.getEncodedString(customerOwnedUnit.Id),BPUtility.getEncodedString(dealList[0].Id)));
        DealWrapper dealWrapperObj = DealWrapper.parse(dealWrapperJSON);
        
        DealWrapper.OptionAndFeeInfo optionAndFeeRec1 = new DealWrapper.OptionAndFeeInfo(new Option_Fee__c());
        String dealInfoObjJson = BPUtility.getDecodedString(CustomerOrderCtrl.updateDealStatus(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString('Approved')));
        DealWrapper.DealInfoWrapper dealInfoObj = (DealWrapper.DealInfoWrapper) System.JSON.deserialize(dealInfoObjJson, DealWrapper.DealInfoWrapper.class);         
    }
    
    static testMethod void createBRPRetailDeliveryReportingBatchTest() {
    	CO_Header__c coHeaderRec = [Select Id from CO_Header__c][0];
	    List<CO_Invoice_Header__c> coInvoiceHeaderRec = [Select Id, Available_For_BRP_RDR_Sync__c from CO_Invoice_Header__c];
        Test.startTest();
       	String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderRec[0].Id)));
        String closedOrder = BPUtility.getDecodedString(CustomerOrderCtrl.closedorderAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeaderRec.Id), BPUtility.getEncodedString('Internal')));
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.stopTest();
        coInvoiceHeaderRec = [Select Available_For_BRP_RDR_Sync__c, Invoice_Number__c, Status__c, Invoice_Date__c from CO_Invoice_Header__c];
        system.assertEquals('Closed',coInvoiceHeaderRec[0].Status__c);
        // if Success
	    List<BRP_log__c> brpLogList = [Select Id, Apex_Class__c, Response_Code__c, Error_Messages__c, Type__c FROM BRP_log__c ];
	    system.assertEquals(false, coInvoiceHeaderRec[0].Available_For_BRP_RDR_Sync__c);
        system.assertEquals(null, brpLogList[0].Error_Messages__c);
	    system.assertEquals('200', brpLogList[0].Response_Code__c);
	    system.assertEquals('Info', brpLogList[0].Type__c);   
    }
}
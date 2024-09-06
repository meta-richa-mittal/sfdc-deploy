@isTest
private class COSectionDetailServiceTest {
    
    @testSetup
    private static void testSetup() {
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        customer.Email__c = null;
        customer.Work_Email__c = null;
        insert customer;
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
        Applicable_Taxes__c appTax = TestUtil.createApplicableTax(true, defaultSalesTax.Id, salesTaxItem.Id);
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, unitmake.Id, unitmodel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'Stock';
        customerOwnedUnit.Status__c = 'Sold';
        insert customerOwnedUnit;
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 50);
        
        String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        soHeaderDetailsObj.SOList[0].SOHeaderInfo.COUId = customerOwnedUnit.Id;
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String jsonStr = System.Json.serialize(soHeaderDetailsObj.SOList[0].SOHeaderInfo);
    }
    
    @isTest
    private static void testCOSectionDetail() {
        CO_Header__c coHeader = [SELECT Id FROM CO_Header__c limit 1];
        Test.startTest();
        COSectionDetailService.createCOSection(coHeader.Id, COSectionDetailService.MERCHANDISE);
        System.assertEquals(1, [SELECT Id FROM CO_Section_Detail__c].size());
        
        COSectionDetailService.deleteCOSection(coHeader.Id, COSectionDetailService.MERCHANDISE);
        System.assertEquals(0, [SELECT Id FROM CO_Section_Detail__c].size());
        
        COSectionDetailService.createCOSection_future(coHeader.Id, COSectionDetailService.MERCHANDISE);
        COSectionDetailService.checkAndCreateCOSection_future(coHeader.Id, COSectionDetailService.MERCHANDISE);
        
        COSectionDetailService.checkAndDeleteCOSection_future(coHeader.Id, COSectionDetailService.DEAL_MERCHANDISE);
        COSectionDetailService.deleteCOSection_future(coHeader.Id, COSectionDetailService.MERCHANDISE);
        Test.stopTest();
        
        COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeader.Id});
        COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeader.Id}, COSectionDetailService.MERCHANDISE);
        
        COSectionDetailService.setSectionStatus(new Set<Id>{coHeader.Id}, COSectionDetailService.MERCHANDISE); 
    }
    
    @isTest
    private static void testCOSectionDetail1() {
    	CO_Header__c coHeader = [SELECT Id FROM CO_Header__c limit 1];
        Test.startTest();
        COSectionDetailService.createCOSection(coHeader.Id, COSectionDetailService.MERCHANDISE);
        System.assertEquals(1, [SELECT Id FROM CO_Section_Detail__c].size());
        
        COSectionDetailService.deleteCOSection(coHeader.Id, COSectionDetailService.MERCHANDISE);
        System.assertEquals(0, [SELECT Id FROM CO_Section_Detail__c].size());
        Test.stopTest();
        
        List<CO_Header__c> coHeaderList = 
            [SELECT Id, (SELECT Section_Type__c, Special_Order_Status__c FROM CO_Section_Details__r),
                    (SELECT Invoice_Number__c FROM Service_Order_Headers__r),
                    (SELECT Special_Order_Belongs_To__c, Special_Order_Status__c FROM Vendor_Order_Line_Items__r Order BY Special_Order_Belongs_To__c ASC) 
                 FROM CO_Header__c WHERE Id =: coHeader.Id];
    	
        COSectionDetailService.setSOStatusForMerchandise(coHeaderList);
        COSectionDetailService.setSOStatusForServiceJobs(coHeaderList);
    }
}
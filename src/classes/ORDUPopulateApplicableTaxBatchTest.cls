@isTest
private class ORDUPopulateApplicableTaxBatchTest {
    
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        Sales_Tax__c purchaseTax =  TestUtil.createSalesTax(false, 'HST');
        purchaseTax.Tax_Type__c = 'Purchase';
        insert purchaseTax;
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
        Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Item1', 10.0, 'Testing1 ', true, testCategory.Id);
         
        Applicable_Taxes__c applicabletax = TestUtil.createApplicableTax(true, purchaseTax.Id, salesTaxItem.Id);
        Applicable_Taxes__c applicabletax1 = TestUtil.createApplicableTax(true, purchaseTax.Id, salesTaxItem1.Id);

        Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        vendor.Purchase_Tax__c = purchaseTax.Id;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c ordu = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        ordu.Unit_Type__c = 'ORDU';
        ordu.Status__c = 'On Order';
        ordu.Mileage_Type__c = 'Km';
        ordu.Vendor__c = vendor.id;
        insert ordu;
    }

    @IsTest
    static void testBatch() {
        Customer_Owned_Unit__c ordu = [Select Unit_Purchase_Tax__c from Customer_Owned_Unit__c where Unit_Type__c = 'ORDU' LIMIT 1];
        system.assertEquals(null, ordu.Unit_Purchase_Tax__c);
        Test.startTest();
        Database.executeBatch(new ORDUPopulateApplicableTaxBatch(), 200);
        Test.stopTest();
        system.assertNotEquals(null, [Select Unit_Purchase_Tax__c from Customer_Owned_Unit__c where Id =: ordu.Id].Unit_Purchase_Tax__c);
    }
}
/**
 * Author: Nidhi Sharma
 * Since: Dec 14, 2022
 * Name: ForeignVendorConversionBatchTest
 * Description: test Class of ForeignVendorConversionBatch.
**/
@isTest
private class ForeignVendorConversionBatchTest {
    
    @testSetup
    private static void setupTestData() {
        TestUtil.bypassValidation();
        TestDataFactory.disableFLSChecks();
    }
    
    static testMethod void getRecordByIdTest() {
        String currencyCode = 'GBP';
        Country__c countryRec = new Country__c(Name__c = 'United Kingdom', Currency_Code__c = currencyCode, Conversion_Rate__c = 10);
        insert countryRec;

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c indvPart = TestUtil.createPart(false, 'part - 1', vendor.Id, 'Individual Part', testCategory.Id, 10, 80, 50, 100, 100);

        Part__c pkgPart = TestUtil.createPart(false, 'package - 2', vendor.Id, 'Test Pkg part', testCategory.Id);
        pkgPart.Packaged_Part__c = true;
        pkgPart.Package_Qty__c = 2;
        pkgPart.Package_Cost__c = 100;
        pkgPart.Last_Cost__c = 50;
        insert new List<Part__c>{indvPart, pkgPart};

        Test.startTest();
        Database.executeBatch(new ForeignVendorConversionBatch(new Map<Id, String>{vendor.Id=> currencyCode}));
        Test.stopTest();
        vendor = [Select Id, Is_Foreign_vendor__c, Country__c FROM Account WHERE Id =: vendor.Id];
        system.assertEquals(true, vendor.Is_Foreign_vendor__c);
        system.assertEquals(countryRec.Id, vendor.Country__c);

        system.assertEquals(8, [Select Id, Foreign_Cost__c FROM Part__c WHERE Id =: indvPart.Id].Foreign_Cost__c);
        pkgPart = [Select Id, Foreign_Cost__c, Foreign_PKG_Cost__c FROM Part__c WHERE Id =: pkgPart.Id];
        system.assertEquals(5, pkgPart.Foreign_Cost__c);
        system.assertEquals(10, pkgPart.Foreign_PKG_Cost__c);
    }
}
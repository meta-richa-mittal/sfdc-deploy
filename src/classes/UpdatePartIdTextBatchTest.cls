@IsTest
private class UpdatePartIdTextBatchTest {
    
    @TestSetup 
    private static void setup() {
        Account vendor = TestDataFactory.createVendor('Test Vendor');
        Category__c category = TestDataFactory.createCategory('Test Category');
        Part__c part = TestDataFactory.createPart(vendor.Id, 100, 100, 100, 100, 10, category.Id);
    }

    @IsTest
    private static void testMatchPartIdTextWithPartNumberAndVendorCode() {
        Part__c part = [SELECT Part_Id_Text__c FROM Part__c LIMIT 1];
        System.assertEquals('Test Part 1231TES', part.Part_Id_Text__c);
        
        Test.startTest();
        Account vendor = [SELECT Vendor_Code__c FROM Account LIMIT 1];
        vendor.Vendor_Code__c = 'updatedVendor';
        update vendor;
        Test.stopTest();
        
        part = [SELECT Part_Id_Text__c FROM Part__c LIMIT 1];
        System.assertEquals('Test Part 1231updatedVendor', part.Part_Id_Text__c);
    }

    @IsTest
    private static void testPartIdTextNotUpdatedOnUpdateOfVendorNumber() {
        Part__c part = [SELECT Part_Id_Text__c FROM Part__c LIMIT 1];
        System.assertEquals('Test Part 1231TES', part.Part_Id_Text__c);
        
        Test.startTest();
        Account vendor = [SELECT Vendor_Number__c, Vendor_Code__c FROM Account LIMIT 1];
        vendor.Vendor_Number__c = '12345678';
        update vendor;
        Test.stopTest();
        
        part = [SELECT Part_Id_Text__c FROM Part__c LIMIT 1];
        System.assertEquals('Test Part 1231TES', part.Part_Id_Text__c);
    }
}
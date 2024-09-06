@IsTest
private class AutomatedPriceFileErrorLogExportCtrlTest {
    
    @testSetup
    private static void setupTestData() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Price_File_Error_Log__c priceFileRecord = new Price_File_Error_Log__c(Vendor__c = vendor.Id);
        priceFileRecord.Part_Number__c = '123456';
        priceFileRecord.Error_Messages__c = 'Null Pointer';
        insert priceFileRecord;
    }
    
    @IsTest
    private static void testFile() {
        Test.startTest();
        AutomatedPriceFileErrorLogExportCtrl obj = new AutomatedPriceFileErrorLogExportCtrl();
        Test.stopTest();
        System.assertEquals(true, obj.fileContent != null);
    }
}
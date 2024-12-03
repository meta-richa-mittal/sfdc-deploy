@IsTest
private class AutomatedPriceFileErrorLogExportCtrlTest {
    
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Vendor_Master__c vmRec = new Vendor_Master__c();
        insert vmRec;
        Summary_Log__c logRec = new Summary_Log__c(Vendor_Master__c = vmRec.Id, Type__c = 'APF');
        insert logRec;
        
        Price_File_Error_Log__c priceFileRecord = new Price_File_Error_Log__c(Vendor__c = vendor.Id);
        priceFileRecord.Part_Number__c = '123456';
        priceFileRecord.Error_Messages__c = 'Null Pointer';
        priceFileRecord.Summary_Log__c = logRec.Id;
        insert priceFileRecord;
    }
    
    @IsTest
    private static void testFile() {
        Summary_Log__c logRec = [Select Id from Summary_Log__c limit 1];
        Test.startTest();
        
        PageReference pageRef = Page.AutomatedPriceFileErrorLogExport;
        pageRef.getParameters().put('summaryLogId', String.valueOf(logRec.Id));
        Test.setCurrentPage(pageRef);
        
        AutomatedPriceFileErrorLogExportCtrl obj = new AutomatedPriceFileErrorLogExportCtrl();
        Test.stopTest();
        System.assertEquals(true, obj.fileContent != null);
    }
}
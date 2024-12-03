@isTest
global without sharing class QB_SyncVOReturnBatchTest {
    @testsetup
    private static void setup(){
    	TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.VENDOR_CREDIT, IFWConfigObj[0].Id);
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.JOURNAL_ENTRY, IFWConfigObj[0].Id);
        Account vendor = TestUtil.createVendor(true, 'Vendor001');
        Category__c category = TestUtil.createCategory(true, 'Category001', 'Part', 'Testing Category', true, true);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'description', category.Id);
        Part_FIFO_Bucket__c fifoBucket = TestUtil.createFifoBucket(true, part.Id, 100, 20, 'Stock Adjustment');
        Return_VO_Header__c  returnVOHeaderRecord = new Return_VO_Header__c();
        returnVOHeaderRecord.RMA__c = 'Test';
        returnVOHeaderRecord.Credit_Memo__c = 'test';
        returnVOHeaderRecord.Vendor__c = vendor.id;
        insert returnVOHeaderRecord;
        Return_VO_Line_Item__c returnVOLIRecord = new Return_VO_Line_Item__c();
        returnVOLIRecord.Return_VO_Header__c = returnVOHeaderRecord.Id;
        returnVOLIRecord.Return_Qty__c = 10;
        returnVOLIRecord.Item_Cost__c = 10;
        returnVOLIRecord.Part__c = part.id;
        returnVOLIRecord.Inventory_Cost__c = 100; //for producing variance
        insert returnVOLIRecord;
        
        String returnVOId  = BPUtility.getEncodedString(returnVOHeaderRecord.id);
        String returnVOJsonForSubmit = ReturnVOCtrl.SubmitReturn(returnVOId);
    }
    
    @isTest
    private static void approveReturnJESyncTest() {
        Return_VO_Header__c returnVOHeaderRecord = [SELECT id from Return_VO_Header__c Limit 1];
        Part_FIFO_Bucket__c fifoBucket = [SELECT id from Part_FIFO_Bucket__c Limit 1];
        Part__c part = [SELECT id from Part__c Limit 1];
        String returnVOId  = BPUtility.getEncodedString(returnVOHeaderRecord.id);
        test.startTest();
        returnVOHeaderRecord.Status__c = 'Approved';
        update returnVOHeaderRecord;
        Part_FIFO_Bucket_Activity_Line_Item__c fifoLI = TestUtil.createFifoBucketLI(false, fifoBucket.Id, 10, part.Id);
        fifoLI.Return_VO_Header__c = returnVOHeaderRecord.Id;
        fifoLI.Reference__c = 'Vendor Return';
        insert fifoLI;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        test.stopTest();
        Part_FIFO_Bucket_Activity_Line_Item__c approvedFIFOLI = [SELECT id, availForQBSync__c, AccountingId__c from Part_FIFO_Bucket_Activity_Line_Item__c Limit 1];
        system.assertEquals(false, approvedFIFOLI.availForQBSync__c);
        system.assertNotEquals(null, approvedFIFOLI.AccountingId__c);
    }
}
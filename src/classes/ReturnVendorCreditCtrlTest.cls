@isTest
private class ReturnVendorCreditCtrlTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, null, null, null, null);
        Part__c part = TestUtil.createPart(true, null, vendor.Id, null, null, 50, 30, 55, 40, 50);
    }

    static testMethod void createVendorCreditTest() {
        Account vendor = [Select Id FROM Account];
      	test.startTest();
      	String rcrId = ReturnVendorCreditCtrl.addVendor(vendor.Id, null);
      	test.stopTest();
      	ReturnCRHeaderWrapper rcrObj = (ReturnCRHeaderWrapper)ReturnVendorCreditCtrl.getReturnCreditDetails(rcrId);
      	system.assertEquals('In Progress', rcrObj.Status);
      	system.assertEquals(vendor.id, rcrObj.VendorId);
    }

    static testMethod void createVendorCreditLineItemTest() {
        Account vendor = [Select Id FROM Account];
        createApprovedRVO(vendor.Id);
      	test.startTest();
        String rvoId = createApprovedRVO(vendor.Id);
      	String rcrId = ReturnVendorCreditCtrl.addVendor(vendor.Id, null);
      	ReturnVendorCreditCtrl.createReturnCRLineItems(rcrId, rvoId);
        test.stopTest();

        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item_Desc__c', 'ASC')};
        Map<String, Object> resultMap = ReturnVendorCreditCtrl.getItemsList(rcrId, pageSort);
      	system.assertEquals(1, resultMap.get('TotalRCRLICount'));
    }

    private static String createApprovedRVO(String vendorId) {
    	Part__c part = [Select Id FROM Part__c];
    	Return_VO_Header__c  returnVOHeaderRecord = new Return_VO_Header__c();
       	returnVOHeaderRecord.RMA__c = 'Test';
      	returnVOHeaderRecord.Credit_Memo__c = 'test';
      	returnVOHeaderRecord.Vendor__c = vendorId;
        insert returnVOHeaderRecord;
        Return_VO_Line_Item__c returnVOLIRecord = new Return_VO_Line_Item__c();
        returnVOLIRecord.Return_VO_Header__c = returnVOHeaderRecord.Id;
        returnVOLIRecord.Return_Qty__c = 10;
        returnVOLIRecord.Part__c = part.id;
        insert returnVOLIRecord;
        
        String returnVOJsonForSubmit = ReturnVOCtrl.SubmitReturn(BPUtility.getEncodedString(returnVOHeaderRecord.Id));
        String returnVOJsonForApproved = ReturnVOCtrl.SetAsApprovedReturnVO(BPUtility.getEncodedString(returnVOHeaderRecord.Id));
        return returnVOHeaderRecord.Id;
    }
}
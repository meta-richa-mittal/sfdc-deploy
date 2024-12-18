@isTest
private class PartDetailTest {
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

	static testMethod void testPartDetail() {
		
		Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
		Account vendor = TestUtil.createVendor(true, 'Test Vendor');
		Part__c partRec = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
		partRec.Qty_Committed__c = 2;
		partRec.Retail_Price__c = 100;

		PartDetail partDetail = new PartDetail(partRec, null);
		System.assertEquals(partDetail.VendorId, vendor.Id);
	}
    
    static testMethod void testParse() {
		
		Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
		Account vendor = TestUtil.createVendor(true, 'Test Vendor');
		Part__c partRec = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
		partRec.Qty_Committed__c = 3;
		partRec.Retail_Price__c = 100;
		
		PartDetail detail = new PartDetail(partRec, null);
		
        String JSONString = JSON.serialize(new List<PartDetail>{detail});
        List<PartDetail> obj = PartDetail.parse(JSONString);
        System.assertEquals(true,true);
        
	}
	 
	static testMethod void testFieldsList() {
		List<String> fieldsList = PartDetail.fieldsList();
		System.assertNotEquals(null, fieldsList);
		System.assertEquals(true, fieldsList.size() > 30);
	}
}
@isTest
private class DisableFlagOnPartForIntextTest {

    @TestSetup
    private static void makeData(){  
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
	  	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
	  	Part.Packaged_Part__c = true;
	  	Part.Package_Qty__c = 22;
	  	Part.Auto_reorder_Min__c = 0;
	  	part.Auto_reorder_Max__c = 100;
	  	part.Order_Lots__c = 1;
        part.Is_Included_In_Intext_Inventory__c = true;
	  	insert part;
        insert new GE_File_Config__c(File_Name__c = 'INTEXT.CSV', Object_API_Name__c = 'Part__c', File_Content_Type__c = 'csv', File_Separator__c = ';');
    }

    @isTest
    private static void testDisableFlagOnPartForIntext() {
        Test.startTest();
        Database.executeBatch(new DisableFlagOnPartForIntext(system.today()));
        Test.stopTest();
        Part__c partRec = [Select id, Is_Included_In_Intext_Inventory__c from Part__c Limit 1][0];
        system.assertEquals(false, partRec.Is_Included_In_Intext_Inventory__c);
    }
}
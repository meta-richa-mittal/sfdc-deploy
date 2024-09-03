@isTest
private class PartPickListServiceTest {
    
    @testSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
    	Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test First Name', 'Test Last Name');
    	CO_Header__c coHeader = TestDataFactory.createCoHeader(customer.Id);
        CO_Line_Item__c CoLineItem = TestDataFactory.createCoLineItem(coHeader.Id, 5);
        Account vendor = TestDataFactory.createVendor('Test vendor');
        Vendor_Order_Header__c VendorOrderHeader = TestDataFactory.createVendorOrderHeader(vendor.id);
        Vendor_Order_Line_Item__c vOLineItem = TestDataFactory.createVendorOrderLineItem(VendorOrderHeader.id);
        Category__c category = TestDataFactory.createCategory('Test Category');
        Part__c part = TestDataFactory.createPart(vendor.id, 500, 450, 700, 650, 10, category.id);
        vOLineItem.CO_Header__c = coHeader.id;
        vOLineItem.CO_Line_Item__c = CoLineItem.id;
        vOLineItem.Is_required_For_Customer__c = true;
        vOLineItem.Is_Service__c = true;
        vOLineItem.Part__c = part.id;
        vOLineItem.Qty_Needed__c = 5;
        update vOLineItem;
    }
    
    @isTest
    private static void testGetPartPickListCOLIList(){
    	Test.startTest();
    	CO_Header__c coHeader = [SELECT Id FROM CO_Header__c LIMIT 1];
    	List<PartPickListCOLIWrapper> result = PartPickListService.getPartPickListCOLIList(coHeader.Id);
    	system.assertEquals(1, result.size());
    	Test.stopTest();
    }
}
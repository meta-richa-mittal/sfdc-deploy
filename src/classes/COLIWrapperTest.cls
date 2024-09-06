@isTest
private class COLIWrapperTest {

    @TestSetup
    private static void makeData(){   
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.id);
        CO_Line_Item__c coLineItem = new CO_Line_Item__c(CO_Header__c = coHeader.id);
        coLineItem.Item_Code__c = 'xyz';
        insert coLineItem;
    }

    @isTest
    private static void TestCOLIWrapper() {
        Test.startTest();
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : COLIWrapper.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM CO_Line_Item__c';
        List<CO_Line_Item__c> coLineItem = Database.query(query1);
        COLIWrapper COLIWrapperItem = new COLIWrapper(coLineItem[0]);
        Test.stopTest();
        system.assertEquals('xyz', COLIWrapperItem.ItemCode);
    }
}
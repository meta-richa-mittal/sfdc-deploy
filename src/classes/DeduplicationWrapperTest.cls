@isTest
private class DeduplicationWrapperTest {

    @TestSetup
    private static void makeData(){  
        TestDataFactory.disableFLSChecks();
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        customer.AccountingId__c = '1234567';
        insert customer;
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.id);
        coHeader.Customer_PO_Number__c = '23445345';
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.Id, 'Closed');
        Service_Order_Header__c soHeaderRec = TestUtil.createSOHeader(coHeader.Id, coinvoiceHeader.Id);
    }

    @isTest
    private static void testDeduplicationWrapper() {
        
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : DeduplicationWrapper.getServiceJobFieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Service_Order_Header__c';
        List<Service_Order_Header__c> soHeaderList = Database.query(query1);
        Test.startTest();
        DeduplicationWrapper deduplicationWrapperObj = new DeduplicationWrapper(soHeaderList[0]);
        Test.stopTest();
        CO_Header__c coHeaderList = [Select id, name from CO_Header__c Limit 1][0];
        system.assertEquals(coHeaderList.name, deduplicationWrapperObj.CONumber);
    }
}


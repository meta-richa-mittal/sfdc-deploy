@isTest
private class CustomerInvoiceHistoryTest {

    @TestSetup
    private static void makeData(){ 
        TestDataFactory.disableFLSChecks(); 
        Branding_Location__c brandingLocationRec = new Branding_Location__c(Is_Disclaimer_for_Service_Job__c = true);
        insert brandingLocationRec;
        Business_Profile__c BusinessProfile= new Business_Profile__c();
        insert BusinessProfile; 
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.id);
        coHeader.Customer_PO_Number__c = '23445345';
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Closed');
        coInvoiceHeader.Invoice_Date__c = system.now();
        insert coInvoiceHeader;
        Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, 
    																												unitSubModel.Id, 'VIN001');
		Deal__c deal = TestDataFactory.createDeal(coHeader.Id, customerOwnedUnit.Id);
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
		for(Integer i = 0; i < 20; i++){
			Deal_Item__c dealItem = TestDataFactory.sampleDealItem(unitModel.Id, deal.Id);
			dealItemList.add(dealItem);
		}
		insert dealItemList;
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, false, 'code', 'code', 'code', 'code', 'code', 12, false, false, null, null);
        CO_Kit_Header__c coKitHeader = new CO_Kit_Header__c(CO_Header__c = coHeader.id, Kit_Header__c = kitHeader.id);
        insert coKitHeader;
        Service_Order_Header__c soHeaderRec = TestUtil.createSOHeader(coHeader.Id, coinvoiceHeader.Id);
        CO_Line_Item__c coLineItem = new CO_Line_Item__c(CO_Header__c = coHeader.id);
        coLineItem.Item_Code__c = 'xyz';
        coLineItem.CO_Kit_Header__c = coKitHeader.id;
        coLineItem.deal__c = deal.id;
        insert coLineItem;
        CO_Invoice_Item__c coInvoiceItem = TestUtil.createCOInvoiceItem(false, testCategory.id, coInvoiceHeader.id, coLineItem.id);
        coInvoiceItem.deal__c = deal.id;
        insert coInvoiceItem;
    }

    @isTest
    private static void TestCustomerInvoiceHistory() {
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM CO_Invoice_Header__c';
        List<CO_Invoice_Header__c> coInvoiceHeaderList = Database.query(query1);
        for(CO_Invoice_Header__c coInvoiceHeaderRec:coInvoiceHeaderList){
            coInvoiceHeaderRec.Invoice_Date__c = system.now();
        }
        update coInvoiceHeaderList;
        Test.startTest();
        CustomerInvoiceHistory coInvoiceHistory = new CustomerInvoiceHistory(coInvoiceHeaderList, 123);
        Test.stopTest();
        system.assertEquals(123, coInvoiceHistory.TotalInvoice);
    }
}
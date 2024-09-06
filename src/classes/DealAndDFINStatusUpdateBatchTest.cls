@isTest
private class DealAndDFINStatusUpdateBatchTest {
    
    @TestSetup
    static void makeData() {
        TestDataFactory.disableFLSChecks();
    }

    @IsTest
    static void executeTest() {
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;

        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        vendor.Finance_Company__c = true;
        insert vendor;

        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        Product__c testProduct1 = TestUtil.createProduct(false, testCategory.Id, 'Test Product2', vendor.Id);
        testProduct1.Type__c = 'Financing Product';
        testProduct1.Taxable__c = true ;
        testProduct1.Applicable_Tax__c = defaultSalesTax.Id;
        testProduct1.Cost__c = 100;
        testProduct1.Price__c = 100;
        insert testProduct1;

        CO_Header__c coHeader1 = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        CO_Header__c coHeader2 = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        CO_Header__c coHeader3 = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert new List<CO_Header__c>{coHeader1, coHeader2, coHeader3};

        Deal__c dealRec1 = new Deal__c(Type__c = 'Financed', CO_Header__c = coHeader1.Id, Status__c = 'Invoiced');
        Deal__c dealRec2 = new Deal__c(Type__c = 'Financed', CO_Header__c = coHeader2.Id, Status__c = 'In Progress');
        Deal__c dealRec3 = new Deal__c(Type__c = 'Financed', CO_Header__c = coHeader3.Id, Status__c = 'In Progress');
        insert new List<Deal__c>{dealRec1, dealRec2, dealRec3};

        Deal_Finance__c dealFinRec1 = new Deal_Finance__c(Deal__c = dealRec1.Id, Finance_Company__c = vendor.Id, Status__c = 'Approved');
        Deal_Finance__c dealFinRec2 = new Deal_Finance__c(Deal__c = dealRec2.Id, Finance_Company__c = vendor.Id, Status__c = 'Approved');
        Deal_Finance__c dealFinRec3 = new Deal_Finance__c(Deal__c = dealRec3.Id, Finance_Company__c = vendor.Id);
        insert new List<Deal_Finance__c>{dealFinRec1, dealFinRec2, dealFinRec3};

        CO_Deposit__c coDepositRec1 = new CO_Deposit__c(CO_Header__c = coHeader3.Id, Deal__c = dealRec3.Id, Payment_Method__c = 'Financing', Amount__c = 100);
        insert coDepositRec1;

        DealWrapper.FIProductWrapper fAndIproductObj1 = new DealWrapper.FIProductWrapper(new F_I_Product__c());
        fAndIproductObj1.ProductId = testProduct1.Id;
        fAndIproductObj1.DealId = dealRec1.Id;
        fAndIproductObj1.DealFinanceId = dealFinRec1.Id;
        CustomerOrderCtrl.saveDealFAndIProduct(BPUtility.getEncodedString(dealRec1.Id),BPUtility.getEncodedString(System.JSON.serialize(fAndIproductObj1)));
        
        DealWrapper.FIProductWrapper fAndIproductObj2 = new DealWrapper.FIProductWrapper(new F_I_Product__c());
        fAndIproductObj2.ProductId = testProduct1.Id;
        fAndIproductObj2.DealId = dealRec2.Id;
        fAndIproductObj2.DealFinanceId = dealFinRec2.Id;
        CustomerOrderCtrl.saveDealFAndIProduct(BPUtility.getEncodedString(dealRec2.Id),BPUtility.getEncodedString(System.JSON.serialize(fAndIproductObj2)));
        
        DealWrapper.FIProductWrapper fAndIproductObj3 = new DealWrapper.FIProductWrapper(new F_I_Product__c());
        fAndIproductObj3.ProductId = testProduct1.Id;
        fAndIproductObj3.DealId = dealRec2.Id;
        fAndIproductObj3.DealFinanceId = dealFinRec3.Id;
        CustomerOrderCtrl.saveDealFAndIProduct(BPUtility.getEncodedString(dealRec3.Id),BPUtility.getEncodedString(System.JSON.serialize(fAndIproductObj3)));
        
        Test.startTest();
        Database.executeBatch(new DealAndDealFINStatusUpdateBatch());
        Test.stopTest();
    }
}

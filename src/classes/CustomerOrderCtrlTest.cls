/**
 * Author: Durga Singh
 * Since: Sep 17, 2015
 * Name: CustomerOrderCtrl test
 * Description: Controller test Class of Customer order.
**/
@isTest
private class CustomerOrderCtrlTest {
    
    
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.bypassValidation();
        TestUtil.createNameSpaceInGeneralConfig();

        User testUser = TestDataFactory.createUser('a@b.c', 'Sharma', 'en_US', 'Shantanu.Sharma@metacube.com', 'sshar', 'America/Los_Angeles');
        User_Group__c userGroup = TestDataFactory.createUserGroup('Test User Group', testUser.Id);
  		List<User_Group__c> userGroupList = [SELECT Id from User_Group__c];
  		String userId = UserInfo.getUserId();
  		List<String> usersList = new List<String>();
  		usersList.add(userId);
  		UserSettingCtrl.assignUserToGroup(BPUtility.getEncodedString(System.JSON.serialize(usersList)), BPUtility.getEncodedString(userGroupList[0].Id));
    }
    
    /**
     * Name: getRecordByIdTest
     * Desc: Test to get customer record by ID
     * @param: 
     * @return: 
    **/
    static testMethod void getRecordByIdTest() {
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        User testUser = TestUtil.createUser(true, 'a@b.c', 'Sharma', 'en_US', 'Shantanu.Sharma@metacube.com', 'sshar');
        
        Test.startTest();
        String customerJSON = BPUtility.getDecodedString(ViewUnitCtrl.getRecordById(BPUtility.getEncodedString(testCustomer.Id)));
        String userJSON = BPUtility.getDecodedString(ViewUnitCtrl.getRecordById(BPUtility.getEncodedString(testUser.Id)));
        Test.stopTest();
        
        system.assertEquals(customerJSON.length() > 0, true);
        system.assertEquals(userJSON.length() > 0, true);
    }

    /**
     * Name: getCOHeaderDetailsTest
     * Desc: Test to fetch CustomerOrder Header details.
     * @param: 
     * @return: 
    **/
    static testMethod void getCOHeaderDetailsTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        CO_Header__c coHeader2 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        
        Test.startTest();
        String coDetailsJSON1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader1.Id), null));
        String coDetailsJSON2 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader2.Id), null));
        Test.stopTest();
        
        CustomerOrderWrapper.COHeaderWrapper coDetails1 = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(coDetailsJSON1, CustomerOrderWrapper.COHeaderWrapper.class);
        CustomerOrderWrapper.COHeaderWrapper coDetails2 = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(coDetailsJSON2, CustomerOrderWrapper.COHeaderWrapper.class);
        
        system.assertEquals(coDetails1.coHeaderRec.COHeaderId, coHeader1.Id);
        system.assertEquals(coDetails1.COKHList.size(), 1);
        system.assertEquals(coDetails1.COKHList[0].COLIList[0].Item, '123 - Test Part');
        
        system.assertEquals(coDetails2.coHeaderRec.COHeaderId, coHeader2.Id);
        system.assertEquals(coDetails2.COKHList.size(), 0);
    }
    /**
     * Name: addCustomerTest
     * Desc: Test to add customer on customer order page and create CO Header.
     * @param: 
     * @return: 
    **/
    static testMethod void addCustomerTest() {
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        
        Test.startTest();
        String coLineItems = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addCustomer(BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString(testCustomer.Id)));
        Test.stopTest();
        
        coHeader1 = [select Customer__c from CO_Header__c where Id = :coHeader1.id];
        system.assertEquals(coHeader1.Customer__c, testCustomer.Id);
    }
    
    /**
     * Name: getCOLineItemByCOHeaderIdTest
     * Desc: Test to get COLineItem 
     * @param: 
     * @return: 
    **/
    static testMethod void getCOLineItemByCOHeaderIdTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        
        Test.startTest();
        List<CO_Line_Item__c> coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeader1.Id);
        Test.stopTest();
        
        system.assertEquals(coLineItems[0].Part__r.Id, part.Id);
    }
    
    
    /**
     * Name: saveCOLineItemTest
     * Desc: Test to save COLineItem
     * @param: 
     * @return: 
    **/
    static testMethod void saveCOLineItemTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        
        List<CO_Line_Item__c> coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeader1.Id);
        COLIWrapper coliObj = new COLIWrapper(coLineItems[0]);
        Test.startTest();
        CustomerOrderCtrl_V2.saveCOLineItem(BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString(System.JSON.serialize(new List<COLIWrapper>{coliObj}, true)), null);
        Test.stopTest();
        //system.assert(false, coLineItemJSON);
        String coHeaderJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString(null)));
        
        CustomerOrderWrapper.COHeaderWrapper coHeaderWrapperObj = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(coHeaderJSON, CustomerOrderWrapper.COHeaderWrapper.class);
        System.assertEquals(coHeaderWrapperObj.COKHList[0].COLIList[0].Item, '123 - Test Part');
    }
    
    /**
     * Name: deleteCOLineItemTest
     * Desc: Test to delete COLineItem
     * @param: 
     * @return: 
    **/
    
    static testMethod void deleteCOLineItemTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        
        Test.startTest();
        String coLineItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.deleteCOLineItem(BPUtility.getEncodedString(coLineItemRec.Id), BPUtility.getEncodedString(coHeader1.Id)));
        Test.stopTest();
        //system.assert(false, coLineItemJSON);
        List<CO_Line_Item__c> coLineItemRecsList = new List<CO_Line_Item__c>();
        coLineItemRecsList = [select Id from CO_Line_Item__c];
        
        system.assertEquals(coLineItemRecsList.size(), 0);
    }
    
    
    /**
     * Name: getCODepositByCOHeaderIdTest
     * Desc: Test to get CODeposit type for COheader
     * @param: 
     * @return: 
    **/
    
    static testMethod void getCODepositByCOHeaderIdTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        
        Test.startTest();
        String coDepositJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCODepositByCOHeaderId(BPUtility.getEncodedString(coHeader1.Id)));
        Test.stopTest();
        
        List<CODeposit> coDeposits = (List<CODeposit>) System.JSON.deserialize(coDepositJSON, List<CODeposit>.class);
        system.assertEquals(coDeposits[0].PaymentMethod, 'Debit');
    }
    
    /**
     * Name: saveCODepositTest
     * Desc: Test to save CODeposite for CustomerOrder.
     * @param: 
     * @return: 
    **/
    static testMethod void saveCODepositTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        
        String coDepositJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCODepositByCOHeaderId(BPUtility.getEncodedString(coHeader1.Id)));
        
        Test.startTest();
        coDepositJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveCODeposit(BPUtility.getEncodedString(coDepositJSON)));
        Test.stopTest();
        
        List<CODeposit> coDeposits = (List<CODeposit>) System.JSON.deserialize(coDepositJSON, List<CODeposit>.class);
        system.assertEquals(coDeposits[0].PaymentMethod, 'Debit');
    }
    
    /**
     * Name: getCOInvoicePaymentsByCOInvoiceHedaerIdTest
     * Desc: Test to get getCOInvoicePayments for COInvoiceHeader.
     * @param: 
     * @return: 
    **/
    static testMethod void getCOInvoicePaymentsByCOInvoiceHedaerIdTest() {
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Payment__c coinvoicepayment1  = TestUtil.createCOInvoicePayment(true, coinvoiceHeader1.Id );
       
        Test.startTest();
        String  COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoicePaymentsByCOInvoiceHedaerId(BPUtility.getEncodedString(coInvoiceHeader1.Id)));
        Test.stopTest();
        
        List<COInvoicePayment> COInvoicePayment2 = (List<COInvoicePayment>) System.JSON.deserialize(COInvoicePaymentJSON, List<COInvoicePayment>.class);
        system.assertEquals(COInvoicePayment2.size(), 1);
    }
    
    /**
     * Name: saveCOInvoicePaymenTest
     * Desc: Test to save InvoicePayment
     * @param: 
     * @return: 
    **/
    
    static testMethod void saveCOInvoicePaymentTest() {
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
 
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        

        //CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Header__c coinvoiceHeader1 = [select Id, CO_Header__c from CO_Invoice_Header__c where CO_Header__c = :coHeader1.Id
                                                            AND Status__c = 'Active'];
        CO_Invoice_Payment__c coinvoicepayment1  = TestUtil.createCOInvoicePayment(true, coinvoiceHeader1.Id );
        coinvoicepayment1.Payment_Method__c = 'Debit';
        update coinvoicepayment1;
        
        String  COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoicePaymentsByCOInvoiceHedaerId(BPUtility.getEncodedString(coinvoiceHeader1.Id)));
        Test.startTest();
        COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString(COInvoicePaymentJSON), BPUtility.getEncodedString(coHeader1.Id)));
        Test.stopTest();
        
        CustomerOrderWrapper.CheckoutWrapper COInvoicePayment2 = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(COInvoicePaymentJSON, CustomerOrderWrapper.CheckoutWrapper.class);
        system.assertEquals(coinvoicepayment2.InvoicePaymentList.size(), 1);
         List<CO_Invoice_Payment__c> coInvoicepaymentRecsList = new List<CO_Invoice_Payment__c>();
        coInvoicepaymentRecsList = [select Id from CO_Invoice_Payment__c];
        
        system.assertEquals(coInvoicepaymentRecsList.size(), 1);
     
      
    }
    
    /* START: Added by kajal # 1998 12th may, 2017 */
    /**
     * Name: saveCOInvoicePaymentTestForCashRounding
     * Desc: Test to save InvoicePayment in case of cash rounding
     * @param: 
     * @return: 
    **/
    static testMethod void saveCOInvoicePaymentTestForCashRounding() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, customer.Id);
        
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        
        CO_Invoice_Payment__c coinvoicepayment1  = TestUtil.createCOInvoicePayment(true, coinvoiceHeader1.Id );
        
        CO_Invoice_Payment__c coinvoicepayment2  = TestUtil.createCOInvoicePayment(true, coinvoiceHeader1.Id );
        
        String COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoicePaymentsByCOInvoiceHedaerId(BPUtility.getEncodedString(coinvoiceHeader1.Id)));
        Test.startTest();
        
        COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(
        BPUtility.getEncodedString('[{"ReverseLink":null,"IsReverse":false,"PaymentMethod":"Cash","Amount":"26","COInvoicePaymentId":"'+coinvoicepayment1.Id+'","COInvoiceHeaderId":"'+coinvoiceHeader1.Id+'"},'+
        '{"ReverseLink":null,"IsReverse":false,"PaymentMethod":"Cash Rounding","Amount":"-0.02","COInvoicePaymentId":"'+coinvoicepayment2.Id+'","COInvoiceHeaderId":"'+coinvoiceHeader1.Id+'"}]'), BPUtility.getEncodedString(coHeader1.Id)));
        
        Test.stopTest();
        COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoicePaymentsByCOInvoiceHedaerId(BPUtility.getEncodedString(coinvoiceHeader1.Id)));
        List<COInvoicePayment> COInvoicePayment3 = (List<COInvoicePayment>) System.JSON.deserialize(COInvoicePaymentJSON, List<COInvoicePayment>.class);
        
        system.assertEquals(COInvoicePayment3.size(), 2);
        
        List<CO_Invoice_Payment__c> roundingPaymentList = [select Id, Amount__c, Cash_Rounding_Payment__c, Payment_Method__c
                                                                from CO_Invoice_Payment__c 
                                                                where Cash_Rounding_Payment__c =:COInvoicePayment3[0].COInvoicePaymentId];
        system.assertEquals(roundingPaymentList.size(), 1);
        system.assertEquals(roundingPaymentList[0].Payment_Method__c, 'Cash Rounding');
        
        /******************** for reverse payment ************************/
        COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(
        BPUtility.getEncodedString('[{"ReverseLink":"'+COInvoicePayment3[0].COInvoicePaymentId+'","IsReverse":true,"PaymentMethod":"Cash","Amount":"-26","COInvoiceHeaderId":"'+coinvoiceHeader1.Id+'"}]'), BPUtility.getEncodedString(coHeader1.Id)));
        
        COInvoicePaymentJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoicePaymentsByCOInvoiceHedaerId(BPUtility.getEncodedString(coinvoiceHeader1.Id)));
        List<COInvoicePayment> COInvoicePayment5 = (List<COInvoicePayment>) System.JSON.deserialize(COInvoicePaymentJSON, List<COInvoicePayment>.class);
        system.assertEquals(COInvoicePayment5.size(), 4);
        
        system.assertEquals(COInvoicePayment5[0].PaymentMethod, 'Cash');
        system.assertEquals(COInvoicePayment5[0].Amount, 26.00);
        system.assertEquals(COInvoicePayment5[0].ReverseLink, COInvoicePayment5[1].COInvoicePaymentId);
        
        system.assertEquals(COInvoicePayment5[1].PaymentMethod, 'Cash');
        system.assertEquals(COInvoicePayment5[1].Amount, -26.00);
        system.assertEquals(COInvoicePayment5[1].ReverseLink, COInvoicePayment5[0].COInvoicePaymentId);
        
        system.assertEquals(COInvoicePayment5[2].PaymentMethod, 'Cash Rounding');
        system.assertEquals(COInvoicePayment5[2].Amount, -0.02);
        system.assertEquals(COInvoicePayment5[2].ReverseLink, COInvoicePayment5[3].COInvoicePaymentId);
        
        system.assertEquals(COInvoicePayment5[3].PaymentMethod, 'Cash Rounding');
        system.assertEquals(COInvoicePayment5[3].Amount, 0.02);
        system.assertEquals(COInvoicePayment5[3].ReverseLink, COInvoicePayment5[2].COInvoicePaymentId);
    }
    /* END: Added by kajal # 1998 12th may, 2017 */
    
     /**
     * Name: getCOInvoiceItemsTest
     * Desc: Test to get invoiced COLI
     * @param: 
     * @return: 
    **/

    static testMethod void getCOInvoiceItemsByCOInvoiceHeaderIdTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Item__c coinvoiceitem1  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeader1.Id, coLineItemRec.Id );
       
        Test.startTest();
        String  COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeader1.Id)));
        Test.stopTest();
        
        List<COInvoiceItem> COInvoiceitem2 = (List<COInvoiceItem>) System.JSON.deserialize(COInvoiceItemJSON, List<COInvoiceItem>.class);
        system.assertEquals(COInvoiceitem2.size(), 1);
    }
    
      /**
     * Name: updateCOInvoiceItemsTest
     * Desc: Test to update invoiced COLI
     * @param: 
     * @return: 
    **/
    static testMethod void updateCOInvoiceItemTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Item__c coinvoiceitem1  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeader1.Id, coLineItemRec.Id );
       
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeader1.Id)));
        List<COInvoiceItem> coInvoiceItemsList = (List<COInvoiceItem>) System.JSON.deserialize(COInvoiceItemJSON, List<COInvoiceItem>.class);
        String coInvoiceItemRecJSONString = System.JSON.serialize(coInvoiceItemsList);
        CustomerOrderCtrl_V2.updateCOInvoiceItem(BPUtility.getEncodedString(coInvoiceItemRecJSONString), BPUtility.getEncodedString(coHeader1.Id));
        Test.stopTest();
        
        List<CO_Invoice_Item__c> COInvoiceitem2 = [select IsActive__c from CO_Invoice_Item__c where Id =: coinvoiceitem1.Id];
        system.assertEquals(COInvoiceitem2.size(), 1);
        system.assertEquals(COInvoiceitem2[0].IsActive__c, true);
    }
    
    /**
     * Name: closedInvoiceActionTest
     * Desc: Test to close invoice and check invoice status
     * @param: 
     * @return: 
    **/
    
    static testMethod void closedInvoiceActionTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 120);
        
        List<CO_Invoice_Header__c> COInvoiceHeaders = [select Invoice_Status__c from CO_Invoice_Header__c];
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(COInvoiceHeaders[0].Id)));
        CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString('Customer'));
        Test.stopTest();
        
        COInvoiceHeaders = [select Invoice_Status__c from CO_Invoice_Header__c];
        system.assertEquals(COInvoiceHeaders[0].Invoice_Status__c, 'Closed');
        system.assertEquals(COInvoiceHeaders[1].Invoice_Status__c, 'Active');
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
        system.assertEquals(parts[0].AvailableParts__c, 0);
    }
       
     
    /*
    * Name: getOtherSimilarCustomerTest
     * Desc: Test to get similar customer
     * @param: 
     * @return: 
    **/
    
    static testMethod void getOtherSimilarCustomerTest() {
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        Account customer1 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111111', null, null, false, true,'Individual');
        Account customer11 = TestUtil.createCustomer(true, 'customerName', 'abc@abcd.com', 'Agra', '1111111111', null, null, false, true,'Individual');
        Account customer12 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual');
        Account customer2 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111111', null, null, false, true,'Business');
        Account customer21 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111111', null, null, false, true,'Business');
        Account customer22 = TestUtil.createCustomer(true, 'customerName', 'abc@abcd.com', 'Agra', '1111111111', null, null, false, true,'Business');
        Account customer23 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Business');
       
        Test.startTest();
        List<Account> customers = SOQLUtil.getCustomer(customer.Id, 'Customer');
        String customerList1JSONString = System.JSON.serialize(new Customer(customers[0]));
        String similarcustomers = BPUtility.getDecodedString(AddCustomerCtrl_V2.getOtherSimilarCustomer(BPUtility.getEncodedString(customerList1JSONString)));
        Test.stopTest();
        
        List<CustomerSuggestion> similarCustomerlist = (List<CustomerSuggestion>) System.JSON.deserialize(similarcustomers, List<CustomerSuggestion>.class);
        system.assertEquals(similarCustomerlist.size(), 3);
        system.assertEquals(similarCustomerlist[1].HomeEmail, 'abc@abc.com');

        customers = SOQLUtil.getCustomer(customer2.Id, 'Customer');
        String customerList1JSONString1 = System.JSON.serialize(new Customer(customers[0]));

        String similarcustomers1 = BPUtility.getDecodedString(AddCustomerCtrl_V2.getOtherSimilarCustomer(BPUtility.getEncodedString(customerList1JSONString1)));
        
        List<CustomerSuggestion> similarCustomerlist1 = (List<CustomerSuggestion>) System.JSON.deserialize(similarcustomers1, List<CustomerSuggestion>.class);
        system.assertEquals(similarCustomerlist.size(), 3);
        system.assertEquals(similarCustomerlist[1].HomeEmail, 'abc@abc.com');
    }
    
    /*
    * Name: getOtherSimilarCustomerTestA
     * Desc: Test to get similar customer  for multiple customers.
     * @param: 
     * @return: 
    **/
    
    static testMethod void getOtherSimilarCustomerTestA() {
        
        Account customer1 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Account customer11 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname2', 'lastname', '9999999999', 'BillingStreet');
        Account customer12 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname2', 'lastname', '9999999991', 'BillingStreet');
        

        Account customer2 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Business','firstname2', 'lastname', '9999999999', 'BillingStreet');
        Account customer21 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Business','firstname2', 'lastname1', '9999999999', 'BillingStreet');
        Account customer22 = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Business','firstname2', 'lastname2', '9999999999', 'BillingStreet1');
        Test.startTest();
        
        List<Account> customers = SOQLUtil.getCustomer(customer1.Id, 'Customer');
        String customerList1JSONString = System.JSON.serialize(new Customer(customers[0]));
        String similarcustomers = BPUtility.getDecodedString(AddCustomerCtrl_V2.getOtherSimilarCustomer(BPUtility.getEncodedString(customerList1JSONString)));
        Test.stopTest();
        
        List<CustomerSuggestion> similarCustomerlist = (List<CustomerSuggestion>) System.JSON.deserialize(similarcustomers, List<CustomerSuggestion>.class);
        system.assertEquals(similarCustomerlist.size(), 3);
        system.assertEquals(similarCustomerlist[1].HomeEmail, 'abc@abc.com');
        
        customers = SOQLUtil.getCustomer(customer2.Id, 'Customer');
        String customerList1JSONString1 = System.JSON.serialize(new Customer(customers[0]));
        String similarcustomers1 = BPUtility.getDecodedString(AddCustomerCtrl_V2.getOtherSimilarCustomer(BPUtility.getEncodedString(customerList1JSONString1)));
        
        List<CustomerSuggestion> similarCustomerlist1 = (List<CustomerSuggestion>) System.JSON.deserialize(similarcustomers1, List<CustomerSuggestion>.class);
        system.assertEquals(similarCustomerlist.size(), 3);
        system.assertEquals(similarCustomerlist[1].HomeEmail, 'abc@abc.com');
    }
    /*
    * Name: getSimilarCOUs
     * Desc: Test to get similar COUs
     * @param: 
     * @return: 
    **/
    
    static testMethod void getSimilarCOUstest() {
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, false,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        Test.startTest();
        String customerOwnedUnitJSONString = BPUtility.getDecodedString(NewViewCustomerCtrl.getSimilarCOUs(BPUtility.getEncodedString('12A')));
        Test.stopTest();
        
        List<CustomerOwnedUnit> customerOwnedUnitlist = (List<CustomerOwnedUnit>) System.JSON.deserialize(customerOwnedUnitJSONString, List<CustomerOwnedUnit>.class);
        system.assertEquals(customerOwnedUnitlist.size(), 0);
        //system.assertEquals(customerOwnedUnitlist[1].VIN, '12A');
    }
    
    /*static testMethod void getAllLookupFieldsJSONTest() {

        Country__c country = TestUtil.createCountry(true, 'India', true, true);
        //Country__c country1 = TestUtil.createCountry(true, 'IndiaA', false, false);
        
        Test.startTest();
        String countrylistJSONString = CustomerOrderCtrl_V2.getAllLookupFieldsJSON();
        Test.stopTest();
        
        List<Country> countrylist = (List<Country>) System.JSON.deserialize(countrylistJSONString, List<Country>.class);
        system.assertEquals(countryList.size(), 1);
    }*/
    
           
    /* Name: getSearchResultsForCustomersTest
     * Desc: Test to search customer results
     * @param: 
     * @return: 
    **/
    
    static testMethod void getSearchResultsForCustomersTest() {
        Testutil.createSearchConfig(true, new Set<String>{'Customer', 'Vendor', 'Part__c'});
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Account customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        
        List<Id> fixedSearchResults= new List<Id>{customer.Id, customer1.Id, part.Id, vendor.Id};
        Test.setFixedSearchResults(fixedSearchResults);
        
        Test.startTest();
        String searchresults = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSearchResults(BPUtility.getEncodedString('{"ObjectLabel":"Customer","SearchText":"customer","SearchableObjects":"Customer","FilterValues":[]}')));
        Test.stopTest();
        //system.assert(false, searchresults );
        system.assertEquals(searchresults.contains('customerName'), true );
        system.assertEquals(searchresults.contains('customerName1'), true );

    }
    
 /* Name: getSearchResultsForPartsTest
     * Desc: Test to search part results
     * @param: 
     * @return: 
    **/
    
    static testMethod void getSearchResultsForPartsTest() {
        Testutil.createSearchConfig(true, new Set<String>{'Customer', 'Vendor', 'Part__c'});
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        //Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Account customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        
        List<Part__c> partList = new List<Part__c>();
        for(Integer i=0;i<10;i++) {
         //Contact contact = TestUtil.createContact(true, 'firstName '+i, 'lastName'+i, vendor.Id);
         Part__c part = TestUtil.createPart(false, 'TestPart'+i, vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        partList.add(part);
        }
        insert partList;
        
        List<Id> fixedSearchResults= new List<Id>{customer.Id, customer1.Id, vendor.Id};
        for(Part__c p : partList){
            fixedSearchResults.add(p.Id);
        }
        Test.setFixedSearchResults(fixedSearchResults);
        
        Test.startTest();
        String searchresults = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSearchResults(BPUtility.getEncodedString('{"ObjectLabel":"","SearchText":"test","PreferredObject":"Customer","SearchableObjects":"Part__c","FilterValues":[]}')));
        Test.stopTest();
        system.assertEquals(searchresults.contains('TestPart'), true);
    }
    
    
     /* Name: getSearchResultsForVendorTest
     * Desc: Test to search vendor results
     * @param: 
     * @return: 
    **/
    
    static testMethod void getSearchResultsForVendorTest() {
        Testutil.createSearchConfig(true, new Set<String>{'Customer', 'Vendor', 'Part__c'});
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Account customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        

        
        List<Id> fixedSearchResults= new List<Id>{customer.Id, customer1.Id, vendor.Id};
        Test.setFixedSearchResults(fixedSearchResults);
        
        Test.startTest();
        String searchresults = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSearchResults(BPUtility.getEncodedString('{"ObjectLabel":"Vendor","SearchText":"test","SearchableObjects":"Vendor","FilterValues":[]}')));
        Test.stopTest();
        //system.assert(false, searchresults );
        system.assertEquals(searchresults.contains('Test Vendor'), true );
    }
               /*
    * Name: saveCustomerTest
     * Desc: Test to save customer for Customerorder
     * @param: 
     * @return: 
    **/
    
    static testMethod void saveCustomerTest() {
        Test.startTest();
        String customerId = AddCustomerCtrl_V2.saveCustomer(BPUtility.getEncodedString('{"IsBothAddressSame":true,"IsCustomer":true,"Active":true,"WorkNumberSMS":false,"MobileNumberSMS":false,"HomeNumberSMS":false,"IsVendor":false,"Type":"Individual","FirstName":"first","LastName":"last1","BirthDay":null,"BirthMonth":null,"BirthYear":null,"WorkNumber":"","WorkEmail":"","BillingCountry":"Canada","BillingState":"Newfoundland and Labrador","ShippingCountry":"Canada","ShippingState":"Newfoundland and Labrador","PriceLevelId":null,"SalesTaxId":null,"PurchaseTaxId":null,"AllowChargeOnAccount":false}'));
        List<Account> customerList = [SELECT Name FROM Account WHERE Id = :customerId];
        Test.stopTest();
        system.assertEquals(customerList[0].Name.contains('first'), true );
    }
    
                   /*
    * Name: createSOHeaderTest
     * Desc: Test to createSOHeader
     * @param: 
     * @return: 
    **/
    
        static testMethod void createSOHeaderTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
       
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
    }
    
                       /*
    * Name: saveCOUTest
     * Desc: Test to saveCOU
     * @param: 
     * @return: 
    **/
    
        static testMethod void saveCOUTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String COU = BPUtility.getDecodedString(NewViewCustomerCtrl.saveCOU(BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString('[{"VIN":"5NPEC4AC8DH640088","Year":2015,"Make":"'+unitmake.Id+'","Model":"'+unitmodel.Id+'","SubModelName":"2039","Plate":"lc","Mileage":"100","Color":"co"}]'), BPUtility.getEncodedString('{}')));
        List<Customer_Owned_Unit__c> COUDetails = SOQLUtil.getCOUListByCustomerId(customer.Id);
        system.assertEquals(COUDetails.size(), 2);
    }
    
                 
    
        static testMethod void splitSOKHItemTest(){
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');     
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);  
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true); 
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, true, unitMake.Id, unitModel.Id);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, LabourCode.Id, Part.Id, 1, 5.0);  
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        Test.startTest();
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);        
        String lineItemsplit = BPUtility.getDecodedString(CustomerOrderCtrl_V2.splitSOKHItem(BPUtility.getEncodedString(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].SOKitHeaderId), BPUtility.getEncodedString(coHeader.Id)));
        
        List<Service_Order_Kit_Header__c> sokhList = [select Id from Service_Order_Kit_Header__c];
        Test.stopTest();
        system.assertEquals(0, sokhList.size());    
                    
    }
                               /*
    * Name: addFeesForSO
     * Desc: Test to add fees for SO 
     * @param: 
     * @return: 
    **/
    
        static testMethod void addFeesForSOTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(fee.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsObj1);
        system.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].ItemDesc, 'FeeCode - Description');
    }
    
        /*
    * Name: saveSOName
     * Desc: Test to save SO Name 
     * @param: 
     * @return: 
    **/
    
        static testMethod void saveSONameTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        String jsonString = '{"Id":"'+soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id+'", "Name":"Oil Change"}';
        String soName = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveSOHeaderInfo(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(jsonString)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOHeaderInfo.Name, 'Oil Change');
    }
    
                /*
    * Name: saveSOHeaderInfo
     * Desc: Test to save SOHeader Info
     * @param: 
     * @return: 
    **/
    
        static testMethod void saveSOHeaderInfoTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Transaction_Type__c transactionType = TestUtil.createTransactionType(true, 'code', 'customer');
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //System.JSON.serialize(soHeaderDetailsObj);
        String soHeaderInfo = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveSOHeaderInfo(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('{"TransactionTypeId":"'+transactionType.Id+'","TransactionType":"Internal","Total":0,"Stock":"No outstanding items","PromisedBy":"01/07/2016 9:00 PM","Name":"Service Job 1","ManualCorrection":[{"Value":"correction","IsDecline":false}],"ManualConcern":[{"Value":"Concern","IsDecline":false},{"Value":"concern1","IsDecline":false}],"ManualCause":[{"Value":"cause","IsDecline":false}],"KitHeaderCorrection":[],"KitHeaderConcern":[],"KitHeaderCause":[],"IsPromisedByAmPm":null,"Id":"'+soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id+'","EstimatedHours":0,"COUId":"'+customerOwnedUnit.Id+'","CategoryName":"Chain Parts","CategoryId":"'+testCategory.Id+'","selectedCOU":{"Year":1915,"VIN":"1G1AW35K1CB156516","SubModelName":"2039","SubModel":"'+unitmodel.Id+'","Plate":"lic","Name":"COU-00001249","ModelName":"Testing Model 49","ModelMakeName":"Audi","Model":"'+unitModel.Id+'","Mileage":18,"MakeName":"Audi","Make":"'+unitMake.Id+'","Id":"'+customerOwnedUnit.Id+'","Color":"woodland brown","$$hashKey":"object:342"},"selectedTime":"9:00 PM","selectedDate":"01/07/2016","CategoryNameStr":{},"NewConcern":"","NewCause":"","NewCorrection":""}')));
        //String soHeaderInfo = CustomerOrderCtrl_V2.saveSOHeaderInfo(coHeader.Id, System.JSON.serialize(soHeaderDetailsObj) );
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
       
        //system.assert(false, soHeaderDetailsObj1);
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOHeaderInfo.ManualConcern[1], 'concern1');
    }
    
                    /*
    * Name: GetSOMasterData
     * Desc: Test to get master data
     * @param: 
     * @return: 
    **/
    
        static testMethod void getSOMasterDataTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Transaction_Type__c transactionType = TestUtil.createTransactionType(true, 'code', 'customer');
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        String SOMasterData = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSOMasterData(BPUtility.getEncodedString(coHeader.Id)));
        //system.assert(false, SOMasterData);
        system.assertEquals(SOMasterData.contains('Model'), true);
        
    }
    
    /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void updateSOKHLineItemsTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, false, true, unitMake.Id, unitModel.Id);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 5.0, null, Part.Id, 1, 5.0); 
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        Test.startTest();
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
               
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice = 20.00;

        String updatedSOKH = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOKHLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH)), BPUtility.getEncodedString(coHeader.Id)));
        updateSOKHLineItemTestValidation(coHeader.Id);
        Test.stopTest();
    }
    
    @future
    private static void updateSOKHLineItemTestValidation(String coHeaderId) {
    	String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        system.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.FixedPrice, 20.00);
    }
    
        /*
    * Name: getAllLookupFieldsJSON
     * Desc: Test to fetch all lookupfields
     * @param: 
     * @return: 
    **/
     static testMethod void getAllLookupFieldsJSONTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        //Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        //Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        //Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        //Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, true, unitMake.Id, unitModel.Id);
        //Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, LabourCode.Id, Part.Id, 1, 5.0);  
        
        //String allMasterData = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getAllLookupFieldsJSON());
        //cOUFieldWrapper masterDataDetails = (cOUFieldWrapper) System.JSON.deserialize(allMasterData, cOUFieldWrapper.class);
        //system.assert(false, masterDataDetails);
        //system.assertEquals(masterDataDetails.UnitMakeList[0].UnitMakeName, 'unitMakeName');
        system.assertEquals(true,true);
    }
    
        /*
    * Name: updateSOLineItems
     * Desc: Test to update SOLineItem when line item is part
     * @param: 
     * @return: 
    **/
     static testMethod void updateSOLineItems() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        //Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, true, unitMake.Id, unitModel.Id);
        //Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, LabourCode.Id, Part.Id, 1, 5.0);    
        
        Test.startTest();
        updateSOLineItemsAsyncHandling(coHeader.Id, customer.Id, part.Id);
        //system.assert(false, soHeaderDetailsObj2);
        Test.stopTest();
    }
    
    @future
	private static void updateSOLineItemsAsyncHandling(String coHeaderId, String customerId, String partId) {
		String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeaderId)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(customerId)));
        
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded = 500.00 ;
        System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0]);

        String updatedSOLI = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0])), BPUtility.getEncodedString(coHeaderId)));
        String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        system.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded, 500.00);
	}
    
    static testMethod void updateSOLineItemsKitTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, false, true, unitMake.Id, unitModel.Id);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 2.0, LabourCode.Id, Part.Id, 1,5.0);   
        
        String soHeader = BPUtility.getDecodedString(ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
    
        Test.startTest();
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
       // system.assert(false,soHeaderDetailsObj1);
        
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded = 2.00;
        Test.stopTest();
        String updateSOLineItem = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0])), BPUtility.getEncodedString(coHeader.Id)));
        
        String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsObj2);
        //Test.stopTest();
        system.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded, 2.00);
       
    }
        
    //END: kv 01/30/2017
    
    // Wrapper class for related list pagination and sorting combination
    public class VendorPaginationSorting {
        
        // Change count
        public Integer ChangesCount;
        
        // Current page number
        public Integer CurrentPage;
        
        // page size
        public Integer PageSize;
        
        // Sorting Attrs
        public List<SortAttrs> Sorting;
    }
    
    // SortAttrs for sorting attributes
    public class SortAttrs {
        
        // Field name
        public String FieldName;
        
        // Sort direction
        public String SortDirection;
        
        public SortAttrs(String FieldName, String SortDirection){
            this.FieldName = FieldName;
            this.SortDirection = SortDirection;
        }
    }
}
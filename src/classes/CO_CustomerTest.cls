@IsTest
private class CO_CustomerTest {

    @TestSetup
    static void makeData() {
        TestDataFactory.disableFLSChecks();
    }

    static String createTestDataForCustomerChangeValidation() {
        List<CO_Header__c> coHeaderList = TestDataFactory_V2.createTestDataForCOHeader(true);
        List<CO_Invoice_Header__c> coInvoiceHeaderList = TestDataFactory_V2.createTestDataForCOInvoiceHeader(coHeaderList, true);
        List<CO_Invoice_Payment__c> coInvoicePaymentList = TestDataFactory_V2.createTestDataForCOInvoicePayment(coInvoiceHeaderList, true);
        List<CO_Deposit__c> coDepositList = TestDataFactory_V2.createTestDataForCODeposit(coHeaderList, true);
        List<Deal__c> dealList = TestDataFactory_V2.createTestDataForDeal(coHeaderList, true);
        List<Deal_Item__c> dealItemList = TestDataFactory_V2.createTestDataForDealItem(dealList, true);
        List<Service_Order_Header__c> soHeaderList = TestDataFactory_V2.createTestDataForServiceOrderHeader(coHeaderList, true);
        return coHeaderList[0].Id;
    }

    static void createTestDataForCustomrOnCO(Boolean createCOWithCustomer) {
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Account> accountList = TestDataFactory_V2.createTestDataForCustomer(accountTypeList, priceLevelList, true);
        
        List<CO_Header__c> coHeaderList = TestDataFactory_V2.createTestDataForCOHeader(false);
        coHeaderList[0].Customer__c = createCOWithCustomer ? accountList[0].Id : null;
        DMLUtility.insertSobjectList('CO_Header__c', coHeaderList);
    }

    @IsTest
    static void testSearchCustomer() {
        Account acc = (Account)TestDataFactory_V2.createSObject(Constants.NAMESPACE+'Account', new Map<String,Object> {
            Constants.NAMESPACE+'Is_Customer__c' => true,
            Constants.NAMESPACE+'Active__c' => true
        });
        String searchQueryJsonStr = BPUtility.getEncodedString('{"SearchableObjects":"Customer","ObjectLabel":"Account", "SearchText":"test0", "FilterValues":[],"IsSpecialSearch":false}');
        String jsonStr = BPUtility.getDecodedString(CustomerOrderCtrl.getSearchResult(searchQueryJsonStr));
        
        // Verifying the result
        List<GenericSearchResultsWrapper> searchObj = (List<GenericSearchResultsWrapper>) System.JSON.deserialize(jsonStr, List<GenericSearchResultsWrapper>.class);
        System.assertEquals(1, searchObj.size());
        System.assertEquals('test0', searchObj[0].Name);
        System.assertEquals('Customer', searchObj[0].Info);
        System.assertEquals(acc.Id, searchObj[0].Id);
    }

    @IsTest
    static void testChangeCustomerValidation() {
        CO_Header__c coHeader = (CO_Header__c)TestDataFactory_V2.createSObject(Constants.NAMESPACE+'CO_Header__c');
        
        String result = validateChangeCustomer(coHeader.Id, false);

        // Verifying the result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(BPUtility.getDecodedString(result));
        System.assertEquals(null, resultMap.get('Error'));
        System.assertEquals(null, resultMap.get('Warnings'));
    }

    @IsTest
    static void testChangeCustomerValidationWithError() {
        String coHeaderId = createTestDataForCustomerChangeValidation();

        String result = validateChangeCustomer(coHeaderId, false);
        
        // Verifying the result
        Map<String, List<String>> resultMap = (Map<String, List<String>>) JSON.deserialize(BPUtility.getDecodedString(result), Map<String, List<String>>.class);
        List<String> errorMsgSet = new List<String> {'An invoice has been generated from the CO.', 'AR credit payments have been made.', 'Active store credit deposits have been made. You must reverse the credit deposit before changing the customer.', 'Deal contains a trade-in which has already been stocked in.'};
        System.assertEquals(errorMsgSet[0], (resultMap.get('Error'))[0]);
        System.assertEquals(errorMsgSet[1], (resultMap.get('Error'))[1]);
        System.assertEquals(errorMsgSet[2], (resultMap.get('Error'))[2]);
        System.assertEquals(errorMsgSet[3], (resultMap.get('Error'))[3]);
    }

    @IsTest
    static void testChangeCustomerValidationWithCustomerDeletion() {
        CO_Header__c coHeader = (CO_Header__c)TestDataFactory_V2.createSObject(Constants.NAMESPACE+'CO_Header__c');

        String result = validateChangeCustomer(coHeader.Id, true);
        
        // Verifying the result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(BPUtility.getDecodedString(result));
        System.assertEquals(null, resultMap.get('Error'));
        System.assertEquals(null, resultMap.get('Warnings'));
    }

    @IsTest
    static void testAddCustomer() {
        createTestDataForCustomrOnCO(false);
        String customerId = [SELECT Id FROM Account LIMIT 1].Id;
        String coHeaderId = [SELECT Id FROM CO_Header__c LIMIT 1].Id;

        customerOnCO(coHeaderId, customerId);

        // Verifying the result
        List<CO_Header__c> coHeaderList = [SELECT Id, Customer__c, Customer__r.Account_Type__r.Name, Customer__r.Price_Level__r.Discount_Markup__c FROM CO_Header__c WHERE Id = :coHeaderId LIMIT 1];
        System.assertEquals(customerId, coHeaderList[0].Customer__c);
        System.assertEquals('Retail Customer', coHeaderList[0].Customer__r.Account_Type__r.Name);
        System.assertEquals(10, coHeaderList[0].Customer__r.Price_Level__r.Discount_Markup__c);
    }

    @IsTest
    static void testDeleteCustomer() {
        createTestDataForCustomrOnCO(true);
        String coHeaderId = [SELECT Id FROM CO_Header__c LIMIT 1].Id;

        customerOnCO(coHeaderId, null);

        // Verifying the result
        System.assertEquals(null, [SELECT Id, Customer__c FROM CO_Header__c WHERE Id = :coHeaderId LIMIT 1].Customer__c);
    }

    @IsTest
    static void testChangeCustomer() {
        createTestDataForCustomrOnCO(true);
        String coHeaderId = [SELECT Id FROM CO_Header__c LIMIT 1].Id;
        Account customer = (Account)TestDataFactory_V2.createSObject(Constants.NAMESPACE+'Account', new Map<String,Object> {
            Constants.NAMESPACE+'Is_Customer__c' => true,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Price_Level__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Account_Type__c' => TestDataFactory_V2.DEFAULT_VALUE
        });
        customerOnCO(coHeaderId, customer.Id);

        // Verifying the result
        List<CO_Header__c> coHeaderList = [SELECT Id, Customer__c, Customer__r.Account_Type__r.Id, Customer__r.Price_Level__r.Id FROM CO_Header__c WHERE Id = :coHeaderId LIMIT 1];
        System.assertEquals(customer.Id, coHeaderList[0].Customer__c);
        System.assertEquals(customer.Account_Type__c, coHeaderList[0].Customer__r.Account_Type__r.Id);
        System.assertEquals(customer.Price_Level__c, coHeaderList[0].Customer__r.Price_Level__r.Id);
        System.assertEquals(customer.Id, [SELECT Id, Customer__c FROM CO_Header__c WHERE Id = :coHeaderId LIMIT 1].Customer__c);
    }

    @IsTest
    static void testActiveCOsByCustomerId() {
        createTestDataForCustomrOnCO(true);
        String accountId = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1].Id;
        String filterJson = BPUtility.getEncodedString('{"StartIndex": 0, "RecordCount": 10, "CustomerId": "' + accountId + '"}');
        
        Test.startTest();
        String result = CustomerOrderCtrl_V2.getActiveCustomerOrdersById(filterJson);
        Test.stopTest();
    
        // Verify the results
        String query = 'SELECT Name, Customer_Name__c, Deal_Header_Total__c, NumberOfDeals__c, Service_Order_Subtotal__c, ' + 
                        'TotalNumberOfSOHeader__c, Merchandise_Total__c, TotalNumberOfCOLI__c, Selling_Group__c, ' + 
                        'LastModifiedDate, Last_Modified_Date__c, Order_status__c FROM CO_Header__c WHERE Customer__c = \'' + accountId + 
                        '\' AND Order_Status__c != \'Closed\' ORDER BY Name Desc ' + 
                        SOQLUtility.getLimitClause(0, 10);
        List<CO_Header__c> coHeaderList = Database.query(query);
        System.assertEquals(BPUtility.getEncodedString(System.JSON.serialize(new GlobalSearchResultsWrapper(1, coHeaderList))), result);    
    }

    @IsTest
    static void testActiveCOCountByCustomerId() {
         createTestDataForCustomrOnCO(true);
         String accountId = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1].Id;

         Test.startTest();
         Integer result = Integer.valueOf(BPUtility.getDecodedString(CustomerOrderCtrl_V2.getActiveCOCountByCustomerId(BPUtility.getEncodedString(accountId))));
         Test.stopTest();

         // Verify the expected output
         System.assertEquals(1, result);
    }

    static void customerOnCO(String coHeaderId, String customerId) {
        Test.startTest();
            CustomerOrderCtrl_V2.addCustomer(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(customerId));
        Test.stopTest();
    }

    static String validateChangeCustomer(String coHeaderId, Boolean isCustomerDeletedFromCO) {
        Test.startTest();
        String result = CustomerOrderCtrl_V2.validateChangeCustomerAction(BPUtility.getEncodedString(coHeaderId), isCustomerDeletedFromCO);
        Test.stopTest();
        return result;
    }
}
@IsTest
public class CO_DeleteCOTest {

    @TestSetup
    public static void makeDataForNewCO() {
        TestDataFactory.disableFLSChecks();
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Category__c> categoryList = TestDataFactory_V2.createTestDataForCategory(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Account> accountList = TestDataFactory_V2.createTestDataForCustomer(accountTypeList, priceLevelList, true);
        List<Sales_Tax_Item__c> salesTaxItemList = TestDataFactory_V2.createTestDataForSalesTaxItem(categoryList, true);
        List<Sales_Tax__c> salesTaxList = TestDataFactory_V2.createTestDataForSalesTax(true);
        List<Tax_Exemption__c> taxExemptionList = TestDataFactory_V2.createTestDataForTaxExemption(accountTypeList, salesTaxItemList, true);
        List<Applicable_Taxes__c> applicableTaxList = TestDataFactory_V2.createTestDataForApplicableTax(salesTaxList, salesTaxItemList, true);
        List<Fee__c> feeList = TestDataFactory_V2.createTestDataForFee(salesTaxList, categoryList, true);
    }

    // ---------------------------- Tax Included Price :OFF ---------------------------- 

    @IsTest
    static void testDeleteMerchandiseCO() {
        CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);
        Test.startTest();
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c];
            CustomerOrderCtrl_V2.removeMerchandiseSection(BPUtility.getEncodedString(coHeaderList[0].Id), true);
        Test.stopTest();    
        assertDeleteMerchandiseCO();
    }

    @IsTest
    static void testDeleteServiceOrderCO() {
        CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
        Test.startTest();
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c];
            List<CO_Header__c> coHeaderList = [SELECT Id FROM Co_Header__c];
            CustomerOrderCtrl_V2.deleteServiceOrder(BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(soHeaderList[0].Id));
        Test.stopTest();
        assertDeleteServiceOrderCO();
    }

    @IsTest
    static void testDeleteUnitDealCO() {
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
        Test.startTest();
            List<Deal__c> dealList = [SELECT Id FROM Deal__c];
            CustomerOrderCtrl_V2.removeDeal(BPUtility.getEncodedString(dealList[0].id));
        Test.stopTest();
        assertDeleteUnitDealCO();
    }

    @IsTest
    static void testDeleteInternalServiceCO() {
        CO_CreateCOTest.coWithCustomer = false;
        CO_CreateCOTest.createCO(CO_CreateCOTest.internalServiceSellingGroup, false);
        Test.startTest();
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c];
            List<CO_Header__c> coHeaderList = [SELECT Id FROM Co_Header__c];
            CustomerOrderCtrl_V2.deleteServiceOrder(BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(soHeaderList[0].Id));
        Test.stopTest();
        assertDeleteInternalServiceCO();
    }

    @IsTest
    static void testDeleteDP360CO() {
        Test.setMock(HttpCalloutMock.class, new DP360LeadServiceTest.DP360MockResponseGenerator());	

        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForDP360();
        TestDataFactory.createIFWConfigItemForDP360('Token', ifwConfig.Id);
        TestDataFactory.createIFWConfigItemForDP360('SearchLead', ifwConfig.Id);
        TestDataFactory.createIFWConfigItemForDP360('Update Lead', ifwConfig.Id);

        String accId = [SELECT Id FROM Account LIMIT 1].Id;

        TestDataFactory_V2.createSObject(Constants.NAMESPACE+'Customer_Owned_Unit__c', new Map<String,Object> {
            Constants.NAMESPACE+'Unit_Type__c' => 'COU',
            Constants.NAMESPACE+'Vin_Number__c' => '1F66F5DY0G0A06626',
            Constants.NAMESPACE+'Account__c' => accId
        });

        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.dp360SellingGroup, false);
            List<Deal__c> dealList = [SELECT Id FROM Deal__c];
            CustomerOrderCtrl_V2.removeDeal(BPUtility.getEncodedString(dealList[0].id));
        Test.stopTest();
        assertDeleteDP360CO();
    }

    public static void assertDeleteServiceOrderCO() {
        applyAssertions(CO_CreateCOTest.serviceJobSellingGroup, false);
    }

    public static void assertDeleteUnitDealCO() {
        applyAssertions(CO_CreateCOTest.unitDealSellingGroup, false);
    }

    public static void assertDeleteMerchandiseCO() {
        applyAssertions(CO_CreateCOTest.partSaleSellingGroup, false);
    }

    public static void assertDeleteInternalServiceCO() {
        applyAssertions(CO_CreateCOTest.internalServiceSellingGroup, false);
    }

    public static void assertDeleteDP360CO() {
        applyAssertions(CO_CreateCOTest.dp360SellingGroup, false);
    }

    static void applyAssertions(String sellingGroup, Boolean isPreventMerchSectionCreation) {

        List<CO_Header__c> coHeaderList = CO_CreateCOTest.getAssertionQueryResult();

        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(sellingGroup == CO_CreateCOTest.partSaleSellingGroup && !isPreventMerchSectionCreation ? 0 : 0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals((sellingGroup == CO_CreateCOTest.internalServiceSellingGroup || sellingGroup == CO_CreateCOTest.serviceJobSellingGroup) ? 1 : 0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(sellingGroup == CO_CreateCOTest.dp360SellingGroup ? 1 : 0, coHeaderList[0].Deals__r.size());

        // 6 Asseriton of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(sellingGroup == CO_CreateCOTest.dp360SellingGroup ? 1 : 0, dealItems.size());

        // 7 Assrtion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(sellingGroup == CO_CreateCOTest.dp360SellingGroup ? 2 : 0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Asseriton of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(sellingGroup == CO_CreateCOTest.internalServiceSellingGroup ? 0 : 1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Asseriton of CO Line Items Creation
        System.assertEquals(sellingGroup == CO_CreateCOTest.partSaleSellingGroup && !isPreventMerchSectionCreation ? 0 : 0, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Account_Type__c, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account LIMIT 1];

        // 12 Assertion for Account type on CO
        System.assertEquals(sellingGroup == CO_CreateCOTest.internalServiceSellingGroup ? null : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals(sellingGroup == CO_CreateCOTest.internalServiceSellingGroup ? 'Internal Service' : 'Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(sellingGroup == CO_CreateCOTest.internalServiceSellingGroup ? null : accountList[0].Id, coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c == null ? 0 : coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c == null ? 0 : coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(0, coHeaderList[0].Deal_Total__c == null ? 0 : coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c == null ? 0 : coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c == null ? 0 : coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c == null ? 0 : coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(0, coHeaderList[0].Uninvoiced_Amount__c == null ? 0 : coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c == null ? 0 : coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Selling Group 
        System.assertEquals(sellingGroup == CO_CreateCOTest.dp360SellingGroup ? CO_CreateCOTest.unitDealSellingGroup : sellingGroup, coHeaderList[0].Selling_Group__c);

        // 27 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 28 Assertion for Order status
        System.assertEquals(true, coHeaderList[0].Hide_Merchandise_Section__c);
    }
}
@IsTest
public class CO_CreateCOTest {
    public static Boolean coWithCustomer = true; 
    public static String   unitDealSellingGroup = 'Unit Deal', 
                            serviceJobSellingGroup = 'Service Order', 
                            partSaleSellingGroup = 'Part Sale', 
                            internalServiceSellingGroup = 'Internal Service', 
                            dp360SellingGroup = 'DP360';

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
        List<Linked_Fee__c> linkedFeeList = TestDataFactory_V2.createTestDataForLinkedFee(feeList, true);
    }

    // ---------------------------- Tax Included Price :ON ---------------------------- 
    @IsTest
    static void testCreateCOWithServiceOrder_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithServiceOrder();
    }
    @IsTest
    static void testCreateCOWithUnitDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithUnitDeal();
    }
    @IsTest
    static void testCreateCOWithOtherSellingGroups_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithOtherSellingGroups();
    }
    @IsTest
    static void testCreateCOWithOtherSellingGroupsWhereMerchSectionCreationFalse_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithOtherSellingGroupsWhereMerchSectionCreationFalse();
    }
    @IsTest
    static void testCreateCOWithInternalService_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithInternalService();
    }
    @IsTest
    static void testCreateCOWithDP360_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        testCreateCOWithDP360();
    }

    // ---------------------------- Tax Included Price :OFF, Enhanced Tax Calculation :ON ---------------------------- 
    @IsTest
    static void testCreateCOWithServiceOrder_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithServiceOrder();
    }
    @IsTest
    static void testCreateCOWithUnitDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithUnitDeal();
    }
    @IsTest
    static void testCreateCOWithOtherSellingGroups_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithOtherSellingGroups();
    }
    @IsTest
    static void testCreateCOWithOtherSellingGroupsWhereMerchSectionCreationFalse_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithOtherSellingGroupsWhereMerchSectionCreationFalse();
    }
    @IsTest
    static void testCreateCOWithInternalService_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithInternalService();
    }
    @IsTest
    static void testCreateCOWithDP360_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        testCreateCOWithDP360();
    }

    // ---------------------------- Tax Included Price :OFF ---------------------------- 
    @IsTest
    static void testCreateCOWithServiceOrder() {
        Test.startTest();
            createCO(serviceJobSellingGroup, false);
        Test.stopTest();
        applyAssertions(serviceJobSellingGroup, false);
    }

    @IsTest
    static void testCreateCOWithUnitDeal() {
        Test.startTest();
            createCO(unitDealSellingGroup, false);
        Test.stopTest();
        applyAssertions(unitDealSellingGroup, false);
    }

    @IsTest
    static void testCreateCOWithOtherSellingGroups() {
        Test.startTest();
            createCO(partSaleSellingGroup, false);
        Test.stopTest();    
        applyAssertions(partSaleSellingGroup, false);
    }

    @IsTest
    static void testCreateCOWithOtherSellingGroupsWhereMerchSectionCreationFalse() {
        Test.startTest();
            createCO(partSaleSellingGroup, true);
        Test.stopTest();
        applyAssertions(partSaleSellingGroup, true);
    }

    @IsTest
    static void testCreateCOWithInternalService() {
        Test.startTest();
            coWithCustomer = false;
            createCO(internalServiceSellingGroup, false);
        Test.stopTest();
        applyAssertions(internalServiceSellingGroup, false);
    }

    @IsTest
    static void testCreateCOWithDP360() {
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
            createCO(dp360SellingGroup, false);
        Test.stopTest();
        applyAssertions(dp360SellingGroup, false);
    }

    public static void createCO(String sellingGroup, Boolean isPreventMerchSectionCreation) {
        String accId;
        if(coWithCustomer) accId = [SELECT Id FROM Account LIMIT 1].Id;
        if(sellingGroup != dp360SellingGroup)
            CustomerOrderCtrl_V2.createCustomerOrder(BPUtility.getEncodedString(accId), BPUtility.getEncodedString(sellingGroup), isPreventMerchSectionCreation);
        else 
            CustomerOrderCtrl_V2.createDealFromDP360(BPUtility.getEncodedString('1050'), BPUtility.getEncodedString(accId));
    }

    static void applyAssertions(String sellingGroup, Boolean isPreventMerchSectionCreation) {

        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(sellingGroup == partSaleSellingGroup && !isPreventMerchSectionCreation ? 1 : 0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals((sellingGroup == dp360SellingGroup || sellingGroup == unitDealSellingGroup || isPreventMerchSectionCreation) ? 0 : 1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(sellingGroup == unitDealSellingGroup || sellingGroup == dp360SellingGroup ? 1 : 0, coHeaderList[0].Deals__r.size());

        // 6 Asseriton of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(sellingGroup == unitDealSellingGroup || sellingGroup == dp360SellingGroup ? 1 : 0, dealItems.size());

        // 7 Assrtion of Service Order Creation 
        System.assertEquals(sellingGroup == serviceJobSellingGroup || sellingGroup == internalServiceSellingGroup ? 1 : 0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(sellingGroup == dp360SellingGroup ? 2 : 0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Asseriton of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(sellingGroup == internalServiceSellingGroup ? 0 : 1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Asseriton of CO Line Items Creation
        System.assertEquals(sellingGroup == partSaleSellingGroup && !isPreventMerchSectionCreation ? 1 : 0, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Account_Type__c, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account LIMIT 1];

        // 12 Assertion for Account type on CO
        System.assertEquals(sellingGroup == internalServiceSellingGroup ? null : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals(sellingGroup == internalServiceSellingGroup ? 'Internal Service' : 'Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(sellingGroup == internalServiceSellingGroup ? null : accountList[0].Id, coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(sellingGroup == partSaleSellingGroup && !isPreventMerchSectionCreation ? (GeneralConfiguration.getTaxIncludingPricing() ? 0.91 : (GeneralConfiguration.IsEnhancedTaxCalculation() ? 51.03 : 1.00)) : 0, coHeaderList[0].Parts_And_Accessories_Total__c == null ? 0 : coHeaderList[0].Parts_And_Accessories_Total__c);

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
        System.assertEquals(sellingGroup == partSaleSellingGroup && !isPreventMerchSectionCreation ? (GeneralConfiguration.getTaxIncludingPricing() ? 0.91 : (GeneralConfiguration.IsEnhancedTaxCalculation() ? 51.03 : 1.00)) : 0, coHeaderList[0].Uninvoiced_Amount__c == null ? 0 : coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(sellingGroup == partSaleSellingGroup && !isPreventMerchSectionCreation ? (GeneralConfiguration.getTaxIncludingPricing() ? 0.91 : 1.00) : 0, coHeaderList[0].Merchandise_Total__c == null ? 0 : coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Selling Group 
        System.assertEquals(sellingGroup == dp360SellingGroup ? unitDealSellingGroup : sellingGroup, coHeaderList[0].Selling_Group__c);

        // 27 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 28 Assertion for Order status
        System.assertEquals(sellingGroup == partSaleSellingGroup ? isPreventMerchSectionCreation : true, coHeaderList[0].Hide_Merchandise_Section__c);
    }

    public static List<CO_Header__c> getAssertionQueryResult () {
        List<CO_Header__c> coHeaderList = [SELECT Id, Account_Type__c, CO_Type__c, Customer__c, Discount_Markup_From_Prive_Level__c, Labour_Rate_From_Price_Level__c, 
                                            Parts_And_Accessories_Total__c, Selling_Group__c, Total_SO__c, Total_Deposit__c, Total_Deposit_And_Payment__c,
                                            Uninvoiced_Amount__c, Part_Price_Base_From_Price_Level__c, Order_status__c, Merchandise_Transaction_Type__c, Merchandise_Total__c,
                                            Total_Payment__c, Deal_Total__c, Hide_Merchandise_Section__c, 
                                            (SELECT Id FROM CO_Section_Details__r),
                                            (SELECT Id FROM Tax_Exemptions__r),
                                            (SELECT Id FROM CO_Line_Items__r),
                                            (SELECT Id FROM CO_Invoice_Headers__r),
                                            (SELECT Id FROM CO_Deposits__r),
                                            (SELECT Id FROM Deals__r),
                                            (SELECT Id FROM Service_Order_Headers__r),
                                            (SELECT Id FROM Internal_Comments__r),
                                            (SELECT Id FROM Fees__r),
                                            (SELECT Id FROM CO_Kit_Headers__r)
                                            FROM CO_Header__c LIMIT 1];

        return coHeaderList;
    }
}
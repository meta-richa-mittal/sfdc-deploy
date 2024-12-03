@IsTest
private class CO_MerchandiseTest {

    @TestSetup
    static void makeData() {
        TestDataFactory.disableFLSChecks();
    }

    static void testData() {
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Category__c> categoryList = TestDataFactory_V2.createTestDataForCategory(true);
        List<Account> vendorList = TestDataFactory_V2.createTestDataForVendor(true);
        List<Sales_Tax_Item__c> salesTaxItemList = TestDataFactory_V2.createTestDataForSalesTaxItem(categoryList, true);
        List<Sales_Tax__c> salesTaxList = TestDataFactory_V2.createTestDataForSalesTax(true);
        List<Tax_Exemption__c> taxExemptionList = TestDataFactory_V2.createTestDataForTaxExemption(accountTypeList, salesTaxItemList, true);
        List<Applicable_Taxes__c> applicableTaxList = TestDataFactory_V2.createTestDataForApplicableTax(salesTaxList, salesTaxItemList, true);
        List<Fee__c> feeList = TestDataFactory_V2.createTestDataForFee(salesTaxList, categoryList, true);
        List<Part__c> partList = TestDataFactory_V2.createTestDataForPart(categoryList, vendorList, salesTaxList, true);
        List<Linked_Fee__c> linkedFeeList = TestDataFactory_V2.createTestDataForLinkedFee(feeList, true);
        List<Kit_Header__c> kitHeaderList = TestDataFactory_V2.createTestDataForKit(true);
        List<Kit_Header_Line_Item__c> kitHeaderLineItemList = TestDataFactory_V2.createTestDataForKitLineItem(partList, feeList, kitHeaderList, true);
    }
    
    // ---------------------------- Tax Included Price :ON ---------------------------- 
    @IsTest
    static void addFeeToMerchandiseBeforeCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addFeeToMerchandiseBeforeCOCreation();
    }

    @IsTest
    static void addFeeToMerchandiseAfterCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addFeeToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addPartToMerchandiseBeforeCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addPartToMerchandiseBeforeCOCreation();
    }

    @IsTest
    static void addPartToMerchandiseAfterCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addPartToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addKitToMerchandiseBeforeCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addKitToMerchandiseBeforeCOCreation();
    }

    @IsTest
    static void addKitToMerchandiseAfterCOCreation_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addKitToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addMultipleLineItemsToCashSaleMerchandise_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addMultipleLineItemsToCashSaleMerchandise();
    }

    @IsTest
    static void updateMultipleLineItemsToCashSaleMerchandise_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        updateMultipleLineItemsToCashSaleMerchandise();
    }

    @IsTest
    static void deleteMultipleLineItemsToCashSaleMerchandise_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        deleteMultipleLineItemsToCashSaleMerchandise();
    }

    // ---------------------------- Tax Included Price :OFF, Enhanced Tax Calculation :ON ---------------------------- 
    @IsTest
    static void addFeeToMerchandiseBeforeCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addFeeToMerchandiseBeforeCOCreation();
    }

    @IsTest
    static void addFeeToMerchandiseAfterCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addFeeToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addPartToMerchandiseBeforeCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addPartToMerchandiseBeforeCOCreation();
    }
    @IsTest
    static void addPartToMerchandiseAfterCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addPartToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addKitToMerchandiseBeforeCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addKitToMerchandiseBeforeCOCreation();
    }
    @IsTest
    static void addKitToMerchandiseAfterCOCreation_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addKitToMerchandiseAfterCOCreation();
    }

    @IsTest
    static void addMultipleLineItemsToCashSaleMerchandise_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addMultipleLineItemsToCashSaleMerchandise();
    }

    @IsTest
    static void updateMultipleLineItemsToCashSaleMerchandise_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        updateMultipleLineItemsToCashSaleMerchandise();
    }

    @IsTest
    static void deleteMultipleLineItemsToCashSaleMerchandise_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        deleteMultipleLineItemsToCashSaleMerchandise();
    }

    // ---------------------------- Tax Included Price :OFF ---------------------------- 
    @IsTest
    static void addFeeToMerchandiseBeforeCOCreation() {
        Test.startTest();
            testData();
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            String jSONString = '{1687159}';
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, feeList.isEmpty() ? null : feeList[0].Id);
        Test.stopTest();

        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(91.82, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(91.82, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(91.82, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(204.03, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(204.03, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(101.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(101.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(101.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(101.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addFeeToMerchandiseAfterCOCreation() {
        Test.startTest();
            testData();
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            String jSONString = '{1687159}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, feeList.isEmpty() ? null : feeList[0].Id);
            Test.stopTest();

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
    
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(91.82, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(91.82, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(91.82, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(204.03, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(204.03, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(101.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(101.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(101.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(101.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addPartToMerchandiseBeforeCOCreation() {
        Test.startTest();
            testData();
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "'+ part.Qty_In_Stock__c +'", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, null);
        Test.stopTest();

        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(500.91, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(500.91, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(500.91, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(667.53, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(667.53, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(551.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals(accountList.isEmpty() ? 'Cash Sale' : 'Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(551.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(551.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(551.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addPartToMerchandiseAfterCOCreation() {
        Test.startTest();
            testData();
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);
            String customerId = null;
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "'+ part.Qty_In_Stock__c +'", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            String soHeaderId = null;
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;

            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));
        Test.stopTest();

        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(500.91, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(500.91, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(500.91, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(667.53, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(667.53, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(551.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(2, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(551.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(551.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(551.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addKitToMerchandiseBeforeCOCreation() {
        Test.startTest();
            testData();
            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            String jSONString = '{"entityId" : "' + kitHeaderList[0].Id + '", "UUID" : ""}';
            CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), null);
        Test.stopTest();

        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Cash Sale', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(191.82, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(191.82, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(191.82, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Cash Sale', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(367.33, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(367.33, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(211.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Cash Sale', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(211.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(211.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(211.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addKitToMerchandiseAfterCOCreation() {
        Test.startTest();
            testData();
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            String jSONString = '{"entityId" : "' + kitHeaderList[0].Id + '", "UUID" : ""}';

            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeaderList[0].Id));
        Test.stopTest();

        
        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(191.82, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(191.82, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(191.82, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(367.33, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(367.33, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(211.00, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(0, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(0, dealItems.size());

            // 7 Assertion of Service Order Creation 
            System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

            // 8 Assertion of Internal Comment Creation
            System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

            // 9 Assertion of Fee Creation 
            System.assertEquals(0, coHeaderList[0].Fees__r.size());

            // 10 Assertion of Tax Exemption Creation 
            System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

            // 11 Assertion of CO Line Items Creation
            System.assertEquals(3, coHeaderList[0].CO_Line_Items__r.size());

            List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
            List<Account_Type__c> accountTypeList;
            List<Price_Level__c> PriceLevelList;
            if(accountList.isEmpty()) {
                accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
                priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            }

            // 12 Assertion for Account type on CO
            System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

            // 13 Assertion for CO type on CO
            System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

            // 14 Assertion for Customer on CO
            System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

            // 15 Assertion for Discount Markup From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

            // 16 Assertion for Labour Rate From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

            // 17 Assertion for part Price Base From Price Level
            System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

            // 18 Assertion for Parts And Accessories Total on CO
            System.assertEquals(211.00, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(211.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(211.00 , coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addMultipleLineItemsToCashSaleMerchandise() {
            testData();
            String customerId = null;
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);

            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "3", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            String soHeaderId = null;
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;
        
        Test.startTest();
            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));

            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            jSONString = '{"entityId" : "' + kitHeaderList[0].Id + '", "UUID" : ""}';

            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeaderList[0].Id));

            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            jSONString = '{1687159}';
            TestDataFactory_V2.resetAllStaticVariables();
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, feeList.isEmpty() ? null : feeList[0].Id);
        Test.stopTest();

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertAddMultipleLineItemsToCashSaleMerchandise_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertAddMultipleLineItemsToCashSaleMerchandise_Enhanced(coHeaderList); }
        else { assertAddMultipleLineItemsToCashSaleMerchandise(coHeaderList); }
    }

    static void assertAddMultipleLineItemsToCashSaleMerchandise_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(582.73, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(582.73, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(582.73, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    static void assertAddMultipleLineItemsToCashSaleMerchandise_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(910.23, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(910.23, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(641.00, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    static void assertAddMultipleLineItemsToCashSaleMerchandise(List<CO_Header__c> coHeaderList) {

        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(641.00, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(641.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(641.00, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    @IsTest
    static void updateMultipleLineItemsToCashSaleMerchandise() {
        testData();

        Test.startTest();
            String customerId = null;
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);

            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "3", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            String soHeaderId = null;
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;

            // Add Part
            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));

            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            jSONString = '{"entityId" : "' + kitHeaderList[0].Id + '", "UUID" : ""}';

            // Add Fee
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeaderList[0].Id));
        
            // Add Kit
            jSONString = '{1687159}';
            TestDataFactory_V2.resetAllStaticVariables();
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, feeList.isEmpty() ? null : feeList[0].Id);
        Test.stopTest();

        List<CO_Line_Item__c> coLineItemList = [SELECT Id, Kit_Header_Line_Item__c, Part__c, Is_Linked_Fee__c, Fee__c FROM CO_Line_Item__c WHERE CO_Header__c = :coHeaderList[0].Id];
        String partCOLIRecId;
        String feeCOLIRecId;
        String kitPartCOLIRecId;
        String kitFeeCOLIRecId;
        for(CO_Line_Item__c coLineItemRec : coLineItemList) {
            if(String.isNotBlank(coLineItemRec.Part__c) && String.isBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                partCOLIRecId = coLineItemRec.Id;
            } else if(!coLineItemRec.Is_Linked_Fee__c && String.isNotBlank(coLineItemRec.Fee__c) && String.isBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                feeCOLIRecId = coLineItemRec.Id;
            } else if(String.isNotBlank(coLineItemRec.Part__c) && String.isNotBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartCOLIRecId = coLineItemRec.Id;
            } else if(!coLineItemRec.Is_Linked_Fee__c && String.isNotBlank(coLineItemRec.Fee__c) && String.isNotBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeCOLIRecId = coLineItemRec.Id;
            }
        }
        // Update Part
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '[{"VOHeaderList": [],"VendorId": " ' + vendor.Id + '","UUID": "","Tax": 0,"SubTotal": 330,"StockCommitedCpy": 3,"Status": "In Stock","Retail": 110,"QtyOrder": 0,"QtyCpy": 3,"QtyCommitted": 3,"Qty": 3,"Price": "150.00","PartId": "'+ part.Id +'","OversoldQty": 0,"OnOrderPartQty": 0,"NonInventoryPart": false,"ItemDescription": "test0","ItemCode": "test0","Item": "test0 - test0","IsSupersededPart": false,"isSpecialOrder": false,"IsNonInventoryPart": false,"IsForeignVendor": false,"IsFixedPriceForCO": false,"IsFixedPrice": false,"IsBRPPart": false,"Invoice": "","FulfillDate": "2023-07-25","ExpectedDeliveryDate": "07/24/2023","EntityType": "Part","CoLineItemId": "' + partCOLIRecId + '","CassonsSOH": 0,"AvaliablePartsQty": 2,"ActualRetailPrice": 100,"ActualKitPrice": 110,"ActualAvailableParts": 5,"isAsyncActionInProgress": true}]';
        addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, null);
        
        // Update Fee
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '[{"VOHeaderList":[],"Tax":0,"SubTotal":1,"StockCommitedCpy":1,"Status":"Ready","Retail":1,"QtyOrder":0,"QtyCpy":1,"QtyCommitted":1,"Qty":1,"Price":"2.00","OversoldQty":0,"ItemDescription":"edoceef","ItemCode":"feecode","Item":"feecode - edoceef","IsSupersededPart":false,"isSpecialOrder":false,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsBRPPart":false,"Invoice":"","FulfillDate":"2023-07-24","FeeId":"'+ feeList[0].Id +'","ExpectedDeliveryDate":"07/24/2023","EntityType":"Fee","CoLineItemId":"'+ feeCOLIRecId +'","CassonsSOH":0,"ActualRetailPrice":0,"ActualKitPrice":1,"isAsyncActionInProgress":true}]';
        addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, null);

        // Update Kit
        TestDataFactory_V2.resetAllStaticVariables();
        List<CO_Kit_Header__c> coKitHeaderList = [SELECT Id FROM CO_Kit_Header__c WHERE CO_Header__c = :coHeaderList[0].Id];
        jSONString = '{"UUID": "", "TaxAmount": 0, "Price": "220.00", "ItemDescription": "test0 - test0", "IsServiceKit": false, "IsFixedPrice": false, "IsFixedKitHeaderCO": true, "Id": "'+ coKitHeaderList[0].Id +'", "hasChildren": true, "COLIList": [{"VOHeaderList": [], "Tax": 0, "SubTotal": 90, "StockCommitedCpy": 0, "Status": "Ready", "Retail": 0, "QtyOrder": 1, "QtyCpy": 1, "QtyCommitted": 0, "Qty": 1, "Price": 100, "OversoldQty": 0, "ItemDescription": "test0", "ItemCode": "feecode", "Item": "feecode - test0", "IsSupersededPart": false, "isSpecialOrder": false, "IsFixedPriceForCO": false, "IsFixedPrice": false, "IsBRPPart": false, "Invoice": "", "FulfillDate": "2023-07-25", "FeeId": "'+feeList[0].Id+'", "ExpectedDeliveryDate": "07/25/2023", "EntityType": "Fee", "CoLineItemId": "'+kitFeeCOLIRecId+'", "CassonsSOH": 0, "ActualRetailPrice": 0, "ActualKitPrice": 100, "$$hashKey": "object:683"}, {"VOHeaderList": [], "VendorId": " ' + vendor.Id + '", "Tax": 0, "SubTotal": 110, "StockCommitedCpy": 1, "Status": "In Stock", "Retail": 100, "QtyOrder": 0, "QtyCpy": 1, "QtyCommitted": 1, "Qty": 1, "Price": 110, "PartId": " '+part.Id+' ", "OversoldQty": 0, "OnOrderPartQty": 0, "NonInventoryPart": false, "ItemDescription": "test0", "ItemCode": "test0", "Item": "test0 - test0", "IsSupersededPart": false, "isSpecialOrder": false, "IsNonInventoryPart": false, "IsForeignVendor": false, "IsFixedPriceForCO": true, "IsFixedPrice": false, "IsBRPPart": false, "Invoice": "", "FulfillDate": "2023-07-25", "ExpectedDeliveryDate": "07/25/2023", "EntityType": "Part", "CoLineItemId": "'+kitPartCOLIRecId+'", "CassonsSOH": 0, "AvaliablePartsQty": 1, "ActualRetailPrice": 100, "ActualKitPrice": 110, "ActualAvailableParts": 2}], "CanItSplit": true, "ActualKitPrice": 210, "isAsyncActionInProgress": true}';
        CustomerOrderCtrl_V2.updateCOKHLineItemsRecalculation(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString('null'));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertUpdateMultipleLineItemsToCashSaleMerchandise_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertUpdateMultipleLineItemsToCashSaleMerchandise_Enhanced(coHeaderList); }
        else { assertUpdateMultipleLineItemsToCashSaleMerchandise(coHeaderList); }
    }

    static void assertUpdateMultipleLineItemsToCashSaleMerchandise_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(582.73, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(662.91, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(662.91, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    static void assertUpdateMultipleLineItemsToCashSaleMerchandise_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(910.23, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(942.89, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(673.00, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    static void assertUpdateMultipleLineItemsToCashSaleMerchandise(List<CO_Header__c> coHeaderList) {

        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(5, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(641.00, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(673.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(673.00, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(4, coInvoiceItemList.size());
    }

    
    @IsTest
    static void deleteMultipleLineItemsToCashSaleMerchandise() {
        testData();

        Test.startTest();
            String customerId = null;
            CO_CreateCOTest.coWithCustomer = false;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);

            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "3", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            String soHeaderId = null;
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;

            // Add Part
            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));

            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            jSONString = '{"entityId" : "' + kitHeaderList[0].Id + '", "UUID" : ""}';

            // Add Fee
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            TestDataFactory_V2.resetAllStaticVariables();
            CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeaderList[0].Id));
        
            // Add Kit
            jSONString = '{1687159}';
            TestDataFactory_V2.resetAllStaticVariables();
            addLineItemOnMerchBeforeCOIdGeneration(coHeaderList.isEmpty() ? null : coHeaderList[0].Id, jSONString, feeList.isEmpty() ? null : feeList[0].Id);
        Test.stopTest();

        List<CO_Line_Item__c> coLineItemList = [SELECT Id, Kit_Header_Line_Item__c, Part__c, Is_Linked_Fee__c, Fee__c FROM CO_Line_Item__c WHERE CO_Header__c = :coHeaderList[0].Id];
        String partCOLIRecId;
        String feeCOLIRecId;
        String kitPartCOLIRecId;
        String kitFeeCOLIRecId;
        String linkedFeeCOLIRecId;
        for(CO_Line_Item__c coLineItemRec : coLineItemList) {
            if(String.isNotBlank(coLineItemRec.Part__c) && String.isBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                partCOLIRecId = coLineItemRec.Id;
            } else if(!coLineItemRec.Is_Linked_Fee__c && String.isNotBlank(coLineItemRec.Fee__c) && String.isBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                feeCOLIRecId = coLineItemRec.Id;
            } else if(String.isNotBlank(coLineItemRec.Part__c) && String.isNotBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartCOLIRecId = coLineItemRec.Id;
            } else if(!coLineItemRec.Is_Linked_Fee__c && String.isNotBlank(coLineItemRec.Fee__c) && String.isNotBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeCOLIRecId = coLineItemRec.Id;
            } else if(coLineItemRec.Is_Linked_Fee__c && String.isNotBlank(coLineItemRec.Fee__c) && String.isBlank(coLineItemRec.Kit_Header_Line_Item__c)) {
                linkedFeeCOLIRecId = coLineItemRec.Id;
            }
        }

        // Delete Part
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.deleteCOLineItem(BPUtility.getEncodedString(partCOLIRecId), BPUtility.getEncodedString(coHeaderList[0].Id));
        
        // Delete Fee
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.deleteCOLineItem(BPUtility.getEncodedString(feeCOLIRecId), BPUtility.getEncodedString(coHeaderList[0].Id));
        
        // Delete Fee
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.deleteCOLineItem(BPUtility.getEncodedString(linkedFeeCOLIRecId), BPUtility.getEncodedString(coHeaderList[0].Id));
        
        // delete Kit
        TestDataFactory_V2.resetAllStaticVariables();
        List<CO_Kit_Header__c> coKitHeaderList = [SELECT Id FROM CO_Kit_Header__c WHERE CO_Header__c = :coHeaderList[0].Id];
        CustomerOrderCtrl_V2.deleteCOLineItem(BPUtility.getEncodedString(coKitHeaderList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id));
        
        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertDeleteMultipleLineItemsToCashSaleMerchandise_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertDeleteMultipleLineItemsToCashSaleMerchandise_Enhanced(coHeaderList); }
        else { assertDeleteMultipleLineItemsToCashSaleMerchandise(coHeaderList); }
    }

    static void assertDeleteMultipleLineItemsToCashSaleMerchandise_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(0, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(582.73, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(0, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(0, coInvoiceItemList.size());
    }

    static void assertDeleteMultipleLineItemsToCashSaleMerchandise_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(0, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(910.23, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(0, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(0, coInvoiceItemList.size());
    }

    static void assertDeleteMultipleLineItemsToCashSaleMerchandise(List<CO_Header__c> coHeaderList) {

        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(1, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(1, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(0, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(0, dealItems.size());

        // 7 Assertion of Service Order Creation 
        System.assertEquals(0, coHeaderList[0].Service_Order_Headers__r.size());

        // 8 Assertion of Internal Comment Creation
        System.assertEquals(0, coHeaderList[0].Internal_Comments__r.size()); 

        // 9 Assertion of Fee Creation 
        System.assertEquals(0, coHeaderList[0].Fees__r.size());

        // 10 Assertion of Tax Exemption Creation 
        System.assertEquals(1, coHeaderList[0].Tax_Exemptions__r.size());

        // 11 Assertion of CO Line Items Creation
        System.assertEquals(0, coHeaderList[0].CO_Line_Items__r.size());

        List<Account> accountList = [SELECT Id, Name, Account_Type__c, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
        
        List<Account_Type__c> accountTypeList;
        List<Price_Level__c> PriceLevelList;
        if(accountList.isEmpty()) {
            accountTypeList = [SELECT Id, Name FROM Account_Type__c WHERE Default__c = true LIMIT 1];
            priceLevelList = [SELECT Id, Discount_Markup__c, Labour_Rate__c, Part_Price_Base__c FROM Price_Level__c WHERE Default__c = true LIMIT 1];
        }

        // 12 Assertion for Account type on CO
        System.assertEquals(accountList.isEmpty() ? accountTypeList[0].Id : accountList[0].Account_Type__c, coHeaderList[0].Account_Type__c);

        // 13 Assertion for CO type on CO
        System.assertEquals('Customer', coHeaderList[0].CO_Type__c);

        // 14 Assertion for Customer on CO
        System.assertEquals(accountList.isEmpty() ? null : accountList[0].Id , coHeaderList[0].Customer__c);

        // 15 Assertion for Discount Markup From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Discount_Markup__c : accountList[0].Price_Level__r.Discount_Markup__c, coHeaderList[0].Discount_Markup_From_Prive_Level__c);

        // 16 Assertion for Labour Rate From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Labour_Rate__c : accountList[0].Price_Level__r.Labour_Rate__c, coHeaderList[0].Labour_Rate_From_Price_Level__c);

        // 17 Assertion for part Price Base From Price Level
        System.assertEquals(accountList.isEmpty() ? priceLevelList[0].Part_Price_Base__c : accountList[0].Price_Level__r.Part_Price_Base__c, coHeaderList[0].Part_Price_Base_From_Price_Level__c);

        // 18 Assertion for Parts And Accessories Total on CO
        System.assertEquals(641.00, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(00, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
        
        List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c =  :coHeaderList[0].CO_Invoice_Headers__r[0].Id];

        // 27 Assertion for Order status
        System.assertEquals(0, coInvoiceItemList.size());
    }

    static void addLineItemOnMerchBeforeCOIdGeneration(String coHeaderId, String jsonString, String feeId) {
        CustomerOrderCtrl_V2.saveCOLineItem(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(jsonString), BPUtility.getEncodedString(feeId));
    }

    public static List<CO_Header__c> getAssertionQueryResult () {
        List<CO_Header__c> coHeaderList = [SELECT Id, Account_Type__c, CO_Type__c, Customer__c, Discount_Markup_From_Prive_Level__c, Labour_Rate_From_Price_Level__c, 
                                            Parts_And_Accessories_Total__c, Selling_Group__c, Total_SO__c, Total_Deposit__c, Total_Deposit_And_Payment__c,
                                            Uninvoiced_Amount__c, Part_Price_Base_From_Price_Level__c, Order_status__c, Merchandise_Transaction_Type__c, Merchandise_Total__c,
                                            Total_Payment__c, Deal_Total__c, Hide_Merchandise_Section__c, 
                                            (SELECT Id FROM CO_Section_Details__r),
                                            (SELECT Id FROM Tax_Exemptions__r),
                                            (SELECT Id, Qty__c, Part__c, Fee__c, Kit_Header_Line_Item__c, Price__c FROM CO_Line_Items__r),
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
@IsTest
private class CO_DealTest {

    @TestSetup
    static void makeData() {
        TestDataFactory.disableFLSChecks();
    }

    static void testData() {
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Category__c> categoryList = TestDataFactory_V2.createTestDataForCategory(true);
        List<Account> customerList = TestDataFactory_V2.createTestDataForCustomer(accountTypeList, priceLevelList, true);
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
        List<Customer_Owned_Unit__c> stockUnitList = TestDataFactory_V2.createTestDataForUnit(customerList, salesTaxList, 'STOCK', 'Available', true);
        List<Customer_Owned_Unit__c> couList = TestDataFactory_V2.createTestDataForUnit(customerList, salesTaxList, 'COU', 'Active', true);
        List<Labour_Code__c> labourList = TestDataFactory_V2.createTestDataForLabour(categoryList, salesTaxList, true);
        List<Product__c> subletList = TestDataFactory_V2.createTestDataForSublet(vendorList, categoryList, salesTaxList, true);
        List<Transaction_Type__c> transactionTypeList = TestDataFactory_V2.createTestDataForTransactionType(categoryList, true);
    }
    
    // ---------------------------- Tax Included Price :ON ---------------------------- 
    @IsTest
    static void addFeeToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addFeeToDeal();
    }


    @IsTest
    static void addPartToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addPartToDeal();
    }

    @IsTest
    static void addKitToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addKitToDeal();
    } 

    @IsTest
    static void addLabourToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addLabourToDeal();
    }

    @IsTest
    static void addSubletToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addSubletToDeal();
    }

    @IsTest
    static void addMultipleLineItemsToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addMultipleLineItemsToDeal();
    }

    @IsTest
    static void updateMultipleLineItemsToDeal_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        updateMultipleLineItemsToDeal();
    }

    // ---------------------------- Tax Included Price :OFF, Enhanced Tax Calculation :ON ---------------------------- 

    @IsTest
    static void addFeeToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addFeeToDeal();
    }

    @IsTest
    static void addPartToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addPartToDeal();
    }

    @IsTest
    static void addKitToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addKitToDeal();
    }

    @IsTest
    static void addLabourToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addLabourToDeal();
    }

    @IsTest
    static void addSubletToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addSubletToDeal();
    }

    @IsTest
    static void addMultipleLineItemsToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addMultipleLineItemsToDeal();
    }

    @IsTest
    static void updateMultipleLineItemsToDeal_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        updateMultipleLineItemsToDeal();
    }

    // ---------------------------- Tax Included Price :OFF ---------------------------- 

    @IsTest
    static void addFeeToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"FeeId":"' + feeList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(90.91, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(90.91, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(153.00, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(153.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(100, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(100.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addPartToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"PartId":"' + partList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertOptionAndFeeLineItems(BPUtility.getEncodedString(partList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString), false, false);

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(100, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(100.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(163.30, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(163.30, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(110, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(110.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addKitToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"KitHeaderId":"' + kitHeaderList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(190.91, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(190.91, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(266.30, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(266.30, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(210.00, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(210.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addLabourToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"LabourId":"' + labourList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(9.09, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(9.09, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(60.30, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(60.30, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(10.00, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(10.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addSubletToDeal() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);

        Test.startTest();
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
        List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
        List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];

        CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

        String jSONString = '{"PartId":null,"FeeId":null,"LabourId":null,"IsInstall":true,"Qty":1,"DealId":"' + dealList[0].Id + '","DealItemId":"' + dealItemList[0].Id + '","ProductId":"' + subletList[0].Id + '","Price":null,"KitHeaderId":null,"UUID":"1691138268092"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(90.91, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(90.91, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(153.00, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(153.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        } else {

            // 1 Assertion of CO Creation
            System.assertEquals(1, coHeaderList.size());

            // 2 Assertion of CO Section Creation
            System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

            // 3 Assertion of CO Invoice Header Creation
            System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

            // 4 Assertion of CO Deposit Creation
            System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

            // 5 Assertion of Deal Creation 
            System.assertEquals(1, coHeaderList[0].Deals__r.size());

            // 6 Assertion of Deal Items Creation
            List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
            System.assertEquals(1, dealItems.size());

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

            List<Account> accountList = [SELECT Id, Name, Account_Type__r.Name, Price_Level__r.Discount_Markup__c, Price_Level__r.Labour_Rate__c, Price_Level__r.Part_Price_Base__c FROM Account WHERE Is_Customer__c = true LIMIT 1];
            
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(0, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(100.00, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(100.00, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);
        }
    }

    @IsTest
    static void addMultipleLineItemsToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];
            List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        Test.stopTest();

        // Fee
        String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"FeeId":"' + feeList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Part
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"PartId":"' + partList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.insertOptionAndFeeLineItems(BPUtility.getEncodedString(partList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString), false, false);

        // Labour
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"LabourId":"' + labourList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Kit
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"KitHeaderId":"' + kitHeaderList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));
        
        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertAddMultipleLineItemsToDeal_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertAddMultipleLineItemsToDeal_Enhanced(coHeaderList); }
        else { assertAddMultipleLineItemsToDeal(coHeaderList); }
    }

    static void assertAddMultipleLineItemsToDeal_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(390.91, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(390.91, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    static void assertAddMultipleLineItemsToDeal_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(492.90, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(492.90, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    static void assertAddMultipleLineItemsToDeal(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(430.00, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(430.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    
    @IsTest
    static void updateMultipleLineItemsToDeal() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);

        Test.startTest();
            addMultipleLineItemsToDeal_Future();
        Test.stopTest();

        updateMultipleLineItemsToDeal_Future();
    }

    @Future
    public static void addMultipleLineItemsToDeal_Future() {
  
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
        List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
        List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
        List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];
        List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
        List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
        List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];

        CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
        
        // Fee
        String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"FeeId":"' + feeList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Part
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"PartId":"' + partList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.insertOptionAndFeeLineItems(BPUtility.getEncodedString(partList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString), false, false);

        // Labour
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"LabourId":"' + labourList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Kit
        jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"KitHeaderId":"' + kitHeaderList[0].Id + '"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));
    
        // Sublet
        jSONString = '{"PartId":null,"FeeId":null,"LabourId":null,"IsInstall":true,"Qty":1,"DealId":"' + dealList[0].Id + '","DealItemId":"' + dealItemList[0].Id + '","ProductId":"' + subletList[0].Id + '","Price":null,"KitHeaderId":null,"UUID":"1691138268092"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));
    }

    @Future
    public static void updateMultipleLineItemsToDeal_Future() {

        List<Account> customerList = [SELECT Id FROM Account WHERE Is_Customer__c = TRUE LIMIT 1];
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        Account vendor = [SELECT Id, Name FROM Account WHERE Is_Vendor__c = TRUE LIMIT 1];
        List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
        List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];
        List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
        List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
        List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];
        List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
        List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
        List<Deal_Kit_Header__c> dealKitHeaderList = [SELECT Id FROM Deal_Kit_Header__c LIMIT 1];
        
        List<Option_Fee__c> optionFeeLineItemList = [SELECT Id, CO_Line_Item__c, Deal_Kit_Header__c, Kit_Header_Line_Item__c, Part__c, Fee__c, Product__c, Labour_Code__c FROM Option_Fee__c WHERE Deal_Item__c = :dealItemList[0].Id];
        String partOFLIRecId;
        String feeOFLIRecId;
        String kitPartOFLIRecId;
        String kitFeeOFLIRecId;
        String subletOFLIRecId;
        String labourOFLIRecId;
        String soKitHeaderId;
        for(Option_Fee__c ofLineItemRec : optionFeeLineItemList) {
            if(String.isNotBlank(ofLineItemRec.Part__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                partOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Fee__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                feeOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Part__c) && String.isNotBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Fee__c) && String.isNotBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Product__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                subletOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Labour_Code__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                labourOFLIRecId = ofLineItemRec.Id;
            }
        }

        // Fee
        String jSONString = '{"UUID":"1691144508920","Total":100,"Status":null,"SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":null,"ProductId":null,"Price":"110.00","PartId":null,"OptionStatus":null,"LabourId":null,"KitHeaderId":null,"ItemDescription":"test0","ItemCode":"feecode","Item":"feecode - test0","IsInstall":false,"IsForeignVendor":null,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + feeOFLIRecId + '","FixedPrice":null,"FeeId":"' + feeList[0].Id + '","DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","isAsyncActionInProgress":true}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Part
        jSONString = '{"UUID":"1691142874153","Total":100,"Status":"In Stock","SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":null,"ProductId":null,"Price":"110.00","PartId":"' + partList[0].Id + '","OptionStatus":"Uncommitted","LabourId":null,"KitHeaderId":null,"ItemDescription":"test0","ItemCode":"test0","Item":"test0 - test0","IsInstall":true,"IsForeignVendor":false,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + partOFLIRecId + '","FixedPrice":null,"FeeId":null,"DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","isAsyncActionInProgress":true}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Labour
        jSONString = '{"UUID":"1691144722639","Total":10,"Status":null,"SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":null,"ProductId":null,"Price":"20.00","PartId":null,"OptionStatus":"Uncommitted","LabourId":"' + labourList[0].Id + '","KitHeaderId":null,"ItemDescription":"Test0 description","ItemCode":"Test0","Item":"Test0 - Test0 description","IsInstall":true,"IsForeignVendor":null,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + labourOFLIRecId + '","FixedPrice":null,"FeeId":null,"DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","isAsyncActionInProgress":true}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Kit
        jSONString = '{"UUID":"1691146507463","TaxAmount":0,"RetailPrice":null,"Price":"220.00","OptionAndFeeList":[{"UUID":null,"Total":114.75,"Status":null,"SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":null,"ProductId":null,"Price":114.75,"PartId":null,"OptionStatus":"Uncommitted","LabourId":null,"KitHeaderId":"' + kitHeaderList[0].Id + '","ItemDescription":"test0","ItemCode":"feecode","Item":"feecode - test0","IsInstall":false,"IsForeignVendor":null,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + kitFeeOFLIRecId + '","FixedPrice":100,"FeeId":"' + feeList[0].Id + '","DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","$$hashKey":"object:1414"},{"UUID":null,"Total":126.25,"Status":"In Stock","SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":null,"ProductId":null,"Price":126.25,"PartId":"' + partList[0].Id + '","OptionStatus":"Uncommitted","LabourId":null,"KitHeaderId":"' + kitHeaderList[0].Id + '","ItemDescription":"test0","ItemCode":"test0","Item":"test0 - test0","IsInstall":false,"IsForeignVendor":false,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + partOFLIRecId + '","FixedPrice":110,"FeeId":null,"DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","$$hashKey":"object:1415"}],"ItemDescription":"test0 - test0","IsServiceKit":false,"IsInstall":false,"IsFixedPriceForCO":true,"IsFixedPrice":false,"Id":"' + dealKitHeaderList[0].Id + '","hasChildren":true,"FixedPrice":null,"DealItemId":"' + dealItemList[0].Id + '","CoHeaderId":"' + coHeaderList[0].Id + '","Code":null,"CanItSplit":true,"ActualKitPrice":210,"isAsyncActionInProgress":true}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.recalculationOfDealKHLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString('null'));

         // Sublet
        jSONString = '{"UUID":"1691475902367","Total":100,"Status":null,"SalesTaxPercentage":0,"SalesTax":0,"Qty":1,"ProductType":"Sublet","ProductId":"' + subletList[0].Id + '","Price":"110.00","PartId":null,"OptionStatus":"Uncommitted","LabourId":null,"KitHeaderId":null,"ItemDescription":"Test0","ItemCode":"Test0","Item":"Test0 - Test0","IsInstall":true,"IsForeignVendor":null,"IsFixedPriceForCO":false,"IsFixedPrice":false,"IsEnvFee":false,"Id":"' + subletOFLIRecId + '","FixedPrice":null,"FeeId":null,"DealItemId":"' + dealItemList[0].Id + '","DealId":"' + dealList[0].Id + '","isAsyncActionInProgress":true}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertUpdateMultipleLineItemsToDeal_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertUpdateMultipleLineItemsToDeal_Enhanced(coHeaderList); }
        else { assertUpdateMultipleLineItemsToDeal(coHeaderList); }
    }

    public static void assertUpdateMultipleLineItemsToDeal_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(560.00, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(560.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    public static void assertUpdateMultipleLineItemsToDeal_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(637.10, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(637.10, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    public static void assertUpdateMultipleLineItemsToDeal(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(570.00, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(570.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);
    }

    @IsTest
    static void deleteMultipleLineItemsToDeal() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);

        Test.startTest();
            addMultipleLineItemsToDeal_Future();
        Test.stopTest();

        deleteMultipleLineItemsToDeal_Future();
    }

    @Future
    public static void deleteMultipleLineItemsToDeal_Future() {

        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
        List<Deal_Kit_Header__c> dealKitHeaderList = [SELECT Id FROM Deal_Kit_Header__c LIMIT 1];
        
        List<Option_Fee__c> optionFeeLineItemList = [SELECT Id, CO_Line_Item__c, Deal_Kit_Header__c, Kit_Header_Line_Item__c, Part__c, Fee__c, Product__c, Labour_Code__c FROM Option_Fee__c WHERE Deal_Item__c = :dealItemList[0].Id];
        String partOFLIRecId;
        String feeOFLIRecId;
        String kitPartOFLIRecId;
        String kitFeeOFLIRecId;
        String subletOFLIRecId;
        String labourOFLIRecId;
        String soKitHeaderId;
        for(Option_Fee__c ofLineItemRec : optionFeeLineItemList) {
            if(String.isNotBlank(ofLineItemRec.Part__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                partOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Fee__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                feeOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Part__c) && String.isNotBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Fee__c) && String.isNotBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Product__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                subletOFLIRecId = ofLineItemRec.Id;
            } else if(String.isNotBlank(ofLineItemRec.Labour_Code__c) && String.isBlank(ofLineItemRec.Kit_Header_Line_Item__c)) {
                labourOFLIRecId = ofLineItemRec.Id;
            }
        }

        // Fee
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeOptionFeesLineItem(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(feeOFLIRecId));

        // Part
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeOptionFeesLineItem(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(partOFLIRecId));

        // Labour
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeOptionFeesLineItem(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(labourOFLIRecId));

        // Kit
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeOptionFeesLineItem(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(dealKitHeaderList[0].Id));

         // Sublet
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeOptionFeesLineItem(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(subletOFLIRecId));

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertDeleteMultipleLineItemsToDeal_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertDeleteMultipleLineItemsToDeal_Enhanced(coHeaderList); }
        else { assertDeleteMultipleLineItemsToDeal(coHeaderList); }
    }

    public static void assertDeleteMultipleLineItemsToDeal_TIP(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

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
        System.assertEquals(1, coHeaderList[0].Service_Order_Headers__r.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

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
    }

    public static void assertDeleteMultipleLineItemsToDeal_Enhanced(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

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
        System.assertEquals(1, coHeaderList[0].Service_Order_Headers__r.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

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
    }

    public static void assertDeleteMultipleLineItemsToDeal(List<CO_Header__c> coHeaderList) {
        // 1 Assertion of CO Creation
        System.assertEquals(1, coHeaderList.size());

        // 2 Assertion of CO Section Creation
        System.assertEquals(0, coHeaderList[0].CO_Section_Details__r.size());

        // 3 Assertion of CO Invoice Header Creation
        System.assertEquals(0, coHeaderList[0].CO_Invoice_Headers__r.size());

        // 4 Assertion of CO Deposit Creation
        System.assertEquals(0, coHeaderList[0].CO_Deposits__r.size());

        // 5 Assertion of Deal Creation 
        System.assertEquals(1, coHeaderList[0].Deals__r.size());

        // 6 Assertion of Deal Items Creation
        List<Deal_Item__c> dealItems = [SELECT Id FROM Deal_Item__c WHERE Deal__c IN :coHeaderList[0].Deals__r];
        System.assertEquals(1, dealItems.size());

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
        System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

        // 19 Assertion for Service Job Total on CO
        System.assertEquals(0, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(0.00, coHeaderList[0].Deal_Total__c);

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
    }

    @IsTest
    static void recalculatePriceOnDealLineItems() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);

        Test.startTest();
            addMultipleLineItemsToDeal_Future();
            updateMultipleLineItemsToDeal_Future();
        Test.stopTest();
        
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        String jsonStr = '{"COHeaderId":"' + coHeaderList[0].Id + '","CustomerId":null,"SOHeaderId":null,"IsRecalculateTaxes":false,"IsResetPricing":true}';
        CustomerOrderCtrl_V2.refreshCOPricingAndTax(BPUtility.getEncodedString(jsonStr), null);
        
        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        // if(isTaxIncludedPricing) { assertAddMultipleLineItemsToDeal_TIP(coHeaderList); }
        // else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertAddMultipleLineItemsToDeal_Enhanced(coHeaderList); }
        // else { assertAddMultipleLineItemsToDeal(coHeaderList); }
    }

    @IsTest
    static void addTradInToDeal() {
        Test.startTest();
            testData();
            
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'COU' LIMIT 1];
            List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];

            String jSONString = '{"Type":"Trade In"}';

            CustomerOrderCtrl_V2.updateTradeIn(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(jSONString));
            COLineItemTriggerHelper.isTotalCalculated = false;
        Test.stopTest();

            List<Deal_Item__c> dealItemList = [SELECT Id FROM Deal_Item__c LIMIT 1];
            jSONString = '{"Type":"Trade In","UnitId":"'+ couList[0].Id +'","Id":"' + dealItemList[0].Id +'"}';
            CustomerOrderCtrl_V2.updateTradeIn(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(jSONString));

        // Assertion
        dealItemList = [SELECT Id, Customer_Owned_Unit__c, Type__c FROM Deal_Item__c LIMIT 1];
        
        System.assertEquals(couList[0].Id, dealItemList[0].Customer_Owned_Unit__c);
        System.assertEquals('Trade In', dealItemList[0].Type__c);
    }

    @IsTest
    static void addDealMerchandiseInToDeal() {
        testData();
                
        CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
        List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
        List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];

        Test.startTest();
            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));
            
            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + false + ',"PartId":"' + partList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertOptionAndFeeLineItems(BPUtility.getEncodedString(partList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString), false, false);
        Test.stopTest();

            CustomerOrderCtrl_V2.updateDealStatus(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString('In Progress'));
            String jSONStr = '["' + dealItemList[0].Id + '"]';
            CustomerOrderCtrl_V2.createDealMerchSection(BPUtility.getEncodedString(jSONStr), BPUtility.getEncodedString(coHeaderList[0].Id));
            CustomerOrderCtrl_V2.createDealServiceSection(BPUtility.getEncodedString(jSONStr), BPUtility.getEncodedString(coHeaderList[0].Id));

            List<CO_Section_Detail__c> dealMerchandiseList = [Select id from co_section_detail__c where co_header__c = :coHeaderList[0].Id];
            system.assertEquals(1, dealMerchandiseList.size());
            // Assertion
    }


    @IsTest
    static void addDealServiceInToDeal() {
        testData();
        Test.startTest();                
            CO_CreateCOTest.createCO(CO_CreateCOTest.unitDealSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Deal__c> dealList = [SELECT Id FROM Deal__c LIMIT 1];
            List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Id FROM Deal_Item__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' LIMIT 1];
            List<Part__c> partList = [SELECT Id FROM Part__c LIMIT 1];

            CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(couList[0].Id), BPUtility.getEncodedString(dealList[0].Id));

            String jSONString = '{"DealItemId":"' + dealItemList[0].Id + '","Qty":"' + 1 + '","IsInstall":' + true + ',"PartId":"' + partList[0].Id + '"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertOptionAndFeeLineItems(BPUtility.getEncodedString(partList[0].Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(dealItemList[0].Id), BPUtility.getEncodedString(jSONString), false, false);
        Test.stopTest();

            CustomerOrderCtrl_V2.updateDealStatus(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString('In Progress'));
            String jSONStr = '["' + dealItemList[0].Id + '"]';
            CustomerOrderCtrl_V2.createDealMerchSection(BPUtility.getEncodedString(jSONStr), BPUtility.getEncodedString(coHeaderList[0].Id));
            CustomerOrderCtrl_V2.createDealServiceSection(BPUtility.getEncodedString(jSONStr), BPUtility.getEncodedString(coHeaderList[0].Id));

            List<Service_Order_Header__c> dealServiceList = [Select id from Service_Order_Header__c where co_header__c = :coHeaderList[0].Id];
            system.assertEquals(1, dealServiceList.size());
            // Assertion
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
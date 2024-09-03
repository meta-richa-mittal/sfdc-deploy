@IsTest
private class CO_ServiceJobTest {

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
        List<Sales_Tax_Item__c> salesTaxItemList = TestDataFactory_V2.createTestDataForSalesTaxItem('Sell', categoryList, true);
        List<Sales_Tax__c> salesTaxList = TestDataFactory_V2.createTestDataForSalesTax(true);
        List<Tax_Exemption__c> taxExemptionList = TestDataFactory_V2.createTestDataForTaxExemption(accountTypeList, salesTaxItemList, true);
        List<Applicable_Taxes__c> applicableTaxList = TestDataFactory_V2.createTestDataForApplicableTax(salesTaxList, salesTaxItemList, true);
        List<Fee__c> feeList = TestDataFactory_V2.createTestDataForFee(salesTaxList, categoryList, true);
        List<Part__c> partList = TestDataFactory_V2.createTestDataForPart(categoryList, vendorList, salesTaxList, true);
        List<Linked_Fee__c> linkedFeeList = TestDataFactory_V2.createTestDataForLinkedFee(feeList, true);
        List<Kit_Header__c> kitHeaderList = TestDataFactory_V2.createTestDataForKit(true);
        List<Kit_Header_Line_Item__c> kitHeaderLineItemList = TestDataFactory_V2.createTestDataForKitLineItem(partList, feeList, kitHeaderList, true);
        List<Customer_Owned_Unit__c> unitList = TestDataFactory_V2.createTestDataForUnit(customerList, salesTaxList, 'COU', 'Active', true);
        List<Labour_Code__c> labourList = TestDataFactory_V2.createTestDataForLabour(categoryList, salesTaxList, true);
        List<Product__c> subletList = TestDataFactory_V2.createTestDataForSublet(vendorList, categoryList, salesTaxList, true);
        List<Transaction_Type__c> transactionTypeList = TestDataFactory_V2.createTestDataForTransactionType(categoryList, true);
        List<SO_Status__c> jobStatusList = TestDataFactory_V2.createTestDataForServiceJobStatus();

    }
    
    // ---------------------------- Tax Included Price :ON ---------------------------- 
    @IsTest
    static void addFeeToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addFeeToServiceJob();
    }


    @IsTest
    static void addPartToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addPartToServiceJob();
    }

    @IsTest
    static void addKitToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addKitToServiceJob();
    }
    
    @IsTest
    static void addLabourToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addLabourToServiceJob();
    }

    @IsTest
    static void addSubletToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addSubletToServiceJob();
    }

    @IsTest
    static void addMultipleLineItemsToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        addMultipleLineItemsToServiceJob();
    }

    @IsTest
    static void updateMultipleLineItemsToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        updateMultipleLineItemsToServiceJob();
    } 

    @IsTest
    static void deleteMultipleLineItemsToServiceJob_TIP() {
        TestUtil.createtaxsettingInGeneralConfig();
        deleteMultipleLineItemsToServiceJob();
    }

    // ---------------------------- Tax Included Price :OFF, Enhanced Tax Calculation :ON ---------------------------- 

    @IsTest
    static void addFeeToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addFeeToServiceJob();
    }

    @IsTest
    static void addPartToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addPartToServiceJob();
    }

    @IsTest
    static void addKitToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addKitToServiceJob();
    }

    @IsTest
    static void addLabourToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addLabourToServiceJob();
    }

    @IsTest
    static void addSubletToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addSubletToServiceJob();
    }

    @IsTest
    static void addMultipleLineItemsToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        addMultipleLineItemsToServiceJob();
    }

    @IsTest
    static void updateMultipleLineItemsToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        updateMultipleLineItemsToServiceJob();
    }

    @IsTest
    static void deleteMultipleLineItemsToServiceJob_Enhanced() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        deleteMultipleLineItemsToServiceJob();
    }

    // ---------------------------- Tax Included Price :OFF ---------------------------- 

    @IsTest
    static void addFeeToServiceJob() {
        Test.startTest();
            testData();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
            String jSONString = '{"EntityId" : "' + feeList[0].Id +'", "UUID" : "12356789"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
        Test.stopTest();

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(90.91, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
    
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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(100, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else {
    
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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(100, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(100, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        }
    }

    @IsTest
    static void addPartToServiceJob() {
        Test.startTest();
            testData();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);

            List<Account> customerList = [SELECT Id FROM Account WHERE Is_Customer__c = TRUE LIMIT 1];
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account WHERE Is_Vendor__c = TRUE LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            Part__c part = [SELECT Id FROM Part__c LIMIT 1];
            String jSONString = '{"EntityId" : "' + part.Id +'", "UUID" : "12356789"}';
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;

            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderList[0].Id), BPUtility.getEncodedString(customerList[0].Id));
        Test.stopTest();

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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(100, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(100, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(110.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else {
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
            System.assertEquals(1, coHeaderList[0].CO_Line_Items__r.size());

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
            System.assertEquals(110.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        }
    }

    @IsTest
    static void addKitToServiceJob() {
        Test.startTest();
            testData();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
            String jSONString = '{"EntityId" : "' + kitHeaderList[0].Id +'", "UUID" : "12356789"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
        Test.stopTest();

        
        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(190.91, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(2, soLineItemList.size());
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(210, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

            // 21 Assertion for Deposit Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

            // 22 Assertion for Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Payment__c);

            // 23 Assertion for Deposit and Payment Total on CO
            System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

            // 24 Assertion for Uninvoiced Amount Total on CO
            System.assertEquals(316.30, coHeaderList[0].Uninvoiced_Amount__c);

            // 25 Assertion for Merchandise Total on CO
            System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

            // 26 Assertion for Order status
            System.assertEquals('Open', coHeaderList[0].Order_status__c);

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(2, soLineItemList.size());
        } else {
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
            System.assertEquals(0, coHeaderList[0].Parts_And_Accessories_Total__c);

            // 19 Assertion for Service Job Total on CO
            System.assertEquals(210.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);
        
            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(2, soLineItemList.size());
        }
    }

    @IsTest
    static void addLabourToServiceJob() {
        Test.startTest();
            testData();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
            String jSONString = '{"EntityId" : "' + labourList[0].Id +'", "UUID" : "12356789"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
        Test.stopTest();

        
        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
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
            System.assertEquals(9.09, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
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
            System.assertEquals(10.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else {
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
            System.assertEquals(10.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        }
    }

    @IsTest
    static void addSubletToServiceJob() {
        Test.startTest();
            testData();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];
            String jSONString = '{"EntityId" : "' + subletList[0].Id +'", "UUID" : "12356789"}';
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
        Test.stopTest();

        
        // Assertion 
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) {
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
            System.assertEquals(90.91, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) {
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
            System.assertEquals(100.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        } else {
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
            System.assertEquals(100.00, coHeaderList[0].Total_SO__c);

            // 20 Assertion for Deal Total on CO
            System.assertEquals(null, coHeaderList[0].Deal_Total__c);

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

            // 27 Assertion of Service Order Creation 
            System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

            List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
            
            // 30 Assertion of Service Order Creation 
            System.assertEquals(1, soLineItemList.size());
        }
    }

    @IsTest
    static void addMultipleLineItemsToServiceJob() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
        
        Test.startTest();
            addMultipleLineItemsToServiceJob_Future1();
            addMultipleLineItemsToServiceJob_Future2();
        Test.stopTest();

        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertaddMultipleLineItemsToServiceJob_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertaddMultipleLineItemsToServiceJob_Enhanced(coHeaderList); }
        else { assertaddMultipleLineItemsToServiceJob(coHeaderList); }
    }

    @Future 
    static void addMultipleLineItemsToServiceJob_Future1() {
        List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        List<Account> customerList = [SELECT Id FROM Account WHERE Is_Customer__c = TRUE LIMIT 1];
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
        Account vendor = [SELECT Id, Name FROM Account WHERE Is_Vendor__c = TRUE LIMIT 1];
        Part__c part = [SELECT Id FROM Part__c LIMIT 1];

        // Add Fee
        String jSONString = '{"EntityId" : "' + feeList[0].Id +'", "UUID" : "12356789"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
    
        // Add Part
        jSONString = '{"EntityId" : "' + part.Id +'", "UUID" : "12356789"}';
        Boolean isSuppress = false;
        Boolean isDuplicateCheck = false;
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderList[0].Id), BPUtility.getEncodedString(customerList[0].Id));
    }

    @Future 
    static void addMultipleLineItemsToServiceJob_Future2() {
        List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
        List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
        List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];

        // Add Kit
        String jSONString = '{"EntityId" : "' + kitHeaderList[0].Id +'", "UUID" : "12356789"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
    
        // Add Labour
        jSONString = '{"EntityId" : "' + labourList[0].Id +'", "UUID" : "12356789"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
    
        // Add Sublet
        jSONString = '{"EntityId" : "' + subletList[0].Id +'", "UUID" : "12356789"}';
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList.isEmpty() ? null : soHeaderList[0].Id));
    }
    
    static void assertaddMultipleLineItemsToServiceJob_TIP(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(481.82, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(481.82, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    } 
    
    static void assertaddMultipleLineItemsToServiceJob_Enhanced(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(530.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(845.90, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    } 

    static void assertaddMultipleLineItemsToServiceJob(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(530, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(530.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    }

    @IsTest
    static void updateMultipleLineItemsToServiceJob() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
        
        Test.startTest();
            addMultipleLineItemsToServiceJob_Future1();
            addMultipleLineItemsToServiceJob_Future2();
        Test.stopTest();

        updateMultipleLineItemsToServiceJob_Future();
    }

    @Future
    static void updateMultipleLineItemsToServiceJob_Future() {
        List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        List<Account> customerList = [SELECT Id FROM Account WHERE Is_Customer__c = TRUE LIMIT 1];
        List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
        List<Fee__c> feeList = [SELECT Id FROM Fee__c LIMIT 1];
        Account vendor = [SELECT Id, Name FROM Account WHERE Is_Vendor__c = TRUE LIMIT 1];
        Part__c part = [SELECT Id FROM Part__c LIMIT 1];
        List<Kit_Header__c> kitHeaderList = [SELECT Id FROM Kit_Header__c LIMIT 1];
        List<Labour_Code__c> labourList = [SELECT Id FROM Labour_Code__c LIMIT 1];
        List<Product__c> subletList = [SELECT Id FROM Product__c LIMIT 1];

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id, CO_Line_Item__c, Service_Order_Kit_Header__c, Kit_Header_Line_Item__c, Part__c, Fee__c, Sublet__c, Labour_Code__c FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :soHeaderList[0].Id];
        String partCOLIRecId;
        String feeCOLIRecId;
        String kitPartCOLIRecId;
        String kitFeeCOLIRecId;
        String partSOLIRecId;
        String feeSOLIRecId;
        String kitPartSOLIRecId;
        String kitFeeSOLIRecId;
        String subletSOLIRecId;
        String labourSOLIRecId;
        String soKitHeaderId;
        for(Service_Order_Line_Item__c soLineItemRec : soLineItemList) {
            if(String.isNotBlank(soLineItemRec.Part__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                partCOLIRecId = soLineItemRec.CO_Line_Item__c;
                partSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Fee__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                feeCOLIRecId = soLineItemRec.CO_Line_Item__c;
                feeSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Part__c) && String.isNotBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartCOLIRecId = soLineItemRec.CO_Line_Item__c;
                kitPartSOLIRecId = soLineItemRec.Id;
                soKitHeaderId = soLineItemRec.Service_Order_Kit_Header__c;
            } else if(String.isNotBlank(soLineItemRec.Fee__c) && String.isNotBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeCOLIRecId = soLineItemRec.CO_Line_Item__c;
                kitFeeSOLIRecId = soLineItemRec.Id;
                soKitHeaderId = soLineItemRec.Service_Order_Kit_Header__c;
            } else if(String.isNotBlank(soLineItemRec.Sublet__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                subletSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Labour_Code__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                labourSOLIRecId = soLineItemRec.Id;
            }
        }

        TestDataFactory_V2.resetAllStaticVariables();
        String jSONString = '{"VendorId": "'+vendor.Id+'", "UUID": "1690344835134", "ToPull": "1.00", "Tax": 0, "StockCommitedCpy": 1, "StockCommited": 1, "Status": "In Stock", "SoHeaderStatus": "New job", "ReatilPrice": 100, "QtyOrder": 0, "QtyNeeded": 1, "Pulled": "", "PartId": "'+part.Id+'", "OversoldQty": 0, "OnOrderPartQty": 0, "KitPrice": "100.00", "ItemDescription": "test0", "ItemDesc": "test0 - test0", "ItemCode": "test0", "IsSupersededPart": false, "IsSublet": false, "IsPart": true, "IsNonInventoryPart": false, "IsLabour": false, "IsHidden": false, "IsForeignVendor": false, "IsFixedPrice": false, "isFixedKitHeaderLineItemSO": false, "IsFee": false, "IsEnvFee": false, "IsBRPPart": false, "Id": "'+partSOLIRecId+'", "DiscountAmount": -50, "CoLineItem": "'+partCOLIRecId+'", "CassonsSOH": 0, "AvailablePart": 3, "AssignedLocations": [], "ActualRetailPrice": 100, "ActualAvailableParts": 4, "isAsyncActionInProgress": true}';
        CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList[0].id));
        
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '{"VONumber":"","UUID":"1690344846738","ToPull":"1.00","Tax":0,"StockCommitedCpy":1,"StockCommited":1,"Status":"In Stock","SoHeaderStatus":"New job","ReatilPrice":100,"QtyOrder":0,"QtyNeeded":1,"Pulled":"","POStatus":"","OversoldQty":0,"KitPrice":"1.00","ItemDescription":"test0","ItemDesc":"feecode - test0","ItemCode":"feecode","IsSupersededPart":false,"IsSublet":false,"IsPart":false,"IsLabour":false,"IsHidden":false,"IsFixedPrice":false,"isFixedKitHeaderLineItemSO":false,"IsFee":true,"IsEnvFee":false,"IsBRPPart":false,"Id":"'+feeSOLIRecId+'","CoLineItem":"'+feeCOLIRecId+'","CassonsSOH":0,"AssignedLocations":[],"ActualRetailPrice":0,"$$hashKey":"object:1506","isAsyncActionInProgress":true}';
        CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList[0].id));
        
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '{"VONumber":"","UUID":"1690344865961","ToPull":"","Tax":0,"StockCommitedCpy":1,"StockCommited":1,"Status":"In Stock","SoHeaderStatus":"New job","ReatilPrice":100,"QtyOrder":0,"QtyNeeded":1,"Pulled":"","POStatus":"","KitPrice":"10.00","ItemDescription":"Test0 description","ItemDesc":"Test0 - Test0 description","ItemCode":"Test0","IsSupersededPart":false,"IsSublet":false,"IsPart":false,"IsLabour":true,"IsHidden":false,"IsFixedPrice":false,"isFixedKitHeaderLineItemSO":false,"IsFee":false,"IsEnvFee":false,"IsBRPPart":false,"Id":"'+labourSOLIRecId+'","CassonsSOH":0,"AssignedLocations":[],"ActualRetailPrice":10,"isAsyncActionInProgress":true}';
        CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList[0].id));
        
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '{"UUID":"1690344873508","ToPull":"1.00","Tax":0,"StockCommitedCpy":0,"StockCommited":0,"Status":"Required","SoHeaderStatus":"New job","ReatilPrice":100,"QtyOrder":1,"QtyNeeded":1,"Pulled":"","KitPrice":"100.00","ItemDescription":"Test0","ItemDesc":"Test0 - Test0","ItemCode":"Test0","IsSupersededPart":false,"IsSublet":true,"IsPart":false,"IsLabour":false,"IsHidden":false,"IsFixedPrice":false,"isFixedKitHeaderLineItemSO":false,"IsFee":false,"IsEnvFee":false,"IsBRPPart":false,"Id":"'+subletSOLIRecId+'","Cost":100,"CassonsSOH":0,"AssignedLocations":[],"ActualRetailPrice":0,"$$hashKey":"object:1679","isAsyncActionInProgress":true}';
        CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList[0].id));
    
        TestDataFactory_V2.resetAllStaticVariables();
        jSONString = '{"UUID":"1690344854172","taxAmount":0,"SOLIList":[{"VONumber":"","ToPull":"1.00","Tax":0,"StockCommitedCpy":1,"StockCommited":1,"Status":"In Stock","SOKitHeaderId":"'+soKitHeaderId+'","SoHeaderStatus":"New job","ReatilPrice":100,"QtyOrder":0,"QtyNeeded":1,"Pulled":"","POStatus":"","OversoldQty":0,"KitPrice":0,"ItemDescription":"test0","ItemDesc":"feecode - test0","ItemCode":"feecode","IsSupersededPart":false,"IsSublet":false,"IsPart":false,"IsLabour":false,"IsHidden":false,"IsFixedPrice":false,"isFixedKitHeaderLineItemSO":false,"IsFee":true,"IsEnvFee":false,"IsBRPPart":false,"Id":"'+kitFeeSOLIRecId+'","CoLineItem":"'+kitFeeCOLIRecId+'","CassonsSOH":0,"AssignedLocations":[],"ActualRetailPrice":0,"$$hashKey":"object:570"},{"VendorId":"'+vendor.Id+'","ToPull":"1.00","Tax":0,"StockCommitedCpy":1,"StockCommited":1,"Status":"In Stock","SOKitHeaderId":"'+soKitHeaderId+'","SoHeaderStatus":"New job","ReatilPrice":100,"QtyOrder":0,"QtyNeeded":1,"Pulled":"","PartId":"'+part.Id+'","OversoldQty":0,"OnOrderPartQty":0,"KitPrice":110,"ItemDescription":"test0","ItemDesc":"test0 - test0","ItemCode":"test0","IsSupersededPart":false,"IsSublet":false,"IsPart":true,"IsNonInventoryPart":false,"IsLabour":false,"IsHidden":false,"IsForeignVendor":false,"IsFixedPrice":false,"isFixedKitHeaderLineItemSO":false,"IsFee":false,"IsEnvFee":false,"IsBRPPart":false,"Id":"'+kitPartSOLIRecId+'","DiscountAmount":-10,"CoLineItem":"'+kitPartCOLIRecId+'","CassonsSOH":0,"AvailablePart":4,"AssignedLocations":[],"ActualRetailPrice":100,"ActualAvailableParts":5,"$$hashKey":"object:571"}],"Price":110,"ItemDescription":"test0 - test0","IsServiceKit":false,"IsFixedPrice":false,"isFixedKitHeaderSO":true,"Id":"'+soKitHeaderId+'","hasChildren":true,"FixedPrice":"220.00","Code":"test0","CanItSplit":true,"isAsyncActionInProgress":true}';
        CustomerOrderCtrl_V2.updateSOKHLineItems(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(soHeaderList[0].id));
    
        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertUpdateMultipleLineItemsToServiceJob_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertUpdateMultipleLineItemsToServiceJob_Enhanced(coHeaderList); }
        else { assertUpdateMultipleLineItemsToServiceJob(coHeaderList); }
    }

    static void assertUpdateMultipleLineItemsToServiceJob_TIP(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(431.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(431.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    } 
    
    static void assertUpdateMultipleLineItemsToServiceJob_Enhanced(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(431.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(743.93, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    } 

    static void assertUpdateMultipleLineItemsToServiceJob(List<CO_Header__c> coHeaderList) {
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
        System.assertEquals(4, coHeaderList[0].CO_Line_Items__r.size());

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
        System.assertEquals(431.00, coHeaderList[0].Total_SO__c);

        // 20 Assertion for Deal Total on CO
        System.assertEquals(null, coHeaderList[0].Deal_Total__c);

        // 21 Assertion for Deposit Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit__c);

        // 22 Assertion for Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Payment__c);

        // 23 Assertion for Deposit and Payment Total on CO
        System.assertEquals(0, coHeaderList[0].Total_Deposit_And_Payment__c);

        // 24 Assertion for Uninvoiced Amount Total on CO
        System.assertEquals(431.00, coHeaderList[0].Uninvoiced_Amount__c);

        // 25 Assertion for Merchandise Total on CO
        System.assertEquals(0, coHeaderList[0].Merchandise_Total__c);

        // 26 Assertion for Order status
        System.assertEquals('Open', coHeaderList[0].Order_status__c);

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(6, soLineItemList.size());
    }

    @IsTest
    static void deleteMultipleLineItemsToServiceJob() {
        testData();
        CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
        
        Test.startTest();
            addMultipleLineItemsToServiceJob_Future1();
            addMultipleLineItemsToServiceJob_Future2();
        Test.stopTest();

        deleteMultipleLineItemsToServiceJob_Future();
    }

    @Future
    static void deleteMultipleLineItemsToServiceJob_Future() {
        List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id, CO_Line_Item__c, Service_Order_Kit_Header__c, Kit_Header_Line_Item__c, Part__c, Fee__c, Sublet__c, Labour_Code__c FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :soHeaderList[0].Id];

        String partCOLIRecId;
        String feeCOLIRecId;
        String kitPartCOLIRecId;
        String kitFeeCOLIRecId;
        String partSOLIRecId;
        String feeSOLIRecId;
        String kitPartSOLIRecId;
        String kitFeeSOLIRecId;
        String subletSOLIRecId;
        String labourSOLIRecId;
        String soKitHeaderId;

        for(Service_Order_Line_Item__c soLineItemRec : soLineItemList) {
            if(String.isNotBlank(soLineItemRec.Part__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                partCOLIRecId = soLineItemRec.CO_Line_Item__c;
                partSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Fee__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                feeCOLIRecId = soLineItemRec.CO_Line_Item__c;
                feeSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Part__c) && String.isNotBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                kitPartCOLIRecId = soLineItemRec.CO_Line_Item__c;
                kitPartSOLIRecId = soLineItemRec.Id;
                soKitHeaderId = soLineItemRec.Service_Order_Kit_Header__c;
            } else if(String.isNotBlank(soLineItemRec.Fee__c) && String.isNotBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                kitFeeCOLIRecId = soLineItemRec.CO_Line_Item__c;
                kitFeeSOLIRecId = soLineItemRec.Id;
                soKitHeaderId = soLineItemRec.Service_Order_Kit_Header__c;
            } else if(String.isNotBlank(soLineItemRec.Sublet__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                subletSOLIRecId = soLineItemRec.Id;
            } else if(String.isNotBlank(soLineItemRec.Labour_Code__c) && String.isBlank(soLineItemRec.Kit_Header_Line_Item__c)) {
                labourSOLIRecId = soLineItemRec.Id;
            }
        }

        // Delete Part
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeLineItems(BPUtility.getEncodedString(partSOLIRecId), BPUtility.getEncodedString(soHeaderList[0].Id));
        
        // Delete Fee
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeLineItems(BPUtility.getEncodedString(feeSOLIRecId), BPUtility.getEncodedString(soHeaderList[0].Id));
        
        // delete Kit
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeLineItems(BPUtility.getEncodedString(soKitHeaderId), BPUtility.getEncodedString(soHeaderList[0].Id));
        
        // delete Sublet
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeLineItems(BPUtility.getEncodedString(subletSOLIRecId), BPUtility.getEncodedString(soHeaderList[0].Id));
        
        // delete Labour
        TestDataFactory_V2.resetAllStaticVariables();
        CustomerOrderCtrl_V2.removeLineItems(BPUtility.getEncodedString(labourSOLIRecId), BPUtility.getEncodedString(soHeaderList[0].Id));
        
        // Assertion
        Boolean isTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        Boolean isEnhancedTaxCalculation = GeneralConfiguration.IsEnhancedTaxCalculation();
        List<CO_Header__c> coHeaderList = getAssertionQueryResult();

        if(isTaxIncludedPricing) { assertdeleteMultipleLineItemsToServiceJob_TIP(coHeaderList); }
        else if(!isTaxIncludedPricing && isEnhancedTaxCalculation) { assertdeleteMultipleLineItemsToServiceJob_Enhanced(coHeaderList); }
        else { assertdeleteMultipleLineItemsToServiceJob(coHeaderList); }
    }

    static void assertDeleteMultipleLineItemsToServiceJob_TIP(List<CO_Header__c> coHeaderList) {
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

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(0, soLineItemList.size());
    } 
    
    static void assertDeleteMultipleLineItemsToServiceJob_Enhanced(List<CO_Header__c> coHeaderList) {
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

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(0, soLineItemList.size());
    } 

    static void assertDeleteMultipleLineItemsToServiceJob(List<CO_Header__c> coHeaderList) {
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

        // 27 Assertion of Service Order Creation 
        System.assertEquals('Customer', coHeaderList[0].Service_Order_Headers__r[0].Transaction_Type__r.Type__c);

        List<Service_Order_Line_Item__c> soLineItemList = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :coHeaderList[0].Service_Order_Headers__r[0].Id];
        
        // 30 Assertion of Service Order Creation 
        System.assertEquals(0, soLineItemList.size());
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
                                            (SELECT Id, Transaction_Type__r.Type__c, Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Vin_Number__c FROM Service_Order_Headers__r),
                                            (SELECT Id FROM Internal_Comments__r),
                                            (SELECT Id FROM Fees__r),
                                            (SELECT Id FROM CO_Kit_Headers__r)
                                            FROM CO_Header__c LIMIT 1];

        return coHeaderList;
    }

}
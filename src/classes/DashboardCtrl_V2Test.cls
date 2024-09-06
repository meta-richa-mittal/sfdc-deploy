@isTest
public with sharing class DashboardCtrl_V2Test {
    
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
        List<Customer_Owned_Unit__c> unitList = TestDataFactory_V2.createTestDataForUnit(customerList, salesTaxList, 'COU', 'Active', true);
        List<Labour_Code__c> labourList = TestDataFactory_V2.createTestDataForLabour(categoryList, salesTaxList, true);
        List<Product__c> subletList = TestDataFactory_V2.createTestDataForSublet(vendorList, categoryList, salesTaxList, true);
        List<Transaction_Type__c> transactionTypeList = TestDataFactory_V2.createTestDataForTransactionType(categoryList, true);
        List<Shop_Settings__c> shopSettingList = new List<Shop_Settings__c>();
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '1', 'Monday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '2', 'Tuesday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '3', 'Wednesday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '4', 'Thursday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '5', 'Friday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '6', 'Saturday', true));
        shopSettingList.addAll(TestDataFactory_V2.createTestDataForShopSetting(false, '7', 'Sunday', true));
        insert shopSettingList;
        List<Technician__c> technicianList = TestDataFactory_V2.createTestDataForTechnician(true, 'Test Name');
        List<SO_Status__c> jobStatusList = TestDataFactory_V2.createTestDataForServiceJobStatus();

        User_Group__c usergrp = new User_Group__c(); 
        usergrp.Service_job__c = 'Primary'; 
        insert usergrp;
        User_To_Group__c UserAssign = new User_To_Group__c(); 
        UserAssign.User__c = userinfo.getUserId();
        UserAssign.User_Group__c = usergrp.Id;
        Insert UserAssign;
    }
    
    @isTest
    static void getServiceJobsTest() {
        testData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);

            List<Account> customerList = [SELECT Id FROM Account WHERE Is_Customer__c = TRUE LIMIT 1];
            List<CO_Header__c> coHeaderList = [SELECT Id, Name FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account WHERE Is_Vendor__c = TRUE LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];
            Part__c part = [SELECT Id FROM Part__c LIMIT 1];

            String jSONString = '{"EntityId" : "' + part.Id +'", "UUID" : "12356789"}';
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;

            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderList[0].Id), BPUtility.getEncodedString(customerList[0].Id));
            jsonString = '{"CustomerId":"'+ customerList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));

            String filterJson = BPUtility.getEncodedString('{"StatusFilter":"All open jobs","JobTypeFilterList":["All job types"]}');
            String result = DashboardCtrl.getServiceJobs(filterJson);
            List<DashboardServiceJobWrapper> record = (List<DashboardServiceJobWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<DashboardServiceJobWrapper>.class);
            
            System.assertEquals(1, record.size());
            System.assertEquals(coHeaderList[0].id, record[0].COHeaderId);
            System.assertEquals(coHeaderList[0].Name + ' Service Job 1', record[0].CONumberSOName);
            System.assertEquals(0, record[0].ClockedHours);
            System.assertEquals('test0', record[0].CustomerName);
            System.assertEquals(1, record[0].EstimateHours);
            System.assertEquals(false, record[0].IsTechnicianClocked);
            System.assertEquals(0, record[0].ProgressPercent);
            System.assertEquals('not started', record[0].RemainingTime);
            System.assertEquals(0, record[0].TodayHours);
            System.assertEquals('test0', record[0].JobType);
        Test.stopTest();
    }
    
    @isTest
    static void getRefreshMinutesTest() {
        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        genConfig.Dashboard_Refresh_Minutes__c = 15;
        upsert genConfig;
        String result = DashboardCtrl.getRefreshMinutes();
        System.assertEquals('15', BPUtility.getDecodedString(result));
    }

    @isTest
    static void getFormattedTodaysDateTest() {
        String result = DashboardCtrl.getFormattedTodaysDate();
        System.assertEquals(System.now().format('EEEE') + ', ' + System.now().format(Constants.localeToDateMonthFmt.get('en_AU')), BPUtility.getDecodedString(result));
    }

    @isTest
    static void getJobTypeListTest() {
        testData();
        String result = DashboardCtrl.getJobTypeList();
        List<DashboardServiceJobWrapper.JobTypeWrapper> record = (List<DashboardServiceJobWrapper.JobTypeWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<DashboardServiceJobWrapper.JobTypeWrapper>.class);
        System.assertEquals('test0', record[0].Name);
    }
}
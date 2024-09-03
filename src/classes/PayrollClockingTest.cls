@isTest
public without sharing class PayrollClockingTest {
    @TestSetup
    static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    }

    static void makeTestData() {
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
        List<Payroll_Time__c> payrollClockingTimeList = TestDataFactory_V2.createTestDataForPayrollClockingTime(true, technicianList[0].Id, System.today(), System.today().addDays(1));
        List<Hours_Logged__c> hoursLoggedList = TestDataFactory_V2.createTestDataForHoursLogged(true, technicianList[0].Id);
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
    private static void testGetTechnicianList() {
        makeTestData();
        Test.startTest();
            String result = BPUtility.getDecodedString(PayrollCtrl.getTechnicianList());
            List<PayrollWrapper> payrollWrapperList = (List<PayrollWrapper>)JSON.deserialize(result, List<PayrollWrapper>.class);
            assertGetTechnicianList(payrollWrapperList);  
        Test.stopTest();
    }

    private static void assertGetTechnicianList(List<PayrollWrapper> payrollWrapperList) {
    
    }

    @isTest
    private static void testSaveClockStatus() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id, Technician_Name__c, First_Name__c, Last_Name__c FROM Technician__c LIMIT 1];
            Payroll_Time__c payrollTime = [SELECT Id, Technician__c, Start_Date__c, End_Date__c FROM Payroll_Time__c WHERE Technician__c = :technician.Id LIMIT 1];
            String jsonString = '{"Id":"'+payrollTime.Id+'","TechnicianId":"'+technician.Id+'","TechnicianName":"'+technician.Technician_Name__c+'","TechnicianFirstName":"'+technician.First_Name__c+'","TechnicianLastName":"'+technician.Last_Name__c+'","FormattedTotalTime":"8 hours","StartDate":"14/11/23","TimeIn":"09:00","TimeOut":"17:00","TimeInHour":9,"TimeInMinute":0,"IsClockedOn":false}';
            String result = BPUtility.getDecodedString(PayrollCtrl.saveClockStatus(BPUtility.getEncodedString(jsonString)));
        Test.stopTest();
    }

    @isTest
    private static void testSaveClockStatusWithClockedOnTrue() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id, Technician_Name__c, First_Name__c, Last_Name__c FROM Technician__c LIMIT 1];
            Payroll_Time__c payrollTime = [SELECT Id, Technician__c, Start_Date__c, End_Date__c FROM Payroll_Time__c WHERE Technician__c = :technician.Id LIMIT 1];
            String jsonString = '{"Id":"'+payrollTime.Id+'","TechnicianId":"'+technician.Id+'","TechnicianName":"'+technician.Technician_Name__c+'","TechnicianFirstName":"'+technician.First_Name__c+'","TechnicianLastName":"'+technician.Last_Name__c+'","FormattedTotalTime":"8 hours","StartDate":"14/11/23","TimeIn":"09:00","TimeOut":"17:00","TimeInHour":9,"TimeInMinute":0,"IsClockedOn":true}';
            String result = BPUtility.getDecodedString(PayrollCtrl.saveClockStatus(BPUtility.getEncodedString(jsonString)));
        Test.stopTest();
    }

    @isTest
    private static void testPayrollOnForTechnician() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id, Technician_Name__c, First_Name__c, Last_Name__c FROM Technician__c LIMIT 1];
            PayrollCtrl.payrollOnForTechnician(technician.Id);
            Payroll_Time__c payrollTime = [SELECT Id, Technician__c, Start_Date__c, End_Date__c FROM Payroll_Time__c WHERE Technician__c = :technician.Id LIMIT 1];
            system.assertEquals(technician.Id, payrollTime.Technician__c);
        Test.stopTest();
    }

    @isTest
    private static void testGetPayrollList() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id, Technician_Name__c FROM Technician__c LIMIT 1];
            String jsonString = '{"StartDate": "14/11/23","EndDate": "15/11/23","EmployeeId": "'+technician.id+'"}';
            String result = BPUtility.getDecodedString(PayrollCtrl.getPayrollList(BPutility.getEncodedString(jsonString)));
        Test.stopTest();
    }

    @isTest
    private static void testSavePayrollRec() {
        makeTestData();
        Test.startTest();
            String query = 'SELECT '; 
            for(String fieldsName : PayrollWrapper.getPayrollFieldsList()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' FROM  Payroll_Time__c LIMIT 1';
            Payroll_Time__c payrollTimeRec = Database.query(query);
            PayrollWrapper payrollWrapper = new PayrollWrapper(payrollTimeRec);
            payrollWrapper.IsClockedOn = false;
            String jsonString = json.serialize(payrollWrapper);
            String result = BPUtility.getDecodedString(PayrollCtrl.savePayrollRec(BPutility.getEncodedString(jsonString), BPUtility.getEncodedString('')));
            List<PayrollWrapper> payrollWrapperList = new List<PayrollWrapper>((List<PayrollWrapper>)json.deserialize(result, List<PayrollWrapper>.class));
            system.assertEquals(payrollWrapperList.size(), 1);
        Test.stopTest();
    }

    @isTest
    private static void testDeletePayrollRec() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
            Payroll_Time__c payrollTime = [SELECT Id  FROM Payroll_Time__c LIMIT 1];
            String jsonString = '{"StartDate": "14/11/23","EndDate": "15/11/23","EmployeeId": "'+technician.id+'"}';
            String result = BPUtility.getDecodedString(PayrollCtrl.deletePayrollRec(BPUtility.getEncodedString(payrollTime.Id), BPUtility.getEncodedString(jsonString)));
        Test.stopTest();
    }

    @isTest
    private static void testVerifyTechnicianPin() {
        makeTestData();
        Test.startTest();
            Technician__c technician = [SELECT Id, PIN__c FROM Technician__c LIMIT 1];
            String result = PayrollCtrl.verifyTechnicianPin(BPUtility.getEncodedString(technician.Id), BPUtility.getEncodedString(technician.PIN__c));
        Test.stopTest();
    }
}
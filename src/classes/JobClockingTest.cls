@IsTest
public without sharing class JobClockingTest {

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
        List<SO_Status__c> jobStatusList = TestDataFactory_V2.createTestDataForServiceJobStatus();
        
        CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
        Id soHeaderId = [SELECT Id FROM Service_Order_Header__c LIMIT 1].Id;
        Task__c taskRec = TestDataFactory.createTask();
        Hours_Logged__c hoursLoggedRec = TestDataFactory.createHoursLogged(technicianList[0].Id, soHeaderId, taskRec.Id);
        Payroll_Time__c payrollTimeRec = TestDataFactory.createPayrollTime(technicianList[0].Id);
        
        User_Group__c usergrp = new User_Group__c(); 
        usergrp.Service_job__c = 'Primary'; 
        insert usergrp;
        User_To_Group__c UserAssign = new User_To_Group__c(); 
        UserAssign.User__c = userinfo.getUserId();
        UserAssign.User_Group__c = usergrp.Id;
        Insert UserAssign;
    }

    
    @isTest
    private static void testConstructor(){
        makeTestData();
        Test.startTest();
        JobClockingCtrl jobClockingCtrl = new JobClockingCtrl();
        JobClockingCtrl jobClockingCtrlwithNewHomePage = new JobClockingCtrl(new NewHomePageCtrl());
        Technician__c technician = [SELECT Technician_Name__c FROM Technician__c LIMIT 1];
        system.assertEquals(technician.Technician_Name__c, 'Test Name');
        Test.stopTest();
    }
    
    @isTest
    private static void testGetServiceJobs(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        String result = JobClockingCtrl.getServiceJobs(BPUtility.getEncodedString(technician.Id));
        result = BPUtility.getDecodedString(result);
        List<JobClockingWrapper> jobClockingWrapperList = new List<JobClockingWrapper>((List<JobClockingWrapper>)json.deserialize(result, List<JobClockingWrapper>.class));
        system.assertEquals(true, jobClockingWrapperList[0].IsServiceJobClocked);
        system.assertEquals('Service Job 1', jobClockingWrapperList[0].ServiceJobName);
        system.assertEquals('New job', jobClockingWrapperList[0].ServiceJobStatus);
        system.assertEquals('test0', jobClockingWrapperList[0].ServiceJobType);
        system.assertEquals('FirstName', jobClockingWrapperList[0].TechnicianList[0].FirstName);
        system.assertEquals('LastName', jobClockingWrapperList[0].TechnicianList[0].LastName);
        system.assertEquals(true, jobClockingWrapperList[0].TechnicianList[0].IsClocked);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetTechnicianList(){
        makeTestData();

        Test.startTest();
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        String result = BPUtility.getDecodedString(JobClockingCtrl.getTechnicianList(BPUtility.getEncodedString(soHeaderRec.Id)));
        List<SOHeaderWrapper.TechnicianWrapper> technicianObjList = new List<SOHeaderWrapper.TechnicianWrapper>((List<SOHeaderWrapper.TechnicianWrapper>)json.deserialize(result, List<SOHeaderWrapper.TechnicianWrapper>.class));
        system.assertEquals('FirstName', technicianObjList[0].FirstName);
        system.assertEquals('LastName', technicianObjList[0].LastName);
        system.assertEquals(null, technicianObjList[0].IsClockedOn);
        Test.stopTest();
    }
    
    @isTest
    private static void testAssignTechnician(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        String result = BPUtility.getDecodedString(JobClockingCtrl.assignTechnician(BPUtility.getEncodedString(soHeaderRec.Id), BPUtility.getEncodedString(technician.Id), BPUtility.getEncodedString(null)));
        JobClockingWrapper jobClockingWrapper = (JobClockingWrapper)json.deserialize(result, JobClockingWrapper.class);
        system.assertEquals([SELECT Id, Name FROM Account WHERE Is_Customer__c = true LIMIT 1].Name, jobClockingWrapper.CustomerName);
        Test.stopTest();
    }
    
    @isTest
    private static void testRemoveTechnician(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        Hours_Logged__c hoursLogged = [SELECT Start_Date_Time__c FROM Hours_Logged__c LIMIT 1];
        hoursLogged.Start_Date_Time__c = null;
        update hoursLogged;
        String result = BPUtility.getDecodedString(JobClockingCtrl.removeTechnician(BPUtility.getEncodedString(soHeaderRec.Id), BPUtility.getEncodedString(technician.Id), BPUtility.getEncodedString(null)));
        JobClockingWrapper jobClockingWrapper = (JobClockingWrapper)json.deserialize(result, JobClockingWrapper.class);
        system.assertEquals([SELECT Id, Name FROM Account WHERE Is_Customer__c = true LIMIT 1].Name, jobClockingWrapper.CustomerName);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetHoursLoggedBySOHeaderId(){
        makeTestData();

        Test.startTest();
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        String result = BPUtility.getDecodedString(JobClockingCtrl.getHoursLoggedBySOHeaderId(BPUtility.getEncodedString(soHeaderRec.Id)));
        List<JobClockingWrapper.HoursLoggedInfo> sortedHoursLoggedInfoList = new List<JobClockingWrapper.HoursLoggedInfo>((List<JobClockingWrapper.HoursLoggedInfo>)json.deserialize(result,List<JobClockingWrapper.HoursLoggedInfo>.class));
        system.assertEquals('', sortedHoursLoggedInfoList[0].Notes);
        system.assertEquals('FirstName', sortedHoursLoggedInfoList[0].TechnicianFirstName);
        system.assertEquals('LastName', sortedHoursLoggedInfoList[0].TechnicianLastName);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetPayrollEntryForTechnician(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id, (SELECT id FROM Payroll_Times__r) FROM Technician__c LIMIT 1];
        String result = BPUtility.getDecodedString(JobClockingCtrl.getPayrollEntryForTechnician(BPUtility.getEncodedString(technician.Id)));
        system.assertEquals ('{"IsPayrollOn" : true, "PayrollId" : "'+ technician.Payroll_Times__r[0].Id +'"}', result);
        Test.stopTest();
    }
    
    @isTest
    private static void testSetPayrollForTechnician(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Payroll_Time__c payrollTime = [SELECT Id, Technician__c, Technician__r.Technician_Name__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, Start_Date__c, End_Date__c, Formatted_Total_Time__c  FROM Payroll_Time__c LIMIT 1];
        PayrollWrapper payrollWrapper = new PayrollWrapper(payrollTime);
        payrollWrapper.IsClockedOn = true;
        String result = BPUtility.getDecodedString(JobClockingCtrl.setPayrollForTechnician(BPUtility.getEncodedString(json.serialize(payrollWrapper)), BPUtility.getEncodedString(technician.Id)));
        system.assertEquals(true, result.containsIgnoreCase('{"IsPayrollOn" : true'));
        Test.stopTest();
    }
    
    @isTest
    private static void testSetPayrollEntryForTechnician(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        String result = BPUtility.getDecodedString(JobClockingCtrl.setPayrollEntryForTechnician(BPUtility.getEncodedString(technician.Id)));
        system.assertEquals ('{"IsPayrollOn" : true}', result);
        Test.stopTest();
    }
    
    @isTest
    private static void testClockONTechnicianForSOHeader(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        Hours_Logged__c hoursLogged = [SELECT Start_Date_Time__c FROM Hours_Logged__c LIMIT 1];
        hoursLogged.Start_Date_Time__c = null;
        update hoursLogged;
        String result = BPUtility.getDecodedString(JobClockingCtrl.clockONTechnician(BPUtility.getEncodedString(soHeaderRec.Id), BPUtility.getEncodedString(technician.Id)));
        List<JobClockingWrapper> jobClockingWrapperList = new List<JobClockingWrapper>((List<JobClockingWrapper>)json.deserialize(result, List<JobClockingWrapper>.class));
        system.assertEquals([SELECT Id, Name FROM Account WHERE Is_Customer__c = true LIMIT 1].Name, jobClockingWrapperList[0].CustomerName);
        Test.stopTest();
    }
    
    @isTest
    private static void testClockOFFTechnicianWithNotesForSOHeader(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Service_Order_Header__c soHeaderRec = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
        Notes__c notes = TestDataFactory.createNotes();
        String result = BPUtility.getDecodedString(JobClockingCtrl.clockOFFTechnicianWithNotes(BPUtility.getEncodedString(soHeaderRec.Id), BPUtility.getEncodedString(technician.Id), BPUtility.getEncodedString(notes.Id)));
        JobClockingWrapper jobClockingWrapper = (JobClockingWrapper)json.deserialize(result, JobClockingWrapper.class);
        system.assertEquals([SELECT Id, Name FROM Account WHERE Is_Customer__c = true LIMIT 1].Name, jobClockingWrapper.CustomerName);
        Test.stopTest();
    }
    
    @isTest
    private static void testClockOFFTechnicianWithNotesForTask(){
        makeTestData();

        Test.startTest();
        Technician__c technician = [SELECT Id FROM Technician__c LIMIT 1];
        Task__c task = [SELECT Id FROM Task__c LIMIT 1];
        Notes__c notes = TestDataFactory.createNotes();
        String result = BPUtility.getDecodedString(JobClockingCtrl.clockOFFTechnicianWithNotes(BPUtility.getEncodedString(task.Id), BPUtility.getEncodedString(technician.Id), BPUtility.getEncodedString(notes.Id)));
        TaskWrapper jobClockingWrapper = (TaskWrapper)json.deserialize(result, TaskWrapper.class);
        system.assertEquals(0, jobClockingWrapper.TimeSpentDays);
        system.assertEquals(0, jobClockingWrapper.TechnicianList.size());
        system.assertEquals(null, jobClockingWrapper.Name);
        system.assertEquals(false, jobClockingWrapper.IsClockedOn);
        system.assertEquals(0, jobClockingWrapper.CurrentlyClockedMinutes);
        system.assertEquals(0, jobClockingWrapper.CurrentlyClockedHours);
        system.assertEquals(0, jobClockingWrapper.CurrentlyClockedDays);
        system.assertEquals('00h00min', jobClockingWrapper.CurrentlyClocked);

        Test.stopTest();
    }
}
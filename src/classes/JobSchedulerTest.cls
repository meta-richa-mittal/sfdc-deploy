@IsTest
public class JobSchedulerTest {

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

        User_Group__c usergrp = new User_Group__c(); 
        usergrp.Service_job__c = 'Primary'; 
        insert usergrp;
        User_To_Group__c UserAssign = new User_To_Group__c(); 
        UserAssign.User__c = userinfo.getUserId();
        UserAssign.User_Group__c = usergrp.Id;
        Insert UserAssign;
    }

    @IsTest
    static void testGetTechnicianListForSpecificDay() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
            
            String result = SchedulerCtrl.getTechnicianListForSpecificDay(BPUtility.getEncodedString('11/14/2023'));
            List<TechnicianDetailWrapper> response = (List<TechnicianDetailWrapper>)Json.deserialize(BPUtility.getDecodedString(result), List<TechnicianDetailWrapper>.class);
            assertGetTechnicianListForSpecificDay(response);
       Test.stopTest();
    }

    public static void assertGetTechnicianListForSpecificDay(List<TechnicianDetailWrapper> response) {
        system.assertEquals(null, response[0].WorkingDays);
        system.assertEquals(null, response[0].Role);
        system.assertEquals(null, response[0].PIN);
        system.assertEquals('FL', response[0].NameInitials);
        system.assertEquals('Test Name', response[0].Name);
        system.assertEquals(0, response[0].LeaveList.size());
        system.assertEquals('LastName', response[0].LastName);
        system.assertEquals(0, response[0].LabourCostPerHour);
        system.assertEquals(true, response[0].IsTechnician);
        system.assertEquals(false, response[0].IsLicensedUser);
        system.assertEquals(false, response[0].IsFullDayLeave);
        system.assertEquals(null, response[0].HoursForSorting);
        system.assertEquals(false, response[0].HasPartialDayLeave);
        system.assertEquals('FirstName', response[0].FirstName);
        system.assertEquals(2, response[0].BookedHours);
        system.assertEquals(null, response[0].AvailableHoursMorningColor);
        system.assertEquals(null, response[0].AvailableHoursMorning);
        system.assertEquals(null, response[0].AvailableHoursAfternoon);
        system.assertEquals(null, response[0].AvailableHoursAfternoonColor);
        system.assertEquals(9, response[0].AvailableHours);
    }

    @IsTest
    static void testGetAllUnassignedAppointmentsForPullOut() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String result = SchedulerCtrl.getAllUnassignedAppointmentsForPullOut();
            List<UnassignedAppointmentPulloutWrapper.DatewiseUnassignedAppWrapper> response = (List<UnassignedAppointmentPulloutWrapper.DatewiseUnassignedAppWrapper>)Json.deserialize(BPUtility.getDecodedString(result), List<UnassignedAppointmentPulloutWrapper.DatewiseUnassignedAppWrapper>.class);
            assertGetAllUnassignedAppointmentsForPullOut(response);
       Test.stopTest();
    }

    public static void assertGetAllUnassignedAppointmentsForPullOut(List<UnassignedAppointmentPulloutWrapper.DatewiseUnassignedAppWrapper> response ) {
        system.assertEquals(1, response.size());
        system.assertEquals(1, response[0].PMAppointmentList.size());
        system.assertEquals('11/14/2023', response[0].PMAppointmentList[0].ActualEndDate);
        system.assertEquals('1:00PM', response[0].PMAppointmentList[0].ActualEndTime);
        system.assertEquals('11/14/2023', response[0].PMAppointmentList[0].ActualStartDate);
        system.assertEquals('12:00PM', response[0].PMAppointmentList[0].ActualStartTime);
        system.assertEquals('Afternoon', response[0].PMAppointmentList[0].AppointmentDaySegment);
        system.assertEquals(1, response[0].PMAppointmentList[0].AppointmentEstimatedHours);
        CO_Header__c coHeaderRec = [SELECT id, Name FROM CO_Header__c LIMIT 1];
        system.assertEquals(coHeaderRec.Id, response[0].PMAppointmentList[0].COId);
        system.assertEquals(0, response[0].PMAppointmentList[0].Concern.size());
        system.assertEquals(coHeaderRec.Name, response[0].PMAppointmentList[0].CONumber);
        system.assertEquals('test0', response[0].PMAppointmentList[0].CustomerName);
        system.assertEquals('test0', response[0].PMAppointmentList[0].TransactionTypeLabel);
        system.assertEquals('Customer', response[0].PMAppointmentList[0].TransactionType);
        system.assertEquals('Service Job 1', response[0].PMAppointmentList[0].Title);
    }

    @IsTest
    static void testGetAppointmentSchedulerDataForDateRange() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
            
            String result = SchedulerCtrl.getAppointmentSchedulerDataForDateRange(BPUtility.getEncodedString('11/14/2023'), BPUtility.getEncodedString('11/14/2023'));
            AppointmentSchedulerWrapper response = (AppointmentSchedulerWrapper)Json.deserialize(BPUtility.getDecodedString(result), AppointmentSchedulerWrapper.class);
            assertGetAppointmentSchedulerDataForDateRange(response);
       Test.stopTest();
    }

    public static void assertGetAppointmentSchedulerDataForDateRange(AppointmentSchedulerWrapper response) {
        system.assertEquals('11/14/2023', response.DateTo);
        system.assertEquals('11/14/2023', response.DateFrom);
        system.assertEquals(45, response.TotalWorkingHours);
        system.assertEquals(0, response.BookedHours);

        system.assertEquals(7, response.WeekDataList.size());
        system.assertEquals(true, response.WeekDataList[0].IsWorking);
        system.assertEquals(false, response.WeekDataList[0].IsToday);
        system.assertEquals(0, response.WeekDataList[0].DayIndex);
        system.assertEquals('Mon', response.WeekDataList[0].Day);
        system.assertEquals('11/14/2023', response.WeekDataList[0].AppointmentDate);

        system.assertEquals(2, response.WeekDataList[0].DaySegments.size());
        system.assertEquals(4, response.WeekDataList[0].DaySegments[0].TotalWorkingHours);
        system.assertEquals(0, response.WeekDataList[0].DaySegments[0].TotalAppointments);
        system.assertEquals('8:00AM', response.WeekDataList[0].DaySegments[0].StartTime);
        system.assertEquals(0, response.WeekDataList[0].DaySegments[0].BookedHours);
        system.assertEquals(4, response.WeekDataList[0].DaySegments[0].AvailableHours);
    }

    @IsTest
    static void testGetAssignedAppointmentForSpecificDayTest() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
            
            String result = SchedulerCtrl.getAssignedAppointmentForSpecificDay(BPUtility.getEncodedString('11/14/2023'));
            Map<String, List<AppointmentWrapper>> response = (Map<String, List<AppointmentWrapper>>)Json.deserialize(BPUtility.getDecodedString(result), Map<String, List<AppointmentWrapper>>.class);
            List<String> recIds = new List<String>(response.keySet());
            assertAssignedAppointmentForSpecificDay(response.get(recIds[0]));
       Test.stopTest();
    }

    public static Void assertAssignedAppointmentForSpecificDay(List<AppointmentWrapper> appoinmentList) {
        system.assertEquals(1, appoinmentList.size());
        system.assertEquals('11/14/2023', appoinmentList[0].ActualEndDate);
        system.assertEquals('10:15AM', appoinmentList[0].ActualEndTime);
        system.assertEquals('11/14/2023', appoinmentList[0].ActualStartDate);
        system.assertEquals('8:15AM', appoinmentList[0].ActualStartTime);
        system.assertEquals('Afternoon', appoinmentList[0].AppointmentDaySegment);
        system.assertEquals(1, appoinmentList[0].AppointmentEstimatedHours);
        system.assertEquals('test0', appoinmentList[0].CustomerName);
        system.assertEquals('11/16/2023', appoinmentList[0].DueInDate);
        system.assertEquals('', appoinmentList[0].DueInTime);
        system.assertEquals('11/14/2023', appoinmentList[0].EndDate);
        system.assertEquals('10:15AM', appoinmentList[0].EndTime);
        system.assertEquals(2.00, appoinmentList[0].EstimatedHours);
        system.assertEquals('November 14, 2023', appoinmentList[0].FormattedStartDate);
        system.assertEquals(false, appoinmentList[0].IsAppointmentOverlapped);
        system.assertEquals(false, appoinmentList[0].IsMultiTechnicianAssigned);
        system.assertEquals(false, appoinmentList[0].IsMultiday);
        system.assertEquals(false, appoinmentList[0].IsSameSOTypeAppointmentOverlapped);
        system.assertEquals(true, appoinmentList[0].IsSelectedDayIsEndDay);
        system.assertEquals(true, appoinmentList[0].IsSelectedDayIsStartDay);
        system.assertEquals(false, appoinmentList[0].IsUnitArrived);
        system.assertEquals(null, appoinmentList[0].IsWorkLate);
        system.assertEquals('', appoinmentList[0].PromiseByTime);
        system.assertEquals('11/16/2023', appoinmentList[0].PromisedByDate);
        system.assertEquals('New job', appoinmentList[0].ServiceJobStatus);
        system.assertEquals('Test Name', appoinmentList[0].TechnicianName);
        system.assertEquals('Service Job 1', appoinmentList[0].Title);
        system.assertEquals('Customer', appoinmentList[0].TransactionType);
        system.assertEquals('test0', appoinmentList[0].TransactionTypeLabel);
        system.assertEquals('', appoinmentList[0].UnitLocation);
    }

    @IsTest
    static void testUpdateAppointment() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"3","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
            
            String result = SchedulerCtrl.getAssignedAppointmentForSpecificDay(BPUtility.getEncodedString('11/14/2023'));
            Map<String, List<AppointmentWrapper>> response = (Map<String, List<AppointmentWrapper>>)Json.deserialize(BPUtility.getDecodedString(result), Map<String, List<AppointmentWrapper>>.class);
            List<String> recIds = new List<String>(response.keySet());
            assertUpdateAppointment(response.get(recIds[0]));
       Test.stopTest();
    }

    public static Void assertUpdateAppointment(List<AppointmentWrapper> appoinmentList) {
        system.assertEquals(1, appoinmentList.size());
        system.assertEquals('11/14/2023', appoinmentList[0].ActualEndDate);
        system.assertEquals('11:15AM', appoinmentList[0].ActualEndTime);
        system.assertEquals('11/14/2023', appoinmentList[0].ActualStartDate);
        system.assertEquals('8:15AM', appoinmentList[0].ActualStartTime);
        system.assertEquals('Afternoon', appoinmentList[0].AppointmentDaySegment);
        system.assertEquals(1, appoinmentList[0].AppointmentEstimatedHours);
        system.assertEquals('test0', appoinmentList[0].CustomerName);
        system.assertEquals('11/16/2023', appoinmentList[0].DueInDate);
        system.assertEquals('', appoinmentList[0].DueInTime);
        system.assertEquals('11/14/2023', appoinmentList[0].EndDate);
        system.assertEquals('11:15AM', appoinmentList[0].EndTime);
        system.assertEquals(3.00, appoinmentList[0].EstimatedHours);
        system.assertEquals('November 14, 2023', appoinmentList[0].FormattedStartDate);
        system.assertEquals(false, appoinmentList[0].IsAppointmentOverlapped);
        system.assertEquals(false, appoinmentList[0].IsMultiTechnicianAssigned);
        system.assertEquals(false, appoinmentList[0].IsMultiday);
        system.assertEquals(false, appoinmentList[0].IsSameSOTypeAppointmentOverlapped);
        system.assertEquals(true, appoinmentList[0].IsSelectedDayIsEndDay);
        system.assertEquals(true, appoinmentList[0].IsSelectedDayIsStartDay);
        system.assertEquals(false, appoinmentList[0].IsUnitArrived);
        system.assertEquals(null, appoinmentList[0].IsWorkLate);
        system.assertEquals('', appoinmentList[0].PromiseByTime);
        system.assertEquals('11/16/2023', appoinmentList[0].PromisedByDate);
        system.assertEquals('New job', appoinmentList[0].ServiceJobStatus);
        system.assertEquals('Test Name', appoinmentList[0].TechnicianName);
        system.assertEquals('Service Job 1', appoinmentList[0].Title);
        system.assertEquals('Customer', appoinmentList[0].TransactionType);
        system.assertEquals('test0', appoinmentList[0].TransactionTypeLabel);
        system.assertEquals('', appoinmentList[0].UnitLocation);
    }

    @IsTest
    static void testCreateCOForAppointment() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
        
            String result = SchedulerCtrl.getAssignedAppointmentForSpecificDay(BPUtility.getEncodedString('11/14/2023'));
            Map<String, List<AppointmentWrapper>> response = (Map<String, List<AppointmentWrapper>>)Json.deserialize(BPUtility.getDecodedString(result), Map<String, List<AppointmentWrapper>>.class);
            List<String> recIds = new List<String>(response.keySet());

            result = SchedulerCtrl.createCOForAppointment(BPUtility.getEncodedString(json.serialize(response.get(recIds[0])[0])));
            System.assertEquals([SELECT id FROM CO_Header__c LIMIT 1].Id, BPUtility.getDecodedString(result));
       Test.stopTest();
    }
    
    @IsTest
    static void testGetAppointmentById() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            String result = SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));

            result = SchedulerCtrl.getAppointmentById(BPUtility.getEncodedString(appointmentRecId));
            AppointmentWrapper response = (AppointmentWrapper)Json.deserialize(BPUtility.getDecodedString(result), AppointmentWrapper.class);
            assertGetAppointmentById(response);
       Test.stopTest();
    }

    public static Void assertGetAppointmentById(AppointmentWrapper response) {
        system.assertEquals('11/14/2023', response.ActualEndDate);
        system.assertEquals('9:15AM', response.ActualEndTime);
        system.assertEquals('11/14/2023', response.ActualStartDate);
        system.assertEquals('8:15AM', response.ActualStartTime);
        system.assertEquals('Afternoon', response.AppointmentDaySegment);
        system.assertEquals(1, response.AppointmentEstimatedHours);
        system.assertEquals('test0', response.CustomerName);
        system.assertEquals('11/16/2023', response.DueInDate);
        system.assertEquals('', response.DueInTime);
        system.assertEquals(null, response.EndDate);
        system.assertEquals(null, response.EndTime);
        system.assertEquals(1.00, response.EstimatedHours);
        system.assertEquals('November 14, 2023', response.FormattedStartDate);
        system.assertEquals(null, response.IsAppointmentOverlapped);
        system.assertEquals(false, response.IsMultiTechnicianAssigned);
        system.assertEquals(false, response.IsMultiday);
        system.assertEquals(null, response.IsSameSOTypeAppointmentOverlapped);
        system.assertEquals(null, response.IsSelectedDayIsEndDay);
        system.assertEquals(null, response.IsSelectedDayIsStartDay);
        system.assertEquals(false, response.IsUnitArrived);
        system.assertEquals(null, response.IsWorkLate);
        system.assertEquals('', response.PromiseByTime);
        system.assertEquals('11/16/2023', response.PromisedByDate);
        system.assertEquals('New job', response.ServiceJobStatus);
        system.assertEquals(null, response.TechnicianName);
        system.assertEquals('Service Job 1', response.Title);
        system.assertEquals('Customer', response.TransactionType);
        system.assertEquals('test0', response.TransactionTypeLabel);
        system.assertEquals('', response.UnitLocation);
    }
    
    @IsTest
    static void testUpdateEventSchedulingRecord() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));

            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"5","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            String result = SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
            List<Event_Scheduling__c> eventSchedulingList = [SELECT id, Hours__c FROM Event_Scheduling__c LIMIT 1];
            
            system.assertEquals(5, eventSchedulingList[0].Hours__c);        
       Test.stopTest();
    }

    @IsTest
    static void testGetShopSettingData() {
        makeTestData();
        Test.startTest();
            String result = SchedulerCtrl.getShopSettingData();
            List<ShopSettingWrapper> response = (List<ShopSettingWrapper>)Json.deserialize(BPUtility.getDecodedString(result), List<ShopSettingWrapper>.class);
            assertGetShopSettingData(response);
       Test.stopTest();
    }

    public static Void assertGetShopSettingData(List<ShopSettingWrapper> response) {
        System.assertEquals(7, response.size());
        System.assertEquals(true, response[0].IsWorking);
        System.assertEquals('5:00PM', response[0].ToTime);
        System.assertEquals('8:00AM', response[0].FromTime);
        System.assertEquals('Monday', response[0].Day);
    }

    @IsTest
    static void testGetMonthViewDataForDateRange() {
        makeTestData();
        Test.startTest();
            CO_CreateCOTest.createCO(CO_CreateCOTest.serviceJobSellingGroup, false);
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
            List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
            List<Transaction_Type__c> transactionTypeList = [SELECT Id FROM Transaction_Type__c LIMIT 1];
            List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];

            String jsonString = '{"CustomerId":"'+ accountList[0].Id +'","COUId":"'+ couList[0].Id +'","EstimatedHours":1,"TransactionTypeId":"'+ transactionTypeList[0].Id +'","Title":"Service Job 1","StartDate":"11/14/2023","EndDate":"11/14/2023","StartTime":"12:00pm","EndTime":"12:00pm","SOHeaderId":"'+ soHeaderList[0].Id +'","COId":"'+ coHeaderList[0].Id +'","IsMultiday":false,"IsUnitArrived":false,"PromisedByDate":"11/16/2023","DueInTime":"","DueInDate":"11/16/2023","PromiseByTime":"","UnitLocation":"","Concern":[],"EventSchedulingList":[]}';
            AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(jsonString));
            
            String appointmentRecId = [SELECT Id FROM Event__c LIMIT 1].Id; 
            String technicianRecId = [SELECT Id FROM Technician__c LIMIT 1].Id; 
            jsonString = '{"ActualStartDate":"11/14/2023","ActualStartTime":"08:15AM","Hours":"2","IsMultiday":true,"TechnicianId":"'+ technicianRecId +'","isConflictExists":false}';
            SchedulerCtrl.updateEventSchedulingRecord(BPUtility.getEncodedString(appointmentRecId), BPUtility.getEncodedString(jsonString));
        
            String result = SchedulerCtrl.getMonthViewDataForDateRange(BPUtility.getEncodedString('11/01/2023'), BPUtility.getEncodedString('11/30/2023'));
            MonthViewSchedulerWrapper response = (MonthViewSchedulerWrapper)Json.deserialize(BPUtility.getDecodedString(result), MonthViewSchedulerWrapper.class);
            assertGetMonthViewDataForDateRange(response);
       Test.stopTest();
    }

    public static Void assertGetMonthViewDataForDateRange(MonthViewSchedulerWrapper response) {
        System.assertEquals(207, response.TotalScheduledHours);
        System.assertEquals(2.00, response.TotalBookedHours);
        System.assertEquals(1, response.TechnicianDetailList.size());
        System.assertEquals('Test Name', response.TechnicianDetailList[0].TechnicianInfo.TechnicianFullName);
        System.assertEquals('FL', response.TechnicianDetailList[0].TechnicianInfo.NameInitials);
        System.assertEquals(1, response.TechnicianDetailList[0].MaxNumberOfBlocks);
        System.assertEquals(31, response.TechnicianDetailList[0].DayInfoList.size());

        System.assertEquals(true, response.TechnicianDetailList[0].DayInfoList[0].IsWorkingDayForTechnician);
        System.assertEquals(true, response.TechnicianDetailList[0].DayInfoList[0].IsWorkingDay);
        System.assertEquals(9, response.TechnicianDetailList[0].DayInfoList[0].HoursScheduledToWork);
        System.assertEquals(0, response.TechnicianDetailList[0].DayInfoList[0].HoursBooked);
        System.assertEquals('9h', response.TechnicianDetailList[0].DayInfoList[0].AvailableHoursToShow);
        System.assertEquals(0, response.TechnicianDetailList[0].DayInfoList[0].BlockList.size());

        System.assertEquals(true, response.TechnicianDetailList[0].DayInfoList[13].IsWorkingDayForTechnician);
        System.assertEquals(true, response.TechnicianDetailList[0].DayInfoList[13].IsWorkingDay);
        System.assertEquals(9, response.TechnicianDetailList[0].DayInfoList[13].HoursScheduledToWork);
    }
}
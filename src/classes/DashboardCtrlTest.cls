/**
* Author: Manoj Sharma
* Since: May 13, 2020
* Name: DashboardCtrlTest
* Description: Apex class which contains all the test methods to test dashbord ctrl.
**/
@isTest
public without sharing class DashboardCtrlTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        Account customerRec = TestUtil.createCustomer(true, 'Test customer', 'Test@gamil.com', 'jaipur', '3265986532');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customerRec.Id);

        Service_Order_Header__c soheaderRec = new Service_Order_Header__c();
        soheaderRec.Name__c = 'Test service job';
        soheaderRec.CO_Header__c = coHeader.Id;
        soheaderRec.Work_Status__c = ServiceJobUtil.IN_PROGRESS;
        insert soheaderRec;

        Technician__c techRec = new Technician__c();
        techRec.Technician_Name__c = 'Test tech';
        techRec.Type__c = 'Technician';
        techRec.Active__c = true; 
        insert techRec;

        Hours_Logged__c hoursLogRec = new Hours_Logged__c();
        hoursLogRec.Technician__c = techRec.Id;
        hoursLogRec.Start_Date_Time__c = System.now();
        hoursLogRec.Service_Order_Header__c = soheaderRec.Id;
        hoursLogRec.Time_Spent_h__c = 4;
        insert hoursLogRec;

        Event eventRec = new Event();
        eventRec.Service_Order_Header__c = soheaderRec.Id;
        eventRec.Estimated_Hours__c = 4;
        eventRec.Type = 'Appointment';
        eventRec.StartDateTime = System.now();
        eventRec.DurationInMinutes = 240;
        insert eventRec;

        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        genConfig.Dashboard_Refresh_Minutes__c = 15;
		upsert genConfig;
        
    }
    
    /**
     * Name: getServiceJobsTest
     * Desc: Test to get service job records
     * @param: 
     * @return: 
    **/
    static testMethod void getServiceJobsTest() {
        String result =  DashboardCtrl.getServiceJobs(BPUtility.getEncodedString('{"StatusFilter":"All open jobs","JobTypeFilterList":["All job types"]}'));
		List<DashboardServiceJobWrapper> record = (List<DashboardServiceJobWrapper>) System.JSON.deSerialize(BPUtility.getDecodedString(result), List<DashboardServiceJobWrapper>.class);
		System.assertEquals(1, record.size());
    }
    
    /**
     * Name: getRefreshMinutesTest
     * Desc: Test to get refresh time mins
     * @param: 
     * @return: 
    **/
    static testMethod void getRefreshMinutesTest() {
        String result =  DashboardCtrl.getRefreshMinutes();
        result = BPUtility.getDecodedString(result);
        System.assertEquals('15', result);
    }

    /**
     * Name: getTodayDayAndDateTest
     * Desc: Test to get todays day and date
     * @param: 
     * @return: 
    **/
    static testMethod void getFormattedTodaysDateTest() {
        String result =  DashboardCtrl.getFormattedTodaysDate();
        result = BPUtility.getDecodedString(result);
        System.assertNotEquals(null, result);
    }
    
    /**
     * Name: getJobTypeList
     * Desc: Test to get type of job
     * @param: 
     * @return: 
    **/
    static testMethod void getJobTypeList() {
        String result =  DashboardCtrl.getJobTypeList();
        result = BPUtility.getDecodedString(result);
        System.assertNotEquals(null, result);
    }
}
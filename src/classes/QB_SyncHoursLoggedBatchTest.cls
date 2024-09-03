@isTest
global without sharing class QB_SyncHoursLoggedBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
		List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
		customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
		headerList.add(header);
    }

    static testMethod void createHoursLoggedPayLoad() {
		//Integration Metadata
		// Insert Technician Hours Costing
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Technician_Hours_Costing__c = true;
        upsert generalConfig;
        
       	Test.startTest();
       	List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
        
        //Create Customer
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        
        // Create Customer Order
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.Id);
        coHeader.CO_Type__c = 'Customer';
        insert coHeader;
        
        // Create Service Job
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        
        // Create Technician
        Technician__c technicianRec = new Technician__c(Technician_Name__c = 'Test Technician', Active__c = true, Labour_Cost_Per_Hour__c = 150);
        insert technicianRec;
        
        // Create User
        User testUser = TestUtil.createUser(true, 'a@b.c', 'User', 'en_US', 'test.user@abc.com', 'Test');
        
        // Create Hours Logged on Service Job
        Hours_Logged__c hoursLoggedRec = new Hours_Logged__c();
        hoursLoggedRec.Technician__c = technicianRec.id;
        hoursLoggedRec.Time_Spent_h__c = 2;
        hoursLoggedRec.Start_Date_Time__c = datetime.newInstance(2019, 6, 14, 10, 30, 0);
        hoursLoggedRec.Work_Performed_Date__c = Date.newInstance(2019, 6, 9);
        hoursLoggedRec.End_Date_Time__c= datetime.newInstance(2017, 6, 14, 12, 30, 0);
        hoursLoggedRec.Service_Order_Header__c = soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id;
        insert hoursLoggedRec;
        
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
   		
   		List<Hours_Logged__c> hoursLoggedList = [Select QB_Accounting_Id__c, Available_For_QB_Sync__c from Hours_Logged__c Limit 1];
       	system.assertEquals(hoursLoggedList[0].Available_For_QB_Sync__c, false);
	}
}
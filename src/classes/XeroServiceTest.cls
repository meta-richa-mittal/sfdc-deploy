/**
 * Author: Nikhil Kumar Srivastava
 * Since: Feb 25, 2019
 * Name: XeroServiceTest 
 * Description: Test class for XeroService
**/
@isTest
global class XeroServiceTest {
	@testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.enableXeroInCustomSetting();
    	
       //Xero IFW_IntegrationConfig__c Record
      	IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
		//Header
		List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
		customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
		headerList.add(header);
    }
	
	static testMethod void ItemCategoryPayLoad() {
		//Integration Metadata
		Test.startTest();
		List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Item' , IFWConfigObj[0].Id);
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory_III = TestUtil.createCategory(false, 'Test Category III');
        testCategory_III.Income_GL__c = '35';
        insert new List<SObject>{vendor,testCategory_III};
       	Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
       	Test.stopTest();
       	List<Category__c> itemRes = [Select Id,Name,Xero_Accounting_Id__c,Available_For_Xero_Sync__c from Category__c Limit 1];
       	system.assertEquals(itemRes[0].Name,'Test Category III');
       	//system.assertEquals(itemRes[0].Xero_Accounting_Id__c,'xxxItemID101xxx');
       	testCategory_III.Description__c = 'Test Category III for Testing';
        update testCategory_III;
       	
	}
	
	static testMethod void createCODepositPayLoad() {
		//Integration Metadata
       	Test.startTest();
       	List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObj[0].Id);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        
        List<Part__c> partList = new List<Part__c> ();
        Part__c partObject1 = TestUtil.createPart(true, '101', vendor.id, 'test1', testCategory.id, 200, 200, 100, 20, 20);
        partList.add(partObject1);
        List<String> partidList = new List<String>{partObject1.id};
        
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, partObject1.Id, 50);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
   		Test.stopTest();
   		
   		List<CO_Deposit__c> coDepositRes = [Select Id,Name,Xero_Accounting_Id__c,Available_For_Xero_Sync__c from CO_Deposit__c Limit 1];
       	system.assertEquals(coDepositRes[0].Available_For_Xero_Sync__c,false);
       	system.assertEquals(coDepositRes[0].Xero_Accounting_Id__c,'6d037ca7-113b-4919-b4dd-22432503e76a');
	}
	
	static testMethod void ItemCategoryPayLoadfailureRecordsTest () {
		List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Item' , IFWConfigObj[0].Id);
		IFWConfigItemObj.Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/Item';
		update IFWConfigItemObj;
		Test.startTest();
		Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory_III = TestUtil.createCategory(false, 'Test Category III');
        testCategory_III.Income_GL__c = '35';
        //testCategory_III.Available_For_Xero_Sync__c = true;
        insert new List<SObject>{vendor,testCategory_III};
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
		Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
		
	
	}
	
	static testMethod void createHoursLoggedPayLoad() {
		//Integration Metadata
		// Insert Technician Hours Costing
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Technician_Hours_Costing__c = true;
        upsert generalConfig;
        
       	Test.startTest();
       	List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObj[0].Id);
        
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
        
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
   		Test.stopTest();
   		
   		List<Hours_Logged__c> hoursLoggedList = [Select Xero_Accounting_Id__c, Available_For_Xero_Sync__c from Hours_Logged__c Limit 1];
       	system.assertEquals(hoursLoggedList[0].Available_For_Xero_Sync__c, false);
       	system.assertEquals(hoursLoggedList[0].Xero_Accounting_Id__c, '6d037ca7-113b-4919-b4dd-22432503e76a');
	}
}
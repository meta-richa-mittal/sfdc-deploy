/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 07, 2019
 * Name: WebServiceLogTriggerHelperTest
 * Description: Test class for Helper Class to execute operation on WebServiceLog
**/
@isTest
public without sharing class WebServiceLogTriggerHelperTest {
	
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
	
	static testMethod void WebServiceLogTriggerHelperTestforXero() {
		//Integration Metadata
       	Test.startTest();
       	List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObj[0].Id);
		IFWConfigItemObj.Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/Item';
		update IFWConfigItemObj;
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
       	List<WebService_Log__c> logRecordList = [SELECT Id, Name, CreatedDate, Endpoint__c, IFW_IntegrationConfig__c, Status__c,Entity_Name__c,IFW_IntegrationConfig__r.Integration_Name__c, Apex_Class__c FROM WebService_Log__c WHERE CreatedDate = TODAY AND Response_Code__c !='200' AND Status__c != 'OK' LIMIT 1 ];
	    system.assertEquals(1,logRecordList.size());
	}
}
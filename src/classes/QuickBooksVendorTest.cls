/**
 * Author: Pooja Khandelwal
 * Since: Dec. 26, 2016
 * Name: AccSync_CustomerInvoice_Batch_Scheduler
 * Description: Scheduler class for AccSync_CustomerInvoice_Batch
**/
@isTest
private class  QuickBooksVendorTest {
	//private String rootVendorJSONString;
    @testSetup
    private static void setup()	{
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
    }
    
    private static testmethod void syncVendorToQBTest()	{
    	Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Vendor' , IFWConfigObj[0].Id);
    	Account Vendor =  TestUtil.createVendor(true, 'Qb Vendor');
        Test.stopTest();
        List<Account> acc = [Select Id, Vendor_AccountingResponse__c, AccountingId__c From Account Where Is_Vendor__c = true];
        system.assertEquals(acc[0].Vendor_AccountingResponse__c != null, true); 
    }
}
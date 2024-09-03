/**
 * Author: Nikhil Kumar Srivastava
 * Since: April 16, 2019
 * Name: AccountingVendorBatchSchedulerTest
 * Description: test Class for AccountingVendorBatchScheduler.
**/

@isTest
public without sharing  class AccountingVendorBatchSchedulerTest {

    @testSetup
    private static void setupTestData() { 
        TestDataFactory.disableFLSChecks();
        TestUtil.createIFWConfigForXero();
        insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Contacts' , IFWConfigObj[0].Id);
        //Disable Trigger to stop syncing the record
        Trigger_Soft_Disable__c triggerToDisable = new Trigger_Soft_Disable__c();
        triggerToDisable.Name = 'CustomerTrigger';
        triggerToDisable.Disable_Delete__c = triggerToDisable.Disable_Insert__c = triggerToDisable.Disable_Undelete__c = true;
        triggerToDisable.Disable_Update__c = true;
        insert triggerToDisable;
        Account vendorObj = TestUtil.createVendor(false, 'Xero Vendor');
        vendorObj.Available_For_Xero_Vendor_Sync__c = true;
        insert vendorObj;
        delete triggerToDisable;
        system.assertEquals(true, String.isNotBlank(vendorObj.Id));
    }
    
    static testmethod void AccountingCustomerBatchSchedulerTest() { 
        List<Account> accList = [Select Id,Is_Vendor__c from Account where Is_Vendor__c = true Limit 1];
        system.assertEquals(1,accList.size());
        system.assertEquals(true,accList[0].Is_Vendor__c);
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        test.startTest();
        XeroScriptUtil.syncVendors(25,120,25);
        test.stopTest();
     }
}
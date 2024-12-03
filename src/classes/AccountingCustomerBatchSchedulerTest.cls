/**
 * Author: Nikhil Kumar Srivastava
 * Since: April 16, 2019
 * Name: AccountingCustomerBatchSchedulerTest
 * Description: test Class for AccountingCustomerBatchScheduler.
**/

@isTest
public without sharing class AccountingCustomerBatchSchedulerTest {
    
    @testSetup
    private static void setupTestData() { 
        TestDataFactory.disableFLSChecks();
        TestUtil.createIFWConfigForXero();
        insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Contacts', IFWConfigObj[0].Id);
        //Disable Trigger to stop syncing the record
        Trigger_Soft_Disable__c triggerToDisable = new Trigger_Soft_Disable__c();
        triggerToDisable.Name = 'CustomerTrigger';
        triggerToDisable.Disable_Delete__c = triggerToDisable.Disable_Insert__c = triggerToDisable.Disable_Undelete__c = true;
        triggerToDisable.Disable_Update__c = true;
        insert triggerToDisable;
        Account testCustomer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet'); 
        testCustomer.Available_For_Xero_Customer_Sync__c = true;
        insert testCustomer;
        delete triggerToDisable;
        system.assertEquals(true, String.isNotBlank(testCustomer.Id));
    }
    
    
    static testmethod void AccountingCustomerBatchSchedulerTest() { 
        List<Account> accList = [Select Id,Is_Customer__c from Account where Is_Customer__c = true Limit 1];
        system.assertEquals(1,accList.size());
        system.assertEquals(true,accList[0].Is_Customer__c);
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        Test.startTest();
        XeroScriptUtil.syncCustomers(25,120,25);
        Test.stopTest();
     } 
}
/**
 * Author: Nidhi Sharma
 * Name: SyncPaymentOnAccountBatchTest 
 * Description: Test class for SyncPaymentOnAccountBatch.
**/
@isTest
public without sharing class SyncPaymentOnAccountBatchTest {
	
     @testSetup
    private static void setupTestData() {
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
        insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
    }
    
    static testmethod void testSyncPaymentOnAccountBatch() {
   		Account testCustomer = [Select Id from Account where Name = 'test customer' AND Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id);
        insert poaRec;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id, Amount_Paid__c = 10);
        Payment_on_Account__c paymentOnAccountRec = [Select Id, Payment_Date__c from Payment_on_Account__c Limit 1][0];
        paymentOnAccountRec.Payment_Date__c = system.today();
        update paymentOnAccountRec;
        Test.stopTest();
        List<Payment_on_Account__c> poaList = [Select Id, Available_For_Xero_Sync__c from Payment_on_Account__c];
   		system.assertEquals(1, poaList.size());
	}
}
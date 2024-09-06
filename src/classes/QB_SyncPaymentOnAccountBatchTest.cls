@isTest
public without sharing class QB_SyncPaymentOnAccountBatchTest {
    @testSetup
    private static void setupTestData() {
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
        TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.JOURNAL_ENTRY, IFWConfigObj[0].Id);
    }
    
    static testmethod void testSyncPaymentOnAccountBatch() {
   		Account testCustomer = [Select Id from Account where Name = 'test customer' AND AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id, Amount_Paid__c = 10);
        insert poaRec;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id, Amount_Paid__c = 10);
        Test.stopTest();
        List<Payment_on_Account__c> poaList = [Select Id, Available_For_QB_Sync__c, QB_Accounting_Id__c from Payment_on_Account__c];
        system.assertEquals(false , poaList[0].Available_For_QB_Sync__c);
    	system.assertNotEquals(poaList[0].QB_Accounting_Id__c, null);
	} 
}
@isTest
private class SyncARPaymentBatchTest {
    @TestSetup
    private static void setup(){
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
        insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
        

    }
    @isTest
    private static void testSyncARPaymentBatch() {
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
        Payment_on_Account__c paymentOnAccount = new Payment_on_Account__c(customer__c = testCustomer.id, Payment_Date__c = system.today(), Payment_Method__c = 'Debit');
        insert paymentOnAccount;
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        Test.startTest();   
        AR_Payment__c arPayment = new AR_Payment__c(Payment_on_Account__c = paymentOnAccount.id, Amount_Paid__c = 10);
        insert arPayment;
        List<AR_Payment__c> arPaymentList = [Select id from AR_Payment__c limit 1];
        system.assertEquals(1, arPaymentList.size());
        Test.stopTest();
    }
    
}
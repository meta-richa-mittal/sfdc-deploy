@isTest
private class AccountingBatchSchedulerTest {
    static String CRON_EXP = '0 0 0 * * ? *';	
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
        TestUtil.createNameSpaceInGeneralConfig();
        List <General_Configurations__c> config = [SELECT Id FROM General_Configurations__c LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
        system.assertNotEquals(0, config.size());

    }
    @isTest
    private static void testAccountingBatchScheduler() {
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
        Payment_on_Account__c paymentOnAccount = new Payment_on_Account__c(customer__c = testCustomer.id, Payment_Date__c = system.today(), Payment_Method__c = 'Debit');
        insert paymentOnAccount;
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        Test.startTest();   
        AR_Payment__c arPayment = new AR_Payment__c(Payment_on_Account__c = paymentOnAccount.id, Amount_Paid__c = 10);
        insert arPayment;
        AccountingBatchScheduler arPaymentObj = new AccountingBatchScheduler(null, 200, IntegrationUtility.AR_PAYMENT);
        String jobId = system.schedule('AccountingBatchSchedulerTest', CRON_EXP, arPaymentObj);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        new AccountingBatchScheduler(null, 200, IntegrationUtility.AR_PAYMENT, new List<String>());
        new AccountingBatchScheduler(null, 200, IntegrationUtility.AR_PAYMENT, false);
        Test.stopTest();
    }
    
}
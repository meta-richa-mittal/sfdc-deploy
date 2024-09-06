@isTest
private class PaymentOnAccountTriggerHelperTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    static testMethod void testPaymentOnAccountUpdate() {
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id);
        insert poaRec;
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id, Amount_Paid__c = 10);
        List<Payment_on_Account__c> poaList = [Select Id, Total_Payment__c from Payment_on_Account__c];
        system.assertEquals(10, poaList[0].Total_Payment__c);
    }   
}
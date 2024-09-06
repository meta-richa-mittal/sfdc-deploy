@isTest
private class ARPaymentTriggerHelperTest {
    
    static testMethod void testARPaymentInsert() {
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id);
        insert poaRec;
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id);
        system.assertEquals(1, [Select Id from AR_Payment__c].size());
    }   
}
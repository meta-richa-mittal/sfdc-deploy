@isTest
public without sharing class AccSync_ARPayment_Batch_Test {
	@testSetup
   	static void setup() {
   		TestUtil.setQuickBooksConfigurations(false);
   	}
   	
	static testmethod void testSyncARPayment() {
        Test.startTest();
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id);
        BPScriptUtility.disbaleTrigger('PaymentOnAccountTrigger');
        insert poaRec;
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id, Amount_Paid__c = 10);
        BPScriptUtility.enableTrigger('PaymentOnAccountTrigger');
        List<Payment_on_Account__c> poaList = [Select Id, Available_For_QB_Sync__c, Available_For_QB_AR_Payment_Sync__c from Payment_on_Account__c];
        poaList[0].Available_For_QB_AR_Payment_Sync__c = true;
        update poaList;
        Test.stopTest();
        poaList = [Select Id, QB_AR_Payment_Accounting_Id__c from Payment_on_Account__c];
        system.assertEquals('2838', poaList[0].QB_AR_Payment_Accounting_Id__c);
    }
	
	static testmethod void testSetARPaymentFlag() {
		Test.startTest();
   		Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        Payment_on_Account__c poaRec = new Payment_on_Account__c(Payment_Date__c = system.today(), Payment_Method__c = 'Debit', Customer__c = testCustomer.Id);
        insert poaRec;
        insert new AR_Payment__c(Payment_on_Account__c = poaRec.Id, Amount_Paid__c = 10);
        List<Payment_on_Account__c> poaList = [Select Id, Available_For_QB_AR_Payment_Sync__c from Payment_on_Account__c];
   		system.assertEquals(true, poaList[0].Available_For_QB_AR_Payment_Sync__c);
   		Test.stopTest();
	}
}
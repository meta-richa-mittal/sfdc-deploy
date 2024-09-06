@isTest
private without sharing class QBInvoiceDueDateServiceTest {
    
    @testSetup
    private static void setup() {
        TestUtil.setQuickBooksConfigurations(false);
        QB_Term__c standardQBTerm = TestDataFactory.createQBTerm('STANDARD');
        QB_Term__c dateDrivenQBTerm = TestDataFactory.createQBTerm('DATE_DRIVEN');
    }
    
    @isTest
    private static void testGetVendorInvoiceDueDate() {
        Date invDate = system.today();
        QuickbookConnector.getQuickBooksConfigurations();
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(invDate, '238');
        system.assertEquals(invDate.addDays(10), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetQBPreferenceDefaultPaymentTerm() {
        Date invDate = system.today();
        QuickbookConnector.getQuickBooksConfigurations();
        Test.startTest();
        String termQBId = QBInvoiceDueDateService.getQBPreferenceDefaultPaymentTerm();
        system.assertEquals('1', termQBId);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills() {
        Date invDate = Date.newInstance(2019, 1, 1);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDateForBills(invDate, '2');
        system.assertEquals(invDate.addDays(19), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills1() {
        Date invDate = Date.newInstance(2019, 1, 21);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDateForBills(invDate, '2');
        system.assertEquals(Date.newInstance(2019, 2, 20), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills2() {
        Date invDate = Date.newInstance(2019, 1, 12);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDateForBills(invDate, '2');
        system.assertEquals(Date.newInstance(2019, 2, 20), dueDate);
        Test.stopTest();
    }
}
@isTest
private without sharing class QBInvoiceDueDateServiceTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        QB_Term__c standardQBTerm = TestDataFactory.createQBTerm('STANDARD');
        QB_Term__c dateDrivenQBTerm = TestDataFactory.createQBTerm('DATE_DRIVEN');
    }
    
    @isTest
    private static void testGetVendorInvoiceDueDate() {
        Date invDate = system.today();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Date dueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(invDate, '238', null, new List<QB_Term__c>());
        system.assertEquals(invDate.addDays(10), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetQBPreferenceDefaultPaymentTerm() {
        Date invDate = system.today();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        String termQBId = QBInvoiceDueDateService.getQBPreferenceDefaultPaymentTerm(new IFW_IntegrationConfig__c());
        system.assertEquals('1', termQBId);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills() {
        Date invDate = Date.newInstance(2019, 1, 1);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDate(invDate, '2', null, new List<QB_Term__c>());
        system.assertEquals(invDate.addDays(19), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills1() {
        Date invDate = Date.newInstance(2019, 1, 21);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDate(invDate, '2', null, new List<QB_Term__c>());
        system.assertEquals(Date.newInstance(2019, 2, 20), dueDate);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetDueDateForBills2() {
        Date invDate = Date.newInstance(2019, 1, 12);
        Test.startTest();
        Date dueDate = QBInvoiceDueDateService.getDueDate(invDate, '2', null, new List<QB_Term__c>());
        system.assertEquals(Date.newInstance(2019, 2, 20), dueDate);
        Test.stopTest();
    }
}
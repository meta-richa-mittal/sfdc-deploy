/**
 * Author: Namarta Gocher
 * Since: March 16, 2022
 * Name: QBTermServiceTest
 * Description: Test class of QBTermService 
**/
@isTest
private without sharing class QBTermServiceTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        QuickBooks_Configurations__c qbConfig = TestDataFactory.createQBConfig();
        QB_Term__c qbTerm = TestDataFactory.createQBTerm('DATE_DRIVEN');
        
    }
    @isTest
    private static void pullTermsTest(){
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.startTest();        
        QBTermService.pullTerms(null);
        List<QB_Term__c> qbTermList = [SELECT Id FROM QB_Term__c WHERE Name != null];
        Test.stopTest();
       
        System.assertEquals(5, qbTermList.size());

    }
}
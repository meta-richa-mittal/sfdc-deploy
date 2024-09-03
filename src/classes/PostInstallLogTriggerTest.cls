@isTest
public without sharing class PostInstallLogTriggerTest {

    @TestSetup
    public static void createTestData() {
        TestDataFactory.disableFLSChecks();
        Post_Install_Log__c postInstallLogRec = new Post_Install_Log__c();  
        postInstallLogRec.Status__c = 'Pending';
        postInstallLogRec.Script_Name__c = 'Test post install Script';
        insert postInstallLogRec;
    }
    
    @isTest
    public static void PostInstallLogTriggerTest() {
        Test.startTest();
        List<Post_Install_Log__c> postInstallLogList = [SELECT Id FROM Post_Install_Log__c LIMIT 1];
        postInstallLogList[0].Status__c = 'Errored';
        update postInstallLogList;
        Test.stopTest();
        List<Post_Install_Log__c> logList = [SELECT Notified_For_Failure__c FROM Post_Install_Log__c LIMIT 1];
        System.assertEquals(true, logList[0].Notified_For_Failure__c);
    }
}

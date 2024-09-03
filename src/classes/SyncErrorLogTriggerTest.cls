@isTest
private class SyncErrorLogTriggerTest {
    
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();

        Sync_Error_Log__c ser = new Sync_Error_Log__c();
        ser.Error_Message__c = 'Test Error Message';
        insert ser;
    }

    private static testMethod void myUnitTest() {
        List<Sync_Error_Log__c> serList = [SELECT Id FROM Sync_Error_Log__c];
        System.assertEquals(1, serList.size());
        
        Sync_Error_Log__c ser = serList[0];
        ser.Error_Message__c = 'Test Error Message Updated';
        update ser;
        
        ser = [SELECT Id, Error_Message__c FROM Sync_Error_Log__c WHERE Id = :ser.Id];
        System.assertEquals('Test Error Message Updated', ser.Error_Message__c);
    }
}
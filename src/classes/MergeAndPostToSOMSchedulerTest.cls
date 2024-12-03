@isTest
private class MergeAndPostToSOMSchedulerTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    static testMethod void MergeAndPostToSOMSchedulerTest() {
        SOM_Configuration__c somConfig = SOM_Configuration__c.getOrgDefaults();
        somConfig.Blackpurl_Heroku_Endpoint__c = 'https://blackpurl-som.herokuapp.com/SOMAPI';
        insert somConfig;
        
        MergeAndPostToSOMScheduler obj = new MergeAndPostToSOMScheduler();
        obj.execute(null);
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }
}
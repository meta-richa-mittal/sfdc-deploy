@isTest
private without sharing class MergeAndPostToBRPQueueableTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    @isTest
    private static void mergeAndPostToBRPQueueableMethodTest() {
        String exportType = 'None';

        Set<String> attIdList = new Set<String>();
        attIdList.add('Set1');
        attIdList.add('Set2');

        DateTime dateTimeValue = System.today();
        //MergeAndPostToBRPQueueable mergeObj = new MergeAndPostToBRPQueueable(exportType, attIdList, dateTimeValue);

        General_Configurations__c genConfig = TestDataFactory.createGeneralConfig(1);

        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForIntegrationCheck();
        ifwConfig.Integration_Name__c = 'BRP';
        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfig);

        Test.startTest();
        System.enqueueJob(new MergeAndPostToBRPQueueable(exportType, attIdList, dateTimeValue));
        List<IFW_IntegrationConfig__c> configList = [SELECT Username__c, Password__c FROM IFW_IntegrationConfig__c 
        		WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'BRP'];
        System.assertEquals(1, configList.size());
        Test.stopTest();
    }
}

@isTest
public without sharing class GlobalControllerTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    static testMethod void getStaticResourceURLTest() {
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.isLoadStaticResource__c = true;
        upsert BPConfigurationsRec;
        GlobalController globalControllerObj = new GlobalController();
        system.assertEquals(GlobalController.Application.length() > 0, true);
    }
    
    static testMethod void gettResourceURLTest() {
        GlobalController globalControllerObj = new GlobalController();
        system.assertEquals(GlobalController.Application.length() > 0, true);
    }
        
}
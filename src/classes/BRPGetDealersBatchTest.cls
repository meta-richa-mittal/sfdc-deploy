/** 
* Author: Tarun Khandelwal
* Since: Nov 27, 2019 
* Name: BRPGetDealersBatch 
* Description: Batch Apex Test class to get all BRP Dealers using Pagination
**/
@isTest
private without sharing class BRPGetDealersBatchTest {
    
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForBRP();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForBRP('Dealer', ifwConfig.Id);
        BRP_Settings__c brpConfig = TestDataFactory.createBRPConfig();
    }
    
    @isTest
    private static void testDealersData() {
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        
        Test.startTest();
        Database.executeBatch(new BRPGetDealersBatch());
        Test.stopTest();
        
        Database.executeBatch(new BRPGetDealersBatch(1, 1));
        system.assertEquals(1, [SELECT Id FROM BRP_Dealers__c].size());
        system.assertEquals('MANKATO', [SELECT City__c FROM BRP_Dealers__c][0].City__c);
    }    
}
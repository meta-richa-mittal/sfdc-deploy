/**
 * Author: Rajat Jain
 * updated: May 25, 2018
 * Name: IntegrityCheckForQBCtrlTest
 * Description: It includes scenario based test cases for IntegrityCheckForQBCtrl.
**/

@isTest
private without sharing class IntegrityCheckForQBCtrlTest {
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
	 static testMethod void integrityCheckCtrlTest() {
	 	Test.startTest();
	 	BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email_Recipient__c = 'test.singh@test.com';
        upsert BPConfigurationsRec;
		
	 	new IntegrityCheckForQBCtrl().sendIntegrityCheckMailToSupportTeam();
	 	new IntegrityCheckForQBCtrl.EntityInfoWrapper('entityId','name','entityType');
	 	system.assertEquals(0, [SELECT Id FROM Account].size());
        Test.stopTest();
	 }
    
}
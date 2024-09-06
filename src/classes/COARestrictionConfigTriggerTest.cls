/**
 * Author: Nidhi Sharma
 * Since: April 22, 2021
 * Name: COARestrictionConfigTriggerHelper
 * Description: Trigger helper class
**/
@isTest
private class COARestrictionConfigTriggerTest {
    
    @testSetup
    private static void setupTestData() {
    	
    	Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
    	accConfig.Provider_Name__c = 'Quickbooks Online';
    	upsert accConfig;
    	
    	General_Account__c genAcc1 = new General_Account__c(Account_Type__c = 'Credit Card');
    	General_Account__c genAcc2 = new General_Account__c(Account_Type__c = 'Accounts receivable (A/R)');
    	insert new List<General_Account__c>{genAcc1, genAcc2};
    }

    static testMethod void triggerTest() {
    	List<General_Account__c> genAccList = [Select Id, Restricted__c, Account_Type__c from General_Account__c where Restricted__c = true];
    	system.assertEquals(0, genAccList.size());
    	
    	COA_Restriction_Config__c coaConfig = new COA_Restriction_Config__c();
		coaConfig.Integration_Name__c = AccountingUtil.activeAccIntegrationName;
		coaConfig.Field_Name__c = 'Account Type';
		coaConfig.Field_Value__c = 'Credit Card';
		insert coaConfig;
		
		genAccList = [Select Id, Restricted__c, Account_Type__c from General_Account__c where Restricted__c = true];
		system.assertEquals(1, genAccList.size());
		system.assertEquals('Credit Card', genAccList[0].Account_Type__c);
		
		coaConfig.Field_Value__c = 'Accounts receivable (A/R)';
		update coaConfig;
		
		genAccList = [Select Id, Restricted__c, Account_Type__c from General_Account__c where Restricted__c = true];
		system.assertEquals(1, genAccList.size());
		system.assertEquals('Accounts receivable (A/R)', genAccList[0].Account_Type__c);
		
		delete coaConfig;
		genAccList = [Select Id, Restricted__c, Account_Type__c from General_Account__c where Restricted__c = true];
		system.assertEquals(0, genAccList.size());
		
		undelete coaConfig;
		genAccList = [Select Id, Restricted__c, Account_Type__c from General_Account__c where Restricted__c = true];
		system.assertEquals(1, genAccList.size());
		system.assertEquals('Accounts receivable (A/R)', genAccList[0].Account_Type__c);
    }
}
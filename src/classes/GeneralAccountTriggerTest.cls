@isTest
private without sharing class GeneralAccountTriggerTest {

    @TestSetup
    private static void makeData(){
        TestDataFactory.disableFLSChecks();

        Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
        accConfig.Provider_Name__c = 'QuickBooks Online';
        upsert accConfig;
    }

    @isTest
    private static void triggerTest() {
        General_Account__c genAcc = new General_Account__c();
        genAcc.Accounting_Id__c = '000';
        genAcc.Is_Active__c = true;
        insert genAcc;

        Category__c category = TestDataFactory.createCategory('Test category');
        category.Income_GL__c = genAcc.Accounting_Id__c;
        upsert category;

        delete genAcc;

        system.assertEquals(null, [Select Income_GL__c from Category__c WHERE Id =: category.Id].Income_GL__c);
    }
}
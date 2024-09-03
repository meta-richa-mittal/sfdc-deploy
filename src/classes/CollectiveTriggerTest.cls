@isTest
private without sharing class CollectiveTriggerTest {

    @isTest
    private static void triggerTest() {
        Collective__c collRec = new Collective__c();
        collRec.Name__c = 'Test';
        collRec.Default__c = true;
        insert collRec;

        system.assertEquals('Test', [Select Name__c from Collective__c WHERE Id =: collRec.Id].Name__c);
    }
}
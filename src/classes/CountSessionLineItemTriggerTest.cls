/**
 * Author: Manoj Sharma
 * Since: Oct 27, 2020
 * Name: CountSessionLineItemTriggerTest
 * Description: 
**/
@isTest
public without sharing class CountSessionLineItemTriggerTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    static testMethod void setCountedFalseForIssueItemTest() {
        Count_Session__c countSessionRec = new Count_Session__c();
        countSessionRec.Name__c = 'Test count';
        countSessionRec.Type__c = 'Random count';
        insert countSessionRec;

        Count_Session_Line_Item__c csliRec = new Count_Session_Line_Item__c(Count_Session__c = countSessionRec.Id);
        csliRec.Part_Number__c = 'test part';
        csliRec.Counted_Qty__c = 10;
        csliRec.Is_Counted__c = true;
        csliRec.Issue_Indicator__c = 'Invalid part';
        insert csliRec;

        Count_Session_Line_Item__c csliRecord = [Select Id, Is_Counted__c From Count_Session_Line_Item__c];
        system.assertEquals(false, csliRecord.Is_Counted__c);

        csliRecord.Is_Counted__c = true;
        update csliRecord;

        csliRecord = [Select Id, Is_Counted__c From Count_Session_Line_Item__c];
        system.assertEquals(false, csliRecord.Is_Counted__c);

        csliRecord.Issue_Indicator__c = null;
        csliRecord.Is_Counted__c = true;
        update csliRecord;

        csliRecord = [Select Id, Is_Counted__c From Count_Session_Line_Item__c];
        system.assertEquals(true, csliRecord.Is_Counted__c);

    }
}

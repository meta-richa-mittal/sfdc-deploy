@isTest
private class AccSync_CountSession_BatchTest {
    
    @testSetup
    private static void setup(){
        TestUtil.bypassValidation();
    	QuickBooks_Configurations__c qbConfig = new QuickBooks_Configurations__c();
		qbConfig.Consumer_Key__c = 'qyprdFawAAiD3SLud6d5RvREaVOoAn';
        qbConfig.End_Point_URL__c = 'https://sandbox-quickbooks.api.intuit.com/v3/company/';
        qbConfig.Consumer_Secret__c = 'q3JPBvXRxwRWldrpEQzXlByXs7joEglmCBhRPinr';
        qbConfig.OAuth_Token__c = 'qyprdAVMsASHRkSalO3JwbyPdnzistYmRRfJBFbAxL6AOlDj';
        qbConfig.OAuth_Token_Secret__c = 'TN3csfs1tTSX77SW5ysYkcVxJo1gIq8Lq3wusQKO';
        qbConfig.Company_Id__c = '123145730762509';
		qbConfig.Enable_QuickBooks__c = true;   
		insert qbConfig;
		TestUtil.setQuickBooksIFWConfigurations(qbConfig);
		insert new General_Configurations__c(Enable_QB_Accounting__c = true);
        Count_Session__c brandingLocationRec = new Count_Session__c(name__c = 'balveer', Count_Date_Time__c=date.today());
        insert brandingLocationRec;
        Count_Session_Line_Item__c CountSessionLineItem = new Count_Session_Line_Item__c(Count_Session__c = brandingLocationRec.id, Total_Cost_Adjustment__c = 123.9);
        insert CountSessionLineItem;
    }
    
    @isTest
    private static void testAccSync_CountSession_BatchMethods(){
    	Test.startTest();
        List<Count_Session__c> countSessionRec = new List<Count_Session__c>();
        List<Count_Session__c> CountSession = [select id, name__c, Status__c, Net_Adjustment_After_Finalize__c from Count_Session__c];
        CountSession[0].name__c = 'jay';
        CountSession[0].Status__c = 'Closed';
        countSessionRec.add(CountSession[0]);
        update countSessionRec;
        
    	Test.stopTest();
        
        List<Count_Session__c> result = [select id, Status__c, Net_Adjustment_After_Finalize__c from Count_Session__c];
        system.assertEquals(1, result.size());
        List<Count_Session_Line_Item__c> results = [select id, Count_Session__c from Count_Session_Line_Item__c];
        system.assertEquals(result[0].id, results[0].Count_Session__c);
    }
}
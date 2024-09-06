@isTest
private class AccSync_UnitConsignment_BatchTest {
    
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
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Consignment__c=true, Unit_Type__c = 'COU', Status__c = 'Active');
        insert insertCOU;
    }
    
    @isTest
    private static void testAccSync_UnitConsignment_BatchMethods(){
    	Test.startTest();
        List<Customer_Owned_Unit__c> updateCOU = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> couRec = [select id, Status__c, VIN_Number__c from Customer_Owned_Unit__c];
        couRec[0].Status__c = 'Transferred';
        couRec[0].VIN_Number__c = '1324356hn';
        couRec[0].Suggested_Price__c = 123;
        couRec[0].Agreed_Payout__c = 12;
        updateCOU.add(couRec[0]);
        update updateCOU;
    	Test.stopTest();
        List<Customer_Owned_Unit__c> result = [select id from Customer_Owned_Unit__c];
        system.assertEquals(1, result.size());

    }
}
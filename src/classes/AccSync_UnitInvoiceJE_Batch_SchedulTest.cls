@isTest
private class AccSync_UnitInvoiceJE_Batch_SchedulTest {
    
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
        Customer_Owned_Unit__c insertRefCOU = new Customer_Owned_Unit__c(Unit_Type__c= 'ORDU', Status__c = 'Received');
        insert insertRefCOU;
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'STOCK', Available_For_QB_Unit_Invoice_JE_Sync__c = true, Referenced_Unit__c = insertRefCOU.id);
        insert insertCOU;
    }
    
    @isTest
    private static void testAccSync_UnitInvoiceJE_Batch_SchedularMethods(){
    	Test.startTest();
        QBScriptUtil.syncJournalEntryForUnitInvoices(5,60,5);
    	Test.stopTest();
        List<Customer_Owned_Unit__c> result = [select id from Customer_Owned_Unit__c];
        system.assertEquals(2, result.size());

    }
}
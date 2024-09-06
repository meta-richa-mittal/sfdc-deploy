@isTest
private without sharing class IntegrityCheckForBRPCtrlTest {
    
	static testMethod void integrityCheckCtrlTest() {
        CO_Header__c coHeader = TestUtil.createCOHeader(true, null);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Active'); 
        coinvoiceHeader1.Available_For_BRP_Parts_Invoice_Sync__c = true;
        coinvoiceHeader1.Available_For_BRP_Repair_Order_Sync__c = true;
        coinvoiceHeader1.Available_For_BRP_RDR_Sync__c = true;
        insert coinvoiceHeader1;

        List<CO_Invoice_Header__c> coInvoiceHeaderList =  [SELECT Name, Available_For_BRP_Parts_Invoice_Sync__c,Available_For_BRP_RDR_Sync__c, Available_For_BRP_Repair_Order_Sync__c from CO_Invoice_Header__c where Available_For_BRP_Parts_Invoice_Sync__c = true OR Available_For_BRP_RDR_Sync__c = true OR Available_For_BRP_Repair_Order_Sync__c = true];
        Test.startTest();
        insert new BP_Configurations__c(Support_Email_Recipient__c = 'reena.singh@metacube.com');
        new IntegrityCheckForBRPCtrl().sendIntegrityCheckMailToSupportTeam();
        system.assertEquals(1, coInvoiceHeaderList.size());
        Test.stopTest();
    }  
}
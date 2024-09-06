@isTest
private class BRPBatchSchedulerTest {
    static String CRON_EXP = '0 0 0 * * ? *';	
    @TestSetup
    private static void setup(){
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForBRP();
        // insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
        // List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        // IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        insert customer;
        // TestUtil.createNameSpaceInGeneralConfig();
        // List <General_Configurations__c> config = [SELECT Id FROM General_Configurations__c LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
        // system.assertNotEquals(0, config.size());
        CO_Header__c coHeader = new CO_Header__c(Customer__c = Customer.id); 
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem;
        CO_Invoice_Item__c coInvoiceItem1 = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem1;
        CO_Line_Item__c coLineItem = new CO_Line_Item__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert coLineItem;
    }
    @isTest
    private static void testBRPBatchScheduler() {
        Test.startTest();
        BRPBatchScheduler BRPBatchSchedulerObj = new BRPBatchScheduler(null, 'Parts Invoice');
        String jobId = system.schedule('AccountingBatchSchedulerTest', CRON_EXP, BRPBatchSchedulerObj);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }
    
}
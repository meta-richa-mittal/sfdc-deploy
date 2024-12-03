/** 
* Author: Nidhi Sharma
* Since: May 08, 2023
* Name: ArchiveDeleteCOBatchSchedulerTest
* Description: Batch Test Apex class which archive/delete customer orders
**/
@isTest
private class ArchiveDeleteCOBatchSchedulerTest {
    
    @TestSetup
    static void makeData() {
        TestDataFactory.disableFLSChecks();

        Configurations__c config = Configurations__c.getOrgDefaults();
        config.Automatically_Archive_Quotes__c = config.Automatically_Delete_Quotes__c = true;
        config.Automatically_Archive_After_Days__c = config.Automatically_Delete_After_Days__c = 0;
        upsert config;

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');     
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);  
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true); 
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);

        CO_Header__c coHeader2 = TestUtil.createCOHeader(false, customer.Id);
        coHeader2.Is_Archived__c = true;
        coHeader2.Archived_Date_Time__c = system.today();
        insert coHeader2;
    }

    @isTest
    static void batchTest() {
        Test.startTest();
            String cronExpression = BPUtility.getCronExpForGivenTime(2);
            system.schedule('ArchiveDeleteCOBatchSchedulerTest', cronExpression, new ArchiveDeleteCOBatchScheduler());
        Test.stopTest();
    }
}
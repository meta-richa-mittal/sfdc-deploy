@isTest
global without sharing class QB_SyncUnitNITCBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
		List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
		customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
		headerList.add(header);
    }

    static testMethod void unitNITCPayLoad() {
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        BPScriptUtility.disbaleTrigger('COTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('DealItemTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        BPScriptUtility.disbaleTrigger('DealTrigger');
        BPScriptUtility.disbaleTrigger('COLineItemTrigger');
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);

        Account customer = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');
        customer.AccountingId__c = 'AccountingId__c';
        DMLUtility.updateSobjectList('Account', customer);

        Sales_Tax__c salesTax = TestDataFactory.createSalesTax('salesTaxName');
        salesTax.Accounting_Id__c ='Applicable_Tax__r.Accounting_Id__c';
        salesTax.Rate__c = 2.00;
        DMLUtility.updateSobjectList('Sales_Tax__c', salesTax);

        Account vendor = TestDataFactory.createVendor('vendorName');
        vendor.Vendor_AccountingId__c = '233';
        vendor.Purchase_Tax__c = salesTax.Id;
        DMLUtility.updateSobjectList('Account',vendor);
        CO_Header__c coHeader = TestDataFactory.createCOHeader(customer.Id);
        Category__c category = TestDataFactory.createCategory('categoryName');
        category.Type__c = 'Adjustment';
        category.Inventory_GL__c = 'Inventory_GL__c';
        category.COGS_GL__c = 'Inventory_GL__c';
        category.Income_GL__c = 'Inventory_GL__c';
        category.AccountingId__c = 'Category__r.AccountingId__c';
        DMLUtility.updateSobjectList('Category__c',category);
        Fee__c fee = TestDataFactory.createNewFee(true, category.Id,'code' , coHeader.Id, 'description', 5.00, true);

        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);

        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);

        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);

        Customer_Owned_Unit__c unitRec1 = TestDataFactory.createOrduStockUnit(make.Id, model.Id, subModel.Id, 'TES');

        Customer_Owned_Unit__c unitRec = TestDataFactory.createConnectedStockUnit(make.Id, model.Id, subModel.Id, 'TES',unitRec1.Id,vendor.Id);
        unitRec.NITC_Date_Claimed__c = System.today();
        unitRec.NITC_Claimed_Manually__c = true;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);

        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();

        String query = 'SELECT Available_For_QB_NITC_JE_Sync__c From Customer_Owned_Unit__c where Referenced_Unit__c != null ';
        Customer_Owned_Unit__c unitRecord = Database.query(query);
        System.assertEquals(unitRecord.Available_For_QB_NITC_JE_Sync__c, false);
    }

}
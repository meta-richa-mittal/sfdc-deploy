@isTest
private class ServiceJobWorksheetCtrlTest {
    @testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
        BPScriptManager.createDefaultUnitProductType();
    }
    static testMethod void getServiceWorkSheetDataTest() {
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.Bypass_FLS_Check__c = true;
        upsert bpConfig;

        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        customer.Email__c = null;
        customer.Work_Email__c = null;
        insert customer;
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, unitmake.Id, unitmodel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'Stock';
        customerOwnedUnit.Status__c = 'Sold';
        insert customerOwnedUnit;
        
        Transaction_Type__c transactionType =  TestUtil.createTransactionType(true, 'Customer', 'Customer');
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, customerOwnedUnit.Id, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        soHeaderDetailsObj.SOList[0].SOHeaderInfo.UnitId = customerOwnedUnit.Id;
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String jsonStr = System.Json.serialize(soHeaderDetailsObj.SOList[0].SOHeaderInfo);
        String soHeader1Json = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveSOHeaderInfo(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(jsonStr)));
        update new Service_Order_Header__c(Id=soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id, Transaction_Type__c = transactionType.Id);
        Test.startTest();
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        Pagereference pageRef = Page.ServiceJobWorkSheet;
        pageRef.getparameters().put('id', coHeader.Id);
        pageRef.getparameters().put('isPrintReview', 'true');
        if(businessProfileList.size() > 0) {
        	pageRef.getparameters().put('brandingLocationId', businessProfileList[0].Id);
        }
        pageRef.getparameters().put('SelectedSOIds', BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id));
        Test.setCurrentPage(pageRef);
        ServiceJobWorksheetCtrl obj = new ServiceJobWorksheetCtrl();
        Test.stopTest();
    }
}
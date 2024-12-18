/**
 * Author: Nidhi Sharma
 * updated: June 16, 2017
 * Name: VendorProductTriggerHelperTest
**/
@isTest
private class VendorProductTriggerHelperTest {
	@testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
    }
    static testMethod void updateProductTest() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        
        insert new List<SObject>{customer, vendor, testCategory};
        
        Product__c testProduct = TestUtil.createProduct(false, testCategory.Id, 'Test Product Code', vendor.Id);
        testProduct.Description__c = 'Test Desc';
        insert testProduct;
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'STOCK';
        customerOwnedUnit.Status__c = 'Available';
        insert customerOwnedUnit;
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert coHeader;
        CustomerOrderCtrl_V2.createDeal(BPUtility.getEncodedString(coHeader.Id));
        
        List<Deal__c> dealList = [Select id from Deal__c where CO_Header__c = :coHeader.Id];
        
        String dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(null),BPUtility.getEncodedString(customerOwnedUnit.Id),BPUtility.getEncodedString(dealList[0].Id)));
        DealWrapper dealWrapperObj = DealWrapper.parse(dealWrapperJSON);
        
        DealWrapper.OptionAndFeeInfo optionAndFeeRec1 = new DealWrapper.OptionAndFeeInfo(new Option_Fee__c());
        optionAndFeeRec1.DealItemId = dealWrapperObj.UnitList[0].DealItemObj.Id;
        optionAndFeeRec1.Qty = 1;
        optionAndFeeRec1.ProductId = testProduct.Id;
        optionAndFeeRec1.IsInstall = false; 
        optionAndFeeRec1.SalesTaxPercentage = 0;
        optionAndFeeRec1.Price = 0;
        Test.startTest();
        dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString(dealWrapperObj.UnitList[0].DealItemObj.Id),BPUtility.getEncodedString(System.JSON.serialize(optionAndFeeRec1))));
        String dealInfoObjJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateDealStatus(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString('In Progress')));
        
        DealWrapper.DealInfoWrapper dealInfoObj = (DealWrapper.DealInfoWrapper) System.JSON.deserialize(dealInfoObjJson, DealWrapper.DealInfoWrapper.class);
        
        dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createDealMerchAndServiceSetion(BPUtility.getEncodedString(dealList[0].Id), BPUtility.getEncodedString(coHeader.Id)));
        DealWrapper.DealFulfillmentSectionWrapper DealFulfillmentSectionObj = (DealWrapper.DealFulfillmentSectionWrapper) System.JSON.deserialize(dealWrapperJSON, DealWrapper.DealFulfillmentSectionWrapper.class);
        
        testProduct.Code__c = 'Updated Code';
        testProduct.Description__c = 'Updated Desc';
        update testProduct;
        Test.stopTest();
        updateProductTest_future(dealWrapperObj.UnitList[0].DealItemObj.Id, coHeader.Id);
    }
    
    @future
    private static void updateProductTest_future(String dealItemId, String coHeaderId) {
    	List<Option_Fee__c> optionAndFeeList = [Select Id, Item_Code__c, Item_Description__c from Option_Fee__c where Deal_Item__c =: dealItemId];
        Product__c testProduct = [SELECT Id, Code__c, Description__c FROM Product__c];
        system.assertEquals(testProduct.Code__c, optionAndFeeList[0].Item_Code__c);
        system.assertEquals(testProduct.Description__c, optionAndFeeList[0].Item_Description__c);
        List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c where Status__c = 'Active'];
        String coInvoiceItemJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemListOnly(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(coInvoiceItemJson, CustomerOrderWrapper.CheckoutWrapper.class);
        
        COService.finalizeOrder(BPUtility.getEncodedString(System.JSON.serialize(checkoutObj.InvoiceItemList)), BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('Customer'));
        String closedOrder = CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), null);
        CustomerOrderWrapper.COHeaderWrapper coHeaderDetails = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(closedOrder), CustomerOrderWrapper.COHeaderWrapper.class);
        System.assertEquals('Closed', coHeaderDetails.coHeaderRec.OrderStatus);
        
        testProduct.Code__c = 'Updated Code 2';
        testProduct.Description__c = 'Updated Desc 2';
        update testProduct;
        optionAndFeeList = [Select Id, Item_Code__c, Item_Description__c from Option_Fee__c where Deal_Item__c =: dealItemId];
        system.assertEquals('Updated Code', optionAndFeeList[0].Item_Code__c);
        system.assertEquals('Updated Desc', optionAndFeeList[0].Item_Description__c);
    }
}
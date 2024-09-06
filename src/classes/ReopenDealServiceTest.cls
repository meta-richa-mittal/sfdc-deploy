@isTest
public class ReopenDealServiceTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.bypassValidation();
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c testPart1 = TestUtil.createPart(true, 'Part11', vendor.Id, 'Test Part1', testCategory.Id);
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, '123456987');
        customerOwnedUnit.Unit_Type__c = 'Stock';
        customerOwnedUnit.Status__c = 'Available';
        insert customerOwnedUnit;
        
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert coHeader;
        
        Deal__c dealRec = new Deal__c(CO_Header__c = coHeader.Id, Status__c = Constants.QUOTATION, Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert dealRec;
		List<Deal__c> dealList = new List<Deal__c>{dealRec};
        
        String dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addUnitToDeal(BPUtility.getEncodedString(null),BPUtility.getEncodedString(customerOwnedUnit.Id),BPUtility.getEncodedString(dealList[0].Id)));
        DealWrapper dealWrapperObj = DealWrapper.parse(dealWrapperJSON);
        
        DealWrapper.OptionAndFeeInfo optionAndFeeRec1 = new DealWrapper.OptionAndFeeInfo(new Option_Fee__c());
        optionAndFeeRec1.DealItemId = dealWrapperObj.UnitList[0].DealItemObj.Id;
        optionAndFeeRec1.Qty = 2;
        optionAndFeeRec1.PartId = testPart1.Id;
        optionAndFeeRec1.IsInstall = false; 
        optionAndFeeRec1.SalesTaxPercentage = 0;
        optionAndFeeRec1.Price = 0;
		dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.saveOptionFeesLineItem(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString(dealWrapperObj.UnitList[0].DealItemObj.Id),BPUtility.getEncodedString(System.JSON.serialize(optionAndFeeRec1))));
        String dealInfoObjJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateDealStatus(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString('In Progress')));
        DealWrapper.DealInfoWrapper dealInfoObj = (DealWrapper.DealInfoWrapper) System.JSON.deserialize(dealInfoObjJson, DealWrapper.DealInfoWrapper.class);
        closedorderActionForDealCheckoutTestAsyncHandling(coHeader.Id, dealList[0].Id, customerOwnedUnit.Id);
    }
    
    @future
	private static void closedorderActionForDealCheckoutTestAsyncHandling(String coHeaderId, String dealId, String customerOwnedUnitId) {
        String dealWrapperJSON = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createDealMerchAndServiceSetion(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString(coHeaderId)));
        
        DealWrapper.DealFulfillmentSectionWrapper DealFulfillmentSectionObj = (DealWrapper.DealFulfillmentSectionWrapper) System.JSON.deserialize(dealWrapperJSON, DealWrapper.DealFulfillmentSectionWrapper.class);
		List<CO_Invoice_Item__c> COInvoiceItems = [select CO_Line_Item__c, Deal__c from CO_Invoice_Item__c];
        
        List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c where Status__c = 'Active'];
        
        String coInvoiceItemJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemListOnly(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(coInvoiceItemJson, CustomerOrderWrapper.CheckoutWrapper.class);

        List<String> invIdList = new List<String>{DealFulfillmentSectionObj.DealMerchandiseList[0].COLIList[0].CoLineItemId};
        CustomerOrderCtrl_V2.finalizeInvoice(BPUtility.getEncodedString(System.JSON.serialize(invIdList)), BPUtility.getEncodedString(coHeaderId));
		String closedInvoice = BPUtility.getDecodedString(COService.getCOHeaderDetailsByGridName(coHeaderId, null));	
    }
    
    @isTest
    private static void reopenDealQBTestNegative() {
		TestUtil.setQuickBooksConfigurations(false);
        closedorderActionForDealCheckoutTestAsync();
    }

    @isTest
    private static void reopenDealXeroTestNegative() {
        TestUtil.createIFWConfigForXero();
		TestUtil.enableXeroInCustomSetting();
        closedorderActionForDealCheckoutTestAsync();
	}
	
	@isTest
    private static void reopenDealQBTest() {
		TestUtil.setQuickBooksConfigurations(false);
        closedorderActionForDealCheckoutTestAsyncHandling();
    }

    @isTest
    private static void reopenDealXeroTest() {
        TestUtil.createIFWConfigForXero();
		TestUtil.enableXeroInCustomSetting();
        closedorderActionForDealCheckoutTestAsyncHandling();
    }
    
    @future
    private static void closedorderActionForDealCheckoutTestAsyncHandling() { 
        List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c where Status__c = 'Active'];
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
		List<COInvoiceItem> coInvoiceItemList = (List<COInvoiceItem>) System.JSON.deserialize(COInvoiceItemJSON, List<COInvoiceItem>.class);
        for(COInvoiceItem coInvoiceItemObj : coInvoiceItemList) {
            if(String.isNotBlank(coInvoiceItemObj.DealId)) {
                coInvoiceItemObj.isActive = true;
            }
        }
        
        List <Deal__C> dealList1 = [Select Status__c from Deal__c];
        List<CO_Header__c> coHeaderList = [select Id from CO_Header__c];

        String closedOrder = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString(System.JSON.serialize(coInvoiceItemList)), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString('Customer')));
        String  reopenDealServiceObj1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.validateDealReOpening(BPUtility.getEncodedString((dealList1[0].Id))));

        Boolean result = BPUtility.getDecodedString(CustomerOrderCtrl_V2.reOpenDeal(BPUtility.getEncodedString(dealList1[0].Id))).contains('success');
        System.assertEquals(true, result);        
	}
	
	@future
    private static void closedorderActionForDealCheckoutTestAsync() { 
        List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c where Status__c = 'Active'];
        String coInvoiceItemJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemListOnly(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(coInvoiceItemJson, CustomerOrderWrapper.CheckoutWrapper.class);
        
        for(COInvoiceItem_V2 coInvoiceItemObj: checkoutObj.InvoiceItemList) {
            if(coInvoiceItemObj.CheckoutItemType == 'Deal' && String.isNotBlank(coInvoiceItemObj.ItemId)) {
                coInvoiceItemObj.isActive = true;
            }
        }
        
		List <Deal__C> dealList1 = [Select Status__c, (select Customer_Owned_Unit__c from Deal_Items__r) from Deal__c];
		for(Deal_Item__c itemRec : dealList1[0].Deal_Items__r) {
			if(itemRec.Customer_Owned_Unit__c != null) {
				itemRec.Customer_Owned_Unit__c = null;
			}
		}
		if(dealList1[0].Deal_Items__r.size() > 0) {
			update dealList1[0].Deal_Items__r;
		}
        List<CO_Header__c> coHeaderList = [select Id from CO_Header__c];

        String closedOrder = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString(System.JSON.serialize(checkoutObj.InvoiceItemList)), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString('Customer')));
        String  reopenDealServiceObj1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.validateDealReOpening(BPUtility.getEncodedString((dealList1[0].Id))));

        Boolean result = CustomerOrderCtrl_V2.reOpenDeal(BPUtility.getEncodedString(dealList1[0].Id)).contains('success');
        System.assertEquals(false, result);        
    }
    
}
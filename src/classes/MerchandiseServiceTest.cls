@isTest
private without sharing class MerchandiseServiceTest {
    
    @TestSetup
    static void setup(){
        TestDataFactory.disableFLSChecks();
        BPScriptUtility.disbaleTrigger('COTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('DealItemTrigger');
        
        Account customer = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');
	  	customer.Xero_Vendor_Accounting_Id__c = 'Xero_Vendor_Accounting_Id__c';
        DMLUtility.updateSobjectList('Account', customer);

        CO_Header__c coHeader = TestDataFactory.createCOHeader(customer.Id);

        BPScriptUtility.disbaleTrigger('CustomerOwnedUnitTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        BPScriptUtility.disbaleTrigger('DealTrigger');
        BPScriptUtility.disbaleTrigger('KitLineItemtrigger');
        BPScriptUtility.disbaleTrigger('COLineItemTrigger');
        

        Category__c category = TestDataFactory.createCategory('categoryName');

        Fee__c fee = TestDataFactory.createNewFee(true, category.Id,'code' , coHeader.Id, 'description', 5.00, true);

        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);

        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);

        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);

        Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
        unitRec.New_Unit__c = True;
        unitRec.Stock_Id__c = 'Stock_Id__c';
        unitRec.Year__c = 2021;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);

        Deal__c deal = TestDataFactory.createDeal(coHeader.id,unitRec.Id);

        CO_Line_Item__c coli = TestDataFactory.createCoLineItem(coHeader.Id,1);
        coli.Closed_CO_Invoice_link__c = '';
        coli.Deal__c = deal.Id;
        coli.Fee__c = fee.Id;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coli);

        CO_Invoice_Header__c coInvoiceHeader = TestDataFactory.createCOInvoiceHeader(coHeader.id, 'Closed');

        Kit_Header__c kitHeader = TestDataFactory.createKitHeader(true, true, false, false, make.Id, model.Id); 

        Account vendor = TestDataFactory.createVendor('vendorName');

        Part__c part = TestDataFactory.createNewPart(vendor.Id, category.Id);
        part.Qty_In_Stock__c = 1;
        part.Part_Type__c = 'Merchandise';
        DMLUtility.updateSobjectList('Part__c', part);

        Kit_Header_Line_Item__c kHLineItem = TestDataFactory.createKitHeaderLineItem(kitHeader.Id);
        kHLineItem.Fee__c = fee.Id;
        kHLineItem.Qty_Needed__c = 2;
        kHLineItem.Part__c = part.Id;
        DMLUtility.updateSobjectList('Kit_Header_Line_Item__c', kHLineItem);

        CO_Invoice_Item__c coInvoiceItemRec = TestDataFactory.createCoInvoiceItem(category.Id, coInvoiceHeader.Id);
        coInvoiceItemRec.Deal__c = deal.Id;
        coInvoiceItemRec.Deal_Finance__c = null;
        coInvoiceItemRec.isActive__c = true;
        coInvoiceItemRec.Is_Invoiceable__c = true;
        DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvoiceItemRec);

        
    }

    @isTest
    private static void deleteCOLITest(){
        List<CO_Line_Item__c> coliList = [Select Id, Qty__c From CO_Line_Item__c];
        Test.startTest();
        String dealId = MerchandiseService.deleteCOLI(coliList[0].Id);
        List<CO_Line_Item__c> coliListone = [Select Id, Qty__c From CO_Line_Item__c];
        Test.stopTest();
        System.assertEquals(coliList.size()-1, coliListone.size());

    }

    @isTest
    private static void insertMerchKitAndRemoveCOKHLineItem(){
        Kit_Header__c kitHeader = [Select Id,Active__c from Kit_Header__c];
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        
        Test.startTest();
        //insertMerchKit test
        List<CO_Kit_Header__c> cokhRecList = [Select Id, CO_Header__c from CO_Kit_Header__c];
        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(kitHeader.Id, null);
        String ids = MerchandiseService.insertMerchKit(System.JSON.serialize(lineObj), coHeader.Id);
        List<CO_Kit_Header__c> cokhRecListOne = [Select Id, CO_Header__c from CO_Kit_Header__c];

        System.assertEquals(cokhRecList.size()+1, cokhRecListOne.size());

        //removeCOKHLineItem test
        CO_Kit_Header__c cokhRec = [Select Id, (Select Id from CO_Line_Items__r) from CO_Kit_Header__c];
        List<CO_Line_Item__c> coLineItemList= [Select Id from CO_Line_Item__c where CO_Kit_Header__c =: cokhRec.Id];

        System.assertEquals(1,coLineItemList.size());

        String id_one = MerchandiseService.removeCOKHItems(cokhRec.Id);
        List<CO_Line_Item__c> coNewLineItemList= [Select Id from CO_Line_Item__c where CO_Kit_Header__c =: cokhRec.Id];

        System.assertEquals(0,coNewLineItemList.size());
        Test.stopTest();

    }

    @isTest
    private static void splitCOKHItemtest(){

        Kit_Header__c kitHeader = [Select Id,Active__c from Kit_Header__c];
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        
        List<CO_Kit_Header__c> cokhRecList = [Select Id, CO_Header__c from CO_Kit_Header__c];

        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(kitHeader.Id, null);
        String ids = MerchandiseService.insertMerchKit(System.JSON.serialize(lineObj), coHeader.Id);
        List<CO_Kit_Header__c> cokhRecListOne = [Select Id, CO_Header__c from CO_Kit_Header__c];
        CO_Kit_Header__c cokhRec = [Select Id, (Select Id from CO_Line_Items__r) from CO_Kit_Header__c];
        
        Test.startTest();
        List<CO_Line_Item__c> coLineItemList= [Select Id from CO_Line_Item__c where CO_Kit_Header__c =: cokhRec.Id];

        System.assertEquals(1,coLineItemList.size());

        MerchandiseService.splitCOKHItem(cokhRec.Id, coHeader.Id);
        List<CO_Line_Item__c> coNewLineItemList= [Select Id from CO_Line_Item__c where CO_Kit_Header__c =: cokhRec.Id];

        System.assertEquals(0,coNewLineItemList.size());
        

        Test.stopTest();

    }

    @isTest
    private static void updateCOKHLineItemsRecalculationTest() {

        Kit_Header__c kitHeader = [Select Id,Active__c from Kit_Header__c];

        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        
        List<CO_Kit_Header__c> cokhRecList = [Select Id, CO_Header__c from CO_Kit_Header__c];

        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(kitHeader.Id, null);
        String ids = MerchandiseService.insertMerchKit(System.JSON.serialize(lineObj), coHeader.Id);
        
        List<CO_Kit_Header__c> cokhRecListOne = [Select Id, CO_Header__c from CO_Kit_Header__c];

        CO_Kit_Header__c cokhRec = [Select Id,Price__c,Tax_Amount__c, Kit_Header__r.Kit_Unique_Name__c, Service_Kit__c,Fixed_Price_Flag__c,Can_Split__c,Actual_Kit_Price__c,Deal__c,CO_Fixed_KitHeader__c, UUID__c, (Select Id from CO_Line_Items__r) from CO_Kit_Header__c];
        String cokhId = cokhRec.Id;
        String coLineItemQueryStr = 'SELECT ' + String.join(COLineItem.fieldsList(), ',') + ' from CO_Line_Item__c where CO_Kit_Header__c =: cokhId ';
        
        List<CO_Line_Item__c> coLineItemList =  Database.query(coLineItemQueryStr);
        CO_Line_Item__c coLineItemRec = Database.query(coLineItemQueryStr);
        
        
        Test.startTest();
        COHeaderWrapper.COKitHeader coKitHeaderObj = new COHeaderWrapper.COKitHeader(cokhRec, coLineItemList, false);
        COLineItem colineItemObj = new COLineItem(coLineItemRec);

        String cokhJSON = System.JSON.serialize(coKitHeaderObj);
        String cokliJson = System.JSON.serialize(colineItemObj);
        MerchandiseService.updateCOKHLineItemsRecalculation(cokhJSON, coHeader.Id, cokliJson);
        Test.stopTest();

    }

    @isTest
    private static void insertKitHeaderInDealMerchGridTest(){
        Price_Level__c priceLevel = TestDataFactory.createPriceLevel('priceLevelName');
        priceLevel.Default__c = true;
        update priceLevel;
        Kit_Header__c kitHeader = [Select Id,Active__c from Kit_Header__c];
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        Deal__c deal = [Select Id from Deal__c];
        deal.Invoice_Number__c = null;
        update deal;
        
        Test.startTest();
        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(kitHeader.Id, null);
        MerchandiseService.insertKitHeaderInDealMerchGrid(System.JSON.serialize(lineObj), deal.Id, coHeader.Id);
        List<CO_Line_Item__c> coLineItemList = [Select Id,Deal__c from CO_Line_Item__c where CO_Header__c =: coHeader.Id];
        System.assertEquals(deal.Id,coLineItemList[0].Deal__c);
        Test.stopTest();
    }

    @isTest
    private static void getOutOfStockPartsInKitTest(){
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        Kit_Header__c kitHeader = [Select Id,Active__c from Kit_Header__c];
        Integer count = 0;
        List<Kit_Header_Line_Item__c> khliRecList = SOQLUtil.getKHLineItemRec(new Map<String, String>{'Kit_Header__c' => kitHeader.Id});
		for(Kit_Header_Line_Item__c khliRec : khliRecList) {
			if(khliRec.Part__r.AvailableParts__c < khliRec.Qty_Needed__c) {
				count += 1;
			}
		}

        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(kitHeader.Id, null);
        String ids = MerchandiseService.insertMerchKit(System.JSON.serialize(lineObj), coHeader.Id);
        CO_Kit_Header__c cokhRec = [Select Id,Price__c,Tax_Amount__c, Kit_Header__r.Kit_Unique_Name__c, Service_Kit__c,Fixed_Price_Flag__c,Can_Split__c,Actual_Kit_Price__c,Deal__c,CO_Fixed_KitHeader__c, UUID__c from CO_Kit_Header__c];
        String cokhId = cokhRec.Id;
        String coLineItemQueryStr = 'SELECT ' + String.join(COLineItem.fieldsList(), ',') + ' from CO_Line_Item__c where CO_Kit_Header__c =: cokhId ';
        
        List<CO_Line_Item__c> coLineItemList =  Database.query(coLineItemQueryStr);
        
        COHeaderWrapper.COKitHeader coKitHeaderObj = new COHeaderWrapper.COKitHeader(cokhRec, coLineItemList, false);
        String kitHeaderJSON = System.JSON.serialize(coKitHeaderObj);
        MerchandiseService.oversoldKit(kitHeaderJSON);

        Test.startTest();
        System.assertEquals(count, MerchandiseService.getOutOfStockPartsInKit(kitHeader.Id).size());
        Test.stopTest();
    }

    @isTest
    private static void getMerchAndDealMerchProfitabilityTest(){
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];

        Test.startTest();
        Map<String, ProfitabilityWrapper.SectionProfitabilityWrapper> newMap = MerchandiseService.getMerchAndDealMerchProfitability(coHeader.Id);
        System.assertEquals(1, newMap.size());
        Test.stopTest();
    }

    @isTest
    private static void populateMerchIndividualsCostTotalsAfterFinalizeTest(){
        CO_Header__c coHeader = [Select Id, Customer__c from CO_Header__c];
        CO_Invoice_Header__c coInvoiceHeader = [Select Id from CO_Invoice_Header__c];
        CO_Line_Item__c coli = [Select Id From CO_Line_Item__c where CO_Header__c =: coHeader.Id];
        coli.Invoice_Number__c = coInvoiceHeader.Id;
        coli.Service_Order_Line_Item__c = null;
        update coli;

        Test.startTest();
        MerchandiseService.populateMerchIndividualsCostTotalsAfterFinalize(coInvoiceHeader.Id);
        List<CO_Line_Item__c> coliList = [SELECT Fee__c, Fee_Cost__c FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND Invoice_Number__c =: coInvoiceHeader.Id];
        System.assertEquals(4.00, coliList[0].Fee_Cost__c);
        Test.stopTest();
    }

    @isTest
    private static void updatePartsAndAccessoriesSettingTest(){
        CustomerOrderWrapper.COHeader obj = new CustomerOrderWrapper.COHeader(2);
        String query = 'Select ' + String.join(obj.fieldsList(), ',') + ' from CO_Header__c';
        CO_Header__c coHeader = Database.query(query);

        Test.startTest();
        CustomerOrderWrapper.COHeader coHeaderWrapper = new CustomerOrderWrapper.COHeader(coHeader);
        String coHeaderJson = System.JSON.serialize(coHeaderWrapper);
        String result = MerchandiseService.updatePartsAndAccessoriesSetting(coHeaderJson);
        System.assertEquals('Success', result);
        Test.stopTest();
    }
}

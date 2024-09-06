/**
 * Author: Durga Singh
 * updated: Nov 6, 2015
 * Name: ScenarioBasedTests
 * Description: It includes scenario based test cases.
**/
@isTest
private class COLineItemTriggerHelperTest {
	
    static testMethod void defaultPriceLevelCalculation() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
    	Applicable_Taxes__c appTax = TestUtil.createApplicableTax(true, defaultSalesTax.Id, salesTaxItem.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', defaultPriceLevel.Id, null);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 50);
        
        Test.startTest();
        insert coLineItem;
        Test.stopTest();
        
        List<CO_Line_Item__c> coLineItemList = [select Retail__c, Price__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Retail__c, 55);
        system.assertEquals(coLineItemList[0].Price__c, 55);
    }
    
    static testMethod void priceLevelCalculation() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	Price_Level__c priceLevel = TestUtil.createPriceLevel(true, 'Test Price Level', 'MSRP', -10 , false, true);
    	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
    	Applicable_Taxes__c appTax = TestUtil.createApplicableTax(true, defaultSalesTax.Id, salesTaxItem.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', priceLevel.Id, null);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Sale_Price__c = 30;
        update part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 50);
        
        Test.startTest();
        insert coLineItem;
        Test.stopTest();
        
        List<CO_Line_Item__c> coLineItemList = [select Retail__c, Price__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Retail__c, 45);
        system.assertEquals(coLineItemList[0].Price__c, 30);
    }
    
    static testMethod void priceLevelCalculation1() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	Price_Level__c priceLevel = TestUtil.createPriceLevel(true, 'Test Price Level', 'Average Cost', -10 , false, true);
    	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
    	Applicable_Taxes__c appTax = TestUtil.createApplicableTax(true, defaultSalesTax.Id, salesTaxItem.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', priceLevel.Id, null);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 50);
        
        Test.startTest();
        insert coLineItem;
        Test.stopTest();
        
        List<CO_Line_Item__c> coLineItemList = [select Retail__c, Price__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Retail__c, 18);
        system.assertEquals(coLineItemList[0].Price__c, 18);
    }
    
    static testMethod void defaultSalesTaxCalculation() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
    	Applicable_Taxes__c appTax = TestUtil.createApplicableTax(true, defaultSalesTax.Id, salesTaxItem.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', null, null);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Applicable_Tax__c = defaultSalesTax.Id;
        insert part;
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 50);
        Test.startTest();
        insert coLineItem;
        Test.stopTest();
        
        List<CO_Line_Item__c> coLineItemList = [select Tax__c From CO_Line_Item__c where Id = :coLineItem.Id];
        //system.assert(false, coLineItemList);
        system.assertEquals(coLineItemList[0].Tax__c, 8);
    }
   
    static testMethod void salesTaxCalculation() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax1', true, true, true);
    	Sales_Tax__c salesTax = TestUtil.createSalesTax(true, 'Test Sales Tax2', true, false, true);
    	
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Item1', 10.0, 'Testing ', true, testCategory.Id);
    	Sales_Tax_Item__c salesTaxItem2 = TestUtil.createSalesTaxItem(true, 'Test Item2', 5.0, 'Testing ', true, testCategory.Id, false);
    	Applicable_Taxes__c appTax1 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem1.Id);
    	Applicable_Taxes__c appTax2 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem2.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', null, salesTax.Id);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Applicable_Tax__c = SalesTax.Id;
        insert part;
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 50);
        COLineItemTriggerHelper.isTriggerExecute = false;
        Test.startTest();
        update coLineItem;
        system.debug(+ coLineItem);
        Test.stopTest();
        
        //List<CO_Line_Item__c> coLineItemList = [select Tax__c From CO_Line_Item__c where Id = :coLineItem.Id];
        //system.assertEquals(coLineItemList[0].Tax__c, 10);
        
        
        
        //COLineItemTriggerHelper.isTriggerExecute = false;
        //system.assert(false, coLineItem);
        List<CO_Line_Item__c> coLineItemList = [select Tax__c From CO_Line_Item__c where Id = :coLineItem.Id];
        //system.debug('$$$$$$ ' + coLineItemList);
        system.assertEquals(coLineItemList[0].Tax__c, 15);
    }
    
    static testMethod void qtyCommittedLogicTest() {
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax1', true, true, true);
    	Sales_Tax__c salesTax = TestUtil.createSalesTax(true, 'Test Sales Tax2', true, false, true);
    	
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Item1', 10.0, 'Testing ', true, testCategory.Id);
    	Sales_Tax_Item__c salesTaxItem2 = TestUtil.createSalesTaxItem(true, 'Test Item2', 5.0, 'Testing ', true, testCategory.Id, false);
    	Applicable_Taxes__c appTax1 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem1.Id);
    	Applicable_Taxes__c appTax2 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem2.Id);
    	
    	Account customer = TestUtil.createCustomer(true, 'Test Cust', 'a@b.c', 'Jaipur', '1800111265', null, salesTax.Id);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 50);
        
        Test.startTest();
        insert coLineItem;
        Test.stopTest();
        
        List<CO_Line_Item__c> coLineItemList = [select Qty_Committed__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Qty_Committed__c, 50);
        
        List<Part__c> partList = [select Qty_In_Stock__c, Qty_Committed__c from Part__c where Id =: part.Id ];
        system.assertEquals(partList[0].Qty_Committed__c, 50);
        system.assertEquals(partList[0].Qty_In_Stock__c, 100);
        
        COLineItemTriggerHelper.isTriggerExecute = false;
        coLineItem.Qty__c = 120;
        update coLineItem;
        
        
        /*coLineItemList = [select Qty_Committed__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Qty_Committed__c, 100);
        
        partList = [select Qty_In_Stock__c, Qty_Committed__c from Part__c where Id =: part.Id ];
        system.assertEquals(partList[0].Qty_Committed__c, 100);
        
        COLineItemTriggerHelper.isTriggerExecute = false;
        coLineItem.Qty__c = 130;
        try{
        	update coLineItem;
        } catch(Exception e) {
        	system.assertEquals(BlackPurlException.getErrorMessage(e.getMessage(), '') , 'Validation Error :  Quantity Out of Stock');
        }
        
        COLineItemTriggerHelper.isTriggerExecute = false;
        coLineItem.Qty__c = 80;
        update coLineItem;
        
        coLineItemList = [select Qty_Committed__c From CO_Line_Item__c where Id = :coLineItem.Id];
        system.assertEquals(coLineItemList[0].Qty_Committed__c, 80);
        
        partList = [select Qty_In_Stock__c, Qty_Committed__c from Part__c where Id =: part.Id ];
        system.assertEquals(partList[0].Qty_Committed__c, 80);
        system.assertEquals(partList[0].Qty_In_Stock__c, 100);*/
    }

    
    static testMethod void createLineItemEnhancedTest() {
        
        TestUtil.createEnhancedTaxSettingInGeneralConfig();

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Category__c defaultTestCategory = TestUtil.createCategory(true, 'Tax Default1');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c standardSalestax = TestUtil.createMixedTaxForEnhancedTaxCalculation();
        
        Part__c testPart = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 20, 40, 50, 100, 200);
        testPart.Taxable__c = true;
        testPart.Applicable_Tax__c = standardSalestax.Id;
        insert testPart;
        
        Fee__c fee = TestUtil.createFee(false, true, testCategory.Id, 'FeeCode', null, 'Description', 100, true);
        fee.Taxable__c = true;
        fee.Applicable_Tax__c = standardSalestax.Id;
        insert fee;

        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, testPart.Id, 20);
        
        CO_Line_Item__c coLineItem1 = new CO_Line_Item__c();
        coLineItem1.CO_Header__c = coHeader.Id;
        coLineItem1.Fee__c = fee.Id;
        coLineItem1.Qty__c = 20;
        insert coLineItem1;
        
        Test.startTest();

        List<CO_Line_Item__c> coLineItems = [SELECT Id, Part__c, Fee__c, Price__c, (SELECT Enhanced_Tax_Amount__c,Sales_Tax_Item__r.Name__c,Tax_Rate__c FROM Individual_Taxes__r) 
            FROM CO_Line_Item__c where CO_Header__c =: coHeader.Id];
        System.assertEquals(2, coLineItems.size());
        for (CO_Line_Item__c coLineItemsRec : coLineItems) {
            for (Individual_Tax__c individualTaxRec : coLineItemsRec.Individual_Taxes__r) {
                if (coLineItemsRec.Part__c != null) {
                    system.assertEquals (55.000, coLineItemsRec.Price__c);
                    if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
                        system.assertEquals(33.00, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
                        system.assertEquals(27.50, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
                        system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    } else {
                        system.assert(false, 'Incorrect tax item');
                    }
                } else if (coLineItemsRec.Fee__c != null) {
                    system.assertEquals (100, coLineItemsRec.Price__c);
                    if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
                        system.assertEquals(60, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
                        system.assertEquals(50.00, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
                        system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    } else {
                        system.assert(false, 'Incorrect tax item');
                    }
                }
            }  
        }
        Test.stopTest();
    }

    static testMethod void createKitLineItemEnhancedTest() {
        TestUtil.createEnhancedTaxSettingInGeneralConfig();

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Category__c defaultTestCategory = TestUtil.createCategory(true, 'Tax Default1');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c standardSalestax = TestUtil.createMixedTaxForEnhancedTaxCalculation();
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c testPart = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 20, 40, 50, 100, 200);
        testPart.Taxable__c = true;
        testPart.Applicable_Tax__c = standardSalestax.Id;
        insert testPart;
        
        Fee__c fee = TestUtil.createFee(false, true, testCategory.Id, 'FeeCode', null, 'Description', 100, true);
        fee.Taxable__c = true;
        fee.Applicable_Tax__c = standardSalestax.Id;
        insert fee;

        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, false, false, unitMake.Id, unitModel.Id);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 5.0, null, testPart.Id, 3, 5.0);
       
        Kit_Header_Line_Item__c KitHeaderLineItem1 = new Kit_Header_Line_Item__c();
        KitHeaderLineItem1.Fixed_Price__c = true;
        KitHeaderLineItem1.Kit_Header__c = KitHeader.Id;
        KitHeaderLineItem1.Kit_Price__c = 5.0;
        KitHeaderLineItem1.Fee__c = fee.Id;
        KitHeaderLineItem1.Qty_Needed__c = 1;
        insert KitHeaderLineItem1;

        String insertKitHeaderInMerchGridDetails = BPUtility.getDecodedString(CustomerOrderCtrl.insertKitHeaderInMerchGrid( BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(coHeader.Id)));
        Test.startTest();
        KitHeaderLineItem1.Qty_Needed__c = 2;
        update KitHeaderLineItem1;
        
        List<CO_Line_Item__c> coLineItems = [SELECT Id, Part__c, Fee__c, Price__c, (SELECT Enhanced_Tax_Amount__c,Sales_Tax_Item__r.Name__c,Tax_Rate__c FROM Individual_Taxes__r) 
        FROM CO_Line_Item__c where CO_Header__c =: coHeader.Id];
    
        List<CO_Kit_Header__c> coHeaderList  = [Select Id from CO_Kit_Header__c where CO_Header__c =: coHeader.Id];
        String cokhJSON = '{"TaxAmount":38.85,"Price":210,"ItemDescription":"Test Profit kit - test","IsServiceKit":false,"IsFixedPrice":false,"IsFixedKitHeaderCO":false,"Id":"'+coHeaderList[0].Id+'","hasChildren":true,"COLIList":[{"VOHeaderList":[],"Tax":13,"SubTotal":120,"StockCommitedCpy":0,"Status":"Ready","Retail":0,"QtyOrder":1,"QtyCpy":1,"QtyCommitted":0,"Qty":1,"Price":"12","OversoldQty":0,"ItemDescription":"Fee","ItemCode":"Active","Item":"Active - Fee","IsSupersededPart":false,"isSpecialOrder":false,"IsFixedPriceForCO":true,"IsFixedPrice":false,"IsBRPPart":false,"Invoice":"","FulfillDate":"2020-07-16","FeeId":"'+fee.Id+'","ExpectedDeliveryDate":"07/16/2020","EntityType":"Fee","CoLineItemId":"'+coLineItems[0].Id+'","ActualRetailPrice":0,"ActualKitPrice":15},{"VOHeaderList":[],"VendorId":"'+vendor.Id+'","Tax":13,"SubTotal":90,"StockCommitedCpy":1,"Status":"In Stock","Retail":100,"QtyOrder":0,"QtyCpy":1,"QtyCommitted":1,"Qty":1,"Price":90,"PartId":"'+testPart.Id+'","OversoldQty":0,"NonInventoryPart":false,"ItemDescription":"rounding","ItemCode":"Test rounding","Item":"Test rounding - rounding","IsSupersededPart":false,"isSpecialOrder":false,"IsNonInventoryPart":false,"IsFixedPriceForCO":true,"IsFixedPrice":false,"IsBRPPart":false,"Invoice":"","FulfillDate":"2020-07-16","ExpectedDeliveryDate":"07/16/2020","EntityType":"Part","CoLineItemId":"'+coLineItems[1].Id+'","AvaliablePartsQty":8,"ActualRetailPrice":105,"ActualKitPrice":110,"ActualAvailableParts":9}],"CanItSplit":true,"ActualKitPrice":115}';
        String cokliJson = '{"VOHeaderList":[],"Tax":13,"SubTotal":120,"StockCommitedCpy":0,"Status":"Ready","Retail":0,"QtyOrder":1,"QtyCpy":1,"QtyCommitted":0,"Qty":1,"Price":"12","OversoldQty":0,"ItemDescription":"Fee","ItemCode":"Active","Item":"Active - Fee","IsSupersededPart":false,"isSpecialOrder":false,"IsFixedPriceForCO":true,"IsFixedPrice":false,"IsBRPPart":false,"Invoice":"","FulfillDate":"2020-07-16","FeeId":"'+fee.Id+'","ExpectedDeliveryDate":"07/16/2020","EntityType":"Fee","CoLineItemId":"'+coLineItems[0].Id+'","ActualRetailPrice":0,"ActualKitPrice":15}';  
        MerchandiseService.updateCOKHLineItemsRecalculation(cokhJSON, coHeader.Id, cokliJson);         
       
        System.assertEquals(2, coLineItems.size());
        for (CO_Line_Item__c coLineItemsRec : coLineItems) {
            for (Individual_Tax__c individualTaxRec : coLineItemsRec.Individual_Taxes__r) {
                if (coLineItemsRec.Part__c != null) {
                    system.assertEquals (55.000, coLineItemsRec.Price__c);
                    if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
                        system.assertEquals(4.95, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
                        system.assertEquals(4.13, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
                        system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }else {
                        system.assert(false, 'Incorrect tax item');
                    }
                }else if (coLineItemsRec.Fee__c != null) {
                    system.assertEquals (5.000, coLineItemsRec.Price__c);
                    if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
                        system.assertEquals(0.15, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
                        system.assertEquals(0.13, individualTaxRec.Enhanced_Tax_Amount__c);
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
                        system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }else {
                        system.assert(false, 'Incorrect tax item');
                    }
                }
            }  
        }
        Test.stopTest();
    }
}
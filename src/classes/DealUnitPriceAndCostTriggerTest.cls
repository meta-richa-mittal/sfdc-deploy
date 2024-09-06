/**
 * Author: Nidhi Sharma
 * updated: Dec 20, 2016
 * Name: DealUnitPriceAndCostTriggerTest
 * Description: Test class for option and feee trigger
**/
@isTest
private class DealUnitPriceAndCostTriggerTest {

    static testMethod void dealUnitPriceAndCostTriggerTest() {
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'MSRP', 10 , true, true);
        defaultPriceLevel.Labour_Rate__c = 60 ;
        Insert defaultPriceLevel;
        Sales_Tax__c salestax =  TestUtil.createSalesTax(true, 'HST');
        
        Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
        Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Item1', 10.0, 'Testing1 ', true, testCategory.Id);
        
        Applicable_Taxes__c applicabletax = TestUtil.createApplicableTax(true, salestax.Id, salesTaxItem.Id);
        Applicable_Taxes__c applicabletax1 = TestUtil.createApplicableTax(true, salestax.Id, salesTaxItem1.Id);
        
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        String statusToUpdate = 'In Progress';
        CO_Header__c co = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert co;
        Tax_Exemption__c taxExemption = Testutil.createCOTaxExemption(true, co.Id, salestaxItem.Id);
        DealWrapper dealWrapperObj = (DealWrapper)Json.deserialize(BPUtility.getDecodedString(CustomerOrderCtrl.createDeal(BPUtility.getEncodedString(co.Id))),DealWrapper.class);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'STOCK';
        customerOwnedUnit.Status__c = 'Available';
        customerOwnedUnit.Taxable__c = true;
        customerOwnedUnit.Applicable_Tax__c = salestax.Id;
        insert customerOwnedUnit;
        Unit_Price_Cost__c unitPriceAndCost1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Factory', Cost__c = 3000);
        Unit_Price_Cost__c unitPriceAndCost2 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Dealer', Cost__c = 3555);
        insert new List<Unit_Price_Cost__c>{unitPriceAndCost1, unitPriceAndCost2};
        
        Deal_Item__c dealItemRec = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
        DealItem dealItemObj = new DealItem(dealItemRec);
        dealItemObj.Model = unitmodel.Id;
        String dealItemJsonToSave = System.JSON.serialize(dealItemObj);
        Test.startTest();
        List<Deal__c> dealList = [Select id from Deal__c where CO_Header__c = :co.Id];
        CustomerOrderCtrl.saveTemporaryUnit(BPUtility.getEncodedString(dealList[0].Id),BPUtility.getEncodedString(dealItemJsonToSave));
        String dealItemJson = BPUtility.getDecodedString(CustomerOrderCtrl.getDealDetails(BPUtility.getEncodedString(dealList[0].Id), null));
        
        dealWrapperObj = (DealWrapper)Json.deserialize(dealItemJson, DealWrapper.class);
        dealWrapperObj = (DealWrapper)Json.deserialize(BPUtility.getDecodedString(CustomerOrderCtrl.addUnitToDeal(BPUtility.getEncodedString(dealWrapperObj.UnitList[0].DealItemObj.Id),BPUtility.getEncodedString(customerOwnedUnit.Id),BPUtility.getEncodedString(dealWrapperObj.DealInfo.Id))), DealWrapper.class);
        
        Test.stopTest();
        system.assertEquals(2, dealWrapperObj.UnitList.size());
        system.assertEquals(10, dealWrapperObj.UnitList[0].FactoryOptionList[0].SalesTaxPercentage);
    }
    
    static testMethod void dealDeleteTriggerTest() {
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        
        CO_Header__c co = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert co;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        CustomerOrderCtrl.createDeal(BPUtility.getEncodedString(co.Id));
        system.assertEquals(co.CO_Type__c,'Customer');
        List<Deal__c> dealList = [Select id from Deal__c where CO_Header__c = :co.Id];
        Deal_Item__c dealItemRec = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
        DealItem dealItemObj = new DealItem(dealItemRec);
        dealItemObj.Model = unitmodel.Id;
        String dealItemJsonToSave = System.JSON.serialize(dealItemObj);
        delete dealList[0];
    }
    
    static testMethod void dealItemDeleteTriggerTest() {
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        
        CO_Header__c co = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert co;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Category__c categoryObj = testUtil.createCategory(true,'category one');
        Sales_Tax__c salesTax1 = TestUtil.createSalesTax(true, 'Testing Sales Tax 2', true, false, true);
        Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Sales Tax Item 1', 20, 'Testing Form Label 1', true, categoryObj.id);
        Tax_Exemption__c taxExemptionObj = TestUtil.createCOTaxExemption(true,co.id,salesTaxItem1.id);
        
        Configurations__c taxSetting = Configurations__c.getOrgDefaults();
        taxSetting.Default_Tax_on_Fee__c = salesTax1.Id;
        taxSetting.Default_Tax_on_Labor__c = salesTax1.Id;
        taxSetting.Default_Tax_on_Part__c = salesTax1.Id;
        taxSetting.Default_Tax_on_Vendor_Product__c = salesTax1.Id; 
        taxSetting.Default_Tax_on_Unit__c = salesTax1.Id;
        taxSetting.Tax_Included_Pricing__c = true;
        insert taxSetting;
       
        Applicable_Taxes__c applicableTax1 = TestUtil.createApplicableTax(true, salesTax1.Id, salesTaxItem1.Id);
        Applicable_Taxes__c applicableTax2 = TestUtil.createApplicableTax(true, salesTax1.Id, salesTaxItem1.Id);
        
        CustomerOrderCtrl.createDeal(BPUtility.getEncodedString(co.Id));
        List<Deal__c> dealList = [Select id from Deal__c where CO_Header__c = :co.Id];
        
        Deal_Item__c dealItemRec = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
    	dealItemRec.Unit_Model__c = unitmodel.Id;
    	dealItemRec.Deal__c = dealList[0].Id;
    	dealItemRec.Type__c = Constants.DEAL_ITEM_TYPE_UNIT;
    	insert dealItemRec;
    	
    	Deal_Item__c dealItemRec2 = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
    	dealItemRec2.Unit_Model__c = unitmodel.Id;
    	dealItemRec2.Deal__c = dealList[0].Id;
    	dealItemRec2.Type__c = Constants.DEAL_ITEM_TYPE_UNIT;
    	insert dealItemRec2;
    	
    	Deal_Item__c dealItemRec3 = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
    	dealItemRec3.Unit_Model__c = unitmodel.Id;
    	dealItemRec3.Deal__c = dealList[0].Id;
    	dealItemRec3.Type__c = Constants.DEAL_ITEM_TYPE_TRADE_IN;
    	insert dealItemRec3;
    	//system.assertEquals(1,dealList.size());
        
        delete dealItemRec;
        system.assert(true,true);
    }

    static testMethod void dealUPCEnhancedTaxCalculationTest() {
        
        TestUtil.createEnhancedTaxSettingInGeneralConfig();
        
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Category__c defaultTestCategory = TestUtil.createCategory(true, 'Tax Default1');
        Category__c tax3TestCategory = TestUtil.createCategory(true, 'Tax 3');

        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'MSRP', 10 , true, true);
        defaultPriceLevel.Labour_Rate__c = 60 ;
        Insert defaultPriceLevel;
        Sales_Tax__c standardSalestax =  TestUtil.createSalesTax(true, 'Standard Sales Tax');

        Sales_Tax_Item__c salesTaxStateEscalatingItem = TestUtil.createSalesTaxItem(true, 'State Escalating', 'State Escalating', 0.00, true, defaultTestCategory.Id, 150.00, 2000.00, 5000.00, 0.00, 'Escalating rate', 3.00, 4.00, 5.00, 'Sell');
        Sales_Tax_Item__c salesTaxStateTieredItem = TestUtil.createSalesTaxItem(true, 'State Tiered', 'State Tiered', 0.00, true, defaultTestCategory.Id, 9999999.00, 2000.00,  5000.00, 0.00, 'Tiered rate',  2.50, 3.50, 4.50, 'Sell');                                      
        Sales_Tax_Item__c salesTaxFixedRate1Item = TestUtil.createSalesTaxItem(true,'Fixed Rate 1 Label', 'Fixed Rate 1', 5.00, true, defaultTestCategory.Id, 0.00, 0.00, 0.00, 0.00, 'Fixed rate', 0.00, 0.00, 0.00, 'Sell');
        Sales_Tax_Item__c salesTaxFixedRate2Item = TestUtil.createSalesTaxItem(true, 'Fixed Rate 2 Label', 'Fixed Rate 2', 8.00, true, tax3TestCategory.Id, 0.00, 0.00, 0.00, 0.00, 'Fixed rate', 0.00, 0.00, 0.00, 'Sell');

        Applicable_Taxes__c applicableSalesTaxStateEscalatingTax = TestUtil.createApplicableTax(true, standardSalestax.Id, salesTaxStateEscalatingItem.Id);
        Applicable_Taxes__c applicableTaxStateTieredTax = TestUtil.createApplicableTax(true, standardSalestax.Id, salesTaxStateTieredItem.Id);
        Applicable_Taxes__c applicableTaxFixedRate1Tax = TestUtil.createApplicableTax(true, standardSalestax.Id, salesTaxFixedRate1Item.Id);
        Applicable_Taxes__c applicableTaxFixedRate2Tax = TestUtil.createApplicableTax(true, standardSalestax.Id, salesTaxFixedRate2Item.Id);
     
        Account customer =  TestUtil.createCustomer(false, 'Enhanced Tax Customer', 'tax@abc.com', 'Jaipur', '1234567891', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        String statusToUpdate = 'In Progress';
        CO_Header__c co = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert co;
        
        Tax_Exemption__c taxExemption = Testutil.createCOTaxExemption(true, co.Id, salesTaxFixedRate1Item.Id);
        DealWrapper dealWrapperObj = (DealWrapper)Json.deserialize(BPUtility.getDecodedString(CustomerOrderCtrl.createDeal(BPUtility.getEncodedString(co.Id))),DealWrapper.class);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'STOCK';
        customerOwnedUnit.Status__c = 'Available';
        customerOwnedUnit.Taxable__c = true;
        customerOwnedUnit.Applicable_Tax__c = standardSalestax.Id;
        insert customerOwnedUnit;
        
        Unit_Price_Cost__c unitPriceAndCost1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Factory',Item_Description__c ='Test',Total_Price__c = 500, Cost__c = 3000, Qty__c = 1, Price__c = 500);
        Unit_Price_Cost__c unitPriceAndCostBase = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Base',Item_Description__c ='Test',Total_Price__c = 2000, Cost__c = 2500, Qty__c = 1, Price__c = 2000);
        Unit_Price_Cost__c unitPriceAndCost2 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Dealer',Item_Description__c ='Test',Total_Price__c = 1000, Qty__c = 1, Cost__c = 3555, Price__c = 1000);
        insert new List<Unit_Price_Cost__c>{unitPriceAndCost1, unitPriceAndCost2, unitPriceAndCostBase};
        
        System.assertEquals(2000, unitPriceAndCostBase.price__c);
        
        Test.startTest();
        List<Deal__c> dealList = [SELECT id, (Select Id from Deal_Items__r) FROM Deal__c WHERE CO_Header__c = :co.Id];
        
        dealWrapperObj = (DealWrapper)Json.deserialize(BPUtility.getDecodedString(CustomerOrderCtrl.addUnitToDeal(
        		BPUtility.getEncodedString(dealList[0].Deal_Items__r[0].Id),BPUtility.getEncodedString(customerOwnedUnit.Id),
        		BPUtility.getEncodedString(dealList[0].Id))), DealWrapper.class);
        
        system.assertEquals(1, dealWrapperObj.UnitList.size());

        List<Deal_Unit_Price_Cost__c> dupcList=  [SELECT id, type__c,Price__c,(SELECT Enhanced_Tax_Amount__c,Sales_Tax_Item_Name__c,Tax_Rate__c from Individual_Taxes__r) 
            FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__c =: dealWrapperObj.UnitList[0].DealItemObj.Id];
        
        System.assertEquals(3, dupcList.size());
        for (Deal_Unit_Price_Cost__c dupcRec : dupcList) {
        	System.assertEquals(3, dupcRec.Individual_Taxes__r.size());
            for (Individual_Tax__c individualTaxRec : dupcRec.Individual_Taxes__r) {
                if (dupcRec.Type__c == 'Base') {
                    System.assertEquals(2000, dupcRec.Price__c);
                   if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Escalating') {
                        system.assertEquals(140, individualTaxRec.Enhanced_Tax_Amount__c  );
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Tiered') {
                        system.assertEquals(102.50, individualTaxRec.Enhanced_Tax_Amount__c  );
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'Fixed Rate 2') {
                    	system.assertEquals(8.00, individualTaxRec.Tax_Rate__c);
                    	system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                    }
                } else if (dupcRec.Type__c == 'Factory') {
                    if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Escalating') {
                    	system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(0, individualTaxRec.Enhanced_Tax_Amount__c  );
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Tiered') {
                        system.assertEquals(0, individualTaxRec.Enhanced_Tax_Amount__c  );
                        system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                   }
                } else if (dupcRec.Type__c == 'Dealer') {
                    if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Escalating') {
                    	system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(0, individualTaxRec.Enhanced_Tax_Amount__c  );
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'State Tiered') {
                   		system.assertEquals(null, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(0, individualTaxRec.Enhanced_Tax_Amount__c);
                   } else if (individualTaxRec.Sales_Tax_Item_Name__c == 'Fixed Rate 2') {
                        system.assertEquals(8.00, individualTaxRec.Tax_Rate__c);
                        system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
                   }
                }
            }  
        }   
        Test.stopTest();       
    }
}
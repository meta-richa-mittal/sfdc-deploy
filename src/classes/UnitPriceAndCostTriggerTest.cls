/**
**/ 
@isTest
private class UnitPriceAndCostTriggerTest {

    static testMethod void insertUnitPriceAndCostTriggerTest() {
    	Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
       	Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        List<Customer_Owned_Unit__c> customerOwnedUnitRecList = new List<Customer_Owned_Unit__c>();
        Customer_Owned_Unit__c customerOwnedUnitStockRec1 = TestUtil.createCustomerOwnedUnit(false,customer.id, unitmake.id,unitmodel.id,null,'123');
        customerOwnedUnitStockRec1.Unit_Type__c = 'STOCK';
        customerOwnedUnitStockRec1.Status__c = 'Available';
        customerOwnedUnitStockRec1.Unit_Id__c = '';
        
    	Customer_Owned_Unit__c customerOwnedUnitStockRec2 = TestUtil.createCustomerOwnedUnit(false,customer.id, unitmake.id,unitmodel.id,null,'1213');
        customerOwnedUnitStockRec2.Unit_Type__c = 'STOCK';
        customerOwnedUnitStockRec2.Status__c = 'Available';
        customerOwnedUnitStockRec2.Unit_Id__c = '';
    	
    	Test.startTest();
        customerOwnedUnitRecList.add(customerOwnedUnitStockRec1);
        customerOwnedUnitRecList.add(customerOwnedUnitStockRec2);
        insert customerOwnedUnitRecList;
    	Test.stopTest();
        
        Unit_Price_Cost__c unitPriceAndCost1COU1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnitStockRec1.Id, Type__c = 'Factory', Cost__c = 100, Price__c = 150, Qty__c = 2);
        Unit_Price_Cost__c unitPriceAndCost2COU1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnitStockRec2.Id, Type__c = 'Dealer', Cost__c = 200, Price__c = 300, Qty__c = 2);
        
        Unit_Price_Cost__c unitPriceAndCost1COU2 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnitStockRec1.Id, Type__c = 'Base', Cost__c = 50, Price__c = 20, Qty__c =1);
        Unit_Price_Cost__c unitPriceAndCost2COU2 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnitStockRec2.Id, Type__c = 'Dealer', Cost__c = 60, Price__c = 100, Qty__c = 5);
        insert new List<Unit_Price_Cost__c>{unitPriceAndCost1COU1, unitPriceAndCost2COU1, unitPriceAndCost1COU2, unitPriceAndCost2COU2};
		
		validateTriggerUpdate();
		
		unitPriceAndCost1COU2.Customer_Owned_Unit__c = customerOwnedUnitStockRec1.Id;
		update unitPriceAndCost1COU2;
		delete unitPriceAndCost1COU1;
		validateTriggerUpdate();
	}
	
	private static void validateTriggerUpdate() {
		List<Customer_Owned_Unit__c> customerOwnedUnitRecList = [Select Id, Total_Base_Unit_Price__c, Total_Base_Units_Cost__c, Total_Dealer_Options_Cost__c, Total_Dealer_Options_Price__c, Total_Factory_Options_Cost__c,
					Total_Factory_Options_Price__c, Total_Cost__c, Total_Price__c, (Select Type__c, Total_Cost__c, Total_Price__c from Unit_Prices_Costs__r) from Customer_Owned_Unit__c];
				
		for(Customer_Owned_Unit__c couRec : customerOwnedUnitRecList) {
			Decimal baseUnitsCost = 0;
			Decimal baseUnitsPrice = 0;
			Decimal factoryOptionsCost = 0;
			Decimal factoryOptionsPrice = 0;
			Decimal dealerOptionsCost = 0;
			Decimal dealerOptionsPrice = 0;
			Decimal totalCost = 0;
			Decimal totalPrice = 0;
			for(Unit_Price_Cost__c unitPriceAndCostRec : couRec.Unit_Prices_Costs__r) {
				if(unitPriceAndCostRec.Type__c != null && unitPriceAndCostRec.Type__c == UnitPriceAndCostTriggerHelper.TYPE_BASE) {
					baseUnitsCost += (unitPriceAndCostRec.Total_Cost__c == null) ? 0 : unitPriceAndCostRec.Total_Cost__c;
					baseUnitsPrice += (unitPriceAndCostRec.Total_Price__c == null) ? 0 : unitPriceAndCostRec.Total_Price__c;
				} else if(unitPriceAndCostRec.Type__c != null && unitPriceAndCostRec.Type__c == UnitPriceAndCostTriggerHelper.TYPE_DEALER) {
					dealerOptionsCost += (unitPriceAndCostRec.Total_Cost__c == null) ? 0 : unitPriceAndCostRec.Total_Cost__c;
					dealerOptionsPrice += (unitPriceAndCostRec.Total_Price__c == null) ? 0 : unitPriceAndCostRec.Total_Price__c;
				} else if(unitPriceAndCostRec.Type__c != null && unitPriceAndCostRec.Type__c == UnitPriceAndCostTriggerHelper.TYPE_FACTORY) {
					factoryOptionsCost += (unitPriceAndCostRec.Total_Cost__c == null) ? 0 : unitPriceAndCostRec.Total_Cost__c;
					factoryOptionsPrice += (unitPriceAndCostRec.Total_Price__c == null) ? 0 : unitPriceAndCostRec.Total_Price__c;
				} 
			}
			
			system.assertEquals(baseUnitsCost, couRec.Total_Base_Units_Cost__c);
			system.assertEquals(baseUnitsPrice, couRec.Total_Base_Unit_Price__c);
			system.assertEquals(factoryOptionsCost, couRec.Total_Factory_Options_Cost__c);
			system.assertEquals(factoryOptionsPrice, couRec.Total_Factory_Options_Price__c);
			system.assertEquals(dealerOptionsCost, couRec.Total_Dealer_Options_Cost__c);
			system.assertEquals(dealerOptionsPrice, couRec.Total_Dealer_Options_Price__c);
			system.assertEquals(totalCost, couRec.Total_Cost__c);
			system.assertEquals(totalPrice, couRec.Total_Price__c);
			
		}
	}
    
    static testMethod void upcEnhancedTaxCalculationTest() {
		TestUtil.createEnhancedTaxSettingInGeneralConfig();
        
        Sales_Tax__c standardSalestax = TestUtil.createMixedPurchaseTaxForEnhancedTaxCalculation();
       
		Account vendor = TestUtil.createVendor(false, 'Test Vendor');   
		vendor.Purchase_Tax__c = standardSalestax.ID;
		insert vendor;
		
		Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, null, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Taxable__c = true;
		customerOwnedUnit.Applicable_Tax__c = standardSalestax.Id;
		customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'On Order';
		customerOwnedUnit.Unit_Id__c = '';
		customerOwnedUnit.Vendor__c = vendor.Id ;
        insert customerOwnedUnit;
        
        Unit_Price_Cost__c unitPriceAndCostBase = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Base', 
        	Item_Description__c ='Test',Total_Price__c = 2000, Cost__c = 2500, Total_Cost__c = 2500, Qty__c = 1, Price__c = 2000);
        Unit_Price_Cost__c unitPriceAndCostBase1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Base', 
        	Item_Description__c ='Test',Total_Price__c = 2000, Cost__c = 2500, Total_Cost__c = 300, Qty__c = 1, Price__c = 2000);
        Unit_Price_Cost__c unitPriceAndCostBaseFact = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Factory', 
        	Item_Description__c ='Test',Total_Price__c = 2000, Cost__c = 800, Total_Cost__c = 800, Qty__c = 1, Price__c = 2000);
        Unit_Price_Cost__c unitPriceAndCostBaseFact1 = new Unit_Price_Cost__c(Customer_Owned_Unit__c = customerOwnedUnit.Id, Type__c = 'Factory', 
        	Item_Description__c ='Test',Total_Price__c = 2000, Cost__c = 2500, Total_Cost__c = 300, Qty__c = 1, Price__c = 2000);
        	
        insert new List<Unit_Price_Cost__c>{unitPriceAndCostBase, unitPriceAndCostBase1, unitPriceAndCostBaseFact, unitPriceAndCostBaseFact1};
        
        List<Customer_Owned_Unit__c> unitList = [Select Id, Total_Cost__c, Tax_Amount__c from Customer_Owned_Unit__c where Id=: customerOwnedUnit.Id];
        system.assertEquals(1, unitList.size());
        system.assertEquals(3900, unitList[0].Total_Cost__c);
        system.assertEquals(773.5, unitList[0].Tax_Amount__c);
    }
}
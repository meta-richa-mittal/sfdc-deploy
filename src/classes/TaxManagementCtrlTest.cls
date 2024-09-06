@isTest
private class TaxManagementCtrlTest {
	
   @testsetup
   public static void setTestData() {
	   	Category__c testCategory1 = TestUtil.createCategory(true, 'Test Category 1', 'Tax', 'Test Description', true, true);
	   	
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(false, 'Test Sales Tax1', true, true, true);
    	defaultSalesTax.Tax_Type__c = 'Sell';
    	Sales_Tax__c salesTax = TestUtil.createSalesTax(false, 'Test Sales Tax2', true, false, true);
    	salesTax.Tax_Type__c = 'Purchase';
    	Sales_Tax__c purchaseTax = TestUtil.createSalesTax(false, 'Test Sales Tax3', true, false, true);
    	purchaseTax.Tax_Type__c = 'Purchase';
    	insert new List<Sales_Tax__c>{defaultSalesTax, salesTax, purchaseTax};
    	
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	
    	Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(false, 'Test Item1', 10.0, 'Testing ', true, testCategory.Id);
    	salesTaxItem1.Tax_Type__c = 'Sell';
    	salesTaxItem1.Rate_Type__c = 'Fixed rate';
    	Sales_Tax_Item__c salesTaxItem2 = TestUtil.createSalesTaxItem(false, 'Test Item2', 5.0, 'Testing ', true, testCategory.Id, false);
    	salesTaxItem2.Tax_Type__c = 'Purchase';
    	salesTaxItem2.Rate_Type__c = 'Fixed rate';
    	Sales_Tax_Item__c salesTaxItem3 = TestUtil.createSalesTaxItem(false, 'Test Item3', 10.0, 'Testing ', true, testCategory.Id);
    	salesTaxItem3.Tax_Type__c = 'Purchase';
    	salesTaxItem3.Rate_Type__c = 'Fixed rate';
    	insert new List<Sales_Tax_Item__c>{salesTaxItem1, salesTaxItem2, salesTaxItem3};
    	
    	Applicable_Taxes__c appTax1 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem1.Id);
    	Applicable_Taxes__c appTax2 = TestUtil.createApplicableTax(true, salesTax.Id, salesTaxItem2.Id);
    	
   }
   
    static testMethod void getAllTaxRatesTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getAllTaxRates());
    	TaxRateWrapper taxRateWrapperObj = (TaxRateWrapper) System.JSON.deserialize(response, TaxRateWrapper.class);
    	system.assertEquals(1, taxRateWrapperObj.SalesTaxRates.size());
    	system.assertEquals(2, taxRateWrapperObj.PurchaseTaxRates.size());
    }
    
    static testMethod void deleteTaxRateTest() {
    	List<Sales_Tax_Item__c> salesTaxRecList = [Select Id from Sales_Tax_Item__c where Name__c =: 'Test Item3'];
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.deleteTaxRate(BPUtility.getEncodedString(salesTaxRecList[0].Id)));
    	
    	system.assertEquals('Success', response);
    	
    	salesTaxRecList = [Select Id from Sales_Tax_Item__c where Name__c =: 'Test Item1'];
    	try {
    		BPUtility.getDecodedString(TaxManagementCtrl.deleteTaxRate(BPUtility.getEncodedString(salesTaxRecList[0].Id)));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Cannot delete: tax rate is being used in a tax code'));
    	}
    }
    
    static testMethod void getTaxCategoriesTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getTaxCategories());
    	List<CategoryWrapper> categoryObjList = (List<CategoryWrapper>) System.JSON.deserialize(response, List<CategoryWrapper>.class);
    	system.assertEquals(1, categoryObjList.size());
    }
    
    static testMethod void saveTaxRateTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getTaxCategories());
    	List<CategoryWrapper> categoryObjList = (List<CategoryWrapper>) System.JSON.deserialize(response, List<CategoryWrapper>.class);
    	
    	TaxRateWrapper.TaxRate taxRateObj1 = new TaxRateWrapper.TaxRate();
    	taxRateObj1.TaxName = 'State Tax';
    	taxRateObj1.FormsLabel = 'State Tax';
    	taxRateObj1.RateType = TaxManagementService.FIXED_RATE;
    	taxRateObj1.CategoryId = categoryObjList[0].Id;
    	taxRateObj1.TaxRate = 10;
    	
    	response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxRate(BPUtility.getEncodedString(System.JSON.serialize(taxRateObj1))));
    	List<Sales_Tax_Item__c> stiList = [Select Id from Sales_Tax_Item__c where Rate_Type__c =: TaxManagementService.FIXED_RATE];
    	system.assertEquals(4, stiList.size());
    	
    	TaxRateWrapper.TaxRate taxRateObj2 = new TaxRateWrapper.TaxRate();
    	taxRateObj2.TaxName = 'Country Tax';
    	taxRateObj2.FormsLabel = 'Country Tax';
    	taxRateObj2.RateType = TaxManagementService.ESCALATING_RATE;
    	taxRateObj2.CategoryId = categoryObjList[0].Id;
    	taxRateObj2.TaxRate = 15;
    	taxRateObj2.MinimumTaxAmount = 500;
    	taxRateObj2.MaximumTaxAmount = 2000;
    	
    	List<TaxRateWrapper.RateTableWrapper> RateTable = new List<TaxRateWrapper.RateTableWrapper>();
    	RateTable.add(new TaxRateWrapper.RateTableWrapper(0, null, 10));
    	taxRateObj2.RateTable = RateTable;
    	
    	response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxRate(BPUtility.getEncodedString(System.JSON.serialize(taxRateObj2))));
    	stiList = [Select Id from Sales_Tax_Item__c where Rate_Type__c =: TaxManagementService.ESCALATING_RATE];
    	system.assertEquals(1, stiList.size());
    	
    	try {
    		TaxRateWrapper.TaxRate taxRateObj3 = new TaxRateWrapper.TaxRate();
	    	taxRateObj3.FormsLabel = 'City Tax';
	    	taxRateObj3.RateType = TaxManagementService.FIXED_RATE;
	    	taxRateObj3.CategoryId = categoryObjList[0].Id;
	    	taxRateObj3.TaxRate = 10;
    	
    		response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxRate(BPUtility.getEncodedString(System.JSON.serialize(taxRateObj3))));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Tax name is required'));
    	}
    }
    
    static testMethod void saveDuplicateTaxRateTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getTaxCategories());
    	List<CategoryWrapper> categoryObjList = (List<CategoryWrapper>) System.JSON.deserialize(response, List<CategoryWrapper>.class);
    	
    	TaxRateWrapper.TaxRate taxRateObj1 = new TaxRateWrapper.TaxRate();
    	taxRateObj1.TaxName = 'State Tax';
    	taxRateObj1.FormsLabel = 'State Tax';
    	taxRateObj1.RateType = TaxManagementService.FIXED_RATE;
    	taxRateObj1.CategoryId = categoryObjList[0].Id;
    	taxRateObj1.TaxRate = 10;
    	
    	response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxRate(BPUtility.getEncodedString(System.JSON.serialize(taxRateObj1))));
    	List<Sales_Tax_Item__c> stiList = [Select Id from Sales_Tax_Item__c where Rate_Type__c =: TaxManagementService.FIXED_RATE];
    	system.assertEquals(4, stiList.size());
    	
    	try {
    		TaxRateWrapper.TaxRate taxRateObj3 = new TaxRateWrapper.TaxRate();
	    	taxRateObj3.TaxName = 'State Tax';
    		taxRateObj3.FormsLabel = 'Country Tax';
	    	taxRateObj3.RateType = TaxManagementService.FIXED_RATE;
	    	taxRateObj3.CategoryId = categoryObjList[0].Id;
	    	taxRateObj3.TaxRate = 10;
    	
    		response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxRate(BPUtility.getEncodedString(System.JSON.serialize(taxRateObj3))));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Duplicate tax rate'));
    	}
    }
    
    static testMethod void getAllTaxCodesTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getAllTaxCodes());
    	TaxCodeWrapper taxCodeWrapperObj = (TaxCodeWrapper) System.JSON.deserialize(response, TaxCodeWrapper.class);
    	system.assertEquals(1, taxCodeWrapperObj.SalesTaxCodes.size());
    	system.assertEquals(2, taxCodeWrapperObj.PurchaseTaxCodes.size());
    }
    
    static testMethod void saveTaxCodeTest() {
    	TaxCodeWrapper.TaxCode taxCodeObj1 = new TaxCodeWrapper.TaxCode();
    	taxCodeObj1.Name = 'Sales Tax1';
    	taxCodeObj1.FormsLabel = 'Sales Tax1';
    	taxCodeObj1.TaxType = 'Sell';
    	taxCodeObj1.IsDefault = true;
    	taxCodeObj1.IsActive = true;
    	taxCodeObj1.IsListRatesOnForms = false;
    	
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxCode(BPUtility.getEncodedString(System.JSON.serialize(taxCodeObj1))));
    	List<Sales_Tax__c> stList = [Select Id from Sales_Tax__c where Name__c = 'Sales Tax1'];
    	system.assertEquals(1, stList.size());
    	
    	try {
    		TaxCodeWrapper.TaxCode taxCodeObj2 = new TaxCodeWrapper.TaxCode();
	    	taxCodeObj2.FormsLabel = 'Sales Tax2';
	    	taxCodeObj2.TaxType = 'Sell';
	    	taxCodeObj2.IsDefault = false;
	    	taxCodeObj2.IsActive = true;
	    	taxCodeObj2.IsListRatesOnForms = false;
    	
    		response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxCode(BPUtility.getEncodedString(System.JSON.serialize(taxCodeObj2))));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Tax name is required'));
    	}
    }
    
    static testMethod void saveDuplicateTaxCodeTest() {
    	TaxCodeWrapper.TaxCode taxCodeObj1 = new TaxCodeWrapper.TaxCode();
    	taxCodeObj1.Name = 'Sales Tax1';
    	taxCodeObj1.FormsLabel = 'Sales Tax1';
    	taxCodeObj1.TaxType = 'Sell';
    	taxCodeObj1.IsDefault = true;
    	taxCodeObj1.IsActive = true;
    	taxCodeObj1.IsListRatesOnForms = false;
    	
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxCode(BPUtility.getEncodedString(System.JSON.serialize(taxCodeObj1))));
    	List<Sales_Tax__c> stList = [Select Id from Sales_Tax__c where Name__c = 'Sales Tax1'];
    	system.assertEquals(1, stList.size());
    	
    	try {
    		TaxCodeWrapper.TaxCode taxCodeObj2 = new TaxCodeWrapper.TaxCode();
    		taxCodeObj2.Name = 'Sales Tax1';
	    	taxCodeObj2.FormsLabel = 'Sales Tax2';
	    	taxCodeObj2.TaxType = 'Sell';
	    	taxCodeObj2.IsDefault = false;
	    	taxCodeObj2.IsActive = true;
	    	taxCodeObj2.IsListRatesOnForms = false;
    	
    		response = BPUtility.getDecodedString(TaxManagementCtrl.saveTaxCode(BPUtility.getEncodedString(System.JSON.serialize(taxCodeObj2))));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Duplicate tax code'));
    	}
    }
    
    static testMethod void deleteTaxCodeTest() {
    	List<Sales_Tax__c> salesTaxList = [Select Id from Sales_Tax__c where Name__c =: 'Test Sales Tax3'];
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.deleteTaxCode(BPUtility.getEncodedString(salesTaxList[0].Id)));
    	
    	system.assertEquals('Success', response);
    	
    	salesTaxList = [Select Id from Sales_Tax__c where Name__c =: 'Test Sales Tax1'];
    	Configurations__c config = Configurations__c.getOrgDefaults();
    	config.Default_Tax_on_Fee__c = salesTaxList[0].Id;
    	insert config;
    	
    	try {
    		BPUtility.getDecodedString(TaxManagementCtrl.deleteTaxCode(BPUtility.getEncodedString(salesTaxList[0].Id)));
    	} catch(Exception e) {
    		system.assertEquals(true, e.getMessage().contains('Cannot delete: tax code is being used.'));
    	}
    }
    
    static testMethod void assignTaxRatesTest() {
    	String response = BPUtility.getDecodedString(TaxManagementCtrl.getTaxCategories());
    	List<CategoryWrapper> categoryObjList = (List<CategoryWrapper>) System.JSON.deserialize(response, List<CategoryWrapper>.class);
    	
    	List<Sales_Tax__c> salesTaxList = [Select Id from Sales_Tax__c where Name__c =: 'Test Sales Tax3'];
    	TaxCodeWrapper.TaxCode taxCodeObj1 = new TaxCodeWrapper.TaxCode();
    	taxCodeObj1.Id = salesTaxList[0].Id;
    	
    	List<TaxRateWrapper.TaxRate> taxRateList = new List<TaxRateWrapper.TaxRate>();
    	List<Sales_Tax_Item__c> stiList = [Select Id from Sales_Tax_Item__c];
    	
    	TaxRateWrapper.TaxRate taxRateObj1 = new TaxRateWrapper.TaxRate();
    	taxRateObj1.Id = stiList[0].Id;
    	
    	TaxRateWrapper.TaxRate taxRateObj2 = new TaxRateWrapper.TaxRate();
    	taxRateObj2.Id = stiList[1].Id;
    	
    	taxRateList.add(taxRateObj1);
    	taxRateList.add(taxRateObj2);
    	
    	taxCodeObj1.TaxRateList = taxRateList;
    	
    	response = BPUtility.getDecodedString(TaxManagementCtrl.assignTaxRates(BPUtility.getEncodedString(System.JSON.serialize(taxCodeObj1))));
    	system.assertEquals('Success', response);
    }
}
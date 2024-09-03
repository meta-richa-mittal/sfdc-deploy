/**
 * Author: Durga Singh
 * Since: July 17, 2015
 * Name: ViewCustomerCtrlTest
 * Description: Test for Controller Class of view customer.
**/
@isTest
private class ViewCustomerCtrlTest {
	@testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
    }
    
    /**
     * Name: getSimilarCOUsTest 
     * Desc: Test to fetch similar COUs on VIN.
     * @param: 
     * @return: 
    **/
    
    static testMethod void getSimilarCOUsTest() {
 		Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		Account customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		
 		Unit_Make__c unitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c unitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		Customer_Owned_Unit__c  customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, unitMake.Id, unitModel.Id, null, 'VIN123');
 		
 		String similarCOUs = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarCOUs(BPUtility.getEncodedString('VIN123')));
     	List<CustomerOwnedUnit> CustomerOwnedUnits = (List<CustomerOwnedUnit>) System.JSON.deserialize(similarCOUs, List<CustomerOwnedUnit>.class);
        system.assertEquals(CustomerOwnedUnits.size() , 1);
        
        String similarCOUs1 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarCOUs(BPUtility.getEncodedString('VIN1234')));
     	List<CustomerOwnedUnit> CustomerOwnedUnits1 = (List<CustomerOwnedUnit>) System.JSON.deserialize(similarCOUs1, List<CustomerOwnedUnit>.class);
        system.assertEquals(CustomerOwnedUnits1.size() , 0);
    }
    
    /**
     * Name: getsaveCOUTest 
     * Desc: Test to save COU.
     * @param: 
     * @return: 
    **/
    
    static testMethod void getsaveCOUTest() {
 		Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		Account Customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		
 		Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c UnitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		Customer_Owned_Unit__c  customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, Customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
 		
 		Test.starttest();
 		String similarCOUs = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarCOUs(BPUtility.getEncodedString('VIN123')));
 		String saveCOUs = BPUtility.getDecodedString(ViewCustomerCtrl.saveCOU(BPUtility.getEncodedString(Customer1.Id), BPUtility.getEncodedString(similarCOUs)));
 		Test.stoptest();
     	
     	List<CustomerOwnedUnit> CustomerOwnedUnits = (List<CustomerOwnedUnit>) System.JSON.deserialize(similarCOUs, List<CustomerOwnedUnit>.class);
        system.assertEquals(CustomerOwnedUnits.size(), 1);
    }
    
      /**
     * Name: getCOURecordByIdTest 
     * Desc: Test to getCOURecordById.
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void getCOURecordByIdTest() {
 		Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		customer.Is_Customer__c = true;
 		insert customer;
 		Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c UnitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		Customer_Owned_Unit__c  customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
 		customerOwnedUnit.VIN_Number__c = 'VIN123';
 		insert customerOwnedUnit;
 		
 		string COUList = BPUtility.getDecodedString(ViewCustomerctrl.getCOURecordById(BPUtility.getEncodedString(customerOwnedUnit.Id)));
 		List<CustomerOwnedUnit> CustomerOwnedUnits = (List<CustomerOwnedUnit>) System.JSON.deserialize(COUList, List<CustomerOwnedUnit>.class);
        system.assertEquals(CustomerOwnedUnits[0].VIN , 'VIN123');
    }
    
     /**
     * Name: getCustomerContactByCustomerIdTest 
     * Desc: Test to ugetCustomerContactByCustomerId.
     * @param: 
     * @return: 
    **/
    
    static testMethod void getCustomerContactByCustomerIdTest() {
 		Account customer =  TestUtil.createCustomer(true, 'DST', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual', 'ds', 'rathore', '9783764669', 'abc', 'work@work.com', 'other@other.com', '1234567890','facebook', 'twitter', 'linkedin'  );
 		Contact contact = TestUtil.createContact(true, 'abc', 'last', customer.Id);
 		
 		String newContact = BPUtility.getDecodedString(ViewCustomerCtrl.getCustomerContactByCustomerId(BPUtility.getEncodedString(customer.Id)));
 		List<CustomerContact> customerContact = (List<CustomerContact>) System.JSON.deserialize(newContact, List<CustomerContact>.class);
 		//system.assert(false, newContact);
 		system.assertEquals(customerContact[0].LastName, 'last');
 		
    }
    
    
     /**
     * Name: getCustomerContactByIdTest 
     * Desc: Test to getCustomerContactById.
     * @param: 
     * @return: 
    **/
    
     static testMethod void getCustomerContactByIdTest() {
 		Account customer =  TestUtil.createCustomer(true, 'DST', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual', 'ds', 'rathore', '9783764669', 'abc', 'work@work.com', 'other@other.com', '1234567890','facebook', 'twitter', 'linkedin'  );
 		Contact contact = TestUtil.createContact(true, 'abc', 'last', customer.Id);
 		
 		String newContact = BPUtility.getDecodedString(ViewCustomerCtrl.getCustomerContactById(BPUtility.getEncodedString(contact.Id)));
 		List<CustomerContact> customerContact = (List<CustomerContact>) System.JSON.deserialize(newContact, List<CustomerContact>.class);
 		//system.assert(false, newContact);
 		system.assertEquals(customerContact[0].LastName, 'last');
 		
    }
    
    /**
     * Name: updateCustomerContactTest 
     * Desc: Test to update information for customer contact.
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void updateCustomerContactTest() {
 		Account customer =  TestUtil.createCustomer(true, 'DST', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual', 'ds', 'rathore', '9783764669', 'abc', 'work@work.com', 'other@other.com', '1234567890','facebook', 'twitter', 'linkedin'  );
 		Contact contact = TestUtil.createContact(true, 'abc', 'last', customer.Id);
 		
 		String newContact = BPUtility.getDecodedString(ViewCustomerCtrl.getCustomerContactById(BPUtility.getEncodedString(contact.Id)));
 		List<CustomerContact> customerContact = (List<CustomerContact>) System.JSON.deserialize(newContact, List<CustomerContact>.class);
 		customerContact[0].LastName = 'DST';
 		String customercontactsJSONString = System.JSON.serialize(customerContact);
 		String newContactId = BPUtility.getDecodedString(ViewCustomerCtrl.updateCustomerContact(BPUtility.getEncodedString(customercontactsJSONString)));
 		system.assertNotEquals(null, newContactId);
    }
    
    
     /**
     * Name: getMakeListTest 
     * Desc: Test to verify the retrieved Make List 
     * @param: 
     * @return:
     * @author:Nikhil 
    **/
    
    static testMethod void getMakeListTest() {
    	Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
    	
 		string UMList = BPUtility.getDecodedString(ViewCustomerctrl.getMakeList());
 		List<UnitMake> unitMakeList = (List<UnitMake>) System.JSON.deserialize(UMList, List<UnitMake>.class);
        system.assertEquals(unitMakeList[0].UnitMakeName,'unitMakeName');
    	
    
    
    }
    
    /**
     * Name: getModelListTest 
     * Desc: Test to verify the retrieved Model List 
     * @param: 
     * @return:
     * @author:Nikhil 
    **/
    
    static testMethod void getModelListTest() {
    	
    	Unit_Make__c unitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c unitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
    	
 		string UMList = BPUtility.getDecodedString(ViewCustomerctrl.getModelList(BPUtility.getEncodedString(unitMake.Id)));
 		List<UnitModel> unitModelList = (List<UnitModel>) System.JSON.deserialize(UMList, List<UnitModel>.class);
        system.assertEquals(unitModelList[0].UnitModelName,'unitModelName');
    	
    
    
    }
    
     /**
     * Name: getSubModelListTest 
     * Desc: Test to getSubModelList
     * @param: 
     * @return:
     * @author : Nikhil 
    **/
    
    
	static testMethod void getSubModelListTest() {
 		Unit_Make__c unitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c unitModel = testutil.createUnitModel(false, 'unitModelName', 'VIN', true, unitMake.Id);
 		unitModel.Sub_Model__c = 'unitSubModelName' ;
 		insert unitModel;
 		Unit_Sub_Model__c unitSubModel = new Unit_Sub_Model__c();
 		unitSubModel.Sub_Model_Name__c = 'unitSubModelName';
 		unitSubModel.Active__c = true;
 		unitSubModel.Unit_Model__c = unitModel.ID;
 		unitSubModel.VIN_Code__c = 'VIN';
 		
 		insert unitSubModel;
 		
    	
    	string USMList = BPUtility.getDecodedString(ViewCustomerctrl.getSubModelList(BPUtility.getEncodedString(unitModel.Id),BPUtility.getEncodedString(unitMake.Id)));
 		List<UnitSubModel> unitSubModelList = (List<UnitSubModel>) System.JSON.deserialize(USMList, List<UnitSubModel>.class);
        system.assertEquals(unitSubModelList[0].SubModelName,'unitSubModelName');
        
    }
    

	 /**
     * Name: getDefaultUnitCategoryTest 
     * Desc: Test to getDefaultUnitCategory
     * @param: 
     * @return:
     * @author : Nikhil 
    **/
    
    
	static testMethod void getDefaultUnitCategoryTest() {
		Account vendor = TestUtil.createVendor(true, 'Test Vendor');
       	Category__c testCategory = TestUtil.createCategory(true, 'Test Category','Unit','Test Description',true,true);
        string unitCategory = BPUtility.getDecodedString(ViewCustomerctrl.getDefaultUnitCategory());
 		Category unitCategoryList = (Category) System.JSON.deserialize(unitCategory, Category.class);
		system.assertEquals(unitCategoryList.CategoryName, 'Test Category');
		system.assertEquals(unitCategoryList.IsDefault, true);
		  
    }
    
    
   
	 /**
     * Name: getApplicableTaxListTest 
     * Desc: Test to getApplicableTaxList
     * @param: 
     * @return:
     * @author : Nikhil 
    **/
    
    
	static testMethod void getApplicableTaxListTest() { 
		
		Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
            
        Configurations__c taxSetting = Configurations__c.getOrgDefaults();
        taxSetting.Default_Tax_on_Fee__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Labor__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Part__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Vendor_Product__c = defaultSalesTax.Id; 
        taxSetting.Default_Tax_on_Unit__c = defaultSalesTax.Id;
        taxSetting.Tax_Included_Pricing__c = false;
        taxSetting.Country_Id__c = country.Id;
        taxSetting.State_Id__c = state.Id;
        //taxSetting.Time_Zone__c = state.Id;
        insert taxSetting;
        
		string applicableTax = BPUtility.getDecodedString(ViewCustomerCtrl.getApplicableTaxList());
		System.assertEquals(applicableTax.contains('Test Sales Tax'), true);
	
	}
    
    
    
    /**
     * Name: getSimilarUnitsTest 
     * Desc: Test to setUnitFields
     * @param: 
     * @return:
     * @author : Nikhil 
   **/
    
    
	static testMethod void getSimilarUnitsTest() {
	
		Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		customer.Is_Customer__c = true;
 		insert customer;
 		
 		Account customer1 = TestUtil.createCustomer(false, 'customerName1', 'abc@abcd.com', 'jaipur', '1111161112', null, null, false, true,'Individual','firstname11', 'lastname11', '9999996999', 'BillingStreet1');
 		customer1.Is_Customer__c = true;
 		insert customer1;
 		
 		Account customer2 = TestUtil.createCustomer(false, 'customerName2', 'abc@abcde.com', 'jaipur', '1111151112', null, null, false, true,'Individual','firstname12', 'lastname12', '9999991999', 'BillingStreet2');
 		customer2.Is_Customer__c = true;
 		insert customer2;
 		
 		Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c UnitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, null);
 		//customerOwnedUnitRec.VIN_Number__c = 'VIN123';
 		customerOwnedUnitRec.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec.Status__c = 'Active' ;
 		customerOwnedUnitRec.Plate__c = 'RJ143021';
 		//customerOwnedUnitRec.Other_Serial_No__c= 'S123456' ;
 		insert customerOwnedUnitRec;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec1 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
 		customerOwnedUnitRec1.VIN_Number__c = 'VIN123';
 		customerOwnedUnitRec1.Plate__c = 'RJ143023';
 		customerOwnedUnitRec1.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec1.Status__c = 'Active' ;
 		
 		insert customerOwnedUnitRec1;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec2 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012345');
 		customerOwnedUnitRec2.VIN_Number__c = 'VIN12356789012345';
 		customerOwnedUnitRec2.Plate__c = 'RJ143024';
 		customerOwnedUnitRec2.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec2.Status__c = 'Active' ;
 		insert customerOwnedUnitRec2;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecA = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012344');
 		customerOwnedUnitRecA.VIN_Number__c = 'VIN12356789012344';
 		customerOwnedUnitRecA.Plate__c = 'RJ143024';
 		customerOwnedUnitRecA.Unit_Type__c ='ORDU' ; 
 		customerOwnedUnitRecA.Status__c = 'On Order' ;
 		insert customerOwnedUnitRecA;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecB = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789012344');
 		customerOwnedUnitRecB.VIN_Number__c = 'TIN12356789012344';
 		//customerOwnedUnitRecB.Plate__c = 'RJ143121';
 		customerOwnedUnitRecB.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRecB.Status__c = 'Available' ;
 		customerOwnedUnitRecB.Other_Serial_No__c= 'S123456' ;
 		insert customerOwnedUnitRecB;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecC = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789012347');
 		customerOwnedUnitRecC.VIN_Number__c = 'TIN12356789012347';
 		//customerOwnedUnitRecC.Plate__c = 'RJ143121';
 		customerOwnedUnitRecC.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRecC.Status__c = 'Available' ;
 		customerOwnedUnitRecC.Engine_Serial_No__c = 'SNO1234';
 		insert customerOwnedUnitRecC;
 		
 		//Comparision COUs
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec3 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012345');
 		customerOwnedUnitRec3.VIN_Number__c = 'VIN12356789012345';
 		customerOwnedUnitRec3.Plate__c = 'RJ143024';
 		customerOwnedUnitRec3.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec3.Status__c = 'Active' ;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec4 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'NIN12356789012345');
 		customerOwnedUnitRec4.VIN_Number__c = 'NIN12356789012345';
 		customerOwnedUnitRec4.Plate__c = 'RJ143022';
 		customerOwnedUnitRec4.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec4.Status__c = 'Active' ;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec5 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, null);
 		//customerOwnedUnitRec5.VIN_Number__c = 'VIN121';
 		customerOwnedUnitRec5.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec5.Status__c = 'Active' ;
 		customerOwnedUnitRec.Plate__c = 'RJ143021';
 		//customerOwnedUnitRec.Other_Serial_No__c= 'S123456' ;
 		
 		string unitJSONString = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec3));
 		string unitJSONString1 = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec4));
 		string unitJSONString2 = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec5));
		
		string similarUnits = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString)));
		string similarUnits1 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString1)));
		string similarUnits2 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString2)));
		
		List<UnitSuggestion> unitSuggestionList = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits, List<UnitSuggestion>.class);
		List<UnitSuggestion> unitSuggestionList1 = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits1, List<UnitSuggestion>.class);
		List<UnitSuggestion> unitSuggestionList2 = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits2, List<UnitSuggestion>.class);
		
		System.assertEquals(unitSuggestionList[0].PriorityNumber,1);
		System.assertEquals(unitSuggestionList1[0].PriorityNumber,4);	
	} 
	
	 /**
     * Name: getSimilarUnitsTestA 
     * Desc: Test to setUnitFields
     * @param: 
     * @return:
     * @author : Nikhil 
   **/
    
    
	static testMethod void getSimilarUnitsTestA() {
		
		Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		customer.Is_Customer__c = true;
 		insert customer;
 		
 		Account customer1 = TestUtil.createCustomer(false, 'customerName1', 'abc@abcd.com', 'jaipur', '1111161112', null, null, false, true,'Individual','firstname11', 'lastname11', '9999996999', 'BillingStreet1');
 		customer1.Is_Customer__c = true;
 		insert customer1;
 		
 		Account customer2 = TestUtil.createCustomer(false, 'customerName2', 'abc@abcde.com', 'jaipur', '1111151112', null, null, false, true,'Individual','firstname12', 'lastname12', '9999991999', 'BillingStreet2');
 		customer2.Is_Customer__c = true;
 		insert customer2;
 		
 		Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c UnitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, null);
 		//customerOwnedUnitRec.VIN_Number__c = 'VIN123';
 		customerOwnedUnitRec.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec.Status__c = 'Active' ;
 		customerOwnedUnitRec.Plate__c = 'RJ143021';
 		//customerOwnedUnitRec.Other_Serial_No__c= 'S123456' ;
 		insert customerOwnedUnitRec;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec1 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
 		customerOwnedUnitRec1.VIN_Number__c = 'VIN123';
 		customerOwnedUnitRec1.Plate__c = 'RJ143023';
 		customerOwnedUnitRec1.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec1.Status__c = 'Active' ;
 		
 		insert customerOwnedUnitRec1;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec2 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012345');
 		customerOwnedUnitRec2.VIN_Number__c = 'VIN12356789012345';
 		customerOwnedUnitRec2.Plate__c = 'RJ143024';
 		customerOwnedUnitRec2.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec2.Status__c = 'Active' ;
 		insert customerOwnedUnitRec2;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecA = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012344');
 		customerOwnedUnitRecA.VIN_Number__c = 'VIN12356789012344';
 		customerOwnedUnitRecA.Plate__c = 'RJ143024';
 		customerOwnedUnitRecA.Unit_Type__c ='ORDU' ; 
 		customerOwnedUnitRecA.Status__c = 'On Order' ;
 		insert customerOwnedUnitRecA;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecB = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789012344');
 		customerOwnedUnitRecB.VIN_Number__c = 'TIN12356789012344';
 		//customerOwnedUnitRecB.Plate__c = 'RJ143121';
 		customerOwnedUnitRecB.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRecB.Status__c = 'Available' ;
 		customerOwnedUnitRecB.Other_Serial_No__c= 'S123456' ;
 		insert customerOwnedUnitRecB;
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRecC = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789012347');
 		customerOwnedUnitRecC.VIN_Number__c = 'TIN12356789012347';
 		//customerOwnedUnitRecC.Plate__c = 'RJ143121';
 		customerOwnedUnitRecC.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRecC.Status__c = 'Reserved' ;
 		customerOwnedUnitRecC.Engine_Serial_No__c = 'SNO1234';
 		insert customerOwnedUnitRecC;
 		
 		//Comparision COUs
 		Customer_Owned_Unit__c  customerOwnedUnitRec6 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'VIN12356789012444');
 		customerOwnedUnitRec6.VIN_Number__c = 'VIN12356789012444';
 		customerOwnedUnitRec6.Plate__c = 'RJ143024';
 		customerOwnedUnitRec6.Unit_Type__c ='ORDU' ; 
 		customerOwnedUnitRec6.Status__c = 'On Order' ;
 		 
 		Customer_Owned_Unit__c  customerOwnedUnitRec7 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789002344');
 		customerOwnedUnitRec7.VIN_Number__c = 'TIN12356789002344';
 		//customerOwnedUnitRec7.Plate__c = 'RJ143124';
 		customerOwnedUnitRec7.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRec7.Status__c = 'Available' ;
 		customerOwnedUnitRec7.Other_Serial_No__c= 'S123456' ; 
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec8 = TestUtil.createCustomerOwnedUnit(false, Customer1.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789022347');
 		customerOwnedUnitRec8.VIN_Number__c = 'TIN12356789022347';
 		customerOwnedUnitRec8.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRec8.Status__c = 'Reserved' ;
 		customerOwnedUnitRec8.Engine_Serial_No__c = 'SNO1234';
		
		string unitJSONString3 = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec6));
		string unitJSONString4 = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec7));
		string unitJSONString5 = System.JSON.serialize(new customerOwnedUnit(customerOwnedUnitRec8));
		
		string similarUnits3 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString3)));
		string similarUnits4 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString4)));
		string similarUnits5 = BPUtility.getDecodedString(ViewCustomerCtrl.getSimilarUnits(BPUtility.getEncodedString(unitJSONString5)));
		
		List<UnitSuggestion> unitSuggestionList3 = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits3, List<UnitSuggestion>.class);
		List<UnitSuggestion> unitSuggestionList4 = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits4, List<UnitSuggestion>.class);
		List<UnitSuggestion> unitSuggestionList5 = (List<UnitSuggestion>) System.JSON.deserialize(similarUnits5, List<UnitSuggestion>.class);
	
		System.assertEquals(unitSuggestionList3[0].PriorityNumber,2);
		System.assertEquals(unitSuggestionList4[0].PriorityNumber,5);
		System.assertEquals(unitSuggestionList5[0].PriorityNumber,3);
	
	}

	static testMethod void getUnitSuggestion() {
		
		Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
 		customer.Is_Customer__c = true;
 		insert customer;
 		
 		Unit_Make__c UnitMake =  TestUtil.createUnitMake(true, 'unitMakeName', 'VIN', true);
 		Unit_Model__c UnitModel = testutil.createUnitModel(true, 'unitModelName', 'VIN', true, unitMake.Id);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec1 = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, 'TIN12356789002344');
 		customerOwnedUnitRec1.VIN_Number__c = 'TIN12356789002344';
 		customerOwnedUnitRec1.Plate__c = 'RJ143021';
 		customerOwnedUnitRec1.Unit_Type__c ='STOCK' ; 
 		customerOwnedUnitRec1.Status__c = 'Delivered' ;
 		insert customerOwnedUnitRec1;
 		UnitSuggestion similarUnits1 = new UnitSuggestion(customerOwnedUnitRec1 , 2);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec2 = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, null);
 		customerOwnedUnitRec2.VIN_Number__c = 'VIN12356789002345';
 		customerOwnedUnitRec2.Unit_Type__c ='ORDU' ; 
 		customerOwnedUnitRec2.Status__c = 'Cancelled' ;
 		customerOwnedUnitRec2.Plate__c = 'RJ143051';
 		insert customerOwnedUnitRec2;
 		UnitSuggestion similarUnits2 = new UnitSuggestion(customerOwnedUnitRec2 , 1);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec3 = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, null);
 		customerOwnedUnitRec3.VIN_Number__c = 'VIN12356789002346';
 		customerOwnedUnitRec3.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec3.Status__c = 'Inactive' ;
 		customerOwnedUnitRec3.Plate__c = 'RJ143061';
 		insert customerOwnedUnitRec3;
 		UnitSuggestion similarUnits3 = new UnitSuggestion(customerOwnedUnitRec3 , 3);
 		
 		Customer_Owned_Unit__c  customerOwnedUnitRec4 = TestUtil.createCustomerOwnedUnit(false, Customer.Id, UnitMake.Id, UnitModel.Id, null, null);
 		customerOwnedUnitRec4.VIN_Number__c = 'VIN12356789002347';
 		customerOwnedUnitRec4.Unit_Type__c ='COU' ; 
 		customerOwnedUnitRec4.Status__c = 'Transferred' ;
 		customerOwnedUnitRec4.Plate__c = 'RJ143071';
 		insert customerOwnedUnitRec4;
		UnitSuggestion similarUnits4 = new UnitSuggestion(customerOwnedUnitRec4 , 2);
		
		List<Customer_Owned_Unit__c> CustomerUnitList = [Select id, VIN_Number__c from Customer_Owned_Unit__c];
		
		System.assertEquals(4,CustomerUnitList.size());
	
	}

}
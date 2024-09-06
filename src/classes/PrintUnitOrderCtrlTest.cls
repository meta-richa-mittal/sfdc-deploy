@isTest
private class PrintUnitOrderCtrlTest {

    @testSetup
    private static void setup() {
        PageReference vfPage = Page.PrintUnitOrder;
        Test.setCurrentPage(vfPage);
        Account vendor = TestDataFactory.createVendor('Vendor001');
        
        Unit_Data_Field_Config__c unitDataFieldConfigRec = new Unit_Data_Field_Config__c();
        unitDataFieldConfigRec.Name = 'Unit Data 01';
        unitDataFieldConfigRec.Display_Label__c = 'Unit Label 01';
        insert unitDataFieldConfigRec;
    }

    @isTest
    private static void testPrintUnitOrderForPreferredNumberAndEmail(){
    	Test.startTest();
    	Account vendor = [SELECT Preferred_Phone__c, Preferred_Email__c, Email__c, Home_Number__c, Formatted_Home_number__c, Formatted_Preferred_Phone__c FROM Account WHERE Is_vendor__c = true LIMIT 1];
    	vendor.Home_Number__c = '999999';
    	vendor.Preferred_Phone__c = vendor.Home_Number__c;
        vendor.Preferred_Email__c = 'abc@xyz.com';
        Vendor.BillingCountry ='India';
        update vendor;
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
 		Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Data_01__c = 'Value';
        update customerOwnedUnit;
        
        ApexPages.currentPage().getParameters().put('id',vendor.Id);
        ApexPages.currentPage().getParameters().put('unitIds',BPUtility.getEncodedString(customerOwnedUnit.Id));
    	PrintUnitOrderCtrl printUnitOrderCtrlObj = new PrintUnitOrderCtrl();
        system.assertEquals(ApexPages.currentPage().getParameters().get('id'), vendor.Id);
        system.assertEquals(printUnitOrderCtrlObj.unitWrapper.vendor.Email,'abc@xyz.com');
    	Test.stopTest();
    }
    
    @isTest
    private static void testPrintUnitOrderForWorkEmailAndWorkNumber(){
    	Test.startTest();
    	Account vendor = [SELECT Preferred_Phone__c, Email__c, Work_Email__c, Mobile__c, Formatted_Preferred_Phone__c FROM Account WHERE Is_vendor__c = true LIMIT 1];
        vendor.Work_Number__c = '9999999999';
        vendor.Email__c = null;
    	vendor.Work_Email__c = 'abcd@xyz.com';
    	update vendor;
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
 		Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        ApexPages.currentPage().getParameters().put('id',vendor.Id);
        ApexPages.currentPage().getParameters().put('unitIds',BPUtility.getEncodedString(customerOwnedUnit.Id));
    	PrintUnitOrderCtrl printUnitOrderCtrlObj = new PrintUnitOrderCtrl();
        system.assertEquals(ApexPages.currentPage().getParameters().get('id'), vendor.Id);
        system.assertEquals(printUnitOrderCtrlObj.unitWrapper.vendor.Email,'abcd@xyz.com');
    	Test.stopTest();
    }
    
    @isTest
    private static void testPrintUnitrOrderForMobileNumberAndOtherEmail(){
    	Test.startTest();
    	Account vendor = [SELECT Preferred_Phone__c, Email__c, Other_Email__c, Work_Number__c, Formatted_Preferred_Phone__c FROM Account WHERE Is_vendor__c = true LIMIT 1];
        vendor.Mobile__c = '8888888888';
        vendor.Email__c = null;
    	vendor.Other_Email__c = 'abcde@xyz.com';
    	update vendor;
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
 		Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        ApexPages.currentPage().getParameters().put('id',vendor.Id);
        ApexPages.currentPage().getParameters().put('unitIds',BPUtility.getEncodedString(customerOwnedUnit.Id));
    	PrintUnitOrderCtrl printUnitOrderCtrlObj = new PrintUnitOrderCtrl();
        system.assertEquals(ApexPages.currentPage().getParameters().get('id'), vendor.Id);
        system.assertEquals(printUnitOrderCtrlObj.unitWrapper.vendor.Email,'abcde@xyz.com');
    	Test.stopTest();
    }
 
    @IsTest
    private static void getBrandingLocationTest() {
    	Business_Profile__c businessProfileObject = new Business_Profile__c();
    	businessProfileObject.Business_Street_Address1__c = 'test street1';
    	businessProfileObject.Business_Street_Address2__c = 'test street1';
    	businessProfileObject.Business_City__c = 'test city'; 
    	businessProfileObject.Business_Name__c = 'business 1 ';
    	businessProfileObject.Business_Postal_Code__c = '302022';
        insert businessProfileObject;
        BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
        Test.startTest();
        brandingLocationObj.setDefaultBrandingLocation(businessProfileObject);
        Test.stopTest();
        system.assertEquals(brandingLocationObj.BusinessStreetAddress1,'test street1');
    }

    @IsTest
    private static void getUnitsTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
 		Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        Set<Id> unitIdSet = new Set<Id>();
        unitIdSet.add(customerOwnedUnit.Id);
        Test.startTest();
        List<Customer_Owned_Unit__c> unitList = SOQLUtil.getUnitDetails(unitIdSet);
        Test.stopTest();
        system.assertEquals(unitList.size(),1);
    }
}
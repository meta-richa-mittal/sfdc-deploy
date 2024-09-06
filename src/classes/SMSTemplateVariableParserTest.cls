/**
 * Author: Reena Singh
 * Since: Nov 27, 2020
 * Name: SMSTemplateVariableParserTest
 * Description: Test Class of SMSTemplateVariableParser class
**/
@isTest
public without sharing class SMSTemplateVariableParserTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        Text_Message_Template__c textMessageTemplate = new Text_Message_Template__c();
        textMessageTemplate.Template_Body__c = 'Hi [store_name], [service_job_total], [parts_ready_qty_this_CO], [customer], [parts_ready_qty_all_CO], [service_job_unit], This template for testing purpose. Thanks, [store_phone]';
        textMessageTemplate.Template_Name__c = 'test';
        insert textMessageTemplate;
        
        Business_Profile__c businessProfile = new Business_Profile__c();
        businessProfile.Abbreviated_Business_Name__c = 'ABRName';
        insert businessProfile;
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);

        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax__c salestax =  TestUtil.createSalesTax(true, 'HST');
        
        Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
        
        Applicable_Taxes__c applicabletax = TestUtil.createApplicableTax(true, salestax.Id, salesTaxItem.Id);
        
        Account customer = TestUtil.createCustomer(false, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        customer.Is_Customer__c = true;
        insert customer;
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Line_Item__c coLineItemRec1 = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 50);

        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        Transaction_Type__c transactionType =  TestUtil.createTransactionType(true, 'Code', 'Customer');
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c();
        soHeaderRec.Name__c = 'Test SO Header';  
        soHeaderRec.CO_Header__c = coHeader.Id;
        soHeaderRec.Customer_Owned_Unit__c = customerOwnedUnit.Id;
        soHeaderRec.Total__c = 100;
        soHeaderRec.Transaction_Type__c = transactionType.Id;
        insert soHeaderRec;
    }

    @isTest
    private static void parsingLogicTest() {
        List<Text_Message_Template__c> textMessageTemplateList = [SELECT Id FROM Text_Message_Template__c];
        List<Account> customerList = [SELECT Id FROM Account where Is_Customer__c = true];
        CO_Header__c coHeader = [SELECT Id FROM CO_Header__c LIMIT 1];
        
        Test.startTest();
        String templateBody = SMSTemplateVariableParser.parse(textMessageTemplateList[0].Id, customerList[0].Id, coHeader.Id);
        System.assert(!templateBody.contains('[customer]'), templateBody);
        System.assert(templateBody.contains('Test Customer'), templateBody);
        Test.stopTest();
    }
}

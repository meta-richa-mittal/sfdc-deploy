/**
 * Author: Riccha Mittal
 * Since: Feb 11, 2021
 * Name: PrintOrderFulfillmentCtrlTest test
 * Description: Controller test Class of PrintOrderFulfillmentCtrl.
**/
@isTest
public without sharing class PrintOrderFulfillmentCtrlTest {
    @testSetup
    private static void setup() {
    	Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part2 = TestUtil.createPart(true, 'TestPart2', vendor.Id, 'TestPart2', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, false, null, null);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, null, part1.Id, 1, 5.0);    
        CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part1.Id, 40);
        CO_Line_Item__c coLineItem2 = TestUtil.createCOLineItem(true, coHeader.Id, part2.Id, 40);
        CustomerOrderCtrl.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(coHeader.Id));
    }
    
    static testMethod void printOrderFulfillmentCtrlTest() {
    	Test.startTest();
    	List<CO_Header__c> coList = [SELECT Id FROM CO_Header__c];
    	List<CO_Line_Item__c> coliList = [SELECT Id FROM CO_Line_Item__c WHERE CO_Kit_Header__c = null];
    	
    	for(CO_Line_Item__c coli: coliList) {
    		List<String> invIdList = new List<String>{coli.Id};
        	CustomerOrderCtrl_V2.finalizeInvoice(BPUtility.getEncodedString(System.JSON.serialize(invIdList)), BPUtility.getEncodedString(coList[0].Id));
    	}
        
        List<CO_Invoice_Header__c> coInvList = [SELECT Id FROM CO_Invoice_Header__c WHERE Status__c = 'Closed' AND CO_Header__c = :coList[0].Id];
    	ApexPages.currentPage().getParameters().put('id', coInvList[0].Id);
    	PrintOrderFulfillmentCtrl obj = new PrintOrderFulfillmentCtrl();
		system.assertEquals(ApexPages.currentPage().getParameters().get('id'), obj.coInvId);
    	Test.stopTest();
    }
}
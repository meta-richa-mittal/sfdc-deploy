@isTest
private without sharing class PrintCOProfitabilityCtrlTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        
        Account customerRec = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');

        Account vendorRec = TestDataFactory.createVendor('newacc');
        
        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(customerRec.Id);

        CO_Line_Item__c coLineItemRec = TestDataFactory.createCoLineItem(customerOrderRec.Id,1);

        CO_Invoice_Header__c invoiceHeaderRec = TestDataFactory.createCOInvoiceHeader(customerOrderRec.Id,'Completed');
    }
    @isTest
    private static void getCOProfitabilityTest(){
        CO_Header__c customerOrderRec =[Select Id FROM CO_Header__c Limit 1];
        PrintCOProfitabilityCtrl coProfitabilityCtrlObj = new PrintCOProfitabilityCtrl();

        Test.startTest();
        String coId = BPUtility.getEncodedString(customerOrderRec.Id);
        String profitabilityObj = PrintCOProfitabilityCtrl.getCOProfitability(coId);
        
        profitabilityObj = BPUtility.getDecodedString(profitabilityObj);
        PrintCOProfitabilityCtrl.COProfitabilityDetail profitabilityObj1 = (PrintCOProfitabilityCtrl.COProfitabilityDetail)System.JSON.deserialize(profitabilityObj,PrintCOProfitabilityCtrl.COProfitabilityDetail.class);
        
        Test.stopTest();
        System.assertEquals('customerName', profitabilityObj1.CustomerName);

    }
}

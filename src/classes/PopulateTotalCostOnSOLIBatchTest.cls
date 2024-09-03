/**
 * Author: Namarta Gocher
 * updated: March 2, 2022
 * Name: PopulateTotalCostOnSOLIBatchTest
 * Description: Test class for PopulateTotalCostOnSOLIBatch
**/
@isTest
private without sharing class PopulateTotalCostOnSOLIBatchTest {
    
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        
        Account customerRec = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');

        Account vendorRec = TestDataFactory.createVendor('newacc');
        
        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(customerRec.Id);

        CO_Line_Item__c coLineItemRec = TestDataFactory.createCoLineItem(customerOrderRec.Id,1);

        CO_Invoice_Header__c invoiceHeaderRec = TestDataFactory.createCOInvoiceHeader(customerOrderRec.Id,'Completed');

        Service_Order_Header__c soHeaderRec = TestDataFactory.createSOHeader(customerOrderRec.Id);
        soHeaderRec.Total_Hours_Billed__c = 3;
        soHeaderRec.Is_Technician_Hours_Costing_Enabled__c = true;
        soHeaderRec.Invoice_Number__c = invoiceHeaderRec.Id;
        soHeaderRec.Work_Status__c = ServiceJobUtil.INVOICED;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);

        Category__c catRec = TestDataFactory.createCategory('categoryName');

        Product__c productRec = TestDataFactory.createNewProduct(catRec.Id,'12',vendorRec.Id);

        Labour_Code__c labourCode = TestDataFactory.createNewLabourCode(catRec.Id, '1234', customerOrderRec.Id, true, 3, 'labourCodeName', 2.00, false);
        Fee__c aplicableFee = TestDataFactory.sampleFee(true, catRec.Id, 'CodeToCode', customerOrderRec.Id, 'DescriptionToDescribe ', 15, true);
        Shop_Supplies__c shopsup = TestDataFactory.createShopSupplies(aplicableFee.Id);
        Fee__c feeRec = TestDataFactory.createNewFee(true,catRec.Id,'123',customerOrderRec.Id,'description',24,true);

        Service_Order_Line_Item__c lineItemRec = TestDataFactory.createServiceOrderLineItem(soHeaderRec.Id);
        lineItemRec.Qty_Needed__c = 2;
        lineItemRec.Labour_Code__c = labourCode.Id;
        lineItemRec.Sublet__c = productRec.Id;
        lineItemRec.Fee__c = feeRec.Id;
        lineItemRec.Kit_Price__c = 2;
        lineItemRec.Qty_Needed__c = 1;
        lineItemRec.Total_Cost__c = 4;
        lineItemRec.Cost__c = 2;
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', lineItemRec);

    }

    @isTest
    private static void PopulateTCOnSOLIBatchMethodsTest(){
        Fee__c feeRec = [Select Id From Fee__c];
        Service_Order_Line_Item__c lineItemRec = [Select Id from Service_Order_Line_Item__c ];
        Service_Order_Header__c soHeaderRec = [Select Id from Service_Order_Header__c ];
        Labour_Code__c labourCode = [Select Id from Labour_Code__c ];
        Product__c productRec = [Select Id from Product__c ];
        PopulateTotalCostOnSOLIBatch reassign = new PopulateTotalCostOnSOLIBatch();
    
        Test.startTest();
        Id batchprocessid = Database.executeBatch(reassign);
        feeRec.Cost_Method__c = 'Percent Retail';
        DMLUtility.updateSobjectList('Fee__c', feeRec);
        Id batchprocessid1 = Database.executeBatch(reassign);

        lineItemRec.Fee__c = null;
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c',lineItemRec);
        Id batchprocessid2 = Database.executeBatch(reassign);
        soHeaderRec.Is_Technician_Hours_Costing_Enabled__c = false;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);

        Id batchprocessid3 = Database.executeBatch(reassign);
        labourCode.Cost_Method__c = 'Percent Retail';
        Id batchprocessid4 = Database.executeBatch(reassign);

        lineItemRec.Labour_Code__c = null;
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', lineItemRec);
        Id batchprocessid5 = Database.executeBatch(reassign);
        lineItemRec.Cost__c = null;
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', lineItemRec);
        Id batchprocessid6 = Database.executeBatch(reassign);
        productRec.Cost_Method__c = 'Percent Retail';
        DMLUtility.updateSobjectList('Product__c', productRec);
        Id batchprocessid7 = Database.executeBatch(reassign);

        lineItemRec.Sublet__c = null;
        Id batchprocessid8 = Database.executeBatch(reassign);
        
        Test.stopTest();
        }
    
}

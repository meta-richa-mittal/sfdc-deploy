@isTest
private class XeroVendorInvoiceUtilityTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendor = TestDataFactory.createVendor('balveer');
        Account customer = TestDataFactory.createCustomer('balveer choudhary', 'individual', 'balveer', 'choudhary');
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'COU', Status__c = 'Active', VIN_Number__c = '1234');
        insert insertCOU;
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id); 
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem;
        CO_Invoice_Item__c coInvoiceItem1 = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem1;
        CO_Invoice_Payment__c coInvoicePayment = new CO_Invoice_Payment__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoicePayment;
        Unit_Price_Cost__c unitPriceCost = new Unit_Price_Cost__c(Total_Cost__c = 120, CO_Invoice_Header__c = coInvoiceHeader.id, Customer_Owned_Unit__c = insertCOU.id, vendor__c = vendor.id);
        insert unitPriceCost;
        Vendor_Invoicing_Header__c vendorInvoicingHeader = new Vendor_Invoicing_Header__c(vendor__c = vendor.id);
        insert vendorInvoicingHeader;
        Vendor_Invoicing_Group__c vendorInvoiceingGroup = new Vendor_Invoicing_Group__c(Vendor_Invoicing_Header__c = vendorInvoicingHeader.id, VI_Cost__c = 500, VI_Discount__c = 10);
        insert vendorInvoiceingGroup;
        Part_FIFO_Bucket__c partFIFOBucket = new Part_FIFO_Bucket__c(Vendor_Invoicing_Header__c = vendorInvoicingHeader.id);
        insert partFIFOBucket;
        Category__c category = new Category__c(name = 'Unit', Income_GL__c = '167', Type__c = 'Unit', Active__c = true, Default__c = true, Description__c = 'Consignment Clearing');
        insert category;
        Fee__c fee = new Fee__c(Category__c = category.id, code__c = '124', Description__c = 'fee');
        insert fee;
        Other_Charges__c otherCharge = new Other_Charges__c(Vendor_Invoicing_Header__c = vendorInvoicingHeader.id, Fee__c = fee.id);
        insert otherCharge;
		Return_CR_Header__c returnVOHeader = new Return_CR_Header__c(vendor__c = vendor.id);
        insert returnVOHeader;
    }

    @isTest
    private static void testXeroVendorInvoiceUtility() {
        Test.startTest();  
        String query1;
        String query2;
        String query3;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingUnit.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Customer_Owned_Unit__c';
        AccountingUnit accountingUnit = new AccountingUnit(Database.query(query1));
        accountingUnit.CreatedDate = date.today();
        accountingUnit.DueDate = date.today();
        XeroVendorInvoiceUtility.setAllInvoiceItemRec(AccountingUnit, false);
        //
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingVendorReturn.getReturnCRFieldList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Return_CR_Header__c';
        AccountingVendorReturn accountingCustomerInvoice = new AccountingVendorReturn(Database.query(query1), null);
        XeroVendorInvoiceUtility.setAllInvoiceItemRec(accountingCustomerInvoice);
        //
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingUnitPriceAndCost.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Unit_Price_Cost__c';
        AccountingUnitPriceAndCost accountingUnitPriceAndCost = new AccountingUnitPriceAndCost(Database.query(query1));
        List<XeroLineItemDTO> lineItemDTO = XeroVendorInvoiceUtility.setAllInvoiceItemRec(accountingUnitPriceAndCost);
        //
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingVendorInvoice.objectToFieldMap.get('VIHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Vendor_Invoicing_Header__c';

        query2 = 'SELECT '; 
        for(String fieldsName : AccountingVendorInvoice.objectToFieldMap.get('VIGroup')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query2 += fieldsName + ', ';
        }
        query2 = query2.substring(0, query2.length()-2);
        query2 += ' FROM Vendor_Invoicing_Group__c';

        query3 = 'SELECT '; 
        for(String fieldsName : AccountingFIFOBucket.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query3 += fieldsName + ', ';
        }
        query3 = query3.substring(0, query3.length()-2);
        query3 += ' FROM Part_FIFO_Bucket__c';

        AccountingVendorInvoice accountingVendorInvoice = new AccountingVendorInvoice(Database.query(query1), Database.query(query2), Database.query(query3));
        XeroVendorInvoiceUtility.setAllInvoiceItemRec(accountingVendorInvoice);
        system.assertNotEquals(0, lineItemDTO.size());
        Test.stopTest();
    }
}
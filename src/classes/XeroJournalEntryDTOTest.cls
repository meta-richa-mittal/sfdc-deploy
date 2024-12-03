@isTest
private class XeroJournalEntryDTOTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendor = TestDataFactory.createVendor('balveer');
        Account customer = TestDataFactory.createCustomer('balveer choudhary', 'individual', 'balveer', 'choudhary');
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id); 
        insert coHeader;
        CO_Deposit__c coDeposit = new CO_Deposit__c(CO_Header__c = coHeader.id, Payment_Method__c = 'Cash');
        insert coDeposit;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'COU', Status__c = 'Active', VIN_Number__c = '1234');
        insert insertCOU;
        Unit_Price_Cost__c unitPriceCost = new Unit_Price_Cost__c(Total_Cost__c = 120, CO_Invoice_Header__c = coInvoiceHeader.id, Customer_Owned_Unit__c = insertCOU.id, vendor__c = vendor.id);
        insert unitPriceCost;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.id, Lien_Payout__c = 122);
        insert dealItem;
        CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem;
        CO_Invoice_Item__c coInvoiceItem1 = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem1;
        CO_Invoice_Payment__c coInvoicePayment = new CO_Invoice_Payment__c(CO_Invoice_Header__c = coInvoiceHeader.id, Payment_Method__c = 'Cash');
        insert coInvoicePayment;
        Vendor_Invoicing_Header__c vendorInvoicingHeader = new Vendor_Invoicing_Header__c();
        insert vendorInvoicingHeader;
        Vendor_Invoicing_Group__c vendorInvoiceingGroup = new Vendor_Invoicing_Group__c(Vendor_Invoicing_Header__c = vendorInvoicingHeader.id);
        insert vendorInvoiceingGroup;
        Part_FIFO_Bucket__c partFIFOBucket = new Part_FIFO_Bucket__c(Vendor_Invoicing_Header__c = vendorInvoicingHeader.id, Source_Name__c = 'Cost Adjust');
        insert partFIFOBucket;
        Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketLineItem = new Part_FIFO_Bucket_Activity_Line_Item__c(Part_FIFO_Bucket__c = partFIFOBucket.id);
        insert partFIFOBucketLineItem;
        Payment_on_Account__c paymentOnAccount = new Payment_on_Account__c(customer__c = customer.id, Payment_Date__c = date.today(), Payment_Method__c = 'Cash');
        insert paymentOnAccount;
        Vendor_Receiving_Header__c vendorReceivingHeader = new Vendor_Receiving_Header__c();
        insert vendorReceivingHeader;
        Vendor_Receiving_Group__c vendorReceivingGroup = new Vendor_Receiving_Group__c(Vendor_Receiving_Header__c = vendorReceivingHeader.id);
        insert vendorReceivingGroup;
    }
    @isTest
    private static void testXeroJournalEntryDTO() {
        Test.startTest();   
        String query;
        query = 'SELECT '; 
        for(String fieldsName : AccountingFIFOBucket.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Part_FIFO_Bucket__c';
        AccountingFIFOBucket accountingFIFOBucket = new AccountingFIFOBucket(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO = new XeroJournalEntryDTO(accountingFIFOBucket);

        query = 'SELECT '; 
        for(String fieldsName : AccountingFIFOBucketActivityLineItem.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Part_FIFO_Bucket_Activity_Line_Item__c';
        AccountingFIFOBucketActivityLineItem accountingFIFOBucketActivityLineItem = new AccountingFIFOBucketActivityLineItem(Database.query(query));
        accountingFIFOBucketActivityLineItem.cost = 15;
        accountingFIFOBucketActivityLineItem.QtyOut = 20;
        XeroJournalEntryDTO xeroJournalEntryDTO1 = new XeroJournalEntryDTO(accountingFIFOBucketActivityLineItem);


        query = 'SELECT '; 
        for(String fieldsName : AccountingDealItem.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Deal_Item__c';
        AccountingDealItem accountingDealItem = new AccountingDealItem(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO2 = new XeroJournalEntryDTO(accountingDealItem);

        query = 'SELECT '; 
        for(String fieldsName : AccountingCOInvoicePayment.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM CO_Invoice_Payment__c';
        AccountingCOInvoicePayment accountingCOInvoicePayment = new AccountingCOInvoicePayment(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO3 = new XeroJournalEntryDTO(accountingCOInvoicePayment);


        query = 'SELECT '; 
        for(String fieldsName : AccountingUnit.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Customer_Owned_Unit__c';
        AccountingUnit accountingUnit = new AccountingUnit(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO4 = new XeroJournalEntryDTO(accountingUnit, 'Stock_Unit_Category');

        query = 'SELECT '; 
        for(String fieldsName : AccountingCODeposit.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM CO_Deposit__c';
        AccountingCODeposit accountingCODeposit = new AccountingCODeposit(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO5 = new XeroJournalEntryDTO(accountingCODeposit);

        query = 'SELECT '; 
        for(String fieldsName : AccountingUnitPriceAndCost.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Unit_Price_Cost__c';
        AccountingUnitPriceAndCost accountingUnitPriceAndCost = new AccountingUnitPriceAndCost(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO6 = new XeroJournalEntryDTO(AccountingUnitPriceAndCost);

        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM CO_Invoice_Header__c';

        String query2;
        query2 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceItem')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query2 += fieldsName + ', ';
        }
        query2 = query2.substring(0, query2.length()-2);
        query2 += ' FROM CO_Invoice_Item__c';
        List<CO_Invoice_Item__c> coInvoiceItem = Database.query(query2);
        AccountingCustomerInvoice accountingCustomerInvoice = new AccountingCustomerInvoice(Database.query(query1), coInvoiceItem);
        XeroJournalEntryDTO xeroJournalEntryDTO7 = new XeroJournalEntryDTO(accountingCustomerInvoice);
        
        query = 'SELECT '; 
        for(String fieldsName : AccountingPaymentOnAccount.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Payment_on_Account__c';
        AccountingPaymentOnAccount accountingPaymentOnAccount = new AccountingPaymentOnAccount(Database.query(query));
        XeroJournalEntryDTO xeroJournalEntryDTO8 = new XeroJournalEntryDTO(accountingPaymentOnAccount);
        
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingVendorReceiving.objectToFieldMap.get('VORHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Vendor_Receiving_Header__c';
        
        query2 = 'SELECT '; 
        for(String fieldsName : AccountingVendorReceiving.objectToFieldMap.get('VORGroup')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query2 += fieldsName + ', ';
        }
        query2 = query2.substring(0, query2.length()-2);
        query2 += ' FROM Vendor_Receiving_Group__c';

        AccountingVendorReceiving accountingVendorReceiving = new AccountingVendorReceiving(Database.query(query1), Database.query(query2));
        XeroJournalEntryDTO xeroJournalEntryDTO9 = new XeroJournalEntryDTO(accountingVendorReceiving);
        
        system.assertEquals('POSTED', xeroJournalEntryDTO.Status);
        Test.stopTest();
    }
    
}
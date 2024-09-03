@isTest
private class XeroInvoicePaymentDTOTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        insert new Configurations__c(Tax_Included_Pricing__c = false);
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
        Payment_on_Account__c paymentOnAccount = new Payment_on_Account__c(customer__c = customer.id, Payment_Date__c = date.today());
        insert paymentOnAccount;
        AR_Payment__c arPayment = new AR_Payment__c(Payment_on_Account__c = paymentOnAccount.id);
        insert arPayment;
    }

    @isTest
    private static void testXeroInvoicePaymentDTO() {
        Test.startTest();   
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
        XeroInvoicePaymentDTO invoicePaymentDTO = new XeroInvoicePaymentDTO(accountingCustomerInvoice, Database.query(query1));
        //
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingARPayment.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM AR_Payment__c';
        AccountingARPayment accountingARPayment = new AccountingARPayment(Database.query(query1));
        XeroInvoicePaymentDTO invoicePaymentDTO1 = new XeroInvoicePaymentDTO(accountingARPayment);
        system.assertEquals('AUTHORISED', invoicePaymentDTO.Status);
        Test.stopTest();
    }
}
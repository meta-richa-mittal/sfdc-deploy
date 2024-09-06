@isTest
private class AccountingLienPayoutTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
	  	CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.id, 'Closed');
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.id, Lien_Payout__c = 122);
        insert dealItem;
    }
    @isTest
    private static void testAccountingLienPayout() {
        Test.startTest();   
        String query;
        query = 'SELECT '; 
        for(String fieldsName : AccountingLienPayout.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Deal_Item__c';
        AccountingLienPayout accountingLienPayout = new AccountingLienPayout(Database.query(query));
        system.assertEquals(122.00, accountingLienPayout.LienPayout);
        Test.stopTest();
    }
    
}
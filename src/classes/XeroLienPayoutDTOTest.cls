@isTest
private class XeroLienPayoutDTOTest {
    @TestSetup
    private static void setup(){
        Account customer = TestDataFactory.createCustomer('balveer choudhary', 'individual', 'balveer', 'choudhary');
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id); 
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.id, Lien_Payout__c = 122);
        insert dealItem;
    }

    @isTest
    private static void testXeroLienPayoutDTO() {
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
        XeroLienPayoutDTO lienPayoutDTO = new XeroLienPayoutDTO(accountingLienPayout);
        system.assertEquals('ACCPAY', lienPayoutDTO.Type);
        Test.stopTest();
    }
}
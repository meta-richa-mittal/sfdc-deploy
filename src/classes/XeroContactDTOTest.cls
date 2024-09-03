@isTest
private class XeroContactDTOTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendor = TestDataFactory.createVendor('balveer');
        Account customer = TestDataFactory.createCustomer('balveer choudhary', 'individual', 'balveer', 'choudhary');
    }

    @isTest
    private static void testXeroContactDTO() {
        Test.startTest();   
        String query;
        query = 'SELECT '; 
        for(String fieldsName : AccountingVendor.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Account where is_vendor__c = true';
        AccountingVendor accountingVendor = new AccountingVendor(Database.query(query));
        query = 'SELECT '; 
        for(String fieldsName : AccountingCustomer.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Account where is_customer__c = true';
        AccountingCustomer accountingCustomer = new AccountingCustomer(Database.query(query));
        XeroContactDTO result = new XeroContactDTO(accountingVendor);
        XeroContactDTO result0 = new XeroContactDTO(accountingCustomer);
        system.assertEquals('ACTIVE', result.ContactStatus);
        Test.stopTest();
    }
}
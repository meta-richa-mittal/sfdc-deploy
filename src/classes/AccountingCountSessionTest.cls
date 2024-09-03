@isTest
private class AccountingCountSessionTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Count_Session__c countSession = new Count_Session__c(name__c = 'balveer', Count_Date_Time__c=date.today());
        insert countSession;
        Count_Session_Line_Item__c CountSessionLineItem = new Count_Session_Line_Item__c(Count_Session__c = countSession.id, Total_Cost_Adjustment__c = 123.9);
        insert CountSessionLineItem;
    }
    @isTest
    private static void testAccountingCountSession() {
        Test.startTest();   
        String query;
        query = 'SELECT '; 
        for(String fieldsName : AccountingCountSession.getCountSessionfieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Count_Session__c';

        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingCountSession.getCountSessionLineItemfieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Count_Session_Line_Item__c';
        AccountingCountSession accountingCountSession = new AccountingCountSession(Database.query(query), Database.query(query1));
        system.assertEquals('balveer', accountingCountSession.Name);
        Test.stopTest();
    }
    
}
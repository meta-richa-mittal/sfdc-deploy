@isTest
private class BPScriptTest {
    
    @testSetup
    private static void setup(){
        Cash_Drawer__c cashDrawer = new Cash_Drawer__c(Name = 'Main Cash Drawer', Active__c = true);
        insert cashDrawer;
        Message_History__c messageHistory = new Message_History__c(Activity__c = 'Text Message');
        insert messageHistory;
        Customer_Owned_Unit__c COU = new Customer_Owned_Unit__c(Unit_Type__c = 'ORDU', Status__c = 'Received');
        insert COU;
    }
    
    @isTest
    private static void testBPScript(){
    	Test.startTest();
        BPScript.runScript_Sprint69();
        BPScript.runScript_Sprint70();
        BPScript.runScript_Sprint71();
        BPScript.runScript_Sprint72();
        BPScript.runScript_Sprint73();
        BPScript.runScript_Sprint75();
        BPScript.runScript_Sprint76();
        BPScript.runScript_Sprint79();
        BPScript.runScript_Sprint82();
        BPScript.runScript_Sprint85();
        BPScript.populateClosedDateOnInvoice();
        List<Cash_Drawer__c> cashDrawerList = [Select id from Cash_Drawer__c];
        system.assertEquals(1, cashDrawerList.size());
        Test.stopTest();
        
    }
        
}
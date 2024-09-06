@isTest
private without sharing class PrintCountSessionCtrlTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        Category__c category = TestDataFactory.createCategory('categoryName');
        category.Type__c = 'Adjustment';
        category.Inventory_GL__c = 'Inventory_GL__c';
        category.COGS_GL__c = 'Inventory_GL__c';
        category.Income_GL__c = 'Inventory_GL__c';
        category.AccountingId__c = 'Category__r.AccountingId__c';
        DMLUtility.updateSobjectList('Category__c',category);

        Count_Session__c countSession = TestDataFactory.createCountSession(category.Id);
    }
    
    @isTest
    private static void printCountSessionCtrlMethodTest() {
        Count_Session__c countSession = [Select Id from Count_Session__c Limit 1];
        String tabName = Constants.COUNTED_PARTS;
        String uniqueFieldLastValue = null;

        PrintCountSessionCtrl countSessionCtrlObj = new PrintCountSessionCtrl();

        Test.startTest();
        PrintCountSessionCtrl.getAllCountSessionLIBySessionIdAndTabName(countSession.Id, tabName);
        String countSessionDetail1 = PrintCountSessionCtrl.getAllCountSessionLIBySessionIdAndTabName_Update(BPUtility.getEncodedString(countSession.Id), BPUtility.getEncodedString(tabName), uniqueFieldLastValue);
        countSessionDetail1 = BPUtility.getDecodedString(countSessionDetail1);
        PrintCountSessionCtrl.CountSessionDetail countSessionDetailObj =(PrintCountSessionCtrl.CountSessionDetail) System.JSON.deserialize(countSessionDetail1, PrintCountSessionCtrl.CountSessionDetail.class);
        Test.stopTest();

        System.assertEquals(true, countSessionDetailObj.IsProcessComplete);
       
        
    }
}

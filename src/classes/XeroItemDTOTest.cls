@isTest
private class XeroItemDTOTest {
    @TestSetup
    private static void setup(){
        Category__c category = new Category__c(name = 'Unit', Income_GL__c = '167', Type__c = 'Unit', Active__c = true, Default__c = true, Description__c = 'Consignment Clearing');
        insert category;
    }

    @isTest
    private static void testXeroItemDTO() {
        Test.startTest();   
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingItemCategory.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Category__c';
        list<Category__c> category = Database.query(query1);
        AccountingItemCategory accountingItemCategory = new AccountingItemCategory(category[0]);
        XeroItemDTO itemDTO = new XeroItemDTO(accountingItemCategory);
        system.assertEquals(category[0].id, itemDTO.SFId);
        Test.stopTest();
    }
}
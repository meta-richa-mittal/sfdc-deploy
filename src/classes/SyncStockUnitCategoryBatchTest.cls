@isTest
    private class SyncStockUnitCategoryBatchTest {
        @TestSetup
        private static void setup(){
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
            Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
            customer.Is_Customer__c = true;
            customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
            insert customer;
            
    
        }
        @isTest
        private static void testSyncStockUnitCategoryBatch() {
            Category__c category = new Category__c(name = 'test', Income_GL__c = '167', Inventory_GL__c = '2345', Type__c = 'test', Active__c = true, Default__c = true, Description__c = 'test');
            insert category;
            Category__c category1 = new Category__c(name = 'test1', Income_GL__c = '166', Inventory_GL__c = '13245', Type__c = 'test1', Active__c = true, Default__c = true, Description__c = 'test1');
            insert category1;
            Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Category__c = category.id, Unit_Type__c = 'Stock', Status__c = 'Available', VIN_Number__c = '1234');
            insert insertCOU;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            Category__c categoryRec = [Select id from Category__c where name = 'test1' LIMIT 2][0];
            Customer_Owned_Unit__c couRec = [Select id, Category__c, Total_Cost__c from Customer_Owned_Unit__c LIMIT 1][0];
            couRec.Category__c = categoryRec.id;
            couRec.Total_Cost__c = 1000;
            update couRec;
            List<Category__c> categoryList = [Select id from Category__c limit 1];
            system.assertEquals(1, categoryList.size());
            Test.stopTest();
        }
        
    }
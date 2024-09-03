
@isTest
private without sharing class IndividualTaxWrapperTest {

    @TestSetup
    static void setup() {
        TestDataFactory.disableFLSChecks();
        Category__c categoryRec = TestDataFactory.createCategory('Test Category');
    	Sales_Tax_Item__c salesTaxItemRec = TestDataFactory.createSalesTaxItem('Test Sales', 2, 'Forms', categoryRec.Id, true);
        System.assert(true,true);
    }

    @isTest
    private static void creatingIndividualTaxWrapperTest(){
        Sales_Tax_Item__c sTaxItemRec = [Select Id, Name From Sales_Tax_Item__c];

        Individual_Tax__c individualTaxRec = TestDataFactory.createIndividualTax(sTaxItemRec.Name, 2.00);
        individualTaxRec.Sales_Tax_Item__c = sTaxItemRec.Id;
        individualTaxRec.Enhanced_Tax_Amount__c = 3;
        DMLUtility.updateSobjectList('Individual_Tax__c', individualTaxRec);
        Test.startTest();
        IndividualTaxWrapper testobj = new IndividualTaxWrapper(individualTaxRec);
        System.assertEquals(individualTaxRec.Id, testobj.Id);
        System.assertEquals(individualTaxRec.Sales_Tax_Item__r.Name__c, testobj.SalesTaxItemName);
        System.assertEquals(2.00, testobj.TaxRate);  
        System.assertEquals(3, testobj.EnhancedTaxAmount);   
        Test.stopTest();
    }
} 

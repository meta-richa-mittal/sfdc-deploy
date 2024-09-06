@isTest
private without sharing class QBCreditMemoDTOTest {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        BPScriptUtility.disbaleTrigger('COTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('DealItemTrigger');
        
        Account customer = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');
        customer.AccountingId__c = 'AccountingId__c';
        DMLUtility.updateSobjectList('Account', customer);

        Sales_Tax__c salesTax = TestDataFactory.createSalesTax('salesTaxName');
        salesTax.Accounting_Id__c ='Applicable_Tax__r.Accounting_Id__c';
        salesTax.Rate__c = 2.00;
        DMLUtility.updateSobjectList('Sales_Tax__c', salesTax);

        Account vendor = TestDataFactory.createVendor('vendorName');
        vendor.Vendor_AccountingId__c = 'Vendor_AccountingId__c';
        vendor.Xero_Vendor_Accounting_Id__c = 'Xero_Vendor_Accounting_Id__c';
        vendor.Purchase_Tax__c = salesTax.Id;
        DMLUtility.updateSobjectList('Account',vendor);

        CO_Header__c coHeader = TestDataFactory.createCOHeader(customer.Id);

        BPScriptUtility.disbaleTrigger('CustomerOwnedUnitTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        BPScriptUtility.disbaleTrigger('DealTrigger');
        BPScriptUtility.disbaleTrigger('COLineItemTrigger');
        

        Category__c category = TestDataFactory.createCategory('categoryName');
        category.Type__c = 'Adjustment';
        category.Inventory_GL__c = 'Inventory_GL__c';
        category.COGS_GL__c = 'Inventory_GL__c';
        category.Income_GL__c = 'Inventory_GL__c';
        category.AccountingId__c = 'Category__r.AccountingId__c';
        DMLUtility.updateSobjectList('Category__c',category);

        Fee__c fee = TestDataFactory.createNewFee(true, category.Id,'code' , coHeader.Id, 'description', 5.00, true);

        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);

        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);

        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);

        Customer_Owned_Unit__c unitRec1 = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
        unitRec1.New_Unit__c = True;
        unitRec1.Stock_Id__c = 'Stock_Id__c';
        unitRec1.Year__c = 2021;
        unitRec1.Unit_Id__c = 'Unit_Id__c';
        unitRec1.Category__c = category.Id;
        unitRec1.Vendor__c = vendor.Id;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec1);

        Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
        unitRec.New_Unit__c = True;
        unitRec.Stock_Id__c = 'a1238735645327';
        unitRec.Year__c = 2021;
        unitRec.Unit_Id__c = '873y78378y78y';
        unitRec.Category__c = category.Id;
        unitRec.Vendor__c = vendor.Id;
        unitRec.Referenced_Unit__c = unitRec1.Id;
        unitRec.Invoice_Number__c = '243243';
        unitRec.Old_Category__c = category.Id;
        unitRec.Date_Stocked_In__c = System.today();
        unitRec.Xero_JE_Accounting_Id__c ='Xero_JE_Accounting_Id__c';
        unitRec.Xero_Accounting_Id__c = 'Xero_Accounting_Id__c';
        unitRec.Xero_Consignment_Accounting_Id__c = 'Xero_Consignment_Accounting_Id__c';
        unitRec.Xero_Accounting_Id_Unit_Invoice_JE__c = 'Xero_Accounting_Id_Unit_Invoice_JE__c';
        unitRec.QB_Accounting_Id_Unit_Invoice_JE__c ='QB_Accounting_Id_Unit_Invoice_JE__c';
        unitRec.Sync_Token_For_Unit_Invoice_JE__c ='Sync_Token_For_Unit_Invoice_JE__c';
        unitRec.QB_NITC_JE_Accounting_Id__c = 'QB_NITC_JE_Accounting_Id__c';
        unitRec.Sales_Tax_Credit__c = 2;
        unitRec.Sync_Token_For_NITC_JE__c = 'Sync_Token_For_NITC_JE__c';
        unitRec.NITC_Date_Claimed__c = System.today();
        unitRec.QB_Consignment_Accounting_Id__c ='QB_Consignment_Accounting_Id__c';
        unitRec.Sync_Token_For_Consignment__c = 'Sync_Token_For_Consignment__c';
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);

        Deal__c deal = TestDataFactory.createDeal(coHeader.id,unitRec.Id);

        CO_Line_Item__c coli = TestDataFactory.createCoLineItem(coHeader.Id,1);
        coli.Closed_CO_Invoice_link__c = '';
        coli.Deal__c = deal.Id;
        coli.Fee__c = fee.Id;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coli);

        CO_Invoice_Header__c coInvoiceHeader = TestDataFactory.createCOInvoiceHeader(coHeader.id, 'Closed');

        CO_Invoice_Item__c coInvoiceItemRec = TestDataFactory.createCoInvoiceItem(category.Id, coInvoiceHeader.Id);
        coInvoiceItemRec.Deal__c = deal.Id;
        coInvoiceItemRec.Deal_Finance__c = null;
        coInvoiceItemRec.isActive__c = true;
        coInvoiceItemRec.Is_Invoiceable__c = true;
        DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvoiceItemRec);

        

        Sales_Tax_Item__c salesTaxItem = TestDataFactory.createSalesTaxItem('salesTaxItemName', 2.00, 'formsLabel', category.Id, true);
        salesTaxItem.AccountingId__c = 'AccountingId__c';
        DMLUtility.updateSobjectList('Sales_Tax_Item__c', salesTaxItem);
        
        
        Applicable_Taxes__c appTax = new Applicable_Taxes__c();
        appTax.Sales_Tax__c = salesTax.Id;
        appTax.Sales_Tax_Item__c =salesTaxItem.Id;
        DMLUtility.insertSobjectList('Applicable_Taxes__c', appTax);


        Unit_Price_Cost__c adjstmentRec = TestDataFactory.createDealUnitPriceCost(unitRec.Id, category.Id, vendor.Id, customer.Id, salesTax.Id);
        

    }
    
    @isTest
    private static void QBCreditMemoDTOTestOne(){
        String query = 'SELECT ' + String.join(AccountingUnitPriceAndCost.fieldsList(), ',') + ' From Unit_Price_Cost__c Limit 1  ';
        
        Unit_Price_Cost__c adjstmentRec = Database.query(query);
        
        AccountingUnitPriceAndCost adjstmentRecObj = new AccountingUnitPriceAndCost(adjstmentRec);
        Test.startTest();
        QBCreditMemoDTO qbObj = new QBCreditMemoDTO(adjstmentRecObj);
        System.assertEquals(adjstmentRec.AccountingId__c, qbObj.Id);
        Test.stopTest();
    }

    @isTest
    private static void QBCreditMemoDTOTest(){
        String query = 'SELECT ' + String.join(AccountingUnit.fieldsList(), ',') + ' From Customer_Owned_Unit__c where Referenced_Unit__c != null ';
        Customer_Owned_Unit__c coUnit = Database.query(query);
        
        Test.startTest();
        AccountingUnit accUnitObj = new AccountingUnit(coUnit);
        QBCreditMemoDTO qbObj = new QBCreditMemoDTO(accUnitObj);
        Test.stopTest();
        System.assertEquals(coUnit.QB_Consignment_Accounting_Id__c, qbObj.Id);
        
    }
}

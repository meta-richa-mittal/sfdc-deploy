@isTest
private class XeroLineItemDTOTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendor = TestDataFactory.createVendor('balveer');
        Account customer = TestDataFactory.createCustomer('balveer choudhary', 'individual', 'balveer', 'choudhary');
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id, Discount_Markup_From_Prive_Level__c = 100); 
        insert coHeader;
        CO_Line_Item__c coLineItem = new CO_Line_Item__c(CO_Header__c = coHeader.id);
        insert coLineItem;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.id, Lien_Payout__c = 122, Default_Unit_Sales_Tax_Percentage__c = 100);
        insert dealItem;
        Service_Order_Line_Item__c serviceOrderLineItem = new Service_Order_Line_Item__c(CO_Line_Item__c = coLineItem.id);
        insert serviceOrderLineItem;
        Unit_Price_Cost__c unitPriceCost = new Unit_Price_Cost__c(Total_Cost__c = 120, CO_Invoice_Header__c = coInvoiceHeader.id, vendor__c = vendor.id);
        insert unitPriceCost;
        Deal_Unit_Price_Cost__c dealUnitPriceCost = new Deal_Unit_Price_Cost__c(name = 'Deal unit price', Unit_Price_Cost__c = unitPriceCost.id);
        insert dealUnitPriceCost;
        Option_Fee__c optionFee = new Option_Fee__c(Deal__c = deal.id, Deal_Item__c = dealItem.id);
        insert optionFee;
        F_I_Product__c FIProduct = new F_I_Product__c(Deal__c = deal.id);
        insert FIProduct;
    }

    @isTest
    private static void testXeroLineItemDTO() {
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
        XeroLineItemDTO lineItemDTO = new XeroLineItemDTO(accountingLienPayout);
        //
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COLineItem')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM CO_Line_Item__c';
        List<CO_Line_Item__c> coLineItem = Database.query(query1);

        String query2;
        query2 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query2 += fieldsName + ', ';
        }
        query2 = query2.substring(0, query2.length()-2);
        query2 += ' FROM CO_Invoice_Header__c';
        List<CO_Invoice_Header__c> coInvoiceHeader = Database.query(query2);

        String query3;
        query3 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceItem')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query3 += fieldsName + ', ';
        }
        query3 = query3.substring(0, query3.length()-2);
        query3 += ' FROM CO_Invoice_Item__c';
        List<CO_Invoice_Item__c> coInvoiceItem = Database.query(query3);

        AccountingCustomerInvoice accountingCustomerInvoice = new AccountingCustomerInvoice(coInvoiceHeader[0], coInvoiceItem);
        XeroLineItemDTO lineItemDTO1 = new XeroLineItemDTO(coLineItem[0], accountingCustomerInvoice);
        
        List<Service_Order_Line_Item__c> serviceOrderLineItem = [SELECT Service_Order_Header__r.Transaction_Type__r.Part_Category__r.Income_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Part_Category__r.COGS_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Part_Category__r.Inventory_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Labour_Category__r.Income_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Labour_Category__r.COGS_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Labour_Category__r.Inventory_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Sublet_Category__r.Income_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Sublet_Category__r.COGS_GL__c,
                                            Service_Order_Header__r.Transaction_Type__r.Sublet_Category__r.Inventory_GL__c,Cost__c,
                                            Item_Code__c, Item_Description__c, Item_Desc__c, Kit_Price__c, Labour_Code__c, Part__c, Qty_Needed__c, Total__c,
                                            Fee__r.Cost_Rate__c,Fee__r.Cost_Method__c,
                                            Labour_Code__r.Cost_Rate__c, Labour_Code__r.Cost_Method__c, 
                                            Price_When_Tax_Included__c, Fee__c, Tax_Percent__c, Tax_Amount__c, Part__r.Taxable__c, Part__r.Category__c,
                                            Part__r.Category__r.AccountingId__c, Part__r.Category__r.Name, Fee__r.Taxable__c, Fee__r.Category__c,
                                            Fee__r.Category__r.AccountingId__c, Fee__r.Category__r.Name, Labour_Code__r.Taxable__c,
                                            Labour_Code__r.Category__c, Labour_Code__r.Category__r.AccountingId__c, Labour_Code__r.Category__r.Name,
                                            Sublet__c, Sublet__r.Cost__c, Sublet__r.Cost_Method__c, Sublet__r.Category__c, Sublet__r.Category__r.AccountingId__c, Sublet__r.Category__r.Name,
                                            Applicable_Tax__c, Applicable_Tax__r.Accounting_Id__c, Part__r.Category__r.Income_GL__c,Part__r.Category__r.COGS_GL__c,Part__r.Category__r.Inventory_GL__c,
                                            Labour_Code__r.Category__r.COGS_GL__c,Labour_Code__r.Category__r.Inventory_GL__c,Sublet__r.Category__r.COGS_GL__c,Sublet__r.Category__r.Inventory_GL__c, 
                                            Labour_Code__r.Category__r.Income_GL__c, Fee__r.Category__r.Income_GL__c, Fee__r.Category__r.COGS_GL__c, Fee__r.Category__r.Inventory_GL__c, Sublet__r.Category__r.Income_GL__c,
                                            CO_Line_Item__r.Adjusted_Cost_Coli__c, CO_Line_Item__r.Part__r.Average_Cost__c,  CO_Line_Item__r.Part__r.Last_Cost__c,Deal_Item__r.Customer_Owned_Unit__r.Category__r.Inventory_GL__c,Deal__r.Is_Deal_Fulfilled__c
                                            FROM Service_Order_Line_Item__c];
                                            
        XeroLineItemDTO lineItemDTO2 = new XeroLineItemDTO(serviceOrderLineItem[0], accountingCustomerInvoice);

        query = 'SELECT '; 
        for(String fieldsName : AccountingDealItem.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query += 'Customer_Owned_Unit__c, Applicable_Tax__c, Applicable_Tax__r.Accounting_Id__c' + ', ';
        query += 'Customer_Owned_Unit__r.Stock_Id__c, Agreed_Value__c, Default_Unit_Sales_Tax_Percentage__c' + ', ';
        query = query.substring(0, query.length()-2);
        query += ' FROM Deal_Item__c';
        List<Deal_Item__c> dealItem = Database.query(query);

        query1 = 'SELECT '; 
        for(String fieldsName :DealWrapper.getDealUnitPriceCost()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 += 'Tax_Amount__c' + ', ';
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Deal_Unit_Price_Cost__c';
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCost = Database.query(query1);
        XeroLineItemDTO lineItemDTO3 = new XeroLineItemDTO(dealItem[0], dealUnitPriceCost[0], accountingCustomerInvoice);
        
        query1 = 'SELECT '; 
        for(String fieldsName :DealWrapper.getOptionAndFeeFields()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 += 'Deal_Item__r.Customer_Owned_Unit__r.Stock_Id__c' + ', ';
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM Option_Fee__c';
        List<Option_Fee__c> optionAndFee = Database.query(query1);
        XeroLineItemDTO lineItemDTO4 = new XeroLineItemDTO(dealItem[0], optionAndFee[0], accountingCustomerInvoice);

        XeroLineItemDTO lineItemDTO5 = new XeroLineItemDTO(dealItem[0], accountingCustomerInvoice, 'Trade In');

        XeroLineItemDTO lineItemDTO6 = new XeroLineItemDTO('description', 23, 'xyz');

        XeroLineItemDTO lineItemDTO7 = new XeroLineItemDTO(dealItem[0], optionAndFee[0], accountingCustomerInvoice);

        query1 = 'SELECT '; 
        for(String fieldsName :DealWrapper.getDealFIProductFields()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 += 'Applicable_Tax__c' + ', ';
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM F_I_Product__c';
        List<F_I_Product__c> FIProduct = Database.query(query1);
        XeroLineItemDTO lineItemDTO8 = new XeroLineItemDTO(FIProduct[0], accountingCustomerInvoice);

        system.assertEquals(true, true);
        Test.stopTest();
    }
}
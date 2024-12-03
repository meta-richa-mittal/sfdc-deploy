global without sharing class PopulatePreTaxInvoiceTotalBatch extends PostInstallScriptBaseBatch {

    public String datetimeValue;
    global PopulatePreTaxInvoiceTotalBatch(String datetimeValue) {
        this.scriptName = 'runPopulatePreTaxInvoiceTotalBatch_V2()';
        if(datetimeValue != null){
            this.datetimeValue = datetimeValue;
        } else { throw new BlackPurlException('Date value is null');
        }
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
    	return Database.getQueryLocator('SELECT Id, Name, Total_Payment__c, CO_Header__r.Customer__r.Total_Store_Credit__c, Invoice_Status__c,' +
        ' (SELECT CO_Line_Item__c, Service_Order_Header__c, CO_Kit_Header__c, Deal__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName ' +
        ' FROM CO_Invoice_Items__r where Deal__c != null) FROM CO_Invoice_Header__c where Is_Deal_Invoiced__c = true and SalesTax_Total__c != null and SalesTax_Total__c != 0 and Taxable_Total__c = 0 and Invoice_Status__c = \'Closed\' and Closed_Invoice_Date__c > '+ this.datetimeValue );
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> invoiceList) {
        Map<Id,CO_Invoice_Header__c> invoiceIdToRecMap = new Map<Id,CO_Invoice_Header__c>();
        Map<Id,List<Id>> invoiceIdToDealIdMap = new Map<Id,List<Id>>();
        List<Id> dealIdList = new List<Id>();
        List<Option_Fee__c> optionFeeList = new List<Option_Fee__c>();
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = new List<Deal_Unit_Price_Cost__c>();
        List<F_I_Product__c> fAndIProductList = new List<F_I_Product__c>();
        Map<Id,List<Option_Fee__c>> invoiceIdToOptionFeeMap = new Map<Id,List<Option_Fee__c>>();
        Map<Id,List<Deal_Item__c>> invoiceIdToDealItemMap = new Map<Id,List<Deal_Item__c>>();
        Map<Id,List<Deal_Unit_Price_Cost__c>> invoiceIdToDealUPCMap = new Map<Id,List<Deal_Unit_Price_Cost__c>>();
        Map<Id,List<F_I_Product__c>> invoiceIdToFIProductMap = new Map<Id,List<F_I_Product__c>>();
        Map<Id, List<Individual_Tax__c>> invoiceIdToIndividualTaxForDealList = new Map<Id, List<Individual_Tax__c>>();

        for(CO_Invoice_Header__c coInvoiceRec: (List<CO_Invoice_Header__c>) invoiceList){
            invoiceIdToRecMap.put(coInvoiceRec.Id, coInvoiceRec);
            for(CO_Invoice_Item__c invoiceItemRec: coInvoiceRec.CO_Invoice_Items__r){
                dealIdList.add(invoiceItemRec.Deal__c);
                if(!invoiceIdToDealIdMap.containsKey(coInvoiceRec.Id)) {
                    invoiceIdToDealIdMap.put(coInvoiceRec.Id, new List<Id>());
                }
                invoiceIdToDealIdMap.get(coInvoiceRec.Id).add(invoiceItemRec.Deal__c);
            }
        }
        if(dealIdList.size()>0){
            if(!GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                for(Individual_Tax__c individualTax : [Select Id, Deal__r.Invoice_Number__c, Sales_Tax_Item__c, Tax_Rate__c, Enhanced_Tax_Amount__c FROM Individual_Tax__c WHERE Deal__c IN: dealIdList]) {
                    if(!invoiceIdToIndividualTaxForDealList.containsKey(individualTax.Deal__r.Invoice_Number__c)) {
                        invoiceIdToIndividualTaxForDealList.put(individualTax.Deal__r.Invoice_Number__c, new List<Individual_Tax__c>());
                    }
                    invoiceIdToIndividualTaxForDealList.get(individualTax.Deal__r.Invoice_Number__c).add(individualTax);
                }
            }
            optionFeeList = [SELECT Price__c,Deal__c,Deal__r.Invoice_Number__c, Qty__c, Part__c, Fee__c, Labour_Code__c, Product__c, Product__r.Type__c, 
                            Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Product__r.Cost__c, Product__r.Cost_Method__c, Deal_Item__r.Taxable__c, Deal_Item__r.Unit_Tax_Applicable_On__c,
                            Deal_Kit_Header__c, Fee__r.Is_Include_In_Profit_Calculation__c, Cost__c, Price_When_Tax_Included__c,Applicable_Tax__c, 
                            Part__r.Taxable__c, Fee__r.Taxable__c , Labour_Code__r.Taxable__c , Product__r.Taxable__c ,
                            (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                                from Option_Fee__c where Deal__c IN: dealIdList];

            dealItemList = [SELECT Agreed_Value__c,Deal__c,Deal__r.Invoice_Number__c, Actual_Cash_Value__c, Default_Unit_Sales_Tax_Percentage__c, Type__c, Lien_Payout__c, Stamp_Duty_Total__c, 
                                Deal__r.Total_Commission_Cost__c, Deal__r.Deal_Commission__c, Taxable__c , Unit_Tax_Applicable_On__c,Applicable_Tax__c,
                                (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0)
                                from Deal_Item__c WHERE (Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN OR Lien_Payout__c > 0 OR Stamp_Duty_Total__c != null) AND Deal__c IN: dealIdList];
            
            dealUnitPriceAndCostList = [Select Qty__c, Price__c, Type__c, Total_Cost__c, Unit_Price_Cost__r.Total_Cost__c, Deal_Item__r.Deal__r.Total_Commission_Cost__c, Deal_Item__r.Deal__r.Deal_Commission__c, 
                                        Deal_Item__r.Taxable__c,Deal_Item__r.Deal__c,Deal_Item__r.Deal__r.Invoice_Number__c,Applicable_Tax__c,
                                        (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                                        from Deal_Unit_Price_Cost__c where Deal_Item__r.Deal__c IN: dealIdList];
                            
            fAndIProductList = [Select Price__c,Deal__c,Deal_Finance__r.Deal__c,Deal_Finance__r.Deal__r.Invoice_Number__c, Sales_Tax__c, Cost__c,Vendor_Product__r.Taxable__c,Applicable_Tax__c, (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                            from F_I_Product__c where Deal__c IN: dealIdList OR Deal_Finance__r.Deal__c IN: dealIdList];
        }

        for(Option_Fee__c opfeeRec: optionFeeList){
            if(!invoiceIdToOptionFeeMap.containsKey(opfeeRec.Deal__r.Invoice_Number__c)) {
                invoiceIdToOptionFeeMap.put(opfeeRec.Deal__r.Invoice_Number__c, new List<Option_Fee__c>());
            }
            invoiceIdToOptionFeeMap.get(opfeeRec.Deal__r.Invoice_Number__c).add(opfeeRec);
        }

        for(Deal_Item__c dealItemRec: dealItemList){
            if(!invoiceIdToDealItemMap.containsKey(dealItemRec.Deal__r.Invoice_Number__c)) {
                invoiceIdToDealItemMap.put(dealItemRec.Deal__r.Invoice_Number__c, new List<Deal_Item__c>());
            }
            invoiceIdToDealItemMap.get(dealItemRec.Deal__r.Invoice_Number__c).add(dealItemRec);
        }

        for(Deal_Unit_Price_Cost__c dealUPCRec: dealUnitPriceAndCostList){
            if(!invoiceIdToDealUPCMap.containsKey(dealUPCRec.Deal_Item__r.Deal__r.Invoice_Number__c)) {
                invoiceIdToDealUPCMap.put(dealUPCRec.Deal_Item__r.Deal__r.Invoice_Number__c, new List<Deal_Unit_Price_Cost__c>());
            }
            invoiceIdToDealUPCMap.get(dealUPCRec.Deal_Item__r.Deal__r.Invoice_Number__c).add(dealUPCRec);
        }

        for(F_I_Product__c fIProductRec: fAndIProductList){
            if(!invoiceIdToFIProductMap.containsKey(fIProductRec.Deal_Finance__r.Deal__r.Invoice_Number__c)) {
                invoiceIdToFIProductMap.put(fIProductRec.Deal_Finance__r.Deal__r.Invoice_Number__c, new List<F_I_Product__c>());
            }
            invoiceIdToFIProductMap.get(fIProductRec.Deal_Finance__r.Deal__r.Invoice_Number__c).add(fIProductRec);
        }
        

        List<CO_Invoice_Header__c> coinvoiceList = new List<CO_Invoice_Header__c>();
        for(Id invoiceId: invoiceIdToDealIdMap.keySet()){
            CO_Invoice_Header__c coInvoiceRec = COService.populatePreTaxTotals(invoiceIdToRecMap.get(invoiceId), new List<CO_Line_Item__c>(), new List<Service_Order_Line_Item__c>(),
                                        invoiceIdToOptionFeeMap.get(invoiceId),invoiceIdToDealItemMap.get(invoiceId),
                                        invoiceIdToDealUPCMap.get(invoiceId),invoiceIdToFIProductMap.get(invoiceId), invoiceIdToIndividualTaxForDealList.get(invoiceId));
            coinvoiceList.add(coInvoiceRec);
        }
        COInvoiceTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('CO_Invoice_Header__c',coinvoiceList);
        COInvoiceTriggerHelper.isForceStopTrigger = false;
    }

    global override void finishScript(Database.BatchableContext bc) {}
}
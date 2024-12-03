/** 
* Author: Manoj Sharma
* Since: Aug 02, 2021
* Name: PrintCustomerOrderInvoiceService 
* Description: Apex service class which contains print invoice methods.
**/
public without sharing class PrintCustomerOrderInvoiceService {

    public static CO_Invoice_Header__c calculateInvoicePreviewTotals(List<CO_Invoice_Header__c> coInvoiceList,  List<Id> coliIds, List<Id> sohIds, List<Id> soPaymentRoleIds, List<Id> cokhIds, List<Id> dealIds, String invoiceType) {
        if(coInvoiceList.size() == 0) {
            return new CO_Invoice_Header__c();
        }
        CO_Invoice_Header__c coInvoice = coInvoiceList[0]; 
        
        List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        List<SO_Payment_Role__c> soPaymentRoleList = new List<SO_Payment_Role__c>();
        List<CO_Kit_Header__c> coKitHeaderList = new List<CO_Kit_Header__c>();
        List<Deal__c> dealList = new List<Deal__c>();
        
        if(coliIds.size() > 0) {
            coliList = [SELECT Item_ID__c, Part__c, Fee__c, Qty__c, Qty_Committed__c, Price__c, Deal__c, Price_When_Tax_Included__c, Actual_Retail_Price__c, Status__c,
                             CO_Header__r.Order_status__c, Part__r.Non_Inventory_Part__c FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND Id IN: coliIds];
        }
                                             
        if(sohIds.size() > 0) {                                   
            soHeaderList =  [select Total_Parts__c, Total_Fees__c, Total_Labor__c, Total_Sublet__c, Total_Shop_Supplies__c, Total_Discount__c,Transaction_Type__r.Type__c, (SELECT Id, Kit_Price__c, Labour_Code__c, 
                                      Part__c, Sublet__c, Qty_Needed__c, Total__c, Fee__c, Tax_Percent__c, Tax_Amount__c FROM Service_Order_Line_Items__r), (SELECT Id, RecordType.DeveloperName, Total_Amount__c FROM SO_Payment_Roles__r where RecordType.DeveloperName = 'Deductible') 
                                FROM Service_Order_Header__c WHERE Id IN: sohIds];
        }
        
        if(soPaymentRoleIds.size() > 0) {
            soPaymentRoleList =  [SELECT Id, Service_Order_Header__c, RecordType.DeveloperName, Total_Amount__c FROM SO_Payment_Role__c WHERE Id IN: soPaymentRoleIds];
        }
                                                                          
        if(cokhIds.size() > 0) {                                   
            coKitHeaderList =  [select Id, Total_Discount__c, Deal__c, Price__c, Tax_Amount__c, (SELECT Id, Part__c, Fee__c, Qty__c, Price__c, 
                                        Deal__c, Sub_Total_Without_Tax__c, Price_When_Tax_Included__c, Tax__c, Sub_Total_With_Tax__c
                                        FROM CO_Line_Items__r) FROM CO_Kit_Header__c WHERE Id IN: cokhIds];
        }
        
        if(dealIds.size() > 0) {                                   
            dealList =  [select Id, Part_Total__c, Labour_Total__c, Fee_Total__c, Lien_Payout_Total__c, Warranty_Product_Total__c, Sublet_Total__c, 
                            Other_Product_Total__c, Trade_In_Total__c, Trade_In_Tax_Total__c, Unit_Price_And_Cost_Total__c, Type__c, F_I_Total__c, F_I_Tax_Total__c, 
                            Product_Total__c, Stamp_Duty_Total__c, Deal_Commission__c, Salesperson_Name__c
                            FROM Deal__c 
                            WHERE Id IN: dealIds];
        }
                                                                        
        boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal partTotal = 0;
        Decimal labourTotal = 0;
        Decimal feeTotal = 0;
        Decimal lienPayoutTotal = 0;
        Decimal subletTotal = 0;
        Decimal unitTotal = 0;
        Decimal tradeInsTotal = 0;
        Decimal tradeInsTaxTotal = 0;
        Decimal warrantyProductTotal = 0;
        Decimal stampDutyTotal = 0;
        Decimal otherProductTotal = 0;
        Decimal productTotal = 0;
        Decimal shopSupplyTotal = 0;
        Decimal salesTaxTotal = 0;
        Decimal totalDiscount = 0;
        Decimal deductibleTotal = 0;
        Decimal fandIProductTotal = 0;
        Decimal dealCommission = 0;
        String salesperson = '';
        
        for(CO_Line_Item__c coli : coliList) {
            coli.Price__c = (coli.Price__c != null) ? coli.Price__c : 0;
            coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
            coli.Actual_Retail_Price__c = (coli.Actual_Retail_Price__c != null) ? coli.Actual_Retail_Price__c : 0;
            Decimal discount = 0;
            if(coli.Part__c != null) {
                coli.Qty_Committed__c = (coli.Qty_Committed__c != null) ? coli.Qty_Committed__c : 0;
                Decimal qty = (!coli.Part__r.Non_Inventory_Part__c && coli.Qty__c > 0 && coli.CO_Header__r.Order_status__c != 'Quote') ? coli.Qty_Committed__c : coli.Qty__c;
                
                if(!isTaxIncludingPricing || String.isNotBlank(coli.Deal__c)) {
                    partTotal += (qty * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    if(qty > 0) {
                        discount = (coli.Actual_Retail_Price__c - coli.Price__c) * qty;
                    }
                } else {
                    if(coli.Price_When_Tax_Included__c == null) {
                        coli.Price_When_Tax_Included__c = 0;
                    }
                    partTotal += (qty * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    if(qty > 0) {
                        discount = (coli.Actual_Retail_Price__c - coli.Price_When_Tax_Included__c) * qty;
                    }
                }
                totalDiscount += (discount > 0) ? discount : 0;
            
            } else if(coli.Fee__c != null) {
                if(!isTaxIncludingPricing) {
                    feeTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    feeTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                }
            }
        }
        
        Set<Id> soIdsToIncludeTax = new Set<Id>();
        
        for(SO_Payment_Role__c soPaymentRoleRec : soPaymentRoleList) {
            if(soPaymentRoleRec.RecordType.DeveloperName != 'Deductible' ) {
                soIdsToIncludeTax.add(soPaymentRoleRec.Service_Order_Header__c);
            }
        }
        
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            soIdsToIncludeTax.add(soHeaderRec.Id);
            partTotal += (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c.setScale(2, RoundingMode.HALF_UP) : 0;
            feeTotal += (soHeaderRec.Total_Fees__c != null) ? soHeaderRec.Total_Fees__c.setScale(2, RoundingMode.HALF_UP) : 0;
            labourTotal += (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c.setScale(2, RoundingMode.HALF_UP) : 0;
            subletTotal += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c.setScale(2, RoundingMode.HALF_UP) : 0;
            productTotal += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c.setScale(2, RoundingMode.HALF_UP) : 0;
            shopSupplyTotal += (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c.setScale(2, RoundingMode.HALF_UP) : 0;
            totalDiscount += ((soHeaderRec.Total_Discount__c != null) && (soHeaderRec.Total_Discount__c > 0)) ? soHeaderRec.Total_Discount__c : 0;
            if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party' && soHeaderRec.SO_Payment_Roles__r.size() > 0) {
                deductibleTotal += (soHeaderRec.SO_Payment_Roles__r[0].Total_Amount__c != null) ? -1 * (soHeaderRec.SO_Payment_Roles__r[0].Total_Amount__c.setScale(2, RoundingMode.HALF_UP)) : 0;
                soPaymentRoleIds.add(soHeaderRec.SO_Payment_Roles__r[0].Id);
            }
        }
                
        for(CO_Kit_Header__c coKitHeader : coKitHeaderList) {
            for(CO_Line_Item__c coli : coKitHeader.CO_Line_Items__r){
                if(coli.Part__c != null && coli.Qty__c != null && coli.Price__c != null){
                    if(!isTaxIncludingPricing || (isTaxIncludingPricing && coKitHeader.Deal__c != null)) {
                        partTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    }else if(coli.Sub_Total_With_Tax__c != null) {
                        partTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    }
                } else if(coli.Fee__c != null && coli.Qty__c != null && coli.Price__c != null){
                    if(!isTaxIncludingPricing || (isTaxIncludingPricing && coKitHeader.Deal__c != null)) {
                        feeTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    }else if(coli.Sub_Total_With_Tax__c != null){
                        feeTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            totalDiscount += ((coKitHeader.Total_Discount__c != null) && (coKitHeader.Total_Discount__c > 0)) ? coKitHeader.Total_Discount__c : 0;
        }
        
        for(Deal__c dealRec : dealList) {
            unitTotal += (dealRec.Unit_Price_And_Cost_Total__c != null) ? dealRec.Unit_Price_And_Cost_Total__c : 0;
            partTotal += (dealRec.Part_Total__c != null) ? dealRec.Part_Total__c : 0;
            feeTotal += (dealRec.Fee_Total__c != null) ? dealRec.Fee_Total__c : 0;
            lienPayoutTotal += (dealRec.Lien_Payout_Total__c != null) ? dealRec.Lien_Payout_Total__c : 0;
            labourTotal += (dealRec.Labour_Total__c != null) ? dealRec.Labour_Total__c : 0;
            tradeInsTotal += (dealRec.Trade_In_Total__c != null) ? dealRec.Trade_In_Total__c : 0;
            tradeInsTaxTotal += dealRec.Trade_In_Tax_Total__c != null ? dealRec.Trade_In_Tax_Total__c : 0;
            warrantyProductTotal += (dealRec.Warranty_Product_Total__c != null) ? dealRec.Warranty_Product_Total__c : 0;
            subletTotal += (dealRec.Sublet_Total__c != null) ? dealRec.Sublet_Total__c : 0;
            otherProductTotal += (dealRec.Other_Product_Total__c != null) ? dealRec.Other_Product_Total__c : 0;
            productTotal += (dealRec.Product_Total__c != null) ? dealRec.Product_Total__c : 0;
            stampDutyTotal += (dealRec.Stamp_Duty_Total__c != null) ? dealRec.Stamp_Duty_Total__c : 0;
            dealCommission = (dealRec.Deal_Commission__c != null) ? dealRec.Deal_Commission__c : 0;
            salesperson = dealRec.Salesperson_Name__c;
            
            if(dealRec.Type__c == Constants.FINANCED) {
                fandIProductTotal += (dealRec.F_I_Total__c != null) ? dealRec.F_I_Total__c : 0;
                if(isTaxIncludingPricing) {
                    fandIProductTotal += (dealRec.F_I_Tax_Total__c != null) ? dealRec.F_I_Tax_Total__c : 0;
                }
            }
        }
        
        TaxCalculation.isInvoiced = (coInvoice.Invoice_Status__c == 'Active') ? false : true;
        List<Individual_Tax__c> individualItemsList = COService.getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, coliIds, cokhIds, 
                                                                    soIdsToIncludeTax, dealIds, soPaymentRoleIds);
        
        Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList, invoiceType);
        TaxCalculation.isInvoiced = true;
        for(String taxName : salesTaxNameToTaxValue.keySet()) {
            salesTaxTotal += salesTaxNameToTaxValue.get(taxName); 
        }
                                             
        coInvoice.Part_Total__c = partTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Labour_Total__c = labourTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Fee_Total__c = feeTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Lien_Payout_Total__c = lienPayoutTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Sublet_Total__c = subletTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Stamp_Duty_Total__c = stampDutyTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Unit_Total__c = unitTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Shop_Supplies_Total__c = shopSupplyTotal.setScale(2, RoundingMode.HALF_UP);
        
        coInvoice.Trade_In_Total__c = tradeInsTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Trade_In_Tax_Total__c = tradeInsTaxTotal.setScale(2, RoundingMode.HALF_UP); //Only to exclude in profitability
        
        coInvoice.Warranty_Product_Total__c = warrantyProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Other_Product_Total__c = otherProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Product_Total__c = productTotal.setScale(2, RoundingMode.HALF_UP);
        
        coInvoice.SalesTax_Total__c = salesTaxTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Discount_Amount__c = totalDiscount.setScale(2, RoundingMode.HALF_UP);
        coInvoice.F_I_Total__c = fandIProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Deductible_Total__c = deductibleTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Deal_Commission__c = dealCommission.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Salesperson__c = salesperson;
        coInvoice.Total__c = coInvoice.Part_Total__c + coInvoice.Labour_Total__c + coInvoice.Fee_Total__c + coInvoice.Lien_Payout_Total__c 
        								+ unitTotal + coInvoice.Trade_In_Total__c + coInvoice.Product_Total__c + coInvoice.Stamp_Duty_Total__c 
                                        + coInvoice.Shop_Supplies_Total__c + coInvoice.Deductible_Total__c + coInvoice.F_I_Total__c;
        if(!isTaxIncludingPricing){
            coInvoice.Total__c += coInvoice.SalesTax_Total__c;
        }
        return coInvoice;
    }
}
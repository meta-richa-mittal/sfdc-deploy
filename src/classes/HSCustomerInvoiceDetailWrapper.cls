/**
 * Author: Manoj Sharma
 * Since: May 20, 2020
 * Name: HSCustomerInvoiceDetailWrapper
 * Description: Class used to create json for customer invoive detail home search.
 * 
**/
global without sharing class HSCustomerInvoiceDetailWrapper  {
    public Integer Type;
    public String Id;
    public String Invoice_Number;
    public String Invoice_Date;
    public String Customer_Name;
    public String Salesperson;
    public String Sale_Type;
    public String Item_Type;
    public String Item_Description;
    public Decimal QTY;
    public Decimal Total_Price;
    public Decimal Total_Cost;
    public Decimal Total_Profit;
    public Decimal Total_Gross_Pct;
    public Decimal Part_Sales;
    public Decimal Labor_Sales;
    public Decimal Sublet_Sales;
    public Decimal Fee_Sales;
    public Decimal Supplies_Sales;
    public Decimal Unit_Base_Sales;
    public Decimal Unit_Factory_Sales;
    public Decimal Unit_Dealer_Sales;
    public Decimal Option_Part_Sales;
    public Decimal Option_Labor_Sales;
    public Decimal Option_Sublet_Sales;
    public Decimal Option_Fee_Sales;
    public Decimal Option_Warranty_Sales;
    public Decimal Option_Product_Sales;
    public Decimal Trade_ins;
    public Decimal Finance_Product_Sales;
    public Decimal Finance_Commission;
    public Decimal Sales_Commission;
    public Decimal Lien_Payouts;
    
    public HSCustomerInvoiceDetailWrapper(CO_Line_Item__c coLineItemRec) {
        this.Id = coLineItemRec.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(coLineItemRec.Invoice_Number__r.Invoice_Number__c) ? coLineItemRec.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(coLineItemRec.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = coLineItemRec.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(coLineItemRec.Invoice_Number__r.Salesperson__c) ? coLineItemRec.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = coLineItemRec.Deal__c != null ? 'Parts - Deal' : 'Parts - Customer';
        this.Item_Description = (String.isNotBlank(coLineItemRec.Item_Code__c) ? coLineItemRec.Item_Code__c : '') + ' - ' + (String.isNotBlank(coLineItemRec.Item_Description__c) ? coLineItemRec.Item_Description__c : '');
        this.QTY = coLineItemRec.Qty__c != null ? coLineItemRec.Qty__c : 0;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = coLineItemRec.Revenue__c != null ? coLineItemRec.Revenue__c : 0;
        this.Total_Cost = coLineItemRec.Total_Cost__c != null ? coLineItemRec.Total_Cost__c : 0;
        this.Total_Profit = coLineItemRec.Total_Profit__c != null ? coLineItemRec.Total_Profit__c : 0;
        this.Item_Type = coLineItemRec.Item_Type__c != null ? (coLineItemRec.Item_Type__c == 'Labour' ? 'Labor' : coLineItemRec.Item_Type__c) : '';
        if(coLineItemRec.Part__c != null) {
            this.Item_Type = 'Part';
        } else if(coLineItemRec.Fee__c != null) {
            this.Item_Type = 'Fee';
        } else {
            this.Item_Type = 'Labor';
        }
        if(coLineItemRec.Part__c != null) {
            this.Part_Sales = coLineItemRec.Pre_Tax_Part_Sales__c;
        } else if(coLineItemRec.Fee__c != null) {
            this.Fee_Sales = coLineItemRec.Pre_Tax_Fee_Sales__c;
        }
        if(coLineItemRec.Revenue__c != null && coLineItemRec.Revenue__c != 0) {
            this.Total_Gross_Pct = ((this.Total_Profit / coLineItemRec.Revenue__c) * 100).setScale(1, System.RoundingMode.UP);
        } else if (this.Total_Profit != 0 && coLineItemRec.Revenue__c != null && coLineItemRec.Revenue__c == 0) {
            this.Total_Gross_Pct = -100;
        } else {
            this.Total_Gross_Pct = 0;
        }
        
    } 
    public HSCustomerInvoiceDetailWrapper(Service_Order_Line_Item__c soLineItemRec) {
        this.Id = soLineItemRec.Service_Order_Header__r.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(soLineItemRec.Service_Order_Header__r.Invoice_Number__r.Invoice_Number__c) ? soLineItemRec.Service_Order_Header__r.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(soLineItemRec.Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = soLineItemRec.Service_Order_Header__r.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(soLineItemRec.Service_Order_Header__r.Invoice_Number__r.Salesperson__c) ? soLineItemRec.Service_Order_Header__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
        if(soLineItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Customer') {
            this.Sale_Type = 'Service - Customer';
        } else if (soLineItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party'){
            this.Sale_Type = 'Service - Third-Party';
        } else if (soLineItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Internal'){
            this.Sale_Type = 'Service - Internal';
        } else if (soLineItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Deal Service'){
            this.Sale_Type = 'Service - Deal Option';
        } else if (soLineItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit'){
            this.Sale_Type = 'Service - Stock Unit';
        } else {
            this.Sale_Type = '';
        }

        if(soLineItemRec.Part__c != null) {
            this.Item_Type = 'Part';
            this.Part_Sales = soLineItemRec.Pre_Tax_Part_Sales__c;
        } else if(soLineItemRec.Labour_Code__c != null) {
            this.Item_Type = 'Labor';
            this.Labor_Sales = soLineItemRec.Pre_Tax_Labor_Sales__c;
        } else if(soLineItemRec.Sublet__c != null) {
            this.Item_Type = 'Sublet';
            this.Sublet_Sales = soLineItemRec.Pre_Tax_Sublet_Sales__c;
        } else if(soLineItemRec.Fee__c != null && soLineItemRec.Type__c == 'Shop Supply') {
            this.Item_Type = 'Supplies';
            this.Supplies_Sales = soLineItemRec.Pre_Tax_Supplies_Sales__c;
        }else if (soLineItemRec.Fee__c != null){
            this.Item_Type = 'Fee';
            this.Fee_Sales = soLineItemRec.Pre_Tax_Fee_Sales__c;
        } else {
            this.Item_Type = '';
        }  

        this.Item_Description = String.isNotBlank(soLineItemRec.Item_Desc__c) ? soLineItemRec.Item_Desc__c : '' + ' ' ;
        this.QTY = soLineItemRec.Qty_Needed__c != null ? soLineItemRec.Qty_Needed__c : 0;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = soLineItemRec.Revenue__c != null ? soLineItemRec.Revenue__c : 0;
        this.Total_Cost = soLineItemRec.Total_Cost__c != null ? soLineItemRec.Total_Cost__c : 0;
        this.Total_Profit = soLineItemRec.Total_Profit__c != null ? soLineItemRec.Total_Profit__c : 0;
        if(soLineItemRec.Revenue__c != null && soLineItemRec.Revenue__c != 0) {
            this.Total_Gross_Pct = ((this.Total_Profit / soLineItemRec.Revenue__c) * 100).setScale(1, System.RoundingMode.UP);
        } else if (this.Total_Profit != 0 && soLineItemRec.Revenue__c != null && soLineItemRec.Revenue__c == 0) {
            this.Total_Gross_Pct = -100;
        } else {
            this.Total_Gross_Pct = 0;
        }
    }

    public HSCustomerInvoiceDetailWrapper(Option_Fee__c optionFeeRec) {
        this.Id = optionFeeRec.Deal__r.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(optionFeeRec.Deal__r.Invoice_Number__r.Invoice_Number__c) ? optionFeeRec.Deal__r.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(optionFeeRec.Deal__r.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = optionFeeRec.Deal__r.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(optionFeeRec.Deal__r.Invoice_Number__r.Salesperson__c) ? optionFeeRec.Deal__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = 'Deal';

        if(optionFeeRec.Part__c != null) {
            this.Item_Type = 'Option-Part';
            this.Option_Part_Sales = optionFeeRec.Pre_Tax_Option_Part_Sales__c;
        } else if(optionFeeRec.Labour_Code__c != null) {
            this.Item_Type = 'Option-Labor';
            this.Option_Labor_Sales = optionFeeRec.Pre_Tax_Option_Labor_Sales__c;
        } else if(optionFeeRec.Product__c != null && optionFeeRec.Product__r.Type__c == 'Sublet') {
            this.Item_Type = 'Option-Sublet';
            this.Option_Sublet_Sales = optionFeeRec.Pre_Tax_Option_Sublet_Sales__c;
        } else if(optionFeeRec.Fee__c != null) {
            this.Item_Type = 'Option-Fee';
            this.Option_Fee_Sales = optionFeeRec.Pre_Tax_Option_Fee_Sales__c;
        }else if (optionFeeRec.Product__c != null && optionFeeRec.Product__r.Type__c == 'Warranty Plan'){
            this.Item_Type = 'Option-Warranty';
            this.Option_Warranty_Sales = optionFeeRec.Pre_Tax_Option_Warranty_Sales__c;
        } else if (optionFeeRec.Product__c != null && optionFeeRec.Product__r.Type__c !='Sublet' && optionFeeRec.Product__r.Type__c != 'Warranty Plan'){
            this.Item_Type = 'Option-Product';
            this.Option_Product_Sales = optionFeeRec.Pre_Tax_Option_Other_Product_Sales__c;
        } else {
            this.Item_Type = '';
        }  

        this.Item_Description = (String.isNotBlank(optionFeeRec.Item_Code__c) ? optionFeeRec.Item_Code__c : '') + ' - ' + (String.isNotBlank(optionFeeRec.Item_Description__c) ? optionFeeRec.Item_Description__c : '');
        this.QTY = optionFeeRec.Qty__c != null ? optionFeeRec.Qty__c : 0;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = optionFeeRec.Revenue__c != null ? optionFeeRec.Revenue__c : 0;
        this.Total_Cost = optionFeeRec.Total_Cost__c != null ? optionFeeRec.Total_Cost__c : 0;
        this.Total_Profit = optionFeeRec.Total_Profit__c != null ? optionFeeRec.Total_Profit__c : 0;
        
        if(optionFeeRec.Revenue__c != null && optionFeeRec.Revenue__c != 0) {
            this.Total_Gross_Pct = ((this.Total_Profit / optionFeeRec.Revenue__c) * 100).setScale(1, System.RoundingMode.UP);
        } else if (this.Total_Profit != 0 && optionFeeRec.Revenue__c != null && optionFeeRec.Revenue__c == 0) {
            this.Total_Gross_Pct = -100;
        } else {
            this.Total_Gross_Pct = 0;
        }
    }

    public HSCustomerInvoiceDetailWrapper(Deal_Unit_Price_Cost__c dealPriceCostRec) {
        this.Id = dealPriceCostRec.Deal_Item__r.Deal__r.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(dealPriceCostRec.Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Number__c) ? dealPriceCostRec.Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(dealPriceCostRec.Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = dealPriceCostRec.Deal_Item__r.Deal__r.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(dealPriceCostRec.Deal_Item__r.Deal__r.Invoice_Number__r.Salesperson__c) ? dealPriceCostRec.Deal_Item__r.Deal__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = 'Deal';

        if(dealPriceCostRec.Type__c == 'Base') {
            this.Item_Type = 'Unit-Base';
            this.Unit_Base_Sales = dealPriceCostRec.Pre_Tax_Base_Sales__c;
        } else if(dealPriceCostRec.Type__c == 'Dealer') {
            this.Item_Type = 'Unit-Dealer';
            this.Unit_Dealer_Sales = dealPriceCostRec.Pre_Tax_Factory_Sales__c;
        } else if(dealPriceCostRec.Type__c == 'Factory') {
            this.Item_Type = 'Unit-Factory';
            this.Unit_Factory_Sales = dealPriceCostRec.Pre_Tax_Dealer_Sales__c;
        } else {
            this.Item_Type = '';
        }  

        this.Item_Description = String.isNotBlank(dealPriceCostRec.Item_Description__c) ? dealPriceCostRec.Item_Description__c : '';
        this.QTY = dealPriceCostRec.Qty__c != null ? dealPriceCostRec.Qty__c : 0;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = dealPriceCostRec.Total_Pre_Tax_Price__c != null ? dealPriceCostRec.Total_Pre_Tax_Price__c : 0;
        this.Total_Cost = dealPriceCostRec.Total_Cost__c != null ? dealPriceCostRec.Total_Cost__c : 0;
        this.Total_Profit = dealPriceCostRec.Total_Profit__c != null ? dealPriceCostRec.Total_Profit__c : 0;
        if(dealPriceCostRec.Price__c != null && dealPriceCostRec.Qty__c != null && (dealPriceCostRec.Qty__c * dealPriceCostRec.Price__c) != 0) {
            this.Total_Gross_Pct = ((this.Total_Profit / (dealPriceCostRec.Qty__c * dealPriceCostRec.Price__c)) * 100).setScale(1, System.RoundingMode.UP);
        } else if (this.Total_Profit != 0 && dealPriceCostRec.Price__c != null && dealPriceCostRec.Qty__c != null && (dealPriceCostRec.Qty__c * dealPriceCostRec.Price__c) == 0) {
            this.Total_Gross_Pct = -100;
        } else {
            this.Total_Gross_Pct = 0;
        }
    }

    public HSCustomerInvoiceDetailWrapper(Deal_Item__c dealItemRec, String entityType) {
        if(dealItemRec.Type__c == 'Trade In') {
            this.Id =  dealItemRec.Deal__r.CO_Header__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
            this.Invoice_Number = String.isNotBlank(dealItemRec.Deal__r.Invoice_Number__r.Invoice_Number__c) ? dealItemRec.Deal__r.Invoice_Number__r.Invoice_Number__c : '';
            this.Invoice_Date =  BPUtility.getFormatedDateTime(dealItemRec.Deal__r.Invoice_Number__r.Invoice_Date__c);
            this.Customer_Name = dealItemRec.Deal__r.CO_Header__r.Customer_Name__c;
            this.Salesperson = String.isNotBlank(dealItemRec.Deal__r.Invoice_Number__r.Salesperson__c) ? dealItemRec.Deal__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
            this.Sale_Type = 'Deal';
            this.Item_Type = 'Trade-in';
            if(entityType == 'Trade In') {
                this.Item_Description = (dealItemRec.Customer_Owned_Unit__r.Year__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year__c) + ' ' : '') + (String.isNotBlank(dealItemRec.Customer_Owned_Unit__r.Make_Name__c) ? dealItemRec.Customer_Owned_Unit__r.Make_Name__c + ' ' : '') + 
                                (String.isNotBlank(dealItemRec.Customer_Owned_Unit__r.Model_Name__c) ? dealItemRec.Customer_Owned_Unit__r.Model_Name__c + ' ' : '') + (String.isNotBlank(dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c) ? dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '');
                this.QTY = -1;
                this.QTY.setscale(1, System.RoundingMode.UP);
                this.Total_Price = dealItemRec.Total_Price_With_Tax__c != null ? dealItemRec.Total_Price_With_Tax__c : 0;
                this.Total_Cost = dealItemRec.Total_Cost__c != null ? dealItemRec.Total_Cost__c : 0;
                this.Total_Profit = dealItemRec.Total_Profit__c != null ? dealItemRec.Total_Profit__c : 0;
                this.Trade_ins = dealItemRec.Total_Price__c != null ? dealItemRec.Total_Price__c : 0;
                if(dealItemRec.Pre_Tax_Agreed_Value__c != null && dealItemRec.Pre_Tax_Agreed_Value__c != 0) {
                    this.Total_Gross_Pct = ((this.Total_Profit / dealItemRec.Pre_Tax_Agreed_Value__c) * 100).setScale(1, System.RoundingMode.UP);
                } else if (this.Total_Profit != 0 && dealItemRec.Pre_Tax_Agreed_Value__c != null && dealItemRec.Pre_Tax_Agreed_Value__c == 0) {
                    this.Total_Gross_Pct = -100;
                } else {
                    this.Total_Gross_Pct = 0;
                }
            } else if(entityType == 'Lien') {
                this.Item_Description = 'Lien Payout';
                this.QTY = 1;
                this.Total_Price = this.Total_Cost = this.Lien_Payouts = dealItemRec.Lien_Payout__c != null ? dealItemRec.Lien_Payout__c : 0;
                this.Total_Profit = this.Total_Gross_Pct = 0;
            }
        }
    }

    public HSCustomerInvoiceDetailWrapper(F_I_Product__c fiProductRec) {
        this.Id =  fiProductRec.Deal_Finance__r.Deal__r.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(fiProductRec.Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Number__c) ? fiProductRec.Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(fiProductRec.Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = fiProductRec.Deal_Finance__r.Deal__r.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(fiProductRec.Deal_Finance__r.Deal__r.Invoice_Number__r.Salesperson__c) ? fiProductRec.Deal_Finance__r.Deal__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = 'Deal';
        this.Item_Type = 'Finance Product';
        this.Item_Description = String.isNotBlank(fiProductRec.Item_Description__c) ? fiProductRec.Item_Description__c : '';
        this.QTY = 1;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = fiProductRec.Price__c != null ? fiProductRec.Price__c : 0;
        this.Total_Cost = fiProductRec.Total_Cost__c != null ? fiProductRec.Total_Cost__c : 0;
        this.Total_Profit = fiProductRec.Total_Profit__c != null ? fiProductRec.Total_Profit__c : 0;
        this.Finance_Product_Sales = fiProductRec.Price__c != null ? fiProductRec.Price__c : 0;
        if(fiProductRec.Price__c != null && fiProductRec.Price__c != 0) {
            this.Total_Gross_Pct = ((this.Total_Profit / fiProductRec.Price__c) * 100).setScale(1, System.RoundingMode.UP);
        } else if (this.Total_Profit != 0 && fiProductRec.Price__c != null && fiProductRec.Price__c == 0) {
            this.Total_Gross_Pct = -100;
        } else {
            this.Total_Gross_Pct = 0;
        }
        
    }

    public HSCustomerInvoiceDetailWrapper(Deal_Finance__c financeRec, String commissionType) {
        this.Id =  financeRec.Deal__r.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(financeRec.Deal__r.Invoice_Number__r.Invoice_Number__c) ? financeRec.Deal__r.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(financeRec.Deal__r.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = financeRec.Deal__r.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(financeRec.Deal__r.Invoice_Number__r.Salesperson__c) ? financeRec.Deal__r.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = 'Deal';
        this.Item_Type = 'Finance Commission';
        this.Item_Description = commissionType;
        if(this.Item_Description == 'Financing Commission') {
            this.Total_Price = this.Total_Profit = this.Finance_Commission = financeRec.Finance_Commission__c != null ? financeRec.Finance_Commission__c : 0;
        } else if(this.Item_Description == 'Buy Rate Commission') {
            this.Total_Price = this.Total_Profit = this.Finance_Commission = financeRec.Buy_Rate_Commission__c != null ? financeRec.Buy_Rate_Commission__c : 0;
        }
        this.QTY = 1;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Cost = 0;
        this.Total_Gross_Pct = 100;
    }

    public HSCustomerInvoiceDetailWrapper(Deal__c dealRec) {
        this.Id =  dealRec.CO_Header__c;
        this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
        this.Invoice_Number = String.isNotBlank(dealRec.Invoice_Number__r.Invoice_Number__c) ? dealRec.Invoice_Number__r.Invoice_Number__c : '';
        this.Invoice_Date =  BPUtility.getFormatedDateTime(dealRec.Invoice_Number__r.Invoice_Date__c);
        this.Customer_Name = dealRec.CO_Header__r.Customer_Name__c;
        this.Salesperson = String.isNotBlank(dealRec.Invoice_Number__r.Salesperson__c) ? dealRec.Invoice_Number__r.Salesperson__c : 'Unassigned';
        this.Sale_Type = 'Deal';
        this.Item_Type = this.Item_Description = 'Sales Commission';
        this.QTY = 1;
        this.QTY.setscale(1, System.RoundingMode.UP);
        this.Total_Price = 0;
        this.Total_Cost = this.Sales_Commission = dealRec.Deal_Commission__c != null ? dealRec.Deal_Commission__c : 0;
        this.Total_Profit = this.Total_Price - this.Total_Cost;
        this.Total_Gross_Pct = -100;
    }
}
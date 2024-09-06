/**
* Author: 
* Since: July 4, 2016
* Name: PriceAndTaxWrapper
* Description: Apex class to wrap variables for price and tax section in user settings page
**/

global without sharing class PriceAndTaxWrapper {
    
    public String regionId;
    public String stateId;
    public String taxId;
    public String timezoneId;
    
    public String defaultLaborTax;
    public String defaultVendorItemTax;
    public String defaultPartTax;
    public String defaultFeeTax;
    public String orderingTaxRate;
    public String DefaultUnitTax;
    
    public boolean priceIncludeTax;
    public String defaultPriceLevel;
    public String DefaultEnvironmentalFee;
    public String DefaultSalesTaxOnInternalService;
    public String DefaultPriceLevelOnInternalService;
    public Decimal StampDutyRate;
    
    public String CustomerInvoiceWarrantyText;
    public String ServiceJobWarrantyText;
    public String OrderDepositWarrantyText;
    public String DealDocumentsWarrantyText;
    public String SalesReceiptWarrantyText;
    public Boolean IsSignatureLineforCustomerInvoice;
    public Boolean IsSignatureLineforServiceJob;
    public Boolean IsSignatureLineforOrderDeposit;
    public Boolean IsSignatureLineforDealDocuments;
    public Boolean IsSignatureLineforSalesReceipt;
    public String Period1;
    public String Period2;
    public String Period3;
    public String Period4;
    public String ApplicableFee;
    public String CalculationMethod;
    public Boolean ItemizedByLaborCode;
    public Decimal MaximumPerInvoice;
    public Decimal SuppliesRate;
    public Decimal CashPaymentRoundingFactor;
    public List<ShopSettingWrapper> shopSettingConfiguration;
    public List<PaymentMethodWrapper> PaymentMethodConfig;
    public Boolean IsHideHoursRateOnServiceJob;
    public Decimal DefaultTechnicianCostingRate;
    public Boolean TradeTaxCreditCanNotExceedUnitTax;
    public Boolean AccrueTradeTaxUntilUnitSold;
    public Boolean EnableTaxAccrualOnOrderUnitsByDefault;
    public String TradeTaxPendingSaleCategory; 
    public String TradeTaxLiabilityCategory;
    public String PurchaseTaxLiabilityCategory; 
    public String TradeTaxExpenseCategory;
    public String DefaultOdometerType;
    public Boolean IsHidePartNumbersOnDocuments;
    public Boolean IsIncludeMSRPAndDiscountOnPartLines;
    public Boolean IsEnforcePayrollPIN;
    public Boolean IsEnforceTechnicianPIN;
    public Boolean IsRecordTrackingNumbers;
    public String ShopifyTTId;
    public String ShopifyPaymentMethodId;
    public String ShopifyFeeId;
    public String ShopifyDiscountFeeId;
    public String ShopifyShippingFeeId;
    public Boolean IsAutoSelectOrdersInPartReceiving;

    public PriceAndTaxWrapper(Price_Level__c defaultPriceLevelRec, Business_Profile__c businessProfileRec){
        setConfigurationData(defaultPriceLevelRec,businessProfileRec);
    }
        
    public void setConfigurationData(Price_Level__c defaultPriceLevelRec, Business_Profile__c businessProfileRec){
        Part_Aging_Period__c partAgingObj = Part_Aging_Period__c.getOrgDefaults();
        Shop_Supplies__c shopSuppliesObj = Shop_Supplies__c.getOrgDefaults();
        Configurations__c configurationObj = Configurations__c.getOrgDefaults();
        Period1 = partAgingObj.Period_1__c == null ? '' : partAgingObj.Period_1__c;
        Period2 = partAgingObj.Period_2__c== null ? '' : partAgingObj.Period_2__c;
        Period3 = partAgingObj.Period_3__c == null ? '' : partAgingObj.Period_3__c;
        Period4 = partAgingObj.Period_4__c == null ? '' : partAgingObj.Period_4__c;
        
        ApplicableFee = shopSuppliesObj.Applicable_Fee__c == null ? '' : shopSuppliesObj.Applicable_Fee__c;
        CalculationMethod = shopSuppliesObj.Calculation_Method__c == null ? Constants.NOT_CALCULATED : shopSuppliesObj.Calculation_Method__c;
        ItemizedByLaborCode = shopSuppliesObj.Itemized_by_labor_code__c;
        MaximumPerInvoice = shopSuppliesObj.Maximum_Per_Invoice__c == null ? 0 : shopSuppliesObj.Maximum_Per_Invoice__c;
        SuppliesRate = shopSuppliesObj.Supplies_Rate__c == null ? 0 : shopSuppliesObj.Supplies_Rate__c;
        
        defaultLaborTax = configurationObj.Default_Tax_on_Labor__c == null ? '' : configurationObj.Default_Tax_on_Labor__c;
        defaultVendorItemTax = configurationObj.Default_Tax_on_Vendor_Product__c == null ? '' : configurationObj.Default_Tax_on_Vendor_Product__c;
        defaultPartTax = configurationObj.Default_Tax_on_Part__c == null ? '' : configurationObj.Default_Tax_on_Part__c;
        defaultFeeTax = configurationObj.Default_Tax_on_Fee__c == null ? '' : configurationObj.Default_Tax_on_Fee__c;
        orderingTaxRate = configurationObj.Ordering_Tax_Rate__c == null ? '' : configurationObj.Ordering_Tax_Rate__c;
        priceIncludeTax = configurationObj.Tax_Included_Pricing__c;
        DefaultUnitTax = configurationObj.Default_Tax_on_Unit__c == null ? '' : configurationObj.Default_Tax_on_Unit__c; 
        regionId = configurationObj.Country_Id__c == null ? '' : configurationObj.Country_Id__c;
        stateId = configurationObj.State_Id__c == null ? '' : configurationObj.State_Id__c;
        timezoneId= configurationObj.Time_Zone__c == null ? '' : configurationObj.Time_Zone__c;
        taxId= configurationObj.Tax_Id__c == null ? '' : configurationObj.Tax_Id__c;
        defaultPriceLevel = defaultPriceLevelRec.Id == null ? '' : String.valueOf(defaultPriceLevelRec.Id).substring(0, 15);
        
        DefaultSalesTaxOnInternalService = configurationObj.Default_Sales_Tax_on_Internal_Service__c == null ? '' : configurationObj.Default_Sales_Tax_on_Internal_Service__c;
        DefaultPriceLevelOnInternalService = configurationObj.Default_Price_Level_on_Internal_Service__c == null ? '' : configurationObj.Default_Price_Level_on_Internal_Service__c;
    	CashPaymentRoundingFactor = configurationObj.Cash_Payment_Rounding_Factor__c != null ? configurationObj.Cash_Payment_Rounding_Factor__c : 1;// 4th may 2017 kajal
    	IsHideHoursRateOnServiceJob = configurationObj.Hide_Hours_Rate_On_Service_Documents__c;
    	DefaultTechnicianCostingRate = configurationObj.Default_Technician_Cost_Rate__c != null ? configurationObj.Default_Technician_Cost_Rate__c : 0;
    	DefaultEnvironmentalFee = configurationObj.Default_Environmental_Fee__c;
    	StampDutyRate = configurationObj.Stamp_Duty_Rate__c;
        DefaultOdometerType =  configurationObj.Default_Odometer_Type__c;
        IsHidePartNumbersOnDocuments = configurationObj.Hide_Part_Numbers_On_Documents__c;
        IsIncludeMSRPAndDiscountOnPartLines = configurationObj.Include_MSRP_and_Discount_on_Part_Lines__c;
    	IsEnforcePayrollPIN = configurationObj.Enforce_Payroll_PIN__c;
        IsEnforceTechnicianPIN = configurationObj.Enforce_Technician_PIN__c;
    	IsRecordTrackingNumbers = configurationObj.Record_Tracking_Numbers__c;
        ShopifyTTId = configurationObj.Shopify_TT_Id__c;
        ShopifyPaymentMethodId = configurationObj.Shopify_Payment_Method_Id__c;
        ShopifyFeeId = configurationObj.Shopify_Fee_Id__c;
    	ShopifyDiscountFeeId = configurationObj.Shopify_Discount_Fee_Id__c;
        ShopifyShippingFeeId = configurationObj.Shopify_Shipping_Fee_Id__c;
    	CustomerInvoiceWarrantyText = (businessProfileRec.Customer_Invoice_Warranty_Text__c != null) ? businessProfileRec.Customer_Invoice_Warranty_Text__c : '';
    	ServiceJobWarrantyText = (businessProfileRec.Service_Job_Warranty_Text__c != null) ? businessProfileRec.Service_Job_Warranty_Text__c : '';
    	OrderDepositWarrantyText = (businessProfileRec.Order_Deposit_Warranty_Text__c != null) ? businessProfileRec.Order_Deposit_Warranty_Text__c : '';
    	DealDocumentsWarrantyText = (businessProfileRec.Deal_Documents_Warranty_Text__c != null) ? businessProfileRec.Deal_Documents_Warranty_Text__c : '';
    	SalesReceiptWarrantyText = (businessProfileRec.Sales_Receipt_Warranty_Text__c != null) ? businessProfileRec.Sales_Receipt_Warranty_Text__c : '';
    	
    	IsSignatureLineforCustomerInvoice = businessProfileRec.Is_Signature_Line_for_Customer_Invoice__c;
    	IsSignatureLineforServiceJob = businessProfileRec.Is_Signature_Line_for_Service_Job__c;
    	IsSignatureLineforOrderDeposit = businessProfileRec.is_Signature_Line_for_Order_Deposit__c;
    	IsSignatureLineforDealDocuments = businessProfileRec.Is_Signature_Line_for_Deal_Documents__c;
    	IsSignatureLineforSalesReceipt = businessProfileRec.Is_Signature_Line_for_Sales_Receipt__c;
    	AccrueTradeTaxUntilUnitSold = configurationObj.Accrue_Trade_Tax_Until_Unit_Sold__c;
    	EnableTaxAccrualOnOrderUnitsByDefault = configurationObj.Enable_Tax_Acc_on_Order_Units_By_Default__c;
    	TradeTaxPendingSaleCategory = configurationObj.Trade_Tax_Pending_Sale_Category__c;
    	TradeTaxLiabilityCategory = configurationObj.Trade_Tax_Liability_Category__c;
    	PurchaseTaxLiabilityCategory = configurationObj.Purchase_Tax_Liability_Category__c;
    	TradeTaxExpenseCategory = configurationObj.Trade_Tax_Expense_Category__c;
    	TradeTaxCreditCanNotExceedUnitTax = configurationObj.Trade_Tax_Credit_Can_Not_Exceed_Unit_Tax__c;
        IsAutoSelectOrdersInPartReceiving = configurationObj.Auto_Select_Orders_In_Part_Receiving__c;
    }
}
/**
* Author: 
* Since: July 4, 2016
* Name: PriceAndTaxWrapper
* Description: Apex class to wrap variables for price and tax section in user settings page
**/

global without sharing class PriceAndTaxWrapper {
    
    public String regionId;
    public String stateId;
    public String TimeZone;
    public String DealerNumber;
    
    public boolean priceIncludeTax;
    public String defaultPriceLevel;
    public String DefaultEnvironmentalFee;
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
    public String FormIdToIncludeOnDealDocuments;
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
    public List<ServiceJobStatusWrapper> ServiceJobStatusConfig;
    public String TechClockJobStatusId;
    public Boolean IsHideHoursRateOnServiceJob;
    public Decimal DefaultTechnicianCostingRate;
    public String DefaultOdometerType;
    public Boolean IsHidePartNumbersOnDocuments;
    public Boolean IsHideKitDetailsOnDocuments;
    public Boolean IsReadyToInvoiceRequiredToFinalize;
    public Boolean IsIncludeZeroPricesDealOptionOnDoc;
    public Boolean IsIncludeMSRPAndDiscountOnPartLines;
    public Boolean IsEnforcePayrollPIN;
    public Boolean IsEnforceTechnicianPIN;
    public Boolean ShowTBDOnInvoicePreviews;
    public Boolean IsRecordTrackingNumbers;
    public String ShopifyTTId;
    public String ShopifyPaymentMethodId;
    public String ShopifyFeeId;
    public String ShopifyDiscountFeeId;
    public String ShopifyShippingFeeId;
    public Boolean IsAutoSelectOrdersInPartReceiving;
    public Boolean AlwaysObeyPublishInFeeds;
    public Decimal AcceptablePartCostVariance;
    public Boolean IsIncludePricesOnPartLabels;
    public Boolean DFCommissionInFICompanyPayments;
    public Boolean AllowQuickFulfillingDealUnitOptions;
    public String FinanceCommissionIncomeGL;
    public String TechnicianHoursMethodOnJobs;
    public Boolean IsAutomaticallyArchiveQuotes;
    public Boolean IsAutomaticallyDeleteQuotes;
    public Integer AutomaticallyArchiveAfter;
    public Integer AutomaticallyDeleteAfter;
    public List<PicklistEntry> TimeZoneList;
    public Boolean IsChargeOnAccountRestricted;
    public Boolean AllowPauseOfJobClocking;
    public Boolean isAutomaticPaymentSurchargeEnabled;
    public Boolean AllowCustomerServiceJobWithoutUnit;

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
        
        if(configurationObj.Automatically_Archive_Quotes__c) {
            IsAutomaticallyArchiveQuotes = configurationObj.Automatically_Archive_Quotes__c;
            AutomaticallyArchiveAfter = configurationObj.Automatically_Archive_After_Days__c != null ? 
                Integer.valueOf(configurationObj.Automatically_Archive_After_Days__c) : null;
        }
        if(configurationObj.Automatically_Delete_Quotes__c) {
            IsAutomaticallyDeleteQuotes = configurationObj.Automatically_Delete_Quotes__c;
            AutomaticallyDeleteAfter = configurationObj.Automatically_Delete_After_Days__c != null ? 
                Integer.valueOf(configurationObj.Automatically_Delete_After_Days__c) : null;
        }
        
        ApplicableFee = shopSuppliesObj.Applicable_Fee__c == null ? '' : shopSuppliesObj.Applicable_Fee__c;
        CalculationMethod = shopSuppliesObj.Calculation_Method__c == null ? Constants.NOT_CALCULATED : shopSuppliesObj.Calculation_Method__c;
        ItemizedByLaborCode = shopSuppliesObj.Itemized_by_labor_code__c;
        MaximumPerInvoice = shopSuppliesObj.Maximum_Per_Invoice__c == null ? 0 : shopSuppliesObj.Maximum_Per_Invoice__c;
        SuppliesRate = shopSuppliesObj.Supplies_Rate__c == null ? 0 : shopSuppliesObj.Supplies_Rate__c;
        
        priceIncludeTax = configurationObj.Tax_Included_Pricing__c;
        regionId = configurationObj.Country_Id__c == null ? '' : configurationObj.Country_Id__c;
        stateId = configurationObj.State_Id__c == null ? '' : configurationObj.State_Id__c;
        DealerNumber = configurationObj.Dealer_Number__c != null ? configurationObj.Dealer_Number__c : '';
        defaultPriceLevel = defaultPriceLevelRec.Id == null ? '' : String.valueOf(defaultPriceLevelRec.Id).substring(0, 15);
        
        DefaultPriceLevelOnInternalService = configurationObj.Default_Price_Level_on_Internal_Service__c == null ? '' : configurationObj.Default_Price_Level_on_Internal_Service__c;
    	CashPaymentRoundingFactor = configurationObj.Cash_Payment_Rounding_Factor__c != null ? configurationObj.Cash_Payment_Rounding_Factor__c : 1;// 4th may 2017 kajal
    	IsHideHoursRateOnServiceJob = configurationObj.Hide_Hours_Rate_On_Service_Documents__c;
    	DefaultTechnicianCostingRate = configurationObj.Default_Technician_Cost_Rate__c != null ? configurationObj.Default_Technician_Cost_Rate__c : 0;
    	DefaultEnvironmentalFee = configurationObj.Default_Environmental_Fee__c;
    	StampDutyRate = configurationObj.Stamp_Duty_Rate__c;
        DefaultOdometerType =  configurationObj.Default_Odometer_Type__c;
        IsHidePartNumbersOnDocuments = configurationObj.Hide_Part_Numbers_On_Documents__c;
        IsHideKitDetailsOnDocuments = configurationObj.Hide_Kit_Details_On_Documents__c;
        IsReadyToInvoiceRequiredToFinalize = configurationObj.Is_Ready_To_Invoice_Required_To_Finalize__c;
        IsIncludeZeroPricesDealOptionOnDoc = configurationObj.Include_Zero_Priced_Deal_Options_On_Doc__c;
        IsIncludeMSRPAndDiscountOnPartLines = configurationObj.Include_MSRP_and_Discount_on_Part_Lines__c;
        IsIncludePricesOnPartLabels = configurationObj.Include_Prices_On_Part_Labels__c;
    	IsEnforcePayrollPIN = configurationObj.Enforce_Payroll_PIN__c;
        IsEnforceTechnicianPIN = configurationObj.Enforce_Technician_PIN__c;
        ShowTBDOnInvoicePreviews = configurationObj.Show_TBD_On_Invoice_Previews__c;
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
        FormIdToIncludeOnDealDocuments = configurationObj.Form_Id_To_Include_On_Deal_Documents__c;
    	IsAutoSelectOrdersInPartReceiving = configurationObj.Auto_Select_Orders_In_Part_Receiving__c;
        AlwaysObeyPublishInFeeds = configurationObj.Always_obey_publish_in_feeds__c;
        AcceptablePartCostVariance = configurationObj.Acceptable_Part_Cost_Variance__c;
        DFCommissionInFICompanyPayments = configurationObj.DF_commission_in_FI_company_payments__c;
        AllowQuickFulfillingDealUnitOptions = configurationObj.Allow_fulfilling_of_deal_unit_options__c;
        FinanceCommissionIncomeGL = Accounting_Default_Accounts__c.getOrgDefaults().Finance_Commission_Income__c;
        TechnicianHoursMethodOnJobs = configurationObj.Technician_Hours_Method_On_Jobs__c;
        IsChargeOnAccountRestricted = configurationObj.Is_Charge_On_Account_Restricted__c;
        AllowPauseOfJobClocking = configurationObj.Allow_Pause_Of_Job_Clocking__c;
        isAutomaticPaymentSurchargeEnabled = configurationObj.Enable_Automatic_Payment_Surcharges__c;
        AllowCustomerServiceJobWithoutUnit = configurationObj.Allow_Customer_Service_Job_Without_Unit__c;
    }
}
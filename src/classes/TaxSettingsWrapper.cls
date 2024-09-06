/**
 * Author: Nidhi Sharma
 * Since: March 10, 2024
 * Name: TaxSettingsWrapper
 * Description: 
**/
public without sharing class TaxSettingsWrapper {
    public GeneralConfigWrapper GenConfigObj;
    public AccruedTaxWrapper AccruedTaxObj;
    public DefaultTaxWrapper DefaultTaxObj;
    public List<TaxRateWrapper.TaxRate> AutomaticTaxRates;

    public class GeneralConfigWrapper {
        public String TaxId;
        public Boolean PriceIncludeTax;
        public Boolean TradeTaxCreditCanNotExceedUnitTax;
        public String DealUnitOptionsTaxedLikeUnit;
        public Boolean GroupIndividualTaxesOnSales;
        public String GroupIndividualSalesTaxAs;
        public Boolean GroupIndividualTaxesOnPurchase;
        public String GroupIndividualPurchaseTaxAs;

        public GeneralConfigWrapper() {
            Configurations__c configurationObj = Configurations__c.getOrgDefaults();
            this.TaxId = configurationObj.Tax_Id__c == null ? '' : configurationObj.Tax_Id__c;
            this.PriceIncludeTax = configurationObj.Tax_Included_Pricing__c;
            this.TradeTaxCreditCanNotExceedUnitTax = configurationObj.Trade_Tax_Credit_Can_Not_Exceed_Unit_Tax__c;
            this.DealUnitOptionsTaxedLikeUnit = configurationObj.Deal_Unit_Options_Taxed_Like_Unit__c;
            this.GroupIndividualTaxesOnSales = configurationObj.Group_Individual_Taxes_On_Sales__c;       
            this.GroupIndividualSalesTaxAs = configurationObj.Group_Individual_Sales_Tax_As__c;       
            this.GroupIndividualTaxesOnPurchase = configurationObj.Group_Individual_Taxes_On_Purchases__c;       
            this.GroupIndividualPurchaseTaxAs = configurationObj.Group_Individual_Purchase_Tax_As__c;       
        }
    }

    public class AccruedTaxWrapper {
        public Boolean AccrueTradeTaxUntilUnitSold;
        public Boolean EnableTaxAccrualOnOrderUnitsByDefault;
        public String NationalInputTaxCategory; 
        public String SalesTaxLiabilityCategory;
        public String PurchaseTaxLiabilityCategory; 
        public String NationalInputTaxExpenseCategory;

        public AccruedTaxWrapper() {
            Configurations__c configurationObj = Configurations__c.getOrgDefaults();
            this.AccrueTradeTaxUntilUnitSold = configurationObj.Accrue_Trade_Tax_Until_Unit_Sold__c;
            this.EnableTaxAccrualOnOrderUnitsByDefault = configurationObj.Enable_Tax_Acc_on_Order_Units_By_Default__c;  
            this.NationalInputTaxCategory = configurationObj.Trade_Tax_Pending_Sale_Category__c;
            this.SalesTaxLiabilityCategory = configurationObj.Trade_Tax_Liability_Category__c;
            this.PurchaseTaxLiabilityCategory = configurationObj.Purchase_Tax_Liability_Category__c;
            this.NationalInputTaxExpenseCategory = configurationObj.Trade_Tax_Expense_Category__c;
        }
    }

    public class DefaultTaxWrapper {
        public String PartTax;
        public String LaborTax;
        public String FeeTax; 
        public String UnitTax;
        public String VendorProductTax; 
        public String ClaimDeductiblesTax;
        public String InternalServiceTax;
        public String VendorPurchaseTax;

        public DefaultTaxWrapper() {
            Configurations__c configurationObj = Configurations__c.getOrgDefaults();
            this.PartTax = configurationObj.Default_Tax_on_Part__c == null ? '' : configurationObj.Default_Tax_on_Part__c;
            this.LaborTax = configurationObj.Default_Tax_on_Labor__c == null ? '' : configurationObj.Default_Tax_on_Labor__c;
            this.FeeTax = configurationObj.Default_Tax_on_Fee__c == null ? '' : configurationObj.Default_Tax_on_Fee__c;
            this.UnitTax = configurationObj.Default_Tax_on_Unit__c == null ? '' : configurationObj.Default_Tax_on_Unit__c;
            this.VendorProductTax = configurationObj.Default_Tax_on_Vendor_Product__c == null ? '' : configurationObj.Default_Tax_on_Vendor_Product__c;
            this.ClaimDeductiblesTax = configurationObj.Default_Tax_on_Claim_Deductibles__c == null ? '' : configurationObj.Default_Tax_on_Claim_Deductibles__c;
            this.InternalServiceTax = configurationObj.Default_Sales_Tax_on_Internal_Service__c == null ? '' : configurationObj.Default_Sales_Tax_on_Internal_Service__c;
            this.VendorPurchaseTax = configurationObj.Ordering_Tax_Rate__c == null ? '' : configurationObj.Ordering_Tax_Rate__c;
        }
    }
}
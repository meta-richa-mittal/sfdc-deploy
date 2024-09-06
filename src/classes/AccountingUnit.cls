/**
 * Author: Richa Mittal
 * Since: Dec. 14, 2017
 * Name: AccountingUnit
 * Description: Tempalate class for Accounting Unit (QB Integration)
**/
public without sharing class AccountingUnit {
    public String Id;
    public String StockNumber;
    public String VIN;
    public String MakeName;
    public String ModelName;
    public String SubModelName;
    public String ItemDesc;
    public String InvoiceNumber;
    public Decimal TotalCost;
    public String NewCategoryName;
    public String NewCategoryInventoryGL;
    public String OldCategoryName;
    public String OldCategoryInventoryGL;
    public Date ModifiedDate;
    public Decimal TotalInventoryValuation;
    public VendorWrapper Vendor;
    public String AccountingId;
    public String SyncToken;
    public String AccountingResponse;
    public Date CreatedDate;
    public String Inventory_GL;
    public CategoryWrapper categoryRef;
    public Decimal TotalPurchaseTax;
    public List<AccountingPurchaseTax> AccountingPurchaseTaxList;
    public String AppliedQBTaxCode;
    public Decimal AppliedTaxRate;
    public String XeroJEAccountingId;
    public String UnitId;
    public String XeroAccountingId;
    public String XeroConsignmentAccId;
    public String XeroAccountingIdUnitInvoiceJE;
    public String QBAccountingIdUnitInvoiceJE;
    public String SyncTokenForUnitInvoiceJE;
    public String XeroVendorAccountingId;
    public Decimal PurchaseTaxCredit;
    public String QBUnitNITCJEAccountingId;
    public String XeroUnitNITCJEAccountingId;
    public Decimal SalesTaxCredit;
    public String SyncTokenForUnitNITCJE;
    public Date NITCDateClaimed;
    public Date DueDate;
    public Decimal AgreedPayout;
    public Date UnitInvoiceDate;
    public String XeroCustomerAccId;
    public String QBCustomerAccId;
    public String QBConsAccountingId;
    public String SyncTokenForCons;
    public Decimal TotalCostWithTax;
    
    public AccountingUnit(Customer_Owned_Unit__c couObj) {
        this.Id = couObj.Id;
        this.UnitId = couObj.Unit_Id__c;
        this.StockNumber = couObj.Stock_Id__c;
        this.VIN = couObj.VIN_Number_Formula__c;
        this.MakeName = couObj.Make_Name__c;
        this.ModelName = couObj.Model_Name__c;
        this.SubModelName = (couObj.Sub_Model__c != null && couObj.Sub_Model__r.Sub_Model_Name__c != null) ? couObj.Sub_Model__r.Sub_Model_Name__c : '';
        this.ItemDesc = this.StockNumber + ';' + this.VIN + ';' + this.MakeName + ';' + this.ModelName + ';' + this.SubModelName;
        if(couObj.Consignment__c != null && couObj.Consignment__c && couObj.Deals_Units_Junction__r.size() > 0) {
        	this.InvoiceNumber = couObj.Deals_Units_Junction__r[0].Deal__r.Invoice_Number__r.Invoice_Number__c.replace('INV', 'CONS');
        } else {
        	this.InvoiceNumber = couObj.Invoice_Number__c;
        }
        this.TotalCost = (couObj.Referenced_Unit__r.Total_Cost__c != null) ? couObj.Referenced_Unit__r.Total_Cost__c : 0;
        this.NewCategoryName = couObj.Category__r.Name;
        this.NewCategoryInventoryGL = couObj.Category__r.Inventory_GL__c;
        this.OldCategoryName = couObj.Old_Category__r.Name;
        this.OldCategoryInventoryGL = couObj.Old_Category__r.Inventory_GL__c;
        this.ModifiedDate = Date.valueOf(couObj.LastModifiedDate);
        this.TotalInventoryValuation = couObj.Total_Cost__c != null ? couObj.Total_Cost__c : 0;
        this.Vendor = new VendorWrapper(couObj.Referenced_Unit__r.Vendor__r.Vendor_AccountingId__c, couObj.Referenced_Unit__r.Vendor__r.Name);
        
        this.AccountingId = couObj.AccountingId__c;
        this.SyncToken = couObj.SyncToken__c;
        this.AccountingResponse = couObj.AccountingResponse__c;
        this.CreatedDate = couObj.Date_Stocked_In__c;
        
        // Set tax according unit purchase tax
        Id purchaseTaxId = couObj.Referenced_Unit__r.Unit_Purchase_Tax__c != null ? couObj.Referenced_Unit__r.Unit_Purchase_Tax__r.Id : couObj.Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Id;
        this.AppliedQBTaxCode = couObj.Referenced_Unit__r.Unit_Purchase_Tax__c != null ? couObj.Referenced_Unit__r.Unit_Purchase_Tax__r.Accounting_Id__c : couObj.Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Accounting_Id__c;
        this.AppliedTaxRate = couObj.Referenced_Unit__r.Unit_Purchase_Tax__c != null ? couObj.Referenced_Unit__r.Unit_Purchase_Tax__r.Rate__c : couObj.Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Rate__c;
        List<Applicable_Taxes__c> applicableTaxList = [Select Name, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c, Sales_Tax_Item__r.Category__r.Income_GL__c, Sales_Tax_Item__r.AccountingId__c from Applicable_Taxes__c where Sales_Tax__r.Id = :purchaseTaxId];
        
        this.AccountingPurchaseTaxList = new List<AccountingPurchaseTax>();
        for(Applicable_Taxes__c ApplicableTaxRec : applicableTaxList) {
            this.AccountingPurchaseTaxList.add(new AccountingPurchaseTax(ApplicableTaxRec));
        }
        
        this.TotalPurchaseTax = couObj.Referenced_Unit__r.Tax_Amount__c != null ? couObj.Referenced_Unit__r.Tax_Amount__c : 0;
        this.Inventory_GL = couObj.Referenced_Unit__r.Category__r.Inventory_GL__c;
        this.TotalCostWithTax = couObj.Referenced_Unit__r.Total_Cost_With_Tax__c;
    
        this.XeroJEAccountingId = couObj.Xero_JE_Accounting_Id__c;
        this.XeroAccountingId = couObj.Xero_Accounting_Id__c;
        this.XeroConsignmentAccId = couObj.Xero_Consignment_Accounting_Id__c;
        this.XeroVendorAccountingId = couObj.Vendor__r.Xero_Vendor_Accounting_Id__c;
        this.PurchaseTaxCredit = couObj.Purchase_Tax_Credit__c != null ? couObj.Purchase_Tax_Credit__c : 0;
        this.XeroAccountingIdUnitInvoiceJE = couObj.Xero_Accounting_Id_Unit_Invoice_JE__c;
        this.QBAccountingIdUnitInvoiceJE = couObj.QB_Accounting_Id_Unit_Invoice_JE__c;
        this.SyncTokenForUnitInvoiceJE = couObj.Sync_Token_For_Unit_Invoice_JE__c;
        this.QBUnitNITCJEAccountingId = couObj.QB_NITC_JE_Accounting_Id__c;
        this.XeroUnitNITCJEAccountingId = couObj.Xero_NITC_JE_Accounting_Id__c;
        this.SalesTaxCredit = couObj.Sales_Tax_Credit__c;
        this.SyncTokenForUnitNITCJE = couObj.Sync_Token_For_NITC_JE__c;
        this.NITCDateClaimed = couObj.NITC_Date_Claimed__c;
        this.UnitInvoiceDate = couObj.Date_Stocked_Out__c != null ? couObj.Date_Stocked_Out__c : system.today();
        this.AgreedPayout = couObj.Agreed_Payout__c != null ? couObj.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.XeroCustomerAccId = couObj.Account__c != null ? couObj.Account__r.Xero_Customer_Accounting_Id__c : null;
        this.QBCustomerAccId = couObj.Account__r.AccountingId__c;
        this.QBConsAccountingId = couObj.QB_Consignment_Accounting_Id__c;
        this.SyncTokenForCons = couObj.Sync_Token_For_Consignment__c;
    }
    public class CustomerWrapper {
        public String AccountingId;
        public String Name;
  
        public CustomerWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
    }
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> COUFields = new List<String>{ 'Id',
                            'Name', 
                            'Unit_Id__c',
                            'Stock_Id__c',
                            'VIN_Number_Formula__c',
                            'Make_Name__c',
                            'Model_Name__c',
                            'Sub_Model__c',
                            'Sub_Model__r.Sub_Model_Name__c',
                            'CreatedDate',
                            'Date_Stocked_In__c',
                            'Date_Stocked_Out__c',
                            'Vendor__c',
                            'Vendor__r.Vendor_AccountingId__c',
                            'Vendor__r.Name',
                            'Referenced_Unit__r.Category__r.Inventory_GL__c',
                            'AccountingId__c',
                            'Available_For_QB_Unit_Invoice_JE_Sync__c',
                            'Xero_Accounting_Id_Unit_Invoice_JE__c',
                            'QB_Accounting_Id_Unit_Invoice_JE__c',
                            'Accounting_Response_Unit_Invoice_JE__c',
                            'Sync_Token_For_Unit_Invoice_JE__c',
                            'SyncToken__c',
                            'Referenced_Unit__r.Total_Cost__c',
                            'AccountingResponse__c',
                            'Referenced_Unit__r.Vendor__c',
                            'Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Rate__c',
                            'Referenced_Unit__r.Vendor__r.Vendor_AccountingId__c',
                            'Referenced_Unit__r.Vendor__r.Name',
                            'Invoice_Number__c',
                            'Referenced_Unit__r.Tax_Amount__c',
                            'Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Id',
                            'Referenced_Unit__r.Vendor__r.Purchase_Tax__r.Accounting_Id__c',
                            'Category__r.Name',
                            'Category__r.Inventory_GL__c',
                            'Old_Category__r.Name',
                            'Old_Category__r.Inventory_GL__c',
                            'LastModifiedDate',
                            'Total_Cost__c',
                            'Xero_JE_Accounting_Id__c',
                            'Xero_Accounting_Id__c',
                            'Vendor__r.Xero_Vendor_Accounting_Id__c',
                            'Purchase_Tax_Credit__c',
                            'QB_NITC_JE_Accounting_Id__c',
                            'Xero_NITC_JE_Accounting_Id__c',
                            'Sales_Tax_Credit__c',
                            'Sync_Token_For_NITC_JE__c',
                            'NITC_Date_Claimed__c',
                            'Xero_Consignment_Accounting_Id__c',
                            'Agreed_payout__c',
                            'Available_For_QB_Consignment_Sync__c',
                            'Accounting_Response_Consignment__c',
                            'QB_Consignment_Accounting_Id__c',
                            'Account__r.AccountingId__c',
                            'Account__c',
                            'Account__r.Xero_Customer_Accounting_Id__c',
                            'Sync_Token_For_Consignment__c',
                            'Consignment__c',
                            'Referenced_Unit__r.Unit_Purchase_Tax__c',
                            'Referenced_Unit__r.Unit_Purchase_Tax__r.Id',
                            'Referenced_Unit__r.Unit_Purchase_Tax__r.Accounting_Id__c',
                            'Referenced_Unit__r.Unit_Purchase_Tax__r.Rate__c',
                            'Referenced_Unit__r.Total_Cost_With_Tax__c',
                            'Referenced_Unit__r.Overridden_Total_Cost_With_Tax__c',
                            'Overridden_Total_Cost_With_Tax__c',
                            'Total_Cost_With_Tax__c',
            				'(SELECT Deal__r.Invoice_Number__r.Invoice_Number__c FROM Deals_Units_Junction__r where Deal__r.Invoice_Number__c != null)'
                           };
        return COUFields;
    }
    
    public class VendorWrapper {
        public String AccountingId;
        public String Name;
        public VendorWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
    }
    
    public class AccountRefWrapper {
        public String AccountingId;
        public AccountRefWrapper(String AccountingId) {
            this.AccountingId = AccountingId;
        }
    }
    
    public class CategoryWrapper{
        public String AccountingId;
        public String Name;
        
        public CategoryWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
    }
    
    public class AccountingPurchaseTax {
    	public String SalesTaxName;
    	public Decimal SalesTaxRate;
    	public String CategoyRef;
    	public String QBTaxCodeRef;
    	public Decimal TaxAmount;
    	
	    public AccountingPurchaseTax(Applicable_Taxes__c  applicableTaxRec) { 
	        this.SalesTaxName = applicableTaxRec.Sales_Tax_Item__r.Name__c;
	        this.SalesTaxRate = applicableTaxRec.Sales_Tax_Item__r.Rate__c;
	        this.CategoyRef = applicableTaxRec.Sales_Tax_Item__r.Category__r.Income_GL__c;
	        this.QBTaxCodeRef = applicableTaxRec.Sales_Tax_Item__r.AccountingId__c;
	    }
    }
    
    public class TaxRateComponent {
        public Decimal TaxAmount;
        public Decimal TaxableAmount;
        public String TaxRateAcctId;
        public Decimal TaxRatePercent;
        public TaxRateComponent(Decimal taxAmount, Decimal taxableAmount, String acctId, Decimal taxPercent) {
            this.TaxAmount = (taxAmount != null) ? taxAmount : 0;
            this.TaxableAmount = taxableAmount;
            this.TaxRateAcctId = acctId;
            this.TaxRatePercent = taxPercent;
        }
    }
}
public without sharing class AccountingVendorReturn {
    
	public String Id;
	public String Name;
	public String RTNNumber;
	public String SyncToken;
	public String AccountingId;
   	public String VendorAccountingId;
   	public String TaxCodeAccountingId;
   	public String VendorName;
	public Date CreditedDate;
	public DateTime CreditedDateTime;
   	public String CreditMemoNumber;
   	public Decimal Tax;
   	public Decimal Total;
   	public Decimal ItemTotal;
   	public AccountRefWrapper AccountRef1;
   	public List<ReturnCRLineItemWrapper> ReturnCRLIList;
   	public List<AccountingPurchaseTax> AccountingPurchaseTaxList {get; set;}
    public String XeroVendorAccountingId;
    public String XeroAccountingId;
	public String QBVarianceJEAccountingId;
	public String XeroVarianceJEAccountingId;
	public String SyncTokenForVarianceJE;
	public Boolean IsForeignVendor;
	public String CurrencyCode;
	public Decimal FXConversionRate;
	public Date DueDate;
	public List<AccountingVendorInvoice.OtherChargesWrapper> AccountingOtherChargesList;

	public AccountingVendorReturn(Return_CR_Header__c returnCRHeaderRec, List<Return_VO_Line_Item__c> rvoLIList) {
		this.Id = returnCRHeaderRec.Id;
		this.RTNNumber = returnCRHeaderRec.Name;
		this.Name = (returnCRHeaderRec.Credit_Memo__c != null) ? returnCRHeaderRec.Credit_Memo__c : returnCRHeaderRec.Name;
		this.AccountingId = returnCRHeaderRec.Accounting_Id__c;
		this.SyncToken = returnCRHeaderRec.Sync_Token__c;
    	this.VendorAccountingId = returnCRHeaderRec.Vendor__r.Vendor_AccountingId__c != null ? returnCRHeaderRec.Vendor__r.Vendor_AccountingId__c : '';
    	this.XeroVendorAccountingId = returnCRHeaderRec.Vendor__r.Xero_Vendor_Accounting_Id__c;
    	this.VendorName = returnCRHeaderRec.Vendor__r.Name != null ? returnCRHeaderRec.Vendor__r.Name : '';
    	this.CreditMemoNumber = returnCRHeaderRec.Credit_Memo__c ;
    	this.Tax = returnCRHeaderRec.Tax_Total__c != null ? returnCRHeaderRec.Tax_Total__c : 0;
    	this.Total = returnCRHeaderRec.Total_With_Tax__c != null ? returnCRHeaderRec.Total_With_Tax__c : 0;
    	this.ItemTotal = (returnCRHeaderRec.Item_Total__c != null ? returnCRHeaderRec.Item_Total__c : 0);
    	this.AccountRef1 = new AccountRefWrapper(AccountingUtil.getChartofAccount('A/P Inventory Accrual'));
    	this.CreditedDateTime = returnCRHeaderRec.Credited_Date__c != null ? returnCRHeaderRec.Credited_Date__c : returnCRHeaderRec.CreatedDate;
    	this.CreditedDate = returnCRHeaderRec.Credited_Date__c;
    	
		Id purchaseTaxId = returnCRHeaderRec.Vendor__r.Purchase_Tax__r.Id;
        List<Applicable_Taxes__c> applicableTaxList = [Select Name, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c, Sales_Tax_Item__r.Category__r.Income_GL__c, Sales_Tax_Item__r.AccountingId__c from Applicable_Taxes__c where Sales_Tax__r.Id = :purchaseTaxId];
        
        this.AccountingPurchaseTaxList = new List<AccountingPurchaseTax>();
        for(Applicable_Taxes__c ApplicableTaxRec : applicableTaxList) {
            this.AccountingPurchaseTaxList.add(new AccountingPurchaseTax(ApplicableTaxRec));
        }
    	this.TaxCodeAccountingId = (returnCRHeaderRec.Vendor__r.Purchase_Tax__c != null) ? returnCRHeaderRec.Vendor__r.Purchase_Tax__r.Accounting_Id__c : '';
    	this.XeroAccountingId = returnCRHeaderRec.Xero_Accounting_Id__c;

		this.QBVarianceJEAccountingId = returnCRHeaderRec.QB_Variance_JE_Accounting_Id__c;
		this.XeroVarianceJEAccountingId = returnCRHeaderRec.Xero_Variance_JE_Accounting_Id__c;
		this.SyncTokenForVarianceJE = returnCRHeaderRec.Sync_Token_For_Variance_JE__c;
		this.IsForeignVendor = returnCRHeaderRec.Vendor__r.Is_Foreign_Vendor__c;
		this.CurrencyCode = ForeignExchangeUtil.getVendorCurrencyCode(returnCRHeaderRec.Vendor__r);
		if(QBUtil.isQBEnabled()) {
			this.FXConversionRate = returnCRHeaderRec.FX_Conversion_Rate__c != null ? returnCRHeaderRec.FX_Conversion_Rate__c : 1;
		} else {
			this.FXConversionRate = returnCRHeaderRec.Backward_Conversion_Rate__c != null ? returnCRHeaderRec.Backward_Conversion_Rate__c : 1;
		}

		Map<String, Return_VO_Line_Item__c> rcrLIIdToRVOLIRecMap = new Map<String, Return_VO_Line_Item__c>();
		if(rvoLIList != null) {
			for(Return_VO_Line_Item__c rvoRec: rvoLIList) {
				rcrLIIdToRVOLIRecMap.put(rvoRec.Return_CR_Line_Item__c, rvoRec);
			}
		}
    	this.ReturnCRLIList = new List<ReturnCRLineItemWrapper>();
    	for(Return_CR_Line_Item__c returnCRLineItemRec  : returnCRHeaderRec.Return_CR_Line_Items__r) {
			this.ReturnCRLIList.add(new ReturnCRLineItemWrapper(returnCRLineItemRec, rcrLIIdToRVOLIRecMap.get(returnCRLineItemRec.Id), this.FXConversionRate));
		}

		if(returnCRHeaderRec.Other_Charges__r != null) {
			this.AccountingOtherChargesList = new List<AccountingVendorInvoice.OtherChargesWrapper>(); 
			for(Other_Charges__c otherCharge : returnCRHeaderRec.Other_Charges__r) {
				this.AccountingOtherChargesList.add(new AccountingVendorInvoice.OtherChargesWrapper(otherCharge));
			}
		}
    } 
    
   	public class ReturnCRLineItemWrapper {
		public String Id;
		public String ItemDescription;
		public Decimal ReturnQty;
		public Decimal ItemCost;
		public Decimal InventoryCost;
		public String Inventory_GL;
		public Decimal Variance;
	   
		public ReturnCRLineItemWrapper(Return_CR_Line_Item__c returnCRLIRec, Return_VO_Line_Item__c rvoLIRec, Decimal fxConversionRateWithMarkup) {
			this.Id = returnCRLIRec.Id;
			this.ItemDescription = returnCRLIRec.Item_Desc__c;
			this.ReturnQty = returnCRLIRec.Return_Qty__c != null ? returnCRLIRec.Return_Qty__c : 0;
			this.ItemCost = returnCRLIRec.Credit_Cost__c != null ? returnCRLIRec.Credit_Cost__c : 0;
			this.InventoryCost = returnCRLIRec.Return_Cost__c != null ? returnCRLIRec.Return_Cost__c : 0;
			this.Inventory_GL = (returnCRLIRec.Part__r.Category__c != null && returnCRLIRec.Part__r.Category__r.Inventory_GL__c != null) ? 
									returnCRLIRec.Part__r.Category__r.Inventory_GL__c : '';
				fxConversionRateWithMarkup = fxConversionRateWithMarkup != null && fxConversionRateWithMarkup != 0 ? fxConversionRateWithMarkup : 1;
			if(rvoLIRec != null) {
				this.Variance = rvoLIRec.Variance__c;
			}
		}
	}
	
	public class AccountRefWrapper {
        public String AccountingId {get; set;}
        
        public AccountRefWrapper(String AccountingId) {
            this.AccountingId = AccountingId;
        }
    }
    
    public class AccountingPurchaseTax {
    	public String SalesTaxName {get; set;}
    	public Decimal SalesTaxRate {get; set;}
    	public String SalesTaxItemAccountingId {get; set;}
    	public String CategoyRef {get; set;}
    	public Decimal TaxAmount {get; set;}
    	
    	// Constructor
	    public AccountingPurchaseTax(Applicable_Taxes__c  applicableTaxRec) { 
	        this.SalesTaxName = applicableTaxRec.Sales_Tax_Item__r.Name__c;
	        this.SalesTaxRate = applicableTaxRec.Sales_Tax_Item__r.Rate__c;
	        this.CategoyRef = applicableTaxRec.Sales_Tax_Item__r.Category__r.Income_GL__c;
	        this.SalesTaxItemAccountingId = applicableTaxRec.Sales_Tax_Item__r.AccountingId__c;
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

	public static List<String> getReturnCRFieldList(){
        List<String> returnCRFields = new List<String>{ 
        											'Id',
        											'Name',
        											'Sync_Token__c',
        											'Accounting_Id__c',
        											'Vendor__c',
        											'Vendor__r.Vendor_AccountingId__c',
        											'Vendor__r.Name',
        											'Tax_Total__c',
        											'Item_Total__c',
        											'Other_Charges_Total__c',
        											'Credited_Date__c',
        											'Credit_Memo__c',
        											'Total_With_Tax__c',
        											'CreatedDate',
        											'Vendor__r.Purchase_Tax__r.Id',
        											'Vendor__r.Purchase_Tax__c',
        											'Vendor__r.Purchase_Tax__r.Accounting_Id__c',
        											'Vendor__r.Xero_Vendor_Accounting_Id__c',
        											'Xero_Accounting_Id__c',
													'QB_Variance_JE_Accounting_Id__c',
													'Xero_Variance_JE_Accounting_Id__c',
													'Sync_Token_For_Variance_JE__c',
													'Vendor__r.Is_Foreign_Vendor__c',
													'Vendor__r.Country__r.Currency_Code__c',
													'FX_Conversion_Rate__c',
													'Backward_Conversion_Rate__c'
        };
        return returnCRFields;
    }
    
    
    public static List<String> getReturnCRLIFieldList(){
        List<String> returnCRLIFields = new List<String>{ 
        											'Id',
        											'Item_Desc__c',
        											'Return_Qty__c',
        											'Credit_Cost__c',
        											'Return_Cost__c',
        											'Part__r.Category__c',
        											'Part__r.Category__r.Inventory_GL__c'
        };
        
        return returnCRLIFields;
    }    
}
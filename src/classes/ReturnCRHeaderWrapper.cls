public without sharing class ReturnCRHeaderWrapper {

    public String Id;
	public String Name;
	public String VendorId;
	public String VendorName;
	public String Status;
	public String CreatedDate;
	public String CreditedDate;
	public String LastModifiedDate;
    public String OwnerName;
    public String LastModifiedBy;
	public String CreditMemoNumber;
    public Decimal ItemTotal;
    public Decimal OtherChargesTotal;
    public Decimal TaxTotal;
	public Decimal TotalWithTax;
    public Boolean IsForeignVendor;
	public ForeignExchangeUtil.CurrencyWrapper FXCurrencyDetails;

    public ReturnCRHeaderWrapper(Return_CR_Header__c returnCRRec) {
        this.Id = returnCRRec.Id;
        this.Name = returnCRRec.Name;
        this.VendorId = returnCRRec.Vendor__c;
        this.VendorName = returnCRRec.Vendor__r.Name;
        this.Status = returnCRRec.Status__c;
        this.CreatedDate = returnCRRec.CreatedDate != null ? BPUtility.getFormatedDateTime(returnCRRec.CreatedDate) : '';
        this.CreditedDate = returnCRRec.Credited_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(returnCRRec.Credited_Date__c.year(), returnCRRec.Credited_Date__c.month(), returnCRRec.Credited_Date__c.day())) : '';
        this.LastModifiedDate = returnCRRec.LastModifiedDate != null ? BPUtility.getFormatedDateTime(returnCRRec.LastModifiedDate) : '';
        this.OwnerName = returnCRRec.owner.name;
        this.LastModifiedBy = returnCRRec.LastModifiedBy.name;
        this.CreditMemoNumber = returnCRRec.Credit_Memo__c;
        this.ItemTotal = returnCRRec.Item_Total__c != null ? returnCRRec.Item_Total__c : 0;
        this.OtherChargesTotal = returnCRRec.Other_Charges_Total__c != null ? returnCRRec.Other_Charges_Total__c : 0;
        this.TaxTotal = returnCRRec.Tax_Total__c;
        this.TotalWithTax = returnCRRec.Total_With_Tax__c;
        this.IsForeignVendor = returnCRRec.Vendor__r.Is_Foreign_Vendor__c;
        if(returnCRRec.Vendor__r.Is_Foreign_Vendor__c) {
            this.FXCurrencyDetails = new ForeignExchangeUtil.CurrencyWrapper(returnCRRec.Vendor__r.Country__r, true);
            if(String.isNotBlank(returnCRRec.Status__c) && returnCRRec.Status__c.equalsIgnoreCase('Credited')) {
                this.FXCurrencyDetails.ConversionRateWithMarkup = XeroUtility.isXeroEnabled() ? returnCRRec.Backward_Conversion_Rate__c : returnCRRec.FX_Conversion_Rate__c;
            }
        }
    }

    public class ReturnCRLineItemWrapper {
	
		public String Id;
		public String Name;
		public String ItemDescription;
		public Decimal ReturnQty;
		public Decimal ReturnCost;
		public Decimal CreditCost;
		public String ReturnCRId;
		public String PartId;
        public String RTNNumber;
        public String RMANumber;
        public String RVOLineItemId;
        public Decimal SubTotal;

		public ReturnCRLineItemWrapper(Return_CR_Line_Item__c returnCRLIRec) {
			this.Id = returnCRLIRec.Id;
			this.Name = returnCRLIRec.Name;
			this.ItemDescription = returnCRLIRec.Item_Desc__c;
			this.ReturnQty = returnCRLIRec.Return_Qty__c != null ? returnCRLIRec.Return_Qty__c : 0;
			this.ReturnCost = returnCRLIRec.Return_Cost__c != null ? returnCRLIRec.Return_Cost__c : 0;
			this.CreditCost = returnCRLIRec.Credit_Cost__c != null ? returnCRLIRec.Credit_Cost__c : 0;
			this.ReturnCRId = returnCRLIRec.Return_CR_Header__c;
			this.PartId = returnCRLIRec.Part__c;
            this.SubTotal = (this.ReturnQty * this.CreditCost).setScale(2, RoundingMode.HALF_UP);
            if(!returnCRLIRec.Return_VO_Line_Items__r.isEmpty()) {
                this.RTNNumber = returnCRLIRec.Return_VO_Line_Items__r[0].Return_VO_Header__r.Name;
                this.RMANumber = returnCRLIRec.Return_VO_Line_Items__r[0].Return_VO_Header__r.RMA__c;
                this.RVOLineItemId = returnCRLIRec.Return_VO_Line_Items__r[0].Id;
            }
		}
	}

    public static List<String> getReturnCRFieldList() {
        List<String> returnCRFields = new List<String>{ 
                                                    'Id',
                                                    'Name',
                                                    'Vendor__c',
                                                    'Vendor__r.Name',
                                                    'Status__c',
                                                    'CreatedDate',
                                                    'Credited_Date__c',
                                                    'LastModifiedDate',
                                                    'Owner.name',
                                                    'LastModifiedBy.Name',
                                                    'Credit_Memo__c',
                                                    'Item_Total__c',
                                                    'Other_Charges_Total__c',
                                                    'Tax_Total__c',
                                                    'Total_With_Tax__c',
                                                    'FX_Conversion_Rate__c',
                                                    'Backward_Conversion_Rate__c',
                                                    'Vendor__r.Is_Foreign_Vendor__c',
                                                    'Vendor__r.Country__r.Conversion_Rate_With_Markup__c',
                                                    'Vendor__r.Country__r.Backward_Conversion_Rate__c',
                                                    'Vendor__r.Country__r.Currency_Code__c',
                                                    'Vendor__r.Country__r.Formatted_FX_Currency_Code__c'
        };
        return returnCRFields;
    }
    
    public static List<String> getReturnCRLIFieldList() {
        List<String> returnCRLIFields = new List<String>{ 
                                                    'Id',
                                                    'Name',
                                                    'Item__c',
                                                    'Description__c',
                                                    'Item_Desc__c',
                                                    'Return_Qty__c',
                                                    'Item_Cost__c',
                                                    'Inventory_Cost__c',
                                                    'Return_VO_Header__c',
                                                    'Part__c',
                                                    'Part__r.Qty_In_Stock__c',
                                                    'Part__r.Package_Unit__c',
                                                    'Part__r.Packaged_Part__c'
        };
        
        return returnCRLIFields;
    }
}
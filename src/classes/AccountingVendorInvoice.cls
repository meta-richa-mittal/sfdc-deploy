/**
 * Author: Pooja Khandelwal
 * Since: Jan. 6, 2017
 * Name: AccountingVendorInvoice
 * Description: Tempalate class for Accounting Vendor Invoice ((QB Integration))
**/ 
public without sharing class AccountingVendorInvoice {
    public static final String INVENTORY_RECEIVED = 'Inventory received';
    public static final String OTHER_CHARGE_ALLOCATION = 'Other charge allocations';

    public String Id; // Created for generalised error response handling in XeroService
    public AccountingVIHeader AccountingVIHeaderRec;
    public List<OtherChargesWrapper> AccountingOtherChargesList;
    public List<AccountingFIFOBucket> AccountingPartFIFOBucketList;
    public VendorWrapper vendor;
	public List<AccountingPurchaseTax> AccountingPurchaseTaxList;
	public String AppliedQBTaxCode;
    public Decimal AppliedTaxRate;
    public List<AccountingVIGroupByGLAndType> AccountingVIGroupByGLAndTypeList;
    public Set<String> VRNumberSet;
    public AccountingVendorInvoice(Vendor_Invoicing_Header__c VIHeaderRec, List<Vendor_Invoicing_Group__c> VIGroupsList, List<Part_FIFO_Bucket__c> PartFIFOBucketList) {
        this.Id = VIHeaderRec.Id;
        this.AccountingVIHeaderRec = new AccountingVIHeader(VIHeaderRec);
        
        this.AccountingOtherChargesList = new List<OtherChargesWrapper>(); 
        for(Other_Charges__c otherCharge : VIHeaderRec.Other_Charges__r) {
            this.AccountingOtherChargesList.add(new OtherChargesWrapper(otherCharge));
        }
        
        this.AccountingPartFIFOBucketList = new List<AccountingFIFOBucket>();
        for(Part_FIFO_Bucket__c PartFIFOBucketRec : PartFIFOBucketList) {
            this.AccountingPartFIFOBucketList.add(new AccountingFIFOBucket(PartFIFOBucketRec));
        }
        this.vendor = new VendorWrapper(VIHeaderRec);
        
        Id purchaseTaxId = VIHeaderRec.Vendor__r.Purchase_Tax__r.Id;
        this.AppliedQBTaxCode = VIHeaderRec.Vendor__r.Purchase_Tax__r.Accounting_Id__c;
        this.AppliedTaxRate = VIHeaderRec.Vendor__r.Purchase_Tax__r.Rate__c;
        this.AccountingPurchaseTaxList = new List<AccountingPurchaseTax>();
        if(purchaseTaxId != null) {
            if(AccessControl.ifObjectFieldIsCreateable('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            List<Applicable_Taxes__c> applicableTaxList = [Select Name, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c, Sales_Tax_Item__r.AccountingId__c,
                            Sales_Tax_Item__r.Category__r.Income_GL__c from Applicable_Taxes__c where Sales_Tax__c =: purchaseTaxId];
            for(Applicable_Taxes__c ApplicableTaxRec : applicableTaxList) {
	            this.AccountingPurchaseTaxList.add(new AccountingPurchaseTax(ApplicableTaxRec));
	        }
        }
        
        this.VRNumberSet = new Set<String>();
        this.AccountingVIGroupByGLAndTypeList = populateAccountingVIGroupByGLAndTypeList(this.AccountingVIHeaderRec, VIGroupsList, this.AccountingPartFIFOBucketList, 
        											this.AppliedQBTaxCode, this.VRNumberSet, null);
    }
    
    public AccountingVendorInvoice(Vendor_Invoicing_Header__c VIHeaderRec, List<Vendor_Invoicing_Group__c> VIGroupsList, List<Part_FIFO_Bucket__c> PartFIFOBucketList, List<Other_Charges__c> otherChargesList) {
    	this.Id = VIHeaderRec.Id;
        this.AccountingVIHeaderRec = new AccountingVIHeader(VIHeaderRec);
         
        this.AccountingOtherChargesList = new List<OtherChargesWrapper>();
        for(Other_Charges__c otherCharge : otherChargesList) {
            this.AccountingOtherChargesList.add(new OtherChargesWrapper(otherCharge));
        }
        
        this.AccountingPartFIFOBucketList = new List<AccountingFIFOBucket>();
        for(Part_FIFO_Bucket__c PartFIFOBucketRec : PartFIFOBucketList) {
            this.AccountingPartFIFOBucketList.add(new AccountingFIFOBucket(PartFIFOBucketRec));
        }
        this.vendor = new VendorWrapper(VIHeaderRec);
        
        Id purchaseTaxId = VIHeaderRec.Vendor__r.Purchase_Tax__r.Id;
        this.AppliedQBTaxCode = VIHeaderRec.Vendor__r.Purchase_Tax__r.Accounting_Id__c;
        this.AppliedTaxRate = VIHeaderRec.Vendor__r.Purchase_Tax__r.Rate__c;
        this.AccountingPurchaseTaxList = new List<AccountingPurchaseTax>();
        if(purchaseTaxId != null) {
            if(AccessControl.ifObjectFieldIsCreateable('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            List<Applicable_Taxes__c> applicableTaxList = [Select Name, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c, Sales_Tax_Item__r.AccountingId__c,
                            Sales_Tax_Item__r.Category__r.Income_GL__c from Applicable_Taxes__c where Sales_Tax__c =: purchaseTaxId];
            for(Applicable_Taxes__c ApplicableTaxRec : applicableTaxList) {
                this.AccountingPurchaseTaxList.add(new AccountingPurchaseTax(ApplicableTaxRec));
            }
        }
        
        this.VRNumberSet = new Set<String>();
        this.AccountingVIGroupByGLAndTypeList = populateAccountingVIGroupByGLAndTypeList(this.AccountingVIHeaderRec, VIGroupsList, this.AccountingPartFIFOBucketList, 
        											this.AppliedQBTaxCode, this.VRNumberSet, otherChargesList);
    }
    
    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'VIHeader'      => new Set<String>{
                                            'Id',
                                            'Name',
                                            'Vendor__r.Name',
                                            'Vendor__c',
                                            'Owner__c',
                                            'Owner__r.Name',
                                            'Invoice_Number__c',
                                            'Status__c',
                                            'Invoice_Date__c',
                                            'Closed_Invoice_Date__c',
                                            'Vendor__r.Purchase_Tax__r.Rate__c',
                                            'Vendor__r.Purchase_Tax__r.Id',
                                            'Vendor__r.Purchase_Tax__r.Accounting_Id__c',
                                            'Tax_Amount__c',
                                            'Tax_Amount_For_Other_Charges__c',
                                            'Vendor__r.Vendor_AccountingId__c',
                                            'CreatedDate',
                                            'Total__c',
                                            'Total_With_Tax__c',
                                            'FX_Conversion_Rate__c',
                                            'Total_Other_Charges__c',
                                            'AccountingId__c',
                                            'AccountingResponse__c',
                                            'SyncToken__c',
                                            'Xero_Accounting_Id__c',
                                            'Vendor__r.Xero_Vendor_Accounting_Id__c',
                                            'Sub_Total__c',
                                            'Vendor__r.Vendor_AvailForQBSync__c',
                                            'QB_Variance_JE_Accounting_Id__c',
                                            'Xero_Variance_JE_Accounting_Id__c',
                                            'Sync_Token_For_Variance_JE__c',
                                            'Vendor__r.Is_Foreign_Vendor__c',
                                            'Vendor__r.Country__r.Currency_Code__c',
                                            'Backward_Conversion_Rate__c'
                                         },
          
         'VIGroup'      => new Set<String>{  
                                            'Id',
                                            'Vendor_Invoicing_Header__c',
                                            'Vendor_Receiving_Group__c',
                                            'Vendor_Receiving_Group__r.Sublet__c',
                                            'Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Code__c',
                                            'Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Description__c',
                                            
                                            'Vendor_Receiving_Group__r.Sublet__r.Category__r.AccountingId__c',
                                            'Vendor_Receiving_Group__r.Sublet__r.Category__r.Name',
											'Vendor_Receiving_Group__r.Sublet__r.Category__r.COGS_GL__c',
             								'Vendor_Receiving_Group__r.Sublet__r.Category__r.Income_GL__c',
             								'Vendor_Receiving_Group__r.Sublet__r.Category__r.Inventory_GL__c',
             								
                                            'Vendor_Receiving_Group__r.Part__c',
                                            'Vendor_Receiving_Group__r.Part__r.Part_ID__c',
                                            'Vendor_Receiving_Group__r.Part__r.Part_Number__c',
                                            'Vendor_Receiving_Group__r.Part__r.Packaged_Part__c', 
                                            'Vendor_Receiving_Group__r.Part__r.Package_Qty__c',
                                            'Vendor_Receiving_Group__r.Part__r.Package_Unit__c',
                                            'Vendor_Receiving_Group__r.Part__r.Order_Lots__c',
                                            'Vendor_Receiving_Group__r.Part__r.Description__c',
                                            'Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Packing_Slip_Number__c',
                                            'Vendor_Receiving_Group__r.Recieved__c',
                                            'Vendor_Receiving_Group__r.Cost__c',
                                            'Vendor_Receiving_Group__r.Discount__c',
                                            'Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c',
                                            'VI_Cost__c',
                                            'VI_Discount__c',
                                            'VI_Qty__c',
                                            'VI_SubTotal__c',
                                            'PO_Type__c',
                                            'Packaged_Unit__c',
                                            'Vendor_Receiving_Group__r.Part__r.Category__r.AccountingId__c',
                                            'Vendor_Receiving_Group__r.Part__r.Category__r.Name',
											'Vendor_Receiving_Group__r.Part__r.Category__r.COGS_GL__c',
             								'Vendor_Receiving_Group__r.Part__r.Category__r.Income_GL__c',
             								'Vendor_Receiving_Group__r.Part__r.Category__r.Inventory_GL__c',
                                            'Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c',
                                            'Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c',
             								'Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c',
             								'Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Name',
                                            'Applied_Charge__c'
                                        },
                                        
		'OtherCharges' => new Set<String>{
											'Name',
											'Item_Desc__c',
											'Item_Code__c',
											'Fee__c',
											'Item_Description__c',
											'Cost__c',
											'Fee__r.Category__r.Income_GL__c',
											'Notes__c',
                                            'Is_Taxable__c',
                                            'Vendor_Invoicing_Header__c',
                                            'Applied_Amount__c'      
                                        }
         };
         
    /**
     * Name: AccountingVIHeader
     * Description: Accounting Vendor Invoice Header  class
    **/
    public class AccountingVIHeader {
        
        public String VendorName;
        public String VendorId;
        public String VendorAccountingId;
        public String OwnerName;
        public String OwnerId;
        public String Status;
        public String InvoiceNumber;
        public Date InvoiceDate;
        public Date DueDate;
        public String VIHeaderId;
        public String VIHeaderNumber;
        
        public String AccountingId;
        public String SyncToken;
        public String AccountingResponse;
        public Date CreatedDate;
        public DateTime InvoicedDateTime;
        public DateTime ClosedInvoiceDateTime;
        public Decimal TotalAmt;
        public Decimal TotalPartSubtotal;
        public Decimal TotalOtherChargeSubtotal;
        public String QBVarinaceJEAccountingId;
        public String XeroVarinaceJEAccountingId;
        public String SyncTokenForVarinaceJE;
        public String XeroAccountingId;
        public Boolean IsForeignVendor;
        public String CurrencyCode;
        public Decimal FXConversionRate;
        public Decimal BackwardFXConversionRate;
        public Decimal TotalTax;
        public Decimal TotalWithTax;
        
         /**
         * Name: AccountingVIHeader
         * Desc: Constructor
         * @param:  (1) VIHeaderRec - Vendor_Invoicing_Header__c -  Vendor Invoice Header Record
         * @return: 
         **/
        public AccountingVIHeader(Vendor_Invoicing_Header__c VIHeaderRec) {
            
            this.VendorName = VIHeaderRec.Vendor__r.Name;
            this.VendorId = VIHeaderRec.Vendor__c;
            this.VendorAccountingId = VIHeaderRec.Vendor__r.Vendor_AccountingId__c;
            this.OwnerName = VIHeaderRec.Owner__r.Name;
            this.OwnerId = VIHeaderRec.Owner__c;
            this.Status = VIHeaderRec.Status__c;
            this.InvoiceNumber = (VIHeaderRec.Invoice_Number__c != null && VIHeaderRec.Invoice_Number__c.length() > 21) ? 
                                    VIHeaderRec.Invoice_Number__c.substring(0, 21) : VIHeaderRec.Invoice_Number__c; // 21 limit of field in QB to which this variable is binded
            if(VIHeaderRec.Invoice_Date__c != null) {
                this.InvoiceDate = VIHeaderRec.Invoice_Date__c; 
                //(datetime.newInstance(VIHeaderRec.Invoice_Date__c.year(), VIHeaderRec.Invoice_Date__c.month(), VIHeaderRec.Invoice_Date__c.day())).format('MM/dd/YYYY');
            }
            this.VIHeaderId = VIHeaderRec.Id;
            this.VIHeaderNumber = VIHeaderRec.Name;
            this.AccountingId = VIHeaderRec.AccountingId__c;
            this.SyncToken = VIHeaderRec.SyncToken__c;
            this.AccountingResponse = VIHeaderRec.AccountingResponse__c;
            this.CreatedDate = VIHeaderRec.CreatedDate.date();
            
            this.InvoicedDateTime = DateTime.newInstance(VIHeaderRec.Invoice_Date__c.year(), VIHeaderRec.Invoice_Date__c.month(), VIHeaderRec.Invoice_Date__c.day());
            
            this.ClosedInvoiceDateTime = VIHeaderRec.Closed_Invoice_Date__c;
            this.TotalAmt = (VIHeaderRec.Total__c != null ? VIHeaderRec.Total__c : 0) + 
                            (VIHeaderRec.Total_Other_Charges__c != null ? VIHeaderRec.Total_Other_Charges__c : 0);
        	this.TotalPartSubtotal = (VIHeaderRec.Total__c != null ? VIHeaderRec.Total__c : 0);
            this.TotalOtherChargeSubtotal = (VIHeaderRec.Total_Other_Charges__c != null ? VIHeaderRec.Total_Other_Charges__c : 0);
        	this.XeroAccountingId = VIHeaderRec.Xero_Accounting_Id__c;
            this.QBVarinaceJEAccountingId = VIHeaderRec.QB_Variance_JE_Accounting_Id__c;
            this.XeroVarinaceJEAccountingId = VIHeaderRec.Xero_Variance_JE_Accounting_Id__c;
            this.SyncTokenForVarinaceJE = VIHeaderRec.Sync_Token_For_Variance_JE__c;
            this.IsForeignVendor = VIHeaderRec.Vendor__r.Is_Foreign_Vendor__c;
            this.CurrencyCode = ForeignExchangeUtil.getVendorCurrencyCode(VIHeaderRec.Vendor__r);
            this.FXConversionRate = VIHeaderRec.FX_Conversion_Rate__c != null ? VIHeaderRec.FX_Conversion_Rate__c : 1;
            this.BackwardFXConversionRate = VIHeaderRec.Backward_Conversion_Rate__c != null ? VIHeaderRec.Backward_Conversion_Rate__c : 1;
            this.TotalTax = ((VIHeaderRec.Tax_Amount__c != null ? VIHeaderRec.Tax_Amount__c : 0) + (VIHeaderRec.Tax_Amount_For_Other_Charges__c != null ? 
            VIHeaderRec.Tax_Amount_For_Other_Charges__c.setScale(2, RoundingMode.HALF_UP) : 0)).setScale(2, RoundingMode.HALF_UP);
            this.TotalWithTax = VIHeaderRec.Total_With_Tax__c;
        }
    }
    
    /**
     * Name: AccountingVIGroup
     * Description: Vendor Invoice Group Class
    **/
   public class AccountingVIGroup {
        
        public String ItemDesc;
        public String PackingNumber;
        public Decimal ReceivingQty;
        public Decimal ReceivingCost;
        public Decimal ReceivingDiscount;
        public Decimal ReceivingCostMinusDiscount;
        public Decimal ReceivingFXConversionRate;
        public Decimal InvoiceQty;
        public Decimal InvoiceCost;
        public Decimal Discount;
        public Decimal SubTotal;
        public String VIGroupId;
        public String OrderType;
        public String PackageUnit;
        public Decimal PackageQty;
        public Decimal DiscountAmout;
        public String PartId;
        public String SubletId;
       
        public Decimal InvoiceTotalQty;
        public Decimal InvoiceCostMinusDiscount;
        public Decimal AppliedCharge;
        public CategoryWrapper categoryRef;
		public String COGS_GL;
        public String Income_GL;
        public String Inventory_GL;
        
        public Boolean IsReceivingGroupSOLIInvoiced;
        public DateTime ReceivingGroupSOLIInvoicedDateTime; 
        public DateTime ReceivingGroupSOLIClosedInvoicedDateTime;

         /**
         * Name: VIGroup
         * Desc: Constructor
         * @param:  (1) VIGroupRec - Vendor_Invoicing_Group__c -  Vendor Invoice Group Record
         * @return: 
         **/
        public AccountingVIGroup(Vendor_Invoicing_Group__c VIGroupRec) {
            
            if(VIGroupRec.Vendor_Receiving_Group__r.Part__c != null) {
            	this.ItemDesc = VIGroupRec.Vendor_Receiving_Group__r.Part__r.Part_Number__c + ' - ' + VIGroupRec.Vendor_Receiving_Group__r.Part__r.Description__c; // Changed By Pooja 11 Jan 2017: Part_ID__c  -> Part_Number__c
            	
            	this.categoryRef = new CategoryWrapper(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Category__r.AccountingId__c, VIGroupRec.Vendor_Receiving_Group__r.Part__r.Category__r.Name);
            	this.COGS_GL = VIGroupRec.Vendor_Receiving_Group__r.Part__r.Category__r.COGS_GL__c; // Added 17 Jan. 2017
	            this.Income_GL = VIGroupRec.Vendor_Receiving_Group__r.Part__r.Category__r.Income_GL__c; // Added 17 Jan. 2017
	            this.Inventory_GL = VIGroupRec.Vendor_Receiving_Group__r.Part__r.Category__r.Inventory_GL__c; // Added 17 Jan. 2017
            
            } else if(VIGroupRec.Vendor_Receiving_Group__r.Sublet__c != null) {
            	String code = (VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Code__c != null) ? 
            			VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Code__c : '';
            			
            	String description = (VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Description__c != null) ? 
            			VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Item_Description__c : '';
            	this.ItemDesc = (code + ((code.length() > 0 && description.length() > 0) ? ' - ' : '') + description);
            	
            	this.categoryRef = new CategoryWrapper(VIGroupRec.Vendor_Receiving_Group__r.Sublet__r.Category__r.AccountingId__c, VIGroupRec.Vendor_Receiving_Group__r.Sublet__r.Category__r.Name);
            	this.COGS_GL = VIGroupRec.Vendor_Receiving_Group__r.Sublet__r.Category__r.COGS_GL__c;
	            this.Income_GL = VIGroupRec.Vendor_Receiving_Group__r.Sublet__r.Category__r.Income_GL__c;
	            this.Inventory_GL = VIGroupRec.Vendor_Receiving_Group__r.Sublet__r.Category__r.Inventory_GL__c;
            }
            
            this.PackingNumber = VIGroupRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Packing_Slip_Number__c;
            this.ReceivingQty = VIGroupRec.Vendor_Receiving_Group__r.Recieved__c;
            this.ReceivingCost = (VIGroupRec.Vendor_Receiving_Group__r.Cost__c != null) ? VIGroupRec.Vendor_Receiving_Group__r.Cost__c : 0.00;
            this.ReceivingDiscount = VIGroupRec.Vendor_Receiving_Group__r.Discount__c != null ? VIGroupRec.Vendor_Receiving_Group__r.Discount__c : 0;
            this.ReceivingCostMinusDiscount = this.ReceivingCost - ((this.ReceivingCost * this.ReceivingDiscount) / 100);
            this.ReceivingFXConversionRate = (VIGroupRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__c != null) ? (VIGroupRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c) : 1;
            this.InvoiceCost = (VIGroupRec.VI_Cost__c != null) ? VIGroupRec.VI_Cost__c : 0.00;
            this.Discount = VIGroupRec.VI_Discount__c;
            this.SubTotal = (VIGroupRec.VI_SubTotal__c != null) ? VIGroupRec.VI_SubTotal__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.VIGroupId = VIGroupRec.Id;
            if(VIGroupRec.VI_Cost__c == null || this.ReceivingQty == null || this.Discount == null) {
                this.DiscountAmout = 0.00;
            } else {
                this.DiscountAmout = ((VIGroupRec.VI_Cost__c * this.ReceivingQty * this.Discount) / 100).setScale(2, RoundingMode.HALF_UP);
            }
            
            this.OrderType = '';
            if(VIGroupRec.Vendor_Receiving_Group__r.Part__c != null) {
	            if(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Packaged_Part__c) {
	                this.ReceivingQty = this.ReceivingQty / VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Qty__c;
                    this.OrderType = 'Ordered as ' + VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Qty__c + '/' + ((String.isBlank(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Unit__c) && VIGroupRec.Vendor_Receiving_Group__r.Part__r.Packaged_Part__c) ? 'PKG': VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Unit__c);
	                if(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Order_Lots__c > 1) {
	                    this.OrderType += ' in Lots of ' + VIGroupRec.Vendor_Receiving_Group__r.Part__r.Order_Lots__c;
	                }
	            } else if(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Order_Lots__c > 1) {
	                this.OrderType += 'Ordered as in Lots of ' + VIGroupRec.Vendor_Receiving_Group__r.Part__r.Order_Lots__c;
	            }
            }
            this.InvoiceQty = this.ReceivingQty;
            this.PackageUnit = VIGroupRec.Vendor_Receiving_Group__r.Part__c != null ? ((String.isBlank(VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Unit__c) && VIGroupRec.Vendor_Receiving_Group__r.Part__r.Packaged_Part__c) ? 'PKG': VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Unit__c) : 'EA';
            this.PackageQty = (VIGroupRec.Vendor_Receiving_Group__r.Part__c != null ? VIGroupRec.Vendor_Receiving_Group__r.Part__r.Package_Qty__c : 1);
            this.PartId = VIGroupRec.Vendor_Receiving_Group__r.Part__c;
            this.SubletId = VIGroupRec.Vendor_Receiving_Group__r.Sublet__c;
            this.InvoiceTotalQty = (VIGroupRec.VI_Qty__c != null) ? VIGroupRec.VI_Qty__c.setScale(2, RoundingMode.HALF_UP) : 1;
            this.InvoiceCostMinusDiscount = this.InvoiceCost - ((this.InvoiceCost * this.Discount) / 100); // Added By Pooja 11 Jan 2017
            this.AppliedCharge = (VIGroupRec.Applied_Charge__c != null) ? VIGroupRec.Applied_Charge__c.setScale(2, RoundingMode.HALF_UP) : 0.00;

            this.IsReceivingGroupSOLIInvoiced = VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__c != null 
                                                    && VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null;
            this.ReceivingGroupSOLIClosedInvoicedDateTime = this.IsReceivingGroupSOLIInvoiced ? (VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c) : System.now();                                        
            this.ReceivingGroupSOLIInvoicedDateTime = this.IsReceivingGroupSOLIInvoiced ? (VIGroupRec.Vendor_Receiving_Group__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c) : System.now();
        
        }
    }
    
     /**
     * Name: VendorWrapper
     * Description: Vendor Class
    **/
    public class VendorWrapper{
        
        public String AccountingId;
        public String Name;
        public String XeroVendorAccountingId;
        
        public VendorWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
        
        public VendorWrapper(Vendor_Invoicing_Header__c viHeaderRec) {
            this.AccountingId = viHeaderRec.Vendor__r.Vendor_AccountingId__c;
            this.Name = viHeaderRec.Vendor__r.Name;
            this.XeroVendorAccountingId = viHeaderRec.Vendor__r.Xero_Vendor_Accounting_Id__c;
        }
    }
    
    public class AccountRefWrapper {
        public String AccountingId;
        
        public AccountRefWrapper(String AccountingId) {
            this.AccountingId = AccountingId;
        }
    }
    
    /**
     * Name: CategoryWrapper
     * Description: Category Class
    **/
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
    	
        // Constructor
	    public AccountingPurchaseTax(Applicable_Taxes__c  applicableTaxRec) { 
	        this.SalesTaxName = applicableTaxRec.Sales_Tax_Item__r.Name__c;
	        this.SalesTaxRate = applicableTaxRec.Sales_Tax_Item__r.Rate__c;
	        this.CategoyRef = applicableTaxRec.Sales_Tax_Item__r.Category__r.Income_GL__c;
            this.QBTaxCodeRef = applicableTaxRec.Sales_Tax_Item__r.AccountingId__c;
	    }
    }
    
    public class OtherChargesWrapper {
    	public String Name;
    	public String ItemDesc;
    	public String Fee;
    	public String Notes;
    	public Decimal Cost;
    	public String CategoyRef;
    	public Boolean IsTaxable;
        public Decimal AppliedAmount;
        
        public OtherChargesWrapper(Other_Charges__c otherChargesRec) {
            this.Name = otherChargesRec.Name;
            this.ItemDesc = (otherChargesRec.Item_Desc__c != null) ? otherChargesRec.Item_Desc__c : '';
            this.Fee = (otherChargesRec.Fee__c != null) ? otherChargesRec.Fee__c : '';
            this.Notes = (otherChargesRec.Notes__c != null) ? otherChargesRec.Notes__c : '';
            this.Cost = (otherChargesRec.Cost__c != null) ? otherChargesRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.CategoyRef = otherChargesRec.Fee__r.Category__r.Income_GL__c;
            this.IsTaxable = otherChargesRec.Is_Taxable__c;
            this.AppliedAmount = (otherChargesRec.Applied_Amount__c != null) ? otherChargesRec.Applied_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00; 
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
    
    public class AccountingVIGroupByGLAndType {
    	
    	public String Type;
    	public String GLNumber;
    	public Decimal Total;
    	public String TaxCodeAccId;
    	
    	public AccountingVIGroupByGLAndType(String typeValue, String GLNumber, Decimal total, String taxCodeAccId) {
    		this.Type = typeValue;
    		this.GLNumber = GLNumber;
    		this.Total = total;
    		this.TaxCodeAccId = taxCodeAccId;
    	}
    }
    
    private static List<AccountingVIGroupByGLAndType> populateAccountingVIGroupByGLAndTypeList(AccountingVIHeader accountingVIHeaderRec, 
    													List<Vendor_Invoicing_Group__c> VIGroupsList, List<AccountingFIFOBucket> accountingPartFIFOBucketList, 
    													String appliedQBTaxCode, Set<String> VRNumberSet, List<Other_Charges__c> otherChargesList) {
    	List<AccountingVIGroupByGLAndType> accountingVIGroupByGLAndTypeList = new List<AccountingVIGroupByGLAndType>();
    	
    	Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap = populateLineTypeToGLNumberToAmountMap(accountingVIHeaderRec, VIGroupsList, 
    																		accountingPartFIFOBucketList, VRNumberSet, otherChargesList);
        for(String typeValue: lineTypeToGLNumberToAmountMap.keySet()) {
        	if(lineTypeToGLNumberToAmountMap.get(typeValue) != null) {
        		for(String GLNumber: lineTypeToGLNumberToAmountMap.get(typeValue).keySet()) {
        			if(lineTypeToGLNumberToAmountMap.get(typeValue).get(GLNumber) != null) {
        				accountingVIGroupByGLAndTypeList.add(new AccountingVIGroupByGLAndType(typeValue, GLNumber, 
        														lineTypeToGLNumberToAmountMap.get(typeValue).get(GLNumber), 
        														(typeValue == INVENTORY_RECEIVED ? appliedQBTaxCode : QBUtil.nonTaxablePurchaseCodeAccId)));
        			}
	        	}
        	}
        }
    	return accountingVIGroupByGLAndTypeList;
    }
    
    private static Map<String, Map<String, Decimal>> populateLineTypeToGLNumberToAmountMap(AccountingVIHeader accountingVIHeaderRec, 
    													List<Vendor_Invoicing_Group__c> VIGroupsList, List<AccountingFIFOBucket> accountingPartFIFOBucketList, 
    													Set<String> VRNumberSet, List<Other_Charges__c> otherChargesList) {
    	Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap = new Map<String, Map<String, Decimal>>();
    	
        for(Vendor_Invoicing_Group__c VIGroupRec : VIGroupsList) {
            AccountingVIGroup VIGroupObj = new AccountingVIGroup(VIGroupRec);
            VRNumberSet.add(VIGroupRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Name);
            
            // default line item Inventory received
            setInventoryReceivedLine(lineTypeToGLNumberToAmountMap, VIGroupObj);
            
            Decimal perItemCostVariance = (VIGroupObj.ReceivingCostMinusDiscount - VIGroupObj.InvoiceCostMinusDiscount);
            Decimal appliedCharge = VIGroupObj.AppliedCharge;
            if(accountingVIHeaderRec.IsForeignVendor) {
                Decimal localInvoiceCost = ForeignExchangeUtil.getConvertedAmountInLocalCurrencyNotRounded(VIGroupObj.InvoiceCostMinusDiscount, accountingVIHeaderRec.FXConversionRate);
                Decimal localReceivingCost = ForeignExchangeUtil.getConvertedAmountInLocalCurrencyNotRounded(VIGroupObj.ReceivingCostMinusDiscount, VIGroupObj.ReceivingFXConversionRate);
                perItemCostVariance = (localReceivingCost - localInvoiceCost);

                system.debug('localInvoiceCost::'+localInvoiceCost);
                system.debug('localReceivingCost::'+localReceivingCost);
                system.debug('perItemCostVariance::'+perItemCostVariance);
                
                appliedCharge = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(appliedCharge, accountingVIHeaderRec.FXConversionRate);
            }
            if(perItemCostVariance != null && perItemCostVariance != 0) {
                setReceivingAdjustmentLine(lineTypeToGLNumberToAmountMap, VIGroupObj, perItemCostVariance);    
            }

            // sold on CO before vendor invoicing/ pre sold cost adjustment
            appliedCharge = (appliedCharge != null ? appliedCharge : 0);
            Decimal perItemAppliedCharge = ((appliedCharge/VIGroupObj.InvoiceTotalQty).setScale(2, RoundingMode.HALF_UP));
            Decimal preSoldCostAdjAmount = (perItemCostVariance != null ? perItemCostVariance : 0) - perItemAppliedCharge; // minus because perItemCostVariance is (VRCOst - VICost) and applied charge should be added to VICost
            if(preSoldCostAdjAmount != 0) {
                setPreSoldAdjustmentLine(lineTypeToGLNumberToAmountMap, VIGroupObj, accountingPartFIFOBucketList, preSoldCostAdjAmount, accountingVIHeaderRec);
            }
            setOtherChargeAllocationsLine(lineTypeToGLNumberToAmountMap, VIGroupObj.Inventory_GL, appliedCharge);
        }

        if(otherChargesList != null) {
            for(Other_Charges__c otherChargeRec: otherChargesList) {
                OtherChargesWrapper otherChargeObj = new OtherChargesWrapper(otherChargeRec);
                Decimal appliedAmount = otherChargeObj.AppliedAmount;
                if(accountingVIHeaderRec.IsForeignVendor) {
                    appliedAmount = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(appliedAmount, accountingVIHeaderRec.FXConversionRate);
                }
                setOtherChargeAllocationsLine(lineTypeToGLNumberToAmountMap, otherChargeObj.CategoyRef, appliedAmount*-1);
            }
        }
    	return lineTypeToGLNumberToAmountMap;
    }

    private static void setOtherChargeAllocationsLine(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, String glNumber, Decimal amount) {
    	if(amount == null || amount == 0) return;
        if(!lineTypeToGLNumberToAmountMap.containsKey(OTHER_CHARGE_ALLOCATION)) {
        	lineTypeToGLNumberToAmountMap.put(OTHER_CHARGE_ALLOCATION, new Map<String, Decimal>());
        }
        Map<String, Decimal> GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get(OTHER_CHARGE_ALLOCATION);

        // Inventory GL assigned to the category
        if(!GLNumberToAmountMap.containsKey(glNumber)) {
            GLNumberToAmountMap.put(glNumber, 0);
        }
        
        GLNumberToAmountMap.put(glNumber, GLNumberToAmountMap.get(glNumber) + amount);
        lineTypeToGLNumberToAmountMap.put(OTHER_CHARGE_ALLOCATION, GLNumberToAmountMap);
    }
    
    private static void setInventoryReceivedLine(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, AccountingVIGroup VIGroupObj) {
    	String receivedInvGL = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
    	
    	if(!lineTypeToGLNumberToAmountMap.containsKey(INVENTORY_RECEIVED)) {
        	lineTypeToGLNumberToAmountMap.put(INVENTORY_RECEIVED, new Map<String, Decimal>());
        }
        Map<String, Decimal> GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get(INVENTORY_RECEIVED);
        if(!GLNumberToAmountMap.containsKey(receivedInvGL)) {
        	GLNumberToAmountMap.put(receivedInvGL, 0);
        }
        
        GLNumberToAmountMap.put(receivedInvGL, GLNumberToAmountMap.get(receivedInvGL) + VIGroupObj.SubTotal);
        lineTypeToGLNumberToAmountMap.put(INVENTORY_RECEIVED, GLNumberToAmountMap);
    }
    
    private static void setReceivingAdjustmentLine(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, AccountingVIGroup VIGroupObj, Decimal perItemCostVariance) {
        if(perItemCostVariance != null && perItemCostVariance != 0) {
        	String receivedInvGL = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
        	
        	if(!lineTypeToGLNumberToAmountMap.containsKey('Receiving adjustment')) {
            	lineTypeToGLNumberToAmountMap.put('Receiving adjustment', new Map<String, Decimal>());
            }
            
            Map<String, Decimal> GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get('Receiving adjustment');
            
            // Received Inventory Accrual GL
            if(!GLNumberToAmountMap.containsKey(receivedInvGL)) {
            	GLNumberToAmountMap.put(receivedInvGL, 0);
            }
            Decimal totalCostVariance = (VIGroupObj.InvoiceTotalQty * perItemCostVariance).setScale(2, RoundingMode.HALF_UP);
            system.debug('VIGroupObj.InvoiceTotalQty::'+VIGroupObj.InvoiceTotalQty);
            system.debug('totalCostVariance::'+totalCostVariance);
            GLNumberToAmountMap.put(receivedInvGL, GLNumberToAmountMap.get(receivedInvGL) + totalCostVariance);
            
            // Inventory GL assigned to the category
            if(!GLNumberToAmountMap.containsKey(VIGroupObj.Inventory_GL)) {
            	GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, 0);
            }
            GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, GLNumberToAmountMap.get(VIGroupObj.Inventory_GL) + (totalCostVariance * -1));
            
            lineTypeToGLNumberToAmountMap.put('Receiving adjustment', GLNumberToAmountMap);
        }
    }
    
    private static void setPreSoldAdjustmentLine(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, AccountingVIGroup VIGroupObj, 
    												List<AccountingFIFOBucket> accountingPartFIFOBucketList, Decimal perItemCostVariance, AccountingVIHeader accountingVIHeaderRec) {
    	Map<Id, List<AccountingFIFOBucket>> partIdToFIFOBucketMap = new Map<Id, List<AccountingFIFOBucket>>();
        for(AccountingFIFOBucket partFIFOBucketRec : accountingPartFIFOBucketList) {
            if(!partIdToFIFOBucketMap.containsKey(partFIFOBucketRec.PartId)) {
                partIdToFIFOBucketMap.put(partFIFOBucketRec.PartId, new List<AccountingFIFOBucket>());
            }
            partIdToFIFOBucketMap.get(partFIFOBucketRec.PartId).add(partFIFOBucketRec);
        }
        
        Decimal totalQtyOut = 0;
        if(partIdToFIFOBucketMap.containsKey(VIGroupObj.PartId)) {
            for(AccountingFIFOBucket PartFIFOBucketRec : partIdToFIFOBucketMap.get(VIGroupObj.PartId)) {
                totalQtyOut += PartFIFOBucketRec.QtyOut;
            }
        }
        
        // pre sold Part
        setPreSoldCostAdjLineForPart(lineTypeToGLNumberToAmountMap, VIGroupObj, totalQtyOut, perItemCostVariance);
        
        // pre sold Sublet
        setPreSoldCostAdjLineForSublet(lineTypeToGLNumberToAmountMap, VIGroupObj, perItemCostVariance, accountingVIHeaderRec);
    }
    
    private static void setPreSoldCostAdjLineForPart(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, AccountingVIGroup VIGroupObj, Decimal totalQtyOut, 
    Decimal perItemCostVariance) {
    	if(perItemCostVariance != null && perItemCostVariance != 0 && totalQtyOut > 0) {
        	if(!lineTypeToGLNumberToAmountMap.containsKey('Pre-sold cost adjustment')) {
            	lineTypeToGLNumberToAmountMap.put('Pre-sold cost adjustment', new Map<String, Decimal>());
            }
            Map<String, Decimal> GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get('Pre-sold cost adjustment');
            
            // Inventory GL assigned to the category
            if(!GLNumberToAmountMap.containsKey(VIGroupObj.Inventory_GL)) {
            	GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, 0);
            }
            
            Decimal totalQtyOutVariance = (totalQtyOut * perItemCostVariance).setScale(2, RoundingMode.HALF_UP);
            GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, GLNumberToAmountMap.get(VIGroupObj.Inventory_GL) + totalQtyOutVariance);
            
            // COGS GL assigned to the category
            if(!GLNumberToAmountMap.containsKey(VIGroupObj.COGS_GL)) {
            	GLNumberToAmountMap.put(VIGroupObj.COGS_GL, 0);
            }
            GLNumberToAmountMap.put(VIGroupObj.COGS_GL, GLNumberToAmountMap.get(VIGroupObj.COGS_GL) + (totalQtyOutVariance * -1));
            
            lineTypeToGLNumberToAmountMap.put('Pre-sold cost adjustment', GLNumberToAmountMap);
        }
    }
    
    private static void setPreSoldCostAdjLineForSublet(Map<String, Map<String, Decimal>> lineTypeToGLNumberToAmountMap, AccountingVIGroup VIGroupObj, Decimal perItemCostVariance, 
    													AccountingVIHeader accountingVIHeaderRec) {
    	DateTime vendorInvoiceFinalizeDate = (accountingVIHeaderRec.ClosedInvoiceDateTime != null) ? 
        					accountingVIHeaderRec.ClosedInvoiceDateTime : accountingVIHeaderRec.InvoicedDateTime;
        if(VIGroupObj.SubletId != null && perItemCostVariance != null && perItemCostVariance != 0 && VIGroupObj.IsReceivingGroupSOLIInvoiced && 
        		(VIGroupObj.ReceivingGroupSOLIClosedInvoicedDateTime < vendorInvoiceFinalizeDate)) {
        	if(!lineTypeToGLNumberToAmountMap.containsKey('Pre-sold cost adjustment')) {
            	lineTypeToGLNumberToAmountMap.put('Pre-sold cost adjustment', new Map<String, Decimal>());
            }
            Map<String, Decimal> GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get('Pre-sold cost adjustment');
            
            // Inventory GL assigned to the category
            if(!GLNumberToAmountMap.containsKey(VIGroupObj.Inventory_GL)) {
            	GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, 0);
            }
            
            Decimal totalSoldQtyVariance = (VIGroupObj.ReceivingQty * perItemCostVariance).setScale(2, RoundingMode.HALF_UP);
            GLNumberToAmountMap.put(VIGroupObj.Inventory_GL, GLNumberToAmountMap.get(VIGroupObj.Inventory_GL) + totalSoldQtyVariance);
            
            // COGS GL assigned to the category
            if(!lineTypeToGLNumberToAmountMap.containsKey('Pre-sold cost adjustment')) {
            	lineTypeToGLNumberToAmountMap.put('Pre-sold cost adjustment', new Map<String, Decimal>());
            }
            GLNumberToAmountMap = lineTypeToGLNumberToAmountMap.get('Pre-sold cost adjustment');
            if(!GLNumberToAmountMap.containsKey(VIGroupObj.COGS_GL)) {
            	GLNumberToAmountMap.put(VIGroupObj.COGS_GL, 0);
            }
            GLNumberToAmountMap.put(VIGroupObj.COGS_GL, GLNumberToAmountMap.get(VIGroupObj.COGS_GL) + (totalSoldQtyVariance * -1));
            
            lineTypeToGLNumberToAmountMap.put('Pre-sold cost adjustment', GLNumberToAmountMap);
        }
    }
}
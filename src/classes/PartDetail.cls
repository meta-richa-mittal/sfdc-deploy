/**
 * Author: Tarun Khandelwal
 * Since: June 15, 2015
 * Name: PartDetail
 * Description: Apex class to handle JSON related oprations of Part entity.
**/
public without sharing class PartDetail {
    
    // Id
    public String Id;
    
    // Name
    public String Name;
    
    // Part Number
    public String PartNumber;
    
    // Decsription
    public String Description;
    
    // Vendor Id
    public String VendorId;
    
    // Vendor Name
    public String VendorName;
    
    // Vendor Name
    public String VendorCode;
    
    // Vendor Name
    public String PartId;
    
    // Category Id
    public String CategoryId;
    
    // Category Name
    public String CategoryName;
    
    // Price Method
    public String PriceMethod;
    
    // ReplacedBy Id
    public String ReplacedById;
    
    // ReplacedBy Name
    public String ReplacedByName;
    
    // Packaged Part
    public Boolean IsPackagedPart;
    
    // Packaged Qty
    public Decimal PackagedQty;
    
    // Packaged Unit
    public String PackagedUnit;
    
    // Is Taxable
    public Boolean IsTaxable;
    
    // In Stock Qty
    public Decimal InStockQty;
    
    // Location
    public String Location;
    
    // Cost
    public Decimal Cost; 
    
    // Packaged Cost
    public Decimal PackagedCost;
    
    // MSRP
    public Decimal MSRP;
    
    // Retail
    public Decimal Retail;
    
    // EnviroFee 
    public Decimal EnviroFee;
    
    public String EnvFeeName;
    public String EnvFeeDesc;
    public String EnvFeeId;
    
    // AutoReorder At
    public Decimal AutoReorderAt;
    
    // AutoReorder To
    public Decimal AutoReorderTo;
    
    // Order Lots
    public Decimal OrderLots; 
    
    // Active
    public Boolean Active;
    
    // Status of Part 
    public String Status;
    
    // Qty Commited 
    public Decimal QtyCommited;
    
    // Qty Commited 
    public Decimal QtyAvailable;
    
    // Qty Commited 
    public Decimal QtyOnOrder;
    
    // Revenue Lifetime
    public Decimal RevenueLifetime;
    
    //Special Order
    public Decimal SpecialOrder;
    
    // IsOrderLot
	public Boolean IsOrderLot;
	
    // Last Sold
    public String LastSold;
    
    // Last Ordered
    public String LastOrdered;
    
    // ApplicableTaxId
    public String ApplicableTaxId;
    
    // ApplicableTaxName 
	public String ApplicableTaxName;
	
	//Mfg Part // Added by richa 25/11/2016
	public String MfgPart;
	
	//SKU Number // Added by richa 25/11/2016
	public String SKUNumber;
	
	//Non-Inventory Part // Added by richa 25/11/2016 
	public Boolean IsNonInventoryPart;
	
	public List<String> AssignedTags;
    public List<String> AssignedLocations;
    public Decimal ForeignCost;
    public Decimal ForeignPkgCost;
    public String CurrencyCode;
    public Boolean IsForeignVendor;
    public Decimal ConversionRate;

    public String RetailBaseValueOnVendor;
   	
   	public Escalator RetailEscalatorForVendor;
   	
   	public Decimal RetailRoundingCentValueOnVendor;
   	
   	public Boolean RetailRoundingFlagOnVendor;
   	
   	public Boolean IsCalculatePartRetailPriceOnVendor;
   	public Decimal ProfitAmount;
   	public Decimal ProfitPercent;
    
    public String PartType;
    
    public Boolean IsBRPPart;
    public Decimal SalePrice;
    public String CassonsId;
    public Boolean IsPublishInFeeds;
    public String ShopifyId;
    public String ShopifyUrl;
    public Decimal CassonsSOH;

    public Decimal AverageCost;
    public Boolean IsDescriptionLockedIn;
    public Boolean IsMSRPLockedIn;
    public Boolean IsRetailLockedIn;

    // Constructor
    public PartDetail(Part__c partRec, Escalator__c vendorRetailEscRec){
        this.Id = partRec.Id;
        this.Name = partRec.Name;
        this.PartNumber = partRec.Part_Number__c;
        this.Description = partRec.Description__c;
        this.VendorId = partRec.Vendor__c;
        this.IsForeignVendor = partRec.Vendor__r.Is_Foreign_Vendor__c;
        if(partRec.Vendor__c != null && this.IsForeignVendor && partRec.Vendor__r.Country__c != null) {
            this.CurrencyCode = partRec.Vendor__r.Country__r.Currency_Code__c;
            this.ConversionRate = XeroUtility.isXeroEnabled() ? partRec.Vendor__r.Country__r.Backward_Conversion_Rate__c : partRec.Vendor__r.Country__r.Conversion_Rate_With_Markup__c;
        }
        this.VendorName = partRec.Vendor__r.Name;
        this.RetailBaseValueOnVendor = partRec.Vendor__r.Retail_Base_Value__c;
        if(vendorRetailEscRec != null) {
            this.RetailEscalatorForVendor = new Escalator(vendorRetailEscRec);
        }
        this.RetailRoundingCentValueOnVendor = partRec.Vendor__r.Retail_Round_To__c;
        this.RetailRoundingFlagOnVendor= partRec.Vendor__r.Retail_Rounding__c;
        this.IsCalculatePartRetailPriceOnVendor = partRec.Vendor__r.Is_Calculate_Part_Retail_Price__c;
        this.partId = partRec.Part_ID__c;
        this.VendorCode = partRec.Vendor_Code__c;
        this.CategoryId = partRec.Category__c;
        this.CategoryName = partRec.Category__r.Name;
        this.PriceMethod = '';
        this.ReplacedById = partRec.Superseded_By__c;
        this.ReplacedByName = partRec.Superseded_By__r.Part_ID__c;
        this.IsPackagedPart = partRec.Packaged_Part__c;
        this.PackagedQty = partRec.Package_Qty__c;
        this.PackagedUnit = ((String.isBlank(partRec.Package_Unit__c) && partRec.Packaged_Part__c) ? 'PKG': partRec.Package_Unit__c);
        this.IsTaxable = partRec.Taxable__c;
        this.InStockQty = partRec.Qty_In_Stock__c;
        this.ForeignCost = (partRec.Foreign_Cost__c != null) ? partRec.Foreign_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.ForeignPkgCost = (partRec.Foreign_Pkg_Cost__c != null) ? partRec.Foreign_Pkg_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.Cost = (partRec.Last_Cost__c != null) ? partRec.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.PackagedCost = (partRec.Package_Cost__c != null) ? partRec.Package_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.MSRP = (partRec.MSRP__c != null) ? partRec.MSRP__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.Retail = (partRec.Retail_Price__c != null) ? partRec.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.EnviroFee = (partRec.Enviro_Fee__c != null) ? partRec.Enviro_Fee__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.EnvFeeId = partRec.Enviro_Fee_Code__c;
        this.EnvFeeName = (partRec.Enviro_Fee_Code__c != null) ? partRec.Enviro_Fee_Code__r.Fee_Unique_Name__c : '';
        this.EnvFeeDesc = (partRec.Enviro_Fee_Code__c != null) ? partRec.Enviro_Fee_Code__r.Description__c : '';
        
        this.AutoReorderAt = partRec.Auto_reorder_Min__c;
        this.AutoReorderTo = partRec.Auto_reorder_Max__c;
        this.OrderLots = partRec.Order_Lots__c;
        this.Active = partRec.Active__c;
        this.QtyCommited = partRec.Qty_Committed__c;
        this.RevenueLifetime = partRec.Qty_Committed__c * partRec.Retail_Price__c;
        this.QtyCommited = partRec.Qty_Committed__c;
        this.QtyAvailable = partRec.AvailableParts__c;
        this.QtyOnOrder = partRec.Qty_On_Order__c ;
        this.Status = partRec.Status__c;
    
        this.IsOrderLot = partRec.Is_OrderLot__c;
        this.ApplicableTaxId = partRec.Applicable_Tax__c;
        this.ApplicableTaxName = (partRec.Applicable_Tax__c != null) ? partRec.Applicable_Tax__r.Name__c : null;
        
        Decimal taxRate = (partRec.Applicable_Tax__r.Rate__c != null) ? partRec.Applicable_Tax__r.Rate__c : 0;
        Decimal preTaxRetail = GeneralConfiguration.getTaxIncludingPricing() ? (this.Retail / (1 + (taxRate / 100))).setScale(2, RoundingMode.HALF_UP) : this.Retail;
        this.ProfitAmount = (preTaxRetail - this.Cost);
        this.ProfitPercent = (this.ProfitAmount == 0 || preTaxRetail == 0) ? 0 : ((this.ProfitAmount / preTaxRetail) * 100).setScale(2, RoundingMode.HALF_UP);
        
        this.MfgPart = partRec.Mfg_Part__c; // Added by richa 25/11/2016
        this.SKUNumber = partRec.SKU_Number__c; // Added by richa 25/11/2016
        this.IsNonInventoryPart = partRec.Non_Inventory_Part__c; // Added by richa 25/11/2016
        if(partRec.Non_Inventory_Part__c) { // if Added by richa 25/11/2016
        	this.Status = 'Not Stocked';
        }
        this.AssignedTags = TagUtil.getTagsList(partRec);
        this.AssignedLocations = LocationManagementService.getLocationsList(partRec);
        this.Location =  string.join(this.AssignedLocations,',').trim();
        this.PartType = (partRec.Part_Type__c != null) ? partRec.Part_Type__c : 'Part';
    	this.IsBRPPart = BRPUtility.getAllBRPVendorsIdSet().contains(partRec.Vendor__c);
        this.SalePrice = (partRec.Sale_Price__c != null) ? partRec.Sale_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        if(GeneralConfiguration.isCassonsEnabled() && String.isNotBlank(partRec.Cassons_ID__c)) {
            this.CassonsId = partRec.Cassons_ID__c;
        }
        this.CassonsSOH = (partRec.Cassons_SOH__c != null) ? partRec.Cassons_SOH__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        
        this.IsPublishInFeeds = partRec.Publish_in_feeds__c;
        if(GeneralConfiguration.isShopifyIntegrationEnabled() && String.isNotBlank(partRec.Shopify_Product_Id__c)) {
            this.ShopifyId = partRec.Shopify_Product_Id__c;
            this.ShopifyUrl = partRec.Shopify_URL__c;
        }
        this.AverageCost = partRec.Average_Cost__c != null ? partRec.Average_Cost__c : 0;
        this.IsDescriptionLockedIn = partRec.Is_Description_Locked_In__c;
        this.IsMSRPLockedIn = partRec.Is_MSRP_Locked_In__c;
        this.IsRetailLockedIn = partRec.Is_Retail_Locked_In__c;
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: PartDetail - Class Object
    **/
    public static List<PartDetail> parse(String JSONString) {
        return (List<PartDetail>) System.JSON.deserialize(JSONString, List<PartDetail>.class);
    }
    
    // A method to define the list of part fields to be used in queries
    public static List<String> fieldsList(){
        List<String> partFields = new List<String>{ 'Id',
                                                    'Name',
                                                    'Part_Number__c',
                                                    'Description__c',
                                                    'Vendor__c',
                                                    'Vendor__r.Name',
                                                    'Part_Id__c',
                                                    'Category__c',
                                                    'Category__r.Name',
                                                    'Superseded_By__c',
                                                    'Superseded_By__r.Part_ID__c',
                                                    'Packaged_Part__c',
                                                    'Package_Qty__c',
                                                    'Package_Unit__c',
                                                    'Taxable__c',
                                                    'Qty_In_Stock__c', 
                                                    'Vendor_Code__c',
                                                    'Location__c',
                                                    'Last_Cost__c',
                                                    'Package_Cost__c',
                                                    'Foreign_Cost__c',
                                                    'Foreign_Pkg_Cost__c',
                                                    'MSRP__c',
                                                    'Retail_Price__c',
                                                    'Enviro_Fee__c',
                                                    'Enviro_Fee_Code__c',
                                                    'Enviro_Fee_Code__r.Fee_Unique_Name__c',
                                                    'Enviro_Fee_Code__r.Description__c',
                                                    'Auto_reorder_Min__c',
                                                    'Auto_reorder_Max__c',
                                                    'Order_Lots__c',
                                                    'Active__c',
                                                    'Qty_On_Order__c',
                                                    'Qty_Committed__c',
                                                    'AvailableParts__c',
                                                    'Applicable_Tax__c',
                                                    'Applicable_Tax__r.Name__c',
                                                    'Applicable_Tax__r.Rate__c',
													'Is_OrderLot__c',
													'Mfg_Part__c',
													'SKU_Number__c',
													'Non_Inventory_Part__c',
													'Assigned_Tag_1__c',
													'Assigned_Tag_2__c',
													'Assigned_Location_1__c',
                                                    'Assigned_Location_2__c',
                                                    'Vendor__r.Retail_Base_Value__c',
                                                    'Vendor__r.Country__r.Currency_Code__c',
                                                    'Vendor__r.Country__r.Conversion_Rate_With_Markup__c',
                                                    'Vendor__r.Country__r.Backward_Conversion_Rate__c',
                                                    'Vendor__r.Is_Foreign_Vendor__c',
													'Vendor__r.Retail_Rate__c',
													'Vendor__r.Retail_Round_To__c',
													'Vendor__r.Retail_Rounding__c',
													'Vendor__r.Is_Calculate_Part_Retail_Price__c',
                                                    'Part_Type__c',
                                                    'Sale_Price__c',
                                                    'Cassons_ID__c',
                                                    'Publish_in_feeds__c',
                                                    'Shopify_ID__c',
                                                    'Shopify_URL__c',
                                                    'Cassons_SOH__c',
                                                    'Shopify_Product_Id__c', 
                                                    'Calculated_Cost__c',
                                                    'Average_Cost__c',
                                                    'Is_Retail_Locked_In__c',
                                                    'Is_MSRP_Locked_In__c',
                                                    'Is_Description_Locked_In__c',
                                                    'Status__c'
                                                };
        return partFields;
    }
}
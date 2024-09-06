public without sharing class AutomatedPriceFileMappingWrapper {
    public Id Id;
    public Id VendorMasterId;
	public List<CategoryMappingWrapper> CategoryMappingList;
	public String Description;
    public String CostBasedOnValue;
    public Decimal CostMarkupTier1;
    public Decimal CostMarkupTier2;
    public Decimal CostMarkupTier3;
    public Decimal CostMaxMarkupAmountTier1;
    public Decimal CostMaxMarkupAmountTier2;
    public boolean IsPackagedPart;	
    public boolean IsForcedCategory;
    public String MSRPBasedOnValue;
    public Decimal MSRPMarkupTier1;
    public Decimal MSRPMarkupTier2;
    public Decimal MSRPMarkupTier3;
    public Decimal MSRPMaxMarkupAmountTier1;
    public Decimal MSRPMaxMarkupAmountTier2;
    public Boolean IsMSRPRounded;
    public Decimal MSRPRoundToValue;
    public String RetailBasedOnValue;
    public Decimal RetailMarkupTier1;
    public Decimal RetailMarkupTier2;
    public Decimal RetailMarkupTier3;
    public Decimal RetailMaxMarkupAmountTier1;
    public Decimal RetailMaxMarkupAmountTier2;
    public Boolean IsRetailRounded;
    public Decimal RetailRoundToValue;

    public AutomatedPriceFileMappingWrapper(Id vendorMasterId) {  this.vendorMasterId =  vendorMasterId;}

    public AutomatedPriceFileMappingWrapper(Price_File_Mapping__c priceFileMappingRec) {
        this.Id = priceFileMappingRec.Id;
        this.vendorMasterId = priceFileMappingRec.Vendor_Master__c;
        this.CategoryMappingList = String.isBlank(priceFileMappingRec.Category__c) ? new List<CategoryMappingWrapper>() : (List<CategoryMappingWrapper>) System.JSON.deserialize(priceFileMappingRec.Category__c, List<CategoryMappingWrapper>.class);
        this.Description = priceFileMappingRec.Description__c;
        this.CostBasedOnValue = priceFileMappingRec.Cost_Based_On_Value__c;
        this.CostMarkupTier1 = priceFileMappingRec.Cost_Markup_Tier_1__c;
        this.CostMarkupTier2 = priceFileMappingRec.Cost_Markup_Tier_2__c;
        this.CostMarkupTier3 = priceFileMappingRec.Cost_Markup_Tier_3__c;
        this.CostMaxMarkupAmountTier1 = priceFileMappingRec.Cost_Max_Markup_Amount_Tier_1__c;
        this.CostMaxMarkupAmountTier2 = priceFileMappingRec.Cost_Max_Markup_Amount_Tier_2__c;
        this.IsPackagedPart = priceFileMappingRec.Is_Packaged_Part__c;	
        this.IsForcedCategory = priceFileMappingRec.Is_Forced_Category__c;	
        this.MSRPBasedOnValue = priceFileMappingRec.MSRP_Based_On_Value__c;
        this.MSRPMarkupTier1 = priceFileMappingRec.MSRP_Markup_Tier_1__c;
        this.MSRPMarkupTier2 = priceFileMappingRec.MSRP_Markup_Tier_2__c;
        this.MSRPMarkupTier3 = priceFileMappingRec.MSRP_Markup_Tier_3__c;
        this.MSRPMaxMarkupAmountTier1 = priceFileMappingRec.MSRP_Max_Markup_Amount_Tier_1__c;
        this.MSRPMaxMarkupAmountTier2 = priceFileMappingRec.MSRP_Max_Markup_Amount_Tier_2__c;
        this.IsMSRPRounded = priceFileMappingRec.Is_MSRP_Rounded__c;
        this.MSRPRoundToValue = priceFileMappingRec.MSRP_Round_To__c;
        this.RetailBasedOnValue = priceFileMappingRec.Retail_Based_On_Value__c;
        this.RetailMarkupTier1 = priceFileMappingRec.Retail_Markup_Tier_1__c;
        this.RetailMarkupTier2 = priceFileMappingRec.Retail_Markup_Tier_2__c;
        this.RetailMarkupTier3 = priceFileMappingRec.Retail_Markup_Tier_3__c;
        this.RetailMaxMarkupAmountTier1 = priceFileMappingRec.Retail_Max_Markup_Amount_Tier_1__c;
        this.RetailMaxMarkupAmountTier2 = priceFileMappingRec.Retail_Max_Markup_Amount_Tier_2__c;
        this.IsRetailRounded = priceFileMappingRec.Is_Retail_Rounded__c;
        this.RetailRoundToValue = priceFileMappingRec.Retail_Round_To__c;
    }    

    public static List<String> getFieldList() {
		return new List<String> {'Id',
			'Category__c',
			'Cost_Based_On_Value__c',
			'Cost_Markup_Tier_1__c',
			'Cost_Markup_Tier_2__c',
			'Cost_Markup_Tier_3__c',
			'Cost_Max_Markup_Amount_Tier_1__c',
			'Cost_Max_Markup_Amount_Tier_2__c',
			'Description__c',
			'Is_Packaged_Part__c',
            'Is_Forced_Category__c',
			'MSRP_Based_On_Value__c',
			'MSRP_Markup_Tier_1__c',
			'MSRP_Markup_Tier_2__c',
			'MSRP_Markup_Tier_3__c',
            'MSRP_Max_Markup_Amount_Tier_1__c',
            'MSRP_Max_Markup_Amount_Tier_2__c',
            'Is_MSRP_Rounded__c',
            'MSRP_Round_To__c',
			'Retail_Based_On_Value__c',
			'Retail_Markup_Tier_1__c',
			'Retail_Markup_Tier_2__c',
			'Retail_Markup_Tier_3__c',
			'Retail_Max_Markup_Amount_Tier_1__c',
			'Retail_Max_Markup_Amount_Tier_2__c',
			'Is_Retail_Rounded__c',
			'Retail_Round_To__c',
			'Vendor_Master__c'
		};
    }
    
    public class CategoryMappingWrapper {
        public String Key;
        public String Value;
    }
}
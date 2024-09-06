public without sharing class AutomatedPriceFileMappingWrapper {
    public Id Id;
    public Id VendorMasterId;
	public List<CategoryMappingWrapper> CategoryMappingList;
	public String Description;
    public String CostBasedOnValue;
    public Escalator CostEscalator;
    public boolean IsPackagedPart;	
    public boolean IsForcedCategory;
    public String MSRPBasedOnValue;
    public Escalator MSRPEscalator;
    public Boolean IsMSRPRounded;
    public Decimal MSRPRoundToValue;
    public String RetailBasedOnValue;
    public Escalator RetailEscalator;
    public Boolean IsRetailRounded;
    public Decimal RetailRoundToValue;

    public AutomatedPriceFileMappingWrapper(Id vendorMasterId) {  this.vendorMasterId =  vendorMasterId;}

    public AutomatedPriceFileMappingWrapper(Price_File_Mapping__c priceFileMappingRec) {
        this.Id = priceFileMappingRec.Id;
        this.vendorMasterId = priceFileMappingRec.Vendor_Master__c;
        this.CategoryMappingList = String.isBlank(priceFileMappingRec.Category__c) ? new List<CategoryMappingWrapper>() : (List<CategoryMappingWrapper>) System.JSON.deserialize(priceFileMappingRec.Category__c, List<CategoryMappingWrapper>.class);
        this.Description = priceFileMappingRec.Description__c;
        this.CostBasedOnValue = priceFileMappingRec.Cost_Based_On_Value__c;
        this.IsPackagedPart = priceFileMappingRec.Is_Packaged_Part__c;	
        this.IsForcedCategory = priceFileMappingRec.Is_Forced_Category__c;	
        this.MSRPBasedOnValue = priceFileMappingRec.MSRP_Based_On_Value__c;
        this.IsMSRPRounded = priceFileMappingRec.Is_MSRP_Rounded__c;
        this.MSRPRoundToValue = priceFileMappingRec.MSRP_Round_To__c;
        this.RetailBasedOnValue = priceFileMappingRec.Retail_Based_On_Value__c;
        this.IsRetailRounded = priceFileMappingRec.Is_Retail_Rounded__c;
        this.RetailRoundToValue = priceFileMappingRec.Retail_Round_To__c;
        for(Escalator__c escalatorRec: priceFileMappingRec.Escalators__r) {
            if(escalatorRec.Type__c == EscalatorUtil.TYPE_COST) {
                this.CostEscalator = new Escalator(escalatorRec);
            } else if(escalatorRec.Type__c == EscalatorUtil.TYPE_MSRP) {
                this.MSRPEscalator = new Escalator(escalatorRec);
            } else if(escalatorRec.Type__c == EscalatorUtil.TYPE_RETAIL) {
                this.RetailEscalator = new Escalator(escalatorRec);
            }
        }
    }    

    public static List<String> getFieldList() {
		return new List<String> {'Id',
			'Category__c',
			'Cost_Based_On_Value__c',
			'Description__c',
			'Is_Packaged_Part__c',
            'Is_Forced_Category__c',
			'MSRP_Based_On_Value__c',
            'Is_MSRP_Rounded__c',
            'MSRP_Round_To__c',
			'Retail_Based_On_Value__c',
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
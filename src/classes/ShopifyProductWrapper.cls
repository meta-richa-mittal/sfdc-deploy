/** 
* Author: Nidhi Sharma
* Since: Dec 17, 2020
* Name: ShopifyProductWrapper 
* Description: Apex wrapper class which contains Shopify Product fields.
**/
public without sharing class ShopifyProductWrapper {
	
	//product fields
	public String description;
	public String descriptionHtml;
	public Boolean inactive;
	public String productType;
	public String status;
	public String tags;
	public String title;
	public String updateDescription;
    public String vendor;
	public String vendorCode;
    public String shopifyId;
	public List<ShopifyProductVarintatWrapper> variants;
	
	public ShopifyProductWrapper(){}
	
	public ShopifyProductWrapper(Part__c partRec) {
		/*this.shopifyId = partRec.Shopify_Id__c;
		this.vendorCode = partRec.Vendor_Code__c;
		this.productNumber = partRec.Part_Number__c;
		this.vendor = partRec.Vendor__r.Name;
		this.qtyAvailable = partRec.AvailableParts__c != null ? Integer.valueOf(partRec.AvailableParts__c) : 0;
		this.description = partRec.Description__c;
		this.title = partRec.Description__c;
		this.productType = partRec.Part_Type__c;
		this.inactive = !partRec.Publish_In_Feeds__c;
		this.price = (partRec.Retail_Price__c != null) ? partRec.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
		this.sku = partRec.SKU_Number__c;
		if(!partRec.Publish_In_Feeds__c) {
			this.qtyAvailable = 0;
		} else {
			this.qtyAvailable = partRec.AvailableParts__c != null ? Integer.valueOf(partRec.AvailableParts__c) : 0;
		}
		this.salesPrice = (partRec.Sale_Price__c != 0) ? partRec.Sale_Price__c : null;*/
	}
	
	public ShopifyProductWrapper(List<Website_Product__c> variantRecList) {
		if(variantRecList != null && variantRecList.size() > 0) {
			setProductFields(variantRecList[0]);
			setVariantList(variantRecList);
		}
	}
	
	private void setProductFields(Website_Product__c productRec) {
		this.shopifyId = productRec.Product_Id__c;
		if(String.isBlank(productRec.Product_Id__c)) {
			this.vendor = productRec.Part__r.Vendor__r.Name;
		}
        this.vendorCode = productRec.Part__r.Vendor_Code__c;

		if(String.isBlank(productRec.Product_Id__c) || checkForSparseUpdate(productRec, 'Title__c')) {
            this.title = productRec.Title__c;
			if(String.isBlank(productRec.Variant_Options__c) && GeneralConfiguration.getConfigurationByName(GeneralConfiguration.INCLUDE_PARTNUM_IN_WEBSITE_PRODUCT_NAME) == 'true' && productRec.Part__c != null) {
				this.title = this.title + ' (' + productRec.Part__r.Part_Number__c +')';
			}
		}
		if(String.isBlank(productRec.Product_Id__c)) {
		    this.status = productRec.Publish_As_Draft__c != null && productRec.Publish_As_Draft__c ? 'DRAFT' : 'ACTIVE';
		}
		if(String.isBlank(productRec.Product_Id__c) || (productRec.Part__r != null && checkForSparseUpdate(productRec.Part__r, 'Description__c'))) {
            this.description = productRec.Part__r.Description__c;
		}
	}
	
	private void setVariantList(List<Website_Product__c> variantRecList) {
		Set<String> tags = new Set<String>();
		Boolean isWPMTagSyncingEnabled = GeneralConfiguration.isWPMTagSyncingEnabled();
		String skuMappedTo = Shopify_Configuration__c.getOrgDefaults().Product_Sku_Mapping_Field__c;
		
		this.variants = new List<ShopifyProductVarintatWrapper>();
		for(Website_Product__c variantRec : variantRecList) {
			ShopifyProductVarintatWrapper variantObj = new ShopifyProductVarintatWrapper();
			variantObj.shopifyId = variantRec.Variant_Id__c;
			variantObj.optionName1 = variantRec.Option_Label_1__c;
			variantObj.optionName2 = variantRec.Option_Label_2__c;
			variantObj.optionName3 = variantRec.Option_Label_3__c;
			variantObj.optionValue1 = variantRec.Option_Value_1__c;
			variantObj.optionValue2 = variantRec.Option_Value_2__c;
			variantObj.optionValue3 = variantRec.Option_Value_3__c;
			
			if(String.isNotBlank(variantRec.Part__c)) {
				if(String.isBlank(this.vendor)) {
					if(String.isBlank(variantRec.Product_Id__c) && String.isBlank(variantRec.Variant_Id__c)) {
						this.vendor = variantRec.Part__r.Vendor__r.Name;
					}
					this.vendorCode = variantRec.Part__r.Vendor_Code__c;
				}
				variantObj.price = (variantRec.Part__r.Retail_Price__c != null) ? variantRec.Part__r.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
				variantObj.productNumber = variantRec.Part__r.Part_Number__c;
				variantObj.qtyAvailable = variantRec.Part__r.AvailableParts__c != null ? Integer.valueOf(variantRec.Part__r.AvailableParts__c) : 0;
				variantObj.salesPrice = (variantRec.Part__r.Sale_Price__c != null && variantRec.Part__r.Sale_Price__c != 0) ? 
										variantRec.Part__r.Sale_Price__c.setScale(2, RoundingMode.HALF_UP) : null;
				variantObj.unitCost = (variantRec.Part__r.Last_Cost__c != null && variantRec.Part__r.Last_Cost__c != 0) ? 
										variantRec.Part__r.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : null;
				if(String.isNotBlank(skuMappedTo)) {
					if(skuMappedTo.equalsIgnoreCase('SKU_Number__c') && String.isNotBlank(variantRec.Part__r.SKU_Number__c) && (String.isBlank(variantRec.Variant_Id__c) || checkForSparseUpdate(variantRec.Part__r, 'SKU_Number__c'))) {
						variantObj.sku = variantRec.Part__r.SKU_Number__c;
					} else if(skuMappedTo.equalsIgnoreCase('Part_Number__c') && String.isNotBlank(variantRec.Part__r.Part_Number__c) ) {
						variantObj.sku = variantRec.Part__r.Part_Number__c;
					}
				}
			}
			this.variants.add(variantObj);

			if(variantRec.Part__r != null && isWPMTagSyncingEnabled) {
				tags.addAll(new Set<String>(TagUtil.getTagsList(variantRec.Part__r)));
			}
		}
		if(isWPMTagSyncingEnabled) {
			this.tags = String.join(new List<String>(tags), ', ');
		}
	}
	
	private Boolean checkForSparseUpdate(Website_Product__c productRec, String fieldAPINameForSparseUpdate) {
	    return (productRec.Shopify_Sparse_Update_Fields__c != null && productRec.Shopify_Sparse_Update_Fields__c.contains(fieldAPINameForSparseUpdate));
	}
	
	private Boolean checkForSparseUpdate(Part__c partRec, String fieldAPINameForSparseUpdate) {
        return (partRec.Shopify_Sparse_Update_Fields__c != null && partRec.Shopify_Sparse_Update_Fields__c.contains(fieldAPINameForSparseUpdate));
    }
	
	public class ShopifyProductVarintatWrapper {
	    public String optionName1;
	    public String optionName2;
	    public String optionName3;
	    public String optionValue1;
	    public String optionValue2;
	    public String optionValue3;
	    public Decimal price;
		public String sku;
	    public String productNumber;
	    public Integer qtyAvailable;
	    public Decimal salesPrice;
	    public String shopifyId;
	    public Boolean taxable;
	    public Decimal unitCost;
	    public Decimal weight;
	    public String weightUnit;
	    
	}
	
	//Post parts to shopify
	public static List<String> getFieldsToQuery() {
		return new List<String>{'Id', 'Publish_In_Feeds__c', 'Part_Type__c', 'Part_Number__c', 'Vendor_Code__c', 'Vendor__r.Name', 'Shopify_Sparse_Update_Fields__c',
								'AvailableParts__c', 'Shopify_ID__c', 'Description__c', 'Retail_Price__c', 'SKU_Number__c', 'Sale_Price__c', 'Last_Cost__c'};
	}
	
	//Post website products to shopify
	public static List<String> getWebsiteProductFieldList() {
		return new List<String>{'Title__c', 'Product_Id__c', 'Variant_Options__c', 'Variant_Id__c', 'Product_Vendor__c', 'Status__c', 'Option_Label_1__c', 
								'Option_Label_2__c', 'Option_Label_3__c', 'Option_Value_1__c', 'Option_Value_2__c', 'Option_Value_3__c', 'Part__c', 'Publish_As_Draft__c', 
								'Part__r.Assigned_Tag_1__c', 'Part__r.Assigned_Tag_2__c', 'Part__r.Publish_In_Feeds__c', 'Part__r.Part_Type__c', 'Internal_Product_Id__c', 
								'Part__r.Part_Number__c', 'Part__r.Vendor_Code__c', 'Part__r.Vendor__r.Name', 'Part__r.AvailableParts__c', 'Part__r.Last_Cost__c', 
								'Part__r.Shopify_ID__c', 'Part__r.Description__c', 'Part__r.Retail_Price__c','Part__r.SKU_Number__c', 'Part__r.Sale_Price__c',
								'Retry_Attempt_Counter__c', 'Shopify_Sparse_Update_Fields__c', 'Part__r.Shopify_Sparse_Update_Fields__c', 'Group_Id__c', 'Website_API_Response__c'};
	}
}
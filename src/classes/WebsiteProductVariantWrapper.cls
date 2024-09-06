/** 
* Author: Tarun Khandelwal
* Since: June 21, 2021
* Name: WebsiteProductVariantWrapper 
* Description: Wrapper class for Website Product Variants.
**/
public without sharing class WebsiteProductVariantWrapper {
    
    public String Title;
    public String ProductId;
    public Boolean IsPublishAsDraft;
    public List<VariantWrapper> VariantOptionList;
    
    public WebsiteProductVariantWrapper(List<Website_Product__c> productList) {
        if(productList.size() > 0) {
            this.Title = productList[0].Title__c;
            this.ProductId = productList[0].Product_Id__c;
            this.IsPublishAsDraft = productList[0].Publish_as_Draft__c;
        }
        this.VariantOptionList = new List<VariantWrapper>();
        for(Website_Product__c productRec : productList) {
            this.VariantOptionList.add(new VariantWrapper(productRec));
        }
    }
    
    public class VariantWrapper {
        public String VariantId;
        public String Id;
        public String PartId;
        public String PartNumber;
	    public String PartDesc;
	    public String ProductVendor;
	    public Decimal Price;
	    public Decimal Stock;
	    public String Label1;
	    public String Value1;
	    public String Label2;
	    public String Value2;
	    public String Label3;
	    public String Value3;
	    public String VariantOptions;
	    public Integer VariantPosition;
	    
	    public VariantWrapper(Website_Product__c productRec) {
	        this.VariantId = productRec.Variant_Id__c;
	        this.Id = productRec.Id;
	        this.PartId = productRec.Part__c;
	        this.PartNumber = productRec.Part__r.Part_Number__c;
	        this.PartDesc = productRec.Part__r.Description__c;
	        this.ProductVendor = productRec.Product_Vendor__c;
	        this.Price = productRec.Part__r.Retail_Price__c != null ? productRec.Part__r.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
	        this.Stock = productRec.Part__r.Qty_In_Stock__c;
	        this.VariantOptions = productRec.Variant_Options__c;
	        this.Label1 = productRec.Option_Label_1__c;
	        this.Value1 = productRec.Option_Value_1__c;
	        this.Label2 = productRec.Option_Label_2__c;
	        this.Value2 = productRec.Option_Value_2__c;
	        this.Label3 = productRec.Option_Label_3__c;
	        this.Value3 = productRec.Option_Value_3__c;
	    }
    }
    
    public static List<String> fieldList = new List<String>{ 
        'Title__c', 'Option_Label_1__c', 'Option_Value_1__c', 'Option_Label_2__c', 'Option_Value_2__c', 'Option_Label_3__c', 'Option_Value_3__c',
        'Product_Id__c', 'Variant_Id__c', 'Variant_Options__c', 'Publish_as_Draft__c', 'Product_Vendor__c',
        'Part__c', 'Part__r.Part_Number__c', 'Part__r.Description__c', 'Part__r.Retail_Price__c', 'Part__r.Qty_In_Stock__c'
    };
}
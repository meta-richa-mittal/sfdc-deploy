/** 
* Author: Richa Mittal
* Since: June 3, 2021 
* Name: WebsiteProductWrapper 
* Description: Wrapper class for Website Product Management.
**/
public without sharing class WebsiteProductWrapper {
	
	public String Id;
	public String ProductId;
	public String ProductURL;
	public String Status;
	public String Title;
	public String VariantOptions;
	public String ProductVendor;
	public String PartId;
	public String PartCodeDesc;
	public Boolean IsIgnored;
	public Boolean IsPublishAsDraft;
	
	public WebsiteProductWrapper(Website_Product__c productRec) {
		this.Id = productRec.Id;
		this.ProductId = productRec.Product_Id__c;
		this.ProductURL = productRec.Product_URL__c;
		this.Status = (String.isNotBlank(productRec.Status__c) ? productRec.Status__c.toLowerCase() : '');	//Added lower case as requested by Dinesh for css handling
		this.IsIgnored = (String.isNotBlank(productRec.Status__c) && productRec.Status__c.equalsIgnoreCase(WebsiteProductManagementUtil.STATUS_IGNORED));
		this.Title = productRec.Title__c;
		this.VariantOptions = productRec.Variant_Options__c;
		this.ProductVendor = productRec.Product_Vendor__c;
		this.PartId = productRec.Part__c;
		this.PartCodeDesc = productRec.Part__c != null ? (productRec.Part__r.Part_Number__c + ' - ' + productRec.Part__r.Description__c) : '';
		this.IsPublishAsDraft = productRec.Publish_as_Draft__c;
	}
	
    public static List<String> fieldsList = new List<String>{'Title__c', 'Product_Id__c', 'Variant_Options__c', 'Product_Vendor__c', 'Status__c', 'Part__c', 
												'Part__r.Part_Number__c', 'Part__r.Description__c', 'Option_Label_1__c', 'Option_Label_2__c', 'Publish_as_Draft__c', 
												'Option_Label_3__c', 'Option_Value_1__c', 'Option_Value_2__c', 'Option_Value_3__c', 'Product_URL__c'
												};
}
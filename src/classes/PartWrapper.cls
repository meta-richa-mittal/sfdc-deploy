/** 
* Author: Nidhi Sharma
* Since: June 14, 2021 
* Name: PartWrapper 
* Description: Part Wrapper class
**/
public without sharing class PartWrapper {
	
	public String Id;
	public String PartNumber;
	public String PartDesc;
	public String VendorName;
	public Decimal AvailableQty;
	public Decimal Price;
	public Boolean IsAlreadyLinkedPart;
	
	public PartWrapper(Part__c partRec) {
		this.Id = partRec.Id;
		this.PartNumber = partRec.Part_Number__c;
		this.PartDesc = partRec.Description__c;
		this.VendorName = partRec.Vendor__r.Name;
		this.AvailableQty = partRec.AvailableParts__c;
		this.Price = partRec.Retail_Price__c;
		this.IsAlreadyLinkedPart = String.isNotBlank(partRec.Shopify_Product__c);
	}
	
	public static List<String> fieldsList(){
		return new List<String>{'Part_Number__c', 'Description__c', 'Vendor__r.Name', 'AvailableParts__c', 'Retail_Price__c', 'Shopify_Product__c'};
	}
}
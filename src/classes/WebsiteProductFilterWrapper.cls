/** 
* Author: Nidhi Sharma
* Since: June 11, 2021 
* Name: FilterJSON 
* Description: Apex class which contains fields to filtr website product.
**/
public without sharing class WebsiteProductFilterWrapper {
	public Integer StartIndex;
	public Integer RecordCount;
	public String SearchKeyword;	//Searching in product title and option
	public List<String> ProductVendorList;
	public List<String> StatusList;
	public String ShopifyProductId;
	public String DateTimeWhenSearchExecuted;
}
/** 
* Author: Nidhi Sharma
* Since: June 3, 2021 
* Name: WebsiteInfoWrapper 
* Description: Wrapper class for Website Info.
**/
public without sharing class WebsiteInfoWrapper {
    public String Title;
	public String URL;
	
	public WebsiteInfoWrapper() {
		if(ShopifyUtil.isIntegrationActive) {
			this.Title = Shopify_Configuration__c.getOrgDefaults().Website_Title__c;
			this.URL = Shopify_Configuration__c.getOrgDefaults().Website_URL__c;
		}
	}
}
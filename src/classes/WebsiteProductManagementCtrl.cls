/** 
* Author: Richa Mittal
* Since: June 2, 2021 
* Name: WebsiteProductManagementCtrl 
* Description: Apex class which contains all remote actions related to Website Product Management Page.
**/
global without sharing class WebsiteProductManagementCtrl {
    
    global WebsiteProductManagementCtrl (NewHomePageCtrl controller){}
	public WebsiteProductManagementCtrl() {}
	
	/**SHOP-VAR-001 Starts Here**/
	// To return Json of shopify products based on filter conditions excluding delete pending products
	@RemoteAction
    global static String getAllProducts(String filterString) {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.getAllProducts(BPUtility.getDecodedString(filterString)), true));
    }
    
    //To return website product count based on filter conditions excluding delete pending products
    @RemoteAction
    global static String getProductStatics(String filterString) {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.getProductStatics(BPUtility.getDecodedString(filterString))));
    }
    
    //To return website info if shopify integration is enabled
    @RemoteAction
    global static String getWebsiteInfo() {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.getWebsiteInfo()));
    }
    
    //Save products with Variants.
    @RemoteAction
    global static String saveProductAndVariants(String productVariantJSON) {
    	WebsiteProductManagementService.saveProductAndVariants(BPUtility.getDecodedString(productVariantJSON));
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(200, 'Success')));
    }
    
    //To delete product variant from website and BP, if failed to delete in BP turn on delete pending flag on product
    @RemoteAction
    global static String deleteProductVariant(String productId) {
        WebsiteProductManagementService.deleteProductVariant(BPUtility.getDecodedString(productId));
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(200, 'Success')));
    }
    
    //To search Parts various filters
    @RemoteAction
    global static String getProductVendor(String searchKeyword) {
    	return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.getProductVendor(BPUtility.getDecodedString(searchKeyword))));
    }
    
    //Polling action - Fetch products from shopify
    @RemoteAction
    global static String pollProductsFromWebsite() {
    	WebsiteProductManagementService.pollProductsFromWebsite();
    	return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(200, 'Success')));
    }
    
    //Return true/false if polling in progress
    @RemoteAction
    global static Boolean isPollingInProgress() {
    	return WebsiteProductManagementService.isPollingInProgress();
    }
    
    /**SHOP-VAR-002 Starts Here**/
    //To search Parts with various filters
    @RemoteAction
    global static String searchPartWithFilters(String searchQueryJsonStr) {
    	return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.searchPartWithFilters(BPUtility.getDecodedString(searchQueryJsonStr))));
    }
    
    //To search Parts counter with various filters
    @RemoteAction
    global static String getTotalParts(String searchQueryJsonStr) {
        return BPUtility.getEncodedString(WebsiteProductManagementService.getTotalParts(BPUtility.getDecodedString(searchQueryJsonStr)));
    }
    
    //To search active vendor by startwith name 
    @RemoteAction
    global static String searchBPVendors(String searchKeyword) {
    	return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.searchBPVendors(BPUtility.getDecodedString(searchKeyword))));
    }
    
    //To search tags by name and fetch matching active tages
    @RemoteAction
    global static String searchTags(String searchKeyword) {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.searchTags(BPUtility.getDecodedString(searchKeyword))));
    }
    
    //To search categories by name and fetch matching active categories
    @RemoteAction
    global static String searchCategories(String searchKeyword) {
    	return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.searchCategories(BPUtility.getDecodedString(searchKeyword))));
    }
    
    //Save products
    @RemoteAction
    global static String saveProducts(String productsJson) {
    	WebsiteProductManagementService.saveProducts(BPUtility.getDecodedString(productsJson));
    	return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(200, 'Success')));
    }
    
    /**SHOP-VAR-003 Starts Here**/
    //Get product variants related to the given website product Id
    @RemoteAction
    global static String getProductVariantsByProductId(String websiteProductId) {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.getProductVariantList(BPUtility.getDecodedString(websiteProductId)), true));
    }
    /**SHOP-VAR-003 Ends Here**/
    
    //GET product variants API call by product id
    @RemoteAction
    global static String syncBPProductWithStoreProductByProductId(String websiteProductId) {
        return BPUtility.getEncodedString(System.JSON.serialize(WebsiteProductManagementService.syncBPProductWithStoreProductByProductId(BPUtility.getDecodedString(websiteProductId)), true));
    }
}
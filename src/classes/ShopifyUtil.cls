/** 
* Author: Nidhi Sharma
* Since: June 15, 2021
* Name: ShopifyUtil 
* Description: Util class which contains Shopify utility variables and methods.
**/
public without sharing class ShopifyUtil {
    
    public static Boolean isIntegrationActive = GeneralConfiguration.isShopifyIntegrationActive();
    public static String integrationName = 'Shopify';
	public static String productAndVendorCodeConnectorKey = '^&&^';
	
	public static final String PRODUCT = 'Product';
    public static final String PRODUCT_VARIANT = 'Product Variant';
    public static final String SHOPIFY_PRODUCT_BY_ID = 'Product By Id';
	public static final String SHOPIFY_PRODUCT_BY_DETAILS = 'Product By Details';
	
	public static final String SHOPIFY_ORDER = 'Shopify Order';
	public static final Integer MAX_RETRY = 3;
	
	public static final String RETRY_BYPASSED_ERROR_MSG_1 = 'Product variant does not exist';
	public static final String RETRY_BYPASSED_ERROR_MSG_2 = 'Product does not exist';

	public static final Integer BulkProcessBatchSize = 50;
}
/** 
* Author: Tarun Khandelwal
* Since: July 22, 2021
* Name: ShopifyProductWrapper 
* Description: Apex wrapper class which contains Shopify Product fields.
**/
public with sharing class ShopifyProductResponseWrapper {
    
    public String shopifyId;
    public String productNumber;
    public String vendorCode;
    public List<ErrorMessageWrapper> userErrors;
    
    public class ErrorMessageWrapper {
        public List<String> field;
        public String message;
    }
}
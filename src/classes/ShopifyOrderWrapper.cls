/** 
* Author: Tarun Khandelwal
* Since: Feb 02, 2020
* Name: ShopifyOrderWrapper 
* Description: Apex wrapper class which contains Shopify Order fields.
**/
public without sharing class ShopifyOrderWrapper {
    
    public String shopifyId;
    public String orderNumber;
    public ShopifyCustomer customer;
    public Decimal discount;
    public Decimal shippingCharge;
    public Decimal totalTax;
    public Decimal total;
    public String createdAt;
    public String updatedAt;
    
    public List<ShopifyOrderLineItem> lineItems;
    public List<ShopifyOrderTaxLine> taxLines;
    
    public class ShopifyCustomer {
        public String shopifyId;
        public String firstName;
        public String lastName;
        public String company;
        public String address1;
        public String address2;
        public String city;
        public String province;
        public String provinceCode;
        public String country;
        
        public String countryCode;
        public String postalZIP;
        public String phone;
        public String email;
        public String locale;
        public String note;
        public Boolean acceptsMarketing;
        public String tags;
    }
    
    public class ShopifyOrderLineItem {
        public String shopifyId;
        public String productShopifyId;
        public String productNumber;
        public String vendorCode;
        public Integer quantity;
        public Decimal price;
        public Decimal discount;
        public Decimal total;
        public Boolean taxable;
        public List<ShopifyOrderTaxLine> taxLines;
    }
    
    public class ShopifyOrderTaxLine {
        public String title;
        public Decimal rate;
        public Decimal tax;
    }
}
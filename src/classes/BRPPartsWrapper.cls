/** 
* Author: Richa Mittal
* Since: June 03, 2024 
* Name: BRPPartsWrapper 
* Description: wrapper class to for Parts Master JSON response (response body)
**/
public without sharing class BRPPartsWrapper {

    public List<ItemWrapper> items;
    public LinksWrapper links;
    
    public class ItemWrapper {
        public String product_code;
        public String product_descr;
        public String product_type;
        public Decimal gross_weight;
        public String gross_weight_uom;
        public Integer first_year_utilization;
        public Integer last_year_utilization;
        public List<String> product_lines;
        public String sales_status_code;
        public Decimal minimum_order_quantity;
        public String sales_uom;
        public String market_classification;
        public List<PricingWrapper> pricings;
        public List<SupersessionWrapper> supersessions;
    }

    public class PricingWrapper {
        public String price_type;
        public Date valid_from;
        public Decimal price_price_uom;
        public Decimal price_sales_uom;
        public String currencyType;
        public PackageWrapper in_package;

    }

    public class PackageWrapper {
        public Decimal quantity;
        public String uom;
    }

    public class SupersessionWrapper {
        public String superseded_product;
        public String superseding_product;
        public String direction;
    }

    public class LinksWrapper {
        public String previous;
        public String next;
    }
}
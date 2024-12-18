/**
 * Author: Tarun Khandelwal
 * Since: June 27, 2016
 * Name: TaxUtility
 * Description: Controller Class related to Tax 
**/
public without sharing class TaxUtility {

    public static String TAX_NAME_SEPERATOR = '^&&^';
    public final static String EXEMPTION = 'Exemption';
    public final static String AUTOMATED_CUSTOMER = 'Automated - Customer';
    public final static String AUTOMATED_STORE = 'Automated - Store';
    
    public static String getApplicableList() {
        return getApplicableList(null); 
    }
    
    public static String getApplicableList(String defaultSalesTaxId) {
        List<Sales_Tax__c> salesTaxList = SOQLUtil.getSalesTax(new List<Id>());
        Boolean isActiveSalesTax = false;
        for(Sales_Tax__c salesTaxRec : salesTaxList) {
        	if(salesTaxRec.Active__c && String.isNotBlank(defaultSalesTaxId) && String.valueOf(salesTaxRec.Id).contains(defaultSalesTaxId)) {
        		isActiveSalesTax = true;
        		break;
        	}
        }
        if(!isActiveSalesTax) {
    		defaultSalesTaxId = getDefaultSalesTaxId();
        }
        Boolean isTaxIncludingPricing = checkForTaxIncludingPricing();
        return system.JSON.serialize(new Tax(isTaxIncludingPricing, salesTaxList, defaultSalesTaxId));
    }

    public static String getDefaultPurchaseTaxId() {
        for(Sales_Tax__c defaultPurchaseTax : ((List<Sales_Tax__c>) SOQLUtility.getQueryResults('Sales_Tax__c', 'Select Id From Sales_Tax__c Where Tax_Type__c = \'Purchase\' AND Active__c = true AND Default__c = true Limit 1'))) {
            return defaultPurchaseTax.Id;
        }
        return null;
    }
    
    private static String getDefaultSalesTaxId() {
    	String defaultSalesTaxId;
    	if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Sales_Tax__c> defaultSalesTaxList = [select Id from Sales_Tax__c where Default__c = true];
    	if(defaultSalesTaxList.size() > 0) {
    		defaultSalesTaxId = defaultSalesTaxList[0].Id;
    	}
    	return defaultSalesTaxId;
    }
    
    private static Boolean checkForTaxIncludingPricing() {
        return Configurations__c.getOrgDefaults().Tax_Included_Pricing__c;
    }

    public static String getFormattedSalesTaxItemName(String salesTaxItemName, Decimal rate) {
        return (salesTaxItemName + TAX_NAME_SEPERATOR + rate);
    }

    public static String getExtractedSTINameFromFormattedName(String formattedSalesTaxItemName) {
        return string.isNotBlank(formattedSalesTaxItemName) ? formattedSalesTaxItemName.substringBefore(TAX_NAME_SEPERATOR): '';
    }

    public static Decimal getExtractedTaxRateFromFormattedName(String formattedSalesTaxItemName) {
        if(String.isNotBlank(formattedSalesTaxItemName)) {
            formattedSalesTaxItemName = formattedSalesTaxItemName.substringAfter(TAX_NAME_SEPERATOR);
            if(String.isNotBlank(formattedSalesTaxItemName)) {
                try {
                    return Decimal.valueOf(formattedSalesTaxItemName.trim());
                } catch(Exception e){}
            }
        }
        return null;
    }

    public class Tax {
        public Boolean IsTaxIncludingPricing;
        public List<SalesTax> SalesTaxList;
        
        public Tax(Boolean isTaxIncludingPricing, List<Sales_Tax__c> salesTaxList, String defaultSalesTaxId) {
            this.IsTaxIncludingPricing = isTaxIncludingPricing;
            this.SalesTaxList = new List<SalesTax>();
            
            for(Sales_Tax__c salesTaxRec : salesTaxList) {
                String salesTaxId = salesTaxRec.Id;
                if(defaultSalesTaxId != null && salesTaxId.contains(defaultSalesTaxId)) {
                    this.SalesTaxList.add(new SalesTax(salesTaxRec, true));
                } else {
                    this.SalesTaxList.add(new SalesTax(salesTaxRec, false));
                }
            }
        }
    }
    
    
    public class SalesTax {
        
        public String Name;
        public String Id;
        public Decimal TaxRate;
        public Boolean IsDefault;
        public String Type;
        
        public SalesTax(Sales_Tax__c salesTaxRec, Boolean isDefault) {
            this.Name = salesTaxRec.Name__c;
            this.Id = salesTaxRec.Id;
            this.IsDefault = isDefault;
            this.Type = salesTaxRec.Tax_Type__c;
            this.TaxRate = (salesTaxRec.Rate__c != null) ? salesTaxRec.Rate__c : 0;
        }
    }
    
}
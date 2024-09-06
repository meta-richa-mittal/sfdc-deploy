/**
 * Author: Tarun Khandelwal
 * Since: July 01, 2016
 * Name: TaxExemptions
 * Description: Apex class to handle JSON related oprations of Tax Exemptions object.
**/
public without sharing class TaxExemptions {
    
    public String TaxExemptionId;
	public String CustomerId;
	public String CustomerName;
	public String SalesTaxItemId;
	public String SalesTaxName;
	public String Description;
	public Decimal Rate;
	public String RateStr;
	public Boolean IsSelected;
	public String TaxType;
	
	public TaxExemptions(Tax_Exemption__c taxExemptionRec, List<String> appliesToList) {
		this.TaxExemptionId = taxExemptionRec.Id;
		this.CustomerName = taxExemptionRec.Customer__r.Name;
		this.CustomerId = taxExemptionRec.Customer__c;
		this.SalesTaxItemId = taxExemptionRec.Sales_Tax_Item__c;
		this.SalesTaxName = taxExemptionRec.Sales_Tax_Item__r.Name__c;
		this.Rate = taxExemptionRec.Sales_Tax_Item__r.Rate__c;
		this.RateStr = '';
		if(taxExemptionRec.Sales_Tax_Item__r != null) {
			this.RateStr = getFormattedTaxRateString(taxExemptionRec.Sales_Tax_Item__r);
		}
		
		this.Description = '';
		if(appliesToList != null) {
			for(String appliesTo : appliesToList) {
				this.Description += appliesTo + ', ';
			}
		}
		if(this.Description.length() > 0) {
			this.Description = this.Description.subString(0, this.Description.length() - 2);
		}
	}
	
	public TaxExemptions(Sales_Tax_Item__c salesTaxItemRec, List<String> appliesToList) {  
		this.SalesTaxItemId = salesTaxItemRec.Id;
		this.SalesTaxName = salesTaxItemRec.Name__c;
		this.TaxType = salesTaxItemRec.Tax_Type__c;
		
		this.Rate = salesTaxItemRec.Rate__c = (salesTaxItemRec.Rate__c != null) ? salesTaxItemRec.Rate__c.setScale(4, RoundingMode.HALF_UP) : 0;
        this.RateStr = getFormattedTaxRateString(salesTaxItemRec);
        
		if(salesTaxItemRec.Tax_Exemptions__r.size() > 0) {
			this.IsSelected = true;
			this.TaxExemptionId = salesTaxItemRec.Tax_Exemptions__r[0].Id;
		} else {
			this.IsSelected = false;
		}
		this.Description = '';
		if(appliesToList != null) {
			for(String appliesTo : appliesToList) {
				this.Description += appliesTo + ', ';
			}
		}
		if(this.Description.length() > 0) {
			this.Description = this.Description.subString(0, this.Description.length() - 2);
		}
	}
	
	public TaxExemptions(Sales_Tax_Item__c salesTaxItemRec, List<String> appliesToList,String typeOf) {  
		this.SalesTaxItemId = salesTaxItemRec.Id;
		this.SalesTaxName = salesTaxItemRec.Name__c;
		this.TaxType = salesTaxItemRec.Tax_Type__c;
		
		this.Rate = salesTaxItemRec.Rate__c = (salesTaxItemRec.Rate__c != null) ? salesTaxItemRec.Rate__c.setScale(4, RoundingMode.HALF_UP) : 0;
        this.RateStr = getFormattedTaxRateString(salesTaxItemRec);
        
		this.IsSelected = false;
		this.Description = '';
		if(appliesToList != null) {
			for(String appliesTo : appliesToList) {
				this.Description += appliesTo + ', ';
			}
		}
		if(this.Description.length() > 0) {
			this.Description = this.Description.subString(0, this.Description.length() - 2);
		}
	}
	public TaxExemptions(Tax_Exemption__c taxExemptionRec, List<String> appliesToList,String typeOf) {
		this.TaxExemptionId = taxExemptionRec.Id;
		this.SalesTaxItemId = taxExemptionRec.Sales_Tax_Item__c;
		this.SalesTaxName = taxExemptionRec.Sales_Tax_Item__r.Name__c;
		this.Rate = taxExemptionRec.Sales_Tax_Item__r.Rate__c;
		this.RateStr = '';
		if(taxExemptionRec.Sales_Tax_Item__r != null) {
			this.RateStr = getFormattedTaxRateString(taxExemptionRec.Sales_Tax_Item__r);
		}
		
		this.Description = '';
		if(appliesToList != null) {
			for(String appliesTo : appliesToList) {
				this.Description += appliesTo + ', ';
			}
		}
		if(this.Description.length() > 0) {
			this.Description = this.Description.subString(0, this.Description.length() - 2);
		}
		
		this.IsSelected = true; 
	}
	
	private static String getFormattedTaxRateString(Sales_Tax_Item__c salesTaxItemRec) {
		
		String rateStr = '';
		if(salesTaxItemRec.Rate_Type__c != null && (salesTaxItemRec.Rate_Type__c.equalsIgnoreCase(TaxManagementService.ESCALATING_RATE) || 
        				salesTaxItemRec.Rate_Type__c.equalsIgnoreCase(TaxManagementService.TIERED_RATE))) {
        	//system.assert(false, salesTaxItemRec.Rate_Type__c)	;
    		salesTaxItemRec.Tax_Rate_Tier_1__c = salesTaxItemRec.Tax_Rate_Tier_1__c != null ? salesTaxItemRec.Tax_Rate_Tier_1__c.setScale(4, RoundingMode.HALF_UP) : 0;
    		salesTaxItemRec.Tax_Rate_Tier_2__c = salesTaxItemRec.Tax_Rate_Tier_2__c != null ? salesTaxItemRec.Tax_Rate_Tier_2__c.setScale(4, RoundingMode.HALF_UP) : 0;
    		salesTaxItemRec.Tax_Rate_Tier_3__c = salesTaxItemRec.Tax_Rate_Tier_3__c != null ? salesTaxItemRec.Tax_Rate_Tier_3__c.setScale(4, RoundingMode.HALF_UP) : 0;
    		
    		salesTaxItemRec.Max_Taxable_Amount_Tier_1__c = salesTaxItemRec.Max_Taxable_Amount_Tier_1__c != null ? 
									salesTaxItemRec.Max_Taxable_Amount_Tier_1__c.setScale(2, RoundingMode.HALF_UP) : salesTaxItemRec.Max_Taxable_Amount_Tier_1__c;
    		salesTaxItemRec.Max_Taxable_Amount_Tier_2__c = salesTaxItemRec.Max_Taxable_Amount_Tier_2__c != null ? 
									salesTaxItemRec.Max_Taxable_Amount_Tier_2__c.setScale(2, RoundingMode.HALF_UP) : salesTaxItemRec.Max_Taxable_Amount_Tier_2__c;
    		
    		List<TaxRateWrapper.RateTableWrapper> rateTable = new List<TaxRateWrapper.RateTableWrapper>();
    		
    		
    		Integer numberOfRowsInRateTable = 1;
    		for(Integer i = TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.size(); i > 0; i--) {
    			if(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i)) != null) {
    				numberOfRowsInRateTable = (i + 1);
    				break;
    			}
    		}
    		
    		Decimal minRate, maxRate;
    		minRate = Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierTaxRateFieldAPINameMap.get(1))));
    		maxRate = Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierTaxRateFieldAPINameMap.get(numberOfRowsInRateTable))));
    		if(minRate != maxRate) {
    			rateStr = minRate + '% to ' + maxRate + '%';
    		} else {
    			rateStr = minRate + '%';
    		}
    	} else {
    		rateStr = String.valueOf(salesTaxItemRec.Rate__c) + '%';
    	}
    	
    	return rateStr;
	}
	/**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/ 
    public static List<String> fieldsList(){
        List<String> taxExemptionFields = new List<String>{	'Id',
	        												'Customer__c',
	        												'Customer__r.Name',
		                                                   	'Description__c',
		                                                   	'Sales_Tax_Item__c',
		                                                   	'Sales_Tax_Item__r.Name__c',
		                                                   	'Sales_Tax_Item__r.Forms_Label__c',
		                                                   	'Sales_Tax_Item__r.Rate__c',
		                                                   	
		                                                   	'Sales_Tax_Item__r.Tax_Type__c',
		                                                   	'Sales_Tax_Item__r.Rate_Type__c',
		                                                   	'Sales_Tax_Item__r.Tax_Rate_Tier_1__c',
		                                                   	'Sales_Tax_Item__r.Tax_Rate_Tier_2__c',
		                                                   	'Sales_Tax_Item__r.Tax_Rate_Tier_3__c',
		                                                   	'Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c',
		                                                   	'Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c'
		                                               	};
        return taxExemptionFields;
    }
}
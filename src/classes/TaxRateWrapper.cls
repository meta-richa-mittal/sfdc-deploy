/**
 * Author: Nidhi Sharma
 * Since: 13 Nov, 2019
 * Name: TaxRateWrapper
 * Description: 
**/
public without sharing class TaxRateWrapper {
    
    public List<TaxRate> SalesTaxRates;
    public List<TaxRate> PurchaseTaxRates;
    
    public TaxRateWrapper(List<Sales_Tax_Item__c> salesTaxRecList) {
    	this.SalesTaxRates = new List<TaxRate>();
    	this.PurchaseTaxRates = new List<TaxRate>();

    	for(Sales_Tax_Item__c stiRec : salesTaxRecList) {
    		if(String.isNotBlank(stiRec.Tax_Type__c)) {
	    		if(stiRec.Tax_Type__c.equalsIgnoreCase('Sell')) {
	    			SalesTaxRates.add(new TaxRate(stiRec));
	    		} else if(stiRec.Tax_Type__c.equalsIgnoreCase('Purchase')) {
	    			PurchaseTaxRates.add(new TaxRate(stiRec));
	    		}
    		}
    	}
    }
    
	public class TaxRate {
		public String Id;
		public String TaxName;
		public Boolean IsActive;
		public String RateType;
		public Decimal TaxRate;
		public String TaxRateStr;
		public String CategoryId;
		public String CategoryName;
		public String TaxCodeUsage;
		public Decimal MinimumTaxAmount;
		public Decimal MaximumTaxAmount;
		public String FormsLabel;
		public List<RateTableWrapper> RateTable;
		public String TaxType;
		
		public TaxRate(){}
		public TaxRate(Sales_Tax_Item__c salesTaxItemRec) {
			this.Id = salesTaxItemRec.Id;
	    	this.TaxName = (salesTaxItemRec.Name__c != null) ? salesTaxItemRec.Name__c : '';
	    	this.IsActive = salesTaxItemRec.Active__c;
	    	this.RateType = salesTaxItemRec.Rate_Type__c;
	        this.TaxRate = (salesTaxItemRec.Rate__c != null) ? salesTaxItemRec.Rate__c.setScale(4, RoundingMode.HALF_UP) : 0;
	        this.TaxRateStr = String.valueOf(this.TaxRate) + '%';
	        this.CategoryId = salesTaxItemRec.Category__c;
	        this.CategoryName = (salesTaxItemRec.Category__c != null) ? salesTaxItemRec.Category__r.Name : '';
	        this.TaxType = salesTaxItemRec.Tax_Type__c;
	        this.TaxCodeUsage = '';
	        
        	for(Applicable_Taxes__c appTaxRec : salesTaxItemRec.Applicable_Taxes__r) {
        		if(String.isNotBlank(appTaxRec.Sales_Tax__r.Name__c)) {
        			this.TaxCodeUsage += appTaxRec.Sales_Tax__r.Name__c + ', ';
        		}
        	}
        	if(this.TaxCodeUsage.length() > 2) {
        		this.TaxCodeUsage = this.TaxCodeUsage.subString(0, this.TaxCodeUsage.length() - 2);
        	}
        	
        	this.MinimumTaxAmount = (salesTaxItemRec.Minimum_Tax_Amount__c != null) ? salesTaxItemRec.Minimum_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	this.MaximumTaxAmount = (salesTaxItemRec.Maximum_Tax_Amount__c != null) ? salesTaxItemRec.Maximum_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	this.FormsLabel = (salesTaxItemRec.Forms_Label__c != null) ? salesTaxItemRec.Forms_Label__c : '';
        	
        	if(salesTaxItemRec.Rate_Type__c != null && (salesTaxItemRec.Rate_Type__c.equalsIgnoreCase(TaxManagementService.ESCALATING_RATE) || 
        				salesTaxItemRec.Rate_Type__c.equalsIgnoreCase(TaxManagementService.TIERED_RATE))) {
        				
        		salesTaxItemRec.Tax_Rate_Tier_1__c = salesTaxItemRec.Tax_Rate_Tier_1__c != null ? salesTaxItemRec.Tax_Rate_Tier_1__c.setScale(4, RoundingMode.HALF_UP) : 0;
        		salesTaxItemRec.Tax_Rate_Tier_2__c = salesTaxItemRec.Tax_Rate_Tier_2__c != null ? salesTaxItemRec.Tax_Rate_Tier_2__c.setScale(4, RoundingMode.HALF_UP) : 0;
        		salesTaxItemRec.Tax_Rate_Tier_3__c = salesTaxItemRec.Tax_Rate_Tier_3__c != null ? salesTaxItemRec.Tax_Rate_Tier_3__c.setScale(4, RoundingMode.HALF_UP) : 0;
        		
        		salesTaxItemRec.Max_Taxable_Amount_Tier_1__c = salesTaxItemRec.Max_Taxable_Amount_Tier_1__c != null ? 
										salesTaxItemRec.Max_Taxable_Amount_Tier_1__c.setScale(2, RoundingMode.HALF_UP) : salesTaxItemRec.Max_Taxable_Amount_Tier_1__c;
        		salesTaxItemRec.Max_Taxable_Amount_Tier_2__c = salesTaxItemRec.Max_Taxable_Amount_Tier_2__c != null ? 
										salesTaxItemRec.Max_Taxable_Amount_Tier_2__c.setScale(2, RoundingMode.HALF_UP) : salesTaxItemRec.Max_Taxable_Amount_Tier_2__c;
        		
        		this.RateTable = new List<RateTableWrapper>();
        		
        		
        		Integer numberOfRowsInRateTable = 1;
        		for(Integer i = TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.size(); i > 0; i--) {
        			if(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i)) != null) {
        				numberOfRowsInRateTable = (i + 1);
        				break;
        			}
        		}
        		
        		for(Integer i = 1; i <= numberOfRowsInRateTable; i++) {
        			Decimal minAmount = 0;
    				Decimal maxAmount = null;
    				Decimal rate = Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierTaxRateFieldAPINameMap.get(i))));
    				
    				if(i > 1 && Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i - 1)))) != null) {
    					minAmount = Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i - 1)))) + 0.01;
    				}
    				if(i < numberOfRowsInRateTable && 
    							Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i)))) != null) {
    					maxAmount = Decimal.valueOf(String.valueOf(salesTaxItemRec.get(TaxManagementService.counterToTierMaxTaxableAmountFieldAPINameMap.get(i))));
    				}
    				
        			this.RateTable.add(new RateTableWrapper(minAmount, maxAmount, rate));
        		}
        		if(this.RateTable.size() > 1) {
        			this.TaxRateStr = this.RateTable[0].TaxRate + '% to ' + this.RateTable[this.RateTable.size() - 1].TaxRate + '%';
        		} else {
        			this.TaxRateStr = this.RateTable[0].TaxRate + '%';
        		}
        	}
	    }
	}
	
	public class RateTableWrapper {
		public Decimal MinimumTaxableAmount;
		public Decimal MaximumTaxableAmount;
		public Decimal TaxRate;
		
		public RateTableWrapper(Decimal minimumTaxableAmount, Decimal maximumTaxableAmount, Decimal taxRate) {
			this.MinimumTaxableAmount = minimumTaxableAmount;
	    	this.MaximumTaxableAmount = maximumTaxableAmount;
	    	this.TaxRate = taxRate;
	    }
	}
	
	public static List<String> fieldsList() {
		return new List<String> {'Id', 
								'Name__c',
								'Active__c',
								'Tax_Type__c',
								'Rate_Type__c',
								'Rate__c',
								'Category__r.Name',
								'(Select Id, Sales_Tax__r.Name__c from Applicable_Taxes__r)',
								'Minimum_Tax_Amount__c',
								'Maximum_Tax_Amount__c',
								'Forms_Label__c',
								'Max_Taxable_Amount_Tier_1__c',
								'Max_Taxable_Amount_Tier_2__c',
								'Tax_Rate_Tier_1__c',
								'Tax_Rate_Tier_2__c',
								'Tax_Rate_Tier_3__c'
								};
	}
}
/**
 * Author: Richa Mittal
 * Since: 27 Nov, 2019
 * Name: TaxCodeWrapper
 * Description: 
**/
public without sharing class TaxCodeWrapper {
    public List<TaxCode> SalesTaxCodes;
    public List<TaxCode> PurchaseTaxCodes;
    
    public TaxCodeWrapper(List<Sales_Tax__c> salesTaxRecList, Map<Id, List<Applicable_Taxes__c>> salesTaxToAppTaxesListMap) {
    	this.SalesTaxCodes = new List<TaxCode>();
    	this.PurchaseTaxCodes = new List<TaxCode>();

    	for(Sales_Tax__c salesTaxRec : salesTaxRecList) {
    		if(String.isNotBlank(salesTaxRec.Tax_Type__c)) {
    			List<Applicable_Taxes__c> appTaxesList = salesTaxToAppTaxesListMap.containsKey(salesTaxRec.Id) ? salesTaxToAppTaxesListMap.get(salesTaxRec.Id) : null;
	    		if(salesTaxRec.Tax_Type__c.equalsIgnoreCase('Sell')) {
	    			SalesTaxCodes.add(new TaxCode(salesTaxRec, appTaxesList));
	    		} else if(salesTaxRec.Tax_Type__c.equalsIgnoreCase('Purchase')) {
	    			PurchaseTaxCodes.add(new TaxCode(salesTaxRec, appTaxesList));
	    		}
    		}
    	}
    }
    
    public class TaxCode {
    	public String Id;
    	public String Name;
    	public String RatesIncluded;
    	public String TotalRateStr;
    	public Boolean IsDefault;
    	public Boolean IsActive;
    	public String FormsLabel;
    	public Boolean IsListRatesOnForms;
    	public String TaxType;
    	public List<TaxRateWrapper.TaxRate> TaxRateList;
    	
    	public TaxCode() {}
    	public TaxCode(Sales_Tax__c salesTaxRec, List<Applicable_Taxes__c> appTaxesList) {
    		this.Id = salesTaxRec.Id;
    		this.Name = salesTaxRec.Name__c;
    		this.IsDefault = salesTaxRec.Default__c;
    		this.IsActive = salesTaxRec.Active__c;
    		this.FormsLabel = salesTaxRec.Forms_Label__c;
    		this.IsListRatesOnForms = salesTaxRec.Forms_List_Taxes__c;
    		this.TaxType = salesTaxRec.Tax_Type__c;
    		
    		this.RatesIncluded = '';
    		this.TotalRateStr = '';
    		this.TaxRateList = new List<TaxRateWrapper.TaxRate>();
    		if(appTaxesList != null) {
    			Boolean isTaxRateOtherThanFixedRate = false;
    			Decimal totalRate = 0;
				Boolean isDistrictTaxIncluded = false;
    			for(Applicable_Taxes__c appTaxRec: appTaxesList) {
    				if(!isTaxRateOtherThanFixedRate && !appTaxRec.Sales_Tax_Item__r.Rate_Type__c.equalsIgnoreCase(TaxManagementService.FIXED_RATE)) {
    					isTaxRateOtherThanFixedRate = true;
    				}
    				if(!isTaxRateOtherThanFixedRate) {
    					totalRate += appTaxRec.Sales_Tax_Item__r.Rate__c;
    				}
					if(TaxActivityAndSettingService.isAutomatedDistrictTax(appTaxRec.Sales_Tax_Item__r)) {
						if(!isDistrictTaxIncluded) {
							isDistrictTaxIncluded = true;
							this.RatesIncluded += convertToCamelCase(ZipTaxUtil.DISTRICT_TAX) + ', ';
						}
					} else {
						this.RatesIncluded += convertToCamelCase(appTaxRec.Sales_Tax_Item__r.Name__c) + ', ';
					}
    				this.TaxRateList.add(new TaxRateWrapper.TaxRate(appTaxRec));
    			}
    			if(this.RatesIncluded.length() > 2) {
    				this.RatesIncluded = this.RatesIncluded.subString(0, this.RatesIncluded.length() - 2);
    			}
    			if(isTaxRateOtherThanFixedRate) {
    				this.TotalRateStr = TaxManagementService.MULTIPLE_RATES;
    			} else {
    				this.TotalRateStr = String.valueOf(totalRate) + '%';
    			}
    		}
    	}
    }
    
    private static String convertToCamelCase(String textToConvert) {
    	textToConvert = textToConvert != null ? textToConvert.toLowerCase() : '';
    	if(textToConvert.length() > 0) {
    		String firstLetterCapital = (textToConvert.subString(0, 1)).toUpperCase();
    		textToConvert = firstLetterCapital + textToConvert.subString(1, textToConvert.length());
    	}
    	
    	return textToConvert;
    }
    
    public static List<String> salesTaxFieldsList() {
		return new List<String> {'Id', 
								'Name__c',
								'Default__c',
								'Active__c',
								'Forms_Label__c',
								'Forms_List_Taxes__c',
								'Tax_Type__c',
								'Accounting_Id__c',
								'Rate__c'
								};
	}
}
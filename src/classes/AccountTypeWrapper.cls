public class AccountTypeWrapper {
	public String Id;
	public String AccountType;
	public String AppliesTo;
	public String TaxExemptions;
	public Boolean IsDefault;
	public Boolean IsActive;
	public Boolean IsUpdatable;
	public List<TaxExemptions> TaxExemptionsList;
	
	public AccountTypeWrapper(Account_Type__c accTypeRec, List<Tax_Exemption__c> taxExemptions) {
		setDefaultFields(accTypeRec, (taxExemptions != null ? taxExemptions : new List<Tax_Exemption__c>()));
	}

	public AccountTypeWrapper(Account_Type__c accTypeRec) {
		setDefaultFields(accTypeRec, accTypeRec.Tax_Exemptions__r);
		this.IsUpdatable = ((accTypeRec.Accounts__r != null && accTypeRec.Accounts__r.size() > 0) || 
							(accTypeRec.Accounts1__r != null && accTypeRec.Accounts1__r.size() > 0)) ? false : true; 
	}

	private void setDefaultFields(Account_Type__c accTypeRec, List<Tax_Exemption__c> taxExemptions) {
		this.Id = accTypeRec.Id;
		this.AccountType = accTypeRec.Name;
		this.AppliesTo = accTypeRec.Applies_To__c;
		this.TaxExemptions = '';
		if(taxExemptions != null) {
			if(taxExemptions.isEmpty()) {
				this.TaxExemptions = 'None';
			} else {
				Boolean isDistrictTaxIncluded = false;
				for(Tax_Exemption__c tax : taxExemptions) {
					if(tax.Sales_Tax_Item__r.Name__c != null && String.isNotBlank(tax.Sales_Tax_Item__r.Name__c)) {
						if(TaxActivityAndSettingService.isAutomatedDistrictTax(tax.Sales_Tax_Item__r)) {
							if(!isDistrictTaxIncluded) {
								isDistrictTaxIncluded = true;
								this.TaxExemptions += ZipTaxUtil.DISTRICT_TAX + ', ' ;
							}
						} else {
							this.TaxExemptions += tax.Sales_Tax_Item__r.Name__c + ', ' ;
						}
					}
				}
				this.TaxExemptions = this.TaxExemptions.length() > 2 ? this.TaxExemptions.subString(0,this.TaxExemptions.length() - 2) :  this.TaxExemptions;
			}
		}
		this.IsDefault = accTypeRec.Default__c;
		this.IsActive = accTypeRec.Active__c;
	}
	
	public AccountTypeWrapper(Account_Type__c accTypeRec,List<TaxExemptions> taxExemptionsList) {
		this.Id = accTypeRec.Id;
		this.AccountType = accTypeRec.Name;
		this.AppliesTo = accTypeRec.Applies_To__c;
		this.TaxExemptionsList = taxExemptionsList;
		this.IsDefault = accTypeRec.Default__c;
		this.IsActive = accTypeRec.Active__c;
		this.IsUpdatable = (accTypeRec.Accounts__r.size() > 0 || accTypeRec.Accounts1__r.size()> 0) ? false : true;
		
		this.TaxExemptions = '';
		if(accTypeRec.Tax_Exemptions__r.size() == 0) {
			this.TaxExemptions = 'None';
		} else {
			for(Tax_Exemption__c tax : accTypeRec.Tax_Exemptions__r) {
				if(tax.Sales_Tax_Item__r.Name__c != null && String.isNotBlank(tax.Sales_Tax_Item__r.Name__c)) {
			    	this.TaxExemptions += tax.Sales_Tax_Item__r.Name__c + ', ' ;
				}
			}
			this.TaxExemptions = this.TaxExemptions.length() > 2 ? this.TaxExemptions.subString(0,this.TaxExemptions.length() - 2) :  this.TaxExemptions;
		}
	}
	public static List<String> getAccountTypeFields() {
       return new List<String>{'Name', 
                                'Active__c', 
                                'Applies_To__c',
                                'Default__c'
                              };
    }
}
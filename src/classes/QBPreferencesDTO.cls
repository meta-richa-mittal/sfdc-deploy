public without sharing class QBPreferencesDTO {
    
    public VendorAndPurchasesPrefsWrapper VendorAndPurchasesPrefs;
    public AccountingInfoPrefsWrapper AccountingInfoPrefs;
    public CurrencyPrefsWrapper CurrencyPrefs;
    public VendorAndPurchasesPrefsWrapper SalesFormsPrefs;
	
    public class VendorAndPurchasesPrefsWrapper {
        public ReferenceTypeWrapper DefaultTerms;    
    }
    
    public class AccountingInfoPrefsWrapper {
    	public String BookCloseDate;
    }

    public class CurrencyPrefsWrapper {
        public ReferenceTypeWrapper HomeCurrency;
        public Boolean MultiCurrencyEnabled;  
    }
    
    public class ReferenceTypeWrapper {
        public String value;    
    }
}
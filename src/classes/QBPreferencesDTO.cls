public without sharing class QBPreferencesDTO {
	public PreferencesWrapper Preferences;
	
	public class PreferencesWrapper {
		public VendorAndPurchasesPrefsWrapper VendorAndPurchasesPrefs;
    	public AccountingInfoPrefsWrapper AccountingInfoPrefs;
	}
	
    public class VendorAndPurchasesPrefsWrapper {
        public TermRefWrapper DefaultTerms;    
    }
    
    public class AccountingInfoPrefsWrapper {
    	public String BookCloseDate;
    }
    
    public class TermRefWrapper {
        public String value;    
    }
}
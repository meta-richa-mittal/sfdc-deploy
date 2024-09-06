public without sharing class QBInvoiceDueDateService {
	public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static Date getVendorInvoiceDueDate(Date invoiceDate, String vendorAccountingId) {
        Date dueDate = invoiceDate;
        String termQBId = getVendorPaymentTerm(vendorAccountingId);
        if(String.isBlank(termQBId)) {
            termQBId = getQBPreferenceDefaultPaymentTerm();
        }
        if(String.isNotBlank(termQBId)) {
            dueDate = getDueDateForBills(invoiceDate, termQBId);
        }
        return dueDate;
    }
    
    public static String getVendorPaymentTerm(String vendorAccountingId) {
        String termQBId = '';
        //HttpResponse response = QuickbookConnector.getRequestFromQuickBooks('vendor', vendorAccountingId);
        QuickbookConnector.ResponseWrapper resObj = QuickbookConnector.getRequestFromQB('vendor', vendorAccountingId);
        HttpResponse response = resObj.Response;
        refreshToken = resObj.RefreshToken;
		refreshTokenExpiresIn = resObj.RefreshTokenExpiresIn;
        if(response.getStatusCode() == 200) { 
            VendorResponseQB vendorObj = (VendorResponseQB)System.JSON.deserialize(response.getBody(), VendorResponseQB.class);
            if(vendorObj.vendor != null && vendorObj.vendor.TermRef != null) {
                termQBId = vendorObj.vendor.TermRef.value;
            }
        } else {
            throw new BlackpurlException('There is some error fetching vendor details from QuickBooks Online.');
        }
        return termQBId;
    }
    
    public static String getQBPreferenceDefaultPaymentTerm() {
        String termQBId = '';
        //HttpResponse response = QuickbookConnector.getRequestFromQuickBooks('preferences', null);
        QuickbookConnector.ResponseWrapper resObj = QuickbookConnector.getRequestFromQB('preferences', null);
        HttpResponse response = resObj.Response;
        refreshToken = resObj.RefreshToken;
		refreshTokenExpiresIn = resObj.RefreshTokenExpiresIn;
        if(response.getStatusCode() == 200) { 
            QBPreferencesDTO preferenceObj = (QBPreferencesDTO)System.JSON.deserialize(response.getBody(), QBPreferencesDTO.class);
            if(preferenceObj.Preferences != null && preferenceObj.Preferences.VendorAndPurchasesPrefs != null && 
                preferenceObj.Preferences.VendorAndPurchasesPrefs.DefaultTerms != null) {
                termQBId = preferenceObj.Preferences.VendorAndPurchasesPrefs.DefaultTerms.value;
            }
        } else {
            throw new BlackpurlException('There is some error fetching organization term details from QuickBooks Online.');
        }
        return termQBId;
    }
    
    public static Date getDueDateForBills(Date invoiceDate, String termQBId) {
        Date dueDate = invoiceDate;
        try {
	        List<QB_Term__c> qbTermList = [SELECT Day_of_Month_Due__c, Due_Days__c, Due_Next_Month_Days__c, Type__c FROM QB_Term__c 
	                                           WHERE Accounting_Id__c =: termQBId];
	        if(qbTermList.size() > 0) {
	            QB_Term__c qbTermRec = qbTermList[0];
	            if(qbTermRec.Type__c == 'STANDARD' && qbTermRec.Due_Days__c != null) {
		            dueDate = invoiceDate.addDays(Integer.valueOf(qbTermRec.Due_Days__c));
		        } else if(qbTermRec.Type__c == 'DATE_DRIVEN') {
		            Integer invoiceDateMonth = invoiceDate.month();
		            Integer invoiceDateDay = invoiceDate.day();
		            Integer dayOfMonthDue = (qbTermRec.Day_of_Month_Due__c != null) ? Integer.valueOf(qbTermRec.Day_of_Month_Due__c) : null;
		            Integer dueNextMonthDays = (qbTermRec.Due_Next_Month_Days__c != null) ? Integer.valueOf(qbTermRec.Due_Next_Month_Days__c) : null;
		            
		            if(dayOfMonthDue != null && invoiceDateDay > dayOfMonthDue) {
		                dueDate = invoiceDate.toStartOfMonth().addMonths(1).addDays(dayOfMonthDue - 1);
		            } else if(dueNextMonthDays != null && dayOfMonthDue != null && invoiceDateDay + dueNextMonthDays <= dayOfMonthDue) {
		                dueDate = invoiceDate.addDays(dayOfMonthDue - invoiceDateDay);
		            } else if(dayOfMonthDue != null) {
		                dueDate = invoiceDate.toStartOfMonth().addMonths(1).addDays(dayOfMonthDue - 1);
		            }
		        }
	        }
        } catch(Exception e) {
        }
        return dueDate;
    }
    
    public class VendorResponseQB {
        public QBVendor vendor;
    }
    public class QBVendor {
        public TermRefWrapper TermRef; 
    }
    public class TermRefWrapper {
        public String value;    
    }
    
    /*public class PreferencesResponseQB {
        public QBPreferencesDTO Preferences;
    }
    public class QBPreferences {
        public VendorAndPurchasesPrefsWrapper VendorAndPurchasesPrefs; 
    }*/
    public class VendorAndPurchasesPrefsWrapper {
        public TermRefWrapper DefaultTerms;    
    }
}
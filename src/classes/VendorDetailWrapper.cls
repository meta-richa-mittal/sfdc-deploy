/**
 * Author: Tarun Khandelwal
 * Since: Aug 02, 2018
 * Name: VendorDetailWrapper
 * Description: Apex class to get vendor data for messaging popup for now - It can be used other places
**/
public class VendorDetailWrapper {
    public String VendorId;
    public String VendorName;
    public String PrefferedEmail;
    public String VendorWorkEmail;
    public String VendorOtherEmail;
    public String VendorAccountNumber;
    public String DefaultExportFormat;
    public String DefaultExportFormatName;
    public Boolean IsCustomExportFormatDefined;
    public Boolean IsForeignVendor;
    public ForeignExchangeUtil.CurrencyWrapper FXCurrencyDetails;
    
    public VendorDetailWrapper() {
        
    }

    public VendorDetailWrapper(Account vendorRec, Boolean isCustomExportFormatDefined) {
    	this.VendorId = vendorRec.Id;
    	this.VendorName = vendorRec.Name;
    	this.PrefferedEmail = vendorRec.Preferred_Email__c;
    	this.VendorWorkEmail = vendorRec.Work_Email__c;
    	this.VendorOtherEmail = vendorRec.Other_Email__c;
        this.VendorAccountNumber = vendorRec.AccountNumber;
        this.DefaultExportFormat = vendorRec.Default_Export_Format__c;
        this.DefaultExportFormatName = vendorRec.Default_Export_Format__r.File_Name__c;
        this.IsCustomExportFormatDefined = isCustomExportFormatDefined;
        this.IsForeignVendor = vendorRec.Is_Foreign_Vendor__c;
        if(this.IsForeignVendor) {
            this.FXCurrencyDetails = new ForeignExchangeUtil.CurrencyWrapper(vendorRec.Country__r, true);
        }       
    }
    
    public static List<String> fieldsList() {
        List<String> vendorFields = new List<String>{ 'Name',
                                                    'Default_Export_Format__c',
                                                    'Default_Export_Format__r.File_Name__c',
                                                    'Work_Email__c',
                                                    'Preferred_Email__c',
                                                    'Other_Email__c',
                                                    'AccountNumber', 
                                                    'Country__c',
                                                    'Country__r.Name__c', 
                                                    'Country__r.Default__c',
                                                    'Country__r.Visible__c',
                                                    'Country__r.Currency_Code__c',
                                                    'Country__r.Active__c',
                                                    'Country__r.Currency_Name__c',
                                                    'Country__r.Currency_Symbol__c',
                                                    'Country__r.Flag_Encoded__c',
                                                    'Country__r.Conversion_Rate__c',
                                                    'Country__r.Conversion_Rate_With_Markup__c', 
                                                    'Is_Foreign_Vendor__c', 
                                                    'Country__r.Formatted_FX_Currency_Code__c',
                                                    'Country__r.Backward_Conversion_Rate__c'
                                                };
        return vendorFields;
    }
}
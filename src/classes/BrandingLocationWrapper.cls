/**
* Author: Nikhil Kumar Srivastava
* Since: May 22, 2019
* Name: BrandingLocationWrapper
* Description: Apex class to wrap variables for Branding Location section in Branding Location page
**/

public without sharing class BrandingLocationWrapper {
	
	public String Id;
	public String BusinessLocationName;
	public String BusinessCity;
	public String BusinessCountry;
	public String BusinessCountryId;
	public String BusinessPhone;
	public String FormattedBusinessPhone;
    public String BusinessEmailAddress;
    public String BusinessPostalCode;
    public String BusinessState;
    public String BusinessStateId;
    public String BusinessStreetAddress1;
    public String BusinessStreetAddress2;
    
    public String DisclaimerforCustomerInvoice;
    public String DisclaimerforDealDocuments;
    public String DisclaimerforOrderDeposit;
    public String DisclaimerforReceipt;
    public String DisclaimerforServiceJob;
    
    public Boolean IsDisclaimerforCustomerInvoice;
    public Boolean IsDisclaimerforDealDocuments;
    public Boolean IsDisclaimerforOrderDeposit;
    public Boolean IsDisclaimerforReceipt;
    public Boolean IsDisclaimerforServiceJob;
    
    public Boolean IsSignatureforCustomerInvoice;
    public Boolean IsSignatureforDealDocuments;
    public Boolean IsSignatureforOrderDeposit;
    public Boolean IsSignatureforReceipt;
    public Boolean IsSignatureforServiceJob;
    
    public String TaxID;
    public String AttachmentId;
	public String AttachmentURL;
	public String AttachmentNameWithExtension;
	public String AttachmentFileData;
	public Decimal AttachmentFileSizeInKB;
	public Decimal LogoHeight;
	public Decimal LogoWidth; 

    public BrandingLocationWrapper() {}
    
    public BrandingLocationWrapper(String brandingLocationId, String brandingLocationName) {
    	this.Id = brandingLocationId;
		this.BusinessLocationName = brandingLocationName;
    }
    
    public void setAllBrandingLocationFields(Branding_Location__c brandingLocationRec) {
    	this.Id = brandingLocationRec.Id;
		this.BusinessLocationName = brandingLocationRec.Business_Location_Name__c != null ? brandingLocationRec.Business_Location_Name__c : '' ;
		this.BusinessCity = brandingLocationRec.Business_City__c != null ? brandingLocationRec.Business_City__c : '' ;
		this.BusinessCountry = brandingLocationRec.Business_Country__r.Name__c != null ? brandingLocationRec.Business_Country__r.Name__c : '';
		this.BusinessCountryId = brandingLocationRec.Business_Country__c;
		this.BusinessPhone = brandingLocationRec.Business_Phone__c != null ? brandingLocationRec.Business_Phone__c : '' ;
		this.FormattedBusinessPhone = brandingLocationRec.Formatted_Business_Phone__c != null ? brandingLocationRec.Formatted_Business_Phone__c : '' ;
		this.BusinessEmailAddress = brandingLocationRec.Business_Email_Address__c != null ? brandingLocationRec.Business_Email_Address__c : '' ;
		this.BusinessPostalCode = brandingLocationRec.Business_Postal_Code__c != null ? brandingLocationRec.Business_Postal_Code__c : '' ;
		this.BusinessState = brandingLocationRec.Business_State__r.Display_Name__c != null ? brandingLocationRec.Business_State__r.Display_Name__c : '';
		this.BusinessStateId = brandingLocationRec.Business_State__c;
		this.BusinessStreetAddress1 = brandingLocationRec.Business_Street_Address1__c != null ? brandingLocationRec.Business_Street_Address1__c : '' ;
		this.BusinessStreetAddress2 = brandingLocationRec.Business_Street_Address2__c != null ? brandingLocationRec.Business_Street_Address2__c : '' ;
		
		this.DisclaimerforCustomerInvoice = brandingLocationRec.Disclaimer_for_Customer_Invoice__c != null ? brandingLocationRec.Disclaimer_for_Customer_Invoice__c : '' ;
		this.DisclaimerforDealDocuments = brandingLocationRec.Disclaimer_for_Deal_Documents__c != null ? brandingLocationRec.Disclaimer_for_Deal_Documents__c : '' ;
		this.DisclaimerforOrderDeposit = brandingLocationRec.Disclaimer_for_Order_Deposit__c != null ? brandingLocationRec.Disclaimer_for_Order_Deposit__c : '' ;
		this.DisclaimerforReceipt = brandingLocationRec.Disclaimer_for_Receipts__c != null ? brandingLocationRec.Disclaimer_for_Receipts__c : '' ;
		this.DisclaimerforServiceJob = brandingLocationRec.Disclaimer_for_Service_Job__c != null ? brandingLocationRec.Disclaimer_for_Service_Job__c : '' ;
		
		this.IsDisclaimerforCustomerInvoice = brandingLocationRec.Is_Disclaimer_for_Customer_Invoice__c ;
		this.IsDisclaimerforDealDocuments = brandingLocationRec.Is_Disclaimer_for_Deal_Documents__c;
		this.IsDisclaimerforOrderDeposit = brandingLocationRec.Is_Disclaimer_for_Order_Deposit__c;
		this.IsDisclaimerforReceipt = brandingLocationRec.Is_Disclaimer_for_Receipts__c;
		this.IsDisclaimerforServiceJob = brandingLocationRec.Is_Disclaimer_for_Service_Job__c;
		
		this.IsSignatureforCustomerInvoice = brandingLocationRec.Is_Signature_for_Customer_Invoice__c;
		this.IsSignatureforDealDocuments = brandingLocationRec.Is_Signature_for_Deal_Documents__c;
		this.IsSignatureforOrderDeposit = brandingLocationRec.Is_Signature_for_Order_Deposit__c;
		this.IsSignatureforReceipt = brandingLocationRec.Is_Signature_for_Receipts__c;
		this.IsSignatureforServiceJob = brandingLocationRec.Is_Signature_for_Service_Job__c;
		
		this.TaxID = brandingLocationRec.Tax_Id__c != null ? brandingLocationRec.Tax_Id__c : '' ;
		if(brandingLocationRec.Attachments.size() > 0) {
        	this.AttachmentId = brandingLocationRec.Attachments[0].Id;
        	this.AttachmentURL = '/servlet/servlet.FileDownload?file='+AttachmentId;
        	this.AttachmentNameWithExtension = brandingLocationRec.Attachments[0].Name;
        	this.AttachmentFileSizeInKB = brandingLocationRec.Attachments[0].BodyLength != null ? Math.ceil(Decimal.valueof(brandingLocationRec.Attachments[0].BodyLength)/1024) : 0;
        }
        this.LogoHeight = brandingLocationRec.Logo_Height__c;
		this.LogoWidth = brandingLocationRec.Logo_Width__c;
    }
    
     public void setBussinessFieldsForBranding(Branding_Location__c brandingLocationRec) {
    	this.Id = brandingLocationRec.Id;
		this.BusinessLocationName = brandingLocationRec.Business_Location_Name__c != null ? brandingLocationRec.Business_Location_Name__c : '' ;
		this.BusinessCity = brandingLocationRec.Business_City__c != null ? brandingLocationRec.Business_City__c : '' ;
		this.BusinessCountry = brandingLocationRec.Business_Country__r.Name__c != null ? brandingLocationRec.Business_Country__r.Name__c : '';
		this.BusinessPostalCode = brandingLocationRec.Business_Postal_Code__c != null ? brandingLocationRec.Business_Postal_Code__c : '' ;
		this.BusinessState = brandingLocationRec.Business_State__r.Display_Name__c != null ? brandingLocationRec.Business_State__r.Display_Name__c : '';
		this.BusinessStreetAddress1 = brandingLocationRec.Business_Street_Address1__c != null ? brandingLocationRec.Business_Street_Address1__c : '' ;
		this.BusinessStreetAddress2 = brandingLocationRec.Business_Street_Address2__c != null ? brandingLocationRec.Business_Street_Address2__c : '' ;
		if(brandingLocationRec.Attachments.size() > 0) {
        	this.AttachmentId = brandingLocationRec.Attachments[0].Id;
        	this.AttachmentURL = '/servlet/servlet.FileDownload?file='+AttachmentId;
        }
		
     }
     
    public void setDefaultBrandingLocation(Business_Profile__c businessProfileRec) {
    	this.BusinessLocationName = businessProfileRec.Business_Name__c != null ? businessProfileRec.Business_Name__c : '' ;
		this.BusinessCity = businessProfileRec.Business_City__c != null ? businessProfileRec.Business_City__c : '' ;
		this.BusinessCountry = businessProfileRec.Business_Country__r.Name__c != null ? businessProfileRec.Business_Country__r.Name__c : '' ;
		this.BusinessCountryId = businessProfileRec.Business_Country__c;
		this.BusinessPhone = businessProfileRec.Business_Phone__c != null ? businessProfileRec.Business_Phone__c : '' ;
		this.FormattedBusinessPhone = businessProfileRec.Formatted_Business_Number__c != null ? businessProfileRec.Formatted_Business_Number__c : '' ;
		this.BusinessEmailAddress = businessProfileRec.Business_Email__c != null ? businessProfileRec.Business_Email__c : '' ;
		this.BusinessPostalCode = businessProfileRec.Business_Postal_Code__c != null ? businessProfileRec.Business_Postal_Code__c : '' ;
		this.BusinessState = businessProfileRec.Business_State__r.Display_Name__c != null ? businessProfileRec.Business_State__r.Display_Name__c : '' ;
		this.BusinessStateId = businessProfileRec.Business_State__c;
		this.BusinessStreetAddress1 = businessProfileRec.Business_Street_Address1__c != null ? businessProfileRec.Business_Street_Address1__c : '' ;
		this.BusinessStreetAddress2 = businessProfileRec.Business_Street_Address2__c != null ? businessProfileRec.Business_Street_Address2__c : '' ;
		
		this.DisclaimerforCustomerInvoice = businessProfileRec.Customer_Invoice_Warranty_Text__c != null ? businessProfileRec.Customer_Invoice_Warranty_Text__c : '' ;
		this.DisclaimerforDealDocuments = businessProfileRec.Deal_Documents_Warranty_Text__c != null ? businessProfileRec.Deal_Documents_Warranty_Text__c : '' ;
		this.DisclaimerforOrderDeposit = businessProfileRec.Order_Deposit_Warranty_Text__c != null ? businessProfileRec.Order_Deposit_Warranty_Text__c : '' ;
		this.DisclaimerforReceipt = businessProfileRec.Sales_Receipt_Warranty_Text__c != null ? businessProfileRec.Sales_Receipt_Warranty_Text__c : '' ;
		this.DisclaimerforServiceJob = businessProfileRec.Service_Job_Warranty_Text__c != null ? businessProfileRec.Service_Job_Warranty_Text__c : '' ;
    	
    	this.IsDisclaimerforCustomerInvoice = businessProfileRec.Customer_Invoice_Warranty_Text__c != null && businessProfileRec.Customer_Invoice_Warranty_Text__c.length() > 0 ? true : false;
		this.IsDisclaimerforDealDocuments = businessProfileRec.Deal_Documents_Warranty_Text__c != null && businessProfileRec.Deal_Documents_Warranty_Text__c.length() > 0 ? true : false;
		this.IsDisclaimerforOrderDeposit = businessProfileRec.Order_Deposit_Warranty_Text__c != null && businessProfileRec.Order_Deposit_Warranty_Text__c.length() > 0 ? true : false;
		this.IsDisclaimerforReceipt = businessProfileRec.Sales_Receipt_Warranty_Text__c != null && businessProfileRec.Sales_Receipt_Warranty_Text__c.length() > 0 ? true : false;
		this.IsDisclaimerforServiceJob = businessProfileRec.Service_Job_Warranty_Text__c != null && businessProfileRec.Service_Job_Warranty_Text__c.length() > 0 ? true : false;
		
		this.IsSignatureforCustomerInvoice = businessProfileRec.Is_Signature_Line_for_Customer_Invoice__c;
		this.IsSignatureforDealDocuments = businessProfileRec.Is_Signature_Line_for_Deal_Documents__c;
		this.IsSignatureforOrderDeposit = businessProfileRec.Is_Signature_Line_for_Order_Deposit__c;
		this.IsSignatureforReceipt = businessProfileRec.Is_Signature_Line_for_Sales_Receipt__c;
		this.IsSignatureforServiceJob = businessProfileRec.Is_Signature_Line_for_Service_Job__c;
		this.TaxID = GeneralConfiguration.getConfigurationsTaxId();
		this.AttachmentURL = GeneralConfiguration.getCompanyLogoUrl();
		this.LogoHeight = businessProfileRec.Logo_Height__c;
		this.LogoWidth = businessProfileRec.Logo_Width__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method to get all fields related to Branding_Location__c object
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList() {
        return new List<String>{'Id',
        						'Business_Location_Name__c',
                                'Business_City__c',
                                'Business_Country__c',
                                'Business_Country__r.Name__c',
                                'CreatedDate',
                                'LastModifiedDate',
                                'Business_Email_Address__c',
                                'Business_Phone__c',
                                'Formatted_Business_Phone__c',
                                'Business_Postal_Code__c',
                                'Business_State__c',
                                'Business_State__r.Name__c',
                                'Business_State__r.Display_Name__c',
                                'Business_Street_Address1__c',
                                'Business_Street_Address2__c',
                                'Disclaimer_for_Customer_Invoice__c',
                                'Disclaimer_for_Deal_Documents__c',
                                'Disclaimer_for_Order_Deposit__c',
                                'Disclaimer_for_Receipts__c',
                                'Disclaimer_for_Service_Job__c',
                                'Is_Disclaimer_for_Customer_Invoice__c',
                                'Is_Disclaimer_for_Deal_Documents__c',
                                'Is_Disclaimer_for_Order_Deposit__c',
                                'Is_Disclaimer_for_Receipts__c',
                                'Is_Disclaimer_for_Service_Job__c',
                                'Is_Signature_for_Customer_Invoice__c',
                                'Is_Signature_for_Deal_Documents__c',
                                'Is_Signature_for_Order_Deposit__c',
                                'Is_Signature_for_Receipts__c',
                                'Is_Signature_for_Service_Job__c',
                                'Tax_Id__c',
                                'Logo_Height__c',
                                'Logo_Width__c'
                        };
    }
}
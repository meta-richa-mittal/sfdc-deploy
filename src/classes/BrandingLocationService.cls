/**
* Author: Author: Nikhil Kumar Srivastava
* Since: May 22, 2019
* Name: BrandingLocationService
* Description: Service class for Branding Location
**/
public without sharing class BrandingLocationService {
	
	/** 
     * Name: getDefaultBrandingLocation
     * Desc: This method will get the default Branding Location details.
     * @param:  
     * @return: BrandingLocationWrapper object 
    **/
	public static BrandingLocationWrapper getDefaultBrandingLocation() {
		if(AccessControl.ifObjectFieldIsAccessible('Business_Profile__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
    	BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
    	brandingLocationObj.setDefaultBrandingLocation(businessProfileList[0]);
        return brandingLocationObj;
    } 
	
    public static List<BrandingLocationWrapper> getBrandingLocationList() {
    	if(AccessControl.ifObjectFieldIsAccessible('Branding_Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Branding_Location__c> brandingLocationRecList = [SELECT Id, Business_Location_Name__c FROM Branding_Location__c 
														ORDER BY Name ASC LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
		
		List<BrandingLocationWrapper> brandingLocationObjList = new List<BrandingLocationWrapper>();
		for(Branding_Location__c brandingLocationRec : brandingLocationRecList) {
			brandingLocationObjList.add(new BrandingLocationWrapper(brandingLocationRec.Id, brandingLocationRec.Business_Location_Name__c));
		}
		return brandingLocationObjList;
	}
	
    public static List<BrandingLocationWrapper> getBrandingLocation(Map<String, String> fieldNameToFieldValueMap, Boolean onlyBusinessInfoNeeded) {
    	List<BrandingLocationWrapper> brandingLocationObjList = new List<BrandingLocationWrapper>();
    	for(Branding_Location__c brandingLocationRec: BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(fieldNameToFieldValueMap)) {
    		BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
    		if(onlyBusinessInfoNeeded) {
    			brandingLocationObj.setBussinessFieldsForBranding(brandingLocationRec);
    		} else {
    			brandingLocationObj.setAllBrandingLocationFields(brandingLocationRec);
    		}
    		brandingLocationObjList.add(brandingLocationObj); 
    	}
    	return brandingLocationObjList; 
    }
	
	 /** 
     * Name: saveBrandingLocation
     * Desc: This method will save the Branding Location details 
     * @param: brandingLocationJson - JSON 
     * @return: String - Success or Error 
    **/
	public static String saveBrandingLocation(String brandingLocationJson) {
    	BrandingLocationWrapper brandingLocationObj = (BrandingLocationWrapper) System.JSON.deserialize(brandingLocationJson, BrandingLocationWrapper.class);
    	Branding_Location__c brandingLocationRec = setBrandingLocation(brandingLocationObj);

		DMLUtility.upsertSobjectList('Branding_Location__c', brandingLocationRec);
    	
    	brandingLocationObj.Id = brandingLocationRec.Id;
    	if(brandingLocationObj.AttachmentFileData != null) {
    		brandingLocationObj.AttachmentURL = '/servlet/servlet.FileDownload?file=' + uploadLogo(brandingLocationRec.Id, brandingLocationObj);
    		return System.JSON.serialize(brandingLocationObj);
    	} else if(brandingLocationObj.AttachmentId != null && (brandingLocationObj.LogoHeight == null || brandingLocationObj.LogoWidth == null)) {
    		brandingLocationObj.AttachmentURL = '/servlet/servlet.FileDownload?file=' + brandingLocationObj.AttachmentId;
    		return System.JSON.serialize(brandingLocationObj);
    	}
    	return null;  
	}
    
    public static String deleteBrandingLocation(String brandingLocationId) {
    	Branding_Location__c brandingLocationRec = new Branding_Location__c(Id = brandingLocationId);
		if(AccessControl.ifObjectIsDeletable('Branding_Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
		delete brandingLocationRec;
		return System.JSON.serialize(new ResponseWrapper('success', 'success'));
    }
    
    public static String isBrandingLocationActive(String brandingLocationId) {
    	Branding_Location__c brandingLocationRec = new Branding_Location__c(Id = brandingLocationId);
		if(AccessControl.ifObjectIsDeletable('Branding_Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
		delete brandingLocationRec;
		return System.JSON.serialize(new ResponseWrapper('success', 'success'));
    }
    
     public static String uploadLogo(String brandingLocationRecId, BrandingLocationWrapper brandingLocationObj) {
     	String fileData = brandingLocationObj.AttachmentFileData; 
        String base64 = fileData.substring(fileData.indexOf(',') + 1);
        Blob actualdata = EncodingUtil.base64Decode(base64);
        if(brandingLocationObj.AttachmentId != null){
        	Attachment att = new Attachment(Id = brandingLocationObj.AttachmentId);
        	if(AccessControl.ifObjectIsDeletable('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
			delete att;
        }
        Attachment att = new Attachment(ParentId = brandingLocationRecId, Body = actualdata);
        att.Name = brandingLocationObj.AttachmentNameWithExtension;
        if(AccessControl.ifObjectFieldIsCreateable('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        DMLUtility.insertSobjectList('Attachment', att);
        return att.Id;
    }
    
    public static void saveLogoDimensions(String logoJson) {
    	BrandingLocationWrapper brandingLocationObj = (BrandingLocationWrapper) System.JSON.deserialize(logoJson, BrandingLocationWrapper.class);
    	if(String.isBlank(brandingLocationObj.Id)) throw new BlackPurlException('Invalid Branding Location'); 
		update new Branding_Location__c(Id = brandingLocationObj.Id, Logo_Height__c = brandingLocationObj.LogoHeight, Logo_Width__c = brandingLocationObj.LogoWidth);
    }
    
    public static Branding_Location__c setBrandingLocation(BrandingLocationWrapper brandingLocationObj) {
    	Branding_Location__c brandingLocationRec = new Branding_Location__c();
    	brandingLocationRec.Id = brandingLocationObj.Id;
    	brandingLocationRec.Business_Location_Name__c = brandingLocationObj.BusinessLocationName;
    	brandingLocationRec.Business_City__c = brandingLocationObj.BusinessCity;
    	brandingLocationRec.Business_Country__c = brandingLocationObj.BusinessCountryId;
    	brandingLocationRec.Business_Email_Address__c = brandingLocationObj.BusinessEmailAddress;
    	brandingLocationRec.Business_Phone__c = brandingLocationObj.BusinessPhone;
    	brandingLocationRec.Business_Postal_Code__c = brandingLocationObj.BusinessPostalCode;
    	brandingLocationRec.Business_State__c = brandingLocationObj.BusinessStateId;
    	brandingLocationRec.Business_Street_Address1__c = brandingLocationObj.BusinessStreetAddress1;
    	brandingLocationRec.Business_Street_Address2__c = brandingLocationObj.BusinessStreetAddress2;
    	
    	brandingLocationRec.Disclaimer_for_Customer_Invoice__c = brandingLocationObj.DisclaimerforCustomerInvoice;
    	brandingLocationRec.Disclaimer_for_Deal_Documents__c = brandingLocationObj.DisclaimerforDealDocuments;
    	brandingLocationRec.Disclaimer_for_Order_Deposit__c = brandingLocationObj.DisclaimerforOrderDeposit;
    	brandingLocationRec.Disclaimer_for_Receipts__c = brandingLocationObj.DisclaimerforReceipt;
    	brandingLocationRec.Disclaimer_for_Service_Job__c = brandingLocationObj.DisclaimerforServiceJob;
    	
    	brandingLocationRec.Is_Disclaimer_for_Customer_Invoice__c = brandingLocationObj.IsDisclaimerforCustomerInvoice;
    	brandingLocationRec.Is_Disclaimer_for_Deal_Documents__c = brandingLocationObj.IsDisclaimerforDealDocuments;
    	brandingLocationRec.Is_Disclaimer_for_Order_Deposit__c = brandingLocationObj.IsDisclaimerforOrderDeposit;
    	brandingLocationRec.Is_Disclaimer_for_Receipts__c = brandingLocationObj.IsDisclaimerforReceipt;
    	brandingLocationRec.Is_Disclaimer_for_Service_Job__c = brandingLocationObj.IsDisclaimerforServiceJob;
    	
    	brandingLocationRec.Is_Signature_for_Customer_Invoice__c = brandingLocationObj.IsSignatureforCustomerInvoice;
    	brandingLocationRec.Is_Signature_for_Deal_Documents__c = brandingLocationObj.IsSignatureforDealDocuments;
    	brandingLocationRec.Is_Signature_for_Order_Deposit__c = brandingLocationObj.IsSignatureforDealDocuments;
    	brandingLocationRec.Is_Signature_for_Receipts__c = brandingLocationObj.IsSignatureforReceipt;
    	brandingLocationRec.Is_Signature_for_Service_Job__c = brandingLocationObj.IsSignatureforServiceJob;
    	
    	brandingLocationRec.Tax_Id__c = brandingLocationObj.TaxID;
    	
    	return brandingLocationRec;
    }
}
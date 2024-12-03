/**
 * Author: Nidhi Sharma
 * Since: March 20, 2019
 * Name: VendorMasterWrapper
 * Description: VendorMasterWrapper class.
**/
global class VendorMasterWrapper {
	public Id VendorMasterId;
	public String Category;
	public List<String> CategoryList;
	public String Cost;
	public Boolean DescriptionEN;
	public Boolean DescriptionFR;
	public Boolean MFGNum;
	public String OtherCost;
	public String OtherPrice;
	public Boolean PartNum;
	public Boolean PkgQty;
	public String Price;
	public Boolean ReplacedBy;
	public Boolean Replaces;
	public Boolean SKUNum;
	public String VendorMasterType;
	
	public String VendorName;
	public String VendorMasterUID;
	public Boolean IsUpdateAvailable;
	public String Status;
	public String LastImportedDate;
	public String BlackpurlVendorName;
	public Id BlackpurlVendorId;
	public String BlackpurlVendorNumber;
	public String PartnerVendorMasterName;
	public String AccessKeyID;
	public String SecretAccessKey;
	public String PriceFileBucketName;
	public String Region;
	public String PriceFileLocation;
    public String CurrencyCode;
	public String FormattedFXCurrencyCode;
	public String Flag;
    public Boolean IsForeignVendor;
    public Decimal ConversionRate;
    public String PFImportStatus;

	public VendorMasterWrapper(Vendor_Master__c vendorMasterRec, String identifier) {
		if(String.isBlank(identifier)) {
			this.Category = vendorMasterRec.Category__c;
			this.CategoryList = String.isBlank(vendorMasterRec.Category__c) ? new List<String>() : (vendorMasterRec.Category__c).split(',');
			this.Cost = vendorMasterRec.Cost_New__c;
			this.PartnerVendorMasterName = vendorMasterRec.Partner_Vendor_Master_Identifier__c;
			this.DescriptionEN = vendorMasterRec.Description_EN__c;
			this.DescriptionFR = vendorMasterRec.Description_FR__c;
			this.MFGNum = vendorMasterRec.Mfg_Num__c;
			this.OtherCost = vendorMasterRec.Other_Cost_New__c;
			this.OtherPrice = vendorMasterRec.Other_Price_New__c;
			this.PartNum = vendorMasterRec.Part_Num__c;
			this.PkgQty = vendorMasterRec.Pkg_Qty__c;
			this.Price = vendorMasterRec.Price_New__c;
			this.ReplacedBy = vendorMasterRec.Replaced_By__c;
			this.Replaces = vendorMasterRec.Replaces__c;
			this.SKUNum = vendorMasterRec.SKU_Num__c;
			this.BlackpurlVendorName = vendorMasterRec.Blackpurl_Vendor__r.Name;
			this.BlackpurlVendorNumber = vendorMasterRec.Blackpurl_Vendor__r.Vendor_Number__c;
			this.VendorName = vendorMasterRec.Vendor_Name__c;
			this.VendorMasterUID = vendorMasterRec.Partner_Vendor_Master_Identifier__c;
			this.IsUpdateAvailable = vendorMasterRec.Is_Update_Available__c;
			this.BlackpurlVendorId = vendorMasterRec.Blackpurl_Vendor__c;
			this.PriceFileLocation = vendorMasterRec.Price_File_Location_URL__c;
			this.VendorMasterType = vendorMasterRec.Vendor_Master_Type__c;
			this.IsForeignVendor = vendorMasterRec.Blackpurl_Vendor__r.Is_Foreign_Vendor__c;
			if(vendorMasterRec.Blackpurl_Vendor__c != null && this.IsForeignVendor && vendorMasterRec.Blackpurl_Vendor__r.Country__c != null) {
				this.CurrencyCode = vendorMasterRec.Blackpurl_Vendor__r.Country__r.Currency_Code__c;
				this.ConversionRate = XeroUtility.isXeroEnabled() ? vendorMasterRec.Blackpurl_Vendor__r.Country__r.Backward_Conversion_Rate__c : vendorMasterRec.Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c;
				this.Flag = vendorMasterRec.Blackpurl_Vendor__r.Country__r.Flag_Encoded__c;
				this.FormattedFXCurrencyCode = vendorMasterRec.Blackpurl_Vendor__r.Country__r.Formatted_FX_Currency_Code__c;
			}
		} else if (identifier == 'Automated Price Files Screen') {
			this.VendorMasterId = vendorMasterRec.Id;
			this.VendorName = vendorMasterRec.Vendor_Name__c;
			this.LastImportedDate = vendorMasterRec.Last_Imported_Date__c != Null ? DateTimeUtility.getFormttedDateFromDateTime(vendorMasterRec.Last_Imported_Date__c, 'dd/MM/yyyy') : '';
			this.BlackpurlVendorName = vendorMasterRec.Blackpurl_Vendor__r.Name;
			this.BlackpurlVendorNumber = vendorMasterRec.Blackpurl_Vendor__r.Vendor_Number__c;
			this.PFImportStatus = vendorMasterRec.Price_File_Import_Status__c;
			if(vendorMasterRec.Vendor_Master_Type__c == 'BRP Parts Master') {
				this.LastImportedDate =  BRP_Settings__c.getOrgDefaults().Parts_Master_Successful_Imported_Date__c != null ? DateTimeUtility.getFormttedDateFromDateTime(BRP_Settings__c.getOrgDefaults().Parts_Master_Successful_Imported_Date__c, 'dd/MM/yyyy') : '';
				this.Status = 'Automatic';
			} else if(vendorMasterRec.Is_Update_Available__c) {
				this.Status = 'Update available';
			} else if(String.isNotBlank(this.LastImportedDate) && !vendorMasterRec.Is_Update_Available__c) {
				this.Status = 'Up to date';
			} else if(String.isBlank(this.LastImportedDate)) {
				this.Status = 'Never imported';
			}
		}
	}
	
	public static List<String> getFieldList() {
		return new List<String> {'Id',
			'Category__c',
			'Cost_New__c',
			'Description_EN__c',
			'Description_FR__c',
			'Mfg_Num__c',
			'Other_Cost_New__c',
			'Other_Price_New__c',
			'Part_Num__c',
			'Pkg_Qty__c',
			'Price_New__c',
			'Replaces__c',
			'Replaced_By__c',
			'SKU_Num__c',
			'Vendor_Name__c',
			'Partner_Vendor_Master_Identifier__c',
			'Price_File_Import_Status__c',
			'Blackpurl_Vendor__r.Vendor_Number__c',
			'Blackpurl_Vendor__r.Name',
			'Blackpurl_Vendor__r.Country__r.Flag_Encoded__c',
			'Blackpurl_Vendor__r.Country__r.Currency_Code__c',
			'Blackpurl_Vendor__r.Is_Foreign_Vendor__c',
			'Blackpurl_Vendor__r.Country__r.Conversion_Rate_With_Markup__c',
			'Blackpurl_Vendor__r.Country__r.Backward_Conversion_Rate__c',
			'Blackpurl_Vendor__r.Country__r.Formatted_FX_Currency_Code__c',
			'Is_Update_Available__c',
			'Blackpurl_Vendor__c',
			'Price_File_Location_URL__c',
			'Vendor_Master_Type__c'
		};
	}
}
/**
 * Author: Ashish Garg
 * Since: Aug 8, 2015
 * Name: VORHeader
 * Description: Apex class to handle all operations related to Vendor Order Receiving Header record.
**/
public without sharing class VORHeader {
	public String VORId;
	public String VORName;
	
	public String VendorId;
    public String VendorName;
    
    public String OwnerId;
    public String OwnerName;
    
    public Boolean IsReceivingFromInvoice;
    public Decimal ReceivingFromInvoiceTotal;
    
    public String Status;
	public String PackagingSlipNumber;
	public Decimal ReceivingTotal;
	public Decimal TotalReceivedQty;
	public Decimal TotalLineItem;

	public Boolean IsForeignVendor;
    public ForeignExchangeUtil.CurrencyWrapper FXCurrencyDetails;
  	
    public String CreatedDate;
	public String LastModifiedDate;
	public String CreatedBy;
	public String LastModifiedBy;
	public String FinalizedDate;

	// pricing related vendor fields
	public Boolean IsCalculatePartRetailPriceFlag;
	public String RetailBaseValue;
	public Decimal RetailRate;
	public Boolean RetailRounding;
	public Decimal RetailRoundTo;
	
	/**
     * Name: VORHeader
     * Desc: Constructor
     * @param:  (1) vorId - String - Vendor Order Receiving Id
     * @return: 
    **/
	public VORHeader(Vendor_Receiving_Header__c vorRecord){
		this.VORId = vorRecord.Id;
		this.VORName = vorRecord.Name;
		this.VendorId = vorRecord.Vendor__c;
		this.VendorName = vorRecord.Vendor__r.Name;
		this.OwnerId = vorRecord.Owner__c;
		this.OwnerName = vorRecord.Owner__r.Name;
		this.IsReceivingFromInvoice = false;
		this.IsReceivingFromInvoice = vorRecord.Is_Receiving_From_Invoice__c;
		this.ReceivingFromInvoiceTotal = vorRecord.Receiving_From_Invoice_Total__c;
		this.Status = vorRecord.Status__c;
		this.PackagingSlipNumber = vorRecord.Packing_Slip_Number__c;
		this.ReceivingTotal = vorRecord.Receiving_Total__c;
		this.TotalReceivedQty = vorRecord.Total_Received_Qty__c != null ? vorRecord.Total_Received_Qty__c.setScale(2, RoundingMode.HALF_UP) : 0;
		this.TotalLineItem = vorRecord.Total_Line_Item__c;
		this.IsForeignVendor = vorRecord.Vendor__r.Is_Foreign_Vendor__c;
        if(this.IsForeignVendor && vorRecord.Vendor__r.Country__c != null) {
            this.FXCurrencyDetails = new ForeignExchangeUtil.CurrencyWrapper(vorRecord.Vendor__r.Country__r, true);
			this.FXCurrencyDetails.ConversionRateWithMarkup = this.Status != 'In Progress' ? (XeroUtility.isXeroEnabled() ? vorRecord.Finalized_VR_Backward_Conversion_Rate__c : vorRecord.Finalized_VR_Conversion_Rate__c) : (XeroUtility.isXeroEnabled() ? vorRecord.Vendor__r.Country__r.Backward_Conversion_Rate__c : vorRecord.Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
        }
        this.CreatedDate = BPUtility.getFormatedDateTime(vorRecord.CreatedDate);
		this.LastModifiedDate = BPUtility.getLastModifiedDateStr(vorRecord);
		this.CreatedBy = vorRecord.CreatedBy.Name != null ? vorRecord.CreatedBy.Name : '';
		this.LastModifiedBy = BPUtility.getLastModifiedBy(vorRecord);
		this.FinalizedDate = vorRecord.Finalized_Date__c != null ? BPUtility.getFormatedDateTime(vorRecord.Finalized_Date__c) : '';
		this.IsCalculatePartRetailPriceFlag = vorRecord.Vendor__r.Is_Calculate_Part_Retail_Price__c;
		this.RetailBaseValue = vorRecord.Vendor__r.Retail_Base_Value__c != null ? vorRecord.Vendor__r.Retail_Base_Value__c : 'MSRP';
		this.RetailRate = vorRecord.Vendor__r.Retail_Rate__c != null ? vorRecord.Vendor__r.Retail_Rate__c : 0;
		this.RetailRounding = vorRecord.Vendor__r.Retail_Rounding__c;
		this.RetailRoundTo = vorRecord.Vendor__r.Retail_Round_To__c != null ? vorRecord.Vendor__r.Retail_Round_To__c : 0;
	}
	
	/**
     * Name: getVORDetails
     * Desc: Method to get Vendor Order Receiving record by Id value passed in arguments
     * @param:  (1) vorId - Id - VOR Id
     * @return: VORHeader - Class Object
    **/
	public static VORHeader getVORDetails(Id vorId){
		List<Vendor_Receiving_Header__c> vorHeaderRecords = SOQLUtil.getVORDetails('Id', vorId);
		if(vorHeaderRecords.size() > 0){
			return new VORHeader(vorHeaderRecords[0]);
		}
		return null;
	}
	
	/**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: VORHeader - Class Object
    **/
    public static VORHeader parse(String json) {
        return (VORHeader) System.JSON.deserialize(json, VORHeader.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> vorHeaderFieldsList = new List<String>{'Id', 
        													'Vendor__c',
        													'Vendor__r.Name', 
        													'Status__c', 
        													'Owner__c',
        													'Owner__r.Name', 
        													'Name',
        													'Is_Receiving_From_Invoice__c',
        													'Packing_Slip_Number__c',
        													'Receiving_From_Invoice_Total__c',
        													'Receiving_Total__c',
															'Finalized_Date__c', // Addedby richa 07/02/2017
															'Total_Received_Qty__c',
															'Total_Line_Item__c',
															'Vendor__r.Country__r.Currency_Code__c',
															'Vendor__r.Country__r.Formatted_FX_Currency_Code__c',
															'Vendor__r.Country__r.Conversion_Rate_With_Markup__c', 
															'Vendor__r.Country__r.Backward_Conversion_Rate__c', 
															'Vendor__r.Is_Foreign_Vendor__c', 
															'Finalized_VR_Conversion_Rate__c',
                                                            'CreatedDate',
															'LastModifiedDate',
															'Last_Modified_Date__c',
															'CreatedBy.Name',
															'LastModifiedBy.Name',
															'Last_Modified_By__r.Name',
															'Finalized_VR_Backward_Conversion_Rate__c',
															'Vendor__r.Is_Calculate_Part_Retail_Price__c',
															'Vendor__r.Retail_Base_Value__c',
															'Vendor__r.Retail_Rate__c',
															'Vendor__r.Retail_Rounding__c',
															'Vendor__r.Retail_Round_To__c'
        												};
        return vorHeaderFieldsList;
    }
}
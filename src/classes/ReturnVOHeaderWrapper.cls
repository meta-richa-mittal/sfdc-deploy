public without sharing class ReturnVOHeaderWrapper {
   
	public String Id {get;private set;}
	public String Name {get;private set;}
	public String VendorId {get;private set;}
	public String VendorName {get;private set;}
	public String Status {get;private set;}
	public String ReturnedDate {get;private set;}
	public String CreatedDate {get;private set;}
	public String SubmittedDate {get;private set;}
	public String ApprovedDate {get;private set;}
	public String LastModifiedDate {get;private set;}
	public String RMANumber {get;private set;}
	public String Reason {get;private set;}
	public String TrackingNumber {get;private set;}
	public String Notes {get;private set;}
	public Decimal SubTotal {get;private set;}
	public Decimal Tax {get;private set;}
	public Decimal Total {get;private set;}
	public String OwnerName {get;private set;}
	public String LastModifiedBy {get;private set;}
	public String SubmittedBy {get;private set;}
	public String ApprovedBy {get;private set;}
	public Boolean IsForeignVendor;
	public ForeignExchangeUtil.CurrencyWrapper FXCurrencyDetails;
	public List<ReturnVoLineItemWrapper> ReturnVOLIList {get;private set;}
	public String RCRSelectedValue;
	
	public ReturnVOHeaderWrapper(Return_VO_Header__c returnVOHeaderRec, String returnCRId) {
		this.setFields(returnVOHeaderRec, returnCRId);
	}
	 
	public ReturnVOHeaderWrapper(Return_VO_Header__c returnVOHeaderRec) {
		this.setFields(returnVOHeaderRec, null);
	} 
	 
	private void setFields(Return_VO_Header__c returnVOHeaderRec, String returnCRId) {
		this.Id = returnVOHeaderRec.Id;
		this.Name = returnVOHeaderRec.Name;
		this.Status = returnVOHeaderRec.Status__c;
		this.RMANumber = returnVOHeaderRec.RMA__c ;
		this.Reason = returnVOHeaderRec.Reason__c;
		if(returnCRId != null) {
			Integer rvoliCountOnCR = 0;
			Integer rvoliCountOnOther = 0;
			for(Return_VO_Line_Item__c rvoliRec: returnVOHeaderRec.Return_VO_Line_Items__r) {
				if(rvoliRec.Return_CR_Line_Item__c != null) {
					if(rvoliRec.Return_CR_Line_Item__r.Return_CR_Header__c == returnCRId) {
						rvoliCountOnCR++;
					} else {
						rvoliCountOnOther++;
					}
				}
			}
			if(rvoliCountOnCR == 0) {
				this.RCRSelectedValue = 'None';
				if(rvoliCountOnOther == returnVOHeaderRec.Return_VO_Line_Items__r.size()) {
					this.RCRSelectedValue = 'Disable';
				}
			} else if(rvoliCountOnCR == returnVOHeaderRec.Return_VO_Line_Items__r.size()) {
				this.RCRSelectedValue = 'All';
			} else {
				this.RCRSelectedValue = 'Partial';
			}
		} else {
			this.VendorId = returnVOHeaderRec.Vendor__c != null ? returnVOHeaderRec.Vendor__c : '';
			this.VendorName = returnVOHeaderRec.Vendor__r.Name != null ? returnVOHeaderRec.Vendor__r.Name : '';
			this.ReturnedDate = returnVOHeaderRec.Returned_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(returnVOHeaderRec.Returned_Date__c.year(), returnVOHeaderRec.Returned_Date__c.month(), returnVOHeaderRec.Returned_Date__c.day())) : BPUtility.getFormatedDateTime(System.Now());
			this.SubmittedDate = returnVOHeaderRec.Submitted_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(returnVOHeaderRec.Submitted_Date__c.year(), returnVOHeaderRec.Submitted_Date__c.month(), returnVOHeaderRec.Submitted_Date__c.day())) : '';
			this.CreatedDate = returnVOHeaderRec.CreatedDate != null ? BPUtility.getFormatedDateTime(returnVOHeaderRec.CreatedDate) : '';
			this.ApprovedDate = returnVOHeaderRec.Approved_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(returnVOHeaderRec.Approved_Date__c.year(), returnVOHeaderRec.Approved_Date__c.month(), returnVOHeaderRec.Approved_Date__c.day())) : '';
			this.LastModifiedDate = returnVOHeaderRec.LastModifiedDate != null ? BPUtility.getFormatedDateTime(returnVOHeaderRec.LastModifiedDate) : '';
			this.TrackingNumber = returnVOHeaderRec.Tracking_Number__c;
			this.Notes = returnVOHeaderRec.Notes__c;
			this.SubTotal = returnVOHeaderRec.SubTotal__c != null ? returnVOHeaderRec.SubTotal__c : 0;
			this.Tax = returnVOHeaderRec.Tax__c != null ? returnVOHeaderRec.Tax__c : 0;
			this.Total = returnVOHeaderRec.Return_Total__c != null ? returnVOHeaderRec.Return_Total__c : 0;
			this.OwnerName = returnVOHeaderRec.owner.name;
			this.SubmittedBy = returnVOHeaderRec.Submitted_By__r.name;
			this.ApprovedBy = returnVOHeaderRec.Approved_By__r.name;
			this.LastModifiedBy = returnVOHeaderRec.LastModifiedBy.name;
			this.IsForeignVendor = returnVOHeaderRec.Vendor__r.Is_Foreign_Vendor__c;
			if(returnVOHeaderRec.Vendor__r.Is_Foreign_Vendor__c) {
				this.FXCurrencyDetails = new ForeignExchangeUtil.CurrencyWrapper(returnVOHeaderRec.Vendor__r.Country__r, true);
				if(String.isNotBlank(returnVOHeaderRec.Status__c) && returnVOHeaderRec.Status__c.equalsIgnoreCase('Credited')) {
					this.FXCurrencyDetails.ConversionRateWithMarkup = XeroUtility.isXeroEnabled() ? returnVOHeaderRec.Backward_Conversion_Rate__c : returnVOHeaderRec.FX_Conversion_Rate__c;
				}
			}
			this.ReturnVOLIList = new List<ReturnVoLineItemWrapper>();
			
			for(Return_VO_Line_Item__c returnVOLineItemRec  : returnVOHeaderRec.Return_VO_Line_Items__r){
				this.ReturnVOLIList.add(new ReturnVoLineItemWrapper(returnVOLineItemRec, null));
			}
		}
	}
	 
	 
	 
	public class ReturnVoLineItemWrapper {
	
		public String Id {get;private set;}
		public String Name {get;private set;}
		public String Item {get;private set;}
		public String Description {get;private set;}
		public String ItemDescription {get;private set;}
		public Decimal ReturnQty {get;private set;}
		public Decimal ItemCost {get;private set;}
		public Decimal InventoryCost {get;private set;}
		public String ReturnVOId {get;private set;}
		public String PartId {get;private set;}
		public Decimal partAvailableQty {get;private set;}
		public String UnitType{get; private set;}
		public String RCRLineItemId;
		public Boolean IsSelected;
		public String CreditStatus;

		public ReturnVoLineItemWrapper(Return_VO_Line_Item__c returnVOLIRec, String returnCRId) {
			this.setLIFields(returnVOLIRec, returnCRId);
		}

		private void setLIFields(Return_VO_Line_Item__c returnVOLIRec, String returnCRId) {
			this.Id = returnVOLIRec.Id;
			this.Name = returnVOLIRec.Name;
			this.ItemDescription = returnVOLIRec.Item_Desc__c;
			this.ReturnQty = returnVOLIRec.Return_Qty__c != null ? returnVOLIRec.Return_Qty__c : 0;
			this.RCRLineItemId = returnVOLIRec.Return_CR_Line_Item__c;
			if(returnCRId != null) {
				this.IsSelected = (returnCRId == returnVOLIRec.Return_CR_Line_Item__r.Return_CR_Header__c);
			} else {
				this.Item = returnVOLIRec.Item__c;
				this.Description = returnVOLIRec.Description__c;
				this.ItemCost = returnVOLIRec.Item_Cost__c != null ? returnVOLIRec.Item_Cost__c : 0;
				this.InventoryCost = returnVOLIRec.Inventory_Cost__c != null ? returnVOLIRec.Inventory_Cost__c : 0;
				this.ReturnVOID = returnVOLIRec.Return_VO_Header__c ;
				this.PartId = returnVOLIRec.Part__c ;
				this.partAvailableQty = returnVOLIRec.Part__c != null ? returnVOLIRec.Part__r.Qty_In_Stock__c : 0;
				this.UnitType = 'EA';
				if(String.isBlank(returnVOLIRec.Part__r.Package_Unit__c) && returnVOLIRec.Part__r.Packaged_Part__c) {
					this.UnitType = 'PKG';
				} else {
					this.UnitType = returnVOLIRec.Part__r.Package_Unit__c;
				}
				this.CreditStatus = returnVOLIRec.Credit_Status__c;
			}
		}
	}

	public class ReturnCreditHistoryWrapper {
		public String Id;
		public String CreditMemoNumber;
		public String CreditedDate;
		public Integer LineItemCount;
		public Decimal PreTaxCreditTotal;
		public String CreatedBy;
		public String Status;

		public ReturnCreditHistoryWrapper(Return_CR_Header__c returnCRHeaderRec) {
			this.Id = returnCRHeaderRec.Id;
			this.CreditMemoNumber = returnCRHeaderRec.Credit_Memo__c != null ? returnCRHeaderRec.Credit_Memo__c : returnCRHeaderRec.Name;
			this.CreditedDate = returnCRHeaderRec.Credited_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(returnCRHeaderRec.Credited_Date__c.year(), 
				returnCRHeaderRec.Credited_Date__c.month(), returnCRHeaderRec.Credited_Date__c.day())) : BPUtility.getFormatedDateTime(System.Now());
			this.LineItemCount = returnCRHeaderRec.Return_CR_Line_Items__r.size();
			this.PreTaxCreditTotal = (returnCRHeaderRec.Item_Total__c != null ? returnCRHeaderRec.Item_Total__c : 0) + 
										(returnCRHeaderRec.Other_Charges_Total__c != null ? returnCRHeaderRec.Other_Charges_Total__c : 0);
			this.CreatedBy = returnCRHeaderRec.Owner.Name;
			this.Status = returnCRHeaderRec.Status__c;
		}

	}
	 
	 public static List<String> getReturnVOFieldList(){
		 List<String> returnVOFields = new List<String>{ 
													 'Id',
													 'Name',
													 'Vendor__c',
													 'Vendor__r.Name',
													 'Status__c',
													 'CreatedDate',
													 'Returned_Date__c',
													 'Submitted_Date__c',
													 'Approved_Date__c',
													 'LastModifiedDate',
													 'RMA__c',
													 'Reason__c',
													 'Tracking_Number__c',
													 'Notes__c',
													 'SubTotal__c',
													 'Tax__c',
													 'Return_Total__c',
													 'Owner.name',
													 'Submitted_By__r.Name',
													 'Approved_By__r.Name',
													 'LastModifiedBy.Name',
													 'Total__c',
													 'FX_Conversion_Rate__c',
													 'Backward_Conversion_Rate__c',
													 'Vendor__r.Is_Foreign_Vendor__c',
													 'Vendor__r.Country__r.Conversion_Rate_With_Markup__c',
													 'Vendor__r.Country__r.Backward_Conversion_Rate__c',
													 'Vendor__r.Country__r.Currency_Code__c',
													 'Vendor__r.Country__r.Formatted_FX_Currency_Code__c'
		 };
		 return returnVOFields;
	 }
	 
	 
	 public static List<String> getReturnVOLIFieldList(){
		 List<String> returnVOLIFields = new List<String>{ 
													 'Id',
													 'Name',
													 'Item__c',
													 'Description__c',
													 'Item_Desc__c',
													 'Return_Qty__c',
													 'Item_Cost__c',
													 'Inventory_Cost__c',
													 'Return_VO_Header__c',
													 'Part__c',
													 'Part__r.Qty_In_Stock__c',
													 'Part__r.Package_Unit__c',
													 'Part__r.Packaged_Part__c',
													 'Return_CR_Line_Item__r.Return_CR_Header__c',
													 'Credit_Status__c'
		 };
		 
		 return returnVOLIFields;
	 }
 }
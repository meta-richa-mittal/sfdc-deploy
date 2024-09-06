public without sharing class UnitOrderingWrapper {
 	
 	public class VendorWrapper{
 		public String VendorName;
 		public String VendorId;
 		public Integer UnitCount;
 		public Boolean IsBRPVendor;
 		public Decimal LeadTime;
		public String VendorPurchasetaxId;
 		
 		public VendorWrapper(){}
 		public VendorWrapper(Account acc){
 			setVendorFields(acc);
 		}
 		
 		public VendorWrapper(Account acc, PO_Type__c poTypeRec){
 			setVendorFields(acc);
 			this.LeadTime = poTypeRec != null ? poTypeRec.Lead_Time__c : 0;
 		}
 		
 		private void setVendorFields(Account acc) {
 			this.VendorId = acc.Id;
 			this.VendorName = acc.Name;
 			if(acc.Customer_Owned_Units1__r != null){
 				this.UnitCount = acc.Customer_Owned_Units1__r.size();
 			}
 			this.IsBRPVendor = BRPUtility.getAllBRPVendorsIdSet().contains(this.VendorId);
			this.VendorPurchasetaxId = acc.Purchase_Tax__c;
 		}
 		
 		public List<VendorWrapper> convertToWrapperList(List<Account> vendorsList){
 			List<VendorWrapper> vendorList = new List<VendorWrapper>();
	    	for(Account acc : vendorsList){
	    		vendorList.add(new VendorWrapper(acc));
	    	}
	    	return vendorList;
 		}
 	}   
 	
 	public class UnitOrderWrapper{
 		public String UnitId;
 		public String UnitNumber;
        public String StockNumber;
        public String VIN;
 		public Decimal Year;
 		public String Make;
 		public String Model;
 		public String ModelName;
 		public String FactoryOrder;
 		public String Status;
 		public String CreatedDate;
 		public String ExpectedDate;
 		public String OrderedDate;
        public String StockedInDateTime;
 		public Decimal TotalCost;
        public Decimal SalesTax;
        public Decimal TotalWithTax;
        public String InvoiceNumber;
        public String DealItemId;
        public String CoNumber;
        public String MakeName;
        public String MakeId;
        public String ModelId;
        public String SubModelName;
        public String SubModelId;
        public Decimal Cylinders;
        public String ComplianceDate;
	    public String YearOf1stRego;
	    public String RegistrationSerial;
		public Decimal TotalTaxAmount;
		public Decimal TotalWithTaxBeforeOverridding;

 		public UnitOrderWrapper(){}
 		public UnitOrderWrapper(Customer_Owned_Unit__c unit){
 			this.UnitId = unit.Id;
 			this.UnitNumber = unit.Unit_Number__c;
            this.StockNumber = unit.Stock_Id__c;
            this.VIN = String.isNotBlank(unit.VIN_Number__c) && unit.VIN_Number__c != 'VIN Unknown' ? unit.VIN_Number__c : '';
 			this.Year = unit.Year__c;
 			this.Make = unit.Make_Name__c	;
 			this.MakeName = unit.Make_Name__c;
            this.Model = unit.Model_Detail__c;
 			this.ModelName = (unit.Unit_Model__c != null) ? unit.Unit_Model__r.Name__c : '';
 			this.SubModelName = (unit.Sub_Model__c != null) ? unit.Sub_Model__r.Sub_Model_Name__c : '';
 			this.FactoryOrder = unit.Factory_Order_No__c == null ? '- - - - - - - - -' : unit.Factory_Order_No__c ;
 			this.Status = unit.Status__c;
 			this.ExpectedDate = (unit.Date_Expected__c != null) ? 
								BPUtility.getFormatedDateTime(datetime.newInstance(unit.Date_Expected__c.year(), unit.Date_Expected__c.month(), unit.Date_Expected__c.day())) : '' ;
 			this.OrderedDate = (unit.Date_Ordered__c != null) ? 
								BPUtility.getFormatedDateTime(datetime.newInstance(unit.Date_Ordered__c.year(), unit.Date_Ordered__c.month(), unit.Date_Ordered__c.day())) : '' ;
			this.CreatedDate = (unit.CreatedDate != null) ? 
								BPUtility.getFormatedDateTime(datetime.newInstance(unit.CreatedDate.year(), unit.CreatedDate.month(), unit.CreatedDate.day())) : '' ;
            this.StockedInDateTime = (unit.Stocked_In_DateTime__c != null) ? 
                                BPUtility.getFormatedDateTime(datetime.newInstance(unit.Stocked_In_DateTime__c.year(), unit.Stocked_In_DateTime__c.month(), unit.Stocked_In_DateTime__c.day())) : '' ;
            this.TotalCost = ((unit.Total_Cost__c != null) ? unit.Total_Cost__c : 0);
            this.SalesTax = unit.Unit_Purchase_Tax__c != null ? unit.Unit_Purchase_Tax__r.Rate__c : unit.Vendor__r.Purchase_Tax__r.Rate__c;
            this.TotalTaxAmount = (unit.Tax_Amount__c != null ? unit.Tax_Amount__c : 0);
			this.TotalWithTax = unit.Overridden_Total_Cost_With_Tax__c != null ? unit.Overridden_Total_Cost_With_Tax__c.setScale(2, RoundingMode.HALF_UP)  : (this.TotalCost + this.TotalTaxAmount).setScale(2, RoundingMode.HALF_UP);
            this.InvoiceNumber = unit.Invoice_Number__c;
            this.DealItemId = unit.Deals_Units_Junction__r.size() > 0 ? unit.Deals_Units_Junction__r[0].Id: null;
            this.CoNumber = unit.Deals_Units_Junction__r.size() > 0 ? (unit.Deals_Units_Junction__r != null ? unit.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Name : null) : null;
            this.Cylinders = unit.Cylinders__c;
	    	this.ComplianceDate = unit.Compliance_Date__c;
	    	this.RegistrationSerial = unit.Registration_Serial__c;
	    	this.YearOf1stRego = unit.Year_Of_1st_Rego__c;
			this.TotalWithTaxBeforeOverridding = this.TotalWithTax;
 		}
 		
 		public List<UnitOrderWrapper> convertToWrapperList(List<Customer_Owned_Unit__c> couList){
 			List<UnitOrderWrapper> unitList = new List<UnitOrderWrapper>();
	    	for(Customer_Owned_Unit__c unit : couList){
	    		unitList.add(new UnitOrderWrapper(unit));
	    	}
	    	return unitList;
 		}
 	}
 	
 	public class UnitDetailsWrapper{
 		public UnitWrapper.UnitInfoWrapper UnitInfo;
		public List<UnitWrapper.PriceAndCostTrackingWrapper> PriceAndCostTrackingWrapperList;
		
		public UnitDetailsWrapper(Customer_Owned_Unit__c unitRec){
			this.UnitInfo = new UnitWrapper.UnitInfoWrapper(unitRec);
			this.PriceAndCostTrackingWrapperList = new List<UnitWrapper.PriceAndCostTrackingWrapper>();
			for(Unit_Price_Cost__c unitPriceAndCostRec : unitRec.Unit_Prices_Costs__r){
				this.PriceAndCostTrackingWrapperList.add(new UnitWrapper.PriceAndCostTrackingWrapper(unitPriceAndCostRec));
	    	}
		}
 	}
    
    public class SortingAttrs {
        
        public String FieldLabel;
        public String SortingOrder;
    }
    
	public class PurchaseTaxWrapper {
        
        public String Id;
        public String Name;
		public Boolean IsSelected;

		public PurchaseTaxWrapper(Sales_Tax__c purchaseTax, Boolean isSelected) {
			this.Id = purchaseTax.Id;
			this.Name = purchaseTax.Name__c;
			this.IsSelected = isSelected;
		}

    }
    
    public static Map<String, String> fieldLabelToFieldAPINameMap = new Map<String, String> {
                                                                          'UnitNumber' => 'Unit_Number__c',
                                                                          'Make' => 'Make_Name__c',
                                                                          'Year' => 'Year__c',
                                                                          'Model' => 'Model_Detail__c',
                                                                          'FactoryOrder' => 'Factory_Order_No__c',
                                                                          'CreatedDate' => 'CreatedDate',
                                                                          'StockedInDateTime' => 'Stocked_In_DateTime__c',
                                                                          'TotalCost' => 'Total_Cost__c',
                                                                          'Status' => 'Status__c',
                                                                          'Ordered Date' => 'Date_Ordered__c',
                                                                          'ExpectedDate' => 'Date_Expected__c'
              };
}
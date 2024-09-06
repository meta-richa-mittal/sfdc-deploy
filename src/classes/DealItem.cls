/**
 * Author: Nidhi Sharma
 * Since: September 01, 2016
 * Name: DealItem
 * Description: Wrapper class to handle JSON variables for Deal Item
**/

public class DealItem { 
    
    public String Id;
    public String UnitId;
    public String Deal;
    public String Make;
    public String MakeName;
    public String Model;
    public String ModelName;
    public String SubModel;
    public String SubModelName;
    public String MakeModelDescription;
    public Decimal Year;
    public String ExteriorColour;
    public String VIN;
    public String UnitType;
    public String UnitNumber;
    public String StockNumber;
    public String FormattedName;
    public String Status;
    public String StatusColor;
    public String REGO;
    public String RegExpiryDate;
    public String EngineNumber;
    public Decimal EngineSize;
    public Boolean Taxable;
    public String ApplicableTaxId;
    public String ApplicableTaxName;
    public String InteriorColor;
    public String ComplianceDate;
    public String RegistrationSerial;
    public String ManufacturedDate;
    public String YearFirstRego;
    public String MileageType;
    
    //Trade In field
    public String Type;
    public Decimal AgreedValue {get; set;}
    public Decimal ActualCashValue {get; set;}
    public String ApprovedBy;
    public String ApprovedByName;
    public String AppraisalMethod;
    public String AppraisalNotes;
    public String AppraisalStatus;
    public String OptionAndFeeStatus;
    public Decimal Mileage;
    public Decimal SalesTaxPercentage;
    public Decimal SalesTax;
    public Boolean IsSctockedIn;
    public String TradeInUnitStockNumber;
    public Decimal TradeInMileageValue;
    public Decimal LienPayout;
    public String FinanceCompanyId;
    public String FinanceCompanyName;
    public String DateStockedIn;
    public String TradeInUnitStockedIn;
    public String OtherSerialNo;
    public String KeyNo;
    public String TradeInMileageType;
    public Map<String, List<FeeExemptWrapper>> TagNameToFeeExemptListMap = new Map<String, List<FeeExemptWrapper>>();
    
    public String CategoryId;
    public String CategoryName;
    public Boolean IsAutomatic;
    public String Notes;

	// Constructor
	public DealItem() {}
	
    public DealItem(Deal_Item__c dealItem) {
        this.Id = dealItem.Id;
        this.UnitId = dealItem.Customer_Owned_Unit__c;
        this.Deal = dealItem.Deal__c;
        this.Type = dealItem.Type__c; 
        this.ApprovedBy = dealItem.Approved_By__c;
        this.ApprovedByName = (dealItem.Approved_By__c == null) ? 'Pending approval' : dealItem.Approved_By__r.Name;
        this.AppraisalMethod = dealItem.Appraisal_Method__c;
        this.AppraisalNotes = dealItem.Appraisal_Notes__c;
        this.AppraisalStatus = (dealItem.Appraisal_Status__c == null) ? 'Pending appraisal' : dealItem.Appraisal_Status__c;
        
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        this.AgreedValue = (dealItem.Agreed_Value__c != null) ? dealItem.Agreed_Value__c : 0;
        this.SalesTaxPercentage = (dealItem.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItem.Default_Unit_Sales_Tax_Percentage__c : 0;
        this.ActualCashValue = dealItem.Actual_Cash_Value__c != null ? dealItem.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.TradeInUnitStockNumber = dealItem.Stocked_In_Unit__r.Stock_Id__c != null ? dealItem.Stocked_In_Unit__r.Stock_Id__c : '';
        
        this.TradeInUnitStockedIn = (dealItem.Stocked_In_Unit__r.Date_Stocked_In__c != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(dealItem.Stocked_In_Unit__r.Date_Stocked_In__c.year(), dealItem.Stocked_In_Unit__r.Date_Stocked_In__c.month(),dealItem.Stocked_In_Unit__r.Date_Stocked_In__c.day())): '';
        this.TradeInMileageValue = dealItem.Customer_Owned_Unit__r.Mileage_Value__c;
        this.TradeInMileageType = dealItem.Customer_Owned_Unit__r.Mileage_Type__c;
        this.LienPayout = dealItem.Lien_Payout__c != null ? dealItem.Lien_Payout__c : 0;
        this.FinanceCompanyId = dealItem.Finance_Company__c;
        this.FinanceCompanyName = dealItem.Finance_Company__r.Name;
        if(isTaxIncludingPricing) {
            this.SalesTax = this.AgreedValue - (this.AgreedValue / (1 + (this.SalesTaxPercentage / 100)));
		} else {
			this.SalesTax = ((this.AgreedValue * this.SalesTaxPercentage)/100).setScale(2, RoundingMode.HALF_UP);
		}

        this.Taxable = dealItem.Taxable__c;
        this.ApplicableTaxId = dealItem.Applicable_Tax__c;
        this.ApplicableTaxName = dealItem.Applicable_Tax__c != null ? dealItem.Applicable_Tax__r.Name__c : '';
        
    	if(dealItem.Customer_Owned_Unit__c == null){
    		this.Make = dealItem.Unit_Make__c;
	    	this.MakeName = (dealItem.Unit_Make__c != null) ? dealItem.Unit_Make__r.Name : '';
	    	
	    	if(dealItem.Unit_Model__c != null) {
	    		this.Model = dealItem.Unit_Model__c;
	    		this.ModelName = dealItem.Unit_Model__r.Name__c;
	    	} 
	    	if(dealItem.Sub_Model__c != null) {
	    		this.SubModel = dealItem.Sub_Model__c;
	    		this.SubModelName = dealItem.Sub_Model__r.Sub_Model_Name__c;
	    	}
	    	
	    	this.MakeModelDescription = (dealItem.Sub_Model__c != null) ? dealItem.Sub_Model__r.Description__c : '';
           
	    	this.Year = dealItem.Year__c;
	    	this.ExteriorColour = dealItem.Colour__c;
	    	this.FormattedName = ((this.Year != null) ? String.valueOf(this.Year) + ', ' : '') + 
	    						 	((this.MakeName != null) ? this.MakeName + ' ' : '') + 
			                       	((this.ModelName != null) ? this.ModelName : '') + 
			                       	((this.SubModelName != null) ? ' ' + this.SubModelName : '') +
			                       	((this.ExteriorColour != null) ? ', ' + this.ExteriorColour : '');

            this.Notes = dealItem.Notes__c != null ? dealItem.Notes__c : '';
                                                   
    	} else {
    		this.Make = dealItem.Customer_Owned_Unit__r.Unit_Make__c;
		this.Make = dealItem.Customer_Owned_Unit__r.Unit_Make_Formula__c;
	    	this.MakeName = (dealItem.Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItem.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
	    	
	    	if(dealItem.Customer_Owned_Unit__r.Unit_Model__c != null) {
	    		this.Model = dealItem.Customer_Owned_Unit__r.Unit_Model__c;
	    		this.ModelName = dealItem.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
	    	} 
	    	if(dealItem.Customer_Owned_Unit__r.Sub_Model__c != null) {
	    		this.SubModel = dealItem.Customer_Owned_Unit__r.Sub_Model__c;
	    		this.SubModelName = dealItem.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
	    	}
	    	
	    	this.MakeModelDescription = (dealItem.Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItem.Customer_Owned_Unit__r.Sub_Model__r.Description__c : '';
	    	this.Year = dealItem.Customer_Owned_Unit__r.Year__c;
	    	this.ExteriorColour = dealItem.Customer_Owned_Unit__r.Colour__c;
	    	this.InteriorColor = dealItem.Customer_Owned_Unit__r.Interior_Colour__c;
	    	this.UnitType = (dealItem.Customer_Owned_Unit__r.Unit_Type__c != null) ? dealItem.Customer_Owned_Unit__r.Unit_Type__c : '';
	    	if(this.UnitType == 'STOCK') {
				if(dealItem.Customer_Owned_Unit__r.Status__c == 'Available') {
					this.StatusColor = 'Green';
				} else if(dealItem.Customer_Owned_Unit__r.Status__c == 'Reserved' || dealItem.Customer_Owned_Unit__r.Status__c == 'Sold'){
					this.StatusColor = 'Red';
				} else if(dealItem.Customer_Owned_Unit__r.Status__c == 'Traded' || dealItem.Customer_Owned_Unit__r.Status__c == 'Delivered'){
					this.StatusColor = 'Black';
				}
	    	} else if(this.UnitType == 'COU') {
	    		if(dealItem.Customer_Owned_Unit__r.Status__c == 'Active') {
	    			this.StatusColor = 'Green';
	    		} else if(dealItem.Customer_Owned_Unit__r.Status__c == 'Inactive'){
	    			this.StatusColor = 'Red';
	    		} else if(dealItem.Customer_Owned_Unit__r.Status__c == 'Transferred'){
	    			this.StatusColor = 'Black';
	    		}
	    	} else if(this.UnitType == 'ORDU') {
	    		if(dealItem.Customer_Owned_Unit__r.Status__c == 'On Order') {
	    			this.StatusColor = 'Red';
	    		} else if(dealItem.Customer_Owned_Unit__r.Status__c == 'Cancelled' || dealItem.Customer_Owned_Unit__r.Status__c == 'Traded'){
	    			this.StatusColor = 'Black';
	    		}
	  		}
	  		this.IsAutomatic = dealItem.Customer_Owned_Unit__r.Automatic__c;
	  		this.Status = dealItem.Customer_Owned_Unit__r.Status__c;
	  		this.VIN = (dealItem.Customer_Owned_Unit__r.VIN_Number__c == null) ? 'VIN Unknown' : dealItem.Customer_Owned_Unit__r.VIN_Number__c;
			this.UnitNumber = dealItem.Customer_Owned_Unit__r.Unit_Number__c;
			this.StockNumber = dealItem.Customer_Owned_Unit__r.Stock_Id__c;
			this.FormattedName = dealItem.Customer_Owned_Unit__r.Formatted_Name__c;
			this.OptionAndFeeStatus = dealItem.Option_And_Fee_Status__c;
			this.REGO = dealItem.Customer_Owned_Unit__r.Plate__c;
			this.RegExpiryDate = (dealItem.Customer_Owned_Unit__r.Reg_Expiry_Date__c!= null) ? BPUtility.getFormatedDateTime(datetime.newInstance(dealItem.Customer_Owned_Unit__r.Reg_Expiry_Date__c.year(), dealItem.Customer_Owned_Unit__r.Reg_Expiry_Date__c.month(),dealItem.Customer_Owned_Unit__r.Reg_Expiry_Date__c.day())): '';
			this.EngineNumber = dealItem.Customer_Owned_Unit__r.Engine_Serial_No__c;
			this.EngineSize = dealItem.Customer_Owned_Unit__r.Displacement__c;
			this.IsSctockedIn = dealItem.Is_Stocked_In__c;
			this.Mileage = dealItem.Customer_Owned_Unit__r.Mileage_Value__c;
			this.MileageType = dealItem.Customer_Owned_Unit__r.Mileage_Type__c;
			
			this.OtherSerialNo = dealItem.Customer_Owned_Unit__r.Other_Serial_No__c != null ? dealItem.Customer_Owned_Unit__r.Other_Serial_No__c : '';
			this.KeyNo = dealItem.Customer_Owned_Unit__r.Key_No__c != null ? dealItem.Customer_Owned_Unit__r.Key_No__c : '';
			
			this.ComplianceDate = (dealItem.Customer_Owned_Unit__r.Compliance_Date__c != null ) ? dealItem.Customer_Owned_Unit__r.Compliance_Date__c : '';
			this.RegistrationSerial = (dealItem.Customer_Owned_Unit__r.Registration_Serial__c != null ) ? dealItem.Customer_Owned_Unit__r.Registration_Serial__c : '';
	  		if(dealItem.Customer_Owned_Unit__r.Manufactured_Date__c != null){
    			this.ManufacturedDate =  BPUtility.getFormatedDateTime(datetime.newInstance(dealItem.Customer_Owned_Unit__r.Manufactured_Date__c.year(), dealItem.Customer_Owned_Unit__r.Manufactured_Date__c.month(), dealItem.Customer_Owned_Unit__r.Manufactured_Date__c.day()));
    		}
    		
    		this.DateStockedIn = (dealItem.Customer_Owned_Unit__r.Date_Stocked_In__c != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(dealItem.Customer_Owned_Unit__r.Date_Stocked_In__c.year(), dealItem.Customer_Owned_Unit__r.Date_Stocked_In__c.month(),dealItem.Customer_Owned_Unit__r.Date_Stocked_In__c.day())): '';
    		
    		this.YearFirstRego = (dealItem.Customer_Owned_Unit__r.Year_Of_1st_Rego__c != null) ? dealItem.Customer_Owned_Unit__r.Year_Of_1st_Rego__c : '';
            this.Notes = (dealItem.Customer_Owned_Unit__r.Notes__c  != null) ? dealItem.Customer_Owned_Unit__r.Notes__c : '';
	  	}
	  	
	  	if(String.isNotBlank(dealItem.Category__c)) {
        	this.CategoryId = dealItem.Category__c;
        	this.CategoryName = dealItem.Category__r.Name;
        }
        
        List<Exempt_Fee_On_Form__mdt> exemptFeeOnFormList = MetadataService.getAllExemptFeeOnFormList();
        if(exemptFeeOnFormList.size() > 0) {
            for(Exempt_Fee_On_Form__mdt exemptFeeOnFormRec : exemptFeeOnFormList) {
                List<FeeExemptWrapper> feeExemptWrapperList = new List<FeeExemptWrapper>();
                for(Option_Fee__c optionAndFeeRec : dealItem.Options_Fees__r) {
                    if(optionAndFeeRec.Fee__c != null && (isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, exemptFeeOnFormRec.Label) || isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, exemptFeeOnFormRec.Label))) {
                        feeExemptWrapperList.add(new FeeExemptWrapper(optionAndFeeRec));
                    }
                }
                if(feeExemptWrapperList.size() > 0) {
            	    TagNameToFeeExemptListMap.put((exemptFeeOnFormRec.Label).toUpperCase(), feeExemptWrapperList);
                 }
            }
        }
    }
    
    public Boolean isRequiredTagExistOnFee(String assignedTagStr, String exemptFeeTagLabel) {
        Boolean isRequiredTagExistOnFee = false;
        Set<String> assingedTagStrSet = new Set<String>();
        if(String.isNotBlank(assignedTagStr) && String.isNotBlank(exemptFeeTagLabel)){ 
            assingedTagStrSet.addAll(assignedTagStr.split(';'));
            if(assingedTagStrSet.contains(exemptFeeTagLabel)) {
                isRequiredTagExistOnFee = true;
            }
        }
        return isRequiredTagExistOnFee;
    }
    
    public class FeeExemptWrapper {
        public Decimal FeePrice;
        public Decimal PreTaxFeePrice;
            
        public FeeExemptWrapper(Option_Fee__c optionFeeRec) {
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                this.FeePrice = optionFeeRec.Price_When_Tax_Included__c != null ? (optionFeeRec.Price_When_Tax_Included__c * optionFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0;
                this.PreTaxFeePrice = optionFeeRec.Price__c != null ? (optionFeeRec.Price__c * optionFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0;
            }
        }
    }
    
    public class DealItemTaxDetailWrapper {
        public Boolean IsTaxable;
        public String ApplicableTaxId;
        public String Id;
        
        public DealItemTaxDetailWrapper() {
            
        }
    }
    
    public static DealItem parse(String json) {
        return (DealItem) System.JSON.deserialize(json, DealItem.class);
    }
    
    public static List<String> getDealItemFields(){
        List<String> dealItemFields = new List<String>{ 'Id',
                                                        'Deal__c', 
                                                        'Unit_Make__c',
                                                        'Unit_Make__r.Name',
                                                        'Unit_Model__c',
                                                        'Unit_Model__r.Name__c',
                                                        'Submodel__c',
                                                        'Sub_Model__c',
                                                        'Sub_Model__r.Sub_Model_Name__c',
                                                        'Sub_Model__r.Description__c',
                                                        'Unit_Model__r.Sub_Model__c',
                                                        'Unit_Model__r.Description__c',
                                                        'Year__c',
                                                        'Colour__c',
                                                        'Customer_Owned_Unit__c',
                                                        'Customer_Owned_Unit__r.Unit_Make__c',
                                                        'Customer_Owned_Unit__r.Unit_Make__r.Name',
                                                        'Customer_Owned_Unit__r.Unit_Model__c',
                                                        'Customer_Owned_Unit__r.Unit_Model__r.Name__c',
                                                        'Customer_Owned_Unit__r.Submodel__c',
                                                        'Customer_Owned_Unit__r.Submodel__r.Name__c',
                                                        'Customer_Owned_Unit__r.Sub_Model__c',
                                                        'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
                                                        'Customer_Owned_Unit__r.Sub_Model__r.Description__c',
                                                        'Customer_Owned_Unit__r.Colour__c',
                                                        'Customer_Owned_Unit__r.Year__c',
                                                        'Customer_Owned_Unit__r.Status__c',
                                                        'Customer_Owned_Unit__r.VIN_Number__c',
                                                        'Customer_Owned_Unit__r.Unit_Type__c',
                                                        'Customer_Owned_Unit__r.Unit_Number__c',
                                                        'Customer_Owned_Unit__r.Stock_Id__c',
                                                        'Customer_Owned_Unit__r.Formatted_Name__c',
                                                        'Customer_Owned_Unit__r.Unit_Model__r.Sub_Model__c',
                                                        'Customer_Owned_Unit__r.Mileage_Value__c',
                                                        'Customer_Owned_Unit__r.Mileage_Type__c',
                                                        'Customer_Owned_Unit__r.Notes__c',
                                                        'Customer_Owned_Unit__r.Plate__c',
                                                        'Customer_Owned_Unit__r.Reg_Expiry_Date__c',
                                                        'Customer_Owned_Unit__r.Engine_Serial_No__c',
                                                        'Customer_Owned_Unit__r.Displacement__c',
                                                        'Customer_Owned_Unit__r.Mileage__c',
                                                        'Customer_Owned_Unit__r.Other_Serial_No__c',
                                                        'Customer_Owned_Unit__r.Key_No__c',
                                                        'Customer_Owned_Unit__r.New_Unit__c',
                                                        'Type__c',
                                                        'Lien_Payout__c',
                                                        'Finance_Company__c',
                                                        'Finance_Company__r.Name',
                                                        'Agreed_Value__c',
                                                        'Actual_Cash_Value__c',
                                                        'Stocked_In_Unit__r.Stock_Id__c',
                                                        'Approved_By__c',
                                                        'Appraisal_Method__c',
                                                        'Appraisal_Notes__c',
                                                        'Appraisal_Status__c',
                                                        'Approved_By__r.Name',
                                                        'Option_And_Fee_Status__c',
                                                        'Default_Unit_Sales_Tax_Percentage__c',
                                                        'Stamp_Duty_Total__c',
                                                        'Is_Override_Stamp_Duty__c',
                                                        'Is_Rideaway_Pricing_Enabled__c',
                                                        'Rideaway_Pricing_Total__c',
                                                        'Deal__r.Status__c',
                                                        'Deal__r.Type__c',
                                                        'Is_Stocked_In__c',
                                                        'Applicable_Tax__c',
                                                        'Applicable_Tax__r.Name__c',
                                                        'Taxable__c',
                                                        'Customer_Owned_Unit__r.Interior_Colour__c',
                                                        'Customer_Owned_Unit__r.Compliance_Date__c',
                                                        'Customer_Owned_Unit__r.Registration_Serial__c',
                                                        'Deal__r.Delivery_Date__c',
                                                        'Deal__r.Total_Financing_Product_Cost__c',
                                                        'Customer_Owned_Unit__r.Manufactured_Date__c',
                                                        'Customer_Owned_Unit__r.Year_Of_1st_Rego__c',
                                                        'Customer_Owned_Unit__r.Date_Stocked_In__c',
                                                        'Stocked_In_Unit__r.Date_Stocked_In__c',
                                                        'Deal__r.Sales_Tax_Total__c',
                                                        'Category__c',
                                                        'Category__r.Name',
                                                        'Customer_Owned_Unit__r.Automatic__c',
                                                        'Notes__c',
                                                        'Deal__r.Notes_For_Customer__c',
                                                        'Deal__r.Is_Deal_Fulfilled__c'
	                                                };
        return dealItemFields;
    } 
}

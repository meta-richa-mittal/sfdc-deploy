/**
 * Author: Tarun Khandelwal
 * Since: May 20, 2015
 * Name: CustomerOwnedUnit
 * Description: Apex class to handle JSON related oprations of Customer Owned Unit object.
**/
public without sharing class CustomerOwnedUnit {
	
	public String Id;
    public Boolean Consignment;
    public Decimal SuggestedPrice;
    public Decimal AgreedPayout;
    public String VIN;
    public Decimal Year;
    public String Make;
    public String MakeName;
    public String ModelName;
    public String Model;
    public String SubModel;
    public String SubModelName;
    public String MakeModelDescription;
    public String ManufacturedDate;
    public String Plate;
    
    public Decimal Mileage;
    public String Color;
    public String Name;
    public String OtherSerialNo;
    public String EngineSerialNo;
    public String MileageType;
    public String KeyNo;
    public String InteriorColour;
    public Decimal Displacement;
    public Decimal Cylinders;
    public Decimal Gears;
    public String UnitType;
    
    public Boolean IsTaxable;
    public Boolean IsPublishInFeeds;
    public Boolean IsActive;
    public String ApplicableTax;
    public String ApplicableTaxName;
    public Boolean IsAutomatic;
    
    public String Status;
    public Boolean IsNewUnit;
    public String DateIn;
    public String DateOut;
    public Decimal Age;
    public String Location;
    public String Category;
    public String CategoryName;
    public String StockId;
    public String UnitId;
    public String StatusColor;
    public String CustomerId;
	public String CustomerName;
    public String FactoryOrderNo;
    public String FormattedName;
    public String ActiveOnSection;
    
    /* added by kajal 26th april, 2017 #1937 */
    public String BaseUnitId;
    public Decimal TotalBasePrice;
    public Decimal TotalBaseCost;
    /* added by kajal 26th april, 2017 #1937 */
    public String RegExpiryDate;/* added by kajal 1st may, 2017 #1975 */
    public String ComplianceDate;
    public String YearOf1stRego;
    public String RegistrationSerial;
    public List<String> AssignedTags;
    public String UnitData01;
    public String UnitData02;
    public String UnitData03;
    public String UnitData04;
    public String UnitData05;
    public String UnitData06;
    public String UnitData07;
	public String UnitData08;
    public String UnitData09;
	public String UnitData10;
	public String UnitData11;
    public String UnitData12;
    public String UnitData13;
    public String UnitData14;
    public String UnitData15;
    
    public CustomerOwnedUnit(Customer_Owned_Unit__c coUnitRec, List<Unit_Price_Cost__c> upcList) {
    	setCOUFields(coUnitRec, upcList);
    }
    // Constructor
    public CustomerOwnedUnit(Customer_Owned_Unit__c coUnitRec) {
    	setCOUFields(coUnitRec, coUnitRec.Unit_Prices_Costs__r);
    }
    	
    private void setCOUFields(Customer_Owned_Unit__c coUnitRec, List<Unit_Price_Cost__c> upcList) {
    	this.VIN = coUnitRec.VIN_Number__c;
    	this.Year = coUnitRec.Year__c;
    	this.Make = coUnitRec.Unit_Make__c;
    	this.MakeName = (coUnitRec.Unit_Make__c != null) ? coUnitRec.Unit_Make__r.Name : '';
    	this.Name = coUnitRec.Name;
    	
    	this.Plate = coUnitRec.Plate__c;
    	this.Color = coUnitRec.Colour__c;
    	this.Id = coUnitRec.Id;
    	
    	this.Mileage = coUnitRec.Mileage_Value__c;
    	this.MileageType = coUnitRec.Mileage_Type__c;
    	this.OtherSerialNo = coUnitRec.Other_Serial_No__c;
    	this.KeyNo = coUnitRec.Key_No__c;
    	this.InteriorColour = coUnitRec.Interior_Colour__c;
    	this.EngineSerialNo = coUnitRec.Engine_Serial_No__c;
    	this.Displacement = coUnitRec.Displacement__c;
    	this.Cylinders = coUnitRec.Cylinders__c;
    	this.Gears = coUnitRec.Gears__c;
    	this.UnitType = coUnitRec.Unit_Type__c;
    	this.StockId = coUnitRec.Stock_Id__c;
    	this.UnitId = coUnitRec.Unit_Id__c;
        this.Model = coUnitRec.Unit_Model__c;
    	this.ModelName = (coUnitRec.Unit_Model__c != null) ? coUnitRec.Unit_Model__r.Name__c : '';
        this.SubModel = coUnitRec.Sub_Model__c;
		this.SubModelName =  (coUnitRec.Sub_Model__c != null) ? coUnitRec.Sub_Model__r.Sub_Model_Name__c : '';
    		
    	this.MakeModelDescription = (coUnitRec.Sub_Model__c != null) ? coUnitRec.Sub_Model__r.Description__c : '';
    	if(coUnitRec.Manufactured_Date__c != null){
    		this.ManufacturedDate = BPUtility.getFormatedDateTime(datetime.newInstance(coUnitRec.Manufactured_Date__c.year(), coUnitRec.Manufactured_Date__c.month(),coUnitRec.Manufactured_Date__c.day()));
    	}
    	this.IsTaxable = coUnitRec.Taxable__c;
        this.IsPublishInFeeds = coUnitRec.Publish_in_feeds__c;
    	this.ApplicableTax = coUnitRec.Applicable_Tax__c;
    	this.ApplicableTaxName = (coUnitRec.Applicable_Tax__c != null) ? coUnitRec.Applicable_Tax__r.Name__c : '';
    	this.Displacement = coUnitRec.Displacement__c;
    	this.IsAutomatic = coUnitRec.Automatic__c;
    	
    	this.Status = coUnitRec.Status__c;
    	this.IsNewUnit = coUnitRec.New_Unit__c;
    	this.Category = coUnitRec.Category__c;
    	this.CategoryName = (coUnitRec.Category__c != null) ? coUnitRec.Category__r.Name : '';
    	this.CustomerId = coUnitRec.Account__c;
    	if(coUnitRec.Date_Stocked_In__c != null){
    		this.DateIn = BPUtility.getFormatedDateTime(datetime.newInstance(coUnitRec.Date_Stocked_In__c.year(), coUnitRec.Date_Stocked_In__c.month(),coUnitRec.Date_Stocked_In__c.day()));
    	}
    	if(coUnitRec.Date_Stocked_Out__c != null){
    		this.DateOut = BPUtility.getFormatedDateTime(datetime.newInstance(coUnitRec.Date_Stocked_Out__c.year(), coUnitRec.Date_Stocked_Out__c.month(),coUnitRec.Date_Stocked_Out__c.day()));
    	}
    	//this.DateIn = (coUnitRec.Date_Stocked_In__c != null) ? coUnitRec.Date_Stocked_In__c;
    	//this.DateOut = coUnitRec.Date_Stocked_Out__c;
		this.Age = coUnitRec.Age__c;
    	this.Location = coUnitRec.Location__c;
    	if(this.UnitType == 'STOCK') {
			this.CustomerName = Constants.UNIT_INVENTORY;
    		if(coUnitRec.Status__c == 'Available') {
    			this.StatusColor = 'Green';
    		} else if(coUnitRec.Status__c == 'Reserved' || coUnitRec.Status__c == 'Sold'){
    			this.StatusColor = 'Red';
    		} else if(coUnitRec.Status__c == 'Traded' || coUnitRec.Status__c == 'Delivered'){
    			this.StatusColor = 'Black';
    		}
    	
    	} else if(this.UnitType == 'COU') {
			this.CustomerName = coUnitRec.Account__r.Name;
    		if(coUnitRec.Status__c == 'Active') {
    			this.StatusColor = 'Green';
    		} else if(coUnitRec.Status__c == 'Inactive'){
    			this.StatusColor = 'Red';
    		} else if(coUnitRec.Status__c == 'Transferred'){
    			this.StatusColor = 'Black';
    		}
    		if(coUnitRec.Deals_Units_Junction__r != null && coUnitRec.Deals_Units_Junction__r.size() > 0) {
    			this.ActiveOnSection = 'Deal';
    		} else if(coUnitRec.Service_Order_Headers__r != null && coUnitRec.Service_Order_Headers__r.size() > 0) {
    			this.ActiveOnSection = 'Service Job';
    		}
    		this.Consignment = coUnitRec.Consignment__c;
	        this.SuggestedPrice = coUnitRec.Suggested_Price__c != null ? coUnitRec.Suggested_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
	        this.AgreedPayout =  coUnitRec.Agreed_Payout__c != null ? coUnitRec.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
	        
    	} else if(this.UnitType == 'ORDU') {
			this.CustomerName = Constants.UNIT_INVENTORY;
    		if(coUnitRec.Status__c == 'On Order') {
    			this.StatusColor = 'Red';
    		} else if(coUnitRec.Status__c == 'Cancelled' || coUnitRec.Status__c == 'Traded'){
    			this.StatusColor = 'Black';
    		}
    	}
    	
    	this.IsActive = (coUnitRec.Status__c == 'Inactive') ? false : true;
    	
    	this.FactoryOrderNo = coUnitRec.Factory_Order_No__c;
    	this.FormattedName = coUnitRec.Formatted_Name__c;
    	this.ComplianceDate = coUnitRec.Compliance_Date__c;
    	this.RegistrationSerial = coUnitRec.Registration_Serial__c;
    	this.YearOf1stRego = coUnitRec.Year_Of_1st_Rego__c;
    	/* added by kajal 26th april, 2017 #1937 */
    	if(upcList.size() > 0) {
    		this.BaseUnitId = upcList[0].Id;
    		this.TotalBaseCost = (upcList[0].Total_Cost__c != null) ? upcList[0].Total_Cost__c : 0;
    		this.TotalBasePrice = (upcList[0].Total_Price__c != null) ? upcList[0].Total_Price__c : 0;
    	} else {
    		this.TotalBaseCost = 0;
    		this.TotalBasePrice = 0;
    	}
    	/* added by kajal 26th april, 2017 #1937 */
    	/* added by kajal 1st may, 2017 #1975 */
    	if(coUnitRec.Reg_Expiry_Date__c != null){
    		this.RegExpiryDate = BPUtility.getFormatedDateTime(datetime.newInstance(coUnitRec.Reg_Expiry_Date__c.year(), coUnitRec.Reg_Expiry_Date__c.month(),coUnitRec.Reg_Expiry_Date__c.day()));
    	}
    	/* added by kajal 1st may, 2017 #1975 */
    	
    	this.AssignedTags = TagUtil.getTagsList(coUnitRec);
    	
    	this.UnitData01 = coUnitRec.Unit_Data_01__c;
    	this.UnitData02 = coUnitRec.Unit_Data_02__c;
    	this.UnitData03 = coUnitRec.Unit_Data_03__c;
    	this.UnitData04 = coUnitRec.Unit_Data_04__c;
    	this.UnitData05 = coUnitRec.Unit_Data_05__c;
    	this.UnitData06 = coUnitRec.Unit_Data_06__c;
    	this.UnitData07 = coUnitRec.Unit_Data_07__c;
    	this.UnitData08 = coUnitRec.Unit_Data_08__c;
    	this.UnitData09 = coUnitRec.Unit_Data_09__c;
    	this.UnitData10 = coUnitRec.Unit_Data_10__c;
    	this.UnitData11 = coUnitRec.Unit_Data_11__c;
    	this.UnitData12 = coUnitRec.Unit_Data_12__c;
    	this.UnitData13 = coUnitRec.Unit_Data_13__c;
    	this.UnitData14 = coUnitRec.Unit_Data_14__c;
    	this.UnitData15 = coUnitRec.Unit_Data_15__c;
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: COLineItem - Class Object
    **/
    public static List<CustomerOwnedUnit> parse(String json) {
        return (List<CustomerOwnedUnit>) System.JSON.deserialize(json, List<CustomerOwnedUnit>.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> COUFields = new List<String>{ 'Id',
                                                    'Name', 
                                                    'Consignment__c',
                                                    'Suggested_Price__c',
                                                    'Agreed_Payout__c',
                                                    'VIN_Number__c',
                                                    'Account__c',
													'Account__r.Name',
                                                    'Colour__c',
                                                    'Mileage_Value__c',
                                                    'Plate__c',
                                                    'Vendor__c',
                                                    'Submodel__c',
                                                    'Sub_Model__c',
                                                    'Sub_Model__r.Sub_Model_Name__c',
                                                    'Sub_Model__r.Description__c',
                                                    'Unit_Make__c',
                                                    'Unit_Make__r.Name',
                                                    'Unit_Model__c',
                                                    'Unit_Model__r.Name__c',
                                                    'Unit_Model__r.Sub_Model__c',
                                                    'Unit_Model__r.Unit_Make__r.Name',
                                                    'Year__c',
                                                    'Manufactured_Date__c',
                                                    'Unit_Model__r.Description__c',
                                                    'Mileage_Type__c',
                                                    'Key_No__c',
                                                    'Interior_Colour__c',
                                                    'Engine_Serial_No__c',
                                                    'Other_Serial_No__c',
                                                    'Displacement__c',
                                                    'Cylinders__c',
                                                    'Gears__c',
                                                    'Status__c',
                                                    'Unit_Type__c',
                                                    'Taxable__c',
                                                    'Publish_in_feeds__c',
                                                    'Applicable_Tax__c',
                                                    'Applicable_Tax__r.Name__c',
                                                    'Automatic__c',
                                                    'New_Unit__c',
                                                    'Category__c',
                                                    'Category__r.Name',
                                                    'Age__c',
                                                    'Location__c',
                                                    'Stock_Id__c',
                                                    'Unit_Id__c',
                                                    'Factory_Order_No__c',
                                                    'Formatted_Name__c',
                                                    'Date_Stocked_In__c',
                                                    'Date_Stocked_Out__c',
                                                    'Total_Base_Units_Cost__c',
                                                    'Total_Base_Unit_Price__c',
                                                    'Reg_Expiry_Date__c',
                                                    'Assigned_Tag_1__c',
                                                    'Assigned_Tag_2__c',
                                                    'Tax_Amount__c',
                                                    'ORDU_Stock_Id__c',
                                                    'Stocked_In_DateTime__c',
                                        			'Compliance_Date__c',
                                                    'Registration_Serial__c',
                                                    'Year_Of_1st_Rego__c',
                                                    'Total_Cost__c',
                                                    'Unit_Data_01__c',
                                                    'Unit_Data_02__c',
                                                    'Unit_Data_03__c',
                                                    'Unit_Data_04__c',
                                                    'Unit_Data_05__c',
                                                    'Unit_Data_06__c',
                                                    'Unit_Data_07__c',
                                                    'Unit_Data_08__c',
                                                    'Unit_Data_09__c',
                                                    'Unit_Data_10__c',
                                                    'Unit_Data_11__c',
                                                    'Unit_Data_12__c',
                                                    'Unit_Data_13__c',
                                                    'Unit_Data_14__c',
                                                    'Unit_Data_15__c',
                                                    'Notes__c'
                                                };/*total cost and price fields added by kajal 26th april, 2017 #1937 *//* Reg_Expiry_Date__c added by kajal 1st may, 2017 #1975 */
        return COUFields;
    }
    
    public static List<String> getSimilarMatchingFieldsForUnits() {
    	List<String> matchingFields = new List<String>{'Plate__c',
    													'Engine_Serial_No__c',
    													'Other_Serial_No__c',
    													'VIN_Number__c'
    													};
    	return matchingFields;
    }
}
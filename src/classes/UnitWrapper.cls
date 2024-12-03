/**
 * Author: Nidhi Sharma
 * Since: August 03, 2016
 * Name: UnitWrapper
 * Description: Wrapper class to handle JSON variables for View Unit page
**/

public without sharing class UnitWrapper { 
    
    public UnitInfoWrapper UnitInfo;
    public List<PriceAndCostTrackingWrapper> PriceAndCostTrackingWrapperList;
    public List<OwnerWrapper> OwnerList;
    public List<SalesTax> SalesTaxList;
    public List<ServiceOrderWrapper> ServiceOrdersList; // for retrieving SO's for a unit
    public VendorInfoWrapper VendorInfo;
    public List<ActiveDealNotificationWrapper> ActiveDealNotificationWrapperList;
    
    // Constructor
    public UnitWrapper(Customer_Owned_Unit__c unitRec, List<Customer_Owned_Unit__c> similarUnits, List<Sales_Tax__c> salesTaxList, 
                        List<Service_Order_Header__c> soList, List<Unit_Price_Cost__c> unitAdjustmentList) {
        this.UnitInfo = new UnitInfoWrapper(unitRec);
        this.PriceAndCostTrackingWrapperList = new List<PriceAndCostTrackingWrapper>();
        this.VendorInfo = new VendorInfoWrapper(unitRec);
        this.OwnerList = new List<OwnerWrapper>();
        this.SalesTaxList = new List<SalesTax>();
        this.ServiceOrdersList = new List<ServiceOrderWrapper>(); // for retrieving SO's for a unit
        this.ActiveDealNotificationWrapperList = new List<ActiveDealNotificationWrapper>();
        for (Deal_Item__c dealItemRec : unitRec.Deals_Units_Junction__r) {
            this.ActiveDealNotificationWrapperList.add(new ActiveDealNotificationWrapper(dealItemRec));
        }
        for(Unit_Price_Cost__c unitPriceAndCostRec : unitAdjustmentList){
            this.PriceAndCostTrackingWrapperList.add(new PriceAndCostTrackingWrapper(unitPriceAndCostRec));
        }
        
        // Sorting of owners 
        List<Customer_Owned_Unit__c> sortedSimilarUnits = new List<Customer_Owned_Unit__c>();
        for(Customer_Owned_Unit__c similarUnitRec : similarUnits) {
            if(similarUnitRec.Id == unitRec.Id && sortedSimilarUnits.size() > 0) {
                sortedSimilarUnits.add(0, similarUnitRec); 
            } else {
                sortedSimilarUnits.add(similarUnitRec);
            }
        }
        
        for(Customer_Owned_Unit__c similarUnitRec : sortedSimilarUnits) {
            this.OwnerList.add(new OwnerWrapper(similarUnitRec));
        }
        
        for(Sales_Tax__c salesTaxRec : salesTaxList) {
            this.SalesTaxList.add(new SalesTax(salesTaxRec, false));
        }

        // Start: for retrieving SO's for a unit
        for(Service_Order_Header__c soRec : soList) {
            this.ServiceOrdersList.add(new ServiceOrderWrapper(soRec));
        }
        // End: for retrieving SO's for a unit
    }
    
    public class VendorInfoWrapper{
        
        public String VendorName;
        public String VendorEmail;
        public String VendorPhone;
        public String VendorAccount;
        public String DateOrdered;
        public String InvoiceDate;
        public String UnitOrderNo;
        public String FactoryOrderNo;
        public String VendorInvoiceNo;
        public Decimal TotalInvoice;
        public String Manufactured;
        public String ReferencedUnitId;
        public Boolean IsForeignVendor;
        public String CurrencyCode;
        public Decimal ConversionRateWithMarkup = 1; 
        
        public VendorInfoWrapper(Customer_Owned_Unit__c unitRec) {
            if(unitRec.Vendor__c != null) {
                this.VendorName = unitRec.Vendor__r.Name;
            
                if(unitRec.Vendor__r.Preferred_Email__c != null) {
                    this.VendorEmail = unitRec.Vendor__r.Preferred_Email__c;
                } else if(unitRec.Vendor__r.Email__c != null) {
                    this.VendorEmail = unitRec.Vendor__r.Email__c;
                } else if(unitRec.Vendor__r.Work_Email__c != null) {
                    this.VendorEmail = unitRec.Vendor__r.Work_Email__c;
                } else if(unitRec.Vendor__r.Other_Email__c != null) {
                    this.VendorEmail = unitRec.Vendor__r.Other_Email__c;
                }
                    
                if(unitRec.Vendor__r.Preferred_Phone__c != null) {
                    this.VendorPhone = unitRec.Vendor__r.Preferred_Phone__c;
                } else if(unitRec.Vendor__r.Home_Number__c != null) {
                    this.VendorPhone = unitRec.Vendor__r.Formatted_Home_number__c;
                } else if(unitRec.Vendor__r.Mobile__c != null) {
                    this.VendorPhone = unitRec.Vendor__r.Formatted_Mobile_Number__c;
                } else if(unitRec.Vendor__r.Work_Number__c != null) {
                    this.VendorPhone = unitRec.Vendor__r.Formatted_Work_Number__c;
                }
                
                this.IsForeignVendor = unitRec.Vendor__r.Is_Foreign_Vendor__c;
                if(this.IsForeignVendor) {
	                if(unitRec.Vendor__r.Country__r != null) {
                        this.ConversionRateWithMarkup = XeroUtility.isXeroEnabled() ? unitRec.Vendor__r.Country__r.Backward_Conversion_Rate__c : unitRec.Vendor__r.Country__r.Conversion_Rate_With_Markup__c;
                        this.CurrencyCode = unitRec.Vendor__r.Country__r.Currency_Code__c;
	                } else {
	                    ForeignExchangeUtil.CurrencyWrapper currencyObj = ForeignExchangeUtil.getHomeCurrencyDetails();
                        this.CurrencyCode = currencyObj.CurrencyCode;
	                }
	                if(unitRec.Status__c.equalsIgnoreCase('Received')) {
                        this.ConversionRateWithMarkup = XeroUtility.isXeroEnabled() ? unitRec.Backward_Conversion_Rate__c : unitRec.FX_Conversion_Rate__c;
	                }
                }
                
                if(unitRec.Referenced_Unit__r.Date_Ordered__c != null) {
                    this.DateOrdered = (datetime.newInstance(unitRec.Referenced_Unit__r.Date_Ordered__c.year(), unitRec.Referenced_Unit__r.Date_Ordered__c.month(),unitRec.Referenced_Unit__r.Date_Ordered__c.day())).format('MMMM dd, yyyy');
                }
                this.VendorAccount = unitRec.Vendor__r.AccountNumber;
                this.FactoryOrderNo = unitRec.Factory_Order_No__c;
                if(unitRec.Unit_Type__c.equalsIgnoreCase('STOCK') && unitRec.Referenced_Unit__r != null) {
                    unitRec.Referenced_Unit__r.Total_Cost__c = (unitRec.Referenced_Unit__r.Total_Cost__c != null) ? unitRec.Referenced_Unit__r.Total_Cost__c : 0;
                    unitRec.Referenced_Unit__r.Tax_Amount__c = (unitRec.Referenced_Unit__r.Tax_Amount__c != null) ? unitRec.Referenced_Unit__r.Tax_Amount__c : 0;
                    
                    this.TotalInvoice = unitRec.Referenced_Unit__r.Total_Cost__c + unitRec.Referenced_Unit__r.Tax_Amount__c;
                } else {
                    unitRec.Total_Cost__c = (unitRec.Total_Cost__c != null) ? unitRec.Total_Cost__c : 0;
                    unitRec.Tax_Amount__c = (unitRec.Tax_Amount__c != null) ? unitRec.Tax_Amount__c : 0;
                    this.TotalInvoice = unitRec.Total_Cost__c + unitRec.Tax_Amount__c;
                }
                
                this.UnitOrderNo = (unitRec.Referenced_Unit__r.Unit_Id__c != null) ? unitRec.Referenced_Unit__r.Unit_Id__c : '';
                this.ReferencedUnitId = unitRec.Referenced_Unit__c;
                this.VendorInvoiceNo = (unitRec.Invoice_Number__c != null) ? unitRec.Invoice_Number__c : '';
                if(unitRec.Manufactured_Date__c != null){
                    this.Manufactured = (datetime.newInstance(unitRec.Manufactured_Date__c.year(), unitRec.Manufactured_Date__c.month(),unitRec.Manufactured_Date__c.day())).format('MMMM dd, yyyy');
                }
            }
            if(unitRec.Date_Stocked_In__c != null){
                 this.InvoiceDate = (datetime.newInstance(unitRec.Date_Stocked_In__c.year(), unitRec.Date_Stocked_In__c.month(),unitRec.Date_Stocked_In__c.day())).format('MMMM dd, yyyy');
            }           
        }
    }
    
    public class UnitInfoWrapper {  
        
        public String Id;
        public Boolean IsGenericUnit;
        public Boolean Consignment;
        public Decimal SuggestedPrice;
        public Decimal AgreedPayout;
        public String Name;
        public String VIN;
        public String UnitType;
        public String UnitId;
        public String StockNumber;
        public Decimal Year;
        public String MakeModelDescription;
        public String Make;
        public String MakeName;
        public String Model;
        public String ModelName;
        public String SubModel;
        public String SubModelName;
        public String Category;
        public String CategoryName;
        public String ExteriorColour;
        public String Plate;
        public Decimal Mileage;
        public String MileageType;
        public String Status;
        public String StatusColor;
        public Boolean IsNewUnit;
        public String DateIn;
        public String DateOut;
        public Decimal Age;
        public String Location;
        public String ManufacturedDate;
        public String KeyNo;
        public String EngineSerialNo;
        public String OtherSerialNo;
        public String FactoryOrderNo;
        public String InteriorColour;
        public Boolean IsTaxable;
        public Boolean IsPublishInFeeds;
        public String ApplicableTax; 
        public String ApplicableTaxName;
	    public Decimal ApplicableTaxRate;
        public String ApplicableStampDutyCalName;
        public String ApplicableStampDutyCalId;
        public Decimal Cylinders;
        public Decimal Displacement;
        public Boolean IsAutomatic;
        public Decimal Gears;
        public String Notes;
        public Decimal NITCAmount;
        public String NITCStatus;
        public Boolean NITCClaimedManually;
        public String VendorPurchasetaxId;
        
        public String Customer;
        public String CustomerFirstName;
        public String CustomerLastName;
        public String CustomerNickname;
        public String BusinessName;
        public Boolean IsCustomerActive;
        public String CustomerType; 
        public String Type;
        public String HomeEmail;
        public String WorkEmail;
        public String OtherEmail;
        public String HomeNumber;
        public String OtherPhone;
        public String WorkNumber;
        public Boolean HomeNumberSMS;
        public Boolean MobileNumberSMS;
        public Boolean WorkNumberSMS;
        
        public String FormattedHomeNumber;
        public String FormattedOtherPhone;
        public String FormattedWorkNumber;
        public String LinkedInLink;
        public String FacebookLink;
        public String TwitterLink;

        public String PreferredEmail;
        public String PreferredPhone;
        public String PreferredSMS;
        
        public String BillingStreet;
        public String BillingCity;
        public String BillingState;
        public String BillingCountry;
        public String BillingPostalCode;
        public String VendorId;
        
        public String TransmissionType;
        public Decimal TotalPrice;
        public Decimal TotalCost;
        public Decimal TaxableCost;
        public Decimal SalesTax;
        public String RegExpiryDate;
        public List<String> AssignedTags;
        public String DealItemId;
        public String CoNumber;
        public String CoId;
        public String CustomerName;
        public String CustomerId;
        public String ComplianceDate;
        public String YearOf1stRego;
    	public String RegistrationSerial;
		public Boolean IsAccruePurchaseTaxUntilThisUnitIsSold;
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
        public String ExpectedDate;
 		public String OrderedDate;
        public Boolean IsSyncToDP360;
        public Date ConfirmedSaleDate;
        public Boolean IsBRPUnit;
        public String FormattedUnitDetails;
        public String DealId;
        public Decimal FXConversionRateWithMarkUp;
        public String ProductTypeId;
        public String ProductType;
        public UnitProductTypeWrapper UnitOptionalFields;

        public UnitInfoWrapper(Customer_Owned_Unit__c unitRec) {
            this.Id = unitRec.Id;
            this.VendorId = unitRec.Vendor__c;
            this.Name = unitRec.Name != null ? unitRec.Name : '';
            this.VIN = (unitRec.VIN_Number__c == null) ? 'VIN Unknown' : unitRec.VIN_Number__c;
            this.UnitType = (unitRec.Unit_Type__c != null) ? unitRec.Unit_Type__c : '';
            if(unitRec.Unit_Type__c == 'Stock'){
                this.UnitId = unitRec.Stock_Id__c;
            }else if(unitRec.Unit_Type__c == 'COU' || unitRec.Unit_Type__c == 'ORDU'){
                this.UnitId = unitRec.Unit_Id__c;
            }
            if(unitRec.Status__c == 'Received') {
                this.StockNumber = unitRec.ORDU_Stock_Id__c;
                this.FXConversionRateWithMarkUp = XeroUtility.isXeroEnabled() ? (unitRec.Backward_Conversion_Rate__c != null ? unitRec.Backward_Conversion_Rate__c : 0) : (unitRec.FX_Conversion_Rate__c != null ? unitRec.FX_Conversion_Rate__c : 0);	
            } else {
                this.StockNumber = unitRec.Stock_Id__c;
            }
            this.Year = unitRec.Year__c;
            this.Make = unitRec.Unit_Make__c;
            this.MakeName = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : '';
            this.IsBRPUnit = BRPUtility.getAllBRPUnitMakeIdSet().contains(this.Make);
            this.FormattedUnitDetails = ((unitRec.Year__c != null) ? unitRec.Year__c + ', ' : '') + this.MakeName + ', ' +
                                            ((unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c + ', ' : '') + 
                                            ((unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Sub_Model_Name__c + ', ' : '') + this.VIN;        
            this.Model = unitRec.Unit_Model__c;
            this.ModelName = (unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c : '';
            
            this.SubModel = unitRec.Sub_Model__c;
            this.SubModelName = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.MakeModelDescription = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Description__c : '';
                        
            this.FactoryOrderNo = (unitRec.Factory_Order_No__c != null) ? unitRec.Factory_Order_No__c : '';
            this.IsTaxable = unitRec.Taxable__c;
            this.IsPublishInFeeds = unitRec.Publish_in_feeds__c;
            this.ApplicableTax = unitRec.Applicable_Tax__c;
            this.ApplicableTaxName = (unitRec.Applicable_Tax__c != null) ? unitRec.Applicable_Tax__r.Name__c : '';
            this.ApplicableTaxRate = (unitRec.Applicable_Tax__c != null && unitRec.Applicable_Tax__r.Rate__c != null) ? unitRec.Applicable_Tax__r.Rate__c : 0;
            this.IsAutomatic = unitRec.Automatic__c;
            this.Notes = unitRec.Notes__c;
            this.ApplicableStampDutyCalId = unitRec.Stamp_Duty_Calculators__c;
            this.ApplicableStampDutyCalName = (unitRec.Stamp_Duty_Calculators__c != null) ? unitRec.Stamp_Duty_Calculators__r.Name__c : '';
            
            this.Status = unitRec.Status__c;
            this.IsNewUnit = unitRec.New_Unit__c;
            /* added by kajal 26th april, 2017 #1937 */
            this.TotalPrice = (unitRec.Total_Price__c != null) ? unitRec.Total_Price__c : 0;
            this.TotalCost = (unitRec.Total_Cost__c != null) ? unitRec.Total_Cost__c : 0;
            this.TaxableCost = (unitRec.Taxable_Cost__c != null) ? unitRec.Taxable_Cost__c : 0;
            this.SalesTax = unitRec.Vendor__r.Purchase_Tax__r.Rate__c;
            /* added by kajal 26th april, 2017 #1937 */
            // Added by kajal 8th may , 2017
            if(unitRec.Reg_Expiry_Date__c != null){
                this.RegExpiryDate = BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Reg_Expiry_Date__c.year(), unitRec.Reg_Expiry_Date__c.month(),unitRec.Reg_Expiry_Date__c.day()));
            }
            // Added by kajal 8th may , 2017
            this.Category = unitRec.Category__c;
            this.CategoryName = (unitRec.Category__c != null) ? unitRec.Category__r.Name : '';
            if(unitRec.Date_Stocked_In__c != null){
                this.DateIn = BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Stocked_In__c.year(), unitRec.Date_Stocked_In__c.month(),unitRec.Date_Stocked_In__c.day()));
            }
            if(unitRec.Date_Stocked_Out__c != null){
                this.DateOut =  BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Stocked_Out__c.year(), unitRec.Date_Stocked_Out__c.month(),unitRec.Date_Stocked_Out__c.day()));
            }
            this.Age = unitRec.Age__c;
            this.Location = unitRec.Location__c;
            
            this.Customer = unitRec.Account__c;
            
            if(this.UnitType == 'STOCK') {
                if(unitRec.Status__c == 'Available') {
                    this.StatusColor = 'Green';
                } else if(unitRec.Status__c == 'Reserved' || unitRec.Status__c == 'Sold'){
                    this.StatusColor = 'Red';
                } else if(unitRec.Status__c == 'Traded' || unitRec.Status__c == 'Delivered'){
                    this.StatusColor = 'Black';
                }
            
            } else if(this.UnitType == 'COU') {
                if(unitRec.Status__c == 'Active') {
                    this.StatusColor = 'Green';
                } else if(unitRec.Status__c == 'Inactive'){
                    this.StatusColor = 'Red';
                } else if(unitRec.Status__c == 'Transferred'){
                    this.StatusColor = 'Black';
                }
            	this.Consignment = unitRec.Consignment__c;
                this.IsGenericUnit = unitRec.Is_Generic_Unit__c;
	            this.SuggestedPrice = unitRec.Suggested_Price__c != null ? unitRec.Suggested_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
	            this.AgreedPayout = unitRec.Agreed_Payout__c != null ? unitRec.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
	            
            } else if(this.UnitType == 'ORDU') {
                if(unitRec.Status__c == 'On Order') {
                    this.StatusColor = 'Red';
                } else if(unitRec.Status__c == 'Cancelled' || unitRec.Status__c == 'Traded'){
                    this.StatusColor = 'Black';
                }
                this.VendorPurchasetaxId = unitRec.Unit_Purchase_Tax__c != null ? unitRec.Unit_Purchase_Tax__r.Id : unitRec.Vendor__r.Purchase_Tax__r.Id;
            }
            
            if(unitRec.Account__c != null){
                this.Type = this.CustomerType = unitRec.Account__r.Type__c;
                this.IsCustomerActive = unitRec.Account__r.Active__c;
                this.CustomerFirstName = (unitRec.Account__r.FirstName__c == null) ? '' : unitRec.Account__r.FirstName__c;
                this.CustomerLastName = (unitRec.Account__r.LastName__c == null) ? '' : unitRec.Account__r.LastName__c;
                this.CustomerNickname = unitRec.Account__r.Nickname__c;
                this.BusinessName = (unitRec.Account__r.Name == null) ? '' : unitRec.Account__r.Name;
                //this.CustomerEmail = (unitRec.Account__c != null) ? unitRec.Account__r.Email__c : '';
                //this.CustomerPhone = (unitRec.Account__c != null) ? unitRec.Account__r.Preferred_Phone__c : '';
                //this.CustomerSMSPhone = (unitRec.Account__c != null) ? unitRec.Account__r.Preferred_SMS__c : '';
                
                this.HomeEmail = (unitRec.Account__r.Email__c == null) ? '' : unitRec.Account__r.Email__c;
                this.WorkEmail = (unitRec.Account__r.Work_Email__c == null) ? '' : unitRec.Account__r.Work_Email__c;
                this.OtherEmail = (unitRec.Account__r.Other_Email__c == null) ? '' : unitRec.Account__r.Other_Email__c;
                
                this.HomeNumber = (unitRec.Account__r.Home_Number__c == null ) ? '' : unitRec.Account__r.Home_Number__c;
                this.OtherPhone = (unitRec.Account__r.Mobile__c == null) ? '' : unitRec.Account__r.Mobile__c;
                this.WorkNumber = (unitRec.Account__r.Work_Number__c == null) ? '' : unitRec.Account__r.Work_Number__c;
                
                this.HomeNumberSMS = unitRec.Account__r.Home_Number_SMS__c;
                this.MobileNumberSMS = unitRec.Account__r.Mobile_Number_SMS__c;
                this.WorkNumberSMS = unitRec.Account__r.Work_Number_SMS__c;
                
                
                this.FormattedHomeNumber = (unitRec.Account__r.Home_Number__c == null ) ? '' : unitRec.Account__r.Formatted_Home_number__c;
                this.FormattedOtherPhone = (unitRec.Account__r.Mobile__c == null) ? '' : unitRec.Account__r.Formatted_Mobile_Number__c;
                this.FormattedWorkNumber = (unitRec.Account__r.Work_Number__c == null) ? '' : unitRec.Account__r.Formatted_Work_Number__c;

                this.LinkedInLink = unitRec.Account__r.LinkedIn__c;
                this.FacebookLink = unitRec.Account__r.Facebook__c;
                this.TwitterLink = unitRec.Account__r.Twitter__c;
                
                this.BillingStreet = (unitRec.Account__r.BillingStreet == null) ? '' : unitRec.Account__r.BillingStreet;
                this.BillingCity = (unitRec.Account__r.BillingCity == null) ? '' : unitRec.Account__r.BillingCity;
                this.BillingState = (unitRec.Account__r.BillingState == null) ? '' : unitRec.Account__r.BillingState;
                this.BillingCountry = (unitRec.Account__r.BillingCountry == null) ? '' : unitRec.Account__r.BillingCountry;
                this.BillingPostalCode = (unitRec.Account__r.BillingPostalCode == null) ? '' : unitRec.Account__r.BillingPostalCode;
        
                if(unitRec.Account__r.Preferred_Email__c != null) {
                    if(unitRec.Account__r.Preferred_Email__c == unitRec.Account__r.Email__c) {
                        this.PreferredEmail = 'HomeEmail';
                    } else if(unitRec.Account__r.Preferred_Email__c == unitRec.Account__r.Work_Email__c) {
                        this.PreferredEmail = 'WorkEmail';
                    } else if(unitRec.Account__r.Preferred_Email__c == unitRec.Account__r.Other_Email__c) {
                        this.PreferredEmail = 'OtherEmail';
                    }
                } else {
                    this.PreferredEmail = '';
                }
                
                if(unitRec.Account__r.Preferred_Phone__c != null) {
                    if(unitRec.Account__r.Preferred_Phone__c == unitRec.Account__r.Home_Number__c) {
                        this.PreferredPhone = 'FormattedHomeNumber';
                    } else if(unitRec.Account__r.Preferred_Phone__c == unitRec.Account__r.Mobile__c) {
                        this.PreferredPhone = 'FormattedOtherPhone';
                    } else if(unitRec.Account__r.Preferred_Phone__c == unitRec.Account__r.Work_Number__c) {
                        this.PreferredPhone = 'FormattedWorkNumber';
                    }
                } else {
                    this.PreferredPhone = '';
                }
                
                if(unitRec.Account__r.Preferred_SMS__c != null) {
                    if(unitRec.Account__r.Preferred_SMS__c == unitRec.Account__r.Home_Number__c) {
                        this.PreferredSMS = 'FormattedHomeNumber';
                    } else if(unitRec.Account__r.Preferred_SMS__c == unitRec.Account__r.Mobile__c) {
                        this.PreferredSMS = 'FormattedOtherPhone';
                    } else if(unitRec.Account__r.Preferred_SMS__c == unitRec.Account__r.Work_Number__c) {
                        this.PreferredSMS = 'FormattedWorkNumber';
                    }
                } else {
                    this.PreferredSMS = '';
                }
            }
            
            this.AssignedTags = TagUtil.getTagsList(unitRec);
            
            if(this.IsAutomatic) {
                this.TransmissionType = 'Automatic';
            } else {
                this.TransmissionType = 'Manual';
            }
            this.DealItemId = unitRec.Deals_Units_Junction__r.size() > 0 ? unitRec.Deals_Units_Junction__r[0].Id: null;
            this.CoNumber = unitRec.Deals_Units_Junction__r.size() > 0 ? (unitRec.Deals_Units_Junction__r != null ? unitRec.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Name : null) : null;
            this.CoId = unitRec.Deals_Units_Junction__r.size() > 0 ? (unitRec.Deals_Units_Junction__r != null ? unitRec.Deals_Units_Junction__r[0].Deal__r.CO_Header__c : null) : null;
            this.CustomerName = unitRec.Deals_Units_Junction__r.size() > 0 ? (unitRec.Deals_Units_Junction__r != null ? unitRec.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Customer__r.Name : null) : null;
            this.CustomerId = unitRec.Deals_Units_Junction__r.size() > 0 ? (unitRec.Deals_Units_Junction__r != null ? unitRec.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Customer__c : null) : null;
        	this.IsAccruePurchaseTaxUntilThisUnitIsSold = unitRec.Is_Accrue_Purchase_Tax_Until_Unit_Sold__c;
        	this.ExpectedDate = (unitRec.Date_Expected__c != null) ? 
								BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Expected__c.year(), unitRec.Date_Expected__c.month(), unitRec.Date_Expected__c.day())) : '' ;
 			this.OrderedDate = (unitRec.Date_Ordered__c != null) ? 
								BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Ordered__c.year(), unitRec.Date_Ordered__c.month(), unitRec.Date_Ordered__c.day())) : '' ;
			if(this.UnitType == 'STOCK') {
				this.NITCAmount = unitRec.NITC_Amount__c;
				this.NITCClaimedManually = unitRec.NITC_Claimed_Manually__c;
				
				if(this.NITCClaimedManually) {
					this.NITCStatus = 'Claimed manually ';
					if(unitRec.NITC_Date_Claimed__c != null) {
						this.NITCStatus += BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.NITC_Date_Claimed__c.year(), unitRec.NITC_Date_Claimed__c.month(),unitRec.NITC_Date_Claimed__c.day()));
					}
				} else if(unitRec.Status__c == 'Sold') {
					this.NITCStatus = 'Claimed when unit sold ' + this.DateOut;
				} else {
					this.NITCStatus = 'Withheld ' + this.DateIn;
				}
			}
            this.ConfirmedSaleDate = unitRec.Deals_Units_Junction__r.size() > 0 ? (unitRec.Deals_Units_Junction__r != null ? unitRec.Deals_Units_Junction__r[0].Deal__r.Confirmed_Sale_Date__c : null) : null;
            this.ProductTypeId = unitRec.Product_type__c;
            this.ProductType = unitRec.Product_type__c != null ? unitRec.Product_type__r.Name__c : '';
        }
    } 
    
    public class PriceAndCostTrackingWrapper {  

        public String Id;
        public String Type;
        public String RefNo;
        public String ItemDescription;
        public String CoHeaderId;
        public Decimal ProfiltPercentage;
        public Decimal ProfitAmount;
        public Decimal Quantity;
        public Decimal Price;
        public Decimal TotalPrice;
        public Decimal TotalCost; 
        public Boolean Taxable;
        public String UnitId; 
        
        public String AdjustmentDate;
	    public String CategoryId;
	    public String CategoryName;
	    public String VendorId;
	    public String VendorName;
	    public String VendorReferenceNumber;
        public Boolean IsForeignVendor;
        public String FactoryOptionId;

        public String CustomerId;
        public String CustomerName;
	    public String CustomerReferenceNumber;
	    
        public String ApplicableTaxID;
        public String ApplicableTaxName;

        public PriceAndCostTrackingWrapper(Unit_Price_Cost__c unitPriceAndCostRec){

            this.Id = unitPriceAndCostRec.Id;
            this.Type = unitPriceAndCostRec.Type__c != null ? unitPriceAndCostRec.Type__c : '';
            // added by subhrant 04/12
            this.RefNo = unitPriceAndCostRec.CO_Invoice_Header__c != null ? unitPriceAndCostRec.CO_Invoice_Header__r.Invoice_Number__c : 
                            (unitPriceAndCostRec.Ref_No__c != null ? unitPriceAndCostRec.Ref_No__c : '');
            this.ItemDescription = unitPriceAndCostRec.Item_Description__c != null ? unitPriceAndCostRec.Item_Description__c : '';
            this.Quantity = unitPriceAndCostRec.Qty__c != null ? unitPriceAndCostRec.Qty__c : 0;
            this.Price = unitPriceAndCostRec.Price__c != null ? unitPriceAndCostRec.Price__c : 0;
            
	    	if(unitPriceAndCostRec.Adjustment_Date__c != null){
    			this.AdjustmentDate =  BPUtility.getFormatedDateTime(datetime.newInstance(unitPriceAndCostRec.Adjustment_Date__c.year(), unitPriceAndCostRec.Adjustment_Date__c.month(),unitPriceAndCostRec.Adjustment_Date__c.day()));
    		}
    		
    		if(unitPriceAndCostRec.Category__c != null) {
    			this.CategoryId = unitPriceAndCostRec.Category__c;
    			this.CategoryName = unitPriceAndCostRec.Category__r.Name;
    		}
    		
    		if(unitPriceAndCostRec.Vendor__c != null) {
    			this.VendorId = unitPriceAndCostRec.Vendor__c;
    			this.VendorName = unitPriceAndCostRec.Vendor__r.Name;
    			this.VendorReferenceNumber = unitPriceAndCostRec.Vendor_Reference_Number__c;
    		}

            if(unitPriceAndCostRec.Customer__c != null) {
    			this.CustomerId = unitPriceAndCostRec.Customer__c;
    			this.CustomerName = unitPriceAndCostRec.Customer__r.Name;
    			this.CustomerReferenceNumber = unitPriceAndCostRec.Customer_Reference_Number__c;
    		}
            if(unitPriceAndCostRec.Applicable_Tax__c != null) {
                this.ApplicableTaxID = unitPriceAndCostRec.Applicable_Tax__c;
                this.ApplicableTaxName = unitPriceAndCostRec.Applicable_Tax__r.Name__c;
            }

            this.TotalPrice = unitPriceAndCostRec.Total_Price__c != null ? unitPriceAndCostRec.Total_Price__c : 0; 
            this.TotalCost = unitPriceAndCostRec.Total_Cost__c != null ? unitPriceAndCostRec.Total_Cost__c : 0;
            this.Taxable = unitPriceAndCostRec.Taxable__c;
            this.ProfiltPercentage = unitPriceAndCostRec.Profit_Percentage__c != null ? unitPriceAndCostRec.Profit_Percentage__c : 0;
            this.ProfitAmount = unitPriceAndCostRec.Profit_Amount__c != null ? unitPriceAndCostRec.Profit_Amount__c : 0;
            this.UnitId = unitPriceAndCostRec.Customer_Owned_Unit__c;// Added by kajal - 11/17/2016 - #1293
            this.CoHeaderId = (unitPriceAndCostRec.CO_Invoice_Header__c != null) ? unitPriceAndCostRec.CO_Invoice_Header__r.CO_Header__c : null;
            this.FactoryOptionId = unitPriceAndCostRec.Factory_Option__c;
        }
    } 
    
    public class OwnerWrapper { 
        public String Id;
        public String CreatedDate;
        public String UnitType;
        public String UnitId;
        public String Source;
        public String CustomerName;
        
        public OwnerWrapper(Customer_Owned_Unit__c similarUnitRec){
            this.Id = similarUnitRec.Id;
            this.UnitType = similarUnitRec.Unit_Type__c;
            if(similarUnitRec.Unit_Type__c == 'Stock'){
                this.UnitId = similarUnitRec.Stock_Id__c;
            } else if(similarUnitRec.Unit_Type__c == 'COU' || similarUnitRec.Unit_Type__c == 'ORDU'){
                this.UnitId = similarUnitRec.Unit_Id__c;
            }
            this.CreatedDate = BPUtility.getFormatedDateTime(similarUnitRec.CreatedDate);
            this.Source = 'New COU'; // This is to be changed
            this.CustomerName = (similarUnitRec.Account__c != null) ? similarUnitRec.Account__r.Name : '';
        }
    } 
    
    public class SalesTax {
        
        public String ApplicableTaxName;
        public String Id;
        public Decimal TaxRate;
        public Boolean IsDefault;
        public String Type;
        
        public SalesTax(Sales_Tax__c salesTaxRec, Boolean isDefault) {
            this.ApplicableTaxName = salesTaxRec.Name__c;
            this.Id = salesTaxRec.Id;
            this.IsDefault = isDefault;
            this.TaxRate = (salesTaxRec.Rate__c != null) ? salesTaxRec.Rate__c : 0;
            this.Type = salesTaxRec.Tax_Type__c;
        }
    }
    
    // Start: for retrieving SO's for a unit 
    public class ServiceOrderWrapper {
        public String COHeaderId;
        public String COHeaderNumber;
        public String SOType;
        public String Concern;
        public Decimal Total;
        public Decimal MileageOut;
        public String LastModified;
        public String WorkStatus;
        
        public ServiceOrderWrapper(Service_Order_Header__c soRec) {
            this.COHeaderId = (soRec.CO_Header__r.Id != null) ? soRec.CO_Header__r.Id : '';
            this.COHeaderNumber = (soRec.CO_Header__r.Name != null) ? soRec.CO_Header__r.Name : '';
            this.SOType = (soRec.SO_Type__c != null) ? soRec.SO_Type__c : '';
            
            if(soRec.SO_Type__c == 'Deal') { 
                this.SOType = 'Deal Service';
            }
            
            this.Concern = (soRec.SO_Concern__c != null) ? soRec.SO_Concern__c.replace('\n', ', ') : '';
            Decimal TaxAmount = (soRec.Tax_Amount__c != null) ? soRec.Tax_Amount__c : 0.00;
            if(soRec.SO_Type__c == 'Deal') {
                TaxAmount = 0.00;
            }
            Decimal TotalWithoutTax = (soRec.Total__c != null) ? soRec.Total__c : 0.00;
            this.Total = TotalWithoutTax + TaxAmount;
            this.MileageOut = (soRec.Odometer_on_Departure__c != null) ? (soRec.Odometer_on_Departure__c).setScale(2, RoundingMode.HALF_UP) : 0.00;
            if(soRec.Invoice_Number__c != null && soRec.Invoice_Number__r.Closed_Invoice_Date__c != null) {
                this.LastModified = String.valueOf((soRec.Invoice_Number__r.Closed_Invoice_Date__c).date().format());
            } else {
                String lastModifiedDateTime = BPUtility.getLastModifiedDateStr(soRec);
                this.LastModified = (String.isBlank(lastModifiedDateTime)) ? '' : lastModifiedDateTime;
            }
            this.WorkStatus = soRec.SO_Status__c;
        }
    }
    // End: for retrieving SO's for a unit

    public class Documents implements Comparable {
        public Boolean IsPrimary;
        public String DocId;
        public String AttachmentId;
        public String AttchmentURL;
        public Decimal ImageUploadedAt;
        public Datetime CreatedDate;
        public String PublicUrl;

        public Documents(String contentDocId, ContentVersion contentVersionRec, ContentDistribution contentDistributionRec) {
            this.IsPrimary = contentVersionRec.Is_Primary__c;
            this.DocId = contentDocId;
            this.AttachmentId = contentVersionRec.Id;
            this.AttchmentURL = '/sfc/servlet.shepherd/version/download/' + AttachmentId;
            this.ImageUploadedAt = contentVersionRec.Image_Uploaded_At__c;
            this.CreatedDate = contentVersionRec.CreatedDate;
            if(String.isNotBlank(this.AttachmentId) && String.isNotBlank(contentDistributionRec.DistributionPublicUrl)) {
				this.PublicUrl = GenericExportUtil.getImagePublicURL(contentDistributionRec.DistributionPublicUrl, this.AttachmentId);
			}
        }

        public Integer compareTo(Object compareToObj) {
            Documents compareToWrapper = (Documents)compareToObj;
            if(this.ImageUploadedAt != null) {
                if(this.ImageUploadedAt < compareToWrapper.ImageUploadedAt) {
                    return -1;
                } else if(this.ImageUploadedAt == compareToWrapper.ImageUploadedAt) {
                    return 0;
                }
            } else {
                if(this.CreatedDate < compareToWrapper.CreatedDate) {
                    return -1;
                } else if(this.CreatedDate == compareToWrapper.CreatedDate) {
                    return 0;
                }
            }
            return 1;
        }
    }
    
    // Start: for retrieving Active Deal Status
    public class ActiveDealNotificationWrapper {
        public String CoId;
        public String CustomerId;
        public String CustomerName;
        public String CoNumber;
        public String DealStatus;
        public String DealItemType;
        
        public ActiveDealNotificationWrapper(Deal_Item__c dealItemRec) {
            this.CoNumber = dealItemRec != null ? dealItemRec.Deal__r.CO_Header__r.Name : '' ;
            this.CoId =  dealItemRec.Deal__r.CO_Header__c;
            this.CustomerName = dealItemRec != null ? dealItemRec.Deal__r.CO_Header__r.Customer__r.Name : '';
            this.CustomerId = dealItemRec.Deal__r.CO_Header__r.Customer__c;
            this.DealStatus = dealItemRec != null ? dealItemRec.Deal__r.Status__c : '';
            this.DealItemType = dealItemRec != null ? dealItemRec.Type__c : '';
        }
    }
    // End: for retrieving Active Deal Status

    public class FileUploadWrapper {
        public String FileName;
        public Decimal ImageUploadedAt;
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: UnitWrapper - Class Object
    **/
    public static UnitWrapper parse(String json) {
        return (UnitWrapper) System.JSON.deserialize(json, UnitWrapper.class);
    }
    
    /**
     * Name: fieldsListForUnitInfo
     * Desc: Method Which contains all the field list to be queried for info section
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsListForUnitInfo(){
        List<String> COUFields = new List<String>{ 'Id',
                                                    'Name',
                                                    'Total_Base_Units_Cost__c',
                                                    'Total_Base_Unit_Price__c',
                                                    'Consignment__c',
                                                    'Is_Generic_Unit__c',
                                                    'Suggested_Price__c',
                                                    'Agreed_Payout__c', 
                                                    'VIN_Number__c', 
                                                    'Account__c',
                                                    'Account__r.Name',
                                                    'Account__r.Nickname__c',
                                                    'Account__r.Active__c',
                                                    'Account__r.Type__c',
                                                    'Account__r.FirstName__c',
                                                    'Account__r.LastName__c',
                                                    'Account__r.Email__c',
                                                    'Account__r.Home_Number__c',
                                                    'Account__r.Home_Number_SMS__c',
                                                    'Account__r.Mobile__c',
                                                    'Account__r.Mobile_Number_SMS__c', 
                                                    'Account__r.Other_Email__c',
                                                    'Account__r.Preferred_Email__c',
                                                    'Account__r.Preferred_Phone__c',
                                                    'Account__r.Preferred_SMS__c',
                                                    'Account__r.Work_Email__c',
                                                    'Account__r.Work_Number__c',
                                                    'Account__r.Work_Number_SMS__c',
                                                    'Account__r.LinkedIn__c',
                                                    'Account__r.Twitter__c',
                                                    'Account__r.Facebook__c',
                                                    'Account__r.BillingStreet',
                                                    'Account__r.BillingCity',
                                                    'Account__r.BillingState',
                                                    'Account__r.BillingCountry',
                                                    'Account__r.BillingPostalCode',
                                                    'Account__r.Formatted_Home_number__c',
                                                    'Account__r.Formatted_Mobile_Number__c',
                                                    'Account__r.Formatted_Work_Number__c',
                                                    'Account__r.Formatted_Preferred_Phone__c',
                                                    'Vendor__r.Purchase_Tax__r.Rate__c',
                                                    'Unit_Type__c',                                   
                                                    'Submodel__c',
                                                    'Sub_Model__r.Description__c',
                                                    'Sub_Model__c',
                                                    'Sub_Model__r.Sub_Model_Name__c',
                                                    'Unit_Make__c',
                                                    'FX_Conversion_Rate__c',
                                                    'Backward_Conversion_Rate__c',
                                                    'Unit_Make__r.Name',
                                                    'Unit_Model__c',
                                                    'Unit_Model__r.Name__c',
                                                    'Unit_Model__r.Sub_Model__c',
                                                    'Unit_Model__r.Unit_Make__r.Name',
                                                    'Unit_Model__r.Description__c',
                                                    'Year__c',
                                                    'Notes__c',
                                                    'Taxable__c',
                                                    'Publish_in_feeds__c',
                                                    'Applicable_Tax__c',
                                                    'Applicable_Tax__r.Name__c',
													'Applicable_Tax__r.Rate__c',
                                                    'Automatic__c',
                                                    'Status__c',
                                                    'New_Unit__c',
                                                    'Unit_Id__c',
                                                    'Stock_Id__c',
                                                    'Category__c',
                                                    'Category__r.Name',
                                                    'Date_Stocked_In__c',
                                                    'Date_Stocked_Out__c',
                                                    'Age__c',
                                                    'Location__c',
                                                    'Factory_Order_No__c',
                                                    'CreatedDate',
                                                    'Total_Cost__c',
                                                    'Taxable_Cost__c',
                                                    'Tax_Amount__c',
                                                    'Total_Price__c',
                                                    'Invoice_Number__c ',
                                                    'Reg_Expiry_Date__c',
                                                    'Assigned_Tag_1__c',
                                                    'Assigned_Tag_2__c',
                                                    'Formatted_Name__c',
                                                    'Vendor__c',
                                                    'Vendor__r.Name',
                                                    'Vendor__r.Preferred_Email__c',
                                                    'Vendor__r.Email__c',
                                                    'Vendor__r.Work_Email__c',
                                                    'Vendor__r.Other_Email__c',
                                                    'Vendor__r.Preferred_Phone__c',
                                                    'Vendor__r.Home_Number__c',
                                                    'Vendor__r.Formatted_Home_number__c',
                                                    'Vendor__r.Mobile__c',
                                                    'Vendor__r.Formatted_Mobile_Number__c',
                                                    'Vendor__r.Work_Number__c',
                                                    'Vendor__r.Formatted_Work_Number__c',
                                                    'Vendor__r.AccountNumber',
                                                    'Vendor__r.Is_Foreign_Vendor__c',
                                                    'Vendor__r.Country__r.Conversion_Rate_With_Markup__c',
                                                    'Vendor__r.Country__r.Backward_Conversion_Rate__c',
                                                    'Vendor__r.Country__r.Currency_Code__c',
                                                    'Referenced_Unit__r.Unit_Id__c',
                                                    'Referenced_Unit__r.CreatedDate',
                                                    'Referenced_Unit__r.Date_Ordered__c',
                                                    'Referenced_Unit__r.Total_Cost__c',
                                                    'Referenced_Unit__r.Tax_Amount__c',
                                                    'Referenced_Unit__c',
                                                    'ORDU_Stock_Id__c',
                                                    'DP360_Inventory_Id__c',
                                                    'CreatedBy.Name',
                                                    'Is_Accrue_Purchase_Tax_Until_Unit_Sold__c',
                                                    'Date_Ordered__c',
                                                    'Date_Expected__c',
                                                    'Sales_Tax_Credit__c',
                                                    'Purchase_Tax_Credit__c',
                                                    'NITC_Claimed_Manually__c',
                                                    'NITC_Date_Claimed__c',
                                                    'Product_type__c',
                                                    'Product_type__r.Id',
                                                    'Product_type__r.Name__c',
                                                    'NITC_Amount__c',
                                                    'Manufactured_Date__c',
                                                    'Unit_Purchase_Tax__r.Id',
                                                    'Vendor__r.Purchase_Tax__r.Id',
                                                    'Stamp_Duty_Calculators__c',
                                                    'Stamp_Duty_Calculators__r.Name__c',
                                                    '(SELECT Name, Deal__r.CO_Header__r.Name, Deal__r.CO_Header__r.Customer__r.Name,Deal__r.Status__c,Type__c, Deal__r.Confirmed_Sale_Date__c FROM Deals_Units_Junction__r)'
											    	};
        return COUFields; 
    }
    
    /**
     * Name: fieldsListForUnitPriceAndCostTracking
     * Desc: Method Which contains all the field list to be queried for Price and Tax Tracking section
     * @param:  
     * @return: List<String> - Fields List
     **/
    public static List<String> fieldsListForUnitPriceAndCostTracking(){
        List<String> COUFields = new List<String>{ 'Id',
        											'Adjustment_Date__c',
        											'Category__r.Name',
        											'Vendor__r.Name',
        											'Vendor_Reference_Number__c',
                                                    'Type__c', 
                                                    'Ref_No__c', 
                                                    'Item_Description__c',
                                                    'Qty__c',
                                                    'Price__c',
                                                    'Total_Price__c',
                                                    'Total_Cost__c',
                                                    'Taxable__c',
                                                    'Profit_Amount__c',
                                                    'Profit_Percentage__c',
                                                    'Customer_Owned_Unit__c',
                                                    'CO_Invoice_Header__c',
                                                    'CO_Invoice_Header__r.Invoice_Number__c',
                                                    'CO_Invoice_Header__r.CO_Header__c',
                                                    'Factory_Option__c',
                                                    'Customer_Reference_Number__c',
                                                    'Customer__c',
                                                    'Customer__r.Name',
                                                    'Applicable_Tax__c',
                                                    'Applicable_Tax__r.Name__c'
                                                };
        return COUFields;
    }

    // Start: for retrieving SO's for a unit
    /**
     * Name: fieldsListForServiceOrders
     * Desc: Method Which contains all the field list to be queried for retrieving SO's for a unit
     * @param:  
     * @return: List<String> - Fields List
     **/
    public static List<String> fieldsListForServiceOrders(){
        List<String> COUFields = new List<String>{ 'Id',
                                                    'Name', 
                                                    'SO_Type__c', 
                                                    'SO_Concern__c',
                                                    'Total__c',
                                                    'Total_With_Tax__c',
                                                    'Tax_Amount__c',
                                                    'Odometer_on_Departure__c',
                                                    'LastModifiedDate',
                                                    'Last_Modified_Date__c',
                                                    'Invoice_Number__r.Closed_Invoice_Date__c',
                                                    'CO_Header__r.Id',
                                                    'CO_Header__r.Name',
                                                    'SO_Status__c'
                                                };
        return COUFields;
    }
    // End: for retrieving SO's for a unit
}
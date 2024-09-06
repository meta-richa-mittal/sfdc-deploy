/**
 * Author: Nidhi Sharma
 * Since: September 01, 2016
 * Name: DealWrapper
 * Description: Wrapper class to handle JSON variables for Deal
**/
public class DealWrapper {  
    
    public DealInfoWrapper DealInfo;
    public List<UnitSectionWrapper> UnitList; 
    public DealSummary DealSummaryObj;
    public List<DealItem> TradeInsList;
    public DealFulfillmentSectionWrapper DealFulfillmentSectionObj;
    public List<UserSettingCtrl.UserWrapper> UserList;
    public List<DealUnresolvedFulfillmentWrapper> DealUnresolvedFulfillmentList;
    public List<CODeposit> DealDepositList;
    public SO_KLI_Recalculation.Errorhandler error;
    
    // Constructor
    public DealWrapper(List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentRecList, List<CO_Line_Item__c> coliList, List<CO_Kit_Header__c> cokhList, List<Vendor_Order_Line_Item__c> specialOrderList) {
        this.DealUnresolvedFulfillmentList = new List<DealUnresolvedFulfillmentWrapper>();
        for(Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec : dealUnresolvedFulfillmentRecList){
            this.DealUnresolvedFulfillmentList.add(new DealUnresolvedFulfillmentWrapper(dealUnresolvedFulfillmentRec));
        }
        
        this.DealFulfillmentSectionObj = new DealFulfillmentSectionWrapper(coliList, cokhList, specialOrderList);
        this.error = (COService.error != null) ? COService.error : new SO_KLI_Recalculation.Errorhandler('200', 'Success');
    }
    
    public DealWrapper(Deal_Finance__c dealFinanceRec) {
        this.DealFinanceObj = new DealFinanceWrapper(dealFinanceRec);
    } 
	
	public DealWrapper(Deal__c dealRec, List<Deal_Item__c> dealItems, Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap) {
		this.DealInfo = new DealInfoWrapper(dealRec);
		this.UnitList = new List<UnitSectionWrapper>();
		for(Deal_Item__c dealItemRec : dealItems) {
            if(dealItemRec.Type__c != Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                if(!dealItemIdToDKHListMap.containsKey(dealItemRec.Id)) {
                    dealItemIdToDKHListMap.put(dealItemRec.Id, new List<Deal_Kit_Header__c>());
                }
                UnitSectionWrapper unitSectionObj = new UnitSectionWrapper(dealItemRec, dealItemIdToDKHListMap.get(dealItemRec.Id));
                if((dealItemRec.Unit_Status__c == 'Temporary' || dealItemRec.Unit_Status__c == 'Required') && dealItemRec.Customer_Owned_Unit__c != null) {
                    unitSectionObj.DealItemObj.UnitOptionalFields = UnitProductTypeService.getUnitOptionalFieldsData(dealItemRec.Customer_Owned_Unit__r.Product_Type__c, dealItemRec.Customer_Owned_Unit__c);
                }
                this.UnitList.add(unitSectionObj);
            }
		}
	}
	
    public DealWrapper(Deal__c dealRec, List<Deal_Item__c> dealItems, List<CO_Line_Item__c> coliList, List<CO_Kit_Header__c> cokhList, 
    					List<Vendor_Order_Line_Item__c> specialOrderList, List<User> usersList, List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentRecList, 
    					Deal_Finance__c dealFinanceRec,  Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap) {
        this.DealInfo = new DealInfoWrapper(dealRec);
        this.UnitList = new List<UnitSectionWrapper>();
        this.TradeInsList = new List<DealItem>();
        this.DealDepositList = new List<CODeposit>();
        List<Deal_Unit_Price_Cost__c> dealUnitPriceList = new List<Deal_Unit_Price_Cost__c>();
        List<Option_Fee__c> optionAndFeeList = new List<Option_Fee__c>();
        
        Decimal stampDutyTotal = 0;
        for(Deal_Item__c dealItemRec : dealItems) {
            if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) { 
                this.TradeInsList.add(new DealItem(dealItemRec));
            } else {
                if(!dealItemIdToDKHListMap.containsKey(dealItemRec.Id)) {
                    dealItemIdToDKHListMap.put(dealItemRec.Id, new List<Deal_Kit_Header__c>());
                }
                UnitSectionWrapper unitSectionObj = new UnitSectionWrapper(dealItemRec, dealItemIdToDKHListMap.get(dealItemRec.Id));
                if((dealItemRec.Unit_Status__c == 'Temporary' || dealItemRec.Unit_Status__c == 'Required') && dealItemRec.Customer_Owned_Unit__c != null) {
                    unitSectionObj.DealItemObj.UnitOptionalFields = UnitProductTypeService.getUnitOptionalFieldsData(dealItemRec.Customer_Owned_Unit__r.Product_Type__c, dealItemRec.Customer_Owned_Unit__c);
                }
                this.UnitList.add(unitSectionObj);
                for(Deal_Unit_Price_Cost__c dealUnitPriceRec : dealItemRec.Deal_Unit_Prices_Costs__r){
                    dealUnitPriceList.add(dealUnitPriceRec);
                }
                for(List<Deal_Kit_Header__c> dealKitHeaderList : dealItemIdToDKHListMap.values()) {
                    for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderList) {
                        for(Option_Fee__c optionAndFeeRec : dealKitHeaderRec.Options_Fees__r) {
                            optionAndFeeList.add(optionAndFeeRec);
                        }
                    } 
                }
                stampDutyTotal += (dealItemRec.Stamp_Duty_Total__c != null) ? (dealItemRec.Stamp_Duty_Total__c).setScale(2, RoundingMode.HALF_UP) : 0;
            } 
        }
        this.DealSummaryObj = new DealSummary(dealUnitPriceList, optionAndFeeList, this.TradeInsList, stampDutyTotal);
        
        for(CO_Deposit__c coDepositRec : dealRec.CO_Deposits__r){
            DealDepositList.add(new CODeposit(coDepositRec));
        }
        this.UserList = new List<UserSettingCtrl.UserWrapper>();
        for(User userRecord : usersList){
            UserSettingCtrl.UserWrapper userWrapperRecord = new UserSettingCtrl.UserWrapper(userRecord.Name,userRecord.Email,false,userRecord.Id);
            UserList.add(userWrapperRecord);
        }
        
        this.DealUnresolvedFulfillmentList = new List<DealUnresolvedFulfillmentWrapper>();
        for(Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec : dealUnresolvedFulfillmentRecList){
            this.DealUnresolvedFulfillmentList.add(new DealUnresolvedFulfillmentWrapper(dealUnresolvedFulfillmentRec));
        }
        
        this.DealFinanceObj = new DealFinanceWrapper(dealFinanceRec);
        
        this.DealFulfillmentSectionObj = new DealFulfillmentSectionWrapper(coliList, cokhList, specialOrderList);
    }
    
    public DealWrapper(Deal__c dealRec, List<Deal_Item__c> dealItems) {
        this.DealInfo = new DealInfoWrapper(dealRec);
        this.UnitList = new List<UnitSectionWrapper>();
        this.DealFinanceObj = new DealFinanceWrapper();
        for(Deal_Item__c dealItemRec : dealItems) {
            this.UnitList.add(new UnitSectionWrapper(dealItemRec, new List<Deal_Kit_Header__c>()));
        }
    }
    
    public DealWrapper(Deal__c dealRec, Boolean isNewCO) {
        this.DealInfo = new DealInfoWrapper(dealRec, isNewCO);
        this.UnitList = new List<UnitSectionWrapper>();
        this.DealFinanceObj = new DealFinanceWrapper();
        for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
            this.UnitList.add(new UnitSectionWrapper(dealItemRec, isNewCO));
        }
    }

    public class DealInfoWrapper {  
        public String Id{get; set;}
        public String DealStatus{get; set;}
        public Boolean IsDealFulfilled{get; set;}
        public String DealType{get; set;}
        public String DeliveryDate{get; set;}
        public Decimal DownPayment{get; set;}
        public String DP360LeadId{get; set;}
        public String DP360LeadURL{get; set;}
        public String CoHeaderId{get; set;}
        public String AssignedTo{get; set;}
        public String UnitStatus{get; set;}
        public Decimal DealCommission{get; set;}
        public String Salesperson{get; set;}
        public String InvoiceId{get; set;}
        public String InvoiceNumber{get; set;}
        public String InsuranceProvider;
        public String InsurancePolicy;
        
        public Decimal UnitsTotal{get; set;}
        public Decimal PartsAndLabourTotals{get; set;}
        public Decimal FeesTotal{get; set;}
        public Decimal OtherProductsTotal{get; set;}
        public Decimal TradeInsTotal{get; set;}
        public Decimal StampDutyTotal{get; set;}
        public Decimal SubTotal{get; set;}
        public Decimal FIProductTotal{get; set;}
        public Decimal FIProductTaxTotal{get; set;}
        public Decimal SalesTaxesTotal{get; set;}
        public Decimal Total{get; set;}
        public Decimal LienPayoutTotal{get; set;}
        
        public Decimal OrderTotal{get; set;}
        public Decimal InvoicedAmount{get; set;}
        public Decimal UninvoicedAmount{get; set;}
        public Boolean isTradeStockInActionAvailable{get; set;}
        public Boolean IsInvoiceItemActive {get; set;}
        public Decimal PreTaxTotal;
        public Boolean isDealSectionTradeOnly; 
	    public String InvoiceDate;
        public List<String> NotesForCustomer;
        public String CoBuyerId{get; set;}
        public String CoBuyerName{get; set;}        
        public String CoBuyerDOB{get; set;}
        public String CoBuyerDriverLicence{get; set;} 
        public String CoBuyerFirstName{get; set;}
        public String CoBuyerLastName{get; set;}
        public Boolean IsTaxBasedOnCustomerAddress{get; set;}
	    
	    public DealInfoWrapper(Deal__c dealInfoRec, Boolean isNewCO) {
            setDealBasicFields(dealInfoRec);
        }

        private void setDealBasicFields(Deal__c dealInfoRec) {
            this.Id = dealInfoRec.Id;
            this.DealStatus = dealInfoRec.Status__c;
            this.DealType = dealInfoRec.Type__c;
        }
        
        public DealInfoWrapper(Deal__c dealInfoRec){
            setDealBasicFields(dealInfoRec);
            if(dealInfoRec.Delivery_Date__c != null){
                this.DeliveryDate =  BPUtility.getFormatedDateTime(datetime.newInstance(dealInfoRec.Delivery_Date__c.year(), dealInfoRec.Delivery_Date__c.month(),dealInfoRec.Delivery_Date__c.day()));
            }
            this.IsTaxBasedOnCustomerAddress = dealInfoRec.Is_Tax_Based_On_Customer_Address__c;
            this.DownPayment = (dealInfoRec.Down_Payment__c != null) ? dealInfoRec.Down_Payment__c : 0;
            this.DealCommission = (dealInfoRec.Deal_Commission__c != null) ? dealInfoRec.Deal_Commission__c : 0;
            
            this.CoHeaderId = dealInfoRec.CO_Header__c;
            this.AssignedTo = dealInfoRec.CO_Header__r.Owner.Name;
            this.UnitStatus = dealInfoRec.Unit_Status__c;
            this.IsDealFulfilled = dealInfoRec.Is_Deal_Fulfilled__c;
            this.UnitsTotal = dealInfoRec.Unit_Price_And_Cost_Total__c  != null ? dealInfoRec.Unit_Price_And_Cost_Total__c : 0;
            this.PartsAndLabourTotals = (dealInfoRec.Part_Total__c  != null ? dealInfoRec.Part_Total__c : 0) + (dealInfoRec.Labour_Total__c  != null ? dealInfoRec.Labour_Total__c : 0);
            this.FeesTotal = dealInfoRec.Fee_Total__c  != null ? dealInfoRec.Fee_Total__c : 0;
            this.TradeInsTotal = dealInfoRec.Trade_In_Total__c  != null ? dealInfoRec.Trade_In_Total__c : 0;
            this.FIProductTotal = dealInfoRec.F_I_Total__c  != null ? dealInfoRec.F_I_Total__c : 0;
            this.FIProductTaxTotal = dealInfoRec.F_I_Tax_Total__c  != null ? dealInfoRec.F_I_Tax_Total__c : 0;
            this.StampDutyTotal = dealInfoRec.Stamp_Duty_Total__c  != null ? dealInfoRec.Stamp_Duty_Total__c : 0;
            this.OtherProductsTotal = dealInfoRec.Product_Total__c  != null ? dealInfoRec.Product_Total__c : 0;
            this.SubTotal = dealInfoRec.Subtotal__c  != null ? dealInfoRec.Subtotal__c : 0;
            this.SalesTaxesTotal = dealInfoRec.Deal_Tax_Total__c  != null ? dealInfoRec.Deal_Tax_Total__c : 0;
            this.Total = dealInfoRec.Deal_Total__c  != null ? dealInfoRec.Deal_Total__c : 0;
            this.LienPayoutTotal = (dealInfoRec.Lien_Payout_Total__c != null) ? dealInfoRec.Lien_Payout_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
            
            this.OrderTotal = (dealInfoRec.CO_Header__r.Order_Total__c != null) ? dealInfoRec.CO_Header__r.Order_Total__c : 0;
            this.InvoicedAmount = (dealInfoRec.CO_Header__r.Invoiced_Amount__c != null) ? dealInfoRec.CO_Header__r.Invoiced_Amount__c : 0;
            this.UninvoicedAmount = (dealInfoRec.CO_Header__r.Uninvoiced_Amount__c != null) ? dealInfoRec.CO_Header__r.Uninvoiced_Amount__c : 0;
            this.DP360LeadId = dealInfoRec.DP360_Lead_Id__c;
            this.DP360LeadURL = dealInfoRec.DP360_Lead_URL__c;
            this.Salesperson =  dealInfoRec.Salesperson_Name__c;
            this.InvoiceNumber = dealInfoRec.Invoice_Number__r.Invoice_Number__c;
            this.InvoiceId = dealInfoRec.Invoice_Number__c;
            this.IsInvoiceItemActive = dealInfoRec.CO_Invoice_Items__r.size() > 0 ? dealInfoRec.CO_Invoice_Items__r[0].Is_Invoiceable__c && dealInfoRec.CO_Invoice_Items__r[0].isActive__c : false;
	    	this.InsuranceProvider = dealInfoRec.Insurance_Provider__c;
            this.InsurancePolicy = dealInfoRec.Insurance_Policy__c;

	    	if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Category__c> defaultStockedTradeCategoryList = [SELECT AccountingId__c, Income_GL__c FROM Category__c WHERE Type__c = 'Stocked Trade' AND Default__c = true AND Active__c = true];
            this.isTradeStockInActionAvailable = 
                String.isBlank(Accounting_Settings__c.getOrgDefaults().Provider_Name__c) || Accounting_Settings__c.getOrgDefaults().Provider_Name__c == 'No Integration' 
	               || (defaultStockedTradeCategoryList.size() > 0 && 
			             ((Accounting_Settings__c.getOrgDefaults().Provider_Name__c == 'Xero' && String.isNotBlank(defaultStockedTradeCategoryList[0].Income_GL__c)) 
							|| (String.isNotBlank(defaultStockedTradeCategoryList[0].AccountingId__c)))
					   );
					   
            this.PreTaxTotal = ((dealInfoRec.Pre_Tax_Unit_Price_And_Cost_Total__c != null ? dealInfoRec.Pre_Tax_Unit_Price_And_Cost_Total__c : 0) + 
        					   (dealInfoRec.F_I_Total__c != null ? dealInfoRec.F_I_Total__c : 0) + 
        					   (dealInfoRec.Pre_Tax_Fee_Total__c != null ? dealInfoRec.Pre_Tax_Fee_Total__c : 0) + 
        					   (dealInfoRec.Pre_Tax_Labour_Total__c != null ? dealInfoRec.Pre_Tax_Labour_Total__c : 0) + 
        				       (dealInfoRec.Pre_Tax_Other_Product_Total__c != null ? dealInfoRec.Pre_Tax_Other_Product_Total__c : 0) + 
        					   (dealInfoRec.Pre_Tax_Part_Total__c != null ? dealInfoRec.Pre_Tax_Part_Total__c : 0)).setScale(2, RoundingMode.HALF_UP);                                       
        	this.isDealSectionTradeOnly = dealInfoRec.Deal_Section_Trade_Only__c;
        	
        	if(dealInfoRec.Invoice_Number__r.Invoice_Date__c != null) {
                this.InvoiceDate =  BPUtility.getFormatedDateTime(dealInfoRec.Invoice_Number__r.Invoice_Date__c);
            } else {
                this.InvoiceDate =  BPUtility.getFormatedDateTime(system.now());
            }
            this.NotesForCustomer = (dealInfoRec.Notes_For_Customer__c != null) ?  dealInfoRec.Notes_For_Customer__c.split('\n') : new List<String>();
            
            this.CoBuyerId = dealInfoRec.Co_Buyer__c;
            this.CoBuyerName = dealInfoRec.Co_Buyer__c != null ? dealInfoRec.Co_Buyer__r.Name : '';
            this.CoBuyerDOB = (dealInfoRec.Co_Buyer__c != null && dealInfoRec.Co_Buyer__r.Birth_Date__c != null) ? 
            	BPUtility.getFormatedDateTime(datetime.newInstance(dealInfoRec.Co_Buyer__r.Birth_Date__c.year(), 
            	dealInfoRec.Co_Buyer__r.Birth_Date__c.month(),dealInfoRec.Co_Buyer__r.Birth_Date__c.day())): '';
            	
            this.CoBuyerDriverLicence = dealInfoRec.Co_Buyer__c != null ? dealInfoRec.Co_Buyer__r.Drivers_License__c : '';
            this.CoBuyerFirstName = dealInfoRec.Co_Buyer__c != null ? dealInfoRec.Co_Buyer__r.FirstName__c : '';
            this.CoBuyerLastName = dealInfoRec.Co_Buyer__c != null ? dealInfoRec.Co_Buyer__r.LastName__c : '';
        }
    }
    
   public class UnitSectionWrapper {    
        public DealItem DealItemObj{get; set;}
        public List<OptionAndFeeInfo> OptionAndFeeList{get; set;} 
        public List<DealKitHeader> DealKitHeaderList {get; set;}
        public List<FactoryOption> FactoryOptionList {get; set;}
        public List<DealerInstalledOption> DealerInstalledOptionList {get; set;}
        public List<BaseUnitPrice> BasePriceList{get; set;}
        public Decimal TotalOptionAndFee{get; set;}
        public Decimal TotalFee{get; set;}
        public Decimal TotalOptionAndFeeWithKit{get; set;}
        public Decimal TotalPartAndLabor{get; set;}
        public Decimal TotalSublet{get; set;}
        public Decimal TotalFactoryOption{get; set;}
        public Decimal TotalDealerInstalledOption{get; set;}
        public Decimal TotalBasePrice{get; set;}
        public Decimal TotalStampDuty{get; set;}
        public Decimal Total{get; set;}
        public SO_KLI_Recalculation.Errorhandler error{get; set;}
        public Decimal TotalEnforceRideawayPrice{get; set;}
        public Boolean IsRideawayPricingEnabled{get; set;}
        public Boolean IsLockInUnitPricing;
        public String DeliveryDate;
        public Decimal SalesTaxTotal;
        public Boolean IsDealFulfilled;
        
        public UnitSectionWrapper(Deal_Item__c dealItemRec, Boolean isNewCO) {
            this.DealItemObj = new DealItem();
            this.DealItemObj.Id = dealItemRec.Id;
        }
        
        public UnitSectionWrapper(Deal_Item__c dealItemRec, List<Deal_Kit_Header__c> dealKitHeaderList) {
            this.DealItemObj = new DealItem(dealItemRec);
            this.OptionAndFeeList = new List<OptionAndFeeInfo>();
            this.DealKitHeaderList = new List<DealKitHeader>();
            this.FactoryOptionList = new List<FactoryOption>();
            this.BasePriceList = new List<BaseUnitPrice>();
            this.DealerInstalledOptionList = new List<DealerInstalledOption>();
            this.FactoryOptionList = new List<FactoryOption>();
            
            this.IsRideawayPricingEnabled = dealItemRec.Is_Rideaway_Pricing_Enabled__c;
            this.IsLockInUnitPricing = dealItemRec.Is_Lock_In_Unit_Pricing__c;
            this.TotalEnforceRideawayPrice = 0;
            this.TotalOptionAndFee = 0;
            this.TotalOptionAndFeeWithKit = 0;
            this.TotalPartAndLabor = 0;
            this.TotalSublet = 0;
            this.TotalFee = 0;
            this.TotalFactoryOption = 0;
            this.TotalDealerInstalledOption = 0;
            this.TotalBasePrice = 0;
            this.SalesTaxTotal = 0;
            this.TotalStampDuty = (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c : 0;
            this.TotalEnforceRideawayPrice= (dealItemRec.Rideaway_Pricing_Total__c != null) ? dealItemRec.Rideaway_Pricing_Total__c : 0;
            
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                OptionAndFeeInfo optionAndFeeObj = new OptionAndFeeInfo(optionAndFeeRec);
                this.TotalOptionAndFee += optionAndFeeObj.Total;
                /*if(optionAndFeeRec.Part__c != null || optionAndFeeRec.Labour_Code__c != null) {
                    this.TotalPartAndLabor += optionAndFeeObj.Total;
                }*/
                this.OptionAndFeeList.add(optionAndFeeObj);
            }
            this.TotalOptionAndFeeWithKit = this.TotalOptionAndFee;
            
            this.DealKitHeaderList = getDealKitHeaderList(dealItemRec.Options_Fees__r, dealKitHeaderList);
            
            // Add Kit - Parts and Labor totals - Added by TK
            for(DealKitHeader kitHeaderObj : this.DealKitHeaderList) {
                for(OptionAndFeeInfo optionFeeObj : kitHeaderObj.OptionAndFeeList) {
                    if(optionFeeObj.PartId != null || optionFeeObj.LabourId != null) {
                        this.TotalPartAndLabor += optionFeeObj.Total;
                    } else if(String.isNotBlank(optionFeeObj.FeeId)) {
						this.TotalFee += optionFeeObj.Total;
					} else if(optionFeeObj.ProductId != null && optionFeeObj.ProductType == 'Sublet') {
					    this.TotalSublet += optionFeeObj.Total;
					}
                    if(optionFeeObj.KitHeaderId != null) {
                        this.TotalOptionAndFeeWithKit += optionFeeObj.Total;
                    }
                }
            }
            
            for(Deal_Unit_Price_Cost__c DealUnitpriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r){
                if(DealUnitpriceCostRec.Type__c == 'Factory'){
                    this.FactoryOptionList.add(new FactoryOption(DealUnitpriceCostRec));
                    this.TotalFactoryOption += (DealUnitpriceCostRec.Total_Price__c != null) ? DealUnitpriceCostRec.Total_Price__c : 0;
                } else if(DealUnitpriceCostRec.Type__c == 'Dealer') {
                    this.DealerInstalledOptionList.add(new DealerInstalledOption(DealUnitpriceCostRec));
                    this.TotalDealerInstalledOption += (DealUnitpriceCostRec.Total_Price__c != null) ? DealUnitpriceCostRec.Total_Price__c : 0;
                } else if(DealUnitpriceCostRec.Type__c == 'Base') {
                    BaseUnitPrice baseUnitPriceObj = new BaseUnitPrice(DealUnitpriceCostRec);
                    this.BasePriceList.add(baseUnitPriceObj);
                    this.TotalBasePrice += baseUnitPriceObj.Price;
                }
            }
            this.Total = this.TotalOptionAndFeeWithKit + this.TotalBasePrice + this.TotalDealerInstalledOption + this.TotalFactoryOption + this.TotalStampDuty;
            this.DeliveryDate = dealItemRec.Deal__r.Delivery_Date__c != null ? BPUtility.getFormatedDateTime(datetime.newInstance(dealItemRec.Deal__r.Delivery_Date__c.year(), dealItemRec.Deal__r.Delivery_Date__c.month(),dealItemRec.Deal__r.Delivery_Date__c.day())): '';
            this.SalesTaxTotal = (dealItemRec.Deal__r.Sales_Tax_Total__c != null ? dealItemRec.Deal__r.Sales_Tax_Total__c : 0);
            this.error = (COService.error != null) ? COService.error : new SO_KLI_Recalculation.Errorhandler('200', 'Success');
            this.IsDealFulfilled = dealItemRec.Deal__r.Is_Deal_Fulfilled__c;
        }
    }
    
    
    public class FactoryOption{
        public String Id{get; set;}
        public String ItemDescription {get; set;}
        public Decimal Qty{get; set;}
        public Decimal Price {get; set;}
        public Decimal TotalPrice{get; set;}
        public String  Type{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public Decimal SalesTax{get; set;}
        
        public FactoryOption(Deal_Unit_Price_Cost__c factoryOption){
            this.Id = factoryOption.Id;
            this.ItemDescription = factoryOption.Item_Description__c;
            this.Qty = (factoryOption.Qty__c != null) ? factoryOption.Qty__c : 0.00;
            this.Type = factoryOption.Type__c;
            this.Price = ((factoryOption.Price__c != null) ? factoryOption.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            this.SalesTaxPercentage = ((factoryOption.Sales_Tax_Percentage__c != null) ? factoryOption.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.TotalPrice = ((factoryOption.Total_Price__c != null) ? factoryOption.Total_Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            
            this.SalesTax = ((this.SalesTaxPercentage * this.Price) / 100).setScale(2, RoundingMode.HALF_UP);
            if(isTaxIncludingPricing) {
                this.Price = (factoryOption.Price_When_Tax_Included__c != null) ? (factoryOption.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : this.Price + this.SalesTax;
                this.TotalPrice = (this.Price * this.Qty);
                this.SalesTax = 0;
            }   
        }       
    
    }
    public class DealerInstalledOption{
        public String Id{get; set;}
        public String ItemDescription {get; set;}
        public Decimal Qty{get; set;}
        public Decimal Price{get; set;}
        public Decimal TotalPrice {get; set;}
        public String  Type{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public Decimal SalesTax{get; set;}
        
        public DealerInstalledOption(Deal_Unit_Price_Cost__c dealerOption){
            this.Id = dealerOption.Id;
            this.ItemDescription = dealerOption.Item_Description__c;
            this.Qty = (dealerOption.Qty__c != null) ? dealerOption.Qty__c : 0.00;
            this.Price = ((dealerOption.Price__c != null) ? dealerOption.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.Type = dealerOption.Type__c;
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            this.SalesTaxPercentage = ((dealerOption.Sales_Tax_Percentage__c != null) ? dealerOption.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.TotalPrice = ((dealerOption.Total_Price__c != null) ? dealerOption.Total_Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.SalesTax = ((this.SalesTaxPercentage * this.Price) / 100).setScale(2, RoundingMode.HALF_UP);
            
            if(isTaxIncludingPricing) {
                this.Price = (dealerOption.Price_When_Tax_Included__c != null) ? (dealerOption.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : this.Price + this.SalesTax;
                this.TotalPrice = (this.Price * this.Qty);
                this.SalesTax = 0;
            }  
        }
    }
    
    public class BaseUnitPrice{
        public String Id{get; set;}
        public String ItemDescription{get; set;}
        public Decimal Qty{get; set;}
        public Decimal Price{get; set;}
        public Decimal TotalPrice{get; set;}
        public String Type{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public Decimal SalesTax{get; set;}
        
        public BaseUnitPrice() {
            
        }
        
        public BaseUnitPrice(Deal_Unit_Price_Cost__c baseUnitPrice){
            this.Id = baseUnitPrice.Id;
            this.ItemDescription = baseUnitPrice.Item_Description__c;
            this.Qty = baseUnitPrice.Qty__c;
            this.Price = ((baseUnitPrice.Price__c != null) ? baseUnitPrice.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.Type = baseUnitPrice.Type__c;
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            this.SalesTaxPercentage = ((baseUnitPrice.Sales_Tax_Percentage__c != null) ? baseUnitPrice.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.TotalPrice = ((baseUnitPrice.Total_Price__c != null) ? baseUnitPrice.Total_Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.SalesTax = ((this.SalesTaxPercentage * this.Price) / 100).setScale(2, RoundingMode.HALF_UP);
            
            if(isTaxIncludingPricing) {
                this.Price = (baseUnitPrice.Price_When_Tax_Included__c != null) ? (baseUnitPrice.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : this.Price + this.SalesTax;
                this.TotalPrice = (this.Price * this.Qty);
                this.SalesTax = 0;
            }  
        }
    
    }
    public class OptionAndFeeInfo { 
        public String Id{get; set;}
        public String DealId{get; set;}
        public String DealItemId{get; set;}
        public Decimal Qty {get; set;}
        public String PartId{get; set;}
        public Boolean IsForeignVendor {get; set;}
        public String FeeId{get; set;}
        public String LabourId{get; set;}
        public String KitHeaderId{get; set;}
        public Decimal Price {get; set;}
        public String Status{get; set;}
        public String OptionStatus{get; set;}
        public String ItemDescription{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public Boolean IsInstall{get; set;}
        public Decimal Total {get; set;}
        public Decimal SalesTax{get; set;}
        public String ProductId{get; set;}
        public String ProductType{get; set;}
        public String ItemCode{get; set;}
        public String Item {get; set;}
        public Decimal FixedPrice{get; set;}
        public Boolean IsFixedPrice{get; set;}
        public Boolean IsFixedPriceForCO{get; set;}
        public Boolean IsEnvFee{get; set;}
        public String UUID;
        public Boolean IsNonInventoryPart;

        public OptionAndFeeInfo(Option_Fee__c optionAndFeeRec){
            this.Id = optionAndFeeRec.Id;
            this.DealId = optionAndFeeRec.Deal__c;
            this.DealItemId = optionAndFeeRec.Deal_Item__c;
            this.Qty = optionAndFeeRec.Qty__c;
            this.PartId = optionAndFeeRec.Part__c;
            if(optionAndFeeRec.Part__c != null) {
                this.IsForeignVendor = optionAndFeeRec.Part__r.Vendor__r.Is_Foreign_Vendor__c;
            }
            this.FeeId = optionAndFeeRec.Fee__c;
            this.LabourId = optionAndFeeRec.Labour_Code__c;
            this.ProductId = optionAndFeeRec.Product__c;
            this.KitHeaderId = optionAndFeeRec.Deal_Kit_Header__c;
            this.IsFixedPrice = (optionAndFeeRec.Is_Fixed_Price__c == null) ? false : optionAndFeeRec.Is_Fixed_Price__c;
            this.IsFixedPriceForCO = (optionAndFeeRec.Is_Fixed_Kit_Line_Item_CO__c == null) ? false : optionAndFeeRec.Is_Fixed_Kit_Line_Item_CO__c  ;
            this.FixedPrice = optionAndFeeRec.Fixed_Price__c;
                        
            if(optionAndFeeRec.Part__c != null) {
                if(optionAndFeeRec.Part__r.Non_Inventory_Part__c) {
                    this.ItemCode = (optionAndFeeRec.Item_Code__c != null) ? optionAndFeeRec.Item_Code__c : '';
                    this.ItemDescription = (optionAndFeeRec.Item_Description__c != null) ? optionAndFeeRec.Item_Description__c : '';
                } else {
                    this.ItemCode = (optionAndFeeRec.Part__r.Part_Number__c != null) ? optionAndFeeRec.Part__r.Part_Number__c : '';
                    this.ItemDescription = (optionAndFeeRec.Part__r.Description__c != null) ? optionAndFeeRec.Part__r.Description__c : '';
                }
                if(optionAndFeeRec.Qty__c < 0) {
                    this.Status = 'Return';
                } else if(optionAndFeeRec.Status__c == 'Fulfilled') {
                    this.Status = optionAndFeeRec.Status__c;
                } else if(optionAndFeeRec.CO_Line_Item__c != null) {
                    this.Status = COLIWrapper.getPartCOLIStatus(optionAndFeeRec.CO_Line_Item__r);
                } else if(optionAndFeeRec.Service_Order_Line_Item__c != null && optionAndFeeRec.Service_Order_Line_Item__r.CO_Line_Item__c != null) {
	    			this.Status = COLIWrapper.getPartCOLIStatus(optionAndFeeRec.Service_Order_Line_Item__r.CO_Line_Item__r);
                } else if((optionAndFeeRec.Part__r.AvailableParts__c > 0) || optionAndFeeRec.Part__r.Non_Inventory_Part__c) {
                    this.Status = 'In Stock';
                } else {
                    this.Status = 'Required';
                }
            } else {
                this.ItemCode = (optionAndFeeRec.Item_Code__c != null) ? optionAndFeeRec.Item_Code__c : '';
                this.ItemDescription = (optionAndFeeRec.Item_Description__c != null) ? optionAndFeeRec.Item_Description__c : '';
            }
            this.OptionStatus = setOptionStatus(optionAndFeeRec);
            this.Item = this.ItemCode + ' - ' + this.ItemDescription;
            this.ProductType = optionAndFeeRec.Product__r.Type__c;
            if(String.isNotBlank(this.LabourId) || (String.isNotBlank(this.ProductId) && this.ProductType == Constants.SUBLET)) {
                this.IsInstall = true;
            } else {
                this.IsInstall = optionAndFeeRec.Is_Install__c;
            }
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            this.Price = (optionAndFeeRec.Price__c != null) ? optionAndFeeRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.SalesTaxPercentage = optionAndFeeRec.Sales_Tax_Percentage__c != null ? optionAndFeeRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP) : 0.00;
            if(isTaxIncludingPricing) {
                this.Price = (optionAndFeeRec.Price_When_Tax_Included__c != null) ? optionAndFeeRec.Price_When_Tax_Included__c.setScale(2, RoundingMode.HALF_UP) :(this.Price * (1 + this.SalesTaxPercentage /100)).setScale(2, RoundingMode.HALF_UP);
            }           
            this.Total = 0;
            this.SalesTax = 0;
            if(this.Price == null) {
                this.Price = 0;
            }
            if(this.Qty == null) {
                this.Qty = 0;
            }
            if(optionAndFeeRec.Price__c == null) {
                optionAndFeeRec.Price__c = 0;
            }
            this.Total = this.Price * this.Qty;
            this.SalesTax = (this.Qty * optionAndFeeRec.Price__c * this.SalesTaxPercentage / 100);
            
            this.SalesTax = this.SalesTax.setScale(2, RoundingMode.HALF_UP);
            this.Total = this.Total.setScale(2, RoundingMode.HALF_UP);
            this.Price = this.Price.setScale(2, RoundingMode.HALF_UP);
            this.IsEnvFee = optionAndFeeRec.Is_Environmental_Fee__c;
            this.UUID = optionAndFeeRec.UUID__c;
            this.IsNonInventoryPart = optionAndFeeRec.Part__r.Non_Inventory_Part__c;
        }

        private String setOptionStatus(Option_Fee__c optionAndFeeRec) {
            if(optionAndFeeRec.Status__c == 'Fulfilled') {
                return Constants.FULFILLED;
            } else if(DealService.isOptionCommitable(optionAndFeeRec)) {
                if(DealService.isOptionCommitted(optionAndFeeRec)) {
                return Constants.COMMITTED;
            } else {
                return Constants.UNCOMIITTED;
            }
        }
            return null;    //For non committable options
        }
    }
    
    public class DealKitHeader {
        
        public List<OptionAndFeeInfo> OptionAndFeeList {get; set;}
        public Decimal Price {get; set;}
        public String ItemDescription {get; set;}
        public Boolean CanItSplit{get; set;}
        public String Code{get; set;}
        public Boolean IsServiceKit{get; set;}
        public Boolean IsInstall{get; set;}
        public String Id{get; set;}
        public String CoHeaderId{get; set;}
        public Decimal FixedPrice{get; set;} 
        public Decimal RetailPrice{get; set;}
        public Boolean IsFixedPrice{get; set;} 
        public Boolean hasChildren {get; set;}
        public Decimal ActualKitPrice{get; set;}
        public Boolean IsFixedPriceForCO{get; set;}
        public Decimal TaxAmount{get; set;}
        public String DealItemId{get; set;}
        public String UUID;
        
        public DealKitHeader(Deal_Kit_Header__c dealKitHeaderRec, List<Option_Fee__c> optionAndFeeRecList, Boolean hasChild) {
            this.hasChildren = hasChild;
            this.TaxAmount = dealKitHeaderRec.Tax_Amount__c;
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            if(dealKitHeaderRec.Fixed_Price__c == null) {
                dealKitHeaderRec.Fixed_Price__c = 0;
            }
            if(dealKitHeaderRec.Tax_Amount__c == null) {
                dealKitHeaderRec.Tax_Amount__c = 0;
            }
            this.Price = (dealKitHeaderRec.Fixed_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.TaxAmount = (dealKitHeaderRec.Tax_Amount__c).setScale(2, RoundingMode.HALF_UP);
            
            this.IsInstall = dealKitHeaderRec.Is_Install__c;
            this.ItemDescription = dealKitHeaderRec.Kit_Header__r.Kit_Unique_Name__c;
            this.Id = dealKitHeaderRec.Id;
            this.IsServiceKit = (dealKitHeaderRec.Service_Kit__c == null) ? false : dealKitHeaderRec.Service_Kit__c;
            this.IsFixedPrice = (dealKitHeaderRec.Is_Fixed_Price__c == null) ? false : dealKitHeaderRec.Is_Fixed_Price__c;
            this.IsFixedPriceForCO = (dealKitHeaderRec.Is_Fixed_Kit_Header_CO__c == null) ? false : dealKitHeaderRec.Is_Fixed_Kit_Header_CO__c;
            this.CanItSplit = dealKitHeaderRec.Can_Split__c;
            this.ActualKitPrice = (dealKitHeaderRec.Actual_Kit_Price__c != null) ? dealKitHeaderRec.Actual_Kit_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.CoHeaderId = dealKitHeaderRec.Deal_Item__r.Deal__r.Co_Header__c;
            this.OptionAndFeeList = new List<OptionAndFeeInfo>();
            
            for(Option_Fee__c optionAndFeeRec : optionAndFeeRecList) {
                this.OptionAndFeeList.add(new OptionAndFeeInfo(optionAndFeeRec));
            }
            this.DealItemId = dealKitHeaderRec.Deal_Item__c;
            this.UUID = (dealKitHeaderRec != null && dealKitHeaderRec.Id != null) ? dealKitHeaderRec.UUID__c : (optionAndFeeRecList.size() > 0 ? optionAndFeeRecList[0].UUID__c : null);
        }
    }
    
    public class DealSummary {  
        public Decimal UnitsTotal{get; set;}
        public Decimal TradeInsTotal{get; set;}
        public Decimal PartsAndLabourTotals{get; set;}
        public Decimal OtherProductsTotal{get; set;}
        public Decimal FeesTotal{get; set;}
        public Decimal StampDutyTotal{get; set;}
        public Decimal SalesTaxesTotal{get; set;} 
        public Decimal Total{get; set;}
        public Boolean IsTaxIncludingPricing{get; set;}
        
        public DealSummary(List<Deal_Unit_Price_Cost__c> dealUnitPriceList, List<Option_Fee__c> optionAndFeeList, 
                              List<DealItem> tradeInsList, Decimal stampDutyTotal){
            this.UnitsTotal = 0;
            this.PartsAndLabourTotals = 0;
            this.FeesTotal = 0;
            this.SalesTaxesTotal = 0;
            this.OtherProductsTotal = 0;
            this.Total = 0;
            this.TradeInsTotal = 0;
            this.StampDutyTotal = 0;
            
            this.IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.StampDutyTotal = (stampDutyTotal != null) ? stampDutyTotal : 0;
            for(Deal_Unit_Price_Cost__c dealUnitPriceRec : dealUnitPriceList){
                this.UnitsTotal += dealUnitPriceRec.Total_Price__c;
                
                if(this.IsTaxIncludingPricing) {
                    this.SalesTaxesTotal += dealUnitPriceRec.Total_Price__c - (dealUnitPriceRec.Total_Price__c / (1 + (dealUnitPriceRec.Tax_Percent__c / 100))).setScale(2, RoundingMode.HALF_UP);
                } else {
                    this.SalesTaxesTotal += ((dealUnitPriceRec.Total_Price__c * dealUnitPriceRec.Tax_Percent__c)/100).setScale(2, RoundingMode.HALF_UP);
                }
            }
            for(Option_Fee__c optionAndFeeRec : optionAndFeeList){
                optionAndFeeRec.Qty__c = (optionAndFeeRec.Qty__c == null) ? 0 : optionAndFeeRec.Qty__c;
                optionAndFeeRec.Price__c = (optionAndFeeRec.Price__c == null) ? 0 : optionAndFeeRec.Price__c;
                if(optionAndFeeRec.Part__c != null || optionAndFeeRec.Labour_Code__c != null){
                    this.PartsAndLabourTotals += optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c;
                } else if(optionAndFeeRec.Fee__c != null){
                    this.FeesTotal += optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c;
                } else if(String.isNotBlank(optionAndFeeRec.Product__c)) {
                    this.OtherProductsTotal += optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c;
                }
                if(optionAndFeeRec.Qty__c != null && optionAndFeeRec.Price__c != null && optionAndFeeRec.Sales_Tax_Percentage__c != null) {
                    this.SalesTaxesTotal += (optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c * optionAndFeeRec.Sales_Tax_Percentage__c)/100;
                }
            }
            
            for(DealItem tradeInRec : tradeInsList) {
                this.TradeInsTotal += (tradeInRec.AgreedValue != null) ? tradeInRec.AgreedValue : 0;
                //Added by Nidhi - 02-12-2016
                this.SalesTaxesTotal -= (tradeInRec.SalesTax != null) ? tradeInRec.SalesTax : 0;
            }
            
            this.TradeInsTotal = (this.TradeInsTotal.setScale(2, RoundingMode.HALF_UP) * -1);
            this.UnitsTotal = this.UnitsTotal.setScale(2, RoundingMode.HALF_UP);
            this.PartsAndLabourTotals = this.PartsAndLabourTotals.setScale(2, RoundingMode.HALF_UP);
            this.FeesTotal = this.FeesTotal.setScale(2, RoundingMode.HALF_UP);
            this.SalesTaxesTotal = this.SalesTaxesTotal.setScale(2, RoundingMode.HALF_UP);
            this.OtherProductsTotal = this.OtherProductsTotal.setScale(2, RoundingMode.HALF_UP);
            this.Total = (this.UnitsTotal + this.PartsAndLabourTotals + this.FeesTotal + this.OtherProductsTotal + this.TradeInsTotal).setScale(2, RoundingMode.HALF_UP);
            if(!this.IsTaxIncludingPricing) {
                this.Total += this.SalesTaxesTotal;
            }
            if(GeneralConfiguration.getCompanyLocale() == 'Australia') {
                this.Total += this.StampDutyTotal;
            }
        }
    }
    
    public class DealFulfillmentSectionWrapper {    
        public List<COHeaderWrapper.COKitHeader> DealMerchandiseList;
        public List<COHeaderWrapper.SpecialOrder> DealSpecialOrderList;
        public Decimal MerchandiseTotal;
        public String SpecialOrderStatus;
        
        //Do not call this wrapper class from a loop
        public DealFulfillmentSectionWrapper(List<CO_Line_Item__c> coliList, List<CO_Kit_Header__c> cokhList, List<Vendor_Order_Line_Item__c> specialOrderList){
            this.DealMerchandiseList = new List<COHeaderWrapper.COKitHeader>();
            this.DealMerchandiseList = COHeaderWrapper.getCOLineItemsList(coliList, cokhList);
            this.MerchandiseTotal = 0;
            if(!coliList.isEmpty() || !cokhList.isEmpty()) {
                String coHeaderId = !coliList.isEmpty() ? coliList[0].CO_Header__c : (!cokhList.isEmpty() ? cokhList[0].CO_Header__c : null);
                if(String.isNotBlank(coHeaderId)) {
                    for(CO_Section_Detail__c sectionDetail : [Select Special_Order_Status__c FROM CO_Section_Detail__c Where CO_Header__c =: coHeaderId AND Section_Type__c =: COSectionDetailService.DEAL_MERCHANDISE LIMIT 1]) {
                        this.SpecialOrderStatus = sectionDetail.Special_Order_Status__c;
                    }
                }
            }
            for(CO_Line_Item__c coliRec : coliList) {
                if(coliRec.Qty__c == null) {
                    coliRec.Qty__c = 0;
                }
                if(coliRec.Price__c == null) {
                    coliRec.Price__c = 0;
                }
                this.MerchandiseTotal += (coliRec.Qty__c * coliRec.Price__c);
            }
            
            for(CO_Kit_Header__c cokhRec : cokhList) {
                this.MerchandiseTotal += (cokhRec.Price__c == null) ? 0 : cokhRec.Price__c;
            }
            this.MerchandiseTotal = this.MerchandiseTotal.setScale(2, RoundingMode.HALF_UP);
            this.DealSpecialOrderList = new List<COHeaderWrapper.SpecialOrder>();
            for(Vendor_Order_Line_Item__c specialOrderRec : specialOrderList) {
                this.DealSpecialOrderList.add(new COHeaderWrapper.SpecialOrder(specialOrderRec));
            }
        }
    }
    
    public class DealUnresolvedFulfillmentWrapper { 
        public String Id;
        public String Type;
        public Decimal ActualQty;
        public Decimal UpdatedQty;
        public String DealId;
        public String DealItemId;
        public String DealMerchandiseLineItemId;
        public String DealServiceLineItemId;
        public String OptionAndFeeId;
        public String ChargeMethod;
        public String ActionRequired;
        public String UnitId;
        public String StockId;
        public String ItemCode;
        public String ItemDescription;
        public String COKitHeaderId;
        public String SOKitHeaderId;
        public String DealKitHeaderId;
        public String RequiredForUnit;
        public String User;
        public String PartId;
        public String LabourId;
        public String FeeId;
        public String SubletId;
        public String KitHeaderId;
        public String RelatedStockIds;
        public List<String> RelatedOptionAndFeeIdList;
        public SO_KLI_Recalculation.Errorhandler error;
        
        public DealUnresolvedFulfillmentWrapper() {
            this.error = COService.error;
        }
        
        public DealUnresolvedFulfillmentWrapper(Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentObj){ 
            this.Id = dealUnresolvedFulfillmentObj.Id;
            this.Type = dealUnresolvedFulfillmentObj.Type__c;
            this.ActualQty = dealUnresolvedFulfillmentObj.Actual_Quantity__c;
            this.UpdatedQty = dealUnresolvedFulfillmentObj.Updated_Quantity__c;
            this.DealId = dealUnresolvedFulfillmentObj.Deal__c;
            this.DealItemId = dealUnresolvedFulfillmentObj.Deal_Item__c;
            this.DealMerchandiseLineItemId = dealUnresolvedFulfillmentObj.CO_Line_Item__c;
            this.DealServiceLineItemId = dealUnresolvedFulfillmentObj.Service_Order_Line_Item__c;
            this.ChargeMethod = dealUnresolvedFulfillmentObj.Charge_Method__c;  
            this.ActionRequired = dealUnresolvedFulfillmentObj.Action_Required__c;
            this.UnitId = dealUnresolvedFulfillmentObj.Customer_Owned_Unit__c;
            this.ItemCode = '';
            this.ItemDescription = '';
            if(String.isNotBlank(dealUnresolvedFulfillmentObj.Item_Code__c)) {
                this.ItemCode = dealUnresolvedFulfillmentObj.Item_Code__c;
            }
            if(String.isNotBlank(dealUnresolvedFulfillmentObj.Item_Description__c)) {
            this.ItemDescription = dealUnresolvedFulfillmentObj.Item_Description__c;
            }
            this.User = dealUnresolvedFulfillmentObj.User__r.Alias;
            this.RequiredForUnit = (dealUnresolvedFulfillmentObj.Required_For_Unit__c != null) ? dealUnresolvedFulfillmentObj.Required_For_Unit__c : 'To be determined';
            this.StockId = dealUnresolvedFulfillmentObj.Customer_Owned_Unit__c != null ? dealUnresolvedFulfillmentObj.Customer_Owned_Unit__r.Stock_Id__c : '';
            this.OptionAndFeeId = dealUnresolvedFulfillmentObj.Option_Fee__c;
            this.COKitHeaderId = dealUnresolvedFulfillmentObj.Co_Kit_Header__c;
            this.DealKitHeaderId = dealUnresolvedFulfillmentObj.Deal_Kit_Header__c;
            this.SOKitHeaderId = dealUnresolvedFulfillmentObj.Service_Order_Kit_Header__c;
            this.error = (COService.error != null) ? COService.error : new SO_KLI_Recalculation.Errorhandler('200', 'Success');
            
            this.RelatedStockIds = '';
            this.RelatedOptionAndFeeIdList = new List<String>();
            if(String.isNotBlank(dealUnresolvedFulfillmentObj.Related_Option_And_Fees__c)) {
                this.RelatedOptionAndFeeIdList = dealUnresolvedFulfillmentObj.Related_Option_And_Fees__c.split(';');
                if(this.RelatedOptionAndFeeIdList.size() > 0) {
                    List<Option_Fee__c> optionAndFeeList = [Select Deal_Item__r.Customer_Owned_unit__r.Stock_Id__c from Option_Fee__c where Id In :this.RelatedOptionAndFeeIdList];
                    Set<String> stockIdSet = new Set<String>();
                    for(Option_Fee__c optionAndFeeRec : optionAndFeeList) {
                        stockIdSet.add(optionAndFeeRec.Deal_Item__r.Customer_Owned_unit__r.Stock_Id__c);
                    }
                    
                    this.RelatedStockIds = string.join((new List<String>(stockIdSet)),', ');
                }
            } else {
                this.RelatedOptionAndFeeIdList.add(dealUnresolvedFulfillmentObj.Option_Fee__c);
                this.RelatedStockIds = dealUnresolvedFulfillmentObj.Customer_Owned_Unit__r.Stock_Id__c;
            }
            
            if(dealUnresolvedFulfillmentObj.Deal_Kit_Header__c != null) {
                this.KitHeaderId = dealUnresolvedFulfillmentObj.Deal_Kit_Header__c;
            } else {
                if(String.isNotBlank(dealUnresolvedFulfillmentObj.CO_Kit_Header__c)) {
                    this.KitHeaderId = dealUnresolvedFulfillmentObj.CO_Kit_Header__r.Kit_Header__c;
                } else if(String.isNotBlank(dealUnresolvedFulfillmentObj.Service_Order_Kit_Header__c)) {
                    this.KitHeaderId = dealUnresolvedFulfillmentObj.Service_Order_Kit_Header__r.Kit_Header__c;
                }
            }
            
            
            if(String.isNotBlank(dealUnresolvedFulfillmentObj.Option_Fee__c)) {
                this.PartId = dealUnresolvedFulfillmentObj.Option_Fee__r.Part__c;
                this.LabourId = dealUnresolvedFulfillmentObj.Option_Fee__r.Labour_Code__c;
                this.SubletId = dealUnresolvedFulfillmentObj.Option_Fee__r.Product__c;
            } else {
                if(String.isNotBlank(dealUnresolvedFulfillmentObj.CO_Line_Item__c)) {
                    this.PartId = dealUnresolvedFulfillmentObj.CO_Line_Item__r.Part__c;
                } else if(String.isNotBlank(dealUnresolvedFulfillmentObj.Service_Order_Line_Item__c)) {
                    this.PartId = dealUnresolvedFulfillmentObj.Service_Order_Line_Item__r.Part__c;
                    this.LabourId = dealUnresolvedFulfillmentObj.Service_Order_Line_Item__r.Labour_Code__c;
                    this.FeeId = dealUnresolvedFulfillmentObj.Service_Order_Line_Item__r.Fee__c;
                    this.SubletId = dealUnresolvedFulfillmentObj.Service_Order_Line_Item__r.Sublet__c;
                }
            }
        }
    }
    
    public static DealWrapper parse(String json) {
        return (DealWrapper) System.JSON.deserialize(json, DealWrapper.class);
    }
    
    public static List<String> getDealFields(){
        List<String> dealFields = new List<String>{ 'Id',
                                                    'Down_Payment__c', 
                                                    'Is_Tax_Based_On_Customer_Address__c',
                                                    'Delivery_Date__c', 
                                                    'Unit_Status__c', 
                                                    'Status__c',
                                                    'Type__c',
                                                    'Total__c',
                                                    'CO_Header__c',
                                                    'Owner.Name',
                                                    'CO_Header__r.Owner.Name',
                                                    'Part_Total__c',
                                                    'Labour_Total__c',
                                                    'Fee_Total__c',
                                                    'Product_Total__c',
                                                    'Unit_Price_And_Cost_Total__c',
                                                    'Deal_Tax_Total__c',
                                                    'Trade_In_Total__c',
                                                    'Deal_Total__c',
                                                    'Lien_Payout_Total__c',
                                                    'F_I_Total__c',
                                                    'F_I_Tax_Total__c',
                                                    'Subtotal__c',
                                                    'CO_Header__r.Uninvoiced_Amount__c',
                                                    'CO_Header__r.Invoiced_Amount__c',
                                                    'CO_Header__r.Order_Total__c',
                                                    'Stamp_Duty_Total__c',
                                                    'Is_Deal_Fulfilled__c',
                                                    'DP360_Lead_Id__c',
                                                    'DP360_Lead_URL__c',
                                                    'Deal_Commission__c',
                                                    'Salesperson_Name__c',
                                                    'Invoice_Number__r.Invoice_Number__c',
                                                    'Invoice_Number__r.Invoice_Date__c',
                                                    'Pre_Tax_Unit_Price_And_Cost_Total__c',
                                                    'Pre_Tax_Fee_Total__c',
                                                    'Pre_Tax_Labour_Total__c',
                                                    'Pre_Tax_Other_Product_Total__c',
                                                    'Pre_Tax_Part_Total__c',
                                                    'Deal_Section_Trade_Only__c',
                                                    'Notes_For_Customer__c',
                                                    'Insurance_Provider__c',
                                                    'Insurance_Policy__c',
                                                    'Co_Buyer__c',
                                                    'Co_Buyer__r.Name',
                                                    'Co_Buyer__r.Birth_Date__c',
                                                    'Co_Buyer__r.Drivers_License__c',
                                                    'Co_Buyer__r.FirstName__c',
                                                    'Co_Buyer__r.LastName__c'
                                                };
                                                
        return dealFields;
    }
    
    public static List<String> getOptionAndFeeFields(){
        // Edited by Kajal 10/14/2016
        List<String> optionAndFeeFields = new List<String>{ 'Id',
                                                            'Deal__c', 
                                                            'Deal_Item__c',
                                                            'Deal_Item__r.Deal__c',
                                                            'Deal_Item__r.Customer_Owned_Unit__c',
                                                            'Deal_Item__r.Applicable_Tax__c',
                                                            'Deal_Item__r.Unit_Tax_Applicable_On__c',
                                                            'Deal_Item__r.Taxable__c',
                                                            'Qty__c',
                                                            'Part__c',
                                                            'Part__r.Vendor__r.Is_Foreign_Vendor__c',
                                                            'Part__r.Description__c',
                                                            'Part__r.Part_Number__c',
                                                            'Part__r.AvailableParts__c',
                                                            'Fee__c',
                                                            'Fee__r.Code__c',
                                                            'Fee__r.Description__c',
                                                            'Labour_Code__c',
                                                            'Labour_Code__r.Code__c',
                                                            'Labour_Code__r.Description__c',
                                                            'Fee__r.Taxable__c',
                                                            'Fee__r.Applicable_Tax__c',
                                                            'Labour_Code__r.Taxable__c',
                                                            'Labour_Code__r.Applicable_Tax__c',
                                                            'Part__r.Taxable__c',
                                                            'Part__r.Applicable_Tax__c',
                                                            'Product__r.Description__c',
                                                            'Product__r.Code__c',
                                                            'Is_Install__c',
                                                            'Price__c',
                                                            'Item_Description__c',
                                                            'Status__c',
                                                            'Item_Code__c',
                                                            'Sales_Tax_Percentage__c',
                                                            'Product__c',
                                                            'Product__r.Type__c',
                                                            'CreatedDate',
                                                            'Deal_Kit_Header__c',
                                                            'Is_Fixed_Kit_Line_Item_CO__c',
                                                            'Is_Fixed_Price__c',
                                                            'Actual_Kit_Price__c',
                                                            'Fixed_Price__c',
                                                            'Part__r.Non_Inventory_Part__c',//kv 02/02/2017
                                                            'Price_When_Tax_Included__c',
                                                            'Is_Environmental_Fee__c',
                                                            'Kit_Header_Line_Item__c',
                                                            'CO_Line_Item__r.Qty_To_Order__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Qty_To_Order__c',
                                                            'Fee__r.Assigned_Tag_1__c',
                                                            'Fee__r.Assigned_Tag_2__c',
                                                            'Kit_Header_Line_Item__r.Kit_Price__c',
                                                            'CO_Line_Item__r.Status__c',
                                                            'CO_Line_Item__r.Qty__c',
                                                            'CO_Line_Item__r.Qty_Committed__c',
                                                            'CO_Line_Item__r.Part__r.Non_Inventory_Part__c',
                                                            'CO_Line_Item__r.Oversold_Qty__c',
                                                            'CO_Line_Item__r.Vendor_Order_Header__c',
                                                            'CO_Line_Item__r.Vendor_Order_Header__r.Status__c',
                                                            'CO_Line_Item__r.CO_Status__c',
                                                            'CO_Line_Item__r.Is_In_Merch_Section__c',
                                                            'CO_Line_Item__r.Is_In_Service_Order__c',
                                                            'CO_Line_Item__r.Merchandise_Commit_Order_controls__c',
                                                            'CO_Line_Item__r.Part__r.AvailableParts__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Qty__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Qty_Committed__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Part__r.Non_Inventory_Part__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Vendor_Order_Header__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Vendor_Order_Header__r.Status__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.CO_Status__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Is_In_Merch_Section__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Is_In_Service_Order__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Merchandise_Commit_Order_controls__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Part__r.AvailableParts__c',
                                                            'Service_Order_Line_Item__r.CO_Line_Item__r.Status__c',
                                                            'UUID__c', 
                                                            'Applicable_Tax__c'
                                                        };
        return optionAndFeeFields;
    }
    
    public static List<String> getDealKitHeaderFieldsList(){
        List<String> DealKHFields = new List<String>{ 'Id',
                                                    'CO_Header__c',
                                                    'Kit_Header__c',
                                                    'Deal_Item__c',
                                                    'Fixed_Price__c',
                                                    'CreatedDate',
                                                    'Kit_Header__r.Kit_Unique_Name__c',
                                                    'Can_Split__c',
                                                    'Service_Kit__c',
                                                    'Is_Fixed_Price__c',
                                                    'Actual_Kit_Price__c',
                                                    'Deal_Item__r.Deal__c',
                                                    'Deal_Item__r.Deal__r.CO_Header__r.Customer__c',
                                                    'Is_Fixed_Kit_Header_CO__c',
                                                    'Tax_Amount__c',
                                                    'Is_Install__c',
                                                    'Deal_Item__r.Customer_Owned_Unit__c',
                                                    'Deal_Item__r.Deal__r.Co_Header__c',
                                                    'Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c',
                                                    'Code__c',
                                                    'Description__c',
                                                    'UUID__c'
                                                };
        return DealKHFields;
    }
    
    public static List<String> getDealUnitPriceCost(){
        List<String> DealUnitPriceCost = new List<String>{ 'Id',
                                                            'Item_Description__c', 
                                                            'Qty__c',
                                                            'Price__c',
                                                            'Total_Price__c',
                                                            'Type__c',                                                          
                                                            'Tax_Percent__c',
                                                            'Sales_Tax_Percentage__c',
                                                            'Unit_Price_Cost__c',
                                                            'Price_When_Tax_Included__c',
															'Deal_Item__r.Customer_Owned_Unit__c',
															'Total_Cost__c'                                                
                                                        };
        return DealUnitPriceCost;
    }
    
    public static List<String> getDealUnresolvedFulfillmentFields(){
        List<String> unresolvedFullfillmentFieldList = new List<String>{ 'Id',
                                                            'Type__c', 
                                                            'Updated_Quantity__c',
                                                            'Actual_Quantity__c',
                                                            'Deal__c',
                                                            'Deal_Item__c',
                                                            'CO_Line_Item__c',
                                                            'Service_Order_Line_Item__c',
                                                            'Action_Required__c',
                                                            'Charge_Method__c',
                                                            'Item_Code__c',
                                                            'Item_Description__c',
                                                            'Required_For_Unit__c',
                                                            'Co_Kit_Header__c',
                                                            'Co_Kit_Header__r.Kit_Header__c',
                                                            'Customer_Owned_Unit__c',
                                                            'User__r.Alias',
                                                            'Customer_Owned_Unit__r.Stock_Id__c',
                                                            'Option_Fee__c',
                                                            'Option_Fee__r.Part__c',
                                                            'CO_Line_Item__r.Part__c',
                                                            'Option_Fee__r.Labour_Code__c',
                                                            'Option_Fee__r.Product__c',
                                                            'Service_Order_Line_Item__r.Part__c',
                                                            'Service_Order_Line_Item__r.Labour_Code__c',
                                                            'Service_Order_Line_Item__r.Fee__c',
                                                            'Service_Order_Line_Item__r.Sublet__c',
                                                            'Service_Order_Kit_Header__r.Kit_Header__c',
                                                            'CO_Line_Item__r.Related_Option_And_Fees__c',
                                                            'Related_Option_And_Fees__c',
                                                            'Deal_Kit_Header__c',
                                                            'Service_Order_Kit_Header__c'                                  
                                                        };
        return unresolvedFullfillmentFieldList;
    }
    
    public class DealFinanceWrapper {
        public String Id{get; set;}
        public String DealId{get; set;}
        public String FinanceCompanyId{get; set;}
        public String FinanceCompanyName{get; set;}
        public String FinanceCompanyEmail{get; set;}
        public String FinanceCompanyPhone{get; set;}
        public String FinanceCompanyFormattedPhone{get; set;}
        public String FinanceCompanyAccountNumber{get; set;}
        public String FinanceCompanyAddress1{get; set;}
        public String FinanceCompanyAddress2{get; set;}
        public String FinanceCompanyCity{get; set;}
        public String FinanceCompanyState{get; set;}
        public String FinanceCompanycountry{get; set;}
        public String FinanceCompanyPostal{get; set;}
        public Boolean CommissionsNotInFINPayments{get; set;}
        public String Status{get; set;}
        public Decimal DealTotal{get; set;}
        public Decimal FIProductTotal{get; set;}
        public Decimal FIProductTax{get; set;}
        public Decimal DownPayment{get; set;}
        public Decimal TotalFinance{get; set;}
        public Decimal InterestRate{get; set;}
        public Decimal LoanTerm{get; set;}
        public String TermType{get; set;}
        public String PaymentFrequency{get; set;}
        public Decimal EstimatedPayment{get; set;}
        public List<FIProductWrapper> FIProductList{get; set;}
        public Decimal FinanceCommission{get; set;}
        public Decimal BuyRate;
        public Decimal BuyRateCommission;
        public Decimal ApprovedAmountFinanced;

        public DealFinanceWrapper(){}
        
        public DealFinanceWrapper(Deal_Finance__c dealFinanceObj){ 
            this.Id = dealFinanceObj.Id;
            this.DealId = dealFinanceObj.Deal__c;
            this.FinanceCompanyId = dealFinanceObj.Finance_Company__c;
            this.FinanceCompanyName = dealFinanceObj.Finance_Company__r.Name;
            this.FinanceCompanyEmail = (dealFinanceObj.Finance_Company__r.Preferred_Email__c != null) ? dealFinanceObj.Finance_Company__r.Preferred_Email__c : dealFinanceObj.Finance_Company__r.Work_Email__c;
            this.FinanceCompanyPhone = (dealFinanceObj.Finance_Company__r.Preferred_Phone__c != null) ? dealFinanceObj.Finance_Company__r.Preferred_Phone__c : dealFinanceObj.Finance_Company__r.Work_Number__c;
            this.FinanceCompanyFormattedPhone = this.FinanceCompanyPhone != null ? PrintCustomerOrderInvoiceCtrl.formatphonenumber(this.FinanceCompanyPhone) : null;
            this.FinanceCompanyAccountNumber = dealFinanceObj.Finance_Company__r.AccountNumber;
            this.CommissionsNotInFINPayments = dealFinanceObj.Finance_Company__r.Commissions_not_in_finance_payments__c;

            String billingStreet = (dealFinanceObj.Finance_Company__r.BillingStreet == null ) ? '' : dealFinanceObj.Finance_Company__r.BillingStreet;
            List<String> bsList = billingStreet.split('\n');
            this.FinanceCompanyAddress1 = (bsList.size() > 0) ? bsList[0] : '';
            this.FinanceCompanyAddress2 = (bsList.size() > 1) ? bsList[1] : '';

            this.FinanceCompanyCity = dealFinanceObj.Finance_Company__r.BillingCity;
            this.FinanceCompanyState = dealFinanceObj.Finance_Company__r.BillingState;
            this.FinanceCompanycountry = dealFinanceObj.Finance_Company__r.BillingCountry;
            this.FinanceCompanyPostal = dealFinanceObj.Finance_Company__r.BillingPostalCode;

            this.Status = dealFinanceObj.Status__c;
            if(dealFinanceObj.Id == null) {
                this.Status = Constants.QUOTATION;
            }
            this.EstimatedPayment = (dealFinanceObj.Estimated_Payment__c != null) ? dealFinanceObj.Estimated_Payment__c : 0;
            this.DealTotal = dealFinanceObj.Deal_Total__c;
            this.FIProductTotal = dealFinanceObj.F_I_Total__c;
            this.FIProductTax = dealFinanceObj.F_I_Product_Tax_Total__c;
            this.DownPayment = dealFinanceObj.Down_Payment__c != null ? dealFinanceObj.Down_Payment__c : 0;
            this.InterestRate = dealFinanceObj.Interest_Rate__c;
            this.FinanceCommission = dealFinanceObj.Finance_Commission__c != null ? dealFinanceObj.Finance_Commission__c : 0;
            this.LoanTerm = dealFinanceObj.Loan_Term__c;
            this.TermType = dealFinanceObj.Term_Type__c;
            this.PaymentFrequency = dealFinanceObj.Payment_Frequency__c;
            this.FIProductList = new List<FIProductWrapper>();
            for(F_I_Product__c fAndIProductRec : dealFinanceObj.F_I_Products__r) {
                FIProductList.add(new FIProductWrapper(fAndIProductRec));
            }
            this.BuyRate = dealFinanceObj.Buy_Rate__c;
            this.BuyRateCommission = dealFinanceObj.Buy_Rate_Commission__c != null ? dealFinanceObj.Buy_Rate_Commission__c : 0;
            this.ApprovedAmountFinanced = dealFinanceObj.Approved_Amount_Financed__c;
        }
    }
    private static String getSystemDefaultPriceLevelName() {
        String systemDefaultPriceLevelName = '';
        List<Price_Level__c> defaultPriceLevelList = [select Name__c from Price_Level__c where Default__c = true];
        if(defaultPriceLevelList.size() > 0) {
            systemDefaultPriceLevelName = defaultPriceLevelList[0].Name__c;
        }  
        return systemDefaultPriceLevelName;
    }
    public class FIProductWrapper {
        public String Id{get; set;}
        public String ItemDescription{get; set;}
        public Decimal Price{get; set;}
        public Decimal Total{get; set;}
        public Decimal SalesTax{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public String ProductId{get; set;} 
        public String DealId{get; set;}
        public String DealFinanceId{get; set;}
        public String UUID;
        public Decimal Cost;
        public String CostMethod;
        public Decimal CostRate;
        public String ProductFinanceCompanyId{get; set;}
        public String ProductFinanceCompanyName{get; set;}
        
        public FIProductWrapper(F_I_Product__c FandIProduct) {
            this.Id = FandIProduct.Id;
            this.ItemDescription = FandIProduct.Item_Description__c;
            this.SalesTax = FandIProduct.Sales_Tax__c;
            this.Total = FandIProduct.Total__c;
            this.ProductId = FandIProduct.Vendor_Product__c;
            this.DealId = FandIProduct.Deal__c;
            this.DealFinanceId = FandIProduct.Deal_Finance__c;
            this.Price = (FandIProduct.Price__c != null) ? FandIProduct.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.SalesTaxPercentage = FandIProduct.Sales_Tax_Percentage__c != null ? FandIProduct.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP) : 0.00;
            if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                this.SalesTax = (FandIProduct.Sales_Tax__c != null ? FandIProduct.Sales_Tax__c : 0);
            } else {
                this.SalesTax = (this.Price * this.SalesTaxPercentage / 100).setScale(2, RoundingMode.HALF_UP);
            }
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(isTaxIncludingPricing) {
                this.Price = (FandIProduct.Price_When_Tax_Included__c != null ? FandIProduct.Price_When_Tax_Included__c.setScale(2, RoundingMode.HALF_UP) : 0);
            }
            this.UUID = FandIProduct.UUID__c;
            this.CostMethod = FandIProduct.Cost_Method__c;
            this.Cost = FandIProduct.Cost__c != null ? FandIProduct.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.CostRate = FandIProduct.Cost_Rate__c != null ? FandIProduct.Cost_Rate__c : 0;
            this.ProductFinanceCompanyId = FandIProduct.Vendor_Product__r.Vendor__c;
            this.ProductFinanceCompanyName = FandIProduct.Vendor_Product__r.Vendor__r.Name;
        }
    }   
    
    public class CoBuyerWrapper {
        public String Id{get; set;}
        public String Name;
        public String Email;
        public String PreferredEmail;
        public String Type;
        public String WorkEmail;
        public String OtherEmail;
        public String PreferredPhone;
        public String PreferredSMS;
        public String HomeNumber;
        public Boolean HomeNumberSMS;
        public String FormattedHomeNumber;
        public String WorkNumber;
        public Boolean WorkNumberSMS;
        public String FormattedWorkNumber;
        public String OtherPhone;
        public Boolean MobileNumberSMS;
        public String FormattedOtherPhone;
        public String PriceLevel;
        public String TaxExemption;
        public String CustomerDriverLicenceNumber;
        public String Notes;
        public Integer TotalActiveOrders;
        
        public CoBuyerWrapper(Account coBuyerObj){ 
            this.Id = coBuyerObj.Id;
            this.Name = (coBuyerObj.Name != null) ? coBuyerObj.Name : '';
            this.Email = (coBuyerObj.Email__c != null) ? coBuyerObj.Email__c : '';
            this.PriceLevel = (coBuyerObj.Price_Level__c != null) ? coBuyerObj.Price_Level__r.Name__c : getSystemDefaultPriceLevelName();
            this.TaxExemption = '';
            if(coBuyerObj.Account_type__r.Id != null) {
                AccountTypeWrapper accRec = AccountTypeService.getRecForAccountType(coBuyerObj.Account_type__r.Id);
                this.TaxExemption = accRec != null ? accRec.TaxExemptions : ''; 
            }
            this.Type = (coBuyerObj.Type__c != null) ? coBuyerObj.Type__c : '';
            
            if(coBuyerObj.Preferred_Phone__c != null) {
                if(coBuyerObj.Preferred_Phone__c == coBuyerObj.Home_Number__c) {
                    this.PreferredPhone = 'HomeNumber';
                } else if(coBuyerObj.Preferred_Phone__c == coBuyerObj.Mobile__c) {
                    this.PreferredPhone = 'OtherPhone';
                } else if(coBuyerObj.Preferred_Phone__c == coBuyerObj.Work_Number__c) {
                    this.PreferredPhone = 'WorkNumber';
                }
           } else {
                this.PreferredPhone = '';
            }
            
            if(coBuyerObj.Preferred_SMS__c != null) {
                if(coBuyerObj.Preferred_SMS__c == coBuyerObj.Home_Number__c) {
                    this.PreferredSMS = 'HomeNumber';
                } else if(coBuyerObj.Preferred_SMS__c == coBuyerObj.Mobile__c) {
                    this.PreferredSMS = 'OtherPhone';
                } else if(coBuyerObj.Preferred_SMS__c == coBuyerObj.Work_Number__c) {
                    this.PreferredSMS = 'WorkNumber';
                }
            } else {
                this.PreferredSMS = '';
            }
            
            this.PreferredEmail = (coBuyerObj.Preferred_Email__c == null) ? '' : coBuyerObj.Preferred_Email__c;
            this.WorkEmail = (coBuyerObj.Work_Email__c == null) ? '' : coBuyerObj.Work_Email__c;
            this.OtherEmail = (coBuyerObj.Other_Email__c == null) ? '' : coBuyerObj.Other_Email__c;
            
            this.HomeNumber = (coBuyerObj.Home_Number__c == null ) ? '' : coBuyerObj.Home_Number__c;
            this.HomeNumberSMS = coBuyerObj.Home_Number_SMS__c;
            this.FormattedHomeNumber = (coBuyerObj.Formatted_Home_number__c == null ) ? '' : coBuyerObj.Formatted_Home_number__c;
            this.WorkNumber = (coBuyerObj.Work_Number__c == null) ? '' : coBuyerObj.Work_Number__c;
            this.WorkNumberSMS = coBuyerObj.Work_Number_SMS__c;
            this.FormattedWorkNumber = (coBuyerObj.Formatted_Work_Number__c == null) ? '' : coBuyerObj.Formatted_Work_Number__c;
            this.OtherPhone = (coBuyerObj.Mobile__c == null) ? '' : coBuyerObj.Mobile__c;
            this.MobileNumberSMS = coBuyerObj.Mobile_Number_SMS__c;
            this.FormattedOtherPhone = (coBuyerObj.Formatted_Mobile_Number__c == null) ? '' : coBuyerObj.Formatted_Mobile_Number__c;
            this.CustomerDriverLicenceNumber = (coBuyerObj.Drivers_License__c != null) ? coBuyerObj.Drivers_License__c : '';
            this.Notes = String.isNotBlank(coBuyerObj.Notes__c) ? coBuyerObj.Notes__c : '';
            this.TotalActiveOrders = (!coBuyerObj.CO_Headers__r.isEmpty()) ? coBuyerObj.CO_Headers__r.size() : 0;
        }
        
    }
    
    public class BillOfSaleFormWrapper {
    	public Decimal CashPrice;
    	public Decimal DocumentationAmount;
    	public Decimal HUTAmount;
    	public Decimal TitleAmount;
    	public Decimal InsuranceAmount;
    	public Decimal LessTradeIn;
    	public Decimal CashPaid;
    	public Decimal BalanceDue;
    	public Decimal TotalAmount;
        public Decimal FeeWithoutHUTAmount;
        public Decimal CashPriceWithoutHUTFeeTag;
    	
    	public BillOfSaleFormWrapper(Deal__c dealRec) {
    		this.CashPrice = (dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c != null ? dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.CashPrice += (dealRec.Stamp_Duty_Total__c != null ? dealRec.Stamp_Duty_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.CashPrice += (dealRec.Lien_Payout_Total__c != null ? dealRec.Lien_Payout_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.CashPriceWithoutHUTFeeTag = (dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c != null ? dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.CashPriceWithoutHUTFeeTag += (dealRec.Stamp_Duty_Total__c != null ? dealRec.Stamp_Duty_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.CashPriceWithoutHUTFeeTag += (dealRec.Lien_Payout_Total__c != null ? dealRec.Lien_Payout_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.DocumentationAmount = 0;
    		//this.HUTAmount = (dealRec.Sales_Tax_Total__c != null ? dealRec.Sales_Tax_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		this.HUTAmount = 0;
    		this.TitleAmount = 0;
            this.FeeWithoutHUTAmount = 0;
    		this.InsuranceAmount = 0;
    		this.LessTradeIn = 0;
    		this.CashPaid = 0;
    		this.TotalAmount = (dealRec.Deal_Total__c != null ? dealRec.Deal_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
    		
    		for(Option_Fee__c optionFeeRec : dealRec.Options_Fees__r) {
    			optionFeeRec.Qty__c = optionFeeRec.Qty__c != null ? optionFeeRec.Qty__c : 0;
    			optionFeeRec.Price__c = optionFeeRec.Price__c != null ? optionFeeRec.Price__c : 0;
    		
    			if(optionFeeRec.Product__c != null && optionFeeRec.Product__r.Type__c == Constants.DEAL_PRODUCT) {
    				this.InsuranceAmount += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
    			} else if(optionFeeRec.Fee__c != null) {
    				if((optionFeeRec.Fee__r.Assigned_Tag_1__c != null && optionFeeRec.Fee__r.Assigned_Tag_1__c.containsIgnoreCase(Constants.HUT))
                        || (optionFeeRec.Fee__r.Assigned_Tag_2__c != null && optionFeeRec.Fee__r.Assigned_Tag_2__c.containsIgnoreCase(Constants.HUT))) {
                        this.HUTAmount += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
    				} else if((optionFeeRec.Fee__r.Assigned_Tag_1__c != null && optionFeeRec.Fee__r.Assigned_Tag_1__c.containsIgnoreCase(Constants.DOC))
    					|| (optionFeeRec.Fee__r.Assigned_Tag_2__c != null && optionFeeRec.Fee__r.Assigned_Tag_2__c.containsIgnoreCase(Constants.DOC))
    					|| (optionFeeRec.Fee__r.Assigned_Tag_1__c != null && optionFeeRec.Fee__r.Assigned_Tag_1__c.containsIgnoreCase(Constants.ORIG))
    					|| (optionFeeRec.Fee__r.Assigned_Tag_2__c != null && optionFeeRec.Fee__r.Assigned_Tag_2__c.containsIgnoreCase(Constants.ORIG))) {
    					this.DocumentationAmount += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
    				} else if((optionFeeRec.Fee__r.Assigned_Tag_1__c != null && optionFeeRec.Fee__r.Assigned_Tag_1__c.containsIgnoreCase(Constants.TITLE))
                        || (optionFeeRec.Fee__r.Assigned_Tag_2__c != null && optionFeeRec.Fee__r.Assigned_Tag_2__c.containsIgnoreCase(Constants.TITLE))) {
    					this.TitleAmount += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    } else {
    					this.CashPrice += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
    				}
                    if((optionFeeRec.Fee__r.Assigned_Tag_1__c != null && !optionFeeRec.Fee__r.Assigned_Tag_1__c.containsIgnoreCase(Constants.HUT))
                    || (optionFeeRec.Fee__r.Assigned_Tag_2__c != null && !optionFeeRec.Fee__r.Assigned_Tag_2__c.containsIgnoreCase(Constants.HUT))
                    || (optionFeeRec.Fee__r.Assigned_Tag_1__c == null && optionFeeRec.Fee__r.Assigned_Tag_2__c == null)) {
                            this.CashPriceWithoutHUTFeeTag += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                            this.FeeWithoutHUTAmount += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    }
    			} 
                else {
    				this.CashPrice += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    this.CashPriceWithoutHUTFeeTag += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
    			}
    		}
    		
    		for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
	        	if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
	        		this.LessTradeIn += ((dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0).setScale(2, RoundingMode.HALF_UP);
	        	}
			}
			this.LessTradeIn = -(this.LessTradeIn);
			
			if(dealRec.Status__c == Constants.INVOICED && dealRec.Invoice_Number__c !=  null) {
				this.CashPaid = dealRec.Invoice_Number__r.Total_Amount_Except_Charge_Account__c.setScale(2, RoundingMode.HALF_UP);
			} else {
				this.CashPaid = dealRec.CO_Header__r.Total_Deposit_And_Payment__c.setScale(2, RoundingMode.HALF_UP);
			}
			
			this.BalanceDue = ((this.CashPrice + this.DocumentationAmount + this.HUTAmount + this.TitleAmount + this.InsuranceAmount
								+ this.LessTradeIn) - this.CashPaid).setScale(2, RoundingMode.HALF_UP);
    	}
    }
    
    public class PriceAndCostOptionWrapper {
        public String Id{get; set;}
        public String Type{get; set;}
        public String ItemDescription{get; set;}
        public Decimal TotalPrice{get; set;}
        public Decimal TotalCost{get; set;}
        public String FactoryOptionId{get; set;}
        public Decimal SalesTaxPercentage{get; set;}
        public String UpcId{get; set;}
        
        public PriceAndCostOptionWrapper(Deal_Unit_Price_Cost__c dupcRec){
            this.Id = dupcRec.Id;
            this.Type = dupcRec.Type__c;
            this.ItemDescription = dupcRec.Item_Description__c;
            this.TotalPrice = ((dupcRec.Total_Price__c != null) ? dupcRec.Total_Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.TotalCost = ((dupcRec.Total_Cost__c != null) ? dupcRec.Total_Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.FactoryOptionId = dupcRec.Factory_Option__c;
            this.SalesTaxPercentage = ((dupcRec.Sales_Tax_Percentage__c != null) ? dupcRec.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
        }
    
    }
    
    public static List<String> getCoBuyerFields(){
        List<String> CoBuyerFieldList = new List<String>{ 'Id',
                                                            'Name',
                                                            'FirstName__c',
                                                            'LastName__c',
                                                            'Email__c',
                                                            'Home_Number__c',
                                                            'Mobile__c',
                                                            'Preferred_Phone__c',
                                                            'Work_Number__c',
                                                            'Home_Number_SMS__c',
                                                            'Mobile_Number_SMS__c', 
                                                            'Preferred_SMS__c',
                                                            'Work_Number_SMS__c',
                                                            'Other_Email__c',
                                                            'Preferred_Email__c',
                                                            'Work_Email__c',
                                                            'Formatted_Home_number__c',
                                                            'Formatted_Mobile_Number__c',
                                                            'Formatted_Work_Number__c',
                                                            'Formatted_Preferred_Phone__c',
                                                            'Account_type__r.Id',
                                                            'Price_Level__c',
                                                            'Price_Level__r.Name__c',
                                                            'Type__c',
                                                            'Drivers_License__c',
                                                            'Notes__c',
                                                            '(Select Id FROM CO_Headers__r where Status__c = \'Open\')'
                                                        };
        return CoBuyerFieldList;
    }
    
    public static List<String> getDealFinanceFields(){
        List<String> DealFinanceFieldList = new List<String>{ 'Id',
                                                            'Status__c', 
                                                            'Deal__c',
                                                            'Finance_Company__c',
                                                            'Finance_Company__r.Preferred_Phone__c',
                                                            'Finance_Company__r.Preferred_Email__c',
                                                            'Finance_Company__r.Work_Email__c',
                                                            'Finance_Company__r.Work_Number__c',
                                                            'Finance_Company__r.Name', 
                                                            'Deal_Total__c', 
                                                            'F_I_Total__c',
                                                            'F_I_Product_Tax_Total__c',
                                                            'Down_Payment__c',
                                                            'Interest_Rate__c',
                                                            'Loan_Term__c',
                                                            'Term_Type__c',
                                                            'Estimated_Payment__c', 
                                                            'Payment_Frequency__c',
                                                            'Finance_Company__r.AccountNumber',
                                                            'Finance_Company__r.Commissions_not_in_finance_payments__c',
                                                            'Finance_Commission__c',
                                                            'Finance_Company__r.BillingStreet',
                                                            'Finance_Company__r.BillingCity',
                                                            'Finance_Company__r.BillingState',
                                                            'Finance_Company__r.BillingCountry',
                                                            'Finance_Company__r.BillingPostalCode',
                                                            'Buy_Rate__c',
                                                            'Buy_Rate_Commission__c',
                                                            'Approved_Amount_Financed__c'
                                                        };
        return DealFinanceFieldList;
    }
    
    public static List<String> getDealFIProductFields(){
        List<String> DealFIProductFieldList = new List<String>{ 'Id',
                                                            'Price__c',
                                                            'Price_When_Tax_Included__c',
                                                            'Item_Description__c',
                                                            'Sales_Tax__c',
                                                            'Sales_Tax_Percentage__c',
                                                            'Total__c',
                                                            'Vendor_Product__c',
                                                            'Vendor_Product__r.Name',
                                                            'Vendor_Product__r.Description__c',
                                                            'Deal_Finance__c',
                                                            'Deal__c',
                                                            'Vendor_Product__r.Code__c',
                                                            'UUID__c',
                                                            'Cost_Method__c',
                                                            'Cost__c',
                                                            'Cost_Rate__c',
                                                            'Vendor_Product__r.Vendor__c',
                                                            'Vendor_Product__r.Vendor__r.Name'
                                                        };
        return DealFIProductFieldList;
    }
    
    private static List<DealKitHeader> getDealKitHeaderList(List<Option_Fee__c> optionAndFeeListObj, List<Deal_Kit_Header__c> dealKitHeaders) {

        List<DealKitHeader> dealKitHeaderObjList = new List<DealKitHeader>();
        List<DateTime> sortedDateTimeList = new List<dateTime>();
        Set<Id> optionAndFeeIdSet = new Set<Id>();
        for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaders) {
            sortedDateTimeList.add(dealKitHeaderRec.CreatedDate);
            
            dealKitHeaderObjList.add(new DealKitHeader(dealKitHeaderRec, dealKitHeaderRec.Options_Fees__r, true));
            for(Option_Fee__c optionAndFeeRec : dealKitHeaderRec.Options_Fees__r) {
                optionAndFeeIdSet.add(optionAndFeeRec.Id);
            } 
        } 
        
        Integer lastIndexValue = 0;
        for(Option_Fee__c optionAndFeeRec : optionAndFeeListObj) {
            if(!optionAndFeeIdSet.contains(optionAndFeeRec.Id)) { 
                for(Integer i = lastIndexValue; i < sortedDateTimeList.size(); i++){
                    system.debug(i);
                    if(sortedDateTimeList[i] < optionAndFeeRec.CreatedDate){
                        lastIndexValue ++;
                    } else { 
                        break;
                    }
                }
                if(dealKitHeaderObjList.size() > lastIndexValue){
                    dealKitHeaderObjList.add(lastIndexValue, new DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    
                    if(sortedDateTimeList.size() > lastIndexValue){
                        sortedDateTimeList.add(lastIndexValue, optionAndFeeRec.CreatedDate);
                    } else {
                        sortedDateTimeList.add(optionAndFeeRec.CreatedDate);
                    }
                    
                    lastIndexValue++;
                } else {
                    dealKitHeaderObjList.add(new DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    lastIndexValue++;
                }
            }
        }
        return dealKitHeaderObjList;
    }
}
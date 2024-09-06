global without sharing class DealDocumentPrintCtrl {

    global DealDocumentPrintCtrl (NewHomePageCtrl controller) {
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
    public String dateFormat { get{ return BPUtility.getDateFormat();}private set;}
    
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    public String dealId;
    public static String documentType {get; set;}
    public boolean isDisplayTaxInvoice { get{return GeneralConfiguration.isDisplayTaxInvoice();} private set;}
    public String brandingLocationId {get;private set;}
    public Boolean isHidePartNumbersOnDocuments{get{return GeneralConfiguration.isHidePartNumbersOnDocuments();} private set;}
    public Boolean isHideKitDetailsOnDocuments{get{return GeneralConfiguration.isHideKitDetailsOnDocuments();} private set;}
    public String DealFormId { get{return GeneralConfiguration.getFormIdToIncludeOnDealDocuments();} private set;}
    
    public DealDocumentDetail dealDocumentDetailRecord {get; private set;}
    public String DealDocumentDetailJson {get; private set;}
    
    global DealDocumentPrintCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
        dealId = ApexPages.currentPage().getParameters().get('id');
        documentType = ApexPages.currentPage().getParameters().get('documentType');        
        brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
        if(dealId  == '' || dealId == 'undefined' || dealId == null) {
            return;
        } else {
            dealId = BPUtility.getEncodedString(dealId);
            if(String.isNotBlank(brandingLocationId)) {
	        	brandingLocationId= BPUtility.getEncodedString(brandingLocationId);
	        	dealDocumentDetailJson = getDealDocumentDetailsWithBrandingLocation(dealId, brandingLocationId);
	        } else {
	        	dealDocumentDetailJson = getDealDocumentDetails(dealId);
	        }
            dealDocumentDetailRecord = (DealDocumentDetail)JSON.deserialize(BPUtility.getDecodedString(dealDocumentDetailJson), DealDocumentDetail.class);
        }
    }
    
    /**
     * Name: getDealDocumentDetails
     * Desc: 
     * @param:  (1) dealIdStr
     * @return: String - JSON String
    **/
    @RemoteAction
    global static String getDealDocumentDetails(String dealIdStr) {
        dealIdStr = BPUtility.getDecodedString(dealIdStr);
        return BPUtility.getEncodedString(getDealDocumentData(dealIdStr, null));
    }
    
    @RemoteAction
    global static String getDealDocumentDetailsWithBrandingLocation(String dealIdStr, String brandingLocationId) {
        dealIdStr = BPUtility.getDecodedString(dealIdStr);
        brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
        return BPUtility.getEncodedString(getDealDocumentData(dealIdStr, brandingLocationId));
    }
    
    private static String getDealDocumentData(String dealIdStr, String brandingLocationId) {
        String dealDetails;
        Id dealId = dealIdStr;
        
        List<Deal__c> dealList = getDealHeaderList(new List<Id>{dealId});
        if(dealList.size() > 0) {
            Deal__c deal = dealList[0];
            Id coInvoiceHeaderId = deal.Invoice_Number__c;
            
            List<Deal_Item__c> dealItemList = getDealHeaders(new List<Id>{dealId});
            
            BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
            
            List<Individual_Tax__c> individualItemsList = DealUtil.getDealRelatedIndividualTaxes(deal.Id);
                                                                    
            List<CO_Invoice_Payment__c> coInvoicePaymentList = [SELECT Name, LastModifiedDate, Payment_Date__c, Reference__c, Payment_Method__c, Amount__c, CreatedDate, Reverse_Link__c, Deposit_Payment_Method__c FROM CO_Invoice_Payment__c WHERE CO_Invoice_Header__c =: coInvoiceHeaderId ORDER BY Payment_Date__c DESC];
                        
            List<Deal_Finance__c> dealFinanceList = SOQLUtil.getDealFinanceRecord(new Map<String, String>{'Deal__c' => deal.Id});
            
            Map<String, String> unitIdToProductTypeIdMap = new Map<String, String>();
            for(Deal_Item__c dealItemRec: dealItemList) {
                if(String.isNotBlank(dealItemRec.Customer_Owned_Unit__r.Product_type__c)) unitIdToProductTypeIdMap.put(dealItemRec.Customer_Owned_Unit__c, dealItemRec.Customer_Owned_Unit__r.Product_type__c);
            }
            List<FilterJSON> filerObjList = new List<FilterJSON>{
                new FilterJSON('Unit_Product_Type__c', 'IN', String.join(unitIdToProductTypeIdMap.values(), ',')),
                new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
                new FilterJSON('Include_In_Deal_Document__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE)
            };

            UnitProductTypeService.OptionalFieldAPINameToRecMap = UnitProductTypeService.getUnitOptionalFieldAPINameToRecMap(filerObjList);
            UnitProductTypeService.UnitDataFieldsAPINameToLabelMap = GeneralConfiguration.getUnitDataFieldsAPINameToLabelMap();
            Map<Id, Customer_Owned_Unit__c> unitIdToRecMap = Unit_Service.getUnitIdToRecMap(unitIdToProductTypeIdMap.keySet(), Unit_Service.UnitPrimaryFields, new List<String>(UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()));
            
            DealDocumentDetail dealDocumentObj = new DealDocumentDetail(brandingLocationObj, deal, dealItemList, individualItemsList, coInvoicePaymentList, dealFinanceList, unitIdToRecMap);
            dealDetails = System.JSON.serialize(dealDocumentObj,true);
        }
        
        return dealDetails;
    }
    
     /**
     * Name: DealDocumentDetail
     * Description: Wrapper class
     * 
    **/
    public class DealDocumentDetail {
        public CustomerDetail.Company CompanyInfo {get; set;}
        public DealHeaderWrapper DealInfo {get; set;}
        public Boolean IsTaxIncludingPricing {get; set;}
        public DealWrapper.DealFinanceWrapper DealFinanceObj {get; set;}
        public String DealDocumentWarrantyText{get; set;}
        public Boolean IsSignatureLineforDealDocument{get; set;}
        public List<TransactionDetail> Transactions {get; set;}
        public List<PrintCustomerOrderInvoiceCtrl.TaxDetail> SalesTaxList {get; set;}
        public DealDetailWrapper DealDetailWrapperObj {get; set;}
        public Decimal DueFromCustomer {get; set;}
        public Decimal DueFromFinance {get; set;}
        public Decimal AmountFinanced {get; set;}
        public Decimal SubTotal {get; set;}
        public Decimal AmountPaid {get; set;}
        public Decimal BalanceDue {get; set;}
        public Decimal Total {get; set;}
        public Decimal GSTOnPurchases {get; set;}
        
        public DealDocumentDetail(BrandingLocationWrapper brandingLocationObj, Deal__c dealsInfo, List<Deal_Item__c> dealItems, List<Individual_Tax__c> individualItemsList, List<CO_Invoice_Payment__c> coInvoicePaymentList, List<Deal_Finance__c> dealFinanceList, Map<Id, Customer_Owned_Unit__c> unitIdToRecMap) {
            
            if(brandingLocationObj != null) {
                this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
                this.DealDocumentWarrantyText = (brandingLocationObj.DisclaimerforDealDocuments != null) ? brandingLocationObj.DisclaimerforDealDocuments : '';
                this.IsSignatureLineforDealDocument = brandingLocationObj.IsSignatureforDealDocuments;
            }


            
            
            this.IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.CompanyInfo.BusinessPhone = this.CompanyInfo.FormattedBusinessPhone != null ? this.CompanyInfo.FormattedBusinessPhone: '';
            this.DealInfo = new DealHeaderWrapper(dealsInfo);
            DealDetailWrapperObj = new DealDetailWrapper(dealItems, unitIdToRecMap);
            
            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);
            Decimal SalesTaxTotal = 0;
            this.SalesTaxList = TaxEngine.setTaxDetails(salesTaxNameToTaxValue);
            for(Decimal taxAmt : salesTaxNameToTaxValue.values()){
                SalesTaxTotal += taxAmt;
            }
            if(dealFinanceList.size() > 0) {
                this.DealFinanceObj = new DealWrapper.DealFinanceWrapper(dealFinanceList[0]);
            }
            this.Transactions = new List<TransactionDetail>();
            
            this.AmountPaid = 0;
            Decimal amountPaidByFinance = 0;
            Decimal amountPaidByCustomer = 0;
            Decimal usedDealDeposit = 0;
            if(String.isNotBlank(documentType) && documentType == 'Bill of sale'){
                for(CO_Invoice_Payment__c coPaymentRec : coInvoicePaymentList) {
                    if(String.isBlank(coPaymentRec.Reverse_Link__c) && !coPaymentRec.Payment_Method__c.equalsIgnoreCase('Financing') &&
                      (String.isBlank(coPaymentRec.Deposit_Payment_Method__c) || !coPaymentRec.Deposit_Payment_Method__c.equalsIgnoreCase('Financing'))) {
                        if(coPaymentRec.Payment_Method__c.equalsIgnoreCase('Use Deal Deposit') && this.DealFinanceObj != null) {
                            if(usedDealDeposit < this.DealFinanceObj.DownPayment) {
                                TransactionDetail txnObj = new TransactionDetail(coPaymentRec);
                                txnObj.Amount = ((usedDealDeposit + coPaymentRec.Amount__c) <= this.DealFinanceObj.DownPayment ? coPaymentRec.Amount__c : (this.DealFinanceObj.DownPayment - usedDealDeposit));
                                usedDealDeposit += txnObj.Amount;
                                this.Transactions.add(txnObj);
                            }
                        } else {
                            this.Transactions.add(new TransactionDetail(coPaymentRec));
                        }
                    if(coPaymentRec.Payment_Method__c != 'Charge Account') {
                    	this.AmountPaid += ((coPaymentRec.Amount__c != null) ? coPaymentRec.Amount__c : 0);
                    }
                }
                }
            	if(this.DealInfo.Status != 'Invoiced') {
            		for(CO_Deposit__c coDepositRec : dealsInfo.CO_Deposits__r){
		            	if(coDepositRec.Payment_Method__c != 'Invoice') {
		                	if(coDepositRec.Payment_Method__c == 'Financing') {
		                		amountPaidByFinance += coDepositRec.Amount__c;
		                	} else {
		                		amountPaidByCustomer += coDepositRec.Amount__c;
                                this.AmountPaid += ((coDepositRec.Amount__c != null) ? coDepositRec.Amount__c : 0);
		                	}
		                	if(!coDepositRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
                                this.Transactions.add(new TransactionDetail(coDepositRec));
                            }
		            	}
		            }
            	}
            } else {
                for(CO_Deposit__c coDepositRec : dealsInfo.CO_Deposits__r){
                    if(coDepositRec.Payment_Method__c != 'Invoice') {
                        if(coDepositRec.Payment_Method__c == 'Financing') {
                            amountPaidByFinance += coDepositRec.Amount__c;
                        } else {
                            amountPaidByCustomer += coDepositRec.Amount__c;
                            this.AmountPaid += ((coDepositRec.Amount__c != null) ? coDepositRec.Amount__c : 0);
                        }
                        
                        if(!coDepositRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
                            this.Transactions.add(new TransactionDetail(coDepositRec));
                        }
                    }
                }
            } 
            
            this.SubTotal = DealDetailWrapperObj.TotalUnits + DealDetailWrapperObj.TotalInstalledOption 
                            + DealDetailWrapperObj.TotalMerchandiseOption + DealDetailWrapperObj.TotalOtherProductsAndFee 
                            + DealDetailWrapperObj.TotalTradeIn + DealDetailWrapperObj.TotalStampDuty + DealDetailWrapperObj.TotalLienPayout;
            if(dealFinanceList.size() > 0) {
                this.SubTotal += (this.DealFinanceObj !=null && this.DealFinanceObj.FIProductTotal != null) ? this.DealFinanceObj.FIProductTotal : 0;
                if(this.IsTaxIncludingPricing) {
                    this.SubTotal += (this.DealFinanceObj !=null && this.DealFinanceObj.FIProductTax != null) ? this.DealFinanceObj.FIProductTax : 0;
                }             
            }
           
            this.BalanceDue = 0;
            this.Total = 0;
            this.Total = this.SubTotal;
           
            if(!this.IsTaxIncludingPricing) { 
                this.Total += SalesTaxTotal;
            }
            this.BalanceDue = this.Total - this.AmountPaid;
           
            if(this.DealFinanceObj != null) {
                this.DealFinanceObj.DownPayment = (this.DealFinanceObj.DownPayment != null) ? this.DealFinanceObj.DownPayment : 0;
                this.AmountFinanced = this.Total - this.DealFinanceObj.DownPayment;
                if(this.DealInfo.Status == 'Invoiced') {
                    this.DueFromCustomer = 0;
                    this.DueFromFinance = 0;
                } else {
                    this.DueFromCustomer = this.DealFinanceObj.DownPayment - amountPaidByCustomer;
                    this.DueFromFinance = DealService.getActualAmountFinanced(this.AmountFinanced, this.DealFinanceObj, this.IsTaxIncludingPricing) - amountPaidByFinance;
                }
                this.DueFromFinance = this.DueFromFinance < 0 ? 0 : this.DueFromFinance;
            }
            
            if(documentType == 'Bill of sale' && GeneralConfiguration.getTaxIncludingPricing()) {
                Boolean isTradeInExists = false;
                Integer unitWithSKUAddedCount = 0;
                for(Deal_Item__c dealItemRec: dealsInfo.Deal_Items__r) {
                    if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                        isTradeInExists = true;
                    } else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT && dealItemRec.Customer_Owned_Unit__c != null) {
                        unitWithSKUAddedCount++;
                    }
                }
                if(unitWithSKUAddedCount > 0 && isTradeInExists) {
                    this.GSTOnPurchases = (SalesTaxTotal + (dealsInfo.Trade_In_Total__c - dealsInfo.Pre_Tax_Trade_In_Total__c)*-1).setScale(2, RoundingMode.HALF_UP);
                }
            }
        }
    }       
    
    public class DealHeaderWrapper {
        public String COType {get; private set;}
        public String DealType {get; private set;}
        public String CustomerName {get; private set;}
        public String CustomerAddress {get; private set;}
        public String CustomerAddress2 {get; private set;}
        public String CustomerCityProv {get; private set;}
        public String CustomerPostal {get; private set;}
        public String CustomerState {get; private set;}
        public String CustomerEmail {get; private set;}
        public String CustomerPhone {get; private set;}
        public String Status {get; private set;}
        public String SoldBy {get; private set;}
        public String InvoiceNumber {get; private set;}
        public String InvoiceDate {get; private set;}
        public String InvoiceStatus {get; private set;}
        public String OrderNumber {get; private set;}
        public String OrderDate {get; private set;}
        public String CustomerPONumber {get; private set;}
        public Boolean isDealSectionTradeOnly {get; private set;}
        public String CoBuyerName {get; set;}
        
        public String CompanyLocale {get; private set;}
        public List<String> NotesForCustomer {get; private set;}
        public DealHeaderWrapper(Deal__c dealInfo) {
            if(dealInfo != null) {
                this.COType  = dealInfo.CO_Header__r.CO_Type__c;
                this.DealType = dealInfo.Type__c;
                this.CustomerName = dealInfo.CO_Header__r.Customer__r.Name;
                this.CoBuyerName = dealInfo.Co_Buyer__c != null ? dealInfo.Co_Buyer__r.Name : null;
                String billingStreet = (dealInfo.CO_Header__r.Customer__r.BillingStreet == null ) ? '' : dealInfo.CO_Header__r.Customer__r.BillingStreet;
                if(dealInfo.CO_Header__r.Customer__r.Preferred_Email__c == null) {
                  if(dealInfo.CO_Header__r.Customer__r.Email__c != null) {
                      this.CustomerEmail = dealInfo.CO_Header__r.Customer__r.Email__c;
                  } else if(dealInfo.CO_Header__r.Customer__r.Work_Email__c != null) {
                      this.CustomerEmail = dealInfo.CO_Header__r.Customer__r.Work_Email__c;
                  } else if(dealInfo.CO_Header__r.Customer__r.Other_Email__c != null) {
                      this.CustomerEmail = dealInfo.CO_Header__r.Customer__r.Other_Email__c;
                  }
                } else {
                    this.CustomerEmail = dealInfo.CO_Header__r.Customer__r.Preferred_Email__c;
                }
                
                if(dealInfo.CO_Header__r.Customer__r.Formatted_Preferred_Phone__c == null) {
                    if(dealInfo.CO_Header__r.Customer__r.Formatted_Home_number__c != null) {
                        this.CustomerPhone = dealInfo.CO_Header__r.Customer__r.Formatted_Home_number__c;
                    } else if(dealInfo.CO_Header__r.Customer__r.Formatted_Mobile_Number__c != null) {
                        this.CustomerPhone = dealInfo.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
                    } else if(dealInfo.CO_Header__r.Customer__r.Formatted_Work_Number__c != null) {
                        this.CustomerPhone = dealInfo.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                    }
                } else {
                    this.CustomerPhone = dealInfo.CO_Header__r.Customer__r.Formatted_Preferred_Phone__c;
                }
                List<String> bsList = billingStreet.split('\n');
                this.CustomerAddress = (bsList.size() > 0) ? bsList[0] : '';
                this.CustomerAddress2 = (bsList.size() > 1) ? bsList[1] : '';
                CustomerCityProv = dealInfo.CO_Header__r.Customer__r.BillingCity;
                this.CustomerCityProv = (CustomerCityProv != null && CustomerCityProv != '') ? (CustomerCityProv ) : '';
                this.CustomerPostal = dealInfo.CO_Header__r.Customer__r.BillingPostalCode;
                this.CustomerState = dealInfo.CO_Header__r.Customer__r.BillingState;
                
                this.Status = dealInfo.Status__c;
                
                this.CompanyLocale = GeneralConfiguration.getCompanyLocale();
                this.OrderNumber = (dealInfo.CO_Header__r.Name == null) ? '' : dealInfo.CO_Header__r.Name;
                this.InvoiceNumber = (dealInfo.Invoice_Number__r.Invoice_Number__c == null) ? '' : dealInfo.Invoice_Number__r.Invoice_Number__c;
                this.InvoiceDate = (dealInfo.Invoice_Number__r.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(dealInfo.Invoice_Number__r.Invoice_Date__c) : BPUtility.getFormatedDateTime(System.now());
                this.OrderDate = (dealInfo.CO_Header__r.LastModifiedDate__c != null) ? BPUtility.getFormatedDateTime(dealInfo.CO_Header__r.LastModifiedDate__c) : '';
                this.InvoiceStatus = dealInfo.Invoice_Number__r.Status__c;
                this.SoldBy = (String.isNotBlank(dealInfo.Salesperson_Name__c) ? dealInfo.Salesperson_Name__c : dealInfo.CO_Header__r.Owner__r.Name);
                this.CustomerPONumber = (dealInfo.CO_Header__r.Customer_PO_Number__c == null) ? '' : dealInfo.CO_Header__r.Customer_PO_Number__c;
                this.NotesForCustomer = (dealInfo.Notes_For_Customer__c != null) ?  dealInfo.Notes_For_Customer__c.split('\n') : new List<String>();
                this.isDealSectionTradeOnly = dealInfo.Deal_Section_Trade_Only__c;
            }
        }

    }
    
    public class DealDetailWrapper {
        public List<DealUnitDetails> UnitList {get; private set;}
        public List<DealTradeInDetails> TradeInList {get; private set;}
        public Decimal TotalUnits {get; private set;}
        public Decimal TotalInstalledOption {get; private set;}
        public Decimal TotalMerchandiseOption {get; private set;}
        public Decimal TotalTradeIn {get; private set;}
        public Decimal TotalLienPayout {get; private set;}
        public Decimal TotalOtherProductsAndFee {get; private set;}
        public Decimal TotalStampDuty {get; private set;}
        
        public DealDetailWrapper(List<Deal_Item__c> dealItemList, Map<Id, Customer_Owned_Unit__c> unitIdToRecMap) {
            this.UnitList = new List<DealUnitDetails>();
            this.TradeInList = new List<DealTradeInDetails>();
            this.TotalUnits = 0;
            this.TotalInstalledOption = 0;
            this.TotalMerchandiseOption = 0;
            this.TotalTradeIn = 0;
            this.TotalLienPayout = 0;
            this.TotalOtherProductsAndFee = 0;
            this.TotalStampDuty = 0;
            
            Set<Id> dealItemIds = new Set<Id>();
            
            for(Deal_Item__c dealItemRec : dealItemList) {
                dealItemIds.add(dealItemRec.Id);
            }
            
            Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
            List<Deal_Kit_Header__c> dealKitHeaderList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealItemIds));
            for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderList) {
                if(dealItemIdToDKHListMap.containsKey(dealKitHeaderRec.Deal_Item__c)) {
                    List<Deal_Kit_Header__c> dealKitHeaders = dealItemIdToDKHListMap.get(dealKitHeaderRec.Deal_Item__c);
                    dealKitHeaders.add(dealKitHeaderRec);
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, dealKitHeaders);
                } else {
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, new List<Deal_Kit_Header__c>{dealKitHeaderRec});
                }
            }
            
            Map<String, UnitDetailWrapper> unitIdToDetailMap = new Map<String, UnitDetailWrapper>();
            for(Deal_Item__c dealItemRec : dealItemList) {
                if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT) {
                    List<Deal_Kit_Header__c> dealKitHeaders = new List<Deal_Kit_Header__c>();
                    if(dealItemIdToDKHListMap.containsKey(dealItemRec.Id)) {
                        dealKitHeaders = dealItemIdToDKHListMap.get(dealItemRec.Id);
                    }
                    this.UnitList.add(new DealUnitDetails(dealItemRec, dealKitHeaders, unitIdToRecMap.get(dealItemRec.Customer_Owned_Unit__c)));
                } else if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                    this.TradeInList.add(new DealTradeInDetails(dealItemRec, unitIdToRecMap.get(dealItemRec.Customer_Owned_Unit__c)));
                    if(dealItemRec.Transfer_Plate_Reg_to_New_Unit__c && dealItemRec.Transfer_To__c != null) {
                        unitIdToDetailMap.put(dealItemRec.Transfer_To__c, new UnitDetailWrapper(dealItemRec.Customer_Owned_Unit__r.Plate__c, dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c));
                    }
                }
            }            
            for(DealUnitDetails dealUnitRec: UnitList) {
                TotalUnits += dealUnitRec.UnitAndPriceCost;
                TotalInstalledOption += dealUnitRec.InstalledOptionCost;
                TotalMerchandiseOption += dealUnitRec.MerchandiseOptionCost;
                TotalOtherProductsAndFee += dealUnitRec.OtherProductsAndFeeCost;
                TotalStampDuty += dealUnitRec.StampDuty;
                if(unitIdToDetailMap.containsKey(dealUnitRec.ItemDesc.COUId)) {
                    dealUnitRec.ItemDesc.PlateNo = unitIdToDetailMap.get(dealUnitRec.ItemDesc.COUId).PlateNo;
                    dealUnitRec.ItemDesc.RegExpiryDate = unitIdToDetailMap.get(dealUnitRec.ItemDesc.COUId).RegExpiryDate;
                }
            }
            
            for(DealTradeInDetails dealTradeInRec: TradeInList) {
                TotalTradeIn += dealTradeInRec.AgreedValue;
                this.TotalLienPayout += dealTradeInRec.LienPayout;
            }
        }
    }
    
    public class DealTradeInDetails {
        public UnitDescriptionWrapper ItemDesc {get; private set;}
        public Decimal AgreedValue {get; private set;}
        public Decimal LienPayout {get; private set;}
        public Decimal SalesTax {get; private set;}
        
        public DealTradeInDetails(Deal_Item__c dealItemRec, Customer_Owned_Unit__c unitRec) {
            this.AgreedValue = 0;
            this.SalesTax = 0;
            this.ItemDesc = new UnitDescriptionWrapper(dealItemRec, unitRec);
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.AgreedValue = (dealItemRec.Agreed_Value__c != null) ? -dealItemRec.Agreed_Value__c : 0;
            this.LienPayout = dealItemRec.Lien_Payout__c != null ? dealItemRec.Lien_Payout__c : 0;
            if(dealItemRec.Default_Unit_Sales_Tax_Percentage__c == null) {
                dealItemRec.Default_Unit_Sales_Tax_Percentage__c = 0;
            }
            if(isTaxIncludingPricing) {
                this.SalesTax = this.AgreedValue - (this.AgreedValue / (1 + (dealItemRec.Default_Unit_Sales_Tax_Percentage__c / 100)));
            } else {
                this.SalesTax = ((this.AgreedValue * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP);
            }
        }
    }
    
    public class DealUnitDetails {
        public List<DealWrapper.DealKitHeader> InstalloptionAndFeeList {get; private set;}
        public List<DealWrapper.DealKitHeader> MerchandiseOptionAndFeeList {get; private set;}
        public List<DealWrapper.DealKitHeader> OtherProductsAndFeeList {get; private set;}
        public List<DealWrapper.DealKitHeader> DealKitHeaderList {get; private set;}
        public List<DealUnitPriceCostWrapper> DealUnitPriceCost {get; private set;}
        public UnitDescriptionWrapper ItemDesc {get; private set;}
        public Decimal UnitAndPriceCost {get; private set;}
        public Decimal InstalledOptionCost {get; private set;}
        public Decimal MerchandiseOptionCost {get; private set;}
        public Decimal OtherProductsAndFeeCost {get; private set;}
        public Decimal StampDuty {get; private set;}
        
        public DealUnitDetails(Deal_Item__c dealItemRec, List<Deal_Kit_Header__c> dealKitHeaderList, Customer_Owned_Unit__c unitRec) {
            this.UnitAndPriceCost = 0;
            this.InstalledOptionCost = 0;
            this.MerchandiseOptionCost = 0;
            this.OtherProductsAndFeeCost = 0;
            this.InstalloptionAndFeeList = new List<DealWrapper.DealKitHeader>();
            this.MerchandiseOptionAndFeeList = new List<DealWrapper.DealKitHeader>();
            this.OtherProductsAndFeeList = new List<DealWrapper.DealKitHeader>();
            this.DealUnitPriceCost = new List<DealUnitPriceCostWrapper>();
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing(); 
 
            this.ItemDesc = new UnitDescriptionWrapper(dealItemRec, unitRec);
            
            String locale = GeneralConfiguration.getCompanyLocale();
            if((String.isBlank(locale) || locale != 'Australia')) {
                this.StampDuty = 0;                       
            } else {
                this.StampDuty = (dealItemRec.Stamp_Duty_Total__c == null) ? 0 : dealItemRec.Stamp_Duty_Total__c;
            }
            
            // Case 00003637
            for(Deal_Unit_Price_Cost__c dealUnitpriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r) {
                DealUnitPriceCostWrapper dealUnitWrapperObj = new DealUnitPriceCostWrapper(dealUnitpriceCostRec);
                if(dealUnitpriceCostRec.Type__c == 'Factory' || (dealUnitWrapperObj.TotalPrice != null && dealUnitWrapperObj.TotalPrice != 0)) {
                    this.UnitAndPriceCost += dealUnitWrapperObj.TotalPrice;
                    DealUnitPriceCost.add(dealUnitWrapperObj);
                }
            }
            
            this.DealKitHeaderList = new List<DealWrapper.DealKitHeader>();
            this.DealKitHeaderList = getDealKitHeaderList(dealItemRec.Options_Fees__r, dealKitHeaderList);
            
            for(DealWrapper.DealKitHeader dealKitHeaderRec : this.DealKitHeaderList) {
                if(dealKitHeaderRec.hasChildren) {
                    if(dealKitHeaderRec.IsInstall) {
                        this.InstalledOptionCost += dealKitHeaderRec.Price;
                        InstalloptionAndFeeList.add(dealKitHeaderRec);
                    } else if((!dealKitHeaderRec.IsInstall)) {
                        this.MerchandiseOptionCost += dealKitHeaderRec.Price;
                        MerchandiseOptionAndFeeList.add(dealKitHeaderRec);
                    }
                } else {
                    for(DealWrapper.OptionAndFeeInfo optionAndFeeRec : dealKitHeaderRec.OptionAndFeeList) {
                        if(optionAndFeeRec.IsInstall) {
                            this.InstalledOptionCost += optionAndFeeRec.Total;
                            InstalloptionAndFeeList.add(dealKitHeaderRec);
                        } else if((!optionAndFeeRec.IsInstall) && ((optionAndFeeRec.PartId !='' && optionAndFeeRec.PartId !=null) || (optionAndFeeRec.KitHeaderId !='' && optionAndFeeRec.KitHeaderId != null))) {
                            this.MerchandiseOptionCost += optionAndFeeRec.Total;
                            MerchandiseOptionAndFeeList.add(dealKitHeaderRec);
                        } else {
                            this.OtherProductsAndFeeCost += optionAndFeeRec.Total;
                            OtherProductsAndFeeList.add(dealKitHeaderRec);
                        }
                    }
                }
            }
        }
        
    }
    
    public class DealUnitPriceCostWrapper {
        public String ItemDescription{get; private set;}
        public Decimal Qty{get; private set;}
        public Decimal Price{get; private set;}
        public Decimal TotalPrice{get; private set;}
        public Decimal SalesTaxPercentage{get; private set;}
        public Decimal SalesTax{get; private set;}
        
        public DealUnitPriceCostWrapper(Deal_Unit_Price_Cost__c dealUnitPrice)   {
            this.ItemDescription = (dealUnitPrice.Item_Description__c != null) ? dealUnitPrice.Item_Description__c : 'Base Unit Price';
            this.Price = ((dealUnitPrice.Price__c != null) ? dealUnitPrice.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.Qty = dealUnitPrice.Qty__c;
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            this.SalesTaxPercentage = ((dealUnitPrice.Sales_Tax_Percentage__c != null) ? dealUnitPrice.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.TotalPrice = ((dealUnitPrice.Total_Price__c != null) ? dealUnitPrice.Total_Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.SalesTax = ((this.SalesTaxPercentage * this.Price) / 100).setScale(2, RoundingMode.HALF_UP);
            
            if(isTaxIncludingPricing) {
                this.Price = (dealUnitPrice.Price_When_Tax_Included__c != null) ? (dealUnitPrice.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : this.Price + this.SalesTax;
                this.TotalPrice = (this.Price * this.Qty);
                this.SalesTax = 0;
            }  
        }
    }
    
    public class UnitDescriptionWrapper {
        public String Name {get; private set;}
        public String Type {get; private set;}
        public String UnitNumber {get; private set;}
        public String VIN {get; private set;}
        public String Year {get; private set;}
        public String Make {get; private set;}
        public String Model {get; private set;}
        public String Submodel {get; private set;}
        public String Colour {get; private set;}
        public String Mileage {get; private set;}
        public String UnitName {get; private set;}
        public String COUId {get; private set;}
        public List<String> NotesList {get; private set;}
        public Boolean IsNewUnit {get; private set;}
        public Boolean IsConsignment {get; private set;}
        public String PlateNo {get; private set;}
        public String RegExpiryDate {get; private set;}
        public String InsuranceProvider {get; private set;}
        public String InsurancePolicy {get; private set;}
        public List<ServiceJobWorksheetWrapper.UnitDataFieldWrapper> UnitOptionalFieldObjList {get; private set;}
        
        public UnitDescriptionWrapper(Deal_Item__c dealItem, Customer_Owned_Unit__c unitRec) {
            this.COUId = dealItem.Customer_Owned_Unit__c;
            this.Type = (dealItem.Type__c == null) ? '' : dealItem.Type__c;
            this.UnitNumber = (dealItem.Customer_Owned_Unit__r.Stock_Id__c == null) ? '' : dealItem.Customer_Owned_Unit__r.Stock_Id__c;
            this.VIN = (dealItem.Customer_Owned_Unit__r.VIN_Number__c == null) ? '' : dealItem.Customer_Owned_Unit__r.VIN_Number__c;
            this.Year = (dealItem.Customer_Owned_Unit__r.Year__c == null) ? (dealItem.Year__c != null ? String.valueOf(dealItem.Year__c) : '') : String.valueOf(dealItem.Customer_Owned_Unit__r.Year__c);
            this.Make = (dealItem.Customer_Owned_Unit__r.Unit_Make__r.Name == null) ? (dealItem.Unit_Make__r.Name != null ? dealItem.Unit_Make__r.Name : '') 
                        : dealItem.Customer_Owned_Unit__r.Unit_Make__r.Name;
            this.Model = (dealItem.Customer_Owned_Unit__r.Unit_Model__r.Name__c == null) ? (dealItem.Unit_Model__r.Name__c != null ? dealItem.Unit_Model__r.Name__c : '')
                         : dealItem.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
            this.Submodel = (dealItem.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c == null) ? (dealItem.Sub_Model__r.Sub_Model_Name__c != null ? dealItem.Sub_Model__r.Sub_Model_Name__c : '') 
                        : dealItem.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
            this.Colour = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Colour__c') && String.isNotBlank(unitRec.Colour__c) ? unitRec.Colour__c : null;
            this.Mileage = ((dealItem.Mileage__c == null) ? 0 : dealItem.Mileage__c) +
                            ((dealItem.Mileage__c == null || dealItem.Mileage_Type__c == null) ? 
                            (GeneralConfiguration.getDefaultOdometerType() != null ? GeneralConfiguration.getDefaultOdometerType() : 'Km') : 
                            dealItem.Mileage_Type__c);
                  
            this.NotesList = (dealItem.Customer_Owned_Unit__r.Notes__c == null) ? new List<String>() : (dealItem.Customer_Owned_Unit__r.Notes__c).split('\n');
            if(dealItem.Customer_Owned_Unit__c == null) {
                this.NotesList = (dealItem.Notes__c == null) ? new List<String>() : (dealItem.Notes__c).split('\n');
            }
            this.UnitName = this.Make;
            if(this.Model != null && this.Model != '') {
                this.UnitName += ', '+ this.Model;
            }
            if(this.Submodel != null && this.Submodel != '') {
                this.UnitName += ', '+ this.Submodel;
            }
            this.IsNewUnit = (dealItem.Type__c == Constants.DEAL_ITEM_TYPE_UNIT && dealItem.Customer_Owned_Unit__c == null) ? true : dealItem.Customer_Owned_Unit__r.New_Unit__c;
            this.IsConsignment = (dealItem.Customer_Owned_Unit__c == null) ? false : dealItem.Customer_Owned_Unit__r.Consignment__c;
            this.PlateNo = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Plate__c') && String.isNotBlank(unitRec.Plate__c) ? unitRec.Plate__c : null;
            this.RegExpiryDate = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Reg_Expiry_Date__c') && unitRec.Reg_Expiry_Date__c != null ? 
                                    BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Reg_Expiry_Date__c.year(), unitRec.Reg_Expiry_Date__c.month(), unitRec.Reg_Expiry_Date__c.day())) : null;
            this.InsuranceProvider = dealItem.Deal__r.Insurance_Provider__c;
            this.InsurancePolicy = dealItem.Deal__r.Insurance_Policy__c;
            if(UnitProductTypeService.OptionalFieldAPINameToRecMap != null && unitRec != null && UnitProductTypeService.UnitDataFieldsAPINameToLabelMap != null) {
                this.UnitOptionalFieldObjList = new List<ServiceJobWorksheetWrapper.UnitDataFieldWrapper>();
                for(String apiName: UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()) {
                    String fieldName = UnitProductTypeService.OptionalFieldAPINameToRecMap.get(apiName).Name;
                    object fieldValue = unitRec.get(apiName);
                    String fieldCat = UnitProductTypeService.OptionalFieldAPINameToRecMap.get(apiName).Category__c;
                    if(fieldValue != null && String.isNotBlank(String.valueOf(fieldValue))) {
                        if(fieldCat != 'Miscellaneous') {
                            this.UnitOptionalFieldObjList.add(new ServiceJobWorksheetWrapper.UnitDataFieldWrapper(fieldName, String.valueOf(fieldValue)));
                        } else if(UnitProductTypeService.UnitDataFieldsAPINameToLabelMap.keySet().contains(apiName)) {
                            this.UnitOptionalFieldObjList.add(new ServiceJobWorksheetWrapper.UnitDataFieldWrapper(UnitProductTypeService.UnitDataFieldsAPINameToLabelMap.get(apiName), String.valueOf(fieldValue)));
                        }
                    }
                }
            }
        }
    }
    
    public class TransactionDetail {
        public boolean IsDeposit {get; private set;}
        public boolean IsPayment {get; private set;}
        public String Method {get; private set;}
        public String TransactionDate {get; private set;}
        public decimal Amount {get; private set;}
        public String ReferenceNo {get; private set;}
        
        public TransactionDetail(CO_Deposit__c coDepositRec) {
            IsDeposit   = true;
            IsPayment   = false;
            Method      = coDepositRec.Payment_Method__c;
            Amount      = coDepositRec.Amount__c;
            TransactionDate = coDepositRec.Payment_Date__c != null ? BPUtility.getFormatedDateTime(coDepositRec.Payment_Date__c) : BPUtility.getFormatedDateTime(coDepositRec.CreatedDate);
            ReferenceNo = String.isNotBlank(coDepositRec.Reference__c) ? coDepositRec.Reference__c : '';
        }
                
        public TransactionDetail(CO_Invoice_Payment__c coPaymentRec) {
            IsPayment   = true;
            IsDeposit   = false;
            Method      = coPaymentRec.Payment_Method__c;
            Amount      = coPaymentRec.Amount__c;
            TransactionDate = coPaymentRec.Payment_Date__c != null ? BPUtility.getFormatedDateTime(coPaymentRec.Payment_Date__c) : BPUtility.getFormatedDateTime(coPaymentRec.CreatedDate);
            ReferenceNo = String.isNotBlank(coPaymentRec.Reference__c) ? coPaymentRec.Reference__c : '';
        }
    }

    public class UnitDetailWrapper {
        public String PlateNo {get; private set;}
        public String RegExpiryDate {get; private set;}

        public UnitDetailWrapper(String plateNo, Date regExpiryDate) {
            this.PlateNo = plateNo;
            this.RegExpiryDate = (regExpiryDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(regExpiryDate.year(), regExpiryDate.month(), regExpiryDate.day())): '';
        }
    }
    
    private static List<DealWrapper.DealKitHeader> getDealKitHeaderList(List<Option_Fee__c> optionAndFeeListObj, List<Deal_Kit_Header__c> dealKitHeaders) {

        List<DealWrapper.DealKitHeader> dealKitHeaderObjList = new List<DealWrapper.DealKitHeader>();
        List<DateTime> sortedDateTimeList = new List<dateTime>();
        Set<Id> optionAndFeeIdSet = new Set<Id>();
        for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaders) {
            sortedDateTimeList.add(dealKitHeaderRec.CreatedDate);
            
            dealKitHeaderObjList.add(new DealWrapper.DealKitHeader(dealKitHeaderRec, dealKitHeaderRec.Options_Fees__r, true));
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
                    dealKitHeaderObjList.add(lastIndexValue, new DealWrapper.DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    
                    if(sortedDateTimeList.size() > lastIndexValue){
                        sortedDateTimeList.add(lastIndexValue, optionAndFeeRec.CreatedDate);
                    } else {
                        sortedDateTimeList.add(optionAndFeeRec.CreatedDate);
                    }
                    
                    lastIndexValue++;
                } else {
                    dealKitHeaderObjList.add(new DealWrapper.DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    lastIndexValue++;
                }
            }
        }
        return dealKitHeaderObjList;
    }
    
    public static List<Deal__c> getDealHeaderList(List<Id> dealIdsList) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

        List<Deal__c> dealList = [SELECT    Id, 
                                            Name,
                                            Status__c,
                                            CreatedById,
                                            CreatedBy.name,
                                            CO_Header__c,
                                            CO_Header__r.Name,
                                            CO_Header__r.Status__c,
                                            CO_Header__r.CO_Type__c,
                                            CO_Header__r.Customer__c,
                                            CO_Header__r.Customer__r.Name,
                                            CO_Header__r.Customer__r.BillingStreet,
                                            CO_Header__r.Customer__r.BillingCity,
                                            CO_Header__r.Customer__r.BillingState,
                                            CO_Header__r.Customer__r.BillingPostalCode,
                                            CO_Header__r.Customer__r.BillingCountry,
                                            CO_Header__r.Customer__r.Email__c,
                                            CO_Header__r.Customer__r.Formatted_Home_number__c,
                                            CO_Header__r.Customer__r.Formatted_Mobile_Number__c,
                                            CO_Header__r.Customer__r.Formatted_Preferred_Phone__c,
                                            CO_Header__r.Customer__r.Formatted_Work_Number__c,
                                            CO_Header__r.Customer__r.Home_Number_SMS__c,
                                            CO_Header__r.Customer__r.Mobile_Number_SMS__c, 
                                            CO_Header__r.Customer__r.Preferred_SMS__c,
                                            CO_Header__r.Customer__r.Work_Number_SMS__c,
                                            CO_Header__r.Customer__r.Other_Email__c,
                                            CO_Header__r.Customer__r.Preferred_Email__c,
                                            CO_Header__r.Customer__r.Work_Email__c,
                                            CO_Header__r.LastModifiedDate__c,
                                            CO_Header__r.Customer_PO_Number__c,
                                            CO_Header__r.Owner__r.Name,
                                            Invoice_Number__c,
                                            Invoice_Number__r.Name,
                                            Invoice_Number__r.Invoice_Number__c,
                                            Invoice_Number__r.Invoice_Date__c,
                                            Invoice_Number__r.CreatedBy.Name,
                                            Invoice_Number__r.Status__c,
                                            Invoice_Number__r.LastModifiedDate,
                                            Type__c, 
                                            Salesperson_Name__c,
                                            Deal_Section_Trade_Only__c,
                                            Pre_Tax_Trade_In_Total__c,
                                            Trade_In_Total__c,
                                            Notes_For_Customer__c,
                                            Co_Buyer__r.Name,
                                            (SELECT id, Type__c, Customer_Owned_Unit__c, Notes__c FROM Deal_Items__r),
                                            (Select Name, Amount__c, Payment_Method__c, CreatedDate, LastModifiedDate, Payment_Date__c, Reference__c From CO_Deposits__r ORDER BY Payment_Date__c DESC)
                                            FROM Deal__c 
                                            WHERE Id IN: dealIdsList
                                    ];
        return dealList;
    }
    
    private static List<Deal_Item__c> getDealHeaders(List<Id> dealIds) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(dealIds != null && dealIds.size() > 0) {
    
            String query = 'SELECT Id, ';
            
            query += '(SELECT Id';
            
            query += ' FROM Deal_Items__r) FROM Deal__c WHERE Id IN: dealIds';
            List<Deal__c> dealList = Database.query(query);
            
            if(dealList.size() > 0) {
                Set<String> dealItemId = new Set<String>();
                for(Deal__c dealRec : dealList) {
                    for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r)
                    dealItemId.add(dealItemRec.Id);
                }
                query = 'SELECT ';
                
                for(String fieldsName : DealItem.getDealItemFields()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                
                query += '(SELECT ';
                
                for(String fieldsName : DealWrapper.getOptionAndFeeFields()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                
                query = query.substring(0, query.length()-2);
                query += ' FROM Options_Fees__r ORDER BY CreatedDate ASC), ';
                query += '(SELECT ';
                
                for(String fieldsName : DealWrapper.getDealUnitPriceCost()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length()-2);
                query += ' FROM Deal_Unit_Prices_Costs__r ORDER BY Type__c ASC, Unit_Price_Cost__r.Name ASC) FROM Deal_Item__c WHERE Id IN: dealItemId ORDER BY CreatedDate';
                dealItemList = Database.query(query);
            }
        }
            
        return dealItemList;
    }
}
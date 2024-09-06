public without sharing class CustomerOrderWrapper {
    
    public class COHeaderWrapper{
        
        public COHeader coHeaderRec;
        public Boolean IsTaxIncludingPricing;
        public Boolean IsLoadFinancingSection;
        public COCardDetail CardInfo;
        public List<COKitHeader> COKHList;
        public List<InvoiceHistory> COInvoiceHistoryList;
        public List<COInvoicePayment> InvoicePaymentList;
        public List<CODeposit> DepositList;
        public Decimal StampDutyRate;
        
        public COHeaderWrapper(CO_Header__c coHeaderObj, List<Account> customerCardInfoList, List<CO_Line_Item__c> coLineItemObjList, List<CO_Kit_Header__c> coKitHeaderRecList, 
        						List<CO_Invoice_Header__c> closedCOInvoiceHeaders, List<Price_Level__c> priceLevelList, List<CO_Deposit__c> coDepositsList, 
        						List<CO_Invoice_Payment__c> coInvoicePayments) {    
            if(coHeaderObj != null) {                           
                this.coHeaderRec = new COHeader(coHeaderObj);
            }
            this.IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.IsLoadFinancingSection = GeneralConfiguration.getLoadFinanceSection();
            this.StampDutyRate = GeneralConfiguration.getStampDutyRate(); 
            if(customerCardInfoList.size() > 0) {
                this.CardInfo = new COCardDetail(customerCardInfoList[0], null, coHeaderObj);
            }

            if(priceLevelList.size() > 0){
                this.CardInfo = new COCardDetail(null, priceLevelList[0], coHeaderObj);
                this.CardInfo.CustomerName = (coHeaderObj.CO_Type__c == Constants.CASH_SALE) ? Constants.CASH_SALE : 
                	(coHeaderObj.CO_Type__c == Constants.INTERNAL_SERVICE) ? Constants.UNIT_INVENTORY : this.CardInfo.CustomerName;
            }
            
	        this.COKHList = getCOLineItemsList(coLineItemObjList, coKitHeaderRecList);
	        
            this.COInvoiceHistoryList = new List<InvoiceHistory>();
            for(CO_Invoice_Header__c closedCOInvoiceHeaderRec : closedCOInvoiceHeaders) {
                this.COInvoiceHistoryList.add(new InvoiceHistory(closedCOInvoiceHeaderRec));
            }
            
            this.DepositList = new List<CODeposit>(); 
	        for(CO_Deposit__c coDeposit  : coDepositsList) {
	            this.DepositList.add(new CODeposit(coDeposit));
	        }
	        
	        this.InvoicePaymentList = new List<COInvoicePayment>();
	        coInvoicePayments = sortCOPayment(coInvoicePayments);
	        for(CO_Invoice_Payment__c coInvoicePaymentRecord : coInvoicePayments) {
	        	this.InvoicePaymentList.add(new COInvoicePayment(coInvoicePaymentRecord));
	        }
        }
    }
    
    public static List<String> taxExemptionFields = new List<String>{'Id',
                                                                    'Sales_Tax_Item__c',
                                                                    'Sales_Tax_Item__r.Name__c'
                                                                }; 
    public class COHeader { 
        public Integer Level = 1;
        public String CustomerId;
        public String CustomerName;
        public Decimal CustomerStoreCredit; 
        public String COHeaderId;
        public String Assignee;
        public String AssigneeName;
        public String OrderStatus;
        public String Owner;
        public String OwnerName;
        public String OrderName;
        public String CreatedDate;
        public String ModifiedDate;
        public String COType;
        public String SellingGroup;
        public Boolean HideMerchandiseSection;
        public String ActiveInvoiceId;
        public Decimal OrderTotal;
        public Decimal InvoicedAmount;
        public Decimal UninvoicedAmount;
        public Decimal MerchandiseTotal;
        public Boolean IsTaxIncludedPricing;
        public Boolean IsDP360SyncEnabled;
        public Decimal TotalPayments;
        public Decimal TotalBalanceDue;
        public String MerchandiseCommitOrdercontrols; 
    	public String MerchandiseTransactionType;
    	public String CustomerPONumber;
    	public Boolean isServiceJobExists;
    	public Boolean isDealExists;
    	public Boolean isSpecialOrderExists;
        public String MerchandiseTransactionTypeId;
        public String MerchandiseTransactionTypeLabel;
        public String ShopifyId;
        public String ShopifyUrl;
        public String SpecialOrderStatus;
        public Boolean IsArchived;
        public Boolean IsOverrideTax;
        public Boolean IsTaxBasedOnCustomerAddress;
        public String ApplicableTaxId;
        public String OverrideTaxApplicableOn;
        public String CustomerContactId;
        public String CustomerShippingAddressId;
        public List<ServiceOrderWrapper.ServiceNotes> MerchandiseNotesForCustomer;
        public Decimal MerchPartsBulkDiscountPct;
        public Decimal MerchFeesBulkDiscountPct;
        public Decimal MerchPartsBulkDiscountPctCopy;
        public Decimal MerchFeesBulkDiscountPctCopy;
        
        public COHeader() {
            this.Level = 1;
        }
        public COHeader(Integer level) {
            this.Level = level;
        }

        public void setCOTotals(CO_Header__c coHeaderObj) {
            this.OrderTotal = (coHeaderObj.Order_Total__c != null) ? coHeaderObj.Order_Total__c : 0;
            this.InvoicedAmount = (coHeaderObj.Invoiced_Amount__c != null) ? coHeaderObj.Invoiced_Amount__c : 0;
            this.UninvoicedAmount = (coHeaderObj.Uninvoiced_Amount__c != null) ? coHeaderObj.Uninvoiced_Amount__c : 0;
            this.TotalPayments = (coHeaderObj.Total_Payment__c != null) ? coHeaderObj.Total_Payment__c : 0;
            this.TotalBalanceDue = this.InvoicedAmount - this.TotalPayments;
        }

        public COHeader(CO_Header__c coHeaderObj) {
            this.COHeaderId = coHeaderObj.Id;
            this.OrderName = coHeaderObj.Name;
            this.OrderTotal = (coHeaderObj.Order_Total__c != null) ? coHeaderObj.Order_Total__c : 0;
            this.OrderStatus = coHeaderObj.Order_status__c;
            this.CustomerId = coHeaderObj.Customer__c;
            this.CustomerName = coHeaderObj.Customer_Name__c;
            this.COType = coHeaderObj.CO_Type__c;
            this.MerchandiseTotal = coHeaderObj.Merchandise_Total__c;
		    this.InvoicedAmount = (coHeaderObj.Invoiced_Amount__c != null) ? coHeaderObj.Invoiced_Amount__c : 0;
            this.UninvoicedAmount = (coHeaderObj.Uninvoiced_Amount__c != null) ? coHeaderObj.Uninvoiced_Amount__c : 0;
            this.TotalPayments = (coHeaderObj.Total_Payment__c != null) ? coHeaderObj.Total_Payment__c : 0;
            this.TotalBalanceDue = this.InvoicedAmount - this.TotalPayments;
            this.CustomerStoreCredit = 0;
            this.CreatedDate = (coHeaderObj.CreatedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(coHeaderObj.CreatedDate.year(), 
        																					coHeaderObj.CreatedDate.month(), coHeaderObj.CreatedDate.day())) : '' ;
        	Datetime lastModifiedDate = BPUtility.getLastModifiedDate(coHeaderObj);
            this.ModifiedDate = (lastModifiedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(lastModifiedDate.year(), lastModifiedDate.month(), lastModifiedDate.day())) : '' ;
            if(coHeaderObj.Customer__r.Total_Store_Credit__c != null){
                this.CustomerStoreCredit = coHeaderObj.Customer__r.Total_Store_Credit__c;
            }
            this.ActiveInvoiceId = (coHeaderObj.CO_Invoice_Headers__r.size() == 1) ? coHeaderObj.CO_Invoice_Headers__r[0].Id : null;
            this.HideMerchandiseSection = coHeaderObj.Hide_Merchandise_Section__c;
            if(Level >= 2) {
                this.SellingGroup = coHeaderObj.Selling_Group__c;
                this.Owner = coHeaderObj.Owner__c;
                this.OwnerName = coHeaderObj.Owner__r.Name;
            }
            this.IsDP360SyncEnabled = (GeneralConfiguration.getDP360DealerId() != null) ? true : false;
            this.IsTaxIncludedPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.MerchandiseCommitOrdercontrols = coHeaderObj.Merchandise_Commit_Order_controls__c;
            this.MerchandiseTransactionTypeId = coHeaderObj.Transaction_Type__c;
            this.MerchandiseTransactionTypeLabel = coHeaderObj.Transaction_Type__r.Code_Label__c;
    		this.CustomerPONumber = coHeaderObj.Customer_PO_Number__c;
    		this.isServiceJobExists = coHeaderObj.Service_Order_Headers__r.size() > 0 ? true : false;
    		this.isDealExists = coHeaderObj.Deals__r.size() > 0 ? true : false;
    		this.isSpecialOrderExists = coHeaderObj.Vendor_Order_Line_Items__r.size() > 0 ? true : false;
            if(GeneralConfiguration.isShopifyIntegrationEnabled() && String.isNotBlank(coHeaderObj.Shopify_ID__c)) {
                this.ShopifyId = coHeaderObj.Shopify_ID__c;
                this.ShopifyUrl = coHeaderObj.Shopify_URL__c;
            }
            if(!coHeaderObj.CO_Section_Details__r.isEmpty()) {
                this.SpecialOrderStatus = coHeaderObj.CO_Section_Details__r[0].Special_Order_Status__c;
            }
            if(coHeaderObj.Is_Override_Merch_Tax__c) {
                this.IsOverrideTax = coHeaderObj.Is_Override_Merch_Tax__c;
                this.ApplicableTaxId = coHeaderObj.Merch_Applicable_Tax__c;
                this.OverrideTaxApplicableOn = coHeaderObj.Override_Merch_Tax_Applicable_On__c;
            }
            this.IsArchived = coHeaderObj.Is_Archived__c;
            this.IsTaxBasedOnCustomerAddress = coHeaderObj.Is_Tax_Based_On_Customer_Address__c;
            this.CustomerContactId = coHeaderObj.Customer_Contact__c;
            this.CustomerShippingAddressId = coHeaderObj.Customer_Shipping_Address__c;
            this.MerchandiseNotesForCustomer = (coHeaderObj.Merchandise_Notes_For_Customer__c != null) ?  ServiceJobService.getServiceNotesList(coHeaderObj.Merchandise_Notes_For_Customer__c.split('\n')) : new List<ServiceOrderWrapper.ServiceNotes>();
            this.MerchPartsBulkDiscountPctCopy = this.MerchPartsBulkDiscountPct = (coHeaderObj.Parts_Bulk_Discount_Percent__c != null) ? coHeaderObj.Parts_Bulk_Discount_Percent__c : 0;
            this.MerchFeesBulkDiscountPctCopy = this.MerchFeesBulkDiscountPct = (coHeaderObj.Fees_Bulk_Discount_Percent__c != null) ? coHeaderObj.Fees_Bulk_Discount_Percent__c : 0;
    
        }
        
        /**
         * Name: fieldsList
         * Desc: Method Which contains all the field list to be quried
         * @param:  
         * @return: List<String> - Fields List
        **/
        public List<String> fieldsList(){
             List<String> coHeaderFieldListLevel1 = new List<String>{ 'Id', 
                                                            'Name',
                                                            'Order_Total__c',
                                                            'CreatedDate',
                                                            'Order_status__c',
                                                            'Customer__c',
                                                            'Customer_Name__c',
                                                            'CO_Type__c',
	                                                        'Merchandise_Total__c',
                                                            'Uninvoiced_Amount__c',
                                                            'Invoiced_Amount__c',
                                                            'Total_Payment__c',
                                                            'LastModifiedDate',
                                                            'Last_Modified_Date__c',
                                                            'Total_Balance_Due__c',
	                                                        'Merchandise_Commit_Order_controls__c',
	                                                        'Merchandise_Transaction_Type__c',
                                                            'Customer_PO_Number__c',
                                                            'Transaction_Type__c',
                                                            'Transaction_Type__r.Code_Label__c',
                                                            'Shopify_ID__c',
                                                            'Shopify_URL__c',
                                                            'Account_Type__r.Id',
                                                            'Is_Override_Merch_Tax__c',
                                                            'Merch_Applicable_Tax__c',
                                                            'Override_Merch_Tax_Applicable_On__c',
                                                            'Is_Archived__c',
                                                            'Is_Tax_Based_On_Customer_Address__c',
                                                            'Merchandise_Notes_For_Customer__c', 
                                                            'Parts_Bulk_Discount_Percent__c',
                                                            'Fees_Bulk_Discount_Percent__c',
                                                            'Customer_Contact__c',
                                                            'Customer_Shipping_Address__c'
                                                            };
                                                            
            List<String> coHeaderFieldListLevel2 = new List<String>{ 'Customer__r.Total_Store_Credit__c',
                                                            'Hide_Merchandise_Section__c',
                                                            'Selling_Group__c',
                                                            'Owner__c',
	                                                        'Owner__r.Name'
                                                    };
            if(this.Level == 1) {
                return coHeaderFieldListLevel1;
            } else {
                coHeaderFieldListLevel2.addAll(coHeaderFieldListLevel1);
                return coHeaderFieldListLevel2;
            }
        }
    }
    
    public class COCardDetail {
        
        public String CustomerName;
        public String CustomerEmail;
        public String CustomerPreferredEmail;
        public String CustomerType;
        public String CustomerWorkEmail;
        public String CustomerOtherEmail;
        public String CustomerPreferredPhone;
        public String CustomerPreferredSMS;
        public String CustomerHomeNumber;
        public Boolean CustomerHomeNumberSMS;
        public String CustomerFormattedHomeNumber;
        public String CustomerWorkNumber;
        public Boolean CustomerWorkNumberSMS;
        public String CustomerFormattedWorkNumber;
        public String CustomerOtherPhone;
        public Boolean CustomerMobileNumberSMS;
        public String CustomerFormattedOtherPhone;
        public Decimal DiscountPercentage;
        public String PartPriceBase;
        public String PriceLevelStr;
        public String PriceLevelName;
        public String ExemptionTaxName;
        public Integer TotalActiveOrders;
        public String CustomerAddress ;
        public String CustomerAddress2 ;
        public String CustomerCityProv ;
        public String CustomerPostal ;
        public String CustomerState ;
        public String CustomerCountry;
        public String AddressLine1;
        public String AddressLine2;
        
        public String CustomerShippingAddress ;
        public String CustomerShippingAddress2 ;
        public String CustomerShippingCityProv ;
        public String CustomerShippingPostal ;
        public String CustomerShippingState ;
        public String CustomerShippingCountry;
        public String CustomerSurname;
       	public String CustomerNumber;
       	public String CustomerFirstName;
       	public String CustomerDriverLicenceNumber;
       	public String CustomerDOB;
       	public Boolean IsShippingAddressExist;
        public String Notes;
        public Boolean IsChargeOnAccountRestricted;
           
       	
        
        public COCardDetail() {
            this.ExemptionTaxName = '';
        }
        
        public COCardDetail(Account customerCardInfoRec, Price_Level__c defaultPriceLevelInfo, CO_Header__c coHeaderObj) {
            if(customerCardInfoRec != null){
                this.CustomerName = (customerCardInfoRec.Name != null) ? customerCardInfoRec.Name : '';
                this.CustomerEmail = (customerCardInfoRec.Email__c != null) ? customerCardInfoRec.Email__c : '';
                this.PriceLevelName = (customerCardInfoRec.Price_Level__c != null) ? customerCardInfoRec.Price_Level__r.Name__c : getSystemDefaultPriceLevelName();
                this.TotalActiveOrders = (customerCardInfoRec.CO_Headers__r.size() > 0) ? customerCardInfoRec.CO_Headers__r.size() : 0;
                this.ExemptionTaxName = '';
                /*for(Tax_Exemption__c taxExemptionRec : customerCardInfoRec.Tax_Exemptions__r) {
                    this.ExemptionTaxName += ((taxExemptionRec.Sales_Tax_Item__c != null) ? (taxExemptionRec.Sales_Tax_Item__r.Name__c + ', ') : '');
                }
                if(this.ExemptionTaxName.length() > 2) {
                    this.ExemptionTaxName = this.ExemptionTaxName.subString(0, this.ExemptionTaxName.length() - 2);
                }*/
                if(coHeaderObj != null) {
                    if(coHeaderObj.Account_Type__c != null) {
                        AccountTypeWrapper accRec = AccountTypeService.getRecForAccountType(coHeaderObj.Account_type__r.Id);
                        this.ExemptionTaxName = accRec != null ? accRec.TaxExemptions : ''; 
                    }
                } else if(customerCardInfoRec.Account_type__r.Id != null) {
		        	AccountTypeWrapper accRec = AccountTypeService.getRecForAccountType(customerCardInfoRec.Account_type__r.Id);
		        	this.ExemptionTaxName = accRec != null ? accRec.TaxExemptions : ''; 
		        }
                
                String billingStreet = (customerCardInfoRec.BillingStreet == null ) ? '' : customerCardInfoRec.BillingStreet;

                List<String> bsList = billingStreet.split('\n');
                this.CustomerAddress = (bsList.size() > 0) ? bsList[0] : '';
                this.CustomerAddress2 = (bsList.size() > 1) ? bsList[1] : '';
                CustomerCityProv    = customerCardInfoRec.BillingCity;
                CustomerCityProv    = (CustomerCityProv != null && CustomerCityProv != '') ? (CustomerCityProv ) : '';
                CustomerPostal      = customerCardInfoRec.BillingPostalCode;
                CustomerState      = customerCardInfoRec.BillingState;
                CustomerCountry = customerCardInfoRec.BillingCountry;
                
                List<String> addressPartList = new List<String>();
                if(String.isNotBlank(this.CustomerAddress)) addressPartList.add(this.CustomerAddress);
                if(String.isNotBlank(this.CustomerAddress2)) addressPartList.add(this.CustomerAddress2);
                this.AddressLine1 = String.join(addressPartList, ', ');

                addressPartList = new List<String>();
                if(String.isNotBlank(this.CustomerCityProv)) addressPartList.add(this.CustomerCityProv);
                if(String.isNotBlank(customerCardInfoRec.Billing_County_Parish__c)) addressPartList.add(customerCardInfoRec.Billing_County_Parish__c);
                if(String.isNotBlank(CustomerState)) addressPartList.add(CustomerState);
                if(String.isNotBlank(this.CustomerCountry)) addressPartList.add(this.CustomerCountry);
                if(String.isNotBlank(this.CustomerPostal)) addressPartList.add(this.CustomerPostal);
                this.AddressLine2 = String.join(addressPartList, ', ');
                
                //Shipping Street
                String shippingStreet;
                if(customerCardInfoRec.ShippingStreet != null) {
	                this.IsShippingAddressExist = true;
	                shippingStreet = customerCardInfoRec.ShippingStreet;
                } else {
                	this.IsShippingAddressExist = false;
                	shippingStreet = '';
                }
                List<String> ssList = ShippingStreet.split('\n');
                this.CustomerShippingAddress = (ssList.size() > 0) ? ssList[0] : '';
                this.CustomerShippingAddress2 = (ssList.size() > 1) ? ssList[1] : '';
                this.CustomerShippingCityProv = customerCardInfoRec.ShippingCity;
                //this.CustomerShippingCityProv = (CustomerCityProv != null && CustomerCityProv != '') ? (CustomerCityProv ) : '';
                this.CustomerShippingPostal = customerCardInfoRec.ShippingPostalCode;
                this.CustomerShippingState = customerCardInfoRec.ShippingState;
                this.CustomerShippingCountry = customerCardInfoRec.ShippingCountry;
                
                this.CustomerType = (customerCardInfoRec.Type__c != null) ? customerCardInfoRec.Type__c : '';
                
                if(customerCardInfoRec.Preferred_Phone__c != null) {
		            if(customerCardInfoRec.Preferred_Phone__c == customerCardInfoRec.Home_Number__c) {
		                this.CustomerPreferredPhone = 'HomeNumber';
		            } else if(customerCardInfoRec.Preferred_Phone__c == customerCardInfoRec.Mobile__c) {
		                this.CustomerPreferredPhone = 'OtherPhone';
		            } else if(customerCardInfoRec.Preferred_Phone__c == customerCardInfoRec.Work_Number__c) {
		                this.CustomerPreferredPhone = 'WorkNumber';
		            }
	           } else {
		            this.CustomerPreferredPhone = '';
		        }
		        
		        if(customerCardInfoRec.Preferred_SMS__c != null) {
		            if(customerCardInfoRec.Preferred_SMS__c == customerCardInfoRec.Home_Number__c) {
		                this.CustomerPreferredSMS = 'HomeNumber';
		            } else if(customerCardInfoRec.Preferred_SMS__c == customerCardInfoRec.Mobile__c) {
		                this.CustomerPreferredSMS = 'OtherPhone';
		            } else if(customerCardInfoRec.Preferred_SMS__c == customerCardInfoRec.Work_Number__c) {
		                this.CustomerPreferredSMS = 'WorkNumber';
		            }
		        } else {
		            this.CustomerPreferredSMS = '';
		        }
                
                this.CustomerPreferredEmail = (customerCardInfoRec.Preferred_Email__c == null) ? '' : customerCardInfoRec.Preferred_Email__c;
                this.CustomerWorkEmail = (customerCardInfoRec.Work_Email__c == null) ? '' : customerCardInfoRec.Work_Email__c;
                this.CustomerOtherEmail = (customerCardInfoRec.Other_Email__c == null) ? '' : customerCardInfoRec.Other_Email__c;
                
                this.CustomerHomeNumber = (customerCardInfoRec.Home_Number__c == null ) ? '' : customerCardInfoRec.Home_Number__c;
                this.CustomerHomeNumberSMS = customerCardInfoRec.Home_Number_SMS__c;
                this.CustomerFormattedHomeNumber = (customerCardInfoRec.Formatted_Home_number__c == null ) ? '' : customerCardInfoRec.Formatted_Home_number__c;
                this.CustomerWorkNumber = (customerCardInfoRec.Work_Number__c == null) ? '' : customerCardInfoRec.Work_Number__c;
                this.CustomerWorkNumberSMS = customerCardInfoRec.Work_Number_SMS__c;
                this.CustomerFormattedWorkNumber = (customerCardInfoRec.Formatted_Work_Number__c == null) ? '' : customerCardInfoRec.Formatted_Work_Number__c;
                this.CustomerOtherPhone = (customerCardInfoRec.Mobile__c == null) ? '' : customerCardInfoRec.Mobile__c;
                this.CustomerMobileNumberSMS = customerCardInfoRec.Mobile_Number_SMS__c;
                this.CustomerFormattedOtherPhone = (customerCardInfoRec.Formatted_Mobile_Number__c == null) ? '' : customerCardInfoRec.Formatted_Mobile_Number__c; 
                
                if(customerCardInfoRec.Type__c == 'Individual'){
	            	this.CustomerSurname = (customerCardInfoRec.LastName__c != null)? customerCardInfoRec.LastName__c : '';
	            	this.CustomerFirstName = (customerCardInfoRec.FirstName__c != null) ? customerCardInfoRec.FirstName__c : '';
	            } else {
	            	this.CustomerSurname = (customerCardInfoRec.Name != null)? customerCardInfoRec.Name : '';
	            	this.CustomerFirstName = '';
	            }
	            this.CustomerNumber = customerCardInfoRec.Customer_Number__c;
	            this.CustomerDriverLicenceNumber = (customerCardInfoRec.Drivers_License__c != null) ? customerCardInfoRec.Drivers_License__c : '';
	            this.CustomerDOB = (customerCardInfoRec.Birth_Date__c != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(customerCardInfoRec.Birth_Date__c.year(), customerCardInfoRec.Birth_Date__c.month(),customerCardInfoRec.Birth_Date__c.day())): '';
                this.Notes = (customerCardInfoRec.Notes__c == null) ? '' : customerCardInfoRec.Notes__c;
                this.IsChargeOnAccountRestricted = (GeneralConfiguration.getConfigurations().Is_Charge_On_Account_Restricted__c && !customerCardInfoRec.Allow_Charge_On_Account__c) ? true : false;
            }else {
            	this.PriceLevelName = defaultPriceLevelInfo != null ? defaultPriceLevelInfo.Name__c : '';
                this.ExemptionTaxName = '';
                if(coHeaderObj != null && coHeaderObj.CO_Type__c == Constants.CASH_SALE) {
                    for(Tax_Exemption__c taxExemptionRec : coHeaderObj.Tax_Exemptions__r) {
                        this.ExemptionTaxName += ((taxExemptionRec.Sales_Tax_Item__c != null) ? (taxExemptionRec.Sales_Tax_Item__r.Name__c + ', ') : '');
                    }
                    if(this.ExemptionTaxName.length() > 2) {
                        this.ExemptionTaxName = this.ExemptionTaxName.subString(0, this.ExemptionTaxName.length() - 2);
                    }
                }
            }
        }
        
        public List<String> getCustomerCardFields(){
             return new List<String>{	'Name', 
             							'Email__c', 
             							'Type__c', 
             							'Preferred_Phone__c', 
             							'Preferred_SMS__c', 
             							'Preferred_Email__c', 
             							'Home_Number__c', 
             							'Home_Number_SMS__c', 
             							'Formatted_Home_number__c', 
             							'Work_Number__c', 
             							'Work_Number_SMS__c', 
             							'Work_Email__c', 
             							'Other_Email__c', 
             							'Formatted_Work_Number__c', 
             							'Mobile__c', 
             							'Mobile_Number_SMS__c', 
             							'Formatted_Mobile_Number__c',
             							'BillingStreet','BillingCity',
             							'BillingState',
             							'BillingPostalCode',
             							'BillingCountry',
             							'Account_type__r.Id', 
             							'LastName__c', 
             							'Customer_Number__c',
             							'FirstName__c',
             							'Drivers_License__c',
             							'Birth_Date__c', 
             							'ShippingStreet', 
             							'ShippingCity', 
             							'ShippingState', 
             							'ShippingPostalCode',
                                        'ShippingCountry',
                                        'Notes__c',
                                        'Allow_Charge_On_Account__c',
                                        'Billing_County_Parish__c'
                                    };
        }
    }
    
    public class CheckoutWrapper{
        
        public List<COInvoiceItem_V2> InvoiceItemList;
        public List<COInvoicePayment> InvoicePaymentList;
        public List<PrintCustomerOrderInvoiceCtrl.TaxDetail> TaxDetails;
        public List<CODeposit> DepositList;
        public Decimal PaymentReceived;
        public Decimal BalanceDue;
    	public Decimal ChangeDue;
        public Decimal CustomerStoreCredit;
        public Decimal Total;
        public String ActiveInvoiceHeaderId;
        
        public Decimal TotalPart;
        public Decimal TotalFee;
        public Decimal TotalLabor;
        public Decimal TotalSublet;
        public Decimal TotalShopSupplies;
        public String COStatus;

        public CheckoutWrapper() {
        }
        
        public CheckoutWrapper(List<CO_Invoice_Item__c> coInvItemList, List<CO_Invoice_Payment__c> coInvPaymentList, String invHeaderId,
                               List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetail, CO_Invoice_Header__c coInvoiceHeaderRec, List<CO_Deposit__c> coDepositsList) {
            
            populateCoInvoiceItemList(coInvItemList);

            populateTaxDetail(taxDetail);
            populateCheckoutTotals(coInvoiceHeaderRec);
            
            populatePayments(coInvPaymentList);
	        populateDeposits(coDepositsList);
        }
        
        public void populateTaxDetail(List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetail) {
        	this.TaxDetails = taxDetail;
        }
        
        public void populateCheckoutTotals(CO_Invoice_Header__c coInvoiceHeaderRec) {
        	this.ActiveInvoiceHeaderId = coInvoiceHeaderRec.Id;
            this.TotalPart = coInvoiceHeaderRec.Part_Total__c;
            this.TotalFee = coInvoiceHeaderRec.Fee_Total__c;
            this.TotalLabor = coInvoiceHeaderRec.Labour_Total__c;
            this.TotalSublet = coInvoiceHeaderRec.Sublet_Total__c;
            this.TotalShopSupplies = coInvoiceHeaderRec.Shop_Supplies_Total__c;
            this.Total = coInvoiceHeaderRec.Total__c;
            this.COStatus = String.isNotBlank(coInvoiceHeaderRec.CO_Header__r.Order_Status__c) ? coInvoiceHeaderRec.CO_Header__r.Order_Status__c : 'Open';

            this.CustomerStoreCredit = coInvoiceHeaderRec.CO_Header__r.Customer__r.Total_Store_Credit__c;
            this.PaymentReceived = (coInvoiceHeaderRec.Total_Payment__c != null) ? coInvoiceHeaderRec.Total_Payment__c  : 0;
	        this.ChangeDue = 0;
            this.BalanceDue = (this.Total != null) ? this.Total - this.PaymentReceived : (-1 * this.PaymentReceived);
	        if(this.BalanceDue < 0) {
	        	this.ChangeDue = -1 * this.BalanceDue;
	        	this.BalanceDue = 0;
	        }
        }
        
        public void populateDeposits(List<CO_Deposit__c> coDepositsList) {
        	this.DepositList = new List<CODeposit>(); 
	        for(CO_Deposit__c coDeposit  : coDepositsList) {
	            this.DepositList.add(new CODeposit(coDeposit));
	        }
        }
        
        public void populatePayments(List<CO_Invoice_Payment__c> coInvPaymentList) {
        	this.InvoicePaymentList = new List<COInvoicePayment>();
        	for(CO_Invoice_Payment__c coPaymentRec : coInvPaymentList) {
                this.InvoicePaymentList.add(new COInvoicePayment(coPaymentRec)); 
            }
        }


        public void populateCoInvoiceItemList(List<CO_Invoice_Item__c> coInvItemList) {
        	this.InvoiceItemList = new List<COInvoiceItem_V2>();
        	for(CO_Invoice_Item__c coInvRec : coInvItemList) {
                if((coInvRec.Service_Order_Header__c != null && (coInvRec.Service_Order_Header__r.Deal__c != null ||
		                	coInvRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Internal' || coInvRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit')) || 
		                	(coInvRec.CO_Line_Item__c != null && coInvRec.CO_Line_Item__r.Deal__c != null) || 
		                	(coInvRec.CO_Kit_Header__c != null && coInvRec.CO_Kit_Header__r.Deal__c != null)) {
            		continue;
            	}
                this.InvoiceItemList.add(new COInvoiceItem_V2(coInvRec));
            }
        }
    }
    
    public class COKitHeader {
    	
        public List<COLIWrapper> COLIList {get; set;}
        public Decimal Price {get; set;}
        public String ItemDescription {get; set;}
        public Boolean CanItSplit {get; set;}
        public String Code {get; set;}
        public Boolean IsServiceKit {get; set;}
        public String Id {get; set;}
        public Decimal FixedPrice {get; set;}
        public Decimal RetailPrice {get; set;}
        public Boolean IsFixedPrice {get; set;} 
        public Boolean hasChildren {get; set;}
        public Decimal ActualKitPrice {get; set;}
        public Boolean IsFixedKitHeaderCO {get; set;}
        public Decimal TaxAmount {get; set;}
        public String DealId {get; set;}
        public String UUID;
    	
    	public COKitHeader(CO_Kit_Header__c coKitHeaderRec, List<CO_Line_Item__c> coliList, Boolean hasChild) {
    		this.hasChildren = hasChild;
    		this.TaxAmount = coKitHeaderRec.Tax_Amount__c;
    		this.Price = (coKitHeaderRec.Price__c != null) ? coKitHeaderRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
    		this.ItemDescription = coKitHeaderRec.Kit_Header__r.Kit_Unique_Name__c;
			this.Id = coKitHeaderRec.Id;
			this.IsServiceKit = (coKitHeaderRec.Service_Kit__c == null) ? false : coKitHeaderRec.Service_Kit__c;
			this.IsFixedPrice = (coKitHeaderRec.Fixed_Price_Flag__c == null) ? false : coKitHeaderRec.Fixed_Price_Flag__c;
			this.CanItSplit = (coKitHeaderRec.Can_Split__c == null) ? false : coKitHeaderRec.Can_Split__c;
			this.ActualKitPrice = (coKitHeaderRec.Actual_Kit_Price__c != null) ? coKitHeaderRec.Actual_Kit_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.DealId = coKitHeaderRec.Deal__c;
            this.UUID = (coKitHeaderRec != null && coKitHeaderRec.Id != null) ? coKitHeaderRec.UUID__c : (coliList.size() > 0 ? coliList[0].UUID__c : null);
    		this.COLIList = new List<COLIWrapper>();
    		
    		for(CO_Line_Item__c coliRec : coliList) {
    			this.COLIList.add(new COLIWrapper(coliRec));
    		}
    		this.IsFixedKitHeaderCO = coKitHeaderRec.CO_Fixed_KitHeader__c;
    	}
    }
    
    public static List<CO_Invoice_Payment__c> sortCOPayment(List<CO_Invoice_Payment__c> coPaymentList) {
    	Map<Id, CO_Invoice_Payment__c> coPaymentIdToCoPaymentRecMap = new Map<Id, CO_Invoice_Payment__c>();
    	for(CO_Invoice_Payment__c coPaymentRec : coPaymentList) {
    		coPaymentIdToCoPaymentRecMap.put(coPaymentRec.Id, coPaymentRec);
    	}
    	
    	Set<Id> coPaymentIdSet = new Set<Id>();
    	List<CO_Invoice_Payment__c> coPaymentSortedList = new List<CO_Invoice_Payment__c>();
    	for(CO_Invoice_Payment__c coPaymentRec : coPaymentList) {
    		if(!coPaymentIdSet.contains(coPaymentRec.Id)){
    			coPaymentIdSet.add(coPaymentRec.Id);
    			coPaymentSortedList.add(coPaymentRec);
    			if(coPaymentRec.Reverse_Link__c != null && coPaymentIdToCoPaymentRecMap.containsKey(coPaymentRec.Reverse_Link__c)) {
    				coPaymentIdSet.add(coPaymentRec.Reverse_Link__c);
    				coPaymentSortedList.add(coPaymentIdToCoPaymentRecMap.get(coPaymentRec.Reverse_Link__c));
    			}
    		}
    	}
    	return coPaymentSortedList;
    }
    
    public static List<COKitHeader> getCOLineItemsList(List<CO_Line_Item__c> coLineItemListObj, List<CO_Kit_Header__c> coKitHeaders ) {
    	
    	List<COKitHeader> coKHObjList = new List<COKitHeader>();
    	List<DateTime> sortedDateTimeList = new List<dateTime>();
    	Set<Id> coliIdSet = new Set<Id>();
    	for(CO_Kit_Header__c cokh : coKitHeaders) {
    		sortedDateTimeList.add(cokh.CreatedDate);
    		
    		coKHObjList.add(new COKitHeader(cokh, cokh.CO_Line_Items__r, true));
        	for(CO_Line_Item__c coliRec : cokh.CO_Line_Items__r) {
        		coliIdSet.add(coliRec.Id);
        	} 
    	}
    	
    	Integer lastIndexValue = 0;
		system.debug('Sorting Started OF COLIs -->>');
		system.debug(sortedDateTimeList);
		for(CO_Line_Item__c coliRec : coLineItemListObj) {
    		if(!coliIdSet.contains(coliRec.Id)) {
    			for(Integer i = lastIndexValue; i < sortedDateTimeList.size(); i++){
    				system.debug(i);
    				if(sortedDateTimeList[i] < coliRec.CreatedDate){ 
    					lastIndexValue ++;
    				} else {
    					break;
    				}
    			}
    			system.debug('lastIndexValue  ' + lastIndexValue);
    			
    			if(coKHObjList.size() > lastIndexValue){
    				coKHObjList.add(lastIndexValue, new COKitHeader(new CO_Kit_Header__c(), new List<CO_Line_Item__c>{coliRec}, false));
    				
    				if(sortedDateTimeList.size() > lastIndexValue){
    					sortedDateTimeList.add(lastIndexValue, coliRec.CreatedDate);
    				} else {
    					sortedDateTimeList.add(coliRec.CreatedDate);
    				}
    				
    				lastIndexValue++;
    			} else {
    				coKHObjList.add(new COKitHeader(new CO_Kit_Header__c(), new List<CO_Line_Item__c>{coliRec}, false));
    				lastIndexValue++;
    			}
    			system.debug('lastIndexValue : ' +lastIndexValue + '\n\n\nSOGridItems : ' + coKHObjList);
    			system.debug('sortedDateTimeList : ' + sortedDateTimeList);
    		}
    	}
    	return coKHObjList;
    }
	
    private static String getSystemDefaultPriceLevelName() {
        String systemDefaultPriceLevelName = '';
        List<Price_Level__c> defaultPriceLevelList = [select Name__c from Price_Level__c where Default__c = true];
        if(defaultPriceLevelList.size() > 0) {
            systemDefaultPriceLevelName = defaultPriceLevelList[0].Name__c;
        }  
        return systemDefaultPriceLevelName;
    }

    public class LineItemWrapper {
        public String EntityId;
        public String UUID;

        public LineItemWrapper(String entityId, String UUID) {
            this.EntityId = entityId;
            this.UUID = UUID;
        }
    }
}
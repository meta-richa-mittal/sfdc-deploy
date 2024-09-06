/**
 * Author: Tarun Khandelwal
 * Since: June 05, 2015
 * Name: CustomerDetail
 * Description: Apex class to handle JSON related oprations of Customer Detail Page.
**/
public without sharing class CustomerDetail {
    
    public Customer CustomerInfo {get; set;}
    
    // open orders
    public Decimal OpenOrders;
    
    // Average Life Time
    public Decimal OrdersLifetime;
    
    // Average Spend per Hours
    public Decimal AverageSpendPerHour;
    
    // Last Visited Order Time
    public String LastVisit;
    
    // Related Customer
    public Integer TotalCustomerRecords;
    public List<RelatedCustomer> RelatedCustomerList;
    
    // COU list
    public Integer TotalCOURecords;
    public List<CustomerOwnedUnit> CustomerOwnedUnitList;
    
    // Contacts List
    public Integer TotalContactRecords;
    public List<CustomerContact> ContactList;
    
    // Active Orders
    public Integer TotalActiveOrderRecords;
    public List<ActiveOrder> ActiveOrderList;
    
    // Active Sales Order (Customer Header)
    public Integer TotalActiveSalesOrderRecords;
    public List<ActiveSalesOrder> ActiveSalesOrderList;
    
    // Tax Exemptions
    public Integer TotalTaxExemptionRecords;
    public List<TaxExemptions> TaxExemptionList;
    
    
    public Integer TotalStoreCreditRecords;
    public List<StoreCredit> StoreCreditList;
    
    public Company CompanyName; 
    public List<ApplicableTax> ApplicableTaxList;
    
    // All Sales Order (Customer Header) 
    public Integer TotalCustomerOrderRecords; // Added by richa 26/01/2017 for retrieving all CO's for a customer
    public List<ActiveSalesOrder> AllCustomerOrderList; // Added by richa 26/01/2017 for retrieving all CO's for a customer
    
    public Integer TotalMessageRecords;
    public List<MessageHistory> SMSMessageList;  

    // Constructor  
    public CustomerDetail(Account customerRec, List<Account> relatedCustomersList, Map<String, String> accountIdToRelationMap, List<Customer_Owned_Unit__c> couList, 
                            List<CO_Header__c> ActiveSalesOrdersList, List<Contact> customerContactList, String lastVisitedValue,
                            List<Tax_Exemption__c> taxExemptionList, List<Business_Profile__c> businessProfileList, 
                            List<Sales_Tax__c> applicableTaxList, List<CO_Header__c> AllCustomerOrdersList,
    						List<Store_Credit__c> storeCreditList, List<Message_History__c> msgList, String taxExemption) { // List<CO_Header__c> AllCustomerOrdersList Added by richa 26/01/2017 for retrieving all CO's
    	this.customerInfo = new Customer(customerRec, taxExemption); 
        this.RelatedCustomerList = new List<RelatedCustomer>();
        this.CustomerOwnedUnitList = new List<CustomerOwnedUnit>();
        this.ContactList = new List<CustomerContact>();
        this.ActiveOrderList = new List<ActiveOrder>();
        this.ActiveSalesOrderList = new List<ActiveSalesOrder>();
        this.TaxExemptionList = new List<TaxExemptions>();
        this.ApplicableTaxList = new List<ApplicableTax>();
        this.AllCustomerOrderList = new List<ActiveSalesOrder>(); // Added by richa 26/01/2017 for retrieving all CO's for a customer 
        this.StoreCreditList = new List<StoreCredit>();
        
        this.OpenOrders = customerRec.Open_Orders__c;
        this.OrdersLifetime = customerRec.Orders_Lifetime__c;
        this.AverageSpendPerHour = customerRec.Average_Spend_per_Order__c;
        this.LastVisit = lastVisitedValue; 
        
        for(Account relatedCustomerRec : relatedCustomersList) {
            this.RelatedCustomerList.add(new RelatedCustomer(relatedCustomerRec, accountIdToRelationMap));
        }
        
        for(Customer_Owned_Unit__c couRec : couList) {
            this.CustomerOwnedUnitList.add(new CustomerOwnedUnit(couRec));
        }
        
        for(CO_Header__c coh : ActiveSalesOrdersList) {
            this.ActiveSalesOrderList.add(new ActiveSalesOrder(coh));
        }
        
        for(Contact contactRec : customerContactList) {
            this.ContactList.add(new CustomerContact(contactRec));
        }
        
        for(CO_Header__c coh : AllCustomerOrdersList) { // Added by richa 26/01/2017 for retrieving all CO's for a customer 
            this.AllCustomerOrderList.add(new ActiveSalesOrder(coh));
        }
        
        for(Store_Credit__c sc : storeCreditList){
            this.StoreCreditList.add(new StoreCredit(sc));
        }

        Map<Id, List<String>> salesTaxItemIdToAppliesToList = getAppliesToList(taxExemptionList);
        for(Tax_Exemption__c taxExemptionRec : taxExemptionList) {
            this.TaxExemptionList.add(new TaxExemptions(taxExemptionRec, salesTaxItemIdToAppliesToList.get(taxExemptionRec.Sales_Tax_Item__c)));
        }
        
        for(Sales_Tax__c applicableTaxRec : applicableTaxList) {
            this.ApplicableTaxList.add(new ApplicableTax(applicableTaxRec));
        }
        
        ActiveOrder.RelatedListPaginationSorting pageSort = new ActiveOrder.RelatedListPaginationSorting();
        pageSort.activeOrdersCurrentPage = 1;
        pageSort.activeOrdersPageSize = 1;

        this.ActiveOrderList = ActiveOrder.getAllActiveOrdersForCustomer(customerRec.Id, system.JSON.serialize(pageSort));
        if(businessProfileList.size() > 0) {
            this.CompanyName = new Company(businessProfileList[0]);
        } else {
            this.CompanyName = new Company(new Business_Profile__c());
        }
        
        SMSMessageList = new List<CustomerDetail.MessageHistory>();
        for(Message_History__c smsRec : msgList) { 
            SMSMessageList.add(new CustomerDetail.MessageHistory(smsRec));
        }
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: CustomerDetail - Class Object
    **/
    public static CustomerDetail parse(String json) {
        return (CustomerDetail) System.JSON.deserialize(json, CustomerDetail.class);
    }
    
    public static Map<Id, List<String>> getAppliesToList(List<Tax_Exemption__c> taxExemptionList) {
        Set<Id> salesTaxItemIdSet = new Set<Id>();
        for(Tax_Exemption__c taxExemptionRec : taxExemptionList) {
            salesTaxItemIdSet.add(taxExemptionRec.Sales_Tax_Item__c);
        }
        
        if(salesTaxItemIdSet.size() == 0) {
            return new Map<Id, List<String>>();
        }
        
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = new Map<Id, List<String>>(); 
        if(AccessControl.ifObjectIsAccessible('Applicable_Taxes__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Applicable_Taxes__c> appTaxList = [select Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax__r.Name__c from Applicable_Taxes__c
                                                    where Sales_Tax_Item__c IN: salesTaxItemIdSet];
        
        for(Applicable_Taxes__c appTaxRec : appTaxList) {
            if(appTaxRec.Sales_Tax__c != null) {
                List<String> appliesToList;
                if(!salesTaxItemIdToAppliesToList.containsKey(appTaxRec.Sales_Tax_Item__c)) {
                    salesTaxItemIdToAppliesToList.put(appTaxRec.Sales_Tax_Item__c, new List<String>());
                }
                salesTaxItemIdToAppliesToList.get(appTaxRec.Sales_Tax_Item__c).add(appTaxRec.Sales_Tax__r.Name__c);
            }
        }
        return salesTaxItemIdToAppliesToList;
    } 

    public class Company {
         
    	public String LogoURL {get; set;}
        public String Address1 {get; set;} 
        public String Address2 {get; set;}
        public String State {get; set;}
        public String PostalCode {get; set;}
        public String Country {get; set;}
        public String City {get; set;} 
        public String Address {get; set;}
        public String CompanyName {get; set;} 
        public String BusinessPhone {get; set;}
        public String FormattedBusinessPhone {get;set;}
        public String BusinessEmail {get; set;}
        public String TaxId {get; set;}
        public Decimal LogoHeight {get; set;}
		public Decimal LogoWidth {get; set;}
        
        public Company(Business_Profile__c businessProfileRec) {
    		this.LogoURL = GeneralConfiguration.getCompanyLogoUrl();
    		this.Address1 = businessProfileRec.Business_Street_Address1__c != null ? (businessProfileRec.Business_Street_Address1__c).replace(',', ' ') : '';
    		this.Address2 = businessProfileRec.Business_Street_Address2__c != null ? (businessProfileRec.Business_Street_Address2__c).replace(',', ' ') : '';
            this.City = businessProfileRec.Business_City__c;
            this.State = (businessProfileRec.Business_State__c != null) ? businessProfileRec.Business_State__r.Name__c : '';
            this.PostalCode = businessProfileRec.Business_Postal_Code__c;
            this.Country = (businessProfileRec.Business_Country__c != null) ? businessProfileRec.Business_Country__r.Name__c : '';
            this.CompanyName = (businessProfileRec.Business_Name__c != null) ? businessProfileRec.Business_Name__c : '';
            this.BusinessPhone = (businessProfileRec.Business_Phone__c != null) ? businessProfileRec.Business_Phone__c : '';
            this.FormattedBusinessPhone = (businessProfileRec.Formatted_Business_Number__c != null) ? businessProfileRec.Formatted_Business_Number__c : '';
            this.BusinessEmail = (businessProfileRec.Business_Email__c != null) ? businessProfileRec.Business_Email__c : '';
            this.TaxId = Configurations__c.getOrgDefaults().Tax_Id__c == null ? '' : Configurations__c.getOrgDefaults().Tax_Id__c;
            this.Address = '';
            if(this.Address1 != null) {
                this.Address += this.Address1 + ', ';
            }
            if(this.Address2 != null) {
                this.Address += this.Address2 + ', ';
            }
            if(this.City != null) {
                this.Address += this.City + ', ';
            }
            if(this.State != null) {
                this.Address += this.State + ', ';
            }
            if(this.Country != null) {
                this.Address += this.Country + ', ';
            }
            if(this.PostalCode != null) {
                this.Address += this.PostalCode + ', ';
            }
            if(this.Address.length() > 1) {
                this.Address = this.Address.subString(0, this.Address.length() - 2).replace(',', ' ');
            }
        }
    	
    	public Company(BrandingLocationWrapper brandingLocationObj) {
        	this.LogoURL = brandingLocationObj.AttachmentURL;
	        
    		this.Address1 = brandingLocationObj.BusinessStreetAddress1 != null ? (brandingLocationObj.BusinessStreetAddress1).replace(',', ' ') : '';
    		this.Address2 = brandingLocationObj.BusinessStreetAddress2 != null ? (brandingLocationObj.BusinessStreetAddress2).replace(',', ' ') : '';
    		this.City = brandingLocationObj.BusinessCity != null ? brandingLocationObj.BusinessCity : '';
    		this.State = (brandingLocationObj.BusinessState != null) ? brandingLocationObj.BusinessState : '';
    		this.PostalCode = brandingLocationObj.BusinessPostalCode != null ? brandingLocationObj.BusinessPostalCode : '';
    		this.Country = (brandingLocationObj.BusinessCountry != null) ? brandingLocationObj.BusinessCountry : '';
    		this.CompanyName = (brandingLocationObj.BusinessLocationName != null) ? brandingLocationObj.BusinessLocationName : '';
    		this.BusinessPhone = (brandingLocationObj.BusinessPhone != null) ? brandingLocationObj.BusinessPhone : '';
    		this.FormattedBusinessPhone = (brandingLocationObj.FormattedBusinessPhone != null) ? brandingLocationObj.FormattedBusinessPhone : '';
    		this.BusinessEmail = (brandingLocationObj.BusinessEmailAddress != null) ? brandingLocationObj.BusinessEmailAddress : '';
    		this.TaxId = brandingLocationObj.TaxID != null ? brandingLocationObj.TaxID : '';
    		this.Address = '';
    		this.Address += this.Address1 != null ? this.Address1 + ', ' : '';
    		this.Address += this.Address2 != null ? this.Address2 + ', ' : '';
    		this.Address += this.City != null ? this.City + ', ' : '';
    		this.Address += this.State != null ? this.State + ', ' : '';
    		this.Address += this.Country != null ? this.Country + ', ' : '';
    		this.Address += this.PostalCode != null ? this.PostalCode + ', ' : '';
    		
    		if(this.Address.length() > 1) {
    			this.Address = this.Address.subString(0, this.Address.length() - 2).replace(',', ' ');
    		}
    		this.LogoHeight = brandingLocationObj.LogoHeight;
            this.LogoWidth = brandingLocationObj.LogoWidth;
    	}
    }
    
    
    public class ApplicableTax {
        public String Id;
        public String ApplicableTaxName;
        
        public ApplicableTax(Sales_Tax__c applicableTaxRec) {
            this.Id = applicableTaxRec.Id;
            this.ApplicableTaxName = applicableTaxRec.Name__c;
        }
    }
    
    public class MessageHistory {
        public String Id;
        public String Activity;
        public String SentBy;
        public String SentTo;
        public String SentToId;
        public String Text;
        public String SentTime;
        public String InvoiceNumber;
        public String COHeaderNumber;
        public String SMSDirection;
        public String SentFrom;
        public String SentFromId;
        
        public MessageHistory() {}
        
        public MessageHistory(Message_History__c messageRec) {
	        this.Id = String.isNotBlank(messageRec.Id) ? messageRec.Id : '';
	        this.Activity = messageRec.Activity__c;
	        this.SentBy = messageRec.Sent_By__r.Name;
	        this.SentTime = BPUtility.getFormatedDateAndTime((messageRec.SMS_Direction__c == Constants.SMS_DIRECTION_REPLY && messageRec.Incoming_SMS_Time__c != null) ? 
	    						messageRec.Incoming_SMS_Time__c : messageRec.CreatedDate);
	        this.SentToId =  messageRec.Sent_To__c; 
	        this.Text = messageRec.Text__c; 
	        if(messageRec.Activity__c == Constants.MESSAGE_HISTORY_ACTIVITY_TEXT_MESSAGE) {
	            if(messageRec.SMS_Direction__c == Constants.SMS_DIRECTION_REPLY) {
	            	this.Activity = 'Text Reply';
	            	this.SentBy = messageRec.Formatted_Phone__c;
	            	this.SentTo =  messageRec.Formatted_Dealership_Phone__c;
	            } else {
	            	this.SentTo =  messageRec.Formatted_Phone__c; 
	            }
	        } else {
	            this.SentTo =  messageRec.Email__c; 
	            if(messageRec.CO_Invoice_Header__c != null) {
	                this.InvoiceNumber = messageRec.CO_Invoice_Header__r.Invoice_Number__c;
	                this.COHeaderNumber = messageRec.CO_Invoice_Header__r.CO_Header__c;
		        }
	        }
	    }
	    
	    public MessageHistory(Message_History__c messageRec, Boolean isCOTextHistory) {
	    	this.SMSDirection = messageRec.SMS_Direction__c;
	    	this.Text = messageRec.Text__c;
	    	this.SentTime = BPUtility.getFormatedDateAndTimeWithHypen((messageRec.SMS_Direction__c == Constants.SMS_DIRECTION_REPLY && messageRec.Incoming_SMS_Time__c != null) ? 
	    						messageRec.Incoming_SMS_Time__c : messageRec.CreatedDate);
	        if(messageRec.SMS_Direction__c == Constants.SMS_DIRECTION_REPLY) {
	        	this.SentFrom = messageRec.Formatted_Phone__c;
	        } else if(messageRec.SMS_Sent_From__c == Constants.SMS_SENT_FROM_CUSTOMER) {
	        	this.SentFrom = 'Customer record';
	        	this.SentFromId = messageRec.Sent_To__c;
	        } else if(messageRec.SMS_Sent_From__c == Constants.SMS_SENT_FROM_CO) {
	        	this.SentFrom = messageRec.CO_Header__r.Name;
	        	this.SentFromId = messageRec.CO_Header__c;
	        }
	    }
    }
    
    public static List<String> getMessageFieldList(){
        List<String> msgFieldList = new List<String>{'Activity__c',
                                                    'Sent_By__r.Name',
                                                    'Sent_To__c',
                                                    'Text__c',
                                                    'Phone__c',
                                                    'Formatted_Phone__c',
                                                    'Email__c',
                                                    'CO_Invoice_Header__r.Invoice_Number__c',
                                                    'CO_Invoice_Header__r.CO_Header__c',
                                                    'CreatedDate',
                                                    'SMS_Direction__c',
                                                    'Incoming_SMS_Time__c',
                                                    'Formatted_Dealership_Phone__c'
                                                };
        return msgFieldList;
    } 
}
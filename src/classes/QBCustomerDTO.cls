public without sharing class QBCustomerDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
    public String GivenName;
    public String MiddleName;
    public String FamilyName;
    public String DisplayName;
    public String CompanyName;
    public Decimal Balance;
    public Boolean Active;
    public Boolean sparse;
    public QuickBooksPhoneWrapper PrimaryPhone;
    public QuickBooksPhoneWrapper AlternatePhone;
    public QuickBooksPhoneWrapper Mobile;
    public QuickBooksPhoneWrapper Fax;
    public QuickBooksEmailWrapper PrimaryEmailAddr;
    public QuickBooksWebAddrWrapper WebAddr;
    public QuickBooksAddressWrapper BillAddr;
    public QuickBooksAddressWrapper ShipAddr;
    public QBInnerEntityWrapper SalesTermRef;

    public QBCustomerDTO(String accId, String syncToken, Boolean isActive) {
        this.Id = accId;
        this.SyncToken = syncToken;
        this.sparse = true;
        this.Active = isActive;
    }
    
    public QBCustomerDTO(AccountingCustomer customerRecord) {
        String updatedFields = customerRecord.QBUpdatedField;
        this.Id = customerRecord.AccountingId;
        this.SFId = customerRecord.Id;
        this.SyncToken = customerRecord.SyncToken;
        this.sparse = true;
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('FirstName__c'))) {
            this.GivenName = customerRecord.FirstName; 
        }
        if(String.isNotBlank(this.GivenName) &&  this.GivenName.trim().length() > 25){
            this.GivenName = this.GivenName.substring(0,25);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('LastName__c'))) {
            this.FamilyName = customerRecord.LastName;
        }
        if(String.isNotBlank(this.FamilyName) && this.FamilyName.trim().length() > 25) {
            this.FamilyName =  this.FamilyName.substring(0,25);
        }
        
        if(customerRecord.Type != null && customerRecord.Type == 'Individual' && !customerRecord.IsProvider) {
            this.DisplayName = customerRecord.FirstName + ' ' + customerRecord.LastName;
        } else if((customerRecord.Type != null && customerRecord.Type == 'Business') || customerRecord.IsProvider) {
            this.DisplayName = customerRecord.BusinessName;
        }

        if(String.isNotBlank(this.DisplayName))	{
            if(this.DisplayName.trim().length() > 90) {
                this.DisplayName =  this.DisplayName.substring(0,90) + customerRecord.CustomerNumber;
            } else {
                this.DisplayName =  this.DisplayName + ' ' + customerRecord.CustomerNumber;
            }
        }
        if(customerRecord.Type != null && customerRecord.Type == 'Individual') {
            this.CompanyName = customerRecord.Company;
        } else if(customerRecord.Type != null && customerRecord.Type == 'Business') {
            this.CompanyName = customerRecord.BusinessName;
        }
        if(String.isNotBlank(this.CompanyName) && this.CompanyName.trim().length() > 50) {
            this.CompanyName =  this.CompanyName.substring(0,50);
        }
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Active__c'))) {
            this.Active = customerRecord.Active;
        }
        if(customerRecord.Type == 'Business') {
            if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Work_Number__c'))) {
                this.PrimaryPhone = new QuickBooksPhoneWrapper(customerRecord.WorkNumber);
            }
        
            if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Work_Email__c'))) {
                this.PrimaryEmailAddr = new QuickBooksEmailWrapper(customerRecord.WorkEmail);
            }
        } else if(customerRecord.Type == 'Individual') {
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Home_Number__c'))) {
                this.PrimaryPhone = new QuickBooksPhoneWrapper(customerRecord.HomeNumber);
            }
            
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Email__c'))) {
                this.PrimaryEmailAddr = new QuickBooksEmailWrapper(customerRecord.HomeEmail);
            }
        }
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Mobile__c'))) {
            this.AlternatePhone = new QuickBooksPhoneWrapper(customerRecord.OtherPhone);
            this.Mobile = new QuickBooksPhoneWrapper(customerRecord.OtherPhone);
        }
        
        QuickBooksAddressWrapper qbBillingAddObj = new QuickBooksAddressWrapper(customerRecord.BillingStreet1, customerRecord.BillingStreet2,
                                                    customerRecord.BillingCity, customerRecord.BillingCountry,
                                                    customerRecord.BillingState, customerRecord.BillingPostalCode, updatedFields, true);
        if(qbBillingAddObj.Line1 != null || qbBillingAddObj.Line2 != null || qbBillingAddObj.City != null || qbBillingAddObj.Country != null
                || qbBillingAddObj.CountrySubDivisionCode != null || qbBillingAddObj.PostalCode != null) {
            this.BillAddr = qbBillingAddObj;
        }
        
        QuickBooksAddressWrapper qbShippingAddObj = new QuickBooksAddressWrapper(customerRecord.ShippingStreet1, customerRecord.ShippingStreet2,
                                                    customerRecord.ShippingCity, customerRecord.ShippingCountry,
                                                    customerRecord.ShippingState, customerRecord.ShippingPostalCode, updatedFields, false);
        if(qbShippingAddObj.Line1 != null || qbShippingAddObj.Line2 != null || qbShippingAddObj.City != null || qbShippingAddObj.Country != null
                || qbShippingAddObj.CountrySubDivisionCode != null || qbShippingAddObj.PostalCode != null) {
            this.ShipAddr = qbShippingAddObj;
        }
    }
    
    public class QuickBooksPhoneWrapper{
        public String FreeFormNumber;
        public QuickBooksPhoneWrapper(String FreeFormNumber) {
            this.FreeFormNumber = FreeFormNumber;  
            if(!String.isBlank(this.FreeFormNumber) &&  this.FreeFormNumber.trim().length() > 21)	{
                this.FreeFormNumber =  this.FreeFormNumber.substring(0,21);
            }  		
        }
    }
    
    public class QuickBooksEmailWrapper{
        public String Address;
        public QuickBooksEmailWrapper(String Address) {
            this.Address = Address;
        }
    }
    
    public class QuickBooksWebAddrWrapper {
        public String URI;
        public QuickBooksWebAddrWrapper(String URI) { 
            this.URI = URI;
        }
    } 
    
    public class QuickBooksAddressWrapper {
        public String Line1;
        public String Line2;
        public String City;
        public String Country;
        public String CountrySubDivisionCode;
        public String PostalCode;
        
        public QuickBooksAddressWrapper() {
            
        }
        public QuickBooksAddressWrapper(String Line1, String Line2, String City, String Country, String CountrySubDivisionCode, String PostalCode,
                            String updatedFields, Boolean isBillingAddress) {
                                
            if(isBillingAddress) {
                if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && (updatedFields.contains('BillingStreet') || 
                        updatedFields.contains('BillingCity') || updatedFields.contains('BillingCountry') || updatedFields.contains('BillingState')
                        || updatedFields.contains('BillingPostalCode')))) {
                    this.Line1 = Line1;
                    this.Line2 = Line2;
                    this.City = City;
                    this.Country = Country;
                    this.CountrySubDivisionCode = CountrySubDivisionCode;
                    this.PostalCode = PostalCode;
                }
            } else {
                if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && (updatedFields.contains('ShippingStreet') || 
                        updatedFields.contains('ShippingCity') || updatedFields.contains('ShippingCountry') || updatedFields.contains('ShippingState')
                        || updatedFields.contains('ShippingPostalCode')))) {
                    
                    this.Line1 = Line1;
                    this.Line2 = Line2;
                    this.City = City;
                    this.Country = Country;
                    this.CountrySubDivisionCode = CountrySubDivisionCode;
                    this.PostalCode = PostalCode;
                }
            }	                      
            if(String.isNotBlank(this.Line1) && this.Line1.trim().length() > 500) {
                this.Line1 =  this.Line1.substring(0,500);
            }
            if(String.isNotBlank(this.Line2) && this.Line2.trim().length() > 500) {
                this.Line2 =  this.Line2.substring(0,500);
            }
            if(String.isNotBlank(this.City) && this.City.trim().length() > 255) {
                this.City =  this.City.substring(0,255);
            }
            if(String.isNotBlank(this.Country) && this.Country.trim().length() > 255) {
                this.Country =  this.Country.substring(0,255);
            }
            if(String.isNotBlank(this.CountrySubDivisionCode) && this.CountrySubDivisionCode.trim().length() > 255)	{
                this.CountrySubDivisionCode =  this.CountrySubDivisionCode.substring(0,255);
            }
            if(String.isNotBlank(this.PostalCode) && this.PostalCode.trim().length() > 31)	{
                this.PostalCode =  this.PostalCode.substring(0,31);
            }
        }
    }
}
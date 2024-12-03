public without sharing class QBVendorDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
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
    public String AcctNum;
    public QBInnerEntityWrapper TermRef;
    public QBInnerEntityWrapper CurrencyRef;

    public QBVendorDTO(String accId, String syncToken, Boolean isActive) {
        this.Id = accId;
        this.SyncToken = syncToken;
        this.sparse = true;
        this.Active = isActive;
    }
   
    public QBVendorDTO(AccountingVendor vendorRecord) {
        this.SFId = vendorRecord.Id;
        String updatedFields = vendorRecord.QBUpdatedField;
        this.Id = vendorRecord.AccountingId;
        this.SyncToken = vendorRecord.SyncToken;
        this.sparse = true;

        if(String.isNotBlank(vendorRecord.CurrencyCode)) {
            this.CurrencyRef = new QBInnerEntityWrapper(vendorRecord.CurrencyCode, null);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Name')) || String.isBlank(vendorRecord.AccountingId)) {
            vendorRecord.VendorName = ((vendorRecord.VendorName.trim().length() > 90) ? vendorRecord.VendorName.trim().substring(0,90) : vendorRecord.VendorName.trim());
            this.DisplayName = vendorRecord.VendorName + ' ' + vendorRecord.VendorNumber;
            if(String.isNotBlank(vendorRecord.VendorName)) {
                this.CompanyName = ((vendorRecord.VendorName.trim().length() > 50) ? vendorRecord.VendorName.trim().substring(0,50) : vendorRecord.VendorName.trim());
            }
        }
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Active__c'))) {
            this.Active = vendorRecord.Active;
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Work_Number__c'))) {
            this.PrimaryPhone = new QuickBooksPhoneWrapper(vendorRecord.WorkNumber);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Mobile__c'))) {
            this.AlternatePhone = new QuickBooksPhoneWrapper(vendorRecord.OtherPhone);
            this.Mobile = new QuickBooksPhoneWrapper(vendorRecord.OtherPhone);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Fax'))) {
            this.Fax = new QuickBooksPhoneWrapper(vendorRecord.Fax);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Email__c'))) {
            this.PrimaryEmailAddr = new QuickBooksEmailWrapper(vendorRecord.WorkEmail);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Website'))) {
            if(String.isNotBlank(vendorRecord.Website) && !(vendorRecord.Website.startsWithIgnoreCase('http://') || vendorRecord.Website.startsWithIgnoreCase('https://'))){
                vendorRecord.Website = 'http://'+vendorRecord.Website;
            }
            this.WebAddr = new QuickBooksWebAddrWrapper(vendorRecord.Website);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('AccountNumber'))) {
            this.AcctNum = vendorRecord.VendorAccountNumber;
        }
        
        QuickBooksAddressWrapper qbBillingAddObj = new QuickBooksAddressWrapper(vendorRecord.BillingStreet1, vendorRecord.BillingStreet2,
                                                    vendorRecord.BillingCity, vendorRecord.BillingCountry,
                                                    vendorRecord.BillingState, vendorRecord.BillingPostalCode, updatedFields, true);
        if(qbBillingAddObj.Line1 != null || qbBillingAddObj.Line2 != null || qbBillingAddObj.City != null || qbBillingAddObj.Country != null
                || qbBillingAddObj.CountrySubDivisionCode != null || qbBillingAddObj.PostalCode != null) {
            this.BillAddr = qbBillingAddObj;
        }
        
        QuickBooksAddressWrapper qbShippingAddObj = new QuickBooksAddressWrapper(vendorRecord.ShippingStreet1, vendorRecord.ShippingStreet2,
                                                    vendorRecord.ShippingCity, vendorRecord.ShippingCountry,
                                                    vendorRecord.ShippingState, vendorRecord.ShippingPostalCode, updatedFields, false);
        if(qbShippingAddObj.Line1 != null || qbShippingAddObj.Line2 != null || qbShippingAddObj.City != null || qbShippingAddObj.Country != null
                || qbShippingAddObj.CountrySubDivisionCode != null || qbShippingAddObj.PostalCode != null) {
            this.ShipAddr = qbShippingAddObj;
        }
        /*this.BillAddr = new QuickBooksAddressWrapper(vendorRecord.BillingStreet1, vendorRecord.BillingStreet2,
                                                    vendorRecord.BillingCity, vendorRecord.BillingCountry,
                                                    vendorRecord.BillingState, vendorRecord.BillingPostalCode, updatedFields, true);
        this.ShipAddr = new QuickBooksAddressWrapper(vendorRecord.ShippingStreet1, vendorRecord.ShippingStreet2,
                                                    vendorRecord.ShippingCity, vendorRecord.ShippingCountry,
                                                    vendorRecord.ShippingState, vendorRecord.ShippingPostalCode, updatedFields, false);*/
        
    }

    public class QuickBooksPhoneWrapper {
        public String FreeFormNumber;
        public QuickBooksPhoneWrapper(String freeFormNumber) {
            if(String.isNotBlank(freeFormNumber)) {
                this.FreeFormNumber = ((freeFormNumber.trim().length() > 21) ? freeFormNumber.trim().substring(0,21) : freeFormNumber.trim());    
            }
        }
    }

    public class QuickBooksEmailWrapper{
        public String Address;
        public QuickBooksEmailWrapper(String Address) {
            this.Address = Address;
        }
    }

    public class QuickBooksWebAddrWrapper{
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
                                
            if(String.isNotBlank(this.Line1) && this.Line1.trim().length() > 255) {
                this.Line1 = this.Line1.substring(0, 255);
            }
            if(String.isNotBlank(this.Line2) && this.Line2.trim().length() > 255) {
                this.Line2 = this.Line2.substring(0, 255);
            }
            if(String.isNotBlank(this.City) && this.City.trim().length() > 255) {
                this.City = this.City.substring(0, 255);
            }
            if(String.isNotBlank(this.Country) && this.Country.trim().length() > 255) {
                this.Country = this.Country.substring(0, 255);
            }
            if(String.isNotBlank(this.CountrySubDivisionCode) && this.CountrySubDivisionCode.trim().length() > 255) {
                this.CountrySubDivisionCode = this.CountrySubDivisionCode.substring(0, 255);
            }
            if(String.isNotBlank(this.PostalCode) && this.PostalCode.trim().length() > 31)  {
                this.PostalCode = this.PostalCode.substring(0, 31);
            }
        }
    }     
}
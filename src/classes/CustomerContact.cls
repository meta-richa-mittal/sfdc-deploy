/**
 * Author: Tarun Khandelwal
 * Since: June 9, 2015
 * Name: CustomerContact
 * Description: Apex class to handle JSON related oprations of Related Customer entity.
**/
public without sharing class CustomerContact {
	
    public String Id;
	public String LastName;
    public String Email;
    public String Phone;
    public Decimal Extension;
    public Boolean IsContact;
    public Boolean IsShippingAddress;
    public String ShippingStreet1;
    public String ShippingStreet2;
    public String ShippingCity;
    public String ShippingState;
    public String ShippingPostalCode;
    public String ShippingCountyParish;
    public String ShippingCountry;
    public String ShippingFullAddress;

    public String ShippingAddressLine1;
    public String ShippingAddressLine2;

    public String FormattedPhone;
    public String ParentCustomer;

    //Not in use
	public String FirstName;
	public Boolean PreferredEmail;
    public Boolean PreferredPhone;
    public Boolean PreferredSMS;
    public Boolean IsSMS;
    public String JobTitle;
    public String Relation;

    public CustomerContact(Contact customerContactRec) {
    	this.Id = customerContactRec.Id;
    	this.ParentCustomer = customerContactRec.AccountId;
    	this.LastName = customerContactRec.LastName;
    	this.Email = (customerContactRec.Email == null) ? '' : customerContactRec.Email;
    	this.Phone = (customerContactRec.Phone == null ) ? '' : customerContactRec.Phone;
    	this.FormattedPhone = (customerContactRec.Formatted_Phone_number__c == null ) ? '' : customerContactRec.Formatted_Phone_number__c;

        this.IsContact = customerContactRec.Is_Contact__c;
        this.IsShippingAddress = customerContactRec.Is_Shipping_Address__c;
        this.Extension = customerContactRec.Extension__c;
        
        String shippingStreet = (customerContactRec.MailingStreet == null ) ? '' : customerContactRec.MailingStreet;
        List<String> spList = shippingStreet.contains('\r\n') ? shippingStreet.split('\r\n') : shippingStreet.split('\n');
        this.ShippingStreet1 = (spList.size() > 0) ? spList[0].replaceAll('\r\n', ' ') : '';
        this.ShippingStreet2 = (spList.size() > 1) ? spList[1].replaceAll('\r\n', ' ') : '';

        this.ShippingCity = customerContactRec.MailingCity;
        this.ShippingState = customerContactRec.MailingState;
        this.ShippingPostalCode = customerContactRec.MailingPostalCode;
        this.ShippingCountyParish = customerContactRec.Mailing_County_Parish__c;
        this.ShippingCountry = customerContactRec.MailingCountry;

        List<String> addressPartList = new List<String>();
        if(String.isNotBlank(this.ShippingStreet1)) addressPartList.add(this.ShippingStreet1);
        if(String.isNotBlank(this.ShippingStreet2)) addressPartList.add(this.ShippingStreet2);
        this.ShippingAddressLine1 = String.join(addressPartList, ', ');

        addressPartList = new List<String>();
        if(String.isNotBlank(this.ShippingCity)) addressPartList.add(this.ShippingCity);
        if(String.isNotBlank(this.ShippingCountyParish)) addressPartList.add(this.ShippingCountyParish);
        if(String.isNotBlank(this.ShippingState)) addressPartList.add(this.ShippingState);
        if(String.isNotBlank(this.ShippingCountry)) addressPartList.add(this.ShippingCountry);
        if(String.isNotBlank(this.ShippingPostalCode)) addressPartList.add(this.ShippingPostalCode);
        this.ShippingAddressLine2 = String.join(addressPartList, ', ');

        addressPartList = new List<String>();
        if(String.isNotBlank(this.ShippingAddressLine1)) addressPartList.add(this.ShippingAddressLine1);
        if(String.isNotBlank(this.ShippingAddressLine2)) addressPartList.add(this.ShippingAddressLine2);
        this.ShippingFullAddress = String.join(addressPartList, ', ');
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: COLineItem - Class Object
    **/
    public static List<CustomerContact> parse(String JSONString) {
        return (List<CustomerContact>) System.JSON.deserialize(JSONString, List<CustomerContact>.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> customerContactFields = new List<String>{ 'Id',
		                                                        'LastName',
		                                                        'Phone',
		                                                        'Extension__c',
		                                                        'AccountId',
		                                                        'Formatted_Phone_number__c',
                                                                'Is_Contact__c',
                                                                'Is_Shipping_Address__c',
                                                                'MailingStreet',
                                                                'MailingCity',
                                                                'MailingState',
                                                                'MailingPostalCode',
                                                                'MailingCountry',
                                                                'Mailing_County_Parish__c',
                                                                'Email'
		                                                };
        return customerContactFields;
    }
}
/**
 * Author: Ashish Garg
 * Since: July 9, 2015
 * Name: VendorContact
 * Description: Apex class to handle JSON related oprations of Related vendor entity.
**/
public without sharing class VendorContact {
	
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
  public String Parentvendor;

//Not in use
public String FirstName;
public Boolean PreferredEmail;
public Boolean PreferredPhone;
public Boolean PreferredSMS;
public Boolean IsSMS;
public String JobTitle;
public String Relation;
  
  // Constructor
  public VendorContact(Contact vendorContactRec) {
      this.Id = vendorContactRec.Id;
      this.LastName = vendorContactRec.LastName;
      this.Email = (vendorContactRec.Email == null) ? '' : vendorContactRec.Email;
      this.Phone = (vendorContactRec.Phone == null ) ? '' : vendorContactRec.Phone;

      this.IsContact = vendorContactRec.Is_Contact__c;
      this.IsShippingAddress = vendorContactRec.Is_Shipping_Address__c;
      this.Extension = vendorContactRec.Extension__c;
      
      String shippingStreet = (vendorContactRec.MailingStreet == null ) ? '' : vendorContactRec.MailingStreet;
      List<String> spList = shippingStreet.contains('\r\n') ? shippingStreet.split('\r\n') : shippingStreet.split('\n');
      this.ShippingStreet1 = (spList.size() > 0) ? spList[0].replaceAll('\r\n', ' ') : '';
      this.ShippingStreet2 = (spList.size() > 1) ? spList[1].replaceAll('\r\n', ' ') : '';

      this.ShippingCity = vendorContactRec.MailingCity;
      this.ShippingState = vendorContactRec.MailingState;
      this.ShippingPostalCode = vendorContactRec.MailingPostalCode;
      this.ShippingCountyParish = vendorContactRec.Mailing_County_Parish__c;
      this.ShippingCountry = vendorContactRec.MailingCountry;

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

      this.Parentvendor = vendorContactRec.AccountId;
      this.FormattedPhone = (vendorContactRec.Formatted_Phone_number__c == null ) ? '' : vendorContactRec.Formatted_Phone_number__c;
  }
  
  /**
   * Name: parse
   * Desc: Method to Parse JSON String to class instance
   * @param:  (1) JSONString - String - JSON String 
   * @return: VendorContact - Class Object
  **/
  public static List<VendorContact> parse(String JSONString) {
      return (List<VendorContact>) System.JSON.deserialize(JSONString, List<VendorContact>.class);
  }
  
  /**
   * Name: getAllContactsForVendor
   * Desc: Get all related alternate parts for a vendor record
   * @param:	(1) vendorId - String - Vendor Id for which parts need to retrieved
   * @return: String - JSON format for all the alternate parts
  **/
  public static List<VendorContact> getAllContactsForVendor(Id vendorId, String pageSortAttrsJSON) {
    RelatedListPaginationSorting pageSortAttrs = VendorContact.parsePageAttrs(pageSortAttrsJSON);
    
    Map<String, String> sortFieldMap = new Map<String, String>();
    if(pageSortAttrs.sorting != null && pageSortAttrs.sorting[0].sortDirection.length() != 0){
      sortFieldMap.put('LastName', pageSortAttrs.sorting[0].sortDirection);
    }
    List<VendorContact> contacts = new List<VendorContact>();
    List<Contact> contactsList = TaxExemption.getPaginatedRecords(	SOQLUtil.getContactsForVendor(vendorId, sortFieldMap), 
                                  pageSortAttrs.contactsCurrentPage, 
                                  pageSortAttrs.contactsPageSize 
                                );
  
      for(Contact vendorContact : contactsList) {
      contacts.add(new VendorContact(vendorContact));
      }
      
  return contacts;
  }
  
  /**
   * Name: getTotalContactsForVendor
   * Desc: Get total count for related Active Orders of a vendor record
   * @param:	(1) vendorId - String - Vendor Id for which parts need to retrieved
   * @return: Integer - Total count
  **/
  public static Integer getTotalContactsForVendor(Id vendorId) {
  List<Contact> contactsList = SOQLUtil.getContactsForVendor(vendorId, new Map<String, String>());
  return contactsList.size();
  }
  
  /**
   * Name: getContactDetailsById
   * Desc: Get Contact record details by id
   * @param:	(1) contactId - Id - Contact Id
   * @return: Contact
  **/
  public static Contact getContactDetailsById(Id contactId) {
    if(contactId != null){
    List<Contact> contactsList = SOQLUtil.getCustomerContactByFieldName('Id', contactId);
    return contactsList[0];
    } else {
      return null;
    }
  }
  
  /**
   * Name: fieldsList
   * Desc: Method Which contains all the field list to be quried
   * @param:  
   * @return: List<String> - Fields List
  **/
  public static List<String> fieldsList(){
      List<String> vendorContactFields = new List<String>{'Id',
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
      return vendorContactFields;
  }
  
  // Wrapper class to hold contact record and total contact records in database for a vendor
  public class VendorContactWrapper {
    // VendorContact record
    public VendorContact ContactRecord;
    
    // Total count in database for a vendor
    public Integer TotalContacts;
    
    // Total count in database for a vendor
    public boolean isError;
    
    // Total count in database for a vendor
    public String ErrorMsg;
    
    // Constructor
    public VendorContactWrapper(Contact ContactRecord, Id vendorId){
      this.ContactRecord = new  VendorContact(ContactRecord);
      this.TotalContacts = VendorContact.getTotalContactsForVendor(vendorId);
      this.isError = false;
    }
    
    // Constructor
    public VendorContactWrapper(String ErrorMsg){
      this.isError = true;
      this.ErrorMsg = ErrorMsg;
    }
  }
  
  /**
   * Name: parsePageAttrs
   * Desc: Method to Parse JSON String to class instance for Pagination and sort attributes
   * @param:  (1) JSONString - String - JSON String 
   * @return: RelatedListPaginationSorting - Class Object
  **/
  public static RelatedListPaginationSorting parsePageAttrs(String json) {
      return (RelatedListPaginationSorting) System.JSON.deserialize(json, RelatedListPaginationSorting.class);
  }
  
  // Wrapper class for related list pagination and sorting combination
  public class RelatedListPaginationSorting {
    // Current page number
    public Integer contactsCurrentPage;
    
    // Current page size
    public Integer contactsPageSize;
    
    // Sorting list
    public List<SortAttrs> sorting;
  }
  
  // SortAttrs for sorting attributes
  public class SortAttrs {
    // Field name
    public String fieldName;
    
    // Sort direction
    public String sortDirection;
  }
}
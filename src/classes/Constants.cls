/**
 * Author: Ashish Garg
 * Since: Sept. 11, 2014
 * Name: Constants
 * Description: utility class which holds constant values thoroughout the system
**/
public without sharing class Constants {
    // SFDC tab name parameter name:
    public static String SMS_SENT_FROM_CUSTOMER = 'Customer';
    public static String SMS_SENT_FROM_CO = 'Customer Order';
    public static String SMS_DIRECTION_SENT = 'Sent';
    public static String SMS_DIRECTION_REPLY = 'Reply';
    public static String MESSAGE_HISTORY_ACTIVITY_TEXT_MESSAGE = 'Text Message';
    
    public static String THIS_SHIPMENT = 'THIS SHIPMENT';
    public static String PREVIOUS_SHIPMENT = 'PREVIOUS SHIPMENT';
    public static String NOT_YET_SHIPPED = 'NOT YET SHIPPED';
    
    public static Integer searchPageGridSize = 50;
    public static String Internal ='Internal'; 
    public static String PART_SALE ='Part Sale';
    public static String EVERY_BUSINESS_DAY = 'Monday; Tuesday; Wednesday; Thursday; Friday';    
    public static final String CO_STATUS_QUOTE = 'Quote';
    public static final String CUSTOMER_TRADE_IN = 'Customer Trade-In';
    
    public static final String INSTALL_DEAL_OPTION = 'Install deal options';
    public static final String CHECKOUT_TYPE_CUSTOMER = 'Customer';
    public static final String CHECKOUT_TYPE_INTERNAL = 'Internal';
    public static final String CHECKOUT_TYPE_THIRD_PARTY = 'Third-Party';
    public static final String CHECKOUT_TYPE_DEAL = 'Deal';

    public static final String SERVICE_INTERNAL = 'Service Internal';
    public static final String SERVICE_THIRD_PARTY = 'Service Third-Party';
    
    public static final String WORK_SERVICE_ORDER_INVOICE_ITEM_TYPE = 'Work';
    public static final String CLAIM_SERVICE_ORDER_INVOICE_ITEM_TYPE = 'Claim';
    public static final String KIT_INVOICE_ITEM_TYPE = 'Kit';
    public static final String PART_INVOICE_ITEM_TYPE = 'Part';
    public static final String FEE_INVOICE_ITEM_TYPE = 'Fee';
    public static final String BASE_UNIT = 'Base Unit';
    
    public static final String DEAL_SERVICE_TT = 'Deal Service';
    
    public static final String OBJIECT_NOT_ACCESSIBLE = 'Object is not accessible for user.';
    public static final String OBJIECT_NOT_CREATEABLE = 'Object is not createable for user.';
    public static final String OBJIECT_NOT_UPDATEABLE = 'Object is not updateable for user.';
    public static final String OBJIECT_NOT_DELETABLE = 'Object is not deletable for user.';
    public static final String EMAIL_SEND_NOT_PERMIT = 'Sending email is not permitted for user.';
    
    public static final String DUPLICATE_PART = 'Duplicate part';
    public static final String INVALID_PART = 'Invalid part';
    public static final String MISSING_VENDOR = 'Missing vendor';
    public static final String ACTIVE_COUNT = 'Active count';
    public static final String COUNTED_PARTS = 'Counted parts';
    public static final String UNCOUNTED_PARTS = 'Uncounted parts';
    public static final String ISSUES_TO_RESOLVE = 'Issues to resolve';
    public static final String ADJUSTMENTS = 'Adjustments';
    
    public static final String BRANDING_LOCATION = 'Branding Location';
    public static final String CASH_DRAWER = 'Cash Drawer';
    public static final String CATEGORY_TYPE_ADJUSTMENT = 'Adjustment';
    public static final String CATEGORY_TYPE_PART = 'Part';
    public static final String CATEGORY_TYPE_TAX = 'Tax';
    public static final String CATEGORY_TYPE_CONSIGNMENT_CLEARING = 'Consignment Clearing';
    // Object translations as defined in cutom labels
    public static String customerObjectLabel = Label.Customer_Object_Display_Label;
    public static String unitModelObjectLabel = Label.Unitmodel_Object_Display_Label;
    public static String vendorObjectLabel = Label.Vendor_Object_Display_Label;
    
    public static boolean IS_RECENT_VENDOR_TO_BE_CREATED = false;
    public static boolean IS_RECENT_CUSTOMER_TO_BE_CREATED = false;
     
    public static String tradeInCategoryName = 'TradeIn Default';
    public static String stampDutyCategoryName = 'Stamp Duty Default';
    
    public static final String TECHNICIAN = 'Technician';

	public static String MESSAGE_STATUS_UNREAD = 'Unread';
    public static String MESSAGE_STATUS_READ = 'Read';
    
    public static final String UNIT_TYPE_COU = 'COU';
    public static final String UNIT_TYPE_STOCK = 'STOCK';
    
    public static final String AR_CREDIT = 'AR Credit';

    public static List<String> allowedUserProfileNames = new List<String>{'System Administrator', 'Blackpurl'};
    public static List<String> BLACKPURL_USER_PROFILE_NAMES = new List<String>{'Blackpurl'};
    public static final String BP_PERMISSION_SET_NAME = 'Blackpurl_Permissions';

    public static final String restrictionErrorForForeignVendor = 'This type of transaction does not work with foreign vendors';
    public static final String restrictionErrorForFXCodeChanges = 'Cannot update existing vendors FX codes.';

    public static String NAMESPACE = (GeneralConfiguration.getNamespace() == null) ? '' : GeneralConfiguration.getNamespace();
    
    /****************************************************/
    /*                  Sales Tax Item                  */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String SALES_TAX_ITEM_NAME_PREFIX = 'STI_';
    
    public static final String READ_TIMED_OUT_ERROR_MESSAGE = 'Read timed out';
    public static final String HOURS_LOGGED_NOT_EDITABLE = 'An accounting entry is still pending for this clocking entry. Cannot modify/delete until the previous entry is successfully sent to accounting. Contact support if this does not resolve itself.';
    
    // Map of Sales Tax field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> SALES_TAX_ITEM_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => SALES_TAX_ITEM_NAME_PREFIX + 'Id',
                                                                                                      'Name__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Name',
                                                                                                      'Active__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Active',
                                                                                                      'Rate__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Rate',
                                                                                                      'Forms_Label__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Forms_Label',
                                                                                                      'Tax_Parts__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Tax_Parts',
                                                                                                      'Tax_Labour__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Tax_Labour',
                                                                                                      'Tax_Units__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Tax_Units',
                                                                                                      'Tax_Misc__c' => SALES_TAX_ITEM_NAME_PREFIX + 'Tax_Misc',
                                                                                                      'Category__r.Name' => SALES_TAX_ITEM_NAME_PREFIX + 'Category',
                                                                                                      'Category__c' => SALES_TAX_ITEM_NAME_PREFIX + 'CategoryId',
                                                                                                      'AccountingId__c' => SALES_TAX_ITEM_NAME_PREFIX + 'AccountingId'
                                                                                                      };
    
    /****************************************************/
    /*                  Sales Tax                       */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String SALES_TAX_NAME_PREFIX = 'ST_';
    
    
    // Map of Sales Tax field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> SALES_TAX_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => SALES_TAX_NAME_PREFIX + 'Id',
                                                                                                'Name__c' => SALES_TAX_NAME_PREFIX + 'Name',
                                                                                                'Active__c' => SALES_TAX_NAME_PREFIX + 'Active',
                                                                                                'Rate__c' => SALES_TAX_NAME_PREFIX + 'Rate',
                                                                                                'Default__c' => SALES_TAX_NAME_PREFIX + 'Default',
                                                                                                'Forms_List_Taxes__c' => SALES_TAX_NAME_PREFIX + 'Forms_List_Taxes',
                                                                                                'Forms_Label__c' => SALES_TAX_NAME_PREFIX + 'Forms_Label',
                                                                                                'Accounting_Id__c' => SALES_TAX_NAME_PREFIX + 'Accounting_Id'};
    
    /****************************************************/
    /*                  Price Level                     */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String PRICE_LEVEL_NAME_PREFIX = 'PL_';
    
    
    // Map of Price Level field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> PRICE_LEVEL_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => PRICE_LEVEL_NAME_PREFIX + 'Id',
                                                                                                'Name__c' => PRICE_LEVEL_NAME_PREFIX + 'Name',
                                                                                                'Description__c' => PRICE_LEVEL_NAME_PREFIX + 'Description',
                                                                                                'Part_Price_Base__c' => PRICE_LEVEL_NAME_PREFIX + 'Part_Price_Base',
                                                                                                'Discount_Markup__c' => PRICE_LEVEL_NAME_PREFIX + 'Discount_Markup',
                                                                                                'Labour_Rate__c' => PRICE_LEVEL_NAME_PREFIX + 'Labour_Rate',
                                                                                                'Active__c' => PRICE_LEVEL_NAME_PREFIX + 'Active',
                                                                                                'Default__c' => PRICE_LEVEL_NAME_PREFIX + 'Default' };
                                                                                            
    /****************************************************/
    /*                  Account                         */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String CUSTOMER_NAME_PREFIX = 'Cust_';
    
    
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> CUSTOMER_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => CUSTOMER_NAME_PREFIX + 'Id',
                                                                                                  'Name' => CUSTOMER_NAME_PREFIX + 'Name',
                                                                                                  'BillingStreet' => CUSTOMER_NAME_PREFIX + 'BillingStreet',
                                                                                                  'BillingCity' => CUSTOMER_NAME_PREFIX + 'BillingCity',
                                                                                                  'BillingState' => CUSTOMER_NAME_PREFIX + 'BillingState',
                                                                                                  'BillingCountry' => CUSTOMER_NAME_PREFIX + 'BillingCountry',
                                                                                                  'BillingPostalCode' => CUSTOMER_NAME_PREFIX + 'BillingPostalCode',
                                                                                                  'Home_Number__c' => CUSTOMER_NAME_PREFIX + 'HomeNumber',
                                                                                                  'Work_Number__c' => CUSTOMER_NAME_PREFIX + 'WorkNumber',
                                                                                                  'Email__c' => CUSTOMER_NAME_PREFIX + 'HomeEmail',
                                                                                                  'Work_Email__c' => CUSTOMER_NAME_PREFIX + 'WorkEmail',
                                                                                                  'Other_Email__c' => CUSTOMER_NAME_PREFIX + 'OtherEmail',
                                                                                                  'Preferred_Email__c' => CUSTOMER_NAME_PREFIX + 'PreferredEmail',
                                                                                                  'Mobile__c' => CUSTOMER_NAME_PREFIX + 'Mobile',
                                                                                                  'Mobile__c' => CUSTOMER_NAME_PREFIX + 'OtherNumber',
                                                                                                  'Preferred_Phone__c' => CUSTOMER_NAME_PREFIX + 'PreferredPhone',
                                                                                                  'Facebook__c' => CUSTOMER_NAME_PREFIX + 'Facebook',
                                                                                                  'Twitter__c' => CUSTOMER_NAME_PREFIX + 'Twitter',
                                                                                                  'LinkedIn__c' => CUSTOMER_NAME_PREFIX + 'LinkedIn',
                                                                                                  'Active__c' => CUSTOMER_NAME_PREFIX + 'Active',
                                                                                                  'Type__c' => CUSTOMER_NAME_PREFIX + 'Type',
                                                                                                  'FirstName__c' => CUSTOMER_NAME_PREFIX + 'FirstName',
                                                                                                  'LastName__c' => CUSTOMER_NAME_PREFIX + 'LastName',
                                                                                                  'Nickname__c' => CUSTOMER_NAME_PREFIX + 'NickName',
                                                                                                  'Formatted_Home_number__c' => CUSTOMER_NAME_PREFIX + 'FormattedHomeNumber',
                                                                                                  'Formatted_Mobile_Number__c' => CUSTOMER_NAME_PREFIX + 'FormattedOtherPhone',
                                                                                                  'Formatted_Work_Number__c' => CUSTOMER_NAME_PREFIX + 'FormattedWorkNumber',
                                                                                                  'Formatted_Preferred_Phone__c' => CUSTOMER_NAME_PREFIX + 'FormattedPreferredPhone',
                                                                                                  'Home_Number_SMS__c' => CUSTOMER_NAME_PREFIX + 'HomeNumberSMS',
                                                                                                  'Work_Number_SMS__c' => CUSTOMER_NAME_PREFIX + 'WorkNumberSMS',
                                                                                                  'Mobile_Number_SMS__c' => CUSTOMER_NAME_PREFIX + 'MobileNumberSMS',
                                                                                                  'Preferred_SMS__c' => CUSTOMER_NAME_PREFIX + 'PreferredSMS'
                                                                                                };
                                                                                  
    // Map of Customer field API name to their Data types
    // Key: Field API Name
    // Value: Data type of field 
    public static Map<String, String> CUSTOMER_FIELDS_TO_DATA_TYPE_MAPPING = new Map<String, String>{'Id' => 'Id',
                                                                                                    'Name' => 'String' ,
                                                                                                    'BillingStreet' => 'String',
                                                                                                    'BillingCity' => 'String',
                                                                                                    'BillingState' => 'String',
                                                                                                    'BillingCountry' => 'String',
                                                                                                    'BillingPostalCode' => 'String',
                                                                                                    'Home_Number__c' => 'String',
                                                                                                    'Work_Number__c' => 'String',
                                                                                                    'Email__c' => 'String',
                                                                                                    'Work_Email__c' => 'String',
                                                                                                    'Other_Email__c' => 'String',
                                                                                                    'Mobile__c' => 'String',
                                                                                                    'Preferred_Email__c' => 'String',
                                                                                                    'Preferred_Phone__c' => 'String',
                                                                                                    'Facebook__c' => 'String',
                                                                                                    'Twitter__c' => 'String',
                                                                                                    'LinkedIn__c' => 'String',
                                                                                                    'Active__c' => 'Boolean',
                                                                                                    'Type__c' => 'String',
                                                                                                    'FirstName__c' => 'String',
                                                                                                    'LastName__c' => 'String',
                                                                                                    'Nickname__c' => 'String',
                                                                                                    'Formatted_Work_Number__c' => 'Formula',
                                                                                                    'Formatted_Home_number__c' => 'Formula',
                                                                                                    'Formatted_Mobile_Number__c' => 'Formula',
                                                                                                    'Formatted_Preferred_Phone__c' => 'Formula',
                                                                                                    'Home_Number_SMS__c' => 'Boolean',
                                                                                                    'Work_Number_SMS__c' => 'Boolean',
                                                                                                    'Mobile_Number_SMS__c' => 'Boolean',
                                                                                                    'Preferred_SMS__c' => 'String'
                                                                                                  };                                                                                                                                                                                                                                                                                                 
    
    /****************************************************/
    /*                  Contact                         */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String INDIVIDUAL_CUSTOMER_NAME_PREFIX = 'Indi_Cust_';
    
    
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> INDIVIDUAL_CUSTOMER_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Id',
                                                                                                          'FirstName' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'FirstName',
                                                                                                          'LastName' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'LastName',
                                                                                                          'MailingStreet' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MailingStreet',
                                                                                                          'MailingCity' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MailingCity',
                                                                                                          'MailingState' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MailingState',
                                                                                                          'MailingCountry' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MailingCountry',
                                                                                                          'MailingPostalCode' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MailingPostalCode',
                                                                                                          
                                                                                                          'OtherStreet' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'OtherStreet',
                                                                                                          'OtherCity' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'OtherCity',
                                                                                                          'OtherState' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'OtherState',
                                                                                                          'OtherCountry' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'OtherCountry',
                                                                                                          'OtherPostalCode' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'OtherPostalCode',
                                                                                                          'SA_same_as_BA__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'SASameAsBA',
                                                                                                          'Phone' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Phone',
                                                                                                          'MobilePhone' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'MobilePhone',
                                                                                                          'Fax' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Fax',
                                                                                                          'Email' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Email',
                                                                                                          'Preferred_Contact__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Preferred_Contact',
                                                                                                          'VIP__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'VIP',
                                                                                                          'Price_Level__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Price_Level_Id',
                                                                                                          'Price_Level__r.Name' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Price_Level',
                                                                                                          'Sales_Tax__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Sales_Tax_Id',
                                                                                                          'Sales_Tax__r.Name' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Sales_Tax',
                                                                                                          'Active__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'Active',
                                                                                                          'Is_Vendor__c' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'IsVendor',
                                                                                                          'LastModifiedDate' => INDIVIDUAL_CUSTOMER_NAME_PREFIX + 'LastActive' };
    
    /****************************************************/
    /*                  Comapny Customer                */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String COMAPANY_CUSTOMER_NAME_PREFIX = 'Comp_Cust_';
    
    
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> COMAPANY_CUSTOMER_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Id',
                                                                                                          'Name' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Name',
                                                                                                          'BillingStreet' => COMAPANY_CUSTOMER_NAME_PREFIX + 'BillingStreet',
                                                                                                          'BillingCity' => COMAPANY_CUSTOMER_NAME_PREFIX + 'BillingCity',
                                                                                                          'BillingState' => COMAPANY_CUSTOMER_NAME_PREFIX + 'BillingState',
                                                                                                          'BillingCountry' => COMAPANY_CUSTOMER_NAME_PREFIX + 'BillingCountry',
                                                                                                          'BillingPostalCode' => COMAPANY_CUSTOMER_NAME_PREFIX + 'BillingPostalCode',
                                                                                                          
                                                                                                          'ShippingStreet' => COMAPANY_CUSTOMER_NAME_PREFIX + 'ShippingStreet',
                                                                                                          'ShippingCity' => COMAPANY_CUSTOMER_NAME_PREFIX + 'ShippingCity',
                                                                                                          'ShippingState' => COMAPANY_CUSTOMER_NAME_PREFIX + 'ShippingState',
                                                                                                          'ShippingCountry' => COMAPANY_CUSTOMER_NAME_PREFIX + 'ShippingCountry',
                                                                                                          'ShippingPostalCode' => COMAPANY_CUSTOMER_NAME_PREFIX + 'ShippingPostalCode',
                                                                                                          'SA_same_as_BA__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'SASameAsBA',
                                                                                                          'Phone' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Phone',
                                                                                                          'Mobile__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Mobile',
                                                                                                          'Fax' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Fax',
                                                                                                          'Email__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Email',
                                                                                                          'Preferred_Contact__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Preferred_Contact',
                                                                                                          'VIP__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'VIP',
                                                                                                          'Price_Level__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Price_Level_Id',
                                                                                                          'Price_Level__r.Name' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Price_Level',
                                                                                                          'Sales_Tax__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Sales_Tax_Id',
                                                                                                          'Sales_Tax__r.Name' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Sales_Tax',
                                                                                                          'Active__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'Active',
                                                                                                          'Is_Vendor__c' => COMAPANY_CUSTOMER_NAME_PREFIX + 'IsVendor',
                                                                                                          'LastModifiedDate' => COMAPANY_CUSTOMER_NAME_PREFIX + 'LastActive' };
                                                             
    /****************************************************/
    /*                  Vendor                          */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String VENDOR_LIST_NAME_PREFIX = 'Vendor_';
    
    
    // Map of Vendor field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> VENDOR_LIST_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => VENDOR_LIST_NAME_PREFIX + 'Id',
                                                                                                  'Name' => VENDOR_LIST_NAME_PREFIX + 'Name',
                                                                                                  'BillingStreet' => VENDOR_LIST_NAME_PREFIX + 'BillingStreet',
                                                                                                  'BillingCity' => VENDOR_LIST_NAME_PREFIX + 'BillingCity',
                                                                                                  'BillingState' => VENDOR_LIST_NAME_PREFIX + 'BillingState',
                                                                                                  'BillingCountry' => VENDOR_LIST_NAME_PREFIX + 'BillingCountry',
                                                                                                  'BillingPostalCode' => VENDOR_LIST_NAME_PREFIX + 'BillingPostalCode',
                                                                                                  'ShippingStreet' => VENDOR_LIST_NAME_PREFIX + 'ShippingStreet',
                                                                                                  'ShippingCity' => VENDOR_LIST_NAME_PREFIX + 'ShippingCity',
                                                                                                  'ShippingState' => VENDOR_LIST_NAME_PREFIX + 'ShippingState',
                                                                                                  'ShippingCountry' => VENDOR_LIST_NAME_PREFIX + 'ShippingCountry',
                                                                                                  'ShippingPostalCode' => VENDOR_LIST_NAME_PREFIX + 'ShippingPostalCode',
                                                                                                  'SA_same_as_BA__c' => VENDOR_LIST_NAME_PREFIX + 'SASameAsBA',
                                                                                                  'Phone' => VENDOR_LIST_NAME_PREFIX + 'Phone',
                                                                                                  'Mobile__c' => VENDOR_LIST_NAME_PREFIX + 'Mobile',
                                                                                                  'Fax' => VENDOR_LIST_NAME_PREFIX + 'Fax',
                                                                                                  'Email__c' => VENDOR_LIST_NAME_PREFIX + 'Email',
                                                                                                  'Preferred_Contact__c' => VENDOR_LIST_NAME_PREFIX + 'Preferred_Contact',
                                                                                                  'VIP__c' => VENDOR_LIST_NAME_PREFIX + 'VIP',
                                                                                                  'Price_Level__c' => VENDOR_LIST_NAME_PREFIX + 'Price_Level_Id',
                                                                                                  'Price_Level__r.Name' => VENDOR_LIST_NAME_PREFIX + 'Price_Level',
                                                                                                  'Sales_Tax__c' => VENDOR_LIST_NAME_PREFIX + 'Sales_Tax_Id',
                                                                                                  'Sales_Tax__r.Name' => VENDOR_LIST_NAME_PREFIX + 'Sales_Tax',
                                                                                                  'Active__c' => VENDOR_LIST_NAME_PREFIX + 'Active',
                                                                                                  'Is_Vendor__c' => VENDOR_LIST_NAME_PREFIX + 'IsVendor',
                                                                                                  'Is_Customer__c' => VENDOR_LIST_NAME_PREFIX + 'IsCustomer',
                                                                                                  'LastModifiedDate' => VENDOR_LIST_NAME_PREFIX + 'LastActive',
                                                                                                  'Vendor_Code__c' => VENDOR_LIST_NAME_PREFIX + 'Vendor_Code',
                                                                                                  'Website' => VENDOR_LIST_NAME_PREFIX + 'Website',
                                                                                                  'Purchase_Tax__c' => VENDOR_LIST_NAME_PREFIX + 'Purchase_Tax' };
    
    
    /****************************************************/
    /*                  Unit Make List                  */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String UNIT_MAKE_LIST_NAME_PREFIX = 'Unit_Make_';
    
    
    // Map of Customer JSON representative field name to related field API name
    // Key: JSON representative Field API Name
    // Value: Related field API name
    public static Map<String, String> UNIT_MAKE_LIST_JSON_TO_FIELDS_MAPPING = new Map<String, String>{UNIT_MAKE_LIST_NAME_PREFIX + 'Id' => 'Id',
                                                                                                       UNIT_MAKE_LIST_NAME_PREFIX + 'Name' => 'Name' ,
                                                                                                       UNIT_MAKE_LIST_NAME_PREFIX + 'Active' => 'Active__c',
                                                                                                       UNIT_MAKE_LIST_NAME_PREFIX + 'VIN_Code' => 'VIN_Code__c'  };
                                                                                                                                                                              
    /****************************************************/
    /*                  User Object                   */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String USER_NAME_PREFIX = 'User_';
    
    
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> USER_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Email' => USER_NAME_PREFIX + 'Email',
                                                                                              'Phone' => USER_NAME_PREFIX + 'Phone',    
                                                                                              'Name' => USER_NAME_PREFIX + 'Name' };
                                                                                                 
    // Map of Customer field API name to their Data types
    // Key: Field API Name
    // Value: Data type of field 
    public static Map<String, String> USER_FIELDS_TO_DATA_TYPE_MAPPING = new Map<String, String>{'Email' => 'String',
                                                                                                    'Phone' => 'String',    
                                                                                                    'Name' => 'String'  };
                                                                                                    
                                                                                                    
                                                                                                                                                                                                            
    
    /****************************************************/
    /*                  Filter Object                   */
    /****************************************************/
    // Prefix name for object fields used in JSON
    private static String FILTER_NAME_PREFIX = 'Filter_';
    
    
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> FILTER_FIELDS_TO_JSON_MAPPING = new Map<String, String>{'Id' => FILTER_NAME_PREFIX + 'Id',
                                                                                              'Custom__c' => FILTER_NAME_PREFIX + 'Custom',
                                                                                              'Filter_JSON__c' => FILTER_NAME_PREFIX + 'Filter_JSON',
                                                                                              'Filter_Label__c' => FILTER_NAME_PREFIX + 'Filter_Label'  };
                                                                                               
    // Map of Customer field API name to their Data types
    // Key: Field API Name
    // Value: Data type of field 
    public static Map<String, String> FILTER_FIELDS_TO_DATA_TYPE_MAPPING = new Map<String, String>{'Id' => 'Id',
                                                                                                    'Custom__c' => 'Boolean' ,
                                                                                                    'Filter_JSON__c' => 'String',
                                                                                                    'Filter_Label__c' => 'String' };
                                                                                                    
    /****************************************************/
    /*                  Parse JSON Map                  */
    /****************************************************/
    // Map of Customer field API name to related webservice field name
    // Key: Field API Name
    // Value: Representative field name used in JSON and webservices
    public static Map<String, String> FILTER_FIELD_TO_FIELD_API_NAME_MAPPING = new Map<String, String>{'Part' => 'Part__c',
                                                                                                        'Category' => 'Category__c',
                                                                                                        'Status' => 'Active__c',
                                                                                                        'Assignee' => 'OwnerId',
                                                                                                        'Date' => 'LastModifiedDate',
                                                                                                        'Summary' => 'Description__c',
                                                                                                        'Last Week' => 'LAST_WEEK',
                                                                                                        'This Week' => 'THIS_WEEK',
                                                                                                        'This Month' => 'THIS_MONTH',
                                                                                                        'Account' => 'Account',
                                                                                                        'Vendor' => 'Account',
                                                                                                        'Customer' => 'Account',
                                                                                                        'Labour' => 'Labour_Code__c',
                                                                                                        'Kit' => 'Kit_Header__c',
                                                                                                        'Fee' => 'Fee__c'
                                                                                                        };
    
    /****************************************************/
    /*                  Seachable Object Map            */
    /****************************************************/
    // Ordered list for objects to display
    public static List<String> homeSearchObjectsOrderedList = new List<String>{'Customer', 'Vendor', 'Part__c', 'Category__c', 'Labour_Code__c', 'Kit_Header__c', 'Fee__c'};
    public static List<String> objectsOrderedList;
    public static map<String, List<String>> objectToSearchableFieldsMap;
    public static map<String, String> objectToDisplayFieldsMap;
    public static map<String, String> objectToAdditionalInfoDisplayMap;
    public static set<String> autoCompleteSearchableFields;
    static {
        objectToSearchableFieldsMap = new map<String, List<String>>{'Account' => new List<String>{'Name'}};
        objectToDisplayFieldsMap = new map<String, String>{'Account' => 'Name'};
        objectToAdditionalInfoDisplayMap = new map<String, String>();
        autoCompleteSearchableFields = new set<String>();
        objectsOrderedList = new List<String>();
        map<Integer, Set<String>> orderToObjectName = new map<Integer, Set<String>>{1 => new Set<String>{'Account'}};
        
        for(SearchConfigurations__c searchConfig : SearchConfigurations__c.getAll().values()){
            List<String> searchableFields = (objectToSearchableFieldsMap.containsKey(searchConfig.Object_Name__c)) 
                                            ? objectToSearchableFieldsMap.get(searchConfig.Object_Name__c)
                                            : new List<String>();
            
            if( !searchConfig.Searchable_Field__c.contains(',') ){
                searchableFields.add(searchConfig.Searchable_Field__c.trim());
                if( !autoCompleteSearchableFields.contains(searchConfig.Searchable_Field__c.trim()) ){
                    autoCompleteSearchableFields.add(searchConfig.Searchable_Field__c.trim());
                }
            } else {
                for(String searchField : searchConfig.Searchable_Field__c.trim().split(',')){
                    if(searchField != null && searchField.trim().length() != 0){
                        searchableFields.add(searchField);
                        
                        if( !autoCompleteSearchableFields.contains(searchField) ){
                            autoCompleteSearchableFields.add(searchField);
                        }
                    }
                }
            }
            objectToSearchableFieldsMap.put(searchConfig.Object_Name__c, searchableFields);
            objectToDisplayFieldsMap.put(searchConfig.Object_Name__c, searchConfig.Display_Field__c);
            objectToAdditionalInfoDisplayMap.put(searchConfig.Object_Name__c, searchConfig.Display_Info__c);
            
            Integer configOrder = Integer.valueOf(searchConfig.Order__c);
            Set<String> currentOrderObjects = (orderToObjectName.containsKey(configOrder)) ? orderToObjectName.get(configOrder) : new Set<String>();
            currentOrderObjects.add(searchConfig.Object_Name__c);
            orderToObjectName.put(configOrder, currentOrderObjects);
        }
        
        List<Integer> orderList = new List<Integer>(orderToObjectName.keySet());
        orderList.sort();
        for(Integer orderNum : orderList){
            List<String> currentOrderObjects = new List<String>(orderToObjectName.get(orderNum));
            currentOrderObjects.sort();
            objectsOrderedList.addAll(currentOrderObjects);
        }
    }
    
    // Map to hold object API name to object label to display on UI (Custom lables value)
    public static map<String, String> objectNameToObjectDisplayLabel = new map<String, String>{
                                                                            'Contact' => Label.Contact_Object_Display_Label,
                                                                            'Customer' => Label.Customer_Object_Display_Label,
                                                                            'Vendor' => Label.Vendor_Object_Display_Label,
                                                                            NAMESPACE + 'Part__c' => Label.Part_Object_Display_Label,
                                                                            NAMESPACE + 'Category__c' => Label.Category_Object_Display_Label,
                                                                            NAMESPACE + 'Unit_Make__c' => Label.Unit_Make_Object_Display_Label,
                                                                            'User' => Label.User_Object_Display_Label,
                                                                            NAMESPACE + 'Sales_Tax_Item__c' => Label.Sales_Tax_Item_Object_Display_Label,
                                                                            NAMESPACE + 'Labour_Code__c' => Label.Labour_Object_Display_Label,
                                                                            NAMESPACE + 'Kit_Header__c' => Label.Kit_Object_Display_Label,
                                                                            NAMESPACE + 'Fee__c' => Label.Fee_Object_Display_Label,
                                                                            NAMESPACE + 'Customer_Owned_Unit__c' => 'Unit',
                                                                            NAMESPACE + 'Product__c' => 'Product'
                                                                        };
                                                                        
    // Map to hold object display label (Custom lables value) to object API name
    public static map<String, String> objectDisplayLabelToObjectName = new map<String, String>{
                                                                            Label.Contact_Object_Display_Label => 'Contact',
                                                                            Label.Customer_Object_Display_Label => 'Customer',
                                                                            Label.Vendor_Object_Display_Label => 'Vendor',
                                                                            Label.Part_Object_Display_Label => NAMESPACE + 'Part__c',
                                                                            Label.Category_Object_Display_Label => NAMESPACE + 'Category__c',
                                                                            Label.Unit_Make_Object_Display_Label => NAMESPACE + 'Unit_Make__c',
                                                                            Label.User_Object_Display_Label => 'User',
                                                                            Label.Sales_Tax_Item_Object_Display_Label => NAMESPACE + 'Sales_Tax_Item__c',
                                                                            Label.Labour_Object_Display_Label => NAMESPACE + 'Labour_Code__c',
                                                                            Label.Kit_Object_Display_Label => NAMESPACE + 'Kit_Header__c',
                                                                            Label.Fee_Object_Display_Label => NAMESPACE + 'Fee__c',
                                                                            Label.UnitSubmodel_Object_Display_Label => NAMESPACE + 'Unit_Model__c',
                                                                            Label.Unitmodel_Object_Display_Label => NAMESPACE + 'Unit_Model__c',
                                                                            'Product' => 'Product__c',
                                                                            'Location' => NAMESPACE + 'Location__c'
                                                                        };
    
    // A Map of Objects to associated fields on which search to be performed
    public static Map<String, Set<String>> searchableObjectToFieldsMap = new Map<String, Set<String>>{
                                                                            'Contact' => new Set<String>{'Id', 'Active__c', 'Name', 'Description', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Customer' => new Set<String>{'Id', 'Is_Customer__c', 'Is_Vendor__c', 'Active__c', 'Name', 'Description', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Account' => new Set<String>{'Id', 'Is_Customer__c', 'Is_Vendor__c', 'Active__c', 'Name', 'Description', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Vendor' => new Set<String>{'Id', 'Is_Customer__c', 'Is_Vendor__c', 'Active__c', 'Name', 'Description', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Part__c' => new Set<String>{'Id', CONSTANTS.NAMESPACE+'Part_ID__c', CONSTANTS.NAMESPACE+'Active__c', CONSTANTS.NAMESPACE+'Description__c', CONSTANTS.NAMESPACE+'Vendor__r.Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'User' => new Set<String>{'Id', 'UserName', 'Name', 'IsActive', 'Title', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Category__c' => new Set<String>{'Id', 'Name', 'Active__c', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Labour_Code__c' => new Set<String>{'Id', 'Name', 'Active__c', 'Name__c', 'Description__c', 'Code__c', 'Owner.Name', 'LastModifiedDate', 'CreatedDate'},
                                                                            'Kit_Header__c' => new Set<String>{'Id', 'Name', 'Active__c', 'Description__c', 'Code__c', 'Owner.Name', 'LastModifiedDate', 'CreatedDate', 'Kit_Unique_Name__c'},
                                                                            'Fee__c' => new Set<String>{'Id', 'Name', 'Active__c', 'Description__c', 'Code__c', 'Owner.Name', 'LastModifiedDate', 'CreatedDate', 'Fee_Unique_Name__c'} };
                                                                            
    public static Map<String, String> objectToMasterOwnerField = new Map<String, String>{
                                                                            'Part__c' => 'Vendor__r.OwnerId'};
                                                                            
                                                                            
     
    // Related To Customer suggestion used in Create Customer Page                                                                        
    public static Map<String, String> customerFieldToFieldAPINameMap = new Map<String, String>{ 'Id' => 'Id',
                                                                                                'Name' => 'Name',
                                                                                                'FirstName' => 'FirstName__c',
                                                                                                'LastName' => 'LastName__c', 
                                                                                                'HomeEmail' => 'Email__c',
                                                                                                'WorkEmail' => 'Work_Email__c',
                                                                                                'OtherEmail' => 'Other_Email__c',
                                                                                                'HomeNumber' => 'Home_Number__c',
                                                                                                'MobileNumber' => 'Mobile__c',
                                                                                                'WorkNumber' => 'Work_Number__c',
                                                                                                'LinkedIn' => 'LinkedIn__c',
                                                                                                'Facebook' => 'Facebook__c',
                                                                                                'Twitter' => 'Twitter__c',
                                                                                                'BillingStreet' => 'BillingStreet',
                                                                                                'IsCustomer' => 'Is_Customer__c',
                                                                                                'IsVendor' => 'Is_Vendor__c'
                                                                                            };
                                                                                        
    
    // Related To Vendor suggestion used in Create Vendor Page                                                                        
    public static Map<String, String> vendorFieldToFieldAPINameMap = new Map<String, String>{  'Id' => 'Id',
                                                                                                'Name' => 'Name',
                                                                                                'WorkEmail' => 'Work_Email__c',
                                                                                                'OtherEmail' => 'Other_Email__c',
                                                                                                'MobileNumber' => 'Mobile__c',
                                                                                                'WorkNumber' => 'Work_Number__c',
                                                                                                'LinkedIn' => 'LinkedIn__c',
                                                                                                'Facebook' => 'Facebook__c',
                                                                                                'Twitter' => 'Twitter__c',
                                                                                                'BillingStreet' => 'BillingStreet',
                                                                                                'IsCustomer' => 'Is_Customer__c',
                                                                                                'IsVendor' => 'Is_Vendor__c'
                                                                                            };
     public static Map<String, Integer> SOStatusToPriorityMap = new Map<String, Integer> {'New' => 1,
                                                                                         'Ready' => 2,
                                                                                         'In Progress' => 3,
                                                                                         'Complete' => 4,
                                                                                         'Reviewed' => 5};
     
     public static Map<String, List<String>> workStatusToAvailableStatusMap = 
                                new Map<String , List<String>> {'New'           =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Estimate'      =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Ready'         =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'In Progress'   =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'On Hold'       =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Complete'      =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Reviewed'      =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Signed Out'    =>  new List<String>{'Set As Complete', 'Re-Open For Work'},
                                                                'Invoiced'      =>  new List<String>{}
                                                            };
     // ClaimStatus Map To Available Status                                                         
    public static Map<String, List<String>> claimStatusToAvailableStatusMap = 
                                new Map<String , List<String>> {'Unsubmitted'       =>  new List<String>{'Claim Submission', 'Claim Response'},
                                                                'Ready to Submit'   =>  new List<String>{'Claim Submission', 'Claim Response'},
                                                                'Submitted'         =>  new List<String>{'Claim Submission', 'Claim Response'},
                                                                'Approved'          =>  new List<String>{'Claim Submission', 'Claim Response'}
                                                               };
                                                               
    public static final String USE_DEPOSIT =  'Use Deposit';
    public static final String QUOTATION =  'Quotation';
    public static final String IN_PROGRESS =  'In Progress';
    public static final String FULFILLED = 'Fulfilled';
    public static final String DEAL_STATUS_INVOICED =  'Invoiced';
    public static final String CASH_DEAL =  'Cash Deal';
    public static final String FINANCED =  'Financed';
    public static final String TEMPORARY =  'Temporary';
    public static final String COMMITTED =  'Committed';
    public static final String UNCOMIITTED =  'Uncommitted'; 
    public static final String COMMIT_AND_ORDER =  'Commit and order';
    public static final String INTERNAL_SERVICE =  'Internal Service'; 
    public static final String CASH_SALE =  'Cash Sale'; 
    public static final String UNIT_INVENTORY =  'UNIT INVENTORY';                                                                   
    public static final String DEAL_ITEM_TYPE_TRADE_IN =  'Trade In';
    public static final String DEAL_ITEM_TYPE_UNIT =  'Unit';
    public static final String APPRAISAL_STATUS_PENDING_APPRAISAL ='Pending Appraisal';
    public static final String UNIT_STATUS_RESERVED ='Reserved';
    
    public static final String UNRESOLVED_FULFILLMENT_TYPE_ADDED ='Added';
    public static final String UNRESOLVED_FULFILLMENT_TYPE_REMOVED ='Removed';
    public static final String UNRESOLVED_FULFILLMENT_TYPE_UPDATED ='Updated';
    public static final String CHARGE_METHOD_DO_NOT_INVOICE ='Do Not Invoice';
    public static final String CHARGE_METHOD_INVOICE ='Invoice';
    public static final String CASH_CREDIT_ONLY_LABEL = 'Cash/Credit Only';
    public static final String VENDOR = 'Vendor';
    public static final String WARRANTY_PLAN = 'Warranty Plan';
    public static final String CUSTOMERS_ACCOUNTING_OBJECT_NAME = 'Customers Card';
    public static final String VENDORS_ACCOUNTING_OBJECT_NAME = 'Supplier Card';
    public static final String ACCOUNTING_OBJECT_NAME = 'Customer Order Sales Invoices';
    public static final String SUBLET = 'Sublet';
    public static final String FINANCING_PRODUCT = 'Financing Product';
    public static final String DEAL_PRODUCT = 'Deal Product';

    public static final String TAX_CODE_PREFIX_FOR_QB = 'BP ';
    public static final String ARI_Partsmart10 = 'ARI Partsmart 10';
    public static final String ARI_Partsmart8 = 'ARI Partsmart 8';
    public static final String Generic_CSV = 'Generic CSV (part#,quantity)';
    public static final String Snap_On_EPC = 'Snap-on EPC';
    public static final String HLSM_CSV = 'HLSM CSV';
    public static final String BRP_PICK_LIST = 'BRP Pick List';
        
      public static Map<String,String> localeToDateTimeFmtOnPageMap  = new Map<String,String> {
        'en_AU'         => 'dd/mm/yy',
         'en_US'         => 'mm/dd/yy',
         'en_CA'         => 'dd/mm/yy',
         'en_NZ'        => 'dd/mm/yy',
         'en_GB'       => 'dd/mm/yy'
     
    };
    
     public static Map<String,String> localeToDateTimeMonthFmt  = new Map<String,String> {
         'en_AU'         => 'dd MMMM, yyyy hh:mm a',
         'en_US'         => 'MMMM dd, yyyy hh:mm a',
         'en_CA'         => 'dd MMMM, yyyy hh:mm a',
         'en_NZ'        => 'dd MMMM, yyyy hh:mm a',
         'en_GB'       => 'dd MMMM, yyyy hh:mm a'
     
    };
    
    public static Map<String,String> localeToDateAndTimeFmtWithHypenMap  = new Map<String,String> {
        'en_AU'         => 'dd/MM/yyyy - hh.mma',
        'en_CA'         => 'dd/MM/yyyy - hh.mma',
        'en_GB'         => 'dd/MM/yyyy - hh.mma',
        'en_NZ'         => 'dd/MM/yyyy - hh.mma',
        'en_US'         => 'MM/dd/yyyy - hh.mma'
    };
    
    public static Map<String,String> localeToDateTimeExtendedMonthFmt  = new Map<String,String> {
         'en_AU'         => 'dd MMM, yyyy',
         'en_US'         => 'MMM dd, yyyy',
         'en_CA'         => 'dd MMM, yyyy',
         'en_NZ'        => 'dd MMM, yyyy',
         'en_GB'       => 'dd MMM, yyyy '
     
    };
   
    public static Map<String,String> localeToDateTimeFmtMap  = new Map<String,String> {             
        'en_AU'         => 'dd/MM/yyyy',
        'en_CA'         => 'dd/MM/yyyy',
        'en_GB'         => 'dd/MM/yyyy',
        'en_NZ'         => 'dd/MM/yyyy',
        'en_US'         => 'MM/dd/yyyy'      
    };
    
    public static Map<String,String> localeToDateAndTimeFmtMap  = new Map<String,String> {
        'en_AU'         => 'dd/MM/yyyy hh:mm a',
        'en_CA'         => 'dd/MM/yyyy hh:mm a',
        'en_GB'         => 'dd/MM/yyyy hh:mm a',
        'en_NZ'         => 'dd/MM/yyyy hh:mm a',
        'en_US'         => 'MM/dd/yyyy hh:mm a'
    };
    
    public static Map<String,String> localeToDateMonthTimeFmtMap  = new Map<String,String> {
            
        'en_AU'         => 'dd/MMM/yyyy',
        'en_CA'         => 'dd/MMM/yyyy',
        'en_GB'         => 'dd/MMM/yyyy',
        'en_NZ'         => 'dd/MMM/yyyy',
        'en_US'         => 'MMM/dd/yyyy'
            
            
    };
    public static Map<String,String> localeToExportFmtMap  = new Map<String,String> {
            
        'en_AU'         => 'd MMM/yyyy',
        'en_CA'         => 'd MMM/yyyy',
        'en_GB'         => 'd MMM/yyyy',
        'en_NZ'         => 'd MMM/yyyy', 
        'en_US'         => 'MMM d/yyyy'       
             
    };
    
    public static Map<String,String> localeToExportFileNameFmtMap  = new Map<String,String> {
            
        'en_AU'         => 'dd-MM-yyyy hh:mm:ss',
         'en_US'         => 'MM-dd-yyyy hh:mm:ss ',
         'en_CA'         => 'dd-MM-yyyy hh:mm:ss',
         'en_NZ'        => 'dd-MM-yyyy hh:mm:ss',
         'en_GB'       => 'dd-MM-yyyy hh:mm:ss'   
            
    };
    
    public static Map<String,String> localeToschedulingDateFmtMap  = new Map<String,String> {
            
        'en_AU'         => 'DD/MM/YYYY',
        'en_CA'         => 'DD/MM/YYYY',
        'en_GB'         => 'DD/MM/YYYY',
        'en_NZ'         => 'DD/MM/YYYY',
        'en_US'         => 'MM/DD/YYYY'
            
    };
    
    
    public static Map<String,String> localeToDateMonthFmt  = new Map<String,String> {
         'en_AU'         => 'dd MMMM yyyy',
         'en_US'         => 'MMMM dd yyyy',
         'en_CA'         => 'dd MMMM yyyy',
         'en_NZ'        => 'dd MMMM yyyy',
         'en_GB'       => 'dd MMMM yyyy'
     
    };

    
    public static Map<String, String> actionTypeToActionNameMap = 
                                new Map<String , String> {'Added'     =>  'Add to Deal',
                                                            'Removed'   =>  'Remove from Deal',
                                                            'Updated'   =>  'Update Deal'                                                       };
                                                            
    public static Map<String, String> exportDisplayObjectNameToObjectNameMap = new Map<String, String>{'Customers Card' => 'Customers',
                                                                                    'ReceiveMoneyTxn_Deposit'       => 'Money Received',
                                                                                    'Customer Order Sales Invoices' => 'Customer Invoices',
                                                                                    'Supplier Card'                 => 'Vendors',
                                                                                    'General Journal Entries'       => 'Journal Entries',
                                                                                    'Vendor Invoicing'              => 'Vendor Invoices'
                                                                                };
                                                                                
                                                                                 public static List<String> userPermissionCategoryNameList = new List<String> { 'Create/modify Records',
                                                                                    'Special Actions',
                                                                                    'Transaction Permissions',
                                                                                    'General Access'
                                                                                };
    
    public static Map<String, List<String>> categoryNameToPermissionTypeListMap = new Map<String, List<String>> {
            'General Access' => new List<String>{'Quick transfers', 'Deal commissions', 'CO profitability', 'Unit costs', 'Part costs', 'Costs', 'Price file import', 'Part inventory count', 'Cash reconciliation', 'Manage job clocking', 'Manage payroll clocking', 'Service scheduler', 'Workshop dashboard', 'Report scheduling', 'Reports', 'Homepage dashboards'},
            
            'Transaction Permissions' => new List<String>{'Unit ordering', 'Vendor invoicing', 'Vendor receiving', 'Vendor order', 'Bulk deleting', 'Internal Service', 'Customer invoicing', 'Deal', 'Service job', 'Merchandise', 'Quick sale'},
            
    		'Special Actions' => new List<String>{'Quick fulfill deal unit options', 'Modify payment method surcharge', 'Job ready to invoice status', 'Sales Taxes', 'Approve deals', 'Adjust store credits', 'Reallocate on order parts', 'Payment on account', 'Set cash drawer', 'Manage website products', 'Reopen finalized invoice', 'View incoming text messages', 'Backdating', 'Returns', 'Special order', 'Oversell inventory', 'Apply bulk discounts', 'Override price'},
            
            'Create/modify Records' => new List<String>{'Price Levels', 'Unit pricing & options', 'Text templates', 'Make & model', 'Locations & tags', 'Linked fees & forms', 'App settings', 'Tax management', 'User management', 'Accounting Integration', 'System Settings', 'Create Make & Model Adhoc', 'Kits', 'Fees', 'Stock units', 'Labor', 'Parts', 'Vendor products', 'Vendors', 'Customers'}                                         
    };
    
    public static Map<String, String> permissionTypeToFieldAPINameMap = new Map<String, String>{
                        'System Settings' => 'System_Settings__c',
                        'Sales Taxes' => 'Sales_Taxes__c',
                        'Price file import' => 'Price_file_import__c',
                        'Cash reconciliation' => 'Cash_reconciliation__c',
                        'Accounting Integration' => 'Accounting_settings_export__c',
                        'Price Levels' => 'Price_Levels__c',
                        'Costs' => 'Costs__c',
                        'Set cash drawer' => 'Set_cash_drawer__c',
						'Payment on account' => 'Payment_on_account__c',
                        'Quick sale' => 'quick_sale__c',
                        'Merchandise' => 'Merchandise__c',
                        'Service job' => 'Service_job__c',
                        'Deal' => 'Deal__c',
                        'Customer invoicing' => 'Customer_invoicing__c',
                        'Internal Service' => 'Internal_Service__c',
                        'Bulk deleting' => 'Bulk_deleting__c',
                        'Vendor order' => 'Vendor_order__c',
                        'Vendor receiving' => 'Vendor_receiving__c',
                        'Vendor invoicing' => 'Vendor_invoicing__c',
                        'Unit ordering' => 'Unit_ordering__c',
                        'Override price' => 'Override_price__c',
                        'Apply bulk discounts' => 'Apply_Bulk_Discounts__c',
                        'Oversell inventory' => 'Oversell_inventory__c',
                        'Special order' => 'Special_order__c',
                        'Returns' => 'Returns__c',
                        'Manage job clocking' => 'Manage_job_clocking__c',
                        'Manage payroll clocking' => 'Manage_payroll_clocking__c',
                        'Part inventory count' => 'Part_inventory_count__c',
                        'Reopen finalized invoice' => 'Open_invoiced_deal__c',
                        'View incoming text messages' => 'View_Incoming_Text_Messages__c',
                        'Customers' => 'customers__c',
                        'Vendors' => 'vendors__c',
                        'Vendor products' => 'vendor_products__c',
                        'Parts' => 'parts__c',
                        'Labor' => 'labor__c',
                        'Stock units' => 'stock_units__c',
                        'Fees' => 'fees__c',
    					'Kits' => 'kits__c',
    					'Backdating' => 'Backdating__c',
    					'Part costs' => 'Part_costs__c',
                        'Unit costs' => 'Unit_costs__c',
                        'Service scheduler' => 'Service_scheduler__c',
                        'Manage website products' => 'Manage_Website_Products__c', 
                        'Homepage dashboards' => 'Homepage_Dashboards__c',
                        'Reports' => 'Reports__c',
                        'Report scheduling' => 'Report_scheduling__c',
                        'Workshop dashboard' => 'Workshop_Dashboard__c',
                        'Reallocate on order parts' => 'Reallocate_On_Order_Parts__c',
                        'CO profitability' => 'CO_profitability__c',
                        'Deal commissions' => 'Deal_commissions__c',
                        'Adjust store credits' => 'Adjust_store_credits__c',
                        'Approve deals' => 'Approve_deals__c',
                        'User management' => 'User_management__c',
                        'Tax management' => 'Tax_management__c',
                        'App settings' => 'App_settings__c',
                        'Linked fees & forms' => 'Linked_fees_forms__c',
                        'Locations & tags' => 'Locations_tags__c',
                        'Make & model' => 'Make_model__c',
                        'Text templates' => 'Text_templates__c',
                        'Unit pricing & options' => 'Unit_pricing_options__c',
                        'Job ready to invoice status' => 'Job_ready_to_invoice_status__c',
                        'Quick transfers' => 'Quick_transfers__c',
                        'Modify payment method surcharge' => 'Modify_payment_method_surcharge__c',
                        'Quick fulfill deal unit options' => 'Quick_Fulfill_Deal_Unit_Options__c',
                        'Create Make & Model Adhoc' => 'Create_Make_Model_Adhoc__c'
    };
    
    public static Map<String, List<String>> permissionTypeToLabelListMap = new Map<String, List<String>> {
                'System Settings' => new List<String>{'enabled', ''},
                'Sales Taxes' => new List<String>{'assign', ''},
                'Price file import' => new List<String>{'enabled', ''},
                'Cash reconciliation' => new List<String>{'submit', 'reconcile'},
                'Accounting Integration' => new List<String>{'enabled', ''},
                'Price Levels' => new List<String>{'assign', 'create/modify'},
                'Costs' => new List<String>{'read only', 'modify'},
                'Set cash drawer' => new List<String>{'enabled', ''},
				'Payment on account' => new List<String>{'enabled', ''},
                'Quick sale' => new List<String>{'enabled', ''},
                'Merchandise' => new List<String>{'view', 'create/modify'},
                'Service job' => new List<String>{'view', 'create/modify'},
                'Deal' => new List<String>{'view', 'create/modify'},
                'Customer invoicing' => new List<String>{'view', 'create/modify'},
                'Internal Service' => new List<String>{'view', 'create/modify'},
                'Bulk deleting' => new List<String>{'enabled', ''},
                'Vendor order' => new List<String>{'view', 'create/modify'},
                'Vendor receiving' => new List<String>{'view', 'create/modify'},
                'Vendor invoicing' => new List<String>{'view', 'create/modify'},
                'Unit ordering' => new List<String>{'view', 'create/modify'},
                'Override price' => new List<String>{'enabled', ''},
                'Apply bulk discounts' => new List<String>{'enabled', ''},
                'Oversell inventory' => new List<String>{'enabled', ''},
                'Special order' => new List<String>{'enabled', ''},
                'Returns' => new List<String>{'enabled', ''},
                'Manage job clocking' => new List<String>{'enabled', ''},
                'Manage payroll clocking' => new List<String>{'enabled', ''},
                'Part inventory count' => new List<String>{'enabled', 'finalize count'},
                'Reopen finalized invoice' => new List<String>{'enabled', ''},
                'View incoming text messages' => new List<String>{'enabled', ''},
                'Customers' => new List<String>{'enabled', ''},
                'Vendors' => new List<String>{'enabled', ''},
                'Vendor products' => new List<String>{'enabled', ''},
                'Parts' => new List<String>{'enabled', ''},
                'Labor' => new List<String>{'enabled', ''},
                'Stock units' => new List<String>{'enabled', ''},
                'Fees' => new List<String>{'enabled', ''},
    			'Kits' => new List<String>{'enabled', ''},
    			'Backdating' => new List<String>{'enabled', ''},
    			'Part costs' => new List<String>{'enabled', ''},
                'Unit costs' => new List<String>{'enabled', ''},
                'Service scheduler' => new List<String>{'read only', 'create/modify'},
                'Manage website products' => new List<String>{'enabled', ''},
                'Homepage dashboards' => new List<String>{'enabled', ''},
                'Reports' => new List<String>{'enabled', ''},
                'Report scheduling' => new List<String>{'enabled', ''},
                'Workshop dashboard' => new List<String>{'enabled', ''},
                'Reallocate on order parts' => new List<String>{'enabled', ''},
                'CO profitability' => new List<String>{'enabled', ''},
                'Deal commissions' => new List<String>{'enabled', ''},
                'Adjust store credits' => new List<String>{'enabled', ''},
                'Approve deals' => new List<String>{'enabled', ''},
                'User management' => new List<String>{'enabled', ''},
                'Tax management' => new List<String>{'enabled', ''},
                'App settings' => new List<String>{'enabled', ''},
                'Linked fees & forms' => new List<String>{'enabled', ''},
                'Locations & tags' => new List<String>{'enabled', ''},
                'Make & model' => new List<String>{'enabled', ''},
                'Text templates' => new List<String>{'enabled', ''},
                'Unit pricing & options' => new List<String>{'enabled', ''},
                'Job ready to invoice status' => new List<String>{'enabled', ''},
                'Quick transfers' => new List<String>{'enabled', ''},
                'Modify payment method surcharge' => new List<String>{'enabled', ''},
                'Quick fulfill deal unit options' => new List<String>{'enabled', ''},
                'Create Make & Model Adhoc' => new List<String>{'enabled', ''}
    };
    public static Map<String,String> permissionTypeToSourceEntityMap = new Map<String,String>{
                                                                                'Merchandise' => 'Customer Order',
                                                                                'Merchandise,Service job,Deal' => 'Customer Invoice',
                                                                                'Vendor order' => 'Vendor Order',
                                                                                'Vendor receiving' => 'Vendor Receiving',
                                                                                'Vendor invoicing' => 'Vendor Invoicing'
   };
   
   /*
   public static Map<String,String> countryNameToCountryCodeMap = new Map<String,String>{ 'Australia' => '61',
                                                                                'Canada' => '1',
                                                                                'India' => '91'};
    */
    public static Map<Integer, String> smsRespCodeToErrMsgMap = new Map<Integer, String>{202 => 'Success',
                                                                                400 => 'A parameter is missing or is invalid',
                                                                                401 => 'Authentication failed',
                                                                                404 => 'Resource cannot be found',
                                                                                405 => 'HTTP method not allowed',
                                                                                500 => 'Server error'
                                                                                };
                                                                                
    public static Map<Integer, String> priorityNumberToMatchKeyNameMap = new Map<Integer, String> {             
        1 => 'Email',
        2 => 'Phone number',
        4 => 'Last name',
        5 => 'First name',
        6 => 'Name',
        7 => 'Address'
    };
    public static final String NOT_CALCULATED = 'Not Calculated';
    public static final String PERCENTAGE_OF_LABOR_TOTAL = 'Percentage of Labor Total';
    public static final String FIXED_AMOUNT_PER_HOUR = 'Fixed Amount per Hour';
    public static final String SHOP_SUPPLY = 'Shop Supply';
    public static final String ON_ORDER_STATUS = 'On Order';
    public static final String TEMP_ORDERD_UNIT_STATUS = 'Temporary';
    public static final String REQ_ORDERD_UNIT_STATUS = 'Required';
    public static final String ACTIVE = 'Active';
    public static final String PARTIALLY_INVOICED = 'Partially Invoiced';
    public static final String INVOICED = 'Invoiced';
    public static final String DOC = 'Doc';
    public static final String ORIG = 'Orig';
    public static final String HUT = 'Hut';
    public static final String TITLE = 'Title';
    public static final String APF = 'APF';
    public static final String DMV_FEES = 'DMV FEES';
    
}
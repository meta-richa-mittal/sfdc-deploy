public without sharing class IntegrationUtility {
    
    public static final String ITEM_CATEGORY = 'Item_Category';
    public static final String PART_FIFO = 'Part_FIFO';
    public static final String PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM = 'Part_FIFO_Bucket_Activity_Line_Item';
    public static final String VENDOR = 'Vendor';
    public static final String CUSTOMER = 'Customer';
    public static final String BATCH_CUSTOMER = 'Batch_Customer';
    public static final String BATCH_VENDOR = 'Batch_Vendor';
    public static final String BATCH = 'Batch';
    public static final String STORE_CREDIT = 'Store_Credit';
    public static final String UNIT_PRICE_COST = 'Unit_Price_Cost';
    
    public static final String CREATE_ACTION = 'CREATE';
    public static final String UPDATE_ACTION = 'UPDATE';
    public static final String RETRIEVE_ACTION = 'RETRIEVE';
    public static final String DELETE_ACTION = 'DELETE';
    
    public static final String ITEM = 'Item';
    public static final String JOURNAL_ENTRY = 'Journal Entry';
    public static List<Integration_Entity__mdt> integrationEntityMetadataList;
    
    public static final String PART_CATEGORY = 'Part_Category';
    public static final String CO_DEPOSIT = 'CO_Deposit';
    public static final String CO_INVOICE_PAYMENT = 'CO_Invoice_Payment';
    public static final String CONTACTS = 'Contacts';
    public static final String ORGANISATION = 'Organisation';
    public static final String CURRENCIES = 'Currencies';

    public static final STring ACCOUNT = 'Account';
    public static final STring TAX_RATE = 'Tax Rate';
    public final static String TAX_CODE = 'Tax Code';

    public static final String VENDOR_RECEIVING = 'Vendor_Receiving';
    public static final String STOCK_UNIT_CATEGORY = 'Stock_Unit_Category';
    public static final String STOCKED = 'Stocked';
    public static final String INVOICE = 'Invoice';
    public static final String CREDIT_NOTE = 'Credit Note';
    public final static String INTERNAL = 'Internal';
    public final static String CLOSED = 'Closed';
    public final static String DEAL = 'Deal'; 
    public final static String STOCK_TRADE_IN = 'Stock_Trade_In';
    
    public static final String VO_INVOICE = 'VO_Invoice';
    public static final String VO_INVOICE_VARIANCE_JE = 'VO_Invoice_Varinace_JE';
    public final static String INVOICED = 'Invoiced';
    public static final String CO_INVOICE_JE = 'CO_Invoice_JE';
    public static final String UNIT_INVOICE_JE = 'Unit_Invoice_JE';
    public static final String COUNT_SESSION_JE = 'Count_Session_JE';
    public static final String LIEN_PAYOUT = 'Lien_Payout';
    public static final String INVOICE_PAYMENT = 'Invoice_Payment';
    public static final String UNIT_INVOICE = 'Unit_Invoice';
    public static final String VO_RETURN = 'VO_Return';
    public static final String VO_RETURN_VARIANCE_JE = 'VO_Return_Variance_JE';
    public static final String HOURS_LOGGED = 'Hours_Logged';
    public static final String AR_PAYMENT = 'AR_Payment';
    public static final String QB_AR_PAYMENT = 'QB_AR_Payment';
    public static final String PAYMENT_ON_ACCOUNT = 'Payment_on_Account';
    public static final String ARPAYMENT_ON_ACCOUNT = 'ARPayment_on_Account';
    public static final String CONNECTION = 'Connection';
    public static final String UNIT_NITC_JE = 'Unit_NITC_JE';
    public static final String UNIT_CONSIGNMENT = 'Unit_Consignment';
    public static final String CREDITED = 'Credited';
    public static final String ARCR_PAYMENT = 'ARCR_Payment';
    public final static String CREDIT_MEMO = 'Credit Memo';
    public final static String REFUND_RECEIPT = 'Refund Receipt';
    public final static String SALES_RECEIPT = 'Sales Receipt';
    public final static String VENDOR_CREDIT = 'Vendor Credit';
    public final static String PAYMENT = 'Payment';
    public final static String BILL = 'Bill';
    public final static String CASH_RECONCILIATION = 'Cash_Reconciliation';

    public static final Integer XERO_MAX_RETRY_COUNT = 2;
    
    public void getIntegrationEntityMetadata(List<BaseIntegrationService> baseIntegrationServiceList, String entityName) {
        getIntegrationEntityMetadata(baseIntegrationServiceList, new List<String>{entityName});
    }
    
    public void getIntegrationEntityMetadata(List<BaseIntegrationService> baseIntegrationServiceList, List<String> entityNameList) {
        List<Integration_Entity__mdt> intEntityMetadataList = 
                [Select Entity_Name__c, Sync_Flag_API_Name__c, Integration_Id_API_Name__c, Object_API_Name__c, Accounting_Response_API_Name__c FROM Integration_Entity__mdt 
                    WHERE MasterLabel =: baseIntegrationServiceList[0].integrationName AND Entity_Name__c IN: entityNameList];
        if(intEntityMetadataList.size() == 0) throw new BlackpurlException('No Sync flag specified.');
        baseIntegrationServiceList[0].integrationEntityNameToRecMap = new Map<String, Integration_Entity__mdt>();
        for(Integration_Entity__mdt intEntityMetadataRec : intEntityMetadataList) {
            baseIntegrationServiceList[0].integrationEntityNameToRecMap.put(intEntityMetadataRec.Entity_Name__c, intEntityMetadataRec);
        }
    }

    public static Map<String, Integration_Entity__mdt> getIntegrationEntityMetadata(List<String> entityNameList, String integrationName) {
        List<Integration_Entity__mdt> intEntityMetadataList = [Select Entity_Name__c, Sync_Flag_API_Name__c, Integration_Id_API_Name__c, Object_API_Name__c, Accounting_Response_API_Name__c FROM Integration_Entity__mdt 
                    WHERE MasterLabel =: integrationName AND Entity_Name__c IN: entityNameList];
        if(intEntityMetadataList.size() == 0) throw new BlackpurlException('No Sync flag specified.');
        Map<String, Integration_Entity__mdt> integrationEntityNameToRecMap = new Map<String, Integration_Entity__mdt>();
        for(Integration_Entity__mdt intEntityMetadataRec : intEntityMetadataList) {
            integrationEntityNameToRecMap.put(intEntityMetadataRec.Entity_Name__c, intEntityMetadataRec);
        }
        return integrationEntityNameToRecMap;
    }

    public static String getSyncFlagAPIName(String entityName) {
        List<Integration_Entity__mdt> intEntityMetadataList = [Select Sync_Flag_API_Name__c FROM Integration_Entity__mdt 
                    WHERE MasterLabel =: IntegrationServiceFactory.getActiveAccountingIntegrationName() AND Entity_Name__c =: entityName];
        if(intEntityMetadataList.size() == 0 || intEntityMetadataList[0].Sync_Flag_API_Name__c == null) throw new BlackpurlException('No Sync flag specified.');
        return intEntityMetadataList[0].Sync_Flag_API_Name__c;
    }
    
    /*Caution: This Map is used in several places. Please be cautious before changing anything here*/
	public static Map<String,String> entityNameToEntityMap = new Map<String,String> { 'Customer' => 'Customer',
																					  'Item_Category' => 'Category',
																					  'Part_FIFO' => 'Part',
																					  'Part_FIFO_Bucket_Activity_Line_Item' => 'Part Adjustment',
																					  'Vendor' => 'Vendor',
																					  'Store_Credit' => 'Store Credit',
																					  'Unit_Price_Cost' => 'Unit Price Adjustment',
																					  'Part_Category' => 'Part Category Change',
																					  'CO_Deposit' => 'Customer Order Deposit',
																					  'CO_Invoice_Payment' => 'Payment',
																					  'Tax Rate' => 'Tax Rate',
																					  'Vendor_Receiving' => 'Vendor Recieve',
																					  'Stock_Unit_Category' => 'Stock Unit Category Change',
																					  'Invoice' => 'Customer Order Invoice',
																					  'VO_Invoice' => 'Vendor Invoice',
																					  'CO_Invoice_JE' => 'Customer Order Invoice JE',
																					  'Lien_Payout' => 'Lien Payout',
																					  'Invoice_Payment' => 'Customer Order Invoice Payment',
																					  'Unit_Invoice' => 'Unit Invoice',
                                                                                      'Unit_Invoice_JE' => 'Unit Invoice JE',
																					  'VO_Return' => 'Vendor Credit',
																					  'Stock_Trade_In' => 'Stock Trade In',
																					  'Hours_Logged' => 'Clocking Entry',
																					  'AR_Payment' => 'AR Payment',
																					  'Payment_on_Account' => 'AR Payment JE',
                                                                                      'Count_Session_JE' => 'Count Session',
                                                                                      'Unit_NITC_JE' => 'Unit NITC JE',
                                                                                      UNIT_CONSIGNMENT => 'Unit Consignment',
                                                                                      VO_INVOICE_VARIANCE_JE => 'Vendor Invoice Variance JE',
                                                                                      VO_RETURN_VARIANCE_JE => 'Vendor Credit Variance JE',
                                                                                      CASH_RECONCILIATION => 'Cash Reconciliation'
	}; 

    public static Map<String, String> syncEntityNameToAsynListViewNameMap = new Map<String, String>{
        'Customer' => 'Async Customers (QB/Xero)',
        'Provider' => 'Async Providers (QB/Xero)',
        'Vendor' => 'Async Vendors (QB/Xero)',
        'CO_Invoice_Payment' => 'Async CO Invoices Payments JE (QB/Xero)',
        'CO_Deposit' => 'Async CO Deposits (QB/Xero)',
        'Invoice' => 'Async CO Invoices (QB/Xero)',
        'CO_Invoice_JE' => 'Async CO Invoices JE (QB/Xero)',
        'Invoice_Payment' => 'Async CO Invoices Payment (QB/Xero)',
        'Lien_Payout' => 'Async Lien Payout (QB/Xero)',
        'Stock_Trade_In' => 'Async Stocked In JE (QB/Xero)',
        'Unit_Consignment' => 'Async Consignment Units (QB/Xero)',
        'Stock_Unit_Category' => 'Async Unit Category JE (QB/Xero)',
        'Unit_Invoice' => 'Async Unit Invoice (QB/Xero)',
        'Unit_Invoice_JE' => 'Async Unit Invoice JE (QB/Xero)',
        'Unit_NITC_JE' => 'Async Unit NITC JE (QB/Xero)',
        'Count_Session_JE' => 'Async Count Session (QB/Xero)',
        'Hours_Logged' => 'Async Clocking Entry (QB/Xero)',
        'Part_Category' => 'Async Part Category (QB/Xero)',
        'Part_FIFO' => 'Async Part FIFO (QB/Xero)',
        'Part_FIFO_Bucket_Activity_Line_Item' => 'Async Part Adjustment (QB/Xero)',
        'Payment_on_Account' => 'Async AR Payment JE (QB/Xero)',
        'VO_Return' => 'Async Return Credit (QB/Xero)',
        'VO_Return_Variance_JE' => 'Async Return Credit JE (QB/Xero)',
        'Store_Credit' => 'Async Store Credit JE (QB/Xero)',
        'Unit_Price_Cost' => 'Async Price Adjustment (QB/Xero)',
        'VO_Invoice' => 'Async Vendor Invoice (QB/Xero)',
        'VO_Invoice_Varinace_JE' => 'Async VI Variance JE (QB/Xero)',
        'Vendor_Receiving' => 'Async VR JE (QB/Xero)',
        'Cash_Reconciliation' => 'Async Cash Reconciliation JE (QB/Xero)'
    };

    public static Map<String, String> syncEntityNameToFailureEntityNameMap = new Map<String, String>{
        'Customer' => 'Account - Customer',
        'Provider' => 'Account - Provider',
        'Vendor' => 'Account - Vendor',
        'CO_Invoice_Payment' => 'CO Checkout payments (COIP)',
        'CO_Deposit' => 'CO Deposits (CODN)',
        'Invoice' => 'CO Invoice Header',
        'CO_Invoice_JE' => 'CO Invoice JE',
        'Invoice_Payment' => 'CO Invoice Payment',
        'Lien_Payout' => 'CO Lien payout',
        'Stock_Trade_In' => 'CO Stocked trade-in',
        'Unit_Consignment' => 'COU - Consignments',
        'Stock_Unit_Category' => 'COU - Unit category',
        'Unit_Invoice' => 'COU - Unit Invoice',
        'Unit_Invoice_JE' => 'COU - Unit JE',
        'Unit_NITC_JE' => 'COU - Unit NITC JE',
        'Count_Session_JE' => 'Count session JE',
        'Hours_Logged' => 'Hours logged',
        'Part_Category' => 'Part - Category',
        'Part_FIFO' => 'Part - FIFO bucket',
        'Part_FIFO_Bucket_Activity_Line_Item' => 'Part - FIFO bucket activity',
        'Payment_on_Account' => 'Payment on account',
        'VO_Return' => 'Vendor credits',
        'VO_Return_Variance_JE' => 'Vendor credit JE',
        'Store_Credit' => 'Store credits',
        'Unit_Price_Cost' => 'Unit Prices & cost',
        'VO_Invoice' => 'Vendor invoice',
        'VO_Invoice_Varinace_JE' => 'Vendor invoice JE',
        'Vendor_Receiving' => 'Vendor receiving', 
        'Cash_Reconciliation' => 'Cash Reconciliation JE'
    };
}
/**
 * Author: Pooja Khandelwal
 * Since: Dec. 23, 2014
 * Name: VendorInvoicingHeaderTriggerHelper
 * Description: Helper class for triggers on COInvoice object
**/
public without sharing class VendorInvoicingHeaderTriggerHelper {
    // List to store trigger new list
    public static List<Vendor_Invoicing_Header__c> invoiceNewList = new List<Vendor_Invoicing_Header__c>();
    
    // List to store trigger old list
    public static List<Vendor_Invoicing_Header__c> invoiceOldList = new List<Vendor_Invoicing_Header__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Vendor_Invoicing_Header__c> invoiceNewMap = new Map<Id, Vendor_Invoicing_Header__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Vendor_Invoicing_Header__c> invoiceOldMap = new Map<Id, Vendor_Invoicing_Header__c>();
     
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.manageVOInvoiceSyncFlag(invoiceNewList, invoiceOldMap);
    }
    
    public static void setVendorInvoiceDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(invoiceOldMap, invoiceNewList, IntegrationUtility.VO_INVOICE);
    }
}
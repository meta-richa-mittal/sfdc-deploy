/**
 * Author: Nidhi Sharma
 * Since: Sept 16, 2024
 * Name: MergeCustomerCtrl
**/
global without sharing class MergeCustomerCtrl {
    
    global MergeCustomerCtrl (NewHomePageCtrl controller){}
    public MergeCustomerCtrl() {}

    @RemoteAction
    global static Decimal getCustomerOpenARBalance(String customerId) {
    	return AccountingUtil.getCustomerOpenARBalance(BPUtility.getDecodedString(customerId));
    }

    @RemoteAction
    global static String getCustomerDetailsById(String contactId) {
    	return BPUtility.getEncodedString(System.Json.serialize(MergeCustomerService.getCustomerDetailsById(BPUtility.getDecodedString(contactId))));
    }

    @RemoteAction
    public static String getCustomerRelatedRecordsSummary(String customerId) {
        return BPUtility.getEncodedString(System.Json.serialize(MergeCustomerService.getCustomerRelatedRecordsSummary(BPUtility.getDecodedString(customerId))));
    }

    @RemoteAction
    public static void mergeCustomers(String mergeJson) {
        MergeCustomerService.mergeCustomers(BPUtility.getDecodedString(mergeJson));
    }
}
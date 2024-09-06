/**
 * Author: Anurag Anand
 * Since: April. 26, 2016
 * Name: DeleteEmptyRecordsSchedulerCtrl
 * Description: Apex class which contains methods to delete Active Blank Records.
**/
public without sharing class DeleteEmptyRecordsSchedulerCtrl {

    public static void deleteVOLineItemWhenQuote() {
        if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        Database.delete([SELECT Id FROM Vendor_Order_Line_Item__c WHERE CO_Header__r.Order_Status__c = 'Quote' AND Vendor_Order_Line_Item_Group__c = null], false);
    }
}
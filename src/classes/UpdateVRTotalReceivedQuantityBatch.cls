/**
 * Author: Raghav Khandelwal
 * Since: May 20, 2021
 * Name: UpdateVRTotalReceivedQuantityBatch
 * Description: Batch for update VR total rececived quantity
**/
public without sharing class UpdateVRTotalReceivedQuantityBatch implements Database.Batchable<sobject> {
    
    public  UpdateVRTotalReceivedQuantityBatch(){}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id,Total_Received_Qty__c FROM Vendor_Receiving_Header__c WHERE Total_Received_Qty__c = null ORDER BY Name ASC';
        return Database.getQueryLocator(strQuery); 
    }

    public void execute(Database.batchableContext bc, List<Vendor_Receiving_Header__c> vrHeaderList) {
        if(vrHeaderList != null && vrHeaderList.size() > 0) {
            vrHeaderList[0].Total_Received_Qty__c = 0;
            List<Vendor_Receiving_Group__c> vrgList = [Select Vendor_Receiving_Header__c, Recieved__c, Part__c, Sublet__c, Part__r.Package_Qty__c, Part__r.Packaged_Part__c, Is_Order_As_Individual_Item__c  
                                From Vendor_Receiving_Group__c where Vendor_Receiving_Header__c In :vrHeaderList];
            for(Vendor_Receiving_Group__c vrg : vrgList) {
                if(vrg.Recieved__c != null) {
                    vrHeaderList[0].Total_Received_Qty__c += VendorReceivingGroupTriggerHelper.getReceivedQuantity(vrg);
                }
            }
            DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vrHeaderList);
        }
    }

    public void finish(Database.batchableContext bc) {}
}
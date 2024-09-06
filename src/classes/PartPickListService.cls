/** 
* Author: Tarun Khandelwal
* Since: March 01, 2021
* Name: PartPickListService 
* Description: Apex service class which contains methods related to PartPickList section.
**/
public without sharing class PartPickListService {
    
    public static List<PartPickListCOLIWrapper> getPartPickListCOLIList(String coHeaderId) {
        // Get all Vendor Order Line Items related to CO
        List<Vendor_Order_Line_Item__c> specialOrderedVOLineItemList = SOQLUtil.getSpecialOrderByCOHeaderId(coHeaderId);
        
        // Get Vendor Id List from related Vendor order line item List.
        // This Vendor Id List is used to find out lead time.
        List<String> vendorIdList = getVendorIdList(specialOrderedVOLineItemList);
        
        // Find out default lead time per vendor
        Map<String, Integer> vendorIdToDefaultLeadTimeMap = CustomerOrderCtrl_V2.getVendorLeadTimeMap(vendorIdList);
        
        Map<String, List<COHeaderWrapper.SpecialOrder>> coLineItemIdToVOLIListMap = new Map<String, List<COHeaderWrapper.SpecialOrder>>();
        Set<String> specialOrderCOLIIdSet = new Set<String>();
        for(Vendor_Order_Line_Item__c specialOrderedVOLI : specialOrderedVOLineItemList) {
            if(String.isBlank(specialOrderedVOLI.CO_Line_Item__r.Invoice_Number__c)) {
                Integer leadTime = 0;
                if(specialOrderedVOLI.Part__c != null) {
                    leadTime = vendorIdToDefaultLeadTimeMap.get(specialOrderedVOLI.Part__r.Vendor__c);
                } else if(specialOrderedVOLI.Sublet__c != null) {
                    leadTime = vendorIdToDefaultLeadTimeMap.get(specialOrderedVOLI.Sublet__r.Vendor__c);
                }
                specialOrderCOLIIdSet.add(specialOrderedVOLI.CO_Line_Item__c);
                
                COHeaderWrapper.SpecialOrder specialOrderObj = new COHeaderWrapper.SpecialOrder(specialOrderedVOLI, leadTime);
                if(!coLineItemIdToVOLIListMap.containsKey(specialOrderedVOLI.CO_Line_Item__c)) {
                    coLineItemIdToVOLIListMap.put(specialOrderedVOLI.CO_Line_Item__c, new List<COHeaderWrapper.SpecialOrder>());
                }
                coLineItemIdToVOLIListMap.get(specialOrderedVOLI.CO_Line_Item__c).add(specialOrderObj);
            }
        }

        List<CO_Line_Item__c> coliList = SOQLUtil.getPartPickListCOLIByCOHeaderId(coHeaderId, specialOrderCOLIIdSet);
        List<PartPickListCOLIWrapper> partPickListCOLiWrapperList = new List<PartPickListCOLIWrapper>();
        for(CO_Line_Item__c coliRec : coliList) {
            partPickListCOLiWrapperList.add(new PartPickListCOLIWrapper(coliRec));
        }
        for(String coLineItemId : coLineItemIdToVOLIListMap.keyset()) {
            partPickListCOLiWrapperList.add(new PartPickListCOLIWrapper(coLineItemIdToVOLIListMap.get(coLineItemId)));
        }
        return partPickListCOLiWrapperList;
    }
    
    private static List<Id> getVendorIdList(List<Vendor_Order_Line_Item__c> voLineItemList) {
        List<String> vendorIdList = new List<String>();
        for(Vendor_Order_Line_Item__c voLineItem : voLineItemList) {
            if(voLineItem.Part__c != null && String.isBlank(voLineItem.CO_Line_Item__r.Invoice_Number__c)) {
                vendorIdList.add(voLineItem.Part__r.Vendor__c);
            } else if(voLineItem.Sublet__c != null) {
                vendorIdList.add(voLineItem.Sublet__r.Vendor__c);
            }
        }
        return vendorIdList;
    }
}
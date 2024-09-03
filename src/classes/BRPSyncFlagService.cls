public without sharing class BRPSyncFlagService {
    public static void manageCOInvoiceSyncFlag(Map<Id, CO_Invoice_Header__c> newMap, Map<Id, CO_Invoice_Header__c> oldMap) {
    	List<String> closedCOInvoiceIdList = new List<String>();
    	for(String coInvoiceId : newMap.keyset()) {
        	if(newMap.get(coInvoiceId).Invoice_Status__c != oldMap.get(coInvoiceId).Invoice_Status__c && newMap.get(coInvoiceId).Invoice_Status__c == IntegrationUtility.CLOSED) {
        		closedCOInvoiceIdList.add(coInvoiceId);
        	}
    	}
    	
		Set<String> brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
		Set<String> brpUnitMakeIdSet = BRPUtility.getAllBRPUnitMakeIdSet();
    	if(closedCOInvoiceIdList.size() > 0) {
    		Map<String, CO_Invoice_Item__c> invoicedDealIdToInvoicedItemMap = new Map<String, CO_Invoice_Item__c>();
    		Map<String, CO_Invoice_Item__c> invoicedCOKHIdToInvoicedItemMap = new Map<String, CO_Invoice_Item__c>();
    		for(CO_Invoice_Item__c coInvoiceItemRec : getCOInvItems(closedCOInvoiceIdList)) {
	        	Set<String> unitVendorIdSet = new Set<String>();
	        	if(coInvoiceItemRec.Deal__c != null) {
	        		invoicedDealIdToInvoicedItemMap.put(coInvoiceItemRec.Deal__c, coInvoiceItemRec);
	        	} else if(coInvoiceItemRec.Service_Order_Header__c != null && (coInvoiceItemRec.SO_Payment_Role__c == null 
	        				|| (coInvoiceItemRec.SO_Payment_Role__c != null && coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible'))
	        				&& !newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Repair_Order_Sync__c 
							&& (brpVendorsIdSet.contains(coInvoiceItemRec.Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c) 
							|| brpUnitMakeIdSet.contains(coInvoiceItemRec.Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c))) {
	        		newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Repair_Order_Sync__c = true;
	        	} else if(coInvoiceItemRec.CO_Kit_Header__c != null) {
	        		invoicedCOKHIdToInvoicedItemMap.put(coInvoiceItemRec.CO_Kit_Header__c, coInvoiceItemRec);
	        	} else if(coInvoiceItemRec.CO_Line_Item__c != null && coInvoiceItemRec.CO_Line_Item__r.Part__c != null 
	        				&& !newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c 
	        				&& brpVendorsIdSet.contains(coInvoiceItemRec.CO_Line_Item__r.Part__r.Vendor__c)) {
	        		newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c = true;
	        	}
	        }
	        
	        if(invoicedDealIdToInvoicedItemMap.size() > 0) {
	        	for(Deal_Item__c dealItemRec: getDealItems(invoicedDealIdToInvoicedItemMap.keySet())) {
					if((brpVendorsIdSet.contains(dealItemRec.Customer_Owned_Unit__r.Vendor__c) 
						|| brpUnitMakeIdSet.contains(dealItemRec.Customer_Owned_Unit__r.Unit_Make__c)) && dealItemRec.Type__c != 'Trade In'
						&& invoicedDealIdToInvoicedItemMap.containsKey(dealItemRec.Deal__c) 
						&& !newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_BRP_RDR_Sync__c) {
						newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_BRP_RDR_Sync__c = true;
					}
				}
	        }
	        if(invoicedCOKHIdToInvoicedItemMap.size() > 0) {
	        	for(CO_Line_Item__c coliRec: getCOLIForCOKH(invoicedCOKHIdToInvoicedItemMap.keySet())) {
					if(coliRec.Part__c != null && invoicedCOKHIdToInvoicedItemMap.containsKey(coliRec.CO_Kit_Header__c) 
							&& !newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c 
	        				&& brpVendorsIdSet.contains(coliRec.Part__r.Vendor__c)) {
						newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c = true;
					}
				}
	        }
    	}
    }
    
    private static List<CO_Invoice_Item__c> getCOInvItems(List<String> closedCOInvoiceIdList) {
		return [SELECT CO_Kit_Header__c, CO_Line_Item__r.Part__r.Vendor__c, Deal__c, Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName, CO_Invoice_Header__c, Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN :closedCOInvoiceIdList AND isActive__c = true];
	}
	
	private static List<Deal_Item__c> getDealItems(Set<String> invoicedDealIdSet) {
		return [SELECT Customer_Owned_Unit__c, Customer_Owned_Unit__r.Vendor__c, Deal__c, Type__c, Customer_Owned_Unit__r.Unit_Make__c FROM Deal_Item__c WHERE Deal__c IN :invoicedDealIdSet];
	}
	
	private static List<CO_Line_Item__c> getCOLIForCOKH(Set<String> invoicedCOKHIdSet) {
		return [SELECT Part__c, Part__r.Vendor__c, CO_Kit_Header__c FROM CO_Line_Item__c WHERE CO_Kit_Header__c IN :invoicedCOKHIdSet];
	}
}
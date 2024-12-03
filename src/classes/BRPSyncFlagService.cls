public without sharing class BRPSyncFlagService {
    public static void manageCOInvoiceSyncFlag(Map<Id, CO_Invoice_Header__c> newMap, Map<Id, CO_Invoice_Header__c> oldMap) {
		Boolean isBRPV4Enabled = (BRPUtility.getAPIVersion() == BRPUtility.API_VERSION_V4);
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
			Map<String, String> soIdToInvoiceIdMap = new Map<String, String>();
    		for(CO_Invoice_Item__c coInvoiceItemRec : getCOInvItems(closedCOInvoiceIdList)) {
	        	Set<String> unitVendorIdSet = new Set<String>();
	        	if(coInvoiceItemRec.Deal__c != null) {
	        		invoicedDealIdToInvoicedItemMap.put(coInvoiceItemRec.Deal__c, coInvoiceItemRec);
	        	} else if(coInvoiceItemRec.Service_Order_Header__c != null && (coInvoiceItemRec.SO_Payment_Role__c == null 
	        				|| (coInvoiceItemRec.SO_Payment_Role__c != null && coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible'))
	        				&& (!newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Repair_Order_Sync__c 
							|| !newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c) 
							&& (brpVendorsIdSet.contains(coInvoiceItemRec.Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c) 
							|| brpUnitMakeIdSet.contains(coInvoiceItemRec.Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c))) {
	        		newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Repair_Order_Sync__c = true;
					if(isBRPV4Enabled) {
						newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c = true;
					}
	        	} else if(coInvoiceItemRec.CO_Kit_Header__c != null) {
	        		invoicedCOKHIdToInvoicedItemMap.put(coInvoiceItemRec.CO_Kit_Header__c, coInvoiceItemRec);
	        	} else if(coInvoiceItemRec.CO_Line_Item__c != null && coInvoiceItemRec.CO_Line_Item__r.Part__c != null 
	        				&& (!newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c 
							|| !newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c)
	        				&& brpVendorsIdSet.contains(coInvoiceItemRec.CO_Line_Item__r.Part__r.Vendor__c)) {
	        		newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c = true;
					if(isBRPV4Enabled) {
						newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c = true;
					}
	        	}
				
				if(isBRPV4Enabled && coInvoiceItemRec.Service_Order_Header__c != null && (coInvoiceItemRec.SO_Payment_Role__c == null 
	        				|| (coInvoiceItemRec.SO_Payment_Role__c != null && coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible'))
	        				&& !newMap.get(coInvoiceItemRec.CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c) {
					soIdToInvoiceIdMap.put(coInvoiceItemRec.Service_Order_Header__c, coInvoiceItemRec.CO_Invoice_Header__c);
				}
	        }
	        
	        if(invoicedDealIdToInvoicedItemMap.size() > 0) {
	        	for(Deal_Item__c dealItemRec: getDealItems(invoicedDealIdToInvoicedItemMap.keySet())) {
					if((brpVendorsIdSet.contains(dealItemRec.Customer_Owned_Unit__r.Vendor__c) 
						|| brpUnitMakeIdSet.contains(dealItemRec.Customer_Owned_Unit__r.Unit_Make__c))
						&& invoicedDealIdToInvoicedItemMap.containsKey(dealItemRec.Deal__c) 
						&& (!newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_BRP_RDR_Sync__c 
						|| !newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c)) {
						if(dealItemRec.Type__c != 'Trade In') {
							newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_BRP_RDR_Sync__c = true;
						}
						if(isBRPV4Enabled && (dealItemRec.Type__c != 'Trade In' || (dealItemRec.Type__c == 'Trade In' && dealItemRec.Deal__r.Deal_Section_Trade_Only__c))) {
							newMap.get(invoicedDealIdToInvoicedItemMap.get(dealItemRec.Deal__c).CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c = true;
						}
					}
				}
	        }
	        if(invoicedCOKHIdToInvoicedItemMap.size() > 0) {
	        	for(CO_Line_Item__c coliRec: getCOLIForCOKH(invoicedCOKHIdToInvoicedItemMap.keySet())) {
					if(coliRec.Part__c != null && invoicedCOKHIdToInvoicedItemMap.containsKey(coliRec.CO_Kit_Header__c) 
							&& (!newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c 
							|| !newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c)
	        				&& brpVendorsIdSet.contains(coliRec.Part__r.Vendor__c)) {
						newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_BRP_Parts_Invoice_Sync__c = true;
						if(isBRPV4Enabled) {
							newMap.get(invoicedCOKHIdToInvoicedItemMap.get(coliRec.CO_Kit_Header__c).CO_Invoice_Header__c).Available_For_Retail_Transactions_Sync__c = true;
						}
					}
				}
	        }
			if(soIdToInvoiceIdMap.size() > 0) { 
				List<Service_Order_Line_Item__c> soliList = [SELECT Id, Service_Order_Header__c FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c IN :soIdToInvoiceIdMap.keySet() AND Part__r.Vendor__c IN :brpVendorsIdSet];
				for(Service_Order_Line_Item__c soliRec : soliList) {
					if(!newMap.get(soIdToInvoiceIdMap.get(soliRec.Service_Order_Header__c)).Available_For_Retail_Transactions_Sync__c) {
						newMap.get(soIdToInvoiceIdMap.get(soliRec.Service_Order_Header__c)).Available_For_Retail_Transactions_Sync__c = true;
					}
				}	
			}
    	}
    }
    
    private static List<CO_Invoice_Item__c> getCOInvItems(List<String> closedCOInvoiceIdList) {
		return [SELECT CO_Kit_Header__c, CO_Line_Item__r.Part__r.Vendor__c, Deal__c, Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName, CO_Invoice_Header__c, Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN :closedCOInvoiceIdList AND isActive__c = true];
	}
	
	private static List<Deal_Item__c> getDealItems(Set<String> invoicedDealIdSet) {
		return [SELECT Customer_Owned_Unit__c, Customer_Owned_Unit__r.Vendor__c, Deal__c, Deal__r.Deal_Section_Trade_Only__c, Type__c, Customer_Owned_Unit__r.Unit_Make__c FROM Deal_Item__c WHERE Deal__c IN :invoicedDealIdSet];
	}
	
	private static List<CO_Line_Item__c> getCOLIForCOKH(Set<String> invoicedCOKHIdSet) {
		return [SELECT Part__c, Part__r.Vendor__c, CO_Kit_Header__c FROM CO_Line_Item__c WHERE CO_Kit_Header__c IN :invoicedCOKHIdSet];
	}
}
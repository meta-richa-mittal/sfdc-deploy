/**
 * Author: Pooja Khandelwal
 * Since: Dec. 23, 2014
 * Name: COInvoiceTriggerHelper
 * Description: Helper class for triggers on COInvoice object
**/
public without sharing class COInvoiceTriggerHelper {
	
	public static Boolean isForceStopTrigger = false;
    // List to store trigger new list
    public static List<CO_Invoice_Header__c> invoiceNewList = new List<CO_Invoice_Header__c>();
    
    // List to store trigger old list
    public static List<CO_Invoice_Header__c> invoiceOldList = new List<CO_Invoice_Header__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, CO_Invoice_Header__c> invoiceNewMap = new Map<Id, CO_Invoice_Header__c>();

    // Map to store Old Trigger Map
    public static Map<Id, CO_Invoice_Header__c> invoiceOldMap = new Map<Id, CO_Invoice_Header__c>();
     
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
    public static void beforeUpdate() {
        populatesAccountingSyncFields();
    }

    public static void afterUpdate() {
        addCOSalespersons();
    }

    private static void addCOSalespersons() {
        Set<Id> closedInvIdSet = new Set<Id>();
        for(CO_Invoice_Header__c inv : invoiceNewList) {
            if(inv.Invoice_Status__c != invoiceOldMap.get(inv.Id).Invoice_Status__c && inv.Invoice_Status__c == IntegrationUtility.CLOSED) {
                closedInvIdSet.add(inv.Id);
            }
        }
        if(!closedInvIdSet.isEmpty()) {
            if(System.isFuture() || System.isBatch()) {
                addCOSalespersonsOnCOInvoice(closedInvIdSet);
            } else {
                addCOSalespersonsOnCOInvoiceFuture(closedInvIdSet);
            }
        }
    }

    @future
    private static void addCOSalespersonsOnCOInvoiceFuture(Set<Id> coInvIdSet) {
        addCOSalespersonsOnCOInvoice(coInvIdSet);
    }

    public static void addCOSalespersonsOnCOInvoice(Set<Id> coInvIdSet) {
        if(coInvIdSet != null && !coInvIdSet.isEmpty()) {
            Map<Id, Set<Id>> merchHeaderIdToInvIdSetMap = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> dealMerchHeaderIdToInvIdSetMap = new Map<Id, Set<Id>>();
            Map<Id, Id> dealIdToInvIdMap = new Map<Id, Id>();
            Map<Id, Set<Id>> soIdToInvIdSetMap = new Map<Id, Set<Id>>();

            DMLUtility.deleteSobjectList('CO_Salesperson__c', [Select Id FROM CO_Salesperson__c WHERE CO_Invoice_Header__c != null AND CO_Invoice_Header__c IN: coInvIdSet]);
            
            for(CO_Invoice_Item__c invItemRec : [Select Id, CO_Invoice_Header__c, CO_Line_Item__r.CO_Header__c, CO_Kit_Header__r.CO_Header__c, 
            CO_Line_Item__r.Deal__c, CO_Kit_Header__r.Deal__c, 
            Service_Order_Header__c, Deal__c, SO_Payment_Role__c FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN: coInvIdSet]) {
                if((invItemRec.CO_Line_Item__c != null || invItemRec.CO_Kit_Header__c != null)) {
                    Id coId = invItemRec.CO_Line_Item__c != null ? invItemRec.CO_Line_Item__r.CO_Header__c : invItemRec.CO_Kit_Header__r.CO_Header__c;
                    if(((invItemRec.CO_Line_Item__c != null && invItemRec.CO_Line_Item__r.Deal__c != null) || 
                    (invItemRec.CO_Kit_Header__c != null && invItemRec.CO_Kit_Header__r.Deal__c != null))) {
                        if(!dealMerchHeaderIdToInvIdSetMap.containsKey(coId)) {
                            dealMerchHeaderIdToInvIdSetMap.put(coId, new Set<Id>());
                        }
                        dealMerchHeaderIdToInvIdSetMap.get(coId).add(invItemRec.CO_Invoice_Header__c);
                    } else {
                        if(!merchHeaderIdToInvIdSetMap.containsKey(coId)) {
                            merchHeaderIdToInvIdSetMap.put(coId, new Set<Id>());
                        }
                        merchHeaderIdToInvIdSetMap.get(coId).add(invItemRec.CO_Invoice_Header__c);
                    }
                } else if(invItemRec.Deal__c != null) {
                    dealIdToInvIdMap.put(invItemRec.Deal__c, invItemRec.CO_Invoice_Header__c);
                } else if(invItemRec.Service_Order_Header__c != null) {
                    if(!soIdToInvIdSetMap.containsKey(invItemRec.Service_Order_Header__c)) {
                        soIdToInvIdSetMap.put(invItemRec.Service_Order_Header__c, new Set<Id>());
                    }
                    soIdToInvIdSetMap.get(invItemRec.Service_Order_Header__c).add(invItemRec.CO_Invoice_Header__c);
                }
            }

            Map<Id, Set<Id>> invIdToTechIdSetMap = new Map<Id, Set<Id>>();
            for(CO_Salesperson__c spRec : [Select Id, Technician__c, CO_Header__c, Deal__c, Service_Order_Header__c FROM CO_Salesperson__c 
            WHERE (CO_Header__c IN: merchHeaderIdToInvIdSetMap.keyset() OR CO_Header__c IN: dealMerchHeaderIdToInvIdSetMap.keyset() OR 
            Deal__c IN: dealIdToInvIdMap.keyset() OR Service_Order_Header__c IN: soIdToInvIdSetMap.keyset()) AND Technician__c != null]) {
                Set<Id> invIdSet = new Set<Id>(); 
                if(spRec.CO_Header__c != null) {
                    if(spRec.Deal__c != null && dealMerchHeaderIdToInvIdSetMap.get(spRec.CO_Header__c) != null) {
                        invIdSet.addAll(dealMerchHeaderIdToInvIdSetMap.get(spRec.CO_Header__c));
                    }
                    if(spRec.Deal__c == null && merchHeaderIdToInvIdSetMap.get(spRec.CO_Header__c) != null) {
                        invIdSet.addAll(merchHeaderIdToInvIdSetMap.get(spRec.CO_Header__c));
                    }
                }
                if(spRec.Deal__c != null && spRec.CO_Header__c == null && dealIdToInvIdMap.get(spRec.Deal__c) != null) {
                    invIdSet.add(dealIdToInvIdMap.get(spRec.Deal__c));
                }
                if(spRec.Service_Order_Header__c != null && soIdToInvIdSetMap.get(spRec.Service_Order_Header__c) != null) {
                    invIdSet.addAll(soIdToInvIdSetMap.get(spRec.Service_Order_Header__c));
                }
                for(Id invId : invIdSet) {
                    if(!invIdToTechIdSetMap.containsKey(invId)) {
                        invIdToTechIdSetMap.put(invId, new Set<Id>{spRec.Technician__c});
                    } else {
                        invIdToTechIdSetMap.get(invId).add(spRec.Technician__c);
                    }
                }
            }
            List<CO_Salesperson__c> coSalespersonInsertList = new List<CO_Salesperson__c>();
            for(Id invId : invIdToTechIdSetMap.keySet()) {
                for(Id techId : invIdToTechIdSetMap.get(invId)) {
                    coSalespersonInsertList.add(new CO_Salesperson__c(CO_Invoice_Header__c = invId, Technician__c = techId));
                }
            }
            DMLUtility.insertSobjectList('CO_Salesperson__c', coSalespersonInsertList);
        }
    }
    
    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.manageCOInvoiceSyncFlag(invoiceNewList,invoiceOldMap);
        
        if(BRPUtility.isBRPEnabled()) {
        	BRPSyncFlagService.manageCOInvoiceSyncFlag(invoiceNewMap, invoiceOldMap);
        }
    }
    
    public static void setCOInvoiceDataForAccountSync() {
        Set<Id> coInvIdSetForPartsInvoice = new Set<Id>();
    	Set<Id> coInvIdSetForRepairOrder = new Set<Id>();
    	Set<Id> coInvIdSetForRDR = new Set<Id>();
        Set<Id> coInvIdSetForRetailTransactions = new Set<Id>();


        IntegrationSyncFlagService.checkAndInitiateSyncBatch(invoiceNewList, IntegrationUtility.INVOICE);
        
        if(BRPUtility.isBRPEnabled()) {
            for(CO_Invoice_Header__c COInvoice : invoiceNewList) {
            	if(COInvoice.Available_For_BRP_Parts_Invoice_Sync__c) {
        			coInvIdSetForPartsInvoice.add(COInvoice.Id);
        		}
        		if(COInvoice.Available_For_BRP_Repair_Order_Sync__c) {
        			coInvIdSetForRepairOrder.add(COInvoice.Id);
        		}
        		if(COInvoice.Available_For_BRP_RDR_Sync__c) {
        			coInvIdSetForRDR.add(COInvoice.Id);
        		}
                if(COInvoice.Available_For_Retail_Transactions_Sync__c) {
                    coInvIdSetForRetailTransactions.add(COInvoice.Id);
	        }
        }
        }
        
        
        if(coInvIdSetForPartsInvoice.size() > 0) {
    		BRPUtility.initiateBatch(coInvIdSetForPartsInvoice, 'Parts Invoice', null);
    	}
    	if(coInvIdSetForRepairOrder.size() > 0) {
    		BRPUtility.initiateBatch(coInvIdSetForRepairOrder, 'Repair Order', null);
    	}
    	if(coInvIdSetForRDR.size() > 0) {
    		BRPUtility.initiateBatch(coInvIdSetForRDR, 'Retail Delivery Reporting', null);
    	}
        if(coInvIdSetForRetailTransactions.size() > 0) {
    		BRPUtility.initiateBatch(coInvIdSetForRetailTransactions, BRPUtility.RETAIL_TRANSACTIONS, null);
    	}
    }
}
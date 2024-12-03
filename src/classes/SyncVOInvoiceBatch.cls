global without sharing class SyncVOInvoiceBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Vendor_Invoicing_Header__c', new List<String>(AccountingVendorInvoice.objectToFieldMap.get('VIHeader')), 
                                                IntegrationUtility.VO_INVOICE));                                        
    }
    
    global void execute(Database.batchableContext bc, List<Vendor_Invoicing_Header__c> voInvoiceList) {
        Set<Id> vendorInvoiceIdSet = new Set<Id>();
        for(Vendor_Invoicing_Header__c vendorInvoiceRec : voInvoiceList) {
        	vendorInvoiceIdSet.add(vendorInvoiceRec.Id);
        }
        
    	List<Vendor_Invoicing_Group__c> viGroupsList = AccountingUtil.getVIGroupsListByVIHeaderId(vendorInvoiceIdSet);
    	List<Other_Charges__c> otherChargesList = AccountingUtil.getOtherChargesListByVIHeaderId(vendorInvoiceIdSet);
    	List<Part_FIFO_Bucket__c> PartFIFOBucketList = AccountingUtil.getPartFifoBucketListByVIHeaderId(vendorInvoiceIdSet);
    	
    	Map<Id, List<Vendor_Invoicing_Group__c>> viHeaderIdToVIGroupsListMap = new Map<Id, List<Vendor_Invoicing_Group__c>>();
    	Map<Id, List<Other_Charges__c>> viHeaderIdToOtherChargesListMap = new Map<Id, List<Other_Charges__c>>();
    	Map<Id, List<Part_FIFO_Bucket__c>> viHeaderIdPartFifoBucketListMap = new Map<Id, List<Part_FIFO_Bucket__c>>();
    	
    	for(Vendor_Invoicing_Group__c viGroupRec : viGroupsList) {
    		if(!viHeaderIdToVIGroupsListMap.containsKey(viGroupRec.Vendor_Invoicing_Header__c)) {
    			viHeaderIdToVIGroupsListMap.put(viGroupRec.Vendor_Invoicing_Header__c, new List<Vendor_Invoicing_Group__c>());
    		}
    		viHeaderIdToVIGroupsListMap.get(viGroupRec.Vendor_Invoicing_Header__c).add(viGroupRec);
    	}
    	
    	for(Other_Charges__c otherChargeRec : otherChargesList) {
    		if(!viHeaderIdToOtherChargesListMap.containsKey(otherChargeRec.Vendor_Invoicing_Header__c)) {
    			viHeaderIdToOtherChargesListMap.put(otherChargeRec.Vendor_Invoicing_Header__c, new List<Other_Charges__c>());
    		}
    		viHeaderIdToOtherChargesListMap.get(otherChargeRec.Vendor_Invoicing_Header__c).add(otherChargeRec);
    	}
    	
    	for(Part_FIFO_Bucket__c partFifoBucketRec : PartFIFOBucketList) {
    		if(!viHeaderIdPartFifoBucketListMap.containsKey(partFifoBucketRec.Vendor_Invoicing_Header__c)) {
    			viHeaderIdPartFifoBucketListMap.put(partFifoBucketRec.Vendor_Invoicing_Header__c, new List<Part_FIFO_Bucket__c>());
    		}
    		viHeaderIdPartFifoBucketListMap.get(partFifoBucketRec.Vendor_Invoicing_Header__c).add(partFifoBucketRec);
    	}
        for(Vendor_Invoicing_Header__c vendorInvoice : voInvoiceList) {
            String accId = String.valueOf(vendorInvoice.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.VO_INVOICE).Integration_Id_API_Name__c));
		   
			String integrationEntityName = (activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) ? IntegrationUtility.BILL : IntegrationUtility.INVOICE;
           
            if(vendorInvoice.Total_With_Tax__c != null && vendorInvoice.Total_With_Tax__c < 0) {
            	integrationEntityName = (activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) ? IntegrationUtility.VENDOR_CREDIT : IntegrationUtility.CREDIT_NOTE;
			}
				
			Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{integrationEntityName => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingVendorInvoice>{new AccountingVendorInvoice(vendorInvoice, 
                                (viHeaderIdToVIGroupsListMap.containsKey(vendorInvoice.Id) ? viHeaderIdToVIGroupsListMap.get(vendorInvoice.Id) : new List<Vendor_Invoicing_Group__c>()), 
                                (viHeaderIdPartFifoBucketListMap.containsKey(vendorInvoice.Id) ? viHeaderIdPartFifoBucketListMap.get(vendorInvoice.Id) : new List<Part_FIFO_Bucket__c>()), 
                                (viHeaderIdToOtherChargesListMap.containsKey(vendorInvoice.Id) ? viHeaderIdToOtherChargesListMap.get(vendorInvoice.Id) : new List<Other_Charges__c>()))}, 
                                (List<SObject>) sobjctListToUpdate, IntegrationUtility.VO_INVOICE, integrationEntityNameToActionMap);
        }
    }
    
    global override void finish(Database.batchableContext bc){
    	syncVOInvoiceJE(idSet);
        finishAction();
    }

	private static void syncVOInvoiceJE(Set<Id> viHeaderIdSet) {
		if(!viHeaderIdSet.isEmpty()) {
			List<Vendor_Invoicing_Header__c> viHeaderList = [SELECT Id, Available_For_QB_Variance_JE_Sync__c, Available_For_Xero_Variance_JE_Sync__c FROM Vendor_Invoicing_Header__c WHERE Id IN: viHeaderIdSet];
			IntegrationSyncFlagService.checkAndInitiateSyncBatch(viHeaderList, IntegrationUtility.VO_INVOICE_VARIANCE_JE);
        }
    }
}
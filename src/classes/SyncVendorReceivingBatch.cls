global without sharing class SyncVendorReceivingBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, List<String>> childObjectAPINameToFieldsList = new Map<String, List<String>>();
        return Database.getQueryLocator(getBaseQuery('Vendor_Receiving_Header__c', new List<String>(AccountingVendorReceiving.objectToFieldMap.get('VORHeader')), IntegrationUtility.VENDOR_RECEIVING, childObjectAPINameToFieldsList));
    }

    global void execute(Database.batchableContext bc, List<Vendor_Receiving_Header__c> listVendorReceivingHeaders) {
    	Set<Id> vendorReceivingIdSet = new Set<Id>();
        for(Vendor_Receiving_Header__c vendorReceivingRec : listVendorReceivingHeaders) {
        	vendorReceivingIdSet.add(vendorReceivingRec.Id);
        }
        
    	List<Vendor_Receiving_Group__c> vorGroupsList = AccSync_VORJournalEntry_Batch.getVORGroupsListByVORHeaderId(vendorReceivingIdSet);
    	
    	Map<Id, List<Vendor_Receiving_Group__c>> vorHeaderIdToVORGroupsListMap = new Map<Id, List<Vendor_Receiving_Group__c>>();
        for(Vendor_Receiving_Group__c vorGroupRec : vorGroupsList) {
    		if(!vorHeaderIdToVORGroupsListMap.containsKey(vorGroupRec.Vendor_Receiving_Header__c)) {
    			vorHeaderIdToVORGroupsListMap.put(vorGroupRec.Vendor_Receiving_Header__c, new List<Vendor_Receiving_Group__c>());
    		}
    		vorHeaderIdToVORGroupsListMap.get(vorGroupRec.Vendor_Receiving_Header__c).add(vorGroupRec);
    	}
    	
        for(Vendor_Receiving_Header__c vendorReceivingHeader : listVendorReceivingHeaders) {
        	String accId = String.valueOf(vendorReceivingHeader.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR_RECEIVING).Integration_Id_API_Name__c));
    		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
        	this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingVendorReceiving>{new AccountingVendorReceiving(vendorReceivingHeader, 
        			(vorHeaderIdToVORGroupsListMap.containsKey(vendorReceivingHeader.Id) ? vorHeaderIdToVORGroupsListMap.get(vendorReceivingHeader.Id) : 
								new List<Vendor_Receiving_Group__c>()))}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.VENDOR_RECEIVING, integrationEntityNameToActionMap);
        }
    }
 
    global override void finish(Database.batchableContext bc) {
        finishAction();
    }
}
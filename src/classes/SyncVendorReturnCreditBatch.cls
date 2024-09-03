global without sharing class SyncVendorReturnCreditBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, List<String>> childObjectAPINameToFieldsListMap = new Map<String, List<String>>();
        childObjectAPINameToFieldsListMap.put('Return_CR_Line_Items__r', new List<String>(AccountingVendorReturn.getReturnCRLIFieldList()));
        childObjectAPINameToFieldsListMap.put('Other_Charges__r', new List<String>(AccountingVendorInvoice.objectToFieldMap.get('OtherCharges')));
        return Database.getQueryLocator(getBaseQuery('Return_CR_Header__c', new List<String>(AccountingVendorReturn.getReturnCRFieldList()), 
                                                IntegrationUtility.VO_RETURN, childObjectAPINameToFieldsListMap));
    }
    
    global void execute(Database.batchableContext bc, List<Return_CR_Header__c> voReturnList) {
        String integrationEntityName;
        for(Return_CR_Header__c vendorReturn: voReturnList) {
            String accId = String.valueOf(vendorReturn.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.VO_RETURN).Integration_Id_API_Name__c));
            if(vendorReturn.Total_With_Tax__c != null && vendorReturn.Total_With_Tax__c < 0) {
                if(QBUtil.isQBEnabled()) integrationEntityName = IntegrationUtility.BILL;
                else integrationEntityName = IntegrationUtility.INVOICE;
            } else {
                if(QBUtil.isQBEnabled()) integrationEntityName = IntegrationUtility.VENDOR_CREDIT;
                else integrationEntityName = IntegrationUtility.CREDIT_NOTE;
            }
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{integrationEntityName => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingVendorReturn>{new AccountingVendorReturn(vendorReturn, null)}, (List<SObject>) sobjctListToUpdate, 
                                        IntegrationUtility.VO_RETURN, integrationEntityNameToActionMap);
        }
    }
    
    global override void finish(Database.batchableContext bc) {
        syncVOReturnJE(idSet);
        finishAction();
    }

    private static void syncVOReturnJE(Set<Id> rcrIdSet) {
		if(!rcrIdSet.isEmpty()) {
			List<Return_CR_Header__c> rcrList = [SELECT Id, Available_For_QB_Variance_JE_Sync__c, Available_For_Xero_Variance_JE_Sync__c FROM Return_CR_Header__c WHERE Id IN: rcrIdSet];
			IntegrationSyncFlagService.checkAndInitiateSyncBatch(rcrList, IntegrationUtility.VO_RETURN_VARIANCE_JE);
        }
    }
}
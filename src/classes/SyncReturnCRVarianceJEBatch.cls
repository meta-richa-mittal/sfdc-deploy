/**
 * Author: Richa Mittal
 * Since: Dec 18, 2023
 * Name: SyncReturnCRVarianceJEBatch
**/
global without sharing class SyncReturnCRVarianceJEBatch extends BaseSyncingBatch {
	
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, List<String>> childObjectAPINameToFieldsListMap = new Map<String, List<String>>();
        childObjectAPINameToFieldsListMap.put('Return_CR_Line_Items__r', new List<String>(AccountingVendorReturn.getReturnCRLIFieldList()));
        return Database.getQueryLocator(getBaseQuery('Return_CR_Header__c', new List<String>(AccountingVendorReturn.getReturnCRFieldList()), 
                                                IntegrationUtility.VO_RETURN_VARIANCE_JE, childObjectAPINameToFieldsListMap));
    }
    
    global void execute(Database.batchableContext bc, List<Return_CR_Header__c> voReturnList) {
        Set<Id> rcrHeaderIdSet = new Set<Id>();
        for(Return_CR_Header__c rcrRec: voReturnList) {
        	rcrHeaderIdSet.add(rcrRec.Id);
        }
        Map<String, List<Return_VO_Line_Item__c>> rcrIdToRVOLIListMap = AccountingUtil.getRCRIdToRVOLIListMap(rcrHeaderIdSet);
        for(Return_CR_Header__c vendorReturn : voReturnList) {
            String accId = String.valueOf(vendorReturn.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.VO_RETURN_VARIANCE_JE).Integration_Id_API_Name__c));
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingVendorReturn>{new AccountingVendorReturn(vendorReturn, rcrIdToRVOLIListMap.get(vendorReturn.Id))}, (List<SObject>) sobjctListToUpdate, 
                                        IntegrationUtility.VO_RETURN_VARIANCE_JE, integrationEntityNameToActionMap);
        }
    }
  
    global override void finish(Database.batchableContext bc) {
        finishAction();
    }
}
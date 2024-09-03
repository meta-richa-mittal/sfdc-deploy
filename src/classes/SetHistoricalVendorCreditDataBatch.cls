/**
 * Author: Richa Mittal
 * Name: SetHistoricalVendorCreditDataBatch
**/
global without sharing class SetHistoricalVendorCreditDataBatch extends PostInstallScriptBaseBatch {

    global SetHistoricalVendorCreditDataBatch() {
        this.scriptName = 'executeSetHistoricalVendorCreditDataBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Submitted_Date__c, Status__c, LastModifiedBy.Id, Credited_Date__c, Credit_Memo__c, ' + 
                            'AccountingId__c, accountingLastSyncTime__c, Accounting_Last_Sync_Time_Variance_JE__c, ' + 
                            'AccountingResponse__c, Accounting_Response_Variance_JE__c, Available_For_QB_Variance_JE_Sync__c, ' +
                            'Available_For_Xero_Sync__c, Available_For_Xero_Variance_JE_Sync__c, availForQBSync__c, ' + 
                            'QB_Variance_JE_Accounting_Id__c, SyncToken__c, Sync_Token_For_Variance_JE__c, Xero_Accounting_Id__c, ' + 
                            'Xero_Variance_JE_Accounting_Id__c, Vendor__c, FX_Conversion_Rate__c ' +  
                            'FROM Return_VO_Header__c WHERE Status__c IN (\'Submitted\', \'Approved\', \'Credited\')';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> rvoList) {
        Map<String, Return_CR_Header__c> rvoIdToRCRRecMap = new Map<String, Return_CR_Header__c>();
        for(Return_VO_Header__c rvoRec: (List<Return_VO_Header__c>)rvoList) {
            if(rvoRec.Status__c == 'Submitted') {
                rvoRec.Submitted_By__c = rvoRec.LastModifiedBy.Id;
            } else if(rvoRec.Status__c == 'Approved' || rvoRec.Status__c == 'Credited') {
                rvoRec.Submitted_By__c = rvoRec.LastModifiedBy.Id;
                rvoRec.Approved_Date__c = rvoRec.Submitted_Date__c;
                rvoRec.Approved_By__c = rvoRec.LastModifiedBy.Id;
                if(rvoRec.Status__c == 'Credited') {
                    rvoIdToRCRRecMap.put(rvoRec.Id, createRCRFromRVO(rvoRec));
                    updateRVOAccountingFields(rvoRec);
                }
            }
        }
        DMLUtility.updateSobjectList('Return_VO_Header__c', rvoList);
        DMLUtility.insertSobjectList('Return_CR_Header__c', rvoIdToRCRRecMap.values());

        Map<String, Return_CR_Line_Item__c> rvoliIdToRCRLIRecMap = createRCRLIFromRVOLI(rvoIdToRCRRecMap);
        updateRCRLIValueOnRVOLI(rvoliIdToRCRLIRecMap);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Map<String, Return_CR_Line_Item__c> createRCRLIFromRVOLI(Map<String, Return_CR_Header__c> rvoIdToRCRRecMap) {
        Map<String, Return_VO_Header__c> rvoIdToRVORecWithRVOLIMap = new Map<String, Return_VO_Header__c>([SELECT Id, (SELECT Item__c, Description__c, 
                                            Item_Cost__c, Return_Qty__c, Part__c FROM Return_VO_Line_Items__r) FROM Return_VO_Header__c WHERE Id IN :rvoIdToRCRRecMap.keySet()]);

        Map<String, Return_CR_Line_Item__c> rvoliIdToRCRLIRecMap = new Map<String, Return_CR_Line_Item__c>();
        for(String rvoId: rvoIdToRVORecWithRVOLIMap.keySet()) {
            for(Return_VO_Line_Item__c rvoliRec: rvoIdToRVORecWithRVOLIMap.get(rvoId).Return_VO_Line_Items__r) {
                Return_CR_Line_Item__c rcrliRec = new Return_CR_Line_Item__c(Return_CR_Header__c = rvoIdToRCRRecMap.get(rvoId).Id);
                rcrliRec.Return_Cost__c = rcrliRec.Credit_Cost__c = rvoliRec.Item_Cost__c;
                rcrliRec.Return_Qty__c = rvoliRec.Return_Qty__c;
                rcrliRec.Part__c = rvoliRec.Part__c;
                rcrliRec.Item__c = rvoliRec.Item__c;
                rcrliRec.Description__c = rvoliRec.Description__c;
                rvoliIdToRCRLIRecMap.put(rvoliRec.Id, rcrliRec);
            }
        }
        DMLUtility.insertSobjectList('Return_CR_Line_Item__c', rvoliIdToRCRLIRecMap.values());
        return rvoliIdToRCRLIRecMap;
    }
    
    private static void updateRCRLIValueOnRVOLI(Map<String, Return_CR_Line_Item__c> rvoliIdToRCRLIRecMap) {
        List<Return_VO_Line_Item__c> rvoliListToUpdate = new List<Return_VO_Line_Item__c>();
        for(String rvoliId: rvoliIdToRCRLIRecMap.keySet()) {
            rvoliListToUpdate.add(new Return_VO_Line_Item__c(Id = rvoliId, Return_CR_Line_Item__c = rvoliIdToRCRLIRecMap.get(rvoliId).Id));
        }
        DMLUtility.updateSobjectList('Return_VO_Line_Item__c', rvoliListToUpdate);
    }

    private static void updateRVOAccountingFields(Return_VO_Header__c rvoRec) {
        rvoRec.AccountingId__c = null;
        rvoRec.Xero_Accounting_Id__c = null;
        rvoRec.QB_Variance_JE_Accounting_Id__c = null;
        rvoRec.Xero_Variance_JE_Accounting_Id__c = null;
        rvoRec.accountingLastSyncTime__c = null;
        rvoRec.Accounting_Last_Sync_Time_Variance_JE__c = null;
        rvoRec.availForQBSync__c = false;
        rvoRec.Available_For_Xero_Sync__c = false;
        rvoRec.Available_For_QB_Variance_JE_Sync__c = false;
        rvoRec.Available_For_Xero_Variance_JE_Sync__c = false;
        rvoRec.SyncToken__c = null;
        rvoRec.Sync_Token_For_Variance_JE__c = null;
        rvoRec.AccountingResponse__c = null;
        rvoRec.Accounting_Response_Variance_JE__c = null;
    }

    private static Return_CR_Header__c createRCRFromRVO(Return_VO_Header__c rvoRec) {
        Return_CR_Header__c rcrRec = new Return_CR_Header__c();
        rcrRec.Vendor__c = rvoRec.Vendor__c;
        rcrRec.Status__c = rvoRec.Status__c;
        rcrRec.Credited_Date__c = (rvoRec.Credited_Date__c != null) ? rvoRec.Credited_Date__c.date() : null;
        rcrRec.Credit_Memo__c = rvoRec.Credit_Memo__c;
        rcrRec.FX_Conversion_Rate__c = rvoRec.FX_Conversion_Rate__c;
        rcrRec.Accounting_Id__c = rvoRec.AccountingId__c;
        rcrRec.Xero_Accounting_Id__c = rvoRec.Xero_Accounting_Id__c;
        rcrRec.QB_Variance_JE_Accounting_Id__c = rvoRec.QB_Variance_JE_Accounting_Id__c;
        rcrRec.Xero_Variance_JE_Accounting_Id__c = rvoRec.Xero_Variance_JE_Accounting_Id__c;
        rcrRec.Accounting_Last_Sync_Time__c = rvoRec.accountingLastSyncTime__c;
        rcrRec.Accounting_Last_Sync_Time_Variance_JE__c = rvoRec.Accounting_Last_Sync_Time_Variance_JE__c;
        rcrRec.Available_For_QB_Sync__c = rvoRec.availForQBSync__c;
        rcrRec.Available_For_Xero_Sync__c = rvoRec.Available_For_Xero_Sync__c;
        rcrRec.Available_For_QB_Variance_JE_Sync__c = rvoRec.Available_For_QB_Variance_JE_Sync__c;
        rcrRec.Available_For_Xero_Variance_JE_Sync__c = rvoRec.Available_For_Xero_Variance_JE_Sync__c;
        rcrRec.Sync_Token__c = rvoRec.SyncToken__c;
        rcrRec.Sync_Token_For_Variance_JE__c = rvoRec.Sync_Token_For_Variance_JE__c;
        rcrRec.Accounting_Response__c = rvoRec.AccountingResponse__c;
        rcrRec.Accounting_Response_Variance_JE__c = rvoRec.Accounting_Response_Variance_JE__c;
        return rcrRec;
    }
}
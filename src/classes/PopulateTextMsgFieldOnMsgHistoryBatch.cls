global without sharing class PopulateTextMsgFieldOnMsgHistoryBatch extends PostInstallScriptBaseBatch  {
    global PopulateTextMsgFieldOnMsgHistoryBatch() {
        this.scriptName = 'executePopulateTextMsgFieldOnMsgHistoryBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Text__c FROM Message_History__c Where Text__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> msgHistoryList) {
        for(Message_History__c msgHistoryRec: (List<Message_History__c>)msgHistoryList) {
            msgHistoryRec.SMS_Body__c = msgHistoryRec.Text__c;
        }
        DMLUtility.updateSobjectList('Message_History__c', msgHistoryList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
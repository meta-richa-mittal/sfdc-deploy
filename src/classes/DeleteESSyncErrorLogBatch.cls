global without sharing class DeleteESSyncErrorLogBatch extends PostInstallScriptBaseBatch {
    global DeleteESSyncErrorLogBatch() {}
	global override Database.QueryLocator startScript(Database.BatchableContext bc) {return null;}
	global override void executeScript(Database.BatchableContext bc, List<SObject> syncErrorLogList) {}
    global override void finishScript(Database.BatchableContext bc) {}
}
/**
 * Author: Richa Mittal
 * Since: March 09, 2022
 * Name: PostInstallScriptBaseBatch
 * Description: Parent batch class for all batch scripts
**/
global without sharing abstract class PostInstallScriptBaseBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    private boolean isBatchFailed = false;
    public String scriptName;
    private Post_Install_Log__c logRec;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            if(String.isNotBlank(scriptName)) {
                List<Post_Install_Log__c> logList = [SELECT Id FROM Post_Install_Log__c WHERE Script_Name__c = :scriptName AND Status__c != 'Completed' Order by CreatedDate DESC LIMIT 1];
                if(logList.size() > 0) {
                    logRec = logList[0];
                    return startScript(bc);
                }
                throw new BlackPurlException('Log record not created for ' + scriptName);
            }
            throw new BlackPurlException('Script name is not set in batch class');
        } catch(Exception e) {
            isBatchFailed = true;
            logRec = PostInstallScriptUtil.upsertLog(logRec, scriptName, e.getMessage(), e.getStackTraceString(), 'Errored', 'start()', false);
            return Database.getQueryLocator('select name from apexClass limit 0');
        }
    }


    global void execute(Database.BatchableContext bc, List<sObject> sObjects) {
        if(!isBatchFailed) {
            try {
                executeScript(bc, sObjects);
            } catch(Exception e) {
                isBatchFailed = true;
                logRec = PostInstallScriptUtil.upsertLog(logRec, scriptName, e.getMessage(), e.getStackTraceString(), 'Errored', 'execute()', false);
            }
        }
    }


    global void finish(Database.BatchableContext bc) {
        try {
            finishScript(bc);
            if(!isBatchFailed) {
                logRec = PostInstallScriptUtil.upsertLog(logRec, scriptName, null, null, 'Completed', null, true);
            } else {
                logRec = PostInstallScriptUtil.upsertLog(logRec, logRec.Script_Name__c, logRec.Error_Message__c, logRec.Stack_Trace__c, 'Errored', logRec.Method_Name__c, true);
            }
        } catch(Exception e) {
            logRec = PostInstallScriptUtil.upsertLog(logRec, scriptName, e.getMessage(), e.getStackTraceString(), 'Errored', 'finish()', true);
        }
    }

    /**
     * below must be implemented by implementation
     */
    global abstract Database.QueryLocator startScript(Database.BatchableContext bc);
    global abstract void executeScript(Database.BatchableContext bc, List<SObject> sObjects);
    global abstract void finishScript(Database.BatchableContext bc);
}
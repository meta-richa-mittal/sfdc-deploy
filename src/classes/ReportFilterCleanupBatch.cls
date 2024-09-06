/**
 * Author: Nidhi Sharma
 * Since: 26 August, 2024
 * Name: ReportFilterCleanupBatch
 * Description: Batch for cleaning up filter records
**/
global without sharing class ReportFilterCleanupBatch extends PostInstallScriptBaseBatch {

    global ReportFilterCleanupBatch() {
        this.scriptName = 'executeReportFilterCleanupBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        return Database.getQueryLocator([Select Id from Filter__c where Common__c = true OR Reconciliation__c = TRUE OR Filter_Label__c = :CommonFiltersService.RECENT_RECORDS]);
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> filterList) {
        DMLUtility.deleteSobjectList('Filter__c', filterList);
    }

    global override void finishScript(Database.BatchableContext bc) {
        ConfigurationScript.createUserDependentFeature();
    }

}
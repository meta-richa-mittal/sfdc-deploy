/**
 * Author: Manoj Sharma
 * Since: Aug 07, 2023
 * Name: DeleteCOFormAttachmentsBatch
 * Description: Batch to delete attachment from the co form object records.
**/
global without sharing class DeleteCOFormAttachmentsBatch extends PostInstallScriptBaseBatch {
    global DeleteCOFormAttachmentsBatch() {
        this.scriptName = 'executeDeleteCOFormAttachmentsBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, ParentId FROM Attachment';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> attachmentList) {
        List<Attachment> attachmentListToDelete = new List<Attachment>();
        String parentApiName;
        for(Attachment attachmentRec : (List<Attachment>)attachmentList) {
            parentApiName = Id.valueOf(attachmentRec.ParentId).getSObjectType().getDescribe().getName();
            if(parentApiName == CONSTANTS.NAMESPACE + 'CO_Form__c') { 
                attachmentListToDelete.add(attachmentRec);
            }
        }
        DMLUtility.deleteSobjectList('Attachment', attachmentListToDelete);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
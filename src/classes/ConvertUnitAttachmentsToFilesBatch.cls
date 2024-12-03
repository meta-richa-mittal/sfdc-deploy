/** Author: Nidhi Sharma
 * Since: July 16, 2024
 * Name: ConvertUnitAttachmentsToFilesBatch
 * Description: 
**/
global without sharing class ConvertUnitAttachmentsToFilesBatch extends PostInstallScriptBaseBatch {

    global ConvertUnitAttachmentsToFilesBatch() {
        this.scriptName = 'executeConvertUnitAttachmentsToFilesBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Is_Primary__c, Image_Uploaded_At__c, Unit__c FROM Document__c WHERE Unit__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> docList) {
        if(docList.size()> 1) throw new BlackPurlException('Kindly run the batch with size 1');

        Document__c docRec = (Document__c)docList[0];
        List<Attachment> attList = [SELECT Body, Name FROM Attachment WHERE ParentId =: docRec.Id];
        List<ContentVersion> cvList = new List<ContentVersion>();
        Map<String, String> uniqueIdToUnitIdMap = new Map<String, String>();
        for(Attachment att: attList) {
            String docName = att.Name + '_' + att.Id;
            cvList.add(new ContentVersion(
                Title = docName,
                PathOnClient = att.Name,
                VersionData = att.Body,
                Is_Primary__c = docRec.Is_Primary__c,
                Image_Uploaded_At__c = docRec.Image_Uploaded_At__c,
                ContentLocation = 'S'
            ));
            uniqueIdToUnitIdMap.put(docName, docRec.Unit__c);
        }
        DMLUtility.insertSobjectList('ContentVersion', cvList);

        List<ContentDocumentLink> cvlList = new List<ContentDocumentLink>();
        List<ContentDistribution> cdList = new List<ContentDistribution>();
        // Get content document id created by inserting ContentVersion record
        for(ContentVersion contentVerRec: [SELECT ContentDocumentId, Title FROM ContentVersion WHERE Id IN :cvList]) {
            cvlList.add(new ContentDocumentLink(
                ContentDocumentId = contentVerRec.ContentDocumentId,
                LinkedEntityId = uniqueIdToUnitIdMap.get(contentVerRec.Title),
                ShareType = 'V'
            ));

            cdList.add(new ContentDistribution(
                Name = contentVerRec.Title,
                ContentVersionId = contentVerRec.Id,
                PreferencesAllowViewInBrowser = true,
                PreferencesNotifyOnVisit = false
            ));
        }
        DMLUtility.insertSobjectList('ContentDocumentLink', cvlList);
        DMLUtility.insertSobjectList('ContentDistribution', cdList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}
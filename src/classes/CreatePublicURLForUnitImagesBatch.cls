/** 
* Author: Richa Mittal
* Since: Dec 12, 2019
* Name: UpdateSupersessionFieldsOnPartBatch 
* Description: Batch class to update Supersession Fields on Part record
**/
global without sharing class CreatePublicURLForUnitImagesBatch implements Database.Batchable<sobject>, Database.Stateful {
	public String folderId;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        folderId = ViewUnitCtrl.getFolderIdForDocuments();
        String objectName = Constants.Namespace + 'Document__c';
        String strQuery = 'SELECT Id, ParentId, Name, Body ' + 
                            'FROM Attachment WHERE Parent.Type = :objectName';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Attachment> attachmentList) {
    	if(folderId != null && GeneralConfiguration.isImagePublicURLCreationEnabled()) {
    		Map<String, Attachment> parentDocIdToAttachmentMap = new Map<String, Attachment>();
    		for(Attachment attachmentRec: attachmentList) {
    			parentDocIdToAttachmentMap.put(attachmentRec.ParentId, attachmentRec);
	        }
    		List<Document__c> parentDocumentList = [SELECT Id, Public_Image_URL__c FROM Document__c WHERE Id IN: parentDocIdToAttachmentMap.keySet()];
    		
    		Map<String, Document> parentDocIdToDocumentMap = new Map<String, Document>();
	        for(Document__c documentRec: parentDocumentList) {
	        	if(String.isBlank(documentRec.Public_Image_URL__c)) {
	        		parentDocIdToDocumentMap.put(documentRec.Id, ViewUnitCtrl.createPublicDocumentForImage(parentDocIdToAttachmentMap.get(documentRec.Id).Body, parentDocIdToAttachmentMap.get(documentRec.Id).Name, folderId));
	        	}
	        }
	        
	        if(parentDocIdToDocumentMap.size() > 0) {
	    		insert parentDocIdToDocumentMap.values();
	    	}
	    	
	    	List<Document__c> parentDocumentListToUpdate = new List<Document__c>();
	    	for(String parentDocId: parentDocIdToDocumentMap.keySet()) {
	    		parentDocumentListToUpdate.add(new Document__c(Id = parentDocId, Public_Image_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=' + parentDocIdToDocumentMap.get(parentDocId).Id + '&oid=' + UserInfo.getOrganizationId()));
	    	}
	    	update parentDocumentListToUpdate;
    	}
    }
    
    global void finish(Database.batchableContext bc) {}
}
public without sharing class Unit_Service {

    public static void populateNotesByModelSubmodelDesc(Customer_Owned_Unit__c unitRec) {
        if(String.isNotBlank(unitRec.Sub_Model__c)) {
            List<Unit_Sub_Model__c> subModelList = [SELECT Description__c, Unit_Model__r.Description__c FROM Unit_Sub_Model__c WHERE Id =: unitRec.Sub_Model__c AND Unit_Model__c =: unitRec.Unit_Model__c];
            if(subModelList.size() > 0 && string.isNotBlank(subModelList[0].Description__c)) {
                unitRec.Notes__c = subModelList[0].Description__c;
            } else if(subModelList.size() > 0 && string.isNotBlank(subModelList[0].Unit_Model__r.Description__c)) {
                    unitRec.Notes__c = subModelList[0].Unit_Model__r.Description__c;
            }
        } else if(String.isNotBlank(unitRec.Unit_Model__c)) {
            List<Unit_Model__c> modelList = [SELECT Description__c FROM Unit_Model__c WHERE Id =: unitRec.Unit_Model__c AND Unit_Make__c =: unitRec.Unit_Make__c];
            if(modelList.size() > 0 && string.isNotBlank(modelList[0].Description__c)) {
                unitRec.Notes__c = modelList[0].Description__c;
            }
        }
    }

    @future
    public static void copyUnitImages(Map<Id, Id> sourceIdToTargetIdMap) {
        String folderId = ViewUnitCtrl.getFolderIdForDocuments();
        boolean isImagePublicURLCreationEnabled = GeneralConfiguration.isImagePublicURLCreationEnabled();

        List<ContentDocumentLink> contentDocLinkList = [Select ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :sourceIdToTargetIdMap.keySet()];
        if(contentDocLinkList.isEmpty()) return;

        List<ContentDocumentLink> contentDocLinkInsertList = new List<ContentDocumentLink>();
        for (ContentDocumentLink contentDocLinkRec: contentDocLinkList) {
            ContentDocumentLink newContentDocLinkRec = contentDocLinkRec.clone(false, true);
            newContentDocLinkRec.LinkedEntityId = sourceIdToTargetIdMap.get(contentDocLinkRec.LinkedEntityId);
            contentDocLinkInsertList.add(newContentDocLinkRec);
        }
        DMLUtility.insertSobjectList('ContentDocumentLink', contentDocLinkInsertList);
    }

    public static Map<Id, Customer_Owned_Unit__c> getUnitIdToRecMap(Set<String> unitIds, List<String> unitPrimaryFields, List<String> optionalFields) {
        String query = 'SELECT ' + String.join(unitPrimaryFields, ', ');
        if(!optionalFields.isEmpty()) query += (', ' + String.join(optionalFields, ', '));
        query += ' FROM Customer_Owned_Unit__c WHERE Id IN: unitIds';
        return new Map<Id, Customer_Owned_Unit__c>((List<Customer_Owned_Unit__c>)Database.query(query));
    }

    public static List<String> UnitPrimaryFields = new List<String>{
        'VIN_Number__c', 'Unit_Id__c', 'Stock_Id__c', 'Unit_Type__c', 'Year__c', 'Unit_Make__r.Name', 'Unit_Model__r.Name__c', 
        'Unit_Model__r.Sub_Model__c', 'Sub_Model__r.Sub_Model_Name__c', 'Submodel__r.Name__c', 'Formatted_Name__c'
    };
}

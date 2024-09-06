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
}
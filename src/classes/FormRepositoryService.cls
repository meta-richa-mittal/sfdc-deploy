public without sharing class FormRepositoryService {
    
    public static Map<String, List<FormRepositoryWrapper>> getFormsListBasedOnType(String formType) {
        List<Form__c> formList = FormSOQLUtil.getFormListBasedOnType(formType);
        Map<String, List<FormRepositoryWrapper>> formRepositoryTypeToRecordListMap = new Map<String, List<FormRepositoryWrapper>>{
                                                                    'Deal' => new List<FormRepositoryWrapper>(),
                                                                    'Vendor product' => new List<FormRepositoryWrapper>(),
                                                                    'Financing' => new List<FormRepositoryWrapper>(), 
                                                                    'Service' => new List<FormRepositoryWrapper>()
                                                        };
        for(Form__c formRec: formList) {
            List<FormRepositoryWrapper> formObjList;
            if(formRepositoryTypeToRecordListMap.containsKey(formRec.Grouping_Name__c)) {
                formObjList = formRepositoryTypeToRecordListMap.get(formRec.Grouping_Name__c);
            }
            formObjList.add(new FormRepositoryWrapper(formRec));
            formRepositoryTypeToRecordListMap.put(formRec.Grouping_Name__c, formObjList);
        }
        return formRepositoryTypeToRecordListMap;
    }
    
    public static String activateForm(String formJson) {
        List<FormRepositoryWrapper> formRepositoryList = (List<FormRepositoryWrapper>) System.JSON.deserialize(formJson, List<FormRepositoryWrapper>.class);
        if(formRepositoryList.size() == 1 && !formRepositoryList[0].IsActive) {
            if(AccessControl.ifObjectFieldIsAccessible('Linked_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Linked_Form__c> linkedFormList = [SELECT id FROM Linked_Form__c WHERE Form__c =: formRepositoryList[0].Id];
            if(linkedFormList.size() > 0) {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Form_deselect_error_message')));
            }
        }
        List<Form__c> formRepositoryListToUpdate = new List<Form__c>();
        for(FormRepositoryWrapper formRepositoryRec: formRepositoryList) {
            Form__c formRec = new Form__c();
            formRec.Id = formRepositoryRec.Id;
            formRec.Is_Active__c = formRepositoryRec.IsActive;
            formRepositoryListToUpdate.add(formRec);
        }
        if(AccessControl.ifObjectFieldIsUpdateable('Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update formRepositoryListToUpdate;
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
    }
    
    public static String deleteForm(String formId) {
        if(AccessControl.ifObjectFieldIsAccessible('Linked_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Linked_Form__c> linkedFormList = [SELECT id FROM Linked_Form__c WHERE Form__c =: formId];
        if(linkedFormList.size() > 0) {
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Form_delete_error_message')));
        }
        
        Form__c formRec = new Form__c();
        formRec.Id = formId;
        if(AccessControl.ifObjectIsDeletable('Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete formRec;
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
    }
    
    public static String saveForm(String formJson) {
        FormRepositoryWrapper formRepositoryRec = (FormRepositoryWrapper) System.JSON.deserialize(formJson, FormRepositoryWrapper.class);
        if(String.isNotBlank(formRepositoryRec.Id)) {
            if(AccessControl.ifObjectFieldIsAccessible('Linked_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Linked_Form__c> linkedFormList = [SELECT Grouping_Name__c FROM Linked_Form__c WHERE Form__c =: formRepositoryRec.Id];
            if(linkedFormList.size() > 0 && formRepositoryRec.GroupingName != linkedFormList[0].Grouping_Name__c) {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Form_update_error_message')));
            }
        }
        
        Form__c formRec = new Form__c();
        formRec.Id = formRepositoryRec.Id;
        formRec.Is_Manual_Upload__c = true;
        formRec.Is_Active__c = true;
        formRec.Name = formRepositoryRec.FormName;
        formRec.Description__c = formRepositoryRec.Description;
        formRec.Grouping_Name__c = formRepositoryRec.GroupingName;
        if(AccessControl.ifObjectFieldIsUpdateable('Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        upsert formRec;
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', formRec.Id)));
    }

    public static List<FormRepositoryWrapper> getActiveFormsListBasedOnGroup(String groupingName) {
        List<Form__c> formList = FormSOQLUtil.getActiveFormsListBasedOnGroup(groupingName);
        List<FormRepositoryWrapper> formObjList = new List<FormRepositoryWrapper>();
        for(Form__c formRec: formList) {
            formObjList.add(new FormRepositoryWrapper(formRec));
        }
        return formObjList;
    }

    public static void deleteImagesForForm(String formId) { // delete already created images for the form with name in the format formId + '_%'
        String imageNamePrefix = formId + '%';
        DMLUtility.deleteSobjectList('Attachment', [SELECT Id FROM Attachment WHERE Name Like :imageNamePrefix AND ParentId = :formId]);
    }

    public static List<FormRepositoryWrapper> getActiveFormsList() {
        List<Form__c> formList = FormSOQLUtil.getFormListBasedOnType('Active');
        List<FormRepositoryWrapper> formObjList = new List<FormRepositoryWrapper>();
        for(Form__c formRec: formList) {
            formObjList.add(new FormRepositoryWrapper(formRec));
        }
        return formObjList;
    }

    public static String getUserDefinedFields(String formId) {
        if(String.isBlank(formId)) throw new BlackPurlException('Invalid form Id.');
        List<form__c> formList = [SELECT User_Defined_Fields_Config__c FROM Form__c WHERE Id =: formId];
        if(formList.isEmpty()) throw new BlackPurlException('Form not found.');
        return formList[0].User_Defined_Fields_Config__c;
    }

    public static void saveUserDefinedFields(String formId, String fieldsJson, String formEditConfigJson) {
        DMLUtility.updateSobjectList('Form__c', new Form__c(Id = formId, User_Defined_Fields_Config__c = fieldsJson, User_Defined_Fields_Form_Edit_Config__c = formEditConfigJson));
    }
}
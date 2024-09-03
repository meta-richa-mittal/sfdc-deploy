/**
 * Author: Reena Singh
 * Since: October 1, 2020
 * Name: MMSManagementCtrl
 * Description: Conroller class for make, model and sub-model page
**/
global without sharing class MMSManagementCtrl {
    global MMSManagementCtrl(NewHomePageCtrl controller) {}
    public MMSManagementCtrl(){}
    
    @remoteAction
    global static String getMakeList() {
        try {
           return BPUtility.getEncodedString(MakeModelSubModelService.getAllUnitMakes(true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getModelList() { return ''; }
    
    @RemoteAction
    global static String getSubModelList() { return ''; }
    
    @RemoteAction
    global static String getModelListByMakeId(String makeId) {
    	makeId = BPUtility.getDecodedString(makeId);
        return BPUtility.getEncodedString(MakeModelSubModelService.getModelListByMakeId(makeId));
    }
    
    @RemoteAction
    global static String getSubmodelListByModelId(String modelId) {
    	modelId = BPUtility.getDecodedString(modelId);
        return BPUtility.getEncodedString(MakeModelSubModelService.getSubmodelListByModelId(modelId));
    }
    
    @RemoteAction
    global static String saveMake(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.saveMake(jsonString));  
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String saveModel(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.saveModel(jsonString));  
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveSubModel(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.saveSubModel(jsonString));  
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getUnitCategoryList() {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitOrderingService.getUnitCategoryList()));
    }
    
    @RemoteAction
    global static String deleteMake(String makeId) {
        makeId = BPUtility.getDecodedString(makeId);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.deleteMake(makeId));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String deleteModel(String modelId) {
        modelId = BPUtility.getDecodedString(modelId);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.deleteModel(modelId));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String deleteSubModel(String subModelId) {
        subModelId = BPUtility.getDecodedString(subModelId);
        try {
            return BPUtility.getEncodedString(MakeModelSubModelService.deleteSubModel(subModelId));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
}
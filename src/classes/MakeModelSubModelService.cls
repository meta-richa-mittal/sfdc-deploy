public without sharing class MakeModelSubModelService {
	
    public static String getAllUnitMakes() {
        return getAllUnitMakes(false);
    }
    
    public static String getAllUnitModels() {
        return getAllUnitModels(false);
    }
    
    public static String getAllUnitSubModels() {
        return getAllUnitSubModels(false);
    }
    
	public static String getAllUnitMakes(Boolean shouldIncludeInactive) {
		List<MakeModelSubmodelWrapper> makeList = new List<MakeModelSubmodelWrapper>();
        for(Unit_Make__c unitMakeRec : Database.query(getQuery('Unit_Make__c', shouldIncludeInactive))) {
            makeList.add(new MakeModelSubmodelWrapper(unitMakeRec));
        }
        return system.JSON.serialize(makeList, true);
    }
    
    public static String getAllUnitModels(Boolean shouldIncludeInactive) {
		List<MakeModelSubmodelWrapper> modelList = new List<MakeModelSubmodelWrapper>();
        for(Unit_Model__c unitModelRec : Database.query(getQuery('Unit_Model__c', shouldIncludeInactive))) {
            modelList.add(new MakeModelSubmodelWrapper(unitModelRec));
        }
        return system.JSON.serialize(modelList, true);
    }
    
    public static String getAllUnitSubModels(Boolean shouldIncludeInactive) {
		List<MakeModelSubmodelWrapper> subModelList = new List<MakeModelSubmodelWrapper>();
        for(Unit_Sub_Model__c unitSubModelRec : Database.query(getQuery('Unit_Sub_Model__c', shouldIncludeInactive))) {
            subModelList.add(new MakeModelSubmodelWrapper(unitSubModelRec));
        }
        return system.JSON.serialize(subModelList, true);
    }
    
    public static String getMakeModelSubmodelList() {
        return system.JSON.serialize(new MakeModelSubModelListWrapper(Database.query(getQuery('Unit_Make__c')), 
                                                       Database.query(getQuery('Unit_Model__c')), Database.query(getQuery('Unit_Sub_Model__c'))), true);
    }
    
    private static Map<String, List<String>> objectAPINameToFieldListMap = 
        new Map<String, List<String>> {
            'Unit_Make__c' => new List<String>{'Name','Active__c'},
            'Unit_Model__c' => new List<String>{'Name__c', 'Unit_Make__c','Active__c','Description__c','Category__c', 'Category__r.Name'},
            'Unit_Sub_Model__c' => new List<String>{'Sub_Model_Name__c', 'Unit_Model__c','Active__c','Description__c','Category__c', 'Category__r.Name'}
        };
    
    private static Map<String, String> objectAPINameToOrderByFieldNameMap = new Map<String, String> {'Unit_Make__c'  => 'Name',
															                                           'Unit_Model__c' => 'Name__c',
															                                           'Unit_Sub_Model__c' => 'Sub_Model_Name__c'
                };
    
    public static String getQuery(String objectName) {
        return getQuery(objectName, false);
    }
    
    public static String getQuery(String objectName, Boolean shouldIncludeInactive) {
    	return getQuery(objectName, shouldIncludeInactive, null);
    }
    
    public static String getQuery(String objectName, Boolean shouldIncludeInactive, Map<String, String> fieldNameToValueMap) {
        if(!AccessControl.ifObjectFieldIsAccessible(objectName)) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT ' + String.join(objectAPINameToFieldListMap.get(objectName), ', ');
        query += ' FROM ' + BPUtility.escapeSingleQuotes(objectName) + ' WHERE ' + BPUtility.escapeSingleQuotes(objectAPINameToFieldListMap.get(objectName)[0]) + '!= null '; 
        query += (!shouldIncludeInactive) ? ' AND Active__c = true' : '';
        
        if(fieldNameToValueMap != null) {
	        for(String fieldName : fieldNameToValueMap.keySet()) {
	            query += ' AND ' + BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToValueMap.get(fieldName)) + '\'';
	        }
        }
        query += ' ORDER BY ' + objectAPINameToOrderByFieldNameMap.get(objectName) + ' ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return query;
    }
    
    public class MakeModelSubModelListWrapper {
        public List<MakeModelSubmodelWrapper> MakeList;
        public List<MakeModelSubmodelWrapper> ModelList;
        public List<MakeModelSubmodelWrapper> SubModelList;
        
        public MakeModelSubModelListWrapper(List<Unit_Make__c> makeRecList, List<Unit_Model__c> modelRecList, List<Unit_Sub_Model__c> subModelRecList) {
            this.MakeList = new List<MakeModelSubmodelWrapper>();
            this.ModelList = new List<MakeModelSubmodelWrapper>();
            this.SubModelList = new List<MakeModelSubmodelWrapper>();
            for(Unit_Make__c unitMakeRec : makeRecList) {
                MakeList.add(new MakeModelSubmodelWrapper(unitMakeRec));
            }
            for(Unit_Model__c unitModelRec : modelRecList) {
                ModelList.add(new MakeModelSubmodelWrapper(unitModelRec));
            }
            for(Unit_Sub_Model__c unitSubModelRec : subModelRecList) {
                SubModelList.add(new MakeModelSubmodelWrapper(unitSubModelRec));
            }
        }
    }
    
    public class MakeModelSubmodelWrapper {
        public String Id;
        public String UnitMakeName;
        public String UnitModelName;
        public String SubModelName;
        public String SubModelDescription;
        public String MakeId;
        public String ModelId;
        public String ModelDescription;
        public String CategoryId;
        public String CategoryName;
        public Boolean Active;
        
        public MakeModelSubmodelWrapper(Unit_Make__c unitMakeRec) {
            this.Id = unitMakeRec.Id;
            this.UnitMakeName = unitMakeRec.Name;
            this.Active = unitMakeRec.Active__c;
        }
        public MakeModelSubmodelWrapper(Unit_Model__c unitModelRec) {
            this.Id = unitModelRec.Id;
            this.UnitModelName = unitModelRec.Name__c;
            this.MakeId = unitModelRec.Unit_Make__c;
            this.ModelDescription = unitModelRec.Description__c;
            this.Active = unitModelRec.Active__c;
            this.CategoryId = unitModelRec.Category__c;
            this.CategoryName = unitModelRec.Category__r.Name;
        }
        public MakeModelSubmodelWrapper(Unit_Sub_Model__c unitSubModelRec) {
            this.Id = unitSubModelRec.Id;
            this.SubModelName = unitSubModelRec.Sub_Model_Name__c;
            this.ModelId = unitSubModelRec.Unit_Model__c;
            this.SubModelDescription = unitSubModelRec.Description__c;
            this.CategoryId = unitSubModelRec.Category__c;
            this.CategoryName = unitSubModelRec.Category__r.Name;
            this.Active = unitSubModelRec.Active__c;
        }
    }

    public static String deleteMake(String makeId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Customer_Owned_Unit__c> couList = [SELECT Unit_Make__c FROM Customer_Owned_Unit__c WHERE Unit_Make__c =: makeId Limit 1];
        List<Deal_Item__c> tempUnitList = [SELECT Id FROM Deal_Item__c WHERE Unit_Make__c =: makeId AND Customer_Owned_Unit__c = null Limit 1]; 
        if(couList.size() > 0 || tempUnitList.size() > 0) {   
            throw new BlackPurlException('Cannot delete this make. This make is currently in use.');
        } else {
            Unit_Make__c unitMakeRec = new Unit_Make__c(Id = makeId);
            Set<Id> setOfUnitModelIds = new Set<Id>();
            if(!AccessControl.ifObjectFieldIsAccessible('Unit_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Unit_Model__c> unitModelList = [SELECT Id FROM Unit_Model__c WHERE Unit_Make__c =: makeId];
            for(Unit_Model__c unitModelRec : unitModelList) {
                setOfUnitModelIds.add(unitModelRec.Id);
            } 
            if(!setOfUnitModelIds.isEmpty()) {
                if(!AccessControl.ifObjectFieldIsAccessible('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(!AccessControl.ifObjectIsDeletable('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete([SELECT Id FROM Unit_Sub_Model__c WHERE Unit_Model__c IN: setOfUnitModelIds]) ;
            }
            if(!AccessControl.ifObjectIsDeletable('Unit_Make__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete unitMakeRec;
        }
        return 'Success';
    }

    public static String deleteModel(String modelId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Customer_Owned_Unit__c> couList = [SELECT Unit_Model__c FROM Customer_Owned_Unit__c WHERE Unit_Model__c =: modelId Limit 1];
        List<Deal_Item__c> tempUnitList = [SELECT Id FROM Deal_Item__c WHERE Unit_Model__c =: modelId AND Customer_Owned_Unit__c = null Limit 1];
        if(couList.size() > 0 || tempUnitList.size() > 0) {
            throw new BlackPurlException('Cannot delete this model. This model is currently in use.');
        } else {
            if(!AccessControl.ifObjectFieldIsAccessible('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Unit_Sub_Model__c> associatedSubModel = [SELECT id FROM Unit_Sub_Model__c WHERE Unit_Model__c =: modelId];
            if (associatedSubModel.size() > 0) {
                if(!AccessControl.ifObjectIsDeletable('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete associatedSubModel;
            }
            Unit_Model__c unitModelRec = new Unit_Model__c(Id = modelId);
            if(!AccessControl.ifObjectIsDeletable('Unit_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete unitModelRec;
        }  
        return 'Success';
    }

    public static String deleteSubModel(String subModelId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Customer_Owned_Unit__c> couList = [SELECT Sub_Model__c FROM Customer_Owned_Unit__c WHERE Sub_Model__c =: subModelId Limit 1];
        List<Deal_Item__c> tempUnitList = [SELECT Id FROM Deal_Item__c WHERE Sub_Model__c =: subModelId AND Customer_Owned_Unit__c = null Limit 1];
        if(couList.size() > 0 || tempUnitList.size() > 0) {
            throw new BlackPurlException('Cannot delete this sub-model. This sub-model is currently in use.');
        } else {
            if(AccessControl.ifObjectIsDeletable('Unit_Sub_Model__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            Unit_Sub_Model__c unitSubModelRec = new Unit_Sub_Model__c(Id = subModelId);
            delete unitSubModelRec;
        } 
        return 'Success';
    }

    public static String saveMake(String makeJSONString) {
        MakeModelSubmodelWrapper makeObj = (MakeModelSubmodelWrapper) System.JSON.deserialize(makeJSONString, MakeModelSubmodelWrapper.class);
        if(String.isBlank(makeObj.Id)) {
            if(!AccessControl.ifObjectFieldIsCreateable('Unit_Make__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }  
        } else {
            if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Make__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }  
        }
        Unit_Make__c makeRec = new Unit_Make__c();
        if(String.isNotBlank(makeObj.Id)) {
            makeRec.Id = makeObj.Id;
            makeRec.Active__c = makeObj.Active;
        }
        makeRec.Name = makeObj.UnitMakeName;
        upsert makeRec;
        return makeRec.Id;
    }

    public static String saveModel(String modelJSONString) { 
        MakeModelSubmodelWrapper modelObj = (MakeModelSubmodelWrapper) System.JSON.deserialize(modelJSONString, MakeModelSubmodelWrapper.class);
        if(String.isBlank(modelObj.Id)) {
            if(!AccessControl.ifObjectFieldIsCreateable('Unit_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        } else {
            if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        }
        Unit_Model__c modelRec = new Unit_Model__c();
        if(String.isNotBlank(modelObj.Id)) {
            modelRec.Id = modelObj.Id;
            modelRec.Active__c = modelObj.Active;
        } else {
            modelRec.Unit_Make__c = modelObj.MakeId;
        }
        modelRec.Name__c = modelObj.UnitModelName;
        modelRec.Description__c = modelObj.ModelDescription;
        modelRec.Category__c = modelObj.CategoryId;
        upsert modelRec;
        return modelRec.Id;
    }

    public static String saveSubModel(String subModelJSONString) {
        MakeModelSubmodelWrapper subModelObj = (MakeModelSubmodelWrapper) System.JSON.deserialize(subModelJSONString, MakeModelSubmodelWrapper.class);
        if(String.isBlank(subModelObj.Id)) {
    		if(!AccessControl.ifObjectFieldIsCreateable('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
    	}else {
    		if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	}
        Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c();
        if(String.isNotBlank(subModelObj.Id)) {
            subModelRec.Id = subModelObj.Id;
            subModelRec.Active__c = subModelObj.Active;
        }
        subModelRec.Sub_Model_Name__c = subModelObj.SubModelName;
        subModelRec.Description__c = subModelObj.SubModelDescription;
        subModelRec.Category__c = subModelObj.CategoryId;
        subModelRec.Unit_Model__c = subModelObj.ModelId;
        upsert subModelRec;
        return subModelRec.Id;
    }
    
    public static String getModelListByMakeId(String makeId) {
		List<MakeModelSubmodelWrapper> modelList = new List<MakeModelSubmodelWrapper>();
		String query = getQuery('Unit_Model__c', true, new Map<String, String>{'Unit_Make__c'=> makeId});
		
        for(Unit_Model__c unitModelRec : Database.query(query)) {
            modelList.add(new MakeModelSubmodelWrapper(unitModelRec));
        }
        return system.JSON.serialize(modelList, true);
    }
    
    public static String getSubmodelListByModelId(String modelId) {
		List<MakeModelSubmodelWrapper> submodelList = new List<MakeModelSubmodelWrapper>();
		String query = getQuery('Unit_Sub_Model__c', true, new Map<String, String>{'Unit_Model__c'=> modelId});
			
        for(Unit_Sub_Model__c unitSubModelRec : Database.query(query)) {
            submodelList.add(new MakeModelSubmodelWrapper(unitSubModelRec));
        }
        return system.JSON.serialize(submodelList, true);
    }
}
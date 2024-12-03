/**
 * Author: Nidhi Sharma
 * Since: January 04, 2021
 * Name: UnitPricingSOQLUtil
 * Description: SOQL Util class for Unit pricing page
**/
public without sharing class UnitPricingSOQLUtil {
    
    public static List<Unit_Make__c> getAllUnitMakes(Boolean includeNonAddedPricing) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Make__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Name,  (SELECT id FROM Unit_Models__r WHERE Active__c = true)' ;
        query += ' FROM Unit_Make__c WHERE  Enable_Unit_Pricing__c = ' + includeNonAddedPricing + ' AND Active__c = true' ;
        query += ' ORDER BY Name ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }
    
    public static List<Unit_Model__c> getActiveModelsByMakeId(String makeId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Model__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Unit_Make__r.Name, Name__c, (SELECT Id FROM Unit_Sub_Models__r WHERE Active__c = true)' ;
        query += ' FROM Unit_Model__c WHERE  Unit_Make__c =: makeId';
        query += ' ORDER BY Name__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }

    public static List<Factory_Option__c> getAllFactoryOptionsListByMakeId(String makeId) {
        return getAllFactoryOptionsListByMakeId(makeId, null);
    }
    
    public static List<Factory_Option__c> getAllFactoryOptionsListByMakeId(String makeId, Set<String> factoryOptionToExcludeSet) {
        if(!AccessControl.ifObjectFieldIsAccessible('Factory_Option__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Unit_Make__c, Code__c, Description__c, Cost__c, Price__c' ;
        query += ' FROM Factory_Option__c WHERE Unit_Make__c =: makeId';
        if(factoryOptionToExcludeSet != null && factoryOptionToExcludeSet.size() > 0) {
        	query += ' AND Id NOT IN: factoryOptionToExcludeSet';
        }
        query += ' ORDER BY Code__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }

    public static List<Submodel_Factory_Option_Junction__c> getAllFactoryOptionsListByRecId(String recId) {
        if(String.isNotBlank(recId)) {
            Id recordId = (Id)recId;
            if(!AccessControl.ifObjectFieldIsAccessible('Submodel_Factory_Option_Junction__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            String baseQuery = 'SELECT ' + String.join(FactoryOptionWrapper.getSubmodelFactoryOptionFieldList(), ', '); 
            baseQuery += ' FROM Submodel_Factory_Option_Junction__c';
            if(recordId.getSObjectType() == Schema.Unit_Model__c.SObjectType){
                baseQuery += ' WHERE Unit_Model__c =: recordId ';
            } else {
                baseQuery += ' WHERE Unit_Sub_Model__c =: recordId ';
            }
            baseQuery += ' ORDER BY Factory_Option__r.Code__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
            return Database.query(baseQuery);
        }
        return new List<Submodel_Factory_Option_Junction__c>();
    }
    
    public static List<Submodel_Factory_Option_Junction__c> getAllModelAndSubModelFactoryOptionsList(String modelId, String subModelId, Set<String> factoryOptionToExcludeSet) {
        if(!AccessControl.ifObjectFieldIsAccessible('Submodel_Factory_Option_Junction__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String baseQuery = 'SELECT ' + String.join(FactoryOptionWrapper.getSubmodelFactoryOptionFieldList(), ', '); 
        baseQuery += ' FROM Submodel_Factory_Option_Junction__c';
        baseQuery += ' WHERE (Unit_Model__c =: modelId';
        if(String.isNotBlank(subModelId)) {
        	baseQuery += ' OR Unit_Sub_Model__c =: subModelId';
        }
        baseQuery += ')';
        if(factoryOptionToExcludeSet != null && factoryOptionToExcludeSet.size() > 0) {
        	baseQuery += ' AND Factory_Option__c NOT IN: factoryOptionToExcludeSet';
        }
        baseQuery += ' ORDER BY Factory_Option__r.Code__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(baseQuery);
    }
    
    public static List<SObject> getAlreadyAddedFOPTList(String sObjectType, String recId) {
    	String query = 'SELECT Factory_Option__c FROM';
    	if(sObjectType == Constants.NAMESPACE + 'Deal_Item__c') {
    		if(!AccessControl.ifObjectFieldIsAccessible('Deal_Item__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    		query += ' Deal_Unit_Price_Cost__c WHERE Deal_Item__c =: recId';
    	} else if(sObjectType == Constants.NAMESPACE + 'Customer_Owned_Unit__c') {
    		if(!AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    		query += ' Unit_Price_Cost__c WHERE Customer_Owned_Unit__c =: recId';
    	}
    	query += ' AND Type__c = \'Factory\' AND Factory_Option__c != null';
    	return Database.query(query);
    }

    public static List<Unit_Sub_Model__c> getActiveSubModelsByModelId(UnitPricingService.UnitSubmodelFilterWrapper filterObj) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Sub_Model__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Unit_Model__r.Name__c, Unit_Model__r.Default_Holdback__c, Unit_Model__r.Default_Price__c, Unit_Model__r.Default_Cost__c, Sub_Model_Name__c, Cost__c, Price__c, Holdback__c, (SELECT id FROM Submodel_Factory_Option_Junctions__r)' ;
        query += ' FROM Unit_Sub_Model__c ' + getWhereClauseByFilterStr(filterObj);
        query += ' ORDER BY Sub_Model_Name__c ASC ' + SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
        List<SObject> sobjList = SOQLUtility.getQueryResults('Unit_Sub_Model__c', query);
    	
    	if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
    	}
    	return sobjList;
    }

    public static List<Unit_Model__c> getActiveModelsByModelId(String modelId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Model__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'Select Name__c, Default_Cost__c,  Default_Holdback__c, Default_Price__c, (SELECT Id FROM Submodel_Factory_Option_Junctions__r) ' ;
        query += ' FROM Unit_Model__c WHERE Id =: modelId';
        query += ' ORDER BY Name__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }

    public static List<Unit_Sub_Model__c> getCostAndPriceBySubModelId(String subModelId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Sub_Model__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Cost__c, Price__c FROM Unit_Sub_Model__c WHERE  Active__c = true AND Id =: subModelId';
        return Database.query(query);
    }

    public static List<Unit_Model__c> getCostAndPriceByModelId(String modelId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Model__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        String query = 'SELECT Id, Default_Cost__c, Default_Price__c FROM Unit_Model__c WHERE Id =: modelId' ;
        return Database.query(query);
    }

    private static String getWhereClauseByFilterStr(UnitPricingService.UnitSubmodelFilterWrapper filterObj) {
    	List<String> filterStrList = new List<String>{'Active__c = true'};
    	
    	if(filterObj != null) {
	    	if(String.isNotBlank(filterObj.SearchKeyword)) {
                filterObj.SearchKeyword = BPUtility.escapeSingleQuotes(filterObj.SearchKeyword.trim());
                filterStrList.add('(Sub_Model_Name__c LIKE \'' + filterObj.SearchKeyword + '%\')');
	    	}
	    	if(String.isNotBlank(filterObj.ModelId)) {
                filterStrList.add('(Unit_Model__c = \'' + filterObj.ModelId + '\')');
	    	}
    	}
    	return (!filterStrList.isEmpty() ? ' WHERE ' + String.join(filterStrList, ' AND ') : '');
    }
    
}
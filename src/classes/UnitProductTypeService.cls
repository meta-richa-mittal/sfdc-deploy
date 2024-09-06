/**
 * Author: Richa Mittal
 * Since: July 23, 2024
 * Name: UnitProductTypeService
 * Description: 
**/
public without sharing class UnitProductTypeService {
    
    public static final String GENERIC = 'Generic';
    public static Map<String, Integer> CategoryNameToOrderMap = new Map<String, Integer>{
        'General & Identification' => 1,
        'Weights & Dimensions' => 2,
        'Power & Wheels' => 3,
        'Construction' => 4,
        'Other specs' => 5,
        'Miscellaneous' => 6
    };
    public static Map<String, String> FieldTypeLabelToValueMap = new Map<String, String>{
        'string' => 'Text',
        'date' => 'Date',
        'double' => 'Number',
        'picklist' => 'Dropdown',
        'textarea' => 'Long Text'
    };
    public static Map<String, Unit_Product_Type_Field__c> OptionalFieldAPINameToRecMap;
    public static Map<String, String> UnitDataFieldsAPINameToLabelMap;

    public static List<UnitProductTypeWrapper> getProductTypes(String productTypeId) {
        List<UnitProductTypeWrapper> productTypeList = new List<UnitProductTypeWrapper>();
        String query = 'SELECT Name__c, Default__c, Active__c, Active_Fields_Count__c';
        if(String.isNotBlank(productTypeId)) {
            query += ', (SELECT Name, Active__c, Category__c, COU_API_Name__c, Include_In_Deal_Document__c, Include_In_SO_Document__c';
            query += ', Include_In_Unit_Order_Document__c FROM Unit_Product_Type_Fields__r ORDER BY Order__c)';
        }
        query += ' FROM Unit_Product_Type__c';
        if(String.isNotBlank(productTypeId)) {
            query += ' WHERE Id = :productTypeId';
        }
        for(Unit_Product_Type__c proTypeRec: Database.query(query)) {
            productTypeList.add(new UnitProductTypeWrapper(proTypeRec, proTypeRec.Unit_Product_Type_Fields__r, null));
        }
        return productTypeList;
    }

    public static void saveProductType(String productTypeJSON) {
        try {
            UnitProductTypeWrapper productTypeObj = (UnitProductTypeWrapper) System.JSON.deserialize(productTypeJSON, UnitProductTypeWrapper.class);
            List<Unit_Product_Type__c> productTypeListToUpsert = new List<Unit_Product_Type__c>();
            Unit_Product_Type__c productTypeRec = new Unit_Product_Type__c();
            productTypeRec.Id = productTypeObj.Id;
            productTypeRec.Name__c = productTypeObj.Name;
            productTypeRec.Active__c = productTypeObj.Active;
            productTypeRec.Default__c = productTypeObj.IsDefault;
            productTypeListToUpsert.add(productTypeRec);

            if(productTypeObj.IsDefault) {
                String query = 'SELECT Id FROM Unit_Product_Type__c WHERE Default__c = true';
                if(productTypeObj.Id != null) {
                    String idValue = productTypeObj.Id;
                    query += ' AND Id != :idValue';
                }
                List<Unit_Product_Type__c> defProductTypeList = Database.query(query);
                if(!defProductTypeList.isEmpty()) {
                    defProductTypeList[0].Default__c = false;
                    productTypeListToUpsert.add(defProductTypeList[0]);
                }
            }
            DMLUtility.upsertSobjectList('Unit_Product_Type__c', productTypeListToUpsert);

            List<Unit_Product_Type_Field__c> fieldList = new List<Unit_Product_Type_Field__c>();
            for(UnitProductTypeWrapper.CategoryDataWrapper categoryObj: productTypeObj.CategoryList) {
                for(UnitProductTypeWrapper.UnitProductTypeFieldWrapper fieldObj: categoryObj.FieldValuesList) {
                    fieldList.add(new Unit_Product_Type_Field__c(Id = fieldObj.Id, Active__c = fieldObj.Active, Name = fieldObj.Name, 
                                                                    Category__c = categoryObj.CategoryName, Order__c = fieldObj.OrderNumber, 
                                                                    COU_API_Name__c = fieldObj.COUAPIName, 
                                                                    Include_In_Deal_Document__c = fieldObj.IncludeInDealDocument, 
                                                                    Include_In_SO_Document__c = fieldObj.IncludeInSODocument, 
                                                                    Include_In_Unit_Order_Document__c = fieldObj.IncludeInUnitOrderDocument, 
                                                                    Unit_Product_Type__c = productTypeListToUpsert[0].Id)); // Since we have added the add/update product type record at 0th position
                }
            }
            DMLUtility.upsertSobjectList('Unit_Product_Type_Field__c', fieldList);
        } catch(Exception e) {
            if(e.getMessage().contains('Duplicate value')) {
                throw new BlackPurlException('Unit Product Type Name already exists. Please use a different name.');
            } else {
                throw new BlackPurlException(e.getMessage());
            }
        }
    }

    public static UnitProductTypeWrapper getNewProductTypeDefaultData() {
        List<FilterJSON> filerObjList = new List<FilterJSON>{
            new FilterJSON('Unit_Product_Type__r.Name__c', SOQLUtility.EQUALS, UnitProductTypeService.GENERIC)
        };
        List<Unit_Product_Type_Field__c> fieldsList = getProductTypeFieldsByFilter(filerObjList);
        return new UnitProductTypeWrapper(new Unit_Product_Type__c(), fieldsList, null);
    }

    public static Map<String, Unit_Product_Type_Field__c> getUnitOptionalFieldAPINameToRecMap(List<FilterJSON> filerObjList) {
        Map<String, Unit_Product_Type_Field__c> fieldNameToRecMap = new Map<String, Unit_Product_Type_Field__c>();
        for(Unit_Product_Type_Field__c fieldRec: getProductTypeFieldsByFilter(filerObjList)) {
            if(String.isNotBlank(fieldRec.COU_API_Name__c)) fieldNameToRecMap.put(fieldRec.COU_API_Name__c, fieldRec);
        }
        return fieldNameToRecMap;
    }

    private static List<Unit_Product_Type_Field__c> getProductTypeFieldsByFilter(List<FilterJSON> filerObjList) {
        String query = 'SELECT ' + String.join(UnitProductTypeWrapper.getFields(), ', ') + ' FROM Unit_Product_Type_Field__c ';
        query += SOQLUtility.getWhereClauseWithANDCondition(filerObjList, true);
        query += ' ORDER BY Order__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        system.debug('**** - ' + query);
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Product_Type_Field__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }


    public static Unit_Product_Type__c getApplicableUnitProductType(String productTypeId) {
        String query = 'SELECT Name__c, Default__c, Active__c, Active_Fields_Count__c';
        query += ', (SELECT Name, Active__c, Category__c, COU_API_Name__c, Include_In_Deal_Document__c, Include_In_SO_Document__c';
        query += ', Include_In_Unit_Order_Document__c FROM Unit_Product_Type_Fields__r WHERE Active__c = true ORDER BY Order__c)';
        query += ' FROM Unit_Product_Type__c'; 
        if(String.isNotBlank(productTypeId)) {
            query += ' WHERE Id = :productTypeId';
        } else {
            query += ' WHERE Default__c = true';
        }
        List<Unit_Product_Type__c> unitProductType = Database.query(query);
        if(unitProductType.isEmpty()) throw new BlackPurlException('Unit product type is not available.'); 
        return unitProductType[0];
    }

    public static UnitProductTypeWrapper getUnitOptionalFieldsData(String productTypeId, String unitId) {
        Unit_Product_Type__c unitProductType = getApplicableUnitProductType(productTypeId);
        if(String.isBlank(unitId)) {
            return new UnitProductTypeWrapper(unitProductType, unitProductType.Unit_Product_Type_Fields__r, null);
        }

        List<String> activeUnitFieldList = new List<String>();
        for(Unit_Product_Type_Field__c unitProductFieldRec : unitProductType.Unit_Product_Type_Fields__r) {
            if(String.isNotBlank(unitProductFieldRec.COU_API_Name__c)) activeUnitFieldList.add(unitProductFieldRec.COU_API_Name__c);
        }

        List<Customer_Owned_Unit__c> couList = SOQLUtil.dynamicSOQLQuery('Customer_Owned_Unit__c', activeUnitFieldList, new Map<String, Object>{'Id' => unitId});
        if(couList.isEmpty()) throw new BlackPurlException('Unit not found with Id ' + unitId);


        return new UnitProductTypeWrapper(unitProductType, unitProductType.Unit_Product_Type_Fields__r, couList[0]);
    }

    public static List<UnitProductTypeWrapper> getUnitProductTypeList() {
    	List<UnitProductTypeWrapper> productTypeObjList = new List<UnitProductTypeWrapper>();
        List<Unit_Product_Type__c> productTypeList = [SELECT Id, Name__c, Default__c, Active__c FROM Unit_Product_Type__c WHERE Active__c = true];
        for(Unit_Product_Type__c productType : productTypeList) {
            productTypeObjList.add(new UnitProductTypeWrapper(productType));
        }
        return productTypeObjList;
    }
}
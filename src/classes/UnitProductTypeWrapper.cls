/**
 * Author: Richa Mittal
 * Since: July 24, 2024
 * Name: UnitProductTypeWrapper
 * Description: 
**/
public without sharing class UnitProductTypeWrapper {

    private static String namespace = Constants.NAMESPACE;

    public String Id;
    public String Name;
    public Integer UnitValues;
    public Boolean IsDefault;
    public Boolean Active;
    public List<CategoryDataWrapper> CategoryList;

    public UnitProductTypeWrapper(Unit_Product_Type__c productTypeRec) {
        this.Id = productTypeRec.Id;
        this.Name = productTypeRec.Name__c;
        this.IsDefault = productTypeRec.Default__c != null ? productTypeRec.Default__c : false;
    }

    public UnitProductTypeWrapper(Unit_Product_Type__c productTypeRec, List<Unit_Product_Type_Field__c> fieldsList, Customer_Owned_Unit__c couRecord) {
        // null check added because productTypeRec can be dummy rec
        this.Id = productTypeRec.Id;
        this.Name = productTypeRec.Name__c;
        this.UnitValues = productTypeRec.Active_Fields_Count__c != null ? Integer.valueOf(productTypeRec.Active_Fields_Count__c) : 0;
        this.IsDefault = productTypeRec.Default__c != null ? productTypeRec.Default__c : false;
        this.Active = productTypeRec.Active__c != null ? productTypeRec.Active__c : false;
        Boolean isDummy = String.isBlank(productTypeRec.Name__c) ? true : false;
        if(fieldsList != null) {
            Map<String, String> unitDataFieldsAPINameToLabelMap = GeneralConfiguration.getUnitDataFieldsAPINameToLabelMap();
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(namespace + 'Customer_Owned_Unit__c');
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            this.CategoryList = new List<CategoryDataWrapper>();
            Map<String, List<UnitProductTypeFieldWrapper>> categoryNameToFieldValuesMap = new Map<String, List<UnitProductTypeFieldWrapper>>();
            String fieldValue;
            for(Unit_Product_Type_Field__c fieldRec: fieldsList) {
                String fieldType, fieldName;
                if(!categoryNameToFieldValuesMap.containsKey(fieldRec.Category__c)) {
                    categoryNameToFieldValuesMap.put(fieldRec.Category__c, new List<UnitProductTypeFieldWrapper>());
                }
                if(fieldRec.Category__c == 'Miscellaneous') {
                    if(!unitDataFieldsAPINameToLabelMap.keySet().contains(fieldRec.COU_API_Name__c)) {
                        continue;
                    } else {
                        fieldName = unitDataFieldsAPINameToLabelMap.get(fieldRec.COU_API_Name__c);
                    }
                }
                fieldType = fieldMap.get(namespace + fieldRec.COU_API_Name__c) != null ? String.valueOf((fieldMap.get(namespace + fieldRec.COU_API_Name__c)).getDescribe().getType()).toLowerCase() : '';
                fieldType = UnitProductTypeService.FieldTypeLabelToValueMap.containsKey(fieldType) ? UnitProductTypeService.FieldTypeLabelToValueMap.get(fieldType) : fieldType;
                if(couRecord != null) {
                    fieldValue = null;
                    if(fieldType == 'Date' && couRecord.get(namespace + fieldRec.COU_API_Name__c) != null) {
                        Date dateValue = (Date)couRecord.get(namespace + fieldRec.COU_API_Name__c); // Cast to Date
                        fieldValue = BPUtility.getFormatedDateTime(datetime.newInstance(dateValue.year(), dateValue.month(), dateValue.day()));
                    } else if (fieldType == 'Number' && couRecord.get(namespace + fieldRec.COU_API_Name__c) != null){
                        fieldValue = ((Decimal)couRecord.get(namespace + fieldRec.COU_API_Name__c)).toPlainString();
                    } else {
                        fieldValue = (String)couRecord.get(namespace + fieldRec.COU_API_Name__c);
                    }
                    categoryNameToFieldValuesMap.get(fieldRec.Category__c).add(new UnitProductTypeFieldWrapper(fieldRec, isDummy, fieldType, fieldValue, fieldName));
                } else {
                    categoryNameToFieldValuesMap.get(fieldRec.Category__c).add(new UnitProductTypeFieldWrapper(fieldRec, isDummy, fieldType, null, fieldName));
                }
            }
            for(String categoryName: categoryNameToFieldValuesMap.keySet()) {
                this.CategoryList.add(new CategoryDataWrapper(categoryName, UnitProductTypeService.CategoryNameToOrderMap.get(categoryName), categoryNameToFieldValuesMap.get(categoryName)));
            }
            this.CategoryList.sort();
        }
    }

    public class CategoryDataWrapper implements Comparable {
        public String CategoryName;
        public Integer Order;
        public List<UnitProductTypeFieldWrapper> FieldValuesList;

        public CategoryDataWrapper(String categoryName, Integer order, List<UnitProductTypeFieldWrapper> fieldValues) {
            this.CategoryName = categoryName;
            this.Order = order;
            this.FieldValuesList = fieldValues;
        }

        public Integer compareTo(Object compareTo) {
            CategoryDataWrapper compareToWrapperObj = ((CategoryDataWrapper)compareTo);
            if (Order == compareToWrapperObj.Order) return 0;
            if (Order > compareToWrapperObj.Order) return 1;
            return -1; 
        }
    }

    public class UnitProductTypeFieldWrapper {

        public String Id;
        public String Name;
        public Boolean Active;
        public Boolean IncludeInDealDocument;
        public Boolean IncludeInSODocument;
        public Boolean IncludeInUnitOrderDocument;
        public Integer OrderNumber;
        public String COUAPIName;
        public String FieldType;
        public String FieldValue;

        public UnitProductTypeFieldWrapper(Unit_Product_Type_Field__c fieldRec, Boolean isDummy, String fieldType, String fieldValue, String fieldName) {
            this.Id = isDummy ? null : fieldRec.Id;
            this.Name = String.isNotBlank(fieldName) ? fieldName : fieldRec.Name;
            this.Active = isDummy ? false : fieldRec.Active__c;
            this.IncludeInDealDocument = isDummy ? false : fieldRec.Include_In_Deal_Document__c;
            this.IncludeInSODocument = isDummy ? false : fieldRec.Include_In_SO_Document__c;
            this.IncludeInUnitOrderDocument = isDummy ? false : fieldRec.Include_In_Unit_Order_Document__c;
            this.OrderNumber = isDummy && fieldRec.Order__c != null ? Integer.valueOf(fieldRec.Order__c) : 0;
            this.COUAPIName = fieldRec.COU_API_Name__c;
            this.FieldType = fieldType;
            this.FieldValue = fieldValue;
        }
    }

    public static List<String> getFields() {
        return new List<String>{'Name', 
                                 'Order__c', 
                                 'COU_API_Name__c',
                                 'Category__c'
                               };
     }
}
public without sharing class GenericSearchUtil {
    
    public static final Integer MAX_RECORDS_TO_DISPLAY = 10;
    public static final Integer MIN_SEARCH_CHAR_TO_SEARCH = 3;
    public static final Integer MAX_RECORD_FOR_SPECIAL_OBJECTS = 50;
    
    public static List<String> matchingCriteriaPriorityList = new List<String>{'Exact', 'StartsWith', 'Contains'};
    public static Set<String> limitedRecordsObjectSet = new Set<String>{'Part__c', 'Account'};
    public static Map<String, List<String>> objectNameToSOSLSearchableFieldsNameListMap = new Map<String, List<String>>{
        'Location__c' => new List<String>{'Name__c'},
        'Part__c' => new List<String>{'Part_Number__c', 'Mfg_Part__c', 'SKU_Number__c', 'Part_Id__c', 'Description__c'},
        'Account' => new List<String>{'Name', 'FirstName__c', 'LastName__c', 'Phone', 'Home_Number__c', 'Mobile__c', 'Work_Number__c', 'Formatted_Home_number__c',
                                                'Formatted_Mobile_Number__c', 'Formatted_Work_Number__c', 'Email__c', 'Other_Email__c', 'Work_Email__c'}
    };
    public static Map<String, String> objectNameToInnerSortingFieldName = new Map<String, String>{
        'Part__c' => 'AvailableParts__c'
    };
    
    public static map<String, String> objectNameToObjectDisplayLabel = new map<String, String>{
                                                                            'Customer' => Label.Customer_Object_Display_Label,
                                                                            'Vendor' => Label.Vendor_Object_Display_Label,
                                                                            'Part__c' => Label.Part_Object_Display_Label,
                                                                            'Labour_Code__c' => Label.Labour_Object_Display_Label,
                                                                            'Kit_Header__c' => Label.Kit_Object_Display_Label,
                                                                            'Fee__c' => Label.Fee_Object_Display_Label,
                                                                            'Customer_Owned_Unit__c' => 'Unit',
                                                                            'Product__c' => 'Product',
                                                                            'Country__c' => 'Country'
                                                                        };
                                                                        
    public static String getObjectAPIName(String objectLabel) {
        String objectApiName = objectLabel;
        if(objectLabel == 'Customer' || objectLabel == 'Vendor') {
            objectApiName = 'Account';
        }
        return objectApiName;
    }
    
    public class QueryJSON {
        public String ObjectLabel;
        public String SearchText;
        public String SearchableObjects;
        public Boolean IsSpecialSearch;
        public List<FilterJSON> FilterValues;
        public String SearchConfigNames;
        public String PreferredObject;
        public Integer FromIndex;
        public Integer ToIndex;
    }
    
    public class FilterJSON {
        public String Field;
        public String Operator;
        public String Value;
        public String FilterObject;
        
        public FilterJSON(String Field, String operator, String value, String filterObject){
            this.Field = Field;
            this.Operator = operator;
            this.Value = value;
            this.FilterObject = filterObject;
        }
    }
    
    public class FieldFilter {
        public String FieldName;
        public String Operator;
        public Object FieldValue;
        
        public FieldFilter(String fieldName, String operator, Object value){
            this.FieldName = fieldName;
            this.Operator = operator;
            this.FieldValue = value;
        }
    }
    
    public class SearchedSObjectWrapper implements Comparable {
        public SObject SearchedObj;
        public Decimal PriorityValue;
        public String objectName;
        
        public SearchedSObjectWrapper(SObject searchedObj, Decimal priorityNumber, String objectName) {
            this.SearchedObj = searchedObj;
            this.PriorityValue = priorityNumber;
            this.objectName = objectName;
        } 
        
        public Integer compareTo(Object compareTo) {
            SearchedSObjectWrapper compareToWrapperObj = ((SearchedSObjectWrapper)compareTo);
            Integer returnValue = 0;
            if (PriorityValue == compareToWrapperObj.PriorityValue) return 0;
            if (PriorityValue > compareToWrapperObj.PriorityValue) return 1;
            return -1; 
        }
    }
    
	public static String formatDynamicTextInSOSL(String textValueToEscape) {
    	textValueToEscape = (textValueToEscape == null) ? '' : textValueToEscape;
    	textValueToEscape = String.escapeSingleQuotes(textValueToEscape);
    	
    	textValueToEscape = textValueToEscape.replace('\\\\', '\\')
											 .replace('?', '\\?')
    										 .replace('&', '\\&')
    										 .replace('|', '\\|')
    										 .replace('!', '\\!')
    										 .replace('{', '\\{')
    										 .replace('}', '\\}')
    										 .replace('[', '\\[')
    										 .replace(']', '\\]')
    										 .replace('(', '\\(')
    										 .replace(')', '\\)')
    										 .replace('^', '\\^')
    										 .replace('~', '\\~')
    										 .replace('*', '\\*')
    										 .replace(':', '\\:')
    										 .replace('"', '\\"')
    										 .replace('\'', '\\\'')
    										 .replace('+', '\\+')
    										 .replace('-', '\\-');
		return textValueToEscape;
    }

    public static String getFieldValueFromSObject(SObject sObjRec, String fieldName) {
        String fieldValue;
        if(fieldName.contains('__r')) {
            List<String> referncedFieldNameList = fieldName.split('\\.');
            SOBject sobj = null;
            for(Integer j = 0; j < referncedFieldNameList.size(); j++) {
                if(referncedFieldNameList[j].contains('__r')) {
                    sobj = (sobj != null) ? sobj.getSobject(Constants.NAMESPACE + referncedFieldNameList[j]) : sObjRec.getSobject(Constants.NAMESPACE + referncedFieldNameList[j]);
                } else if(sobj != null) {
                    fieldValue = sobj.get(referncedFieldNameList[j]) != null ? String.valueOf(sobj.get(referncedFieldNameList[j])) : null;
                }
            }
        } else {
            fieldValue = sObjRec.get(fieldName) != null ? String.valueOf(sObjRec.get(fieldName)) : null;
        }
        return fieldValue;
    }
    
    public static Decimal getSortIndexForInnerSorting(Decimal decimalValue) {
        decimalValue = decimalValue != null ? decimalValue : 0;
        Integer maxValueDigits = 8; // considering this will be the max digits for any decimal value (part's available qty)
        Decimal baseValue = 10;
        return (baseValue.pow(maxValueDigits) - (decimalValue/(baseValue.pow(maxValueDigits))));
    }
}
public without sharing class CategoryService {
    
    public static List<CategoryWrapper> getFilteredCategoryWrapperList(Map<String, String> fieldAPINameToSearchFieldMap) {
        List<Category__c> categoryList = getFilteredCategory(fieldAPINameToSearchFieldMap);
        return getCategoryObjList(categoryList);
    }
    
    public static List<Category__c> getFilteredCategory(Map<String, String> fieldAPINameToSearchFieldMap) {
        String query = 'SELECT Id, Name, Default__c FROM Category__c WHERE Active__c = true ';
        for(String fieldName : fieldAPINameToSearchFieldMap.keySet()) {
            query += 'AND ' + fieldName + ' = \'' + fieldAPINameToSearchFieldMap.get(fieldName) + '\'';
        }
        query += ' ORDER BY NAME ASC';
        return Database.query(query);
    }
    
    public static List<Category__c> getFilteredCategoryList(List<FilterJSON> filerObjList) {
    	String query = 'SELECT Id, Name, Default__c FROM Category__c ' + SOQLUtility.getWhereClauseWithANDCondition(filerObjList, true);
        query += ' ORDER BY Name DESC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
    	return SOQLUtility.getQueryResults('Category__c', query);
    }
    
    public static List<CategoryWrapper> getCategoryObjList(List<Category__c> categoryList) {
    	List<CategoryWrapper> wrapperList = new List<CategoryWrapper>();
        for(Category__c categoryRec : categoryList) {
            wrapperList.add(new CategoryWrapper(categoryRec));
        }
        return wrapperList;
    }

    public static Id getDefaultCategoryIdByType(String catType) {
        if(String.isNotBlank(catType)) {
            for(Category__c categoryRec : [Select Id FROM Category__c WHERE Active__c = true AND Default__c = true AND Type__c =: catType]) {
                return categoryRec.Id;
            }
        }
        return null;
    }
    
    public class CategoryWrapper {
        public String Id;
        public String Name;
        public Boolean IsDefault;
        public Boolean IsDefaultVendorCategory;
        
        public CategoryWrapper(Category__c categoryRec) {
            this.Id = categoryRec.Id;
            this.Name = categoryRec.Name;
            this.IsDefault = categoryRec.Default__c;
        }
    }
}
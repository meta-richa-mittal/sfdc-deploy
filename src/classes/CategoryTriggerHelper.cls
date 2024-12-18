/**
 * Author: Tarun Khandelwal
 * Since: Nov. 17, 2014
 * Name: CategoryTriggerHelper
 * Description: Helper class for triggers on Category object (Used In Kendo)
**/
public without sharing class CategoryTriggerHelper {
	
	// List to store trigger new list
    public static List<Category__c> categoryNewList = new List<Category__c>();
    
    // List to store trigger old list
    public static List<Category__c> categoryOldList = new List<Category__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Category__c> categoryNewMap = new Map<Id, Category__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Category__c> categoryOldMap = new Map<Id, Category__c>();
    
    // Boolean variable to check execution of trigger
    public static boolean runDefaultCheckBoxUpdate = true;
    
    // Trigger run boolean: Added by Pooja 20 Dec. 2016 (QB integration)
    //public static Boolean preventOnAccountingSync = false; 
    
    private static BaseIntegrationService integrationRec;
    
    /**
     * Name: checkForUniqueNameByType
     * Desc: Method to prevent to enter duplicate name by same Category Type
     * @param: 
     * @return: 
    **/
    public static void checkForUniqueNameByType() {
    	if(!runDefaultCheckBoxUpdate) {
    		return;
    	}
    	for(Category__c categoryRec : categoryNewList) {
            categoryRec.Unique_Category__c = categoryRec.Type__c + '-' + categoryRec.Name;
    	}
    	updateDefaultField();
    }
    	
    /**
     * Name: checkForUniqueNameByType
     * Desc: Method to prevent to enter duplicate name by same Category Type
     * @param: 
     * @return: 
    **/
    public static void updateDefaultField() {
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	for(Category__c categoryRec : categoryNewList) {
    		if(categoryRec.Default__c && !categoryRec.Active__c) {
    			categoryRec.addError('You can\'t make inactive category as default' );
    			return;
    		}
    		if(!categoryRec.Default__c && Trigger.isUpdate && categoryOldMap.get(categoryRec.Id).Default__c) {
    			categoryRec.addError('You can\'t deselect of a default category' );
    			return;
    		}
    		if(categoryRec.Default__c && Trigger.isUpdate && categoryOldMap.get(categoryRec.Id).Type__c != categoryRec.Type__c && categoryOldMap.get(categoryRec.Id).Default__c) {
    			categoryRec.addError('You Cannot change the category type of a default record.' );
    			return;
    		}
    	}
    	
    	Map<String, Category__c> categoryTypeToCategoryRecMap = new Map<String, Category__c>();
    	List<Category__c> existingCategoryList = [select Type__c, default__c From Category__c where default__c = true];
    	if(existingCategoryList.size() == 0) {
    		return;
    	} 
    	
    	for(Category__c categoryRec : existingCategoryList) {
    		if(!categoryTypeToCategoryRecMap.containsKey(categoryRec.Type__c)) {
    			categoryTypeToCategoryRecMap.put(categoryRec.Type__c, categoryRec);
    		} 
    	}
    	
    	List<Category__c> categoryListToBeUpdated = new List<Category__c>();
    	for(Category__c categoryToUpsert : categoryNewList) {
    		if(categoryTypeToCategoryRecMap.containsKey(categoryToUpsert.type__c) && categoryToUpsert.Default__c && categoryTypeToCategoryRecMap.get(categoryToUpsert.type__c).Id != categoryToUpsert.Id) {
    			Category__c categoryRecord = categoryTypeToCategoryRecMap.get(categoryToUpsert.type__c);
    			categoryRecord.Default__c = false;
    			categoryListToBeUpdated.add(categoryRecord);
    		} 
    	}
    	if(categoryListToBeUpdated.size() > 0) {
    		runDefaultCheckBoxUpdate = false;
            DMLUtility.updateSobjectList('Category__c', categoryListToBeUpdated);
    	}
    }
    
    
    /**
     * Name: checkForDefaultDelete
     * Desc: Method to prevent to delete default record.
     * @param: 
     * @return: 
    **/
    public static void checkForDefaultDelete() {
    	for(Category__c categoryRec : categoryOldList) {
    		if(categoryRec.Default__c) {
    			categoryRec.addError('You Can\'t delete category marked as default.');
    		}
    	}
    }
    
    public static void setAccountingSyncFlag() {
        if(QBUtil.isQBEnabled()) IntegrationSyncFlagService.manageCategorySyncFlag(categoryNewList, categoryOldMap);
    }
    
    public static void setItemCategoryDataForAccountSync(){
        if(QBUtil.isQBEnabled()) IntegrationSyncFlagService.checkAndInitiateSyncBatch(categoryNewList, IntegrationUtility.ITEM_CATEGORY);
    }
    
    public static void updateTradeInDefaultCategory() {
        List<Category__c> unitDefaultCategoryList = new List<Category__c>();
        for(Category__c categoryRec : categoryNewList) {
            if(categoryRec.Type__c == 'Unit' && categoryRec.Default__c == true
                && (categoryOldMap == null
                    || ((categoryOldMap.get(categoryRec.Id).Default__c != categoryRec.Default__c)
                        || (categoryRec.Inventory_GL__c != categoryOldMap.get(categoryRec.Id).Inventory_GL__c)))) {
                unitDefaultCategoryList.add(categoryRec);
            }
        }
        if(unitDefaultCategoryList.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Category__c> tradeInDefaultCategory = [SELECT Id FROM Category__c WHERE Type__c ='Trade-in'   AND Default__c=true];
            if(tradeInDefaultCategory.size() == 0) {
                tradeInDefaultCategory.add(new Category__c(Active__c=true, Type__c='Trade-in', Default__c=true, Name='Trade-in Default', Description__c='Default category for trade ins'));
            }
            tradeInDefaultCategory[0].Income_GL__c = unitDefaultCategoryList[0].Inventory_GL__c;
            DMLUtility.upsertSobjectList('Category__c', tradeInDefaultCategory);
        }
    }
}
public without sharing class UnitMakeTriggerHelper {
    
    public static void onBeforeInsert(List<Unit_Make__c> newList) {
        setMakeUniqueName(newList);
    }
    public static void onBeforeUpdate(List<Unit_Make__c> newList, Map<Id, Unit_Make__c> oldMap) {
        setMakeUniqueName(newList);   
    }
    
    public static void setMakeUniqueName(List<Unit_Make__c> newList) {
        for(Unit_Make__c make : newList) {
            make.Make_Name_Unique__c = make.Name;
        }
    }
}
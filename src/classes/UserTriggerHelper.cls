public without sharing class UserTriggerHelper {
    // List to store trigger new list
    public static List<User> userNewList = new List<User>();
    
    // List to store trigger old list
    public static List<User> userOldList = new List<User>();
    
    // List to store trigger new Map
    public static Map<Id, User> userNewMap = new Map<Id, User>();
    
    // List to store trigger old Map
    public static Map<Id, User> userOldMap = new Map<Id, User>();
    
    public static Boolean isRunTrigger = true;

    public static void createWidgetAndFilter(){
        List<Id> userIdList =  new List<Id>();
        for(User userRec : userNewList) {
          userIdList.add(userRec.Id);
        }
        assignUserGroup(userIdList);
        if(!Test.isRunningTest()) {
            assignBlackpurlPermissionSet(userIdList, false);
            assignMFAPermissionSet(userIdList);
        }
    }
    
    @future
    public static void createFilterInterface(List<Id> usersNewList){
        UserService.createFilters(usersNewList);
    }
    
    public static void populateDateFields(){
        for(User userRec : userNewList) {
            if(trigger.isInsert) {
                userRec.CreatedDate__c = system.today();
            }
            userRec.LastModifiedDate__c = system.today();
            
            // Populate Timezone offset value - Used in Time field sorting according to User local
            userRec.Timezone_Offset__c = (System.Timezone.getTimeZone(userRec.TimeZoneSidKey)).getOffset(system.now()) / (1000 * 60 * 60.0); 
        }
        removeInActiveUserFromGroup();
    }
    /**
     * Name: removeInActiveUserFromGroup
     * Desc: get InActive users 
     * @param:      
     * @return: 
    **/
    public static void removeInActiveUserFromGroup(){
    	Set<Id> userIdSet = new Set<Id>();
    	for(User userRec: UserNewList){
			if(!userRec.IsActive && userRec.IsActive != userOldMap.get(userRec.Id).IsActive){
				userIdSet.add(userRec.Id);	
			}	    	
    	}
    	if(userIdSet.size() > 0){
    		removeUserFromGroup(userIdSet);
    	}
    }
    /**
     * Name: removeUserFromGroup
     * Desc: Remove InActive user's group
     * @param:      
     * @return: 
    **/
   @future 
   public static void removeUserFromGroup(Set<Id> userIds) {
    	if(userIds.size() > 0){
            DMLUtility.deleteSobjectList('User_To_Group__c', [Select Id,User__c from User_To_Group__c where User__c IN : userIds]);
    	}
   }
    
    @future
    public static void assignUserGroup(List<Id> userIds){
        List<User> UserRecList = [Select Id, Profile.Name From User where Id In : userIds And Profile.Name = 'BlackPurl' ];
        List<User_Group__c> userGrpList = [Select Id from User_Group__c where Is_System_Created__c = true];
     
        List<User_To_Group__c> userToGroupListToInsert = new List<User_To_Group__c>();
        
        if(userGrpList.size() > 0 ){
            for(User userRec : UserRecList){
                User_To_Group__c userTogroupRec = new User_To_Group__c();
                userTogroupRec.User__c = userRec.Id;
                userTogroupRec.User_Group__c = userGrpList[0].Id;
                userToGroupListToInsert.add(userTogroupRec);
    
            }
        }
        if(userToGroupListToInsert.size() > 0 ){
            DMLUtility.insertSobjectList('User_To_Group__c', userToGroupListToInsert);
        }
    }
    
    public static String setFieldFilterJSON(String filerJSON) {
        HomeSearchFilterWrapper obj = new HomeSearchFilterWrapper();
        Map<String, Object> compareToObj = (Map<String, Object>) JSON.deserializeUntyped(system.Json.serialize(obj));
        Map<String, Object> comaparableObj = (Map<String, Object>) JSON.deserializeUntyped(filerJSON);
        
        for(String key : comaparableObj.keySet()) {
            if(!compareToObj.containsKey(key)) comaparableObj.remove(key);
            else {
                if(compareToObj.get(key) == comaparableObj.get(key)) {
                    comaparableObj.remove(key);
                }
            }
        }
        return system.JSON.serialize(comaparableObj);
    }

    public static void onAfterUpdate() {
        if(!Test.isRunningTest()) assignBlackpurlPermissionSetOnUpdate();
        updateRelatedRecords();
    }

    public static void updateRelatedRecords() {
        Set<String> userIdSet =  new Set<String>();
        Set<String> userIdInactiveSet =  new Set<String>();
        for(User userRec : userNewList) {
            if(Trigger.isInsert) {
                userIdSet.add(userRec.Id);
            } else if(!userRec.IsActive && userRec.IsActive != userOldMap.get(userRec.Id).IsActive) {
                userIdInactiveSet.add(userRec.Id);
            } else if(userRec.FirstName != userOldMap.get(userRec.Id).firstName || userRec.LastName != userOldMap.get(userRec.Id).LastName || (userRec.IsActive && userRec.IsActive != userOldMap.get(userRec.Id).IsActive)) {
                userIdSet.add(userRec.Id);
            }
        }
        if(!userIdSet.isEmpty()) UserService.mapUsersWithTechnicians(userIdSet);
        if(!userIdInactiveSet.isEmpty()) {
            UserSettingCtrl.updateTechnicianOnUserDelete(userIdInactiveSet);
            UserService.deleteScheduledReports(userIdInactiveSet);
        }
    }

    private static void assignBlackpurlPermissionSetOnUpdate() {
        List<Id> userIdList =  new List<Id>();
        for(User userRec: userNewList) {
            if(userRec.IsActive && !userOldMap.get(userRec.Id).IsActive) {
                userIdList.add(userRec.Id);
            }
        }
        if(userIdList.size() > 0) assignBlackpurlPermissionSet(userIdList, true);
    }

    @future
    private static void assignBlackpurlPermissionSet(List<Id> userIdList, Boolean isUpdate) {
        List<PermissionSet> bpPermissionList = [SELECT Id FROM PermissionSet WHERE Name = :Constants.BP_PERMISSION_SET_NAME Order By CreatedDate DESC];
        if(bpPermissionList.size() == 0) return;

        Set<Id> alreadyAssignedUserIdSet = new Set<Id>();
        if(isUpdate) {
            for(PermissionSetAssignment permSetAssRec: [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :bpPermissionList[0].Id AND AssigneeId IN: userIdList]) {
                alreadyAssignedUserIdSet.add(permSetAssRec.AssigneeId);
            }
        }
        List<SObject> permissionSetAssList = new List<SObject>();
        for(Id userId: userIdList) {
            if(!alreadyAssignedUserIdSet.contains(userId)) {
                sObject permissionSetAssignmentRec = Schema.getGlobalDescribe().get('PermissionSetAssignment').newSObject();
                permissionSetAssignmentRec.put('PermissionSetId', bpPermissionList[0].Id);
                permissionSetAssignmentRec.put('AssigneeId', userId);
                permissionSetAssList.add(permissionSetAssignmentRec);
            }
        }
        DMLUtility.insertSObjectList('PermissionSetAssignment', permissionSetAssList);
    }

    @future
    private static void assignMFAPermissionSet(List<Id> userIdList) {
        MFAService.enableMFA(userIdList);
    }

    public static void addRemovePackageLicense() {
        Set<Id> newActiveUsersIdSet = new Set<Id>();
        Set<Id> deactivatedUsersIdSet = new Set<Id>();
        for(User userRec: userNewList) {
            if(userRec.IsActive) {
                if(userOldMap == null || !userOldMap.get(userRec.Id).IsActive) {
                    newActiveUsersIdSet.add(userRec.Id);
                }
            } else if(userOldMap != null && userOldMap.get(userRec.Id).IsActive) {
                deactivatedUsersIdSet.add(userRec.Id);
            }
        }
        if(!newActiveUsersIdSet.isEmpty() || !deactivatedUsersIdSet.isEmpty()) {
        	UserService.addRemovePackageLicense_future(newActiveUsersIdSet, deactivatedUsersIdSet);
        }
    }
}
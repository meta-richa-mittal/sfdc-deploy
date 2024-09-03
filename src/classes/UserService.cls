public without sharing class UserService {
    
    public static void checkLicenseLimit() {
        if(!AccessControl.ifObjectFieldIsAccessible('PackageLicense')){throw new BlackPurlException('PackageLicense' + Constants.OBJIECT_NOT_ACCESSIBLE); }
        String nameSpace = GeneralConfiguration.getPackageNamespace();
        List<PackageLicense> pkgLicenceList = [Select Id, Status, AllowedLicenses, UsedLicenses, NamespacePrefix, ExpirationDate From PackageLicense Where NamespacePrefix =: nameSpace];
        for(PackageLicense pkgLicence: pkgLicenceList) {
            if( pkgLicence.AllowedLicenses > 0 && pkgLicence.AllowedLicenses <= pkgLicence.UsedLicenses) { throw new BlackPurlException('You have reached the adding user limit.'); }
        }
    }
    
    public static List<PackageLicense> getBPPackageLicense(String nameSpace) {
        if(!AccessControl.ifObjectFieldIsAccessible('PackageLicense')) { throw new BlackPurlException('PackageLicense' + Constants.OBJIECT_NOT_ACCESSIBLE); }
        return [Select Id, Status, AllowedLicenses, UsedLicenses, NamespacePrefix, ExpirationDate From PackageLicense Where NamespacePrefix =: nameSpace];
    }
    
    @future
	public static void addRemovePackageLicense_future(Set<Id> newActiveUsersIdSet, Set<Id> deactivatedUsersIdSet) {
        String namespace = GeneralConfiguration.getPackageNamespace();
        if(String.isNotBlank(namespace)) {
            String pkgLicenseId;
            List<SObject> userPKGLicenseDeleteList = new List<SObject>();
            if(!AccessControl.ifObjectFieldIsAccessible('UserPackageLicense')){throw new BlackPurlException('UserPackageLicense' + Constants.OBJIECT_NOT_ACCESSIBLE); }
    		for(UserPackageLicense userPkgLicense : [SELECT Id, PackageLicenseId, UserId FROM UserPackageLicense 
            WHERE PackageLicense.NamespacePrefix =: namespace AND PackageLicense.AllowedLicenses > 0 AND (UserId IN: newActiveUsersIdSet OR UserId IN: deactivatedUsersIdSet)]) {
                pkgLicenseId = userPkgLicense.PackageLicenseId;
                if(newActiveUsersIdSet.contains(userPkgLicense.UserId)) {
                    newActiveUsersIdSet.remove(userPkgLicense.UserId);
                } else if(deactivatedUsersIdSet.contains(userPkgLicense.UserId)) {
                    userPKGLicenseDeleteList.add(userPkgLicense);
                }
            }
            if(!userPKGLicenseDeleteList.isEmpty()) {
                if(AccessControl.ifObjectIsDeletable('UserPackageLicense') == false) { throw new BlackPurlException('UserPackageLicense' + Constants.OBJIECT_NOT_DELETABLE); }
                delete userPKGLicenseDeleteList;
            }
            if(!newActiveUsersIdSet.isEmpty()) {
                if(String.isBlank(pkgLicenseId)) {
                    for(PackageLicense pkgLicenceRec : UserService.getBPPackageLicense(namespace)) {
                        if(pkgLicenceRec.AllowedLicenses > 0) pkgLicenseId = pkgLicenceRec.Id;
                    }
                }
                if(String.isNotBlank(pkgLicenseId)) {
                    List<SObject> userPkgLicenseInsertList = new List<SObject>();
                    for(Id activeUserId : newActiveUsersIdSet) {
                        sObject userPkgLicenseRec = Schema.getGlobalDescribe().get('UserPackageLicense').newSObject();
                        userPkgLicenseRec.put('UserId', activeUserId);
                        userPkgLicenseRec.put('PackageLicenseId', pkgLicenseId);
                        userPkgLicenseInsertList.add(userPkgLicenseRec);
                    }
                    if(!userPkgLicenseInsertList.isEmpty()) {
                    	if(AccessControl.ifObjectFieldIsCreateable('UserPackageLicense') == false) { throw new BlackPurlException('UserPackageLicense' + Constants.OBJIECT_NOT_CREATEABLE); }
    					insert userPkgLicenseInsertList;
                    }
                }
            }
        }
    }
    
    @future
    public static void mapUsersWithTechnicians(Set<String> userIdSet) {
        List<User> userList = [SELECT Name, LastName, FirstName, (SELECT Id FROM Technicians__r Limit 1) FROM User WHERE IsActive = true AND Profile.Name = 'Blackpurl' AND Id IN: userIdSet];
        List<Technician__c> existingTechnicianList = [SELECT First_Name__c, Last_Name__c FROM Technician__c WHERE User__c = null AND First_Name__c != null AND Last_Name__c != null];
        Map<String, String> techNameToIdMap = new Map<String, String>();
        for(Technician__c techRec : existingTechnicianList) {
            techNameToIdMap.put(techRec.First_Name__c.toLowerCase() + ' ' + techRec.Last_Name__c.toLowerCase(), techRec.Id);
        }
        List<Technician__c> techUpsertList = new List<Technician__c>();
        Decimal laborCostPerHour = GeneralConfiguration.getDefaultTechnicianCostingRate();
        for(User userRec : userList) {
            Technician__c techToUpsert = new Technician__c();
            techToUpsert.First_Name__c = userRec.FirstName;
            techToUpsert.Last_Name__c = userRec.LastName;
            techToUpsert.Technician_Name__c = userRec.Name;
            techToUpsert.Active__c = true;
            techToUpsert.User__c = userRec.Id;
            if(userRec.Technicians__r.isEmpty()) {
                if(techNameToIdMap.containsKey(userRec.Name.toLowerCase())) {
                    techToUpsert.Id = techNameToIdMap.get(userRec.Name.toLowerCase());
                } else {
                    techToUpsert.Labour_Cost_Per_Hour__c = laborCostPerHour;
                }
            } else {
                if(techNameToIdMap.containsKey(userRec.Name.toLowerCase())) {
                    techToUpsert.Id = techNameToIdMap.get(userRec.Name.toLowerCase());
                    techUpsertList.add(new Technician__c(Id = userRec.Technicians__r[0].Id, User__c = null));
                } else {
                    techToUpsert.Id = userRec.Technicians__r[0].Id;
                }
            }   
            techUpsertList.add(techToUpsert);
        }
        if(!techUpsertList.isEmpty()){
            DMLUtility.upsertSobjectList('Technician__c', techUpsertList);
        }
    }

    @future
    public static void deleteScheduledReports(Set<String> userIdSet) {
        List<User> userList = [SELECT Id, Email FROM User WHERE Id IN: userIdSet];
        Set<String> inactiveUserEmailSet = new Set<String>();
        for(User userRec: userList) {
            inactiveUserEmailSet.add(userRec.Email);
        }

        List<Filter__c> filterList = [SELECT Email_Addresses__c, (SELECT Id, File_Name__c FROM GE_File_Configs__r) FROM Filter__c WHERE Email_Addresses__c != null AND Is_Report_Scheduled__c = true];
        List<GE_File_Config__c> fileConfigListToDelete = new List<GE_File_Config__c>();
        for(Filter__c filterRec: filterList) {
            if(String.isNotBlank(filterRec.Email_Addresses__c)) {
                String updatedEmailStr = '';
                for(String email: filterRec.Email_Addresses__c.split(',')) {
                    email = email.trim();
                    if(String.isNotBlank(email) && !inactiveUserEmailSet.contains(email)) {
                        updatedEmailStr += (email + ',');
                    }
                }
                if(String.isBlank(updatedEmailStr)) {
                    HSReportSchedulingService.resetScheduleRelatedFilterFields(filterRec);
                    fileConfigListToDelete.addAll(filterRec.GE_File_Configs__r);
                } else {
                    updatedEmailStr = updatedEmailStr.substring(0, updatedEmailStr.length() - 1);
                }
                filterRec.Email_Addresses__c = updatedEmailStr;
            }
        }
        DMLUtility.updateSobjectList('Filter__c', filterList);
        if(!fileConfigListToDelete.isEmpty()) {
            HSReportSchedulingService.deleteScheduleRelatedConfig(fileConfigListToDelete);
        }
    }

    public static void createFilters(List<Id> usersNewList) {
        Map<Id, Map<String, Filter__c>> userIdToFilterNameToRecMap = new Map<Id, Map<String, Filter__c>>();
        List<Filter__c> existingFilterList = [Select Id, Filter_User__c, Filter_Label__c from Filter__c where Common__c = true OR Reconciliation__c = TRUE OR Filter_Label__c = :CommonFiltersService.RECENT_RECORDS];
        for(Filter__c filterRec: existingFilterList) {
            if(!userIdToFilterNameToRecMap.containsKey(filterRec.Filter_User__c)) {
                userIdToFilterNameToRecMap.put(filterRec.Filter_User__c, new Map<String, Filter__c>());
            }
            Map<String, Filter__c> filterNameToRecMap = userIdToFilterNameToRecMap.get(filterRec.Filter_User__c);
            filterNameToRecMap.put(filterRec.Filter_Label__c, filterRec);
            userIdToFilterNameToRecMap.put(filterRec.Filter_User__c, filterNameToRecMap);
        }
        List<Filter__c> filterList = new List<Filter__c>();
        List<Filter__c> filterListToDelete = new List<Filter__c>();
        List<Widget_User_Junction__c> widgetUserListToInsert =  new List<Widget_User_Junction__c>();
        for(Id userId: usersNewList) {
            for(String commonFilterName: CommonFiltersService.commonFilterNamesSet) {
                String filterId;
                if(userIdToFilterNameToRecMap.containsKey(userId) && userIdToFilterNameToRecMap.get(userId) != null && userIdToFilterNameToRecMap.get(userId).containsKey(commonFilterName)) {
                    filterId = userIdToFilterNameToRecMap.get(userId).get(commonFilterName).Id;
                    userIdToFilterNameToRecMap.get(userId).remove(commonFilterName);
                }
                filterList.add(CommonFiltersService.insertFilter(commonFilterName, false, true, false, false, userId, filterId));
            }

            for(String reconciliationFilterName: CommonFiltersService.reconciliationFilterNamesSet) {
                String filterId;
                if(userIdToFilterNameToRecMap.containsKey(userId) && userIdToFilterNameToRecMap.get(userId) != null && userIdToFilterNameToRecMap.get(userId).containsKey(reconciliationFilterName)) {
                    filterId = userIdToFilterNameToRecMap.get(userId).get(reconciliationFilterName).Id;
                    userIdToFilterNameToRecMap.get(userId).remove(reconciliationFilterName);
                }
                filterList.add(CommonFiltersService.insertFilter(reconciliationFilterName, false, false, false, true, userId, filterId));
            }

            String recentRecordFilterId;
            if(userIdToFilterNameToRecMap.containsKey(userId) && userIdToFilterNameToRecMap.get(userId) != null && userIdToFilterNameToRecMap.get(userId).containsKey(CommonFiltersService.RECENT_RECORDS)) {
                recentRecordFilterId = userIdToFilterNameToRecMap.get(userId).get(CommonFiltersService.RECENT_RECORDS).Id;
                userIdToFilterNameToRecMap.get(userId).remove(CommonFiltersService.RECENT_RECORDS);
            }
            filterList.add(CommonFiltersService.insertFilter(CommonFiltersService.RECENT_RECORDS, false, false, true, false, userId, recentRecordFilterId));
            if(userIdToFilterNameToRecMap.containsKey(userId) && userIdToFilterNameToRecMap.get(userId) != null) {
                filterListToDelete.addAll(userIdToFilterNameToRecMap.get(userId).values());
            }
        }
        DMLUtility.deleteSobjectList('Filter__c', filterListToDelete);
        DMLUtility.upsertSobjectList('Filter__c', filterList);
    }
}

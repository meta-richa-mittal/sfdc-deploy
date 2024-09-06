/** 
* Author: Tarun Khandelwal
* Since: Aug 26, 2019 
* Name: LocationManagementService 
* Description: Apex class which contains all service methods related to Location management Page.
**/
public without sharing class LocationManagementService {
    
    public static List<LocationWrapper> getActiveLocationList() {
        List<LocationWrapper> locationWrapperList = new List<LocationWrapper>();
        for(Location__c tagRec : LocationManagementSOQLUtil.getLocationList(new Map<String, Object>{'Active__c' => true})){
            locationWrapperList.add(new LocationWrapper(tagRec)); 
        }
        return locationWrapperList;
    }
    
    public static String saveLocation(String locationJSONString) {
        String errorMessage = '';
        LocationWrapper locationObj = (LocationWrapper) System.JSON.deserialize(locationJSONString, LocationWrapper.class);
        try {
            if(String.isNotBlank(locationObj.Name)) {
                List<Location__c> locationList;
                if(locationObj.Id != null) {
                    if(!AccessControl.ifObjectFieldIsAccessible('Location__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
                    locationList = [SELECT Name__c FROM Location__c WHERE Id =: locationObj.Id];
                }
                Location__c locationRec = new Location__c(Id = locationObj.Id);
                locationRec.Name__c = locationObj.Name;
                locationRec.Active__c = (locationObj.IsActive != null) ? locationObj.IsActive : false;
                
                if(!AccessControl.ifObjectFieldIsUpdateable('Location__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                if(!AccessControl.ifObjectFieldIsCreateable('Location__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                upsert locationRec;
                if(locationObj.Id != null && locationList.size() > 0) {
                    replaceLocationFromSobjects(locationList[0].Name__c, locationObj.Name);
                }
            }
        } catch(Exception e) {
            return System.JSON.serialize(new ResponseWrapper('Error', 'Location - ' + locationObj.Name + ' already exists.'));
        }
        return errorMessage;
    }
    
    public static void removeLocation(String locationJSONString) {
        LocationWrapper locationObj = (LocationWrapper) System.JSON.deserialize(locationJSONString, LocationWrapper.class);
        
        if(String.isNotBlank(locationObj.Id)) {
            Location__c locationRec = new Location__c(Id = locationObj.Id);
            if(!AccessControl.ifObjectIsDeletable('Location__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete locationRec;
        }
        removeLocationFromSobjects(locationObj.Name);
    }
    
    public static void removeLocationFromSobjects(String locationNameToRemove) {
        List<Sobject> sobjectList = getSObjectListWhereLocationIsUsed(locationNameToRemove, new List<String>{'Part__c'});
        removeLocationFromSobjectList(locationNameToRemove, sobjectList);
    }
    
    public static void replaceLocationFromSobjects(String oldLocationName, String newLocationName) {
        List<Sobject> sobjectList = getSObjectListWhereLocationIsUsed(oldLocationName, new List<String>{'Part__c'});
        replaceTagFromSobjectList(oldLocationName, newLocationName, sobjectList);
    }
    
    public static List<Sobject> getSObjectListWhereLocationIsUsed(String locationName, List<String> objectAPIList) {
        List<Sobject> sobjList = new List<Sobject>();
        if(objectAPIList.size() < 3) {
            for(String objectAPIName : objectAPIList) {
                sobjList.addAll(getSObjectListWhereLocationIsUsed(locationName, objectAPIName));
            }
        }
        return sobjList;
    }
    
    public static List<Sobject> getSObjectListWhereLocationIsUsed(String locationName, String objectAPIName) {
        String query = 'SELECT Assigned_Location_1__c, Assigned_Location_2__c FROM ' + objectAPIName + 
                        ' WHERE Assigned_Location_1__c LIKE \'%;'+ locationName + ';%\' ' + 
                        ' OR Assigned_Location_2__c LIKE \'%;'+ locationName + ';%\' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }
    
    public static void removeLocationFromSobjectList(String locationName, List<Sobject> sobjectList) {
        updateRelatedSobjectList(locationName, ';', sobjectList);
    }
    
    public static void replaceTagFromSobjectList(String oldLocationName, String newLocationName, List<Sobject> sobjectList) {
        updateRelatedSobjectList(oldLocationName, ';' + newLocationName + ';', sobjectList);
    }
    
    private static void updateRelatedSobjectList(String oldLocationName, String newLocationName, List<Sobject> sobjectList) {
        for(Sobject sobj : sobjectList) {
            String assignedLocation1 = (sobj.get('Assigned_Location_1__c') != null) ? String.valueOf(sobj.get('Assigned_Location_1__c')) : '';
            if(assignedLocation1.contains(';' + oldLocationName + ';')) {
                assignedLocation1 = assignedLocation1.replace(';' + oldLocationName + ';', newLocationName);
            }
            String assignedLocation2 = (sobj.get('Assigned_Location_2__c') != null) ? String.valueOf(sobj.get('Assigned_Location_2__c')) : '';
            if(assignedLocation2.contains(';' + oldLocationName + ';')) {
                assignedLocation2 = assignedLocation2.replace(';' + oldLocationName + ';', newLocationName);
            }
            sobj.put('Assigned_Location_1__c', assignedLocation1);
            sobj.put('Assigned_Location_2__c', assignedLocation2);
        }
        if(sobjectList.size() > 0) {
            update sobjectList;
        }
    }
    
    public static String getLocationUsedCounter(String locationJSONString) {
        LocationWrapper locationObj = (LocationWrapper) System.JSON.deserialize(locationJSONString, LocationWrapper.class);
        Integer locationUsedCounter = 0;
        if(String.isNotBlank(locationObj.Name)) {
            locationUsedCounter = getSObjectListWhereLocationIsUsed(locationObj.Name, new List<String>{'Part__c'}).size();
        }
        return '{"UsedCounter" : ' + locationUsedCounter + '}';
    }
    
    public static List<String> getLocationsList(Sobject sobj) {
        List<String> locationList = new List<String>();
        locationList.addAll(TagUtil.convertStringIntoList(sobj, 'Assigned_Location_1__c'));
        locationList.addAll(TagUtil.convertStringIntoList(sobj, 'Assigned_Location_2__c'));
        return locationList;
    }
    
    public static String getLocationsListString(Sobject sobj) {
    	List<String> allLocationList = LocationManagementService.getLocationsList(sobj);
		return string.join(allLocationList,',').trim();
    }

    public static List<LocationWrapper> getPaginatedLocationList(LocationWrapper.PaginatedLocation locationObj) {
        List<LocationWrapper> locationWrapperList = new List<LocationWrapper>();
        for(Location__c tagRec : LocationManagementSOQLUtil.getPaginatedLocationList(locationObj)){
            locationWrapperList.add(new LocationWrapper(tagRec)); 
        }
        return locationWrapperList;
    }

    public static Integer getTotalLocationCount() {
        return LocationManagementSOQLUtil.getTotalLocationCount();
    }

    public static List<Location__c> createNewLocations(Set<String> locationNameSet) {
        Set<String> existingLocationSet = new Set<String>();
        for(Location__c locationRec : [Select Id,Name__c from Location__c where Name__c IN:locationNameSet AND Name__c != null]){
            existingLocationSet.add(locationRec.Name__c.trim().toLowerCase());
        }
        List<Location__c> locationInsertList = new List<Location__c>();
        for(String locationNameStr : locationNameSet){
            if(!existingLocationSet.contains(locationNameStr.trim().toLowerCase())) {
                locationInsertList.add(new Location__c(Name__c = locationNameStr));
            }
        }
        DMLUtility.insertSobjectList('Location__c', locationInsertList);
        return locationInsertList;
    }
}
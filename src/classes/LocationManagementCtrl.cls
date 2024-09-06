/** 
* Author: Tarun Khandelwal
* Since: Aug 26, 2019 
* Name: LocationManagementCtrl 
* Description: Apex class which contains all remoted methods related to Location management Page.
**/
global without sharing class LocationManagementCtrl {
    
    global LocationManagementCtrl (NewHomePageCtrl controller){}
    public LocationManagementCtrl() {}
    
    @RemoteAction
    global static String getLocationList() {
        return '';
    }
    
    @RemoteAction
    global static String saveLocation(String locationJSONString) {
        locationJSONString = BPUtility.getDecodedString(locationJSONString);
        try {
            String errorMessage = LocationManagementService.saveLocation(locationJSONString);
            if(String.isNotBlank(errorMessage)) {
                return BPUtility.getEncodedString(errorMessage);
            } else {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('Success', 'Success')));
            }
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getLocationUsedCounter(String locationJSONString) {
        locationJSONString = BPUtility.getDecodedString(locationJSONString);
        try {
            return BPUtility.getEncodedString(LocationManagementService.getLocationUsedCounter(locationJSONString));                
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String removeLocation(String locationJSONString) {
        locationJSONString = BPUtility.getDecodedString(locationJSONString);
        try {
            LocationManagementService.removeLocation(locationJSONString);
            return 'Success';                
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getPaginatedLocationList(String locationJSONString) {
        try {
            LocationWrapper.PaginatedLocation locationObj = (LocationWrapper.PaginatedLocation) System.JSON.deserialize(BPUtility.getDecodedString(locationJSONString), LocationWrapper.PaginatedLocation.class);
            return BPUtility.getEncodedString(system.JSON.serialize(LocationManagementService.getPaginatedLocationList(locationObj), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static Integer getTotalLocationCount() {
        try {
            return LocationManagementService.getTotalLocationCount();                
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
}
public without sharing class LoggedInDeviceService {
    
    public static void saveDeviceInfo(String loggedInDeviceJson) {
    	LoggedInDeviceWrapper loggedInDeviceObj = (LoggedInDeviceWrapper) System.JSON.deserialize(loggedInDeviceJson, LoggedInDeviceWrapper.class);
		if(String.isBlank(loggedInDeviceObj.UUID)) {
    		throw new BlackpurlException('UUID not specified');
    	}
        Logged_In_Device__c loggedInDeviceRec = setLoggedInDeviceFields(loggedInDeviceObj);
        
        if(String.isBlank(loggedInDeviceRec.Id)) {
            if(AccessControl.ifObjectFieldIsAccessible('Logged_In_Device__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Logged_In_Device__c> loggedInDeviceRecList = [Select Id from Logged_In_Device__c where Name =: loggedInDeviceRec.Name];
            if(loggedInDeviceRecList.size() > 0) {
                loggedInDeviceRec.Id = loggedInDeviceRecList[0].Id;
            }
        }
        DMLUtility.upsertSobjectList('Logged_In_Device__c', loggedInDeviceRec);
    }
    
    public static Logged_In_Device__c setLoggedInDeviceFields(LoggedInDeviceWrapper loggedInDeviceObj) {
        Logged_In_Device__c loggedInDeviceRec = new Logged_In_Device__c();
        loggedInDeviceRec.Id = loggedInDeviceObj.Id;
        loggedInDeviceRec.Name = loggedInDeviceObj.UUID;
        if(String.isNotBlank(loggedInDeviceObj.BusinessLocationId)) {
        	loggedInDeviceRec.Branding_Location__c = loggedInDeviceObj.BusinessLocationId;
        }
        if(String.isNotBlank(loggedInDeviceObj.CashDrawerId)) {
        	loggedInDeviceRec.Cash_Drawer__c = loggedInDeviceObj.CashDrawerId;
        }
        return loggedInDeviceRec;
    }
    
    public static LoggedInDeviceWrapper getDeviceInfoByDeviceUUID(String UUID) {
        if(AccessControl.ifObjectFieldIsAccessible('Logged_In_Device__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Logged_In_Device__c> loggedInDeviceRecList = [Select Id, Name, Cash_Drawer__r.Active__c, Branding_Location__c, Branding_Location__r.Business_Location_Name__c, Cash_Drawer__c, 
        								Cash_Drawer__r.Name from Logged_In_Device__c where Name =: UUID];
        
        if(loggedInDeviceRecList.size() > 0) {
            return new LoggedInDeviceWrapper(loggedInDeviceRecList[0]);
        }
        return null;
    }
}
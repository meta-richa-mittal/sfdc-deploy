/**
 * Author: Nidhi Sharma
 * Since: Jul 06, 2019
 * Name: BPConfigurationsService
 * Description: Apex class to return all the custom fields of BP Configurations
 **/
 public without sharing class BPConfigurationsService {
    
    public static String getSFUsername() {
        if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BP_Configurations__c.getOrgDefaults().SF_Username__c;
    }
    
    public static String getSFPassword() {
        if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BP_Configurations__c.getOrgDefaults().SF_Password__c;
    }
    
    public static Boolean isBypassValidation() {
        if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BP_Configurations__c.getOrgDefaults().Bypass_Validation__c;
    }
}
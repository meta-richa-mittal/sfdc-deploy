/**
* Author: Manoj Sharma
* Since: Dec 14, 2022
* Name: MFAAuthService 
* Description: Apex class which contains all methods related to multifactor authentication in Salesforce.
**/
public without sharing class MFAService {

    public static void enableMFA(String userId) {
        enableMFA(new List<Id>{userId});
    }

    public static void enableMFA(List<Id> userIdList) {
        List<PermissionSet> permissionSetList = [SELECT Id, Name FROM PermissionSet where Name = :UserSettingCtrl.ENABLE_MFA AND NamespacePrefix = Null Limit 1];
        if(permissionSetList.isEmpty()) {
            throw new BlackPurlException('Permission set is missing for Multi-factor Authentication.');
        }

        List<SObject> permissionSetAssList = new List<SObject>();
        for(Id userId: userIdList) {
            sObject permissionSetAssignmentRec = Schema.getGlobalDescribe().get('PermissionSetAssignment').newSObject();
            permissionSetAssignmentRec.put('PermissionSetId', permissionSetList[0].Id);
            permissionSetAssignmentRec.put('AssigneeId', userId);
            permissionSetAssList.add(permissionSetAssignmentRec);
        }
        DMLUtility.insertSObjectList('PermissionSetAssignment', permissionSetAssList);
    }

    public static void disableMFA(String userId) {
        List<SObject> assignedPermissionSetList = [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = :UserSettingCtrl.ENABLE_MFA];
        if(!assignedPermissionSetList.isEmpty()) {
            delete assignedPermissionSetList;
            deregisterMFAVerificationMethod(userId);
        }
    }

    public static Boolean isMFAVerificationMethodRegistered(String userId) {
        List<TwoFactorMethodsInfo> twoFactorMethodsInfo = [SELECT HasSalesforceAuthenticator, HasTotp FROM TwoFactorMethodsInfo where UserId = :userId];
        return !twoFactorMethodsInfo.isEmpty() && (twoFactorMethodsInfo[0].HasSalesforceAuthenticator || twoFactorMethodsInfo[0].HasTotp);
    }

    public static void deregisterMFAVerificationMethod(String userId) {
        try{
            UserManagement.deregisterVerificationMethod(userId, Auth.VerificationMethod.TOTP);
        } catch(InvalidParameterValueException e) {}

        try{
            UserManagement.deregisterVerificationMethod(userId, Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        } catch(InvalidParameterValueException e) {}
    }
}
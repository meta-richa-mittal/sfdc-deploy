/**
 * Author: Richa Mittal
 * Since: May 10, 2022
 * Name: EscalatorSOQLUtil
 * Description: EscalatorSOQLUtil class.
**/
public without sharing class EscalatorSOQLUtil {
    
    public static List<Escalator__c> getEscalatorsForVendors(Set<String> vendorIdSet) {
        String query = 'SELECT ' + String.join(Escalator.getFieldList(), ',');
        query += ' FROM Escalator__c WHERE Vendor__c IN :vendorIdSet AND Type__c = \'' + EscalatorUtil.TYPE_RETAIL + '\'';
        if(!AccessControl.ifObjectFieldIsAccessible('Escalator__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static Map<Id, Account> getVendorWithEscalators(Set<Id> vendorIdSet) {
        String query = 'SELECT Id, Retail_Base_Value__c, Retail_Rounding__c, Retail_Round_To__c,';
        query += ' (SELECT ' + String.join(Escalator.getFieldList(), ',');
        query += ' FROM Escalators__r WHERE Type__c = \'' + EscalatorUtil.TYPE_RETAIL + '\')';
        query += ' FROM Account WHERE Id IN :vendorIdSet AND Is_Calculate_Part_Retail_Price__c = true';
        if(!AccessControl.ifObjectFieldIsAccessible('Escalator__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(!AccessControl.ifObjectFieldIsAccessible('Account')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return new Map<Id, Account>((List<Account>)Database.query(query));
    }
}
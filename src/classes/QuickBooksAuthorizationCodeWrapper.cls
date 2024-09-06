/**
 * Author: Manoj Sharma
 * Since: April 23, 2020
 * Name: QuickBooksAuthorizationCodeWrapper
 * Description: Apex  wrapper class to set client id and secret for QuickBooks 
**/
public without sharing class QuickBooksAuthorizationCodeWrapper {
    public String ClientId;
    public String ClientSecret;
    
    public QuickBooksAuthorizationCodeWrapper() {}

    public QuickBooksAuthorizationCodeWrapper(IFW_IntegrationConfig__c ifwConfig) {
        this.ClientId = ifwConfig.Client_Id_Long__c;
        this.ClientSecret = ifwConfig.Client_Secret_Long__c;
    }
}
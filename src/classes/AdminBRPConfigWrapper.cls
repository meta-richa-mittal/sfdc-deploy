/**
 * Author: Richa Mittal
 * Since: June 30, 2022
 * Name: AdminBRPConfigWrapper
**/
public without sharing class AdminBRPConfigWrapper {

    public String IntegrationConfigured = 'No';
    public String DealerId; 
    public String RadiusMeasure = 'mile';
    public Integer Radius = 100;
    public String CurrencyCode;
    public String DealershipUserName;
    public String DealershipPassword;
    public List<BRPIdentifier> BRPIdentifierList; 
    public Boolean BRPPOAuthorized;
    public Boolean Enabled = false;
    public String BRPUserName = 'BLACKPURL';
    public String BRPPassword = '0z4aDe2dmAbaHZzqp9ZaR33hGcDlfkxx';
    public String OAuth2ClientId = '3MVG99OxTyEMCQ3jsPoYvkLnL8vd7KvzjjrdzyWXFRbyEauXAg.V8PySz93f45KjdRL6bG6JLBSsIR.lwOHfJ';
    public String OAuth2ClientSecret = 'CED9EE310703CFF36B2F4F44CCB40BE290B9CF1B8F960756B3C5C67816DE939B';
    public String DMSOAuth2ClientId = '0z4aDe2dmAbaHZzqp9ZaR33hGcDlfkxx';
    public String DMSOAuth2ClientSecret = 'AtfonuIh28Q1HLYV';
    public String DMSOAuth2AccessToken = '';
    public Boolean BRPPOEnabled = false;

    public AdminBRPConfigWrapper() {}

    public AdminBRPConfigWrapper(BRP_Settings__c brpSettingsRec, BP_Configurations__c bpConfigRec, Map<String, BRP_Vendors_List__c> brpIdentifierMap, Map<String, SObject> brpIdentifierSFIdToRecMap) {
        this.DealerId = brpSettingsRec.Dealer_Id__c;
        this.CurrencyCode = brpSettingsRec.Currency_Code__c != null ? brpSettingsRec.Currency_Code__c : 'USD';
        this.DealershipUserName = BPUtility.getDecodedString(bpConfigRec.SF_Username__c);
        this.DealershipPassword = BPUtility.getDecodedString(bpConfigRec.SF_Password__c);
        this.BRPIdentifierList = new List<BRPIdentifier>();
        if(brpIdentifierList != null) {
            for(String brpIdentifierSFId: brpIdentifierMap.keySet()) {
                BRP_Vendors_List__c brpIdentifierRec = brpIdentifierMap.get(brpIdentifierSFId);
                if(this.BRPPOEnabled && brpIdentifierRec.Is_Used_For_Parts_Master__c && brpIdentifierRec.Is_Used_For_Parts_Ordering__c) {
                    this.BRPPOEnabled = true;
                }
                this.BRPIdentifierList.add(new BRPIdentifier(brpIdentifierRec, brpIdentifierSFIdToRecMap.get(brpIdentifierSFId)));
            }
        }

        if(!(Constants.NAMESPACE).equalsIgnoreCase('BlackPurlCore__')) {
            this.BRPPassword = 'K60mYH8mcbsYxxzKomIJTKt11uhGNwUz';
            this.OAuth2ClientId = '3MVG9PG9sFc71i9nECwhTwPw88sr1kAcjoMKU1KNrRsvwwboaePeNl23DL9esLIkIKq1kviHxZ36WN3_Zi3K8';
            this.OAuth2ClientSecret = '655CEFB829C45BC8EE45D367ED7906EB5DF9282EEA8266CB8EBABAB2103AE9BB';
            this.DMSOAuth2ClientId = 'K60mYH8mcbsYxxzKomIJTKt11uhGNwUz';
            this.DMSOAuth2ClientSecret = 'EQVTDmAWVNC3aP2K';
            this.DMSOAuth2AccessToken = '';
        }
    }

    public class BRPIdentifier {
        public String Type;
        public String IdentifierId;
        public Boolean Active;
        public Boolean UsedForPartsMaster;
        public Boolean UsedForPartsOrdering;
        public String IdentifierName;
        public String Id;

        public BRPIdentifier(BRP_Vendors_List__c brpIdentifierRec, SObject identifierRec) {
            this.Id = brpIdentifierRec.Id;
            this.Type = brpIdentifierRec.Type__c;
            this.IdentifierId = brpIdentifierRec.Name;
            this.Active = brpIdentifierRec.Is_Active_Vendor__c;
            this.UsedForPartsMaster = brpIdentifierRec.Is_Used_For_Parts_Master__c;
            this.UsedForPartsOrdering = brpIdentifierRec.Is_Used_For_Parts_Ordering__c;
            this.IdentifierName = identifierRec != null ? (String)identifierRec.get('Name') : '';
        }
    }
}
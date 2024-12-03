/** Author: Nidhi Sharma
 * Since: Dec 18, 2023
 * Name: ContactShippingDetailUpdateBatch
**/
global without sharing class ContactShippingDetailUpdateBatch extends PostInstallScriptBaseBatch {

    global ContactShippingDetailUpdateBatch() {
        this.scriptName = 'executeContactShippingDetailUpdateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        Set<String> countrySet = DataLoadForCountryState.countryToStateToCodeMap.keyset();
        String strQuery = 'SELECT Id FROM Account WHERE (Is_Customer__c = true OR Is_Vendor__c = true)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> accList) {
        List<Contact> contactUpsertList = new List<Contact>();
        for(Account accRec : [SELECT Id, SA_same_as_BA__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, (Select Id, FirstName, LastName FROM Contacts) FROM Account WHERE Id IN :accList]) {
            for(Contact conRec : accRec.Contacts) {
                conRec.LastName = String.isNotBlank(conRec.FirstName) ? conRec.FirstName + ' ' + conRec.LastName : conRec.LastName;
                conRec.FirstName = null;
                conRec.Is_Contact__c = true;
                contactUpsertList.add(conRec);
            }
            if(hasDifferentShippingAddress(accRec)) {
                Contact conRec = new Contact();
                conRec.AccountId = accRec.Id;
                conRec.LastName = 'Shipping';
                conRec.MailingStreet = accRec.ShippingStreet;
                conRec.MailingCity = accRec.ShippingCity;
                conRec.MailingState = accRec.ShippingState;
                conRec.MailingPostalCode = accRec.ShippingPostalCode;
                conRec.MailingCountry = accRec.ShippingCountry;
                conRec.Is_Shipping_Address__c = true;
                contactUpsertList.add(conRec);
            }
        }
        DMLUtility.upsertSobjectList('Contact', contactUpsertList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Boolean hasDifferentShippingAddress(Account acc) {
        if(acc != null && acc.ShippingCountry != null) {
            if(hasDifferentValue(acc.ShippingStreet, acc.BillingStreet) || hasDifferentValue(acc.ShippingCity, acc.BillingCity) || 
            hasDifferentValue(acc.ShippingState, acc.BillingState) || hasDifferentValue(acc.ShippingPostalCode, acc.BillingPostalCode) || 
            hasDifferentValue(acc.ShippingCountry, acc.BillingCountry)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean hasDifferentValue(String text1, String text2) {
        text1 = String.isNotBlank(text1) ? text1.trim().toLowerCase() : null;
        text2 = String.isNotBlank(text2) ? text2.trim().toLowerCase() : null;
        return (text1 != text2);
    }
}
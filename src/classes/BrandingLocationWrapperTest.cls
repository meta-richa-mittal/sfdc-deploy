@isTest
private class BrandingLocationWrapperTest {
    
    @testSetup
    private static void setup(){
        Branding_Location__c brandingLocationRec = new Branding_Location__c();
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        insert brandingLocationRec;
        insert BusinessProfileRec;
    }
    
    @isTest
    private static void testBrandingLocationWrapperMethods(){
    	Test.startTest();
        String query;   
        query = 'SELECT '; 
        for(String fieldsName : BrandingLocationWrapper.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Branding_Location__c ';

        List<Branding_Location__c> brandingLocationRec = Database.query(query);
        String JSONStr = System.JSON.serialize(brandingLocationRec);
        List<BrandingLocationWrapper> packageItemObj = (List<BrandingLocationWrapper>) System.JSON.deserialize(JSONStr, List<BrandingLocationWrapper>.class);
        BrandingLocationWrapper nonStaticMethods = new BrandingLocationWrapper();
        nonStaticMethods.setAllBrandingLocationFields(brandingLocationRec[0]);
        nonStaticMethods.setBussinessFieldsForBranding(brandingLocationRec[0]);
        query = 'SELECT '; 
        for(String fieldsName : UserSettingCtrl.BUSINESS_PROFILE_FIELDS_TO_JSON_MAPPING.get('Business_Profile__c')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Business_Profile__c ';
        List<Business_Profile__c> BusinessProfileRec = Database.query(query);

        nonStaticMethods.setDefaultBrandingLocation(BusinessProfileRec[0]);
        
        system.assertEquals(1, brandingLocationRec.size());
    	Test.stopTest();
    }
}
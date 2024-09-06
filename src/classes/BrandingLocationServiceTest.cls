@isTest
private class BrandingLocationServiceTest {
    
    @testSetup
    private static void setup(){
        Branding_Location__c brandingLocationRec = new Branding_Location__c(Is_Disclaimer_for_Service_Job__c = true);
        insert brandingLocationRec;
        Business_Profile__c BusinessProfile= new Business_Profile__c();
        insert BusinessProfile;
    }
    
    @isTest
    private static void testBrandingLocationServiceMethods(){
    	Test.startTest();
        List<Branding_Location__c> brandingLocationRec = [select id, Is_Disclaimer_for_Service_Job__c from Branding_Location__c];
        string Ids = string.valueof(brandingLocationRec[0].id);
        string str = '{"Id":"' + Ids + '","BusinessLocationName":"jaipur","BusinessCity":"jaipur","BusinessCountry":"india","BusinessPhone":"9876543245","BusinessEmailAddress":"test@test.com"}';
        BrandingLocationWrapper BrandingLocationWrapperObj = (BrandingLocationWrapper) System.JSON.deserialize(str, BrandingLocationWrapper.class);
        BrandingLocationService.getDefaultBrandingLocation();
        String brandingLocationRecStr = System.JSON.serialize(brandingLocationRec[0]);
        //BrandingLocationService.saveBrandingLocation(brandingLocationRecStr);
        BrandingLocationService.getBrandingLocationList();
        BrandingLocationService.setBrandingLocation(BrandingLocationWrapperObj);
        BrandingLocationService.isBrandingLocationActive(string.valueof(brandingLocationRec[0].id));
        Branding_Location__c brandingLocationRec1 = new Branding_Location__c();
        insert brandingLocationRec1;
        List<Branding_Location__c> brandingLocationRecords = [select id from Branding_Location__c];
        BrandingLocationService.deleteBrandingLocation(brandingLocationRecords[0].id);
        List<Branding_Location__c> result = [select id from Branding_Location__c];
    	system.assertEquals(0, result.size());
    	Test.stopTest();
    }
}
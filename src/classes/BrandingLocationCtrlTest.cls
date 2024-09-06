@isTest
private class BrandingLocationCtrlTest {
    
    @testSetup
    private static void setup(){
        Branding_Location__c brandingLocationRec = new Branding_Location__c();
        insert brandingLocationRec;
        Business_Profile__c BusinessProfile= new Business_Profile__c();
        insert BusinessProfile;
    }
    
    @isTest
    private static void testBrandingLocationCtrlMethods(){
    	Test.startTest();
    	BrandingLocationCtrl.getDefaultBrandingLocation();
        BrandingLocationCtrl.getBrandingLocationMasterData();
        BrandingLocationCtrl.getAllBrandingLocationDetailList();
        BrandingLocationCtrl.getBusinessDetailOfAllBrandingLocations();
        BrandingLocationCtrl.isBrandingLocationActive();
        List<Branding_Location__c> brandingLocationRec = [select id from Branding_Location__c];
        string str = BPUtility.getEncodedString(brandingLocationRec[0].id);
        BrandingLocationCtrl.getBrandingLocationRecordById(str);
        BrandingLocationCtrl.deleteBrandingLocation(str);
        List<Branding_Location__c> result = [select id from Branding_Location__c];
    	system.assertEquals(0, result.size());
    	Test.stopTest();
    }
}
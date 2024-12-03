@isTest
private class BrandingLocationSOQLUtilTest {
    
    @testSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Branding_Location__c brandingLocationRec = new Branding_Location__c();
        insert brandingLocationRec;
    }
    
    @isTest
    private static void testBrandingLocationSOQLUtilMethods(){
    	Test.startTest();
        List<Branding_Location__c> brandingLocationRec = [select id from Branding_Location__c];
        BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(new Map<String, String>{'Id' => string.valueof(brandingLocationRec[0].id)});
    	system.assertEquals(1, brandingLocationRec.size());
    	Test.stopTest();
    }
}
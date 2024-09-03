@isTest
private class BusinessCustomizationTest {
    @TestSetup
    private static void setup(){
        insert new Business_Customization__c(Business_Name__c = 'HHD');
    }
    @isTest
    private static void testBusinessCustomization() {
        Test.startTest();
        Business_Customization__c BusinessCustomizationRec = [Select Id, Business_Name__c, Customize_MMS_Labels__c from Business_Customization__c Limit 1][0];
        BusinessCustomization BusinessCustomizationObj = new BusinessCustomization(BusinessCustomizationRec);
        system.assertEquals(false, BusinessCustomizationObj.IsMMSFieldLabelsCustomized);
        Test.stopTest();
    }
}
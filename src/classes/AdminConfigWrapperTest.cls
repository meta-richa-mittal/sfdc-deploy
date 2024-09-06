@IsTest
private class AdminConfigWrapperTest {
    
    @IsTest
    private static void UnitDataFieldConfigWrapperTest(){
        String Id='1010001';
        String Name = 'Test Name';
        String displayLabel = 'Test Label'; 
        Test.startTest();
        AdminConfigWrapper.UnitDataFieldConfigWrapper wrapper = new AdminConfigWrapper.UnitDataFieldConfigWrapper(Id,Name,displayLabel);
        Test.stopTest();
        System.assertEquals(Id, wrapper.Id);
        System.assertEquals(Name, wrapper.Name);
        System.assertEquals(displayLabel, wrapper.DisplayLabel);
    }
}
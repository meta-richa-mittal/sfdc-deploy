@IsTest
private class AbbreviationsUtilTest {
 
    @IsTest
    private static void getStateAbbreviationToStateMapTest(){  
        Test.startTest();
        Map<String,String> result = AbbreviationsUtil.getStateAbbreviationToStateMap();
        Test.stopTest();
        System.assertEquals('Northern Territory',result.get('Australia^&&^NT'));
        System.assertNotEquals(null, result);
    }    
    @IsTest
    private static void getStateNameByAbbreviationsTest(){
        Test.startTest();
        String result = AbbreviationsUtil.getStateNameByAbbreviations('Australia','NT'); 
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    @IsTest
    private static void getStateNameByAbbreviationsNegTest(){
        Test.startTest();
        String result = AbbreviationsUtil.getStateNameByAbbreviations('India','Ind');
        Test.stopTest();
        System.assertEquals('Ind',result);
    }
}
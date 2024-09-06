@IsTest
private class AdminConfigUtilTest {

    @IsTest
    private static void testUnitDataFieldNameMap() {
        Map<String, String> expectedMap = new Map<String, String>{
            'Unit Data 01' => 'Unit data field 1',
            'Unit Data 02' => 'Unit data field 2',
            'Unit Data 03' => 'Unit data field 3',
            'Unit Data 04' => 'Unit data field 4',
            'Unit Data 05' => 'Unit data field 5',
            'Unit Data 06' => 'Unit data field 6',
            'Unit Data 07' => 'Unit data field 7',
            'Unit Data 08' => 'Unit data field 8',
            'Unit Data 09' => 'Unit data field 9',
            'Unit Data 10' => 'Unit data field 10',
            'Unit Data 11' => 'Unit data field 11',
            'Unit Data 12' => 'Unit data field 12',
            'Unit Data 13' => 'Unit data field 13',
            'Unit Data 14' => 'Unit data field 14',
            'Unit Data 15' => 'Unit data field 15'
        };
        System.assertEquals(expectedMap, AdminConfigUtil.unitDataFieldNameMap);
    }
    
}
@isTest
private without sharing class GuidUtilTest {
    
    @isTest
    private static void GuidIsV4() {
        Pattern p = Pattern.compile('[\\w]{8}-[\\w]{4}-4[\\w]{3}-[89ab][\\w]{3}-[\\w]{12}');
        for(Integer x = 0; x < 100; x++) {
            Matcher m = p.matcher(GuidUtil.generateGuid());
            System.assert(m.matches() == true);
        }
    }
}
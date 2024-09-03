@isTest 
public class SearchLeadResultWrapperTest {
	@testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
    }
	@isTest
    private static void searchLeadResultWrapperTest() {
    	SearchLeadResultWrapper searchWrapper = new SearchLeadResultWrapper();
    	SearchLeadResultWrapper.parse(System.JSON.serialize(searchWrapper));
    	System.assertNotEquals(searchWrapper, null);
    }
}
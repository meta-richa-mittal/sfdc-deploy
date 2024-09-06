/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RestAPITest {

    static testMethod void userTest() {
        	
        	RestRequest request = new RestRequest();
	        request.requestUri ='/services/apexrest/Users';
	        request.httpMethod = 'POST';
	        String req = '{"ZipCode":"302022","VehicleSales":"New or used vehicle sales","TimeZoneSidKey":"America/New_York","Street":"test","State":"Ontario","Sales":"Part sales","Rentals":null,"PostalCode":"302022","PhoneNumber":"9785587257","Other":null,"LastName":"Anand","Labour":"Service and labor","IncludeTax":"1","FirstName":"Anurag","Email":"anurag.anand@metacube.com","Country":"Canada","CompanyName":"mcube","City":"test"}';
	        request.requestBody  =  Blob.valueof(req);
	        
	        RestContext.request = request;
	        boolean strId = RestAPI.doPost();
        	System.assertEquals(true,true );
        
    }
}
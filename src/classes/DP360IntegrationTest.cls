@isTest
private class DP360IntegrationTest {

    @TestSetup
    private static void makeData(){  
        DP360_Configuration__c DP360Config = TestDataFactory.createDP360Configuration();
        DP360Config.End_Point_URL__c = 'dp360crm';
        update DP360Config;
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForDP360();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForDP360('Token', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem2 = TestDataFactory.createIFWConfigItemForDP360('SearchLead', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem3 = TestDataFactory.createIFWConfigItemForDP360('Update Lead', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem4 = TestDataFactory.createIFWConfigItemForDP360('Create Unit', ifwConfig.Id);
        Account customer = TestDataFactory.createCustomer('Test001', 'Individual', 'Fname', 'Lname');
		CO_Header__c coHeader =  TestDataFactory.createCOHeader(customer.Id);
    	Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	List<Customer_Owned_Unit__c> customerOwnedUnitList = new List<Customer_Owned_Unit__c>();
    	for(Integer i = 0; i < 20; i++){
    		customerOwnedUnitList.add(TestDataFactory.sampleCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, unitSubModel.Id, 'VIN001'));
    	}
    	insert customerOwnedUnitList;
		Deal__c deal = TestDataFactory.createDeal(coHeader.Id, customerOwnedUnitList[0].Id);
    }

    @isTest
    private static void testSearchLead() {
        Test.startTest();
        String searchLeadJson = '{"dealerId":"100","startDate":"2021-04-14","lead_id":"123"}';
        searchLeadJson = BPUtility.getEncodedString(searchLeadJson);
		DP360IntegrationCtrl.SearchLeadWrapper SearchLeadWrapperObj =  (DP360IntegrationCtrl.SearchLeadWrapper) System.JSON.deserialize(BPUtility.getDecodedString(searchLeadJson), DP360IntegrationCtrl.SearchLeadWrapper.class);
        String key = DP360Integration.searchLead(SearchLeadWrapperObj);
        system.assertEquals(null, key);
        Test.stopTest();

    }
    @isTest
    private static void testSearchInventory() {
        Test.startTest();
        String key = DP360Integration.searchInventory('5000', '123');
        system.assertEquals(null, key);
        Test.stopTest();
    }

    @isTest
    private static void testCreateInventory() {
        Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
        Test.startTest();
        String query;
        query = 'SELECT '; 
        for(String fieldsName : DP360InventoryWrapper.unitFieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Customer_Owned_Unit__c';
        List<Customer_Owned_Unit__c> couRec = Database.query(query);
        DP360InventoryWrapper DP360InventoryWrapperObj = new DP360InventoryWrapper(couRec[0], 5000);
        String key = DP360Integration.createInventory(new List<DP360InventoryWrapper>{DP360InventoryWrapperObj});
        system.assertNotEquals(null, key);
        Test.stopTest();
    }

    @isTest
    private static void testUpdateInventory() {
        Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
        Test.startTest();
        String query;
        query = 'SELECT '; 
        for(String fieldsName : DP360InventoryWrapper.unitFieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Customer_Owned_Unit__c';
        List<Customer_Owned_Unit__c> couRec = Database.query(query);
        DP360InventoryWrapper DP360InventoryWrapperObj = new DP360InventoryWrapper(couRec[0], 5000);
        String key = DP360Integration.updateInventory(new List<DP360InventoryWrapper>{DP360InventoryWrapperObj});
        system.assertNotEquals(null, key);
        Test.stopTest();
    }
    @isTest
    private static void testSaveLead() {
        Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
        Test.startTest();
        String query = 'SELECT ';  
    	for(String fieldsName : CreateLeadWrapper.fieldsList()) {
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
        	query += fieldsName + ', ';  
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Deal__c LIMIT 1';
    	Deal__c deal = Database.query(query);
    	List<Customer_Owned_Unit__c> unitList = new List<Customer_Owned_Unit__c>([SELECT Id, DP360_Inventory_Id__c, Year__c, Unit_Make__r.Name, Unit_Model__r.Name__c, Colour__c, Mileage_Value__c, Category__r.Name, VIN_Number__c, Total_Price__c, Location__c, Stock_Id__c FROM Customer_Owned_Unit__c]);
    	Account customer = [SELECT FirstName__c, LastName__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Home_number__c, Work_Number__c, Mobile__c, Birth_Date__c, Preferred_Email__c, Email__c, Work_Email__c, Other_Email__c  FROM Account WHERE Is_Customer__c = true LIMIT 1];
    	CreateLeadWrapper createLeadWrapper = new CreateLeadWrapper('5000', deal.Id, null, customer, unitList, unitList);
        String key = DP360Integration.saveLead(createLeadWrapper);
        system.assertNotEquals(null, key);
        Test.stopTest();
    }
    public class DP360MockResponseGenerator implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setStatusCode(200);
			if(req.getMethod() == 'GET') {
			    res.setBody('{"code": 200,"message": "Success", "data": [{"first_name": "Blackpurl","m_name": null,"last_name": "Testing","address": "1831 ST","address2": "NY","city": "Sydny","zip": null,"mobile": "7894561230","phone": "","work_number": "","email": "blackpurl@testing.com","alternate_email": "bp@testing.com","fax": "","date_of_birth": null,"gender": "Not Known","details": null,"lead_id": 4546504,"vendor_lead_id": null,"dealer_id": 1050,"sperson": "","lead_source": "Blackpurl - Contacts","lead_source_id": 13791,"domain": null,"lead_sub_source": null,"lead_type": "Web Lead","status": "Open","last_activity": null,"last_activity_type": null,"is_deleted": 0,"created": "2020-10-21T06:40:29+00:00","modified": "2020-11-02T06:43:52+00:00","master_contact_lead_id": null,"merge_type": 0,"company": null,"country": "United States","state": "","dealer_name": "  DP360 Blackpurl DEMO","do_not_call": "N","do_not_email": "N","do_not_text": "N","mktg_text_opt_in": "N","lead_units": [{"branch_location": "","vehicle_selection_type": "catalog","unit_record_type": 1,"stock_num": "","vin": "","unit_year": "","unit_make": "","unit_condition": "New","unit_model": "","unit_trim": "","unit_category": "","unit_sub_category": "","inv_instock_unit_id": null,"odometer": "","odometer_units": "miles","unit_color": "","unit_value": null,"unit_msrp": null,"sale_price": null,"contact_lead_id": 4546504,"inv_instock_unit": null},{"branch_location": "Colton","vehicle_selection_type": "catalog","unit_record_type": 2,"stock_num": null,"vin": "1F66F5DY0G0A06626","unit_year": "2016","unit_make": "Forest River","unit_condition": "New","unit_model": "abc50","unit_trim": "","unit_category": "Class A","unit_sub_category": "","inv_instock_unit_id": null,"odometer": "0","odometer_units": "miles","unit_color": "","unit_value": null,"unit_msrp": null,"sale_price": null,"contact_lead_id": 4546504,"inv_instock_unit": null}]}]}');
			} else if(req.getMethod() == 'PUT') {
			    res.setBody('{"message": "Lead updated successfully", "data": {"lead_id": "4554879"}}');
			}
			return res;
		}
	}
}
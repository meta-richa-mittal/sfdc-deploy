/**
 * Author: Reena Singh
 * Since: November 03, 2020
 * Name: DP360LeadServiceTest
 * Description: Controller test Class of CustomerOrder_V2.
**/
@isTest
global class DP360LeadServiceTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForDP360();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForDP360('Token', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem2 = TestDataFactory.createIFWConfigItemForDP360('SearchLead', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem3 = TestDataFactory.createIFWConfigItemForDP360('Update Lead', ifwConfig.Id);
        
        Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        customer.Is_Customer__c = true;
        insert customer;
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert coHeader;
        
        Deal__c dealRec = new Deal__c(CO_Header__c = coHeader.Id, Status__c = Constants.QUOTATION, Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);

		insert dealRec;
		List<Deal__c> dealList = new List<Deal__c>{dealRec};

        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);

		Deal_Item__c dealItemRec = new Deal_Item__c(Colour__c='Red',Year__c=2016); 
        dealItemRec.Unit_Model__c = unitmodel.Id;
		dealItemRec.Deal__c = dealRec.Id;
		dealItemRec.Lien_Payout_Avail_For_Xero_Sync__c = true;
		dealItemRec.Type__c = 'Trade In';
        insert dealItemRec;

        Customer_Owned_Unit__c customerOwnedUnitRec = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnitRec.Unit_Type__c = 'COU';
        customerOwnedUnitRec.Vin_Number__c = '1F66F5DY0G0A06626';
        insert customerOwnedUnitRec;
    }

    @isTest
    private static void getNoOpenLeadsFromDP360Test() {
		Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
		Test.startTest();
		try {
			String openLeadJson = CustomerOrderCtrl_V2.getOpenLeadsFromDP360();
			List<SearchLeadResultWrapper.LeadWrapper> openLeadList =  (List<SearchLeadResultWrapper.LeadWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(openLeadJson), List<SearchLeadResultWrapper.LeadWrapper>.class);
		} catch(Exception e) {
			System.debug('String.valueOf(e):::'+String.valueOf(e));
            System.debug('reee:::'+e.getMessage());
            system.assert(String.valueOf(e).contains('No open leads found in the CRM'),'No open leads found in the CRM');
		}
		Test.stopTest();
	}

	@isTest
    private static void getOpenLeadsFromDP360Test() {
		Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());	
        Test.startTest();
        List<IFW_IntegrationConfigItem__c> configItemList = [SELECT Id from IFW_IntegrationConfigItem__c WHERE Entity_Name__c ='Search Lead' AND HTTP_Method__c ='GET'
            AND IFW_IntegrationConfig__r.Integration_Name__c = 'DP360'];
        System.assertEquals(1, configItemList.size());
		String openLeadJson = CustomerOrderCtrl_V2.getOpenLeadsFromDP360();
		List<SearchLeadResultWrapper.LeadWrapper> openLeadList =  (List<SearchLeadResultWrapper.LeadWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(openLeadJson), List<SearchLeadResultWrapper.LeadWrapper>.class);
		System.assertEquals(1, openLeadList.size());	
		Test.stopTest();
    }
    
    @isTest
    private static void createCustomerFromDP360Test() {
		Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());	
        Test.startTest();
		String openLeadJson = CustomerOrderCtrl_V2.createCustomerFromDP360(BPUtility.getEncodedString('1050'));
		String customerId =  BPUtility.getDecodedString(openLeadJson);
        System.assertNotEquals(null, customerId);	
		Test.stopTest();
	}
    
    @isTest
    private static void createDealFromDP360Test() {
		Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());	
        Test.startTest();
        
        Account customer  = [Select Id from Account Limit 1];
        CO_Header__c coHeaderId = [Select Id from CO_Header__c limit 1];
        List<Deal_Item__c> dealItemList = [SELECT Deal__c FROM Deal_Item__c WHERE Deal__r.CO_Header__c =: coHeaderId.Id order by CreatedDate ASC limit 1];
        System.assertEquals(1, dealItemList.size());
        String vinNumber = '1F66F5DY0G0A06626';
        List<Customer_Owned_Unit__c> couList = [SELECT Id FROM Customer_Owned_Unit__c 
                                        WHERE Unit_Type__c = 'COU' AND VIN_Number__c =: vinNumber AND Account__c =: customer.Id];
        System.assertEquals(1, couList.size());                               
		String dealId = CustomerOrderCtrl_V2.createDealFromDP360(BPUtility.getEncodedString('1050'), BPUtility.getEncodedString(customer.Id));
        System.assertNotEquals(null, dealId);
		Test.stopTest();
    }
    
    @isTest
    private static void updateLeadStatusToDP360Test() {
        Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
        Test.startTest();
        Deal__c dealRec = [SELECT DP360_Lead_Id__c, Status__c FROM Deal__c limit 1];
        dealRec.Status__c = 'Invoiced';
        dealRec.DP360_Lead_Id__c = '12345';
        update dealRec;
        Test.stopTest();
        
        dealRec = [SELECT Available_For_DP360_Sync__c, DP360_Sync_Response__c FROM Deal__c WHERE Id =: dealRec.Id];
        system.assertEquals(false, dealRec.Available_For_DP360_Sync__c);
        system.assertEquals('Lead updated successfully', dealRec.DP360_Sync_Response__c);
    }
    
	global class DP360MockResponseGenerator implements HttpCalloutMock {
		global HTTPResponse respond(HTTPRequest req) {
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

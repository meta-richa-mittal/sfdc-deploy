@isTest
private class JobSchedulerServiceTest {
    @testsetup
    private static void setup(){
		TestDataFactory.disableFLSChecks();
    	Account customerRec = TestDataFactory.createCustomer('Test001', 'Individual', 'Fname', 'Lname');
		Customer_Owned_Unit__c unitRec = TestDataFactory.createCustomerOwnedUnit(customerRec.Id, 'VIN001');
		Event__c eventRec1 = TestDataFactory.createEventForAfternoon(customerRec.Id, unitRec.Id);
		eventRec1.Type__c = 'Appointment';
		eventRec1.Start_DateTime__c = HomeSearchFilterInterface.getDateFromString('12/03/1997');
		update eventRec1;
		Event__c eventRec2 = TestDataFactory.createEventForAfternoon(customerRec.Id, unitRec.Id);
		Shop_Settings__c shopSettings = TestDataFactory.createShopSettings('Wednesday');
    }
    
    @isTest
    private static void testGetTechnicianListForSpecificDay(){
    	Test.startTest();
		List<TechnicianDetailWrapper> technicianDetailWrapperList = new List<TechnicianDetailWrapper>(JobSchedulerService.getTechnicianListForSpecificDay('12/03/1997'));
		system.assertEquals(technicianDetailWrapperList.size(), 0);
    	Test.stopTest();
    }
    
    @isTest
    private static void testUpdateAppointment(){
    	Test.startTest();
    	List<Event__c> eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'});
    	eventRec[0].Start_DateTime__c = HomeSearchFilterInterface.getDateFromString('12/03/1997');
    	update eventRec;
    	AppointmentWrapper appWrapper1 = new AppointmentWrapper(eventRec[0], true);
    	AppointmentWrapper appWrapper2 = new AppointmentWrapper(eventRec[1], true);
    	List<AppointmentWrapper> appointmentWrapperList = new List<AppointmentWrapper>();
    	appointmentWrapperList.add(appWrapper1);
    	appointmentWrapperList.add(appWrapper2);
    	String appointmentObjStr = json.serialize(appointmentWrapperList);
    	JobSchedulerService.updateAppointment(appointmentObjStr);
    	List<Event__c> eventRecUpdated = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'});
    	system.assertEquals(eventRecUpdated[0].Name__c, 'Test Event');
    	Test.stopTest();
    }
    
    /**
    @isTest
    private static void testGetUnassignedAppointmentForSpecificDay(){
    	Test.startTest();
    	List<AppointmentWrapper> appointmentWrapperList = new List<AppointmentWrapper>(JobSchedulerService.getUnassignedAppointmentForSpecificDay('12/03/1997'));
    	system.assertEquals(appointmentWrapperList.size(), 1);
    	Test.stopTest();
    }**/
    
    @isTest
    private static void testCreateCOWithServiceJob(){
    	Test.startTest();
    	Account customer = [SELECT Id FROM Account LIMIT 1];
    	List<Event__c> eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'});
    	eventRec[0].CO_Header__c = null;
    	update eventRec;
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec[0], true);
    	String appointmentObjStr = json.serialize(appWrapper);
    	Id result = (Id)JobSchedulerService.createCOWithServiceJob(appointmentObjStr);
    	system.assertEquals(true, result.getSObjectType().getDescribe().getName().contains('CO_Header__c'));
    	Test.stopTest();
    }
		
	@isTest
	private static void testGetAssignedAppointmentForSpecificDay(){
		Test.startTest();
		Technician__c technician = TestDataFactory.createTechnician();
		Map<String, List<AppointmentWrapper>> result = new Map<String, List<AppointmentWrapper>>(JobSchedulerService.getAssignedAppointmentForSpecificDay('12/03/1997', technician.Id));
		system.assertEquals(result.size(), 0);
		Test.stopTest();
	}
	
	private static List<Event__c> getAppointmentList(Map<String, String> fieldNameToFieldValueMap) {
		String query = 'SELECT ';
        for(String fieldName : AppointmentWrapper.getAppointmentFieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c ';
        if(fieldNameToFieldValueMap.size() > 0){
            query += SOQLUtil.getWhereClause(fieldNameToFieldValueMap);
        }
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
	}
}
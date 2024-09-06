@isTest
private class AppointmentCtrlTest {
	
    @testsetup
    private static void setup() {
		TestDataFactory.disableFLSChecks();
    	Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test First Name', 'Test Last Name');
    	Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, unitSubModel.Id, 'VIN001');
    	CO_Header__c coHeader = TestDataFactory.createCoHeader(customer.Id);
    	Service_Order_Header__c soHeader = TestDataFactory.createSOHeader(coHeader.Id);
    	Event__c eventRecForMorning = TestDataFactory.createEventForMorning(customer.Id, customerOwnedUnit.Id);
    	Event__c eventRecForEvening = TestDataFactory.createEventForAfternoon(customer.Id, customerOwnedUnit.Id);
    	Event__c eventRecWithSOHeader = TestDataFactory.createEventWithServiceHeader(customer.Id, customerOwnedUnit.Id, soHeader.Id);
    	Shop_Settings__c shopSettings = TestDataFactory.createShopSettings('Monday');
    }
    
    @isTest
    private static void testConstructor() {
    	Test.startTest();
    	AppointmentCtrl appointmentCtrl = new AppointmentCtrl();
    	AppointmentCtrl appointmentCtrlWithHomePage = new AppointmentCtrl(new NewHomePageCtrl());
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Morning'})[0];
    	AppointmentWrapper appointmentWrapper = new AppointmentWrapper(eventRec);
    	Account customer = [SELECT Id FROM Account WHERE Is_Customer__c = true LIMIT 1];
    	system.assertEquals(appointmentWrapper.CustomerId, customer.Id);
    	Test.stopTest();
    }
    
    @isTest
    private static void testSaveAppointmentForMorning() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Morning'})[0];
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appWrapper, false);
    	String result = AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(appointmentDetailJSON));
    	ResponseWrapper response = (ResponseWrapper)Json.deserialize(BPUtility.getDecodedString(result), ResponseWrapper.class);
    	system.assertEquals('Success', response.responseStatus);
    	Test.stopTest();
    }
    
    @isTest
    private static void testSaveAppointmentForAfternoon() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'})[0];
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appWrapper, false);
    	String result = AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(appointmentDetailJSON));
    	ResponseWrapper response = (ResponseWrapper)Json.deserialize(BPUtility.getDecodedString(result), ResponseWrapper.class);
    	system.assertEquals('Success', response.responseStatus);
    	Test.stopTest();
    }
    
    @isTest
    private static void testSaveAppointmentWithConflict() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'})[0];
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	appWrapper.isConflictExists = true;
    	String appointmentDetailJSON = System.JSON.serialize(appWrapper, false);
    	String result = AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(appointmentDetailJSON));
    	ResponseWrapper response = (ResponseWrapper)Json.deserialize(BPUtility.getDecodedString(result), ResponseWrapper.class);
    	system.assertEquals('Success', response.responseStatus);
    	Test.stopTest();
    }
    
    @isTest
    private static void testSaveAppointmentWithServiceOrderHeader() {
    	Test.startTest();
    	Event__c eventRec = [SELECT Id, Service_Order_Header__r.SO_Status_Ref__r.Short_Name__c, Service_Order_Header__r.SO_Status_Ref__r.Text_Color__c, Service_Order_Header__r.SO_Status_Ref__r.Background_Color__c, Unit_Location__c, Customer__c, Is_MultiDay__c, Customer_Owned_Unit__c, Estimated_Hours__c, Transaction_Type__r.Code_Label__c, Transaction_Type__c, Transaction_Type__r.Type__c, Name__c, Technician__c, Customer__r.Name, Service_Order_Header__c, End_DateTime__c, Appointment_Concern__c, Customer_Owned_Unit__r.Formatted_Name__c, Appointment_Day_Segment__c, CO_Header__r.Name, Start_DateTime__c,
			Due_In_DateTime__c, Promised_By_DateTime__c, Unit_Arrived__c ,Due_In_Time__c, Promised_By_Time__c, Service_Order_Header__r.SO_Status__c, Event_Scheduling_Count__c FROM Event__c WHERE Service_Order_Header__c != null LIMIT 1]; // Is_Work_Late__c,
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appWrapper, false);
    	String result = AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(appointmentDetailJSON));
    	ResponseWrapper response = (ResponseWrapper)Json.deserialize(BPUtility.getDecodedString(result), ResponseWrapper.class);
    	system.assertEquals('Success', response.responseStatus);
    	Test.stopTest();
    }
    
    @isTest
    private static void testSaveAppointmentWithEventConcern() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Morning'})[0];
    	String appointmentConcern = '';
    	for(Integer i = 0; i < 255; i++){
    		appointmentConcern = appointmentConcern + 'a';
    	}
    	eventRec.Appointment_Concern__c = appointmentConcern;
    	update eventRec;
    	AppointmentWrapper appWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appWrapper, false);
    	String result = AppointmentCtrl.saveAppointment(BPUtility.getEncodedString(appointmentDetailJSON));
    	ResponseWrapper response = (ResponseWrapper)Json.deserialize(BPUtility.getDecodedString(result), ResponseWrapper.class);
    	system.assertEquals('Success', response.responseStatus);
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetCustomerRecByCustomerId() {
    	Test.startTest();
    	Account customer = [SELECT Id FROM Account WHERE Is_Customer__c = true LIMIT 1];
    	String customerRecord = AppointmentCtrl.getCustomerRecByCustomerId(BPUtility.getEncodedString(customer.Id));
    	CustomerWrapper customerWrapper = (CustomerWrapper)Json.deserialize(BPUtility.getDecodedString(customerRecord), CustomerWrapper.class);
    	system.assertEquals(customerWrapper.CustomerRecord.FirstName, 'Test First Name');
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetUnitById() {
    	Test.startTest();
    	Customer_Owned_Unit__c customerOwnedUnit = [SELECT Id FROM Customer_Owned_Unit__c LIMIT 1];
    	String unitDetail = AppointmentCtrl.getUnitById(BPUtility.getEncodedString(customerOwnedUnit.Id));
    	CustomerOwnedUnit customerOwnedUnitJson = (CustomerOwnedUnit)Json.deserialize(BPUtility.getDecodedString(unitDetail), CustomerOwnedUnit.class);
    	system.assertEquals('Test Unit Make', customerOwnedUnitJson.MakeName);
    	Test.stopTest();
    }
    
    @isTest
    private static void testDeleteAppointmentById() {
    	Test.startTest();
    	Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
    	String deleteAppointmentRec = AppointmentCtrl.deleteAppointmentById(BPUtility.getEncodedString(eventRec.Id));
    	system.assertEquals('SUCCESS', BPUtility.getDecodedString(deleteAppointmentRec));
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetJobTypeList(){
    	Test.startTest();
    	String jobType = AppointmentCtrl.getJobTypeList();
    	List<ServiceOrderWrapper.TTType> serviceOrder = (List<ServiceOrderWrapper.TTType>)Json.deserialize(BPUtility.getDecodedString(jobType), List<ServiceOrderWrapper.TTType>.class);
    	system.assertEquals(serviceOrder.size(), 0);
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetTechnicianListWithAvailableHours() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>())[0];
    	AppointmentWrapper appointmentWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appointmentWrapper, true);
    	String result = AppointmentCtrl.getTechnicianListWithAvailableHours(BPUtility.getEncodedString(appointmentDetailJSON));
    	List<TechnicianDetailWrapper> technicianDetailWrapper = (List<TechnicianDetailWrapper>)System.Json.deserialize(BPUtility.getDecodedString(result), List<TechnicianDetailWrapper>.class);
    	system.assertEquals(technicianDetailWrapper.size(), 0);
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetTechnicianListWithAvailableHoursWithSortingTechnicianForMorning() {
    	Test.startTest();
    	Technician__c technician = TestdataFactory.createTechnician();
    	Leave__c leave = TestDataFactory.createLeave(technician.Id);
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Morning'})[0];
    	leave.From__c = eventRec.Start_DateTime__c;
    	update leave;
    	AppointmentWrapper appointmentWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appointmentWrapper, true);
    	String result = AppointmentCtrl.getTechnicianListWithAvailableHours(BPUtility.getEncodedString(appointmentDetailJSON));
    	List<TechnicianDetailWrapper> technicianDetailWrapper = (List<TechnicianDetailWrapper>)System.Json.deserialize(BPUtility.getDecodedString(result), List<TechnicianDetailWrapper>.class);
    	system.assertEquals(technicianDetailWrapper.size(), 1);
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetTechnicianListWithAvailableHoursWithSortingTechnicianForAfternoon() {
    	Test.startTest();
    	Technician__c technician = TestdataFactory.createTechnician();
    	Leave__c leave = TestDataFactory.createLeave(technician.Id);
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'})[0];
    	leave.From__c = eventRec.Start_DateTime__c;
    	update leave;
    	AppointmentWrapper appointmentWrapper = new AppointmentWrapper(eventRec, true, eventRec.Start_DateTime__c);
    	String appointmentDetailJSON = System.JSON.serialize(appointmentWrapper, true);
    	String result = AppointmentCtrl.getTechnicianListWithAvailableHours(BPUtility.getEncodedString(appointmentDetailJSON));
    	List<TechnicianDetailWrapper> technicianDetailWrapper = (List<TechnicianDetailWrapper>)System.Json.deserialize(BPUtility.getDecodedString(result), List<TechnicianDetailWrapper>.class);
    	system.assertEquals(technicianDetailWrapper.size(), 1);
    	Test.stopTest();
    }
    
    @isTest
    private static void testUpdateRelatedSORecord() {
    	Test.startTest();
    	system.assertEquals('', AppointmentCtrl.updateRelatedSORecord('Id'));
    	Test.stopTest();
    }
    
    @isTest
    private static void testGetTimeSlotAndStateForTechnician() {
    	Test.startTest();
    	DateTime dt = System.today();
		Time timeSlot = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
		AppointmentService appointmentService = new AppointmentService();
		appointmentService.TimeSlotWrapper timeSlotWrapper = new appointmentService.TimeSlotWrapper(timeSlot, 'Available');
		timeSlotWrapper.AppointmentDay = 'Monday';
		timeSlotWrapper.AppointmentDate = '07/09/2018';
		timeSlotWrapper.EstimatedHours = 3;
		timeSlotWrapper.IsMultiDay = false;
		String result = AppointmentCtrl.getTimeSlotAndStateForTechnician(BPUtility.getEncodedString(Json.serialize(timeSlotWrapper, true)));
		List<appointmentService.TimeSlotWrapper> timeSlotWrapperResult = new List<appointmentService.TimeSlotWrapper>((List<appointmentService.TimeSlotWrapper>)system.Json.deserialize((BPUtility.getDecodedString(result)), List<appointmentService.TimeSlotWrapper>.class));
		system.assertEquals(timeSlotWrapperResult.size(), 37);
		Test.stopTest();
    }
    
    @isTest
    public static void testPopulateSOKitConcernsOnAppointment() {
    	Test.startTest();
    	Event__c eventRec = getAppointmentList(new Map<String, String>{'Appointment_Day_Segment__c' => 'Afternoon'})[0];
    	AppointmentWrapper appointmentWrapper = new AppointmentWrapper(eventRec, true);
    	Service_Order_Header__c soHeader = [SELECT Id FROM Service_Order_Header__c LIMIT 1];
    	AppointmentService.populateSOKitConcernsOnAppointment(appointmentWrapper, soHeader.Id);
    	system.assertEquals(appointmentWrapper.SOKitConcern.size(), 0);
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
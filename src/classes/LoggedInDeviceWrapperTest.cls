@isTest
private class LoggedInDeviceWrapperTest {
    
    @Testsetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
    	Branding_Location__c brandingLocationobj =TestDataFactory.createBrandingLocationobj();
        Cash_Drawer__c cashDrawerobj = TestDataFactory.createCashDrawer('CashDrawerName');
        Logged_In_Device__c loggedInDevice = TestDataFactory.createNewLoggedInDevice('LoggedInDeviceName',brandingLocationobj.Id,cashDrawerobj.Id);
    }
    
    @isTest
    private static void testLoggedInDeviceWrapper(){
    	Test.startTest();
    	String query;   
        query = 'SELECT '; 
        for(String fieldsName : LoggedInDeviceWrapper.getLoggedInDeviceFieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query += 'Cash_Drawer__r.Active__c, Branding_Location__r.Business_Location_Name__c, ';
        query = query.substring(0, query.length()-2);
        query += ' FROM  Logged_In_Device__c LIMIT 1';
        Logged_In_Device__c loggedInDevice = Database.query(query);
        LoggedInDeviceWrapper loggedInDeviceWrapper = new LoggedInDeviceWrapper(loggedInDevice,'entity');
        LoggedInDeviceWrapper loggedInDeviceWrapper1 = new LoggedInDeviceWrapper(loggedInDevice);
        system.assertEquals(loggedInDeviceWrapper.Id, loggedInDevice.Id);

    	Test.stopTest();
    }

    @isTest
    private static void testgetLoggedInDeviceFieldsList(){
        List<String> coInvoicePaymentFields = new List<String>{ 'Name',
	                                                        'Cash_Drawer__c',
	                                                        'Cash_Drawer__r.Name',
	                                                        'Branding_Location__c',
	                                                        'Branding_Location__r.Name'
	                                               		 };
        system.assertEquals(coInvoicePaymentFields, LoggedInDeviceWrapper.getLoggedInDeviceFieldsList());
    }
}
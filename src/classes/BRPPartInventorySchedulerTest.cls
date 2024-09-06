@isTest
private class BRPPartInventorySchedulerTest {
    @testSetup
    private static void testSetup() { 
        TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Auto_reorder_Min__c = 1;
        part.Last_Sold__c = System.today();
        part.Auto_reorder_Max__c = 4;
        part.Last_Stocked__c = System.today();
        part.Last_Counted__c = System.today();
        part.Qty_In_Stock__c = 5;
        part.Is_Included_In_BRP_Inventory__c =  false;
        insert part;

        Part__c part1 = TestUtil.createPart(false, 'partNumberP011', vendor.Id, 'Test Part1', testCategory.Id, 10, 220, 530, 100, 100);
        part1.Packaged_Part__c = false;
        part1.Qty_On_Order__c = 0;
        part.Qty_In_Stock__c = 5;
        part1.Auto_reorder_Min__c = 1;
        part1.Last_Sold__c = System.today();
        part1.Auto_reorder_Max__c = 4;
        part1.Last_Stocked__c = System.today();
        part1.Last_Counted__c = System.today();
        part1.Is_Included_In_BRP_Inventory__c =  false;
        insert part1;

        File_Storage__c fileStorage =  new File_Storage__c();
        fileStorage.Name__c= 'BRP';
        insert fileStorage;

        BRP_Vendors_List__c brpVendorListRec = new BRP_Vendors_List__c();
        brpVendorListRec.Is_Active_Vendor__c = true;
        brpVendorListRec.Name = vendor.Id;
        insert brpVendorListRec;
        
        BRP_Settings__c brpSettingRec =  new BRP_Settings__c();
        brpSettingRec.Currency_Code__c ='CAD';
        brpSettingRec.Radius_Measure__c = 'mile';
        brpSettingRec.Org_Name__c = 'DEV01';
        brpSettingRec.Dealer_Id__c = '0000691784';
        brpSettingRec.Radius__c = 100;
        brpSettingRec.Endpoint__c = '';
        insert brpSettingRec;
    }

    @isTest
	private static void  testschedule() {
        
        Test.StartTest();
        SchedulableContext sc = null;
        BRPPartInventoryScheduler brpPartInventorySchedulerRec = new BRPPartInventoryScheduler(system.today());   
        brpPartInventorySchedulerRec.execute(sc);
        List<Attachment> attachmentList = [SELECT Id FROM Attachment ];
        system.assertNotEquals(1, attachmentList.size());
        Test.stopTest();

    }
      
    static testMethod void sendEmailTest() {
        BRPResponseWebService.PostResponseWrapper resWrapperObj = new BRPResponseWebService.PostResponseWrapper();
        
        resWrapperObj.FileName = 'Parts Inventory';      
        resWrapperObj.RequestParamStr ='RequestParamStr';
        resWrapperObj.StatusCode = 200;
		resWrapperObj.IsJavaSuccess = true;
        resWrapperObj.ResponseXMLString =  '<?xml version="1.0" encoding="UTF-8"?> <star:AcknowledgePartsInventory xmlns:star="http://www.starstandard.org/STAR/5" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.starstandard.org/STAR/5 file:/C:/STAR/5.8.1/BODs/Standalone/AcknowledgePartsInventory.xsd" releaseID="5.8.1" languageCode="en-US"><star:ApplicationArea><star:Sender><star:ReferenceID>7fc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:ReferenceID><star:CreatorNameCode>Kawasaki Motors Corp., U.S.A.</star:CreatorNameCode><star:SenderNameCode>KA</star:SenderNameCode></star:Sender><star:CreationDateTime>2006-05-04T18:13:51-04:00</star:CreationDateTime><star:BODID>9oc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:BODID><star:Destination><star:DestinationNameCode>AD</star:DestinationNameCode><star:DealerNumberID>12345</star:DealerNumberID></star:Destination></star:ApplicationArea><star:AcknowledgePartsInventoryDataArea><star:Acknowledge> </star:Acknowledge><star:PartsInventory><star:PartsInventoryHeader><star:DocumentIdentificationGroup><star:DocumentIdentification><star:DocumentID>AcknowledgePartsInventory</star:DocumentID><star:AgencyRoleCode>Manufacturer</star:AgencyRoleCode></star:DocumentIdentification></star:DocumentIdentificationGroup></star:PartsInventoryHeader></star:PartsInventory></star:AcknowledgePartsInventoryDataArea></star:AcknowledgePartsInventory>';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/BRPResponse/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
       
        Test.StartTest();
        String response = BRPResponseWebService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
        BRP_log__c brpLogRec = [Select Id, Apex_Class__c, Error_Messages__c FROM BRP_log__c ];
        system.assertEquals('BRPResponseWebService', brpLogRec.Apex_Class__c);
        system.assertEquals(null, brpLogRec.Error_Messages__c);
        Test.stopTest();
    }
 
    static testMethod void sendEmailWithErrorResponseTest() {
        BRPResponseWebService.PostResponseWrapper resWrapperObj = new BRPResponseWebService.PostResponseWrapper();
        
        resWrapperObj.FileName = 'Parts Inventory';      
        resWrapperObj.RequestParamStr ='RequestParamStr';
        resWrapperObj.StatusCode = 200;
		resWrapperObj.IsJavaSuccess = false;
        resWrapperObj.ResponseXMLString = '<?xml version="1.0" encoding="UTF-8"?> <star:ConfirmBOD xmlns:oagis="http://www.openapplications.org/oagis/9" xmlns:star="http://www.starstandard.org/STAR/5" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.starstandard.org/STAR/5 file:/C:/STAR/5.8.1/BODs/Standalone/ConfirmBOD.xsd" releaseID="5.8.1" languageCode="en-US"><star:ApplicationArea><star:Sender><star:ComponentID>BusinessFault</star:ComponentID><star:ReferenceID>7fc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:ReferenceID><star:CreatorNameCode>Kawasaki Motors Corp., U.S.A.</star:CreatorNameCode><star:SenderNameCode>KA</star:SenderNameCode><star:SystemVersion>1</star:SystemVersion><star:ServiceID>ProcessPartsInventory</star:ServiceID></star:Sender><star:CreationDateTime>2006-05-04T18:13:51-04:00</star:CreationDateTime><star:BODID>7fc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:BODID><star:Destination><star:DestinationNameCode>AD</star:DestinationNameCode><star:DealerNumberID>12345</star:DealerNumberID></star:Destination></star:ApplicationArea><star:ConfirmBODDataArea><star:Confirm></star:Confirm><star:BOD><oagis:BODFailureMessage><oagis:ErrorProcessMessage><oagis:Description languageID="en-US">The STAR CreatorNameCode submitted is invalid. The STAR CreatorNameCode must be a valid DMS name.</oagis:Description><oagis:Type>Invalid Data</oagis:Type></oagis:ErrorProcessMessage><oagis:ErrorProcessMessage><oagis:Description languageID="en-US">The STAR CreationDateTime is missing.</oagis:Description><oagis:Type>Required Field Missing</oagis:Type></oagis:ErrorProcessMessage></oagis:BODFailureMessage></star:BOD></star:ConfirmBODDataArea></star:ConfirmBOD>';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/BRPResponse/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.StartTest();
        String response = BRPResponseWebService.sendEmail(resWrapperObj);
        BRP_log__c brpLogRec = [Select Id, Error_Messages__c FROM BRP_log__c ];
        system.assertEquals(brpLogRec.Error_Messages__c.contains('Some error occured at Java program'), true);
        Test.stopTest();

    }
    static testMethod void sendEmailWithExceptionTest() {
        BRPResponseWebService.PostResponseWrapper resWrapperObj = new BRPResponseWebService.PostResponseWrapper();
        
        resWrapperObj.FileName = 'Parts Inventory';      
        resWrapperObj.RequestParamStr ='RequestParamStr';
        resWrapperObj.StatusCode = 200;
		resWrapperObj.IsJavaSuccess = null;
        resWrapperObj.ResponseXMLString =  '<?xml version="1.0" encoding="UTF-8"?> <star:AcknowledgePartsInventory xmlns:star="http://www.starstandard.org/STAR/5" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.starstandard.org/STAR/5 file:/C:/STAR/5.8.1/BODs/Standalone/AcknowledgePartsInventory.xsd" releaseID="5.8.1" languageCode="en-US"><star:ApplicationArea><star:Sender><star:ReferenceID>7fc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:ReferenceID><star:CreatorNameCode>Kawasaki Motors Corp., U.S.A.</star:CreatorNameCode><star:SenderNameCode>KA</star:SenderNameCode></star:Sender><star:CreationDateTime>2006-05-04T18:13:51-04:00</star:CreationDateTime><star:BODID>9oc40f3f-a7ed-4c21-82e0-c0b021f1e30c</star:BODID><star:Destination><star:DestinationNameCode>AD</star:DestinationNameCode><star:DealerNumberID>12345</star:DealerNumberID></star:Destination></star:ApplicationArea><star:AcknowledgePartsInventoryDataArea><star:Acknowledge> </star:Acknowledge><star:PartsInventory><star:PartsInventoryHeader><star:DocumentIdentificationGroup><star:DocumentIdentification><star:DocumentID>AcknowledgePartsInventory</star:DocumentID><star:AgencyRoleCode>Manufacturer</star:AgencyRoleCode></star:DocumentIdentification></star:DocumentIdentificationGroup></star:PartsInventoryHeader></star:PartsInventory></star:AcknowledgePartsInventoryDataArea></star:AcknowledgePartsInventory>';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/BRPResponse/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
       
        Test.StartTest();
        String response = BRPResponseWebService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
        BRP_log__c brpLogRec = [Select Id, Apex_Class__c, Error_Messages__c FROM BRP_log__c ];
        system.assertEquals(brpLogRec.Error_Messages__c.contains('Error while handling BRP response'), true);
        Test.stopTest();

    }
}
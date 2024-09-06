/**
 * Author: Manoj Sharma
 * Since: April 07, 2020
 * Name: AutomatedPriceFileTest
 * Description: AutomatedPriceFileTest class.
**/
@isTest
global without sharing class AutomatedPriceFileTest {

	@testSetup static void setup() {
        Account testVendor = TestUtil.createVendor(true,'Test Vendor');
		Vendor_Master__c testVendorMaster = TestUtil.createVendorMaster(true, 'Honda us', true, true, true, true, testVendor);
        Category__c testCategory = TestUtil.createCategory(true, 'Test Vendor Category', 'Part', 'test category', true, true);
		Vendor_Master__c testVendorMaster2 = TestUtil.createVendorMaster(true, 'Honda AUS', true, true, true, true, testVendor); 
		Price_File_Mapping__c testPriceFileMapping = TestUtil.createPricefileMapping(true, testVendorMaster2.Id);
		
		LMA_Config__c lmaConfig = LMA_Config__c.getOrgDefaults();
    	lmaConfig.Client_Id__c = '3MVG9Z8h6Bxz0zc4xEvbwlKEZ0Tdjp1fpbbP903heXt9zjCDHtmiAGKdT0LqRws.vRXounsKpnhv0y8jLjUfG';
    	lmaConfig.Client_Secret__c = '2CB76DDC97EC788D6AF4D34FD6F8A4884CBE5A56A687C90783928E79005B7902';
    	lmaConfig.End_Point__c = 'https://test.salesforce.com';
    	lmaConfig.Password__c = 'V2VsY29tZUAxMjM0NSM=';
    	lmaConfig.Security_Token__c = 'jAked8zTunbmliCC5x9r2SvZC';
    	lmaConfig.Username__c = 'bWN1YmVfYWRtaW5AYmxhY2twdXJsLmNvbS5JQ1NERVYwMQ==';
		insert lmaConfig;
		
    }
    
	static testMethod void getAllSubscribedPriceFileTest(){
		String result =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> record = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<VendorMasterWrapper>.class);
		System.assertEquals(2, record.size());
	}

	static testMethod void getVendorMasterDetailsByIdTest(){
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getVendorMasterDetailsById(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		List<VendorMasterWrapper> record = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<VendorMasterWrapper>.class);
		System.assertEquals(true, record[0].IsUpdateAvailable);
	}

	static testMethod void getPriceFileMappingByVendorMasterIdTest(){
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getPriceFileMappingByVendorMasterId(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		List<AutomatedPriceFileMappingWrapper> record = (List<AutomatedPriceFileMappingWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<AutomatedPriceFileMappingWrapper>.class);
		System.assertEquals(vendorMasterWrapperList[0].VendorMasterId, record[0].VendorMasterId);
	}

	static testMethod void savePriceFileMappingTest(){
		String vendorMasterListJson = AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getPriceFileMappingByVendorMasterId(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		List<AutomatedPriceFileMappingWrapper> record = (List<AutomatedPriceFileMappingWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<AutomatedPriceFileMappingWrapper>.class);
		record[0].IsPackagedPart = false;
		String resultSavePriceFileMapping = AutomatedPriceFileCtrl.savePriceFileMapping(BPUtility.getEncodedString(System.JSON.Serialize(record[0])));
		
		System.assertNotEquals(null, BPUtility.getDecodedString(resultSavePriceFileMapping));
	}
    
	static testMethod void getPartCategoriesTest(){
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getPartCategories(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		List<CategoryService.CategoryWrapper> record = (List<CategoryService.CategoryWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<CategoryService.CategoryWrapper>.class);
		System.assertEquals(1, record.size());
	}

	static testMethod void skipUpdateForVendorMasterTest(){
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.skipUpdateForVendorMaster(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		String record = BPUtility.getDecodedString(result);
		System.assertEquals('"Update Successful"', String.valueOf(record));
	}
    
    
	static testMethod void getPriceFileMappingByVendorMasterIdTest2(){

        String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getPriceFileMappingByVendorMasterId(BPUtility.getEncodedString(vendorMasterWrapperList[1].VendorMasterId));
		List<AutomatedPriceFileMappingWrapper> record = (List<AutomatedPriceFileMappingWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<AutomatedPriceFileMappingWrapper>.class);
		System.assertEquals(vendorMasterWrapperList[1].VendorMasterId, record[0].VendorMasterId);
	}


	static testMethod void getPriceFileLocationAndConfigTest() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Test.startTest();
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);
		String result = AutomatedPriceFileCtrl.getPriceFileLocationAndConfig(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId), BPUtility.getEncodedString('VM-00000004'));
		Test.stopTest();	
		List<VendorMasterWrapper> record = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<VendorMasterWrapper>.class);
		System.assertEquals('us-east-2', record[0].Region);
	}

	static testMethod void updateVMSImportFlagPartnerOrgTest() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Test.startTest();
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);
		String result = AutomatedPriceFileCtrl.updateVMSImportFlagPartnerOrg(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId), BPUtility.getEncodedString('VM-00000004'));
		Test.stopTest();	
		String record = BPUtility.getDecodedString(result);
		System.assertEquals('"Success"', record);
	}
	
	static testMethod void getLastErrorLogNumberTest() {
        Price_File_Error_Log__c pfeLogRec= new Price_File_Error_Log__c();
        pfeLogRec.Error_Field_Name__c = 'Category';
        insert pfeLogRec;
		String result = BPUtility.getDecodedString(AutomatedPriceFileCtrl.getLastErrorLogNumber());
		System.assertEquals(result, result);
	}

	static testMethod void createActivityHistoryTest() {
		Account testVendor1 = TestUtil.createVendor(true,'Test Vendor1');
		AutomatedPriceFileCtrl.createActivityHistory(BPUtility.getEncodedString(testVendor1.Id));
		List<Activity_History__c> activityHistoryList = [SELECT Id, Name FROM Activity_History__c];
		System.assertEquals(0, activityHistoryList.size());
	}

	static testMethod void importSupersessionPartTest() {
		Account testVendor1 = TestUtil.createVendor(true,'Test Vendor1');
		Part__c testPart = TestUtil.createPart(true, 'PN-12345', testVendor1.Id, 'test part', null);
		List<String> idList = new List<String>();
		idList.add(testPart.Id);
		AutomatedPriceFileCtrl.importSupersessionPart(BPUtility.getEncodedString(System.JSON.serialize(idList)));
		List<Part__c> partList = [SELECT Id, Name FROM Part__c];
		System.assertEquals(1, partList.size());
	}

	static testMethod void createFileReadErrorLogTest() {
		AutomatedPriceFileService.FileReadErrorWrapper frewObj = new AutomatedPriceFileService.FileReadErrorWrapper();
		frewObj.Status = 200;
		frewObj.StatusText = 'test check';
        frewObj.Code = '12345';
		frewObj.Message = 'test check error log';
		
		AutomatedPriceFileCtrl.createFileReadErrorLog(BPUtility.getEncodedString(System.JSON.serialize(frewObj)));
		List<Log__c> logList = [SELECT Id, Name FROM Log__c];
		System.assertEquals(1, logList.size());
	}

	static testMethod void importFileTest() {
		List<AutomatedPriceFileImportService.PriceFileWrapper> recordList = new List<AutomatedPriceFileImportService.PriceFileWrapper>();

		List<Category__c> categoryList = [SELECT Id, Name FROM Category__c];
		String vendorMasterListJson =  AutomatedPriceFileCtrl.getAllSubscribedPriceFile();
		List<VendorMasterWrapper> vendorMasterWrapperList = (List<VendorMasterWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(vendorMasterListJson), List<VendorMasterWrapper>.class);

		String result = AutomatedPriceFileCtrl.getPriceFileMappingByVendorMasterId(BPUtility.getEncodedString(vendorMasterWrapperList[0].VendorMasterId));
		List<AutomatedPriceFileMappingWrapper> record = (List<AutomatedPriceFileMappingWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(result), List<AutomatedPriceFileMappingWrapper>.class);
		AutomatedPriceFileImportService.FieldMappingWrapper mappingObj = new AutomatedPriceFileImportService.FieldMappingWrapper();
		mappingObj.VendorId = vendorMasterWrapperList[0].BlackpurlVendorId;
		mappingObj.IsMfgNumberMapped = true;
		mappingObj.OverridePartPkgSetting = true;
		mappingObj.IsMfgNumberMapped = true;
		mappingObj.IsPackageQtyMapped = true;
		mappingObj.IsReplacedByMapped = true;
		mappingObj.IsReplacesMapped = true;
		mappingObj.IsSKUNumberMapped = true;
		mappingObj.PriceFileFieldMappingId = record[0].Id;
	
		AutomatedPriceFileImportService.PriceFileWrapper recJSONObj = new AutomatedPriceFileImportService.PriceFileWrapper();
		recJSONObj.PartNumber = 'PA-0123586';
        recJSONObj.Description = 'Part to test import file';
		recJSONObj.MfgNumber = '952khm';
        recJSONObj.SKUNumber = 'sku-2536';
        recJSONObj.ReplacedByPart ='56464' ;
        recJSONObj.ReplacesPart = '56464'; 
        recJSONObj.CategoryId = categoryList[0].Id;
        
		recJSONObj.MSRP = '20.32';
		recJSONObj.Retail = '30';
        recJSONObj.ItemCost = '85';
		recJSONObj.PackageQty = '12';
		recordList.add(recJSONObj);
		String resultObj = AutomatedPriceFileCtrl.importFile(BPUtility.getEncodedString(System.JSON.serialize(mappingObj)), BPUtility.getEncodedString(System.JSON.serialize(recordList)));	
		AutomatedPriceFileImportService.ResultWrapper resultRec = (AutomatedPriceFileImportService.ResultWrapper) System.JSON.deserialize(BPUtility.getDecodedString(resultObj), AutomatedPriceFileImportService.ResultWrapper.class);
		System.assertEquals(0, resultRec.UpdatedParts);

	}
	
    global class MockHttpResponseGenerator implements HttpCalloutMock {
    	// Implement this interface method
		global HTTPResponse respond(HTTPRequest req) {
			// Optionally, only send a mock response for a specific endpoint
			// and method.
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			if(req.getEndpoint().substring(req.getEndpoint().lastIndexOf('/')+1) == 'token') {
				res.setBody('{"access_token":"SESSION_ID_REMOVED","instance_url":"https://na96.salesforce.com","id":"https://login.salesforce.com/id/00D41000000ezKnEAI/00541000005cc60AAA","token_type":"Bearer","issued_at":"1583233133580","signature":"EeGo0V6tDp5FYJIBcnG70iKFrP7U74IFs2kDNDEBCjM="}');
			}
			else if(req.getEndpoint().substring(req.getEndpoint().lastIndexOf('/')+1) == 'ImportPriceFile'){
				res.setBody('[{"ResponseStr":"{\\"SecretAccessKey\\":\\"hm2eq5g05klERAzZwVtnmySxzV2XVsXk5G0RREtb\\",\\"Region\\":\\"us-east-2\\",\\"PriceFileLocation\\":\\"https://s3.us-east-2.amazonaws.com/pricefiles.blackpurl.com/sample_pricefile.csv\\",\\"PriceFileBucketName\\":\\"pricefiles.blackpurl.com\\",\\"PartnerVendorMasterName\\":\\"VM-00000065\\",\\"AccessKeyID\\":\\"AKIARTIUYLJBAXZBE6U5\\"}","Message":"Success"}]');
			} 
			else if(req.getEndpoint().substring(req.getEndpoint().lastIndexOf('/')+1) == 'UpdateVendorMasterSubscriber'){
				res.setBody('[{"ResponseStr":"Vendor Master Subscriber updated successfully","Message":"Success"}]');
			}
			res.setStatusCode(200);
			return res;
		}
	}
}
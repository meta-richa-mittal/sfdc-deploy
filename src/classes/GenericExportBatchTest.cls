/**
 * Author: Reena Singh
 * Since: August 28, 2020
 * Name: GenericExportBatchTest
 * Description: Batch test class to generate any export file
**/
@isTest
public without sharing class GenericExportBatchTest {
    @testSetup
    private static void testSetup() {
        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);
        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);
        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);
        Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
        unitRec.New_Unit__c = True;
        update unitRec;

        String exportType = 'Stock Unit';

        Document__c documentRec = new Document__c();
        documentRec.Public_Image_URL__c = 'Public image URL';
        documentRec.Unit__c = unitRec.Id;
        insert documentRec;      
        
        GE_File_Config__c fileConfigRec = new GE_File_Config__c(Object_API_Name__c = 'Customer_Owned_Unit__c', File_Name__c = 'Stock Unit');
        fileConfigRec.File_Content_Type__c ='.csv';
        fileConfigRec.Include_Images__c = true;
        fileConfigRec.Order_By_Clause__c = 'Name ASC';
        fileConfigRec.File_Separator__c = ',';
        fileConfigRec.Use_Public_Image__c = true;
        fileConfigRec.Send_to_FTP__c = true;
        insert fileConfigRec;
        
        GE_File_Detail__c geFileDetailRec = new GE_File_Detail__c ();
        geFileDetailRec.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRec.File_Column_Label__c = 'Make';
        geFileDetailRec.Order_Number__c = 1;
        geFileDetailRec.Data_Type__c = 'Text';
        geFileDetailRec.Field_API_Name__c ='Unit_Make__r.Name';
        geFileDetailRec.Active__c = true;
        geFileDetailRec.Default_Value__c = 'steamrvllc';
        insert geFileDetailRec;
        
        Business_Profile__c businessProfileRec = new Business_Profile__c ();
        businessProfileRec.Business_Phone__c ='1234567898';
        insert businessProfileRec;

        GE_File_Detail__c geFileDetailRecForOtherObject = new GE_File_Detail__c ();
        geFileDetailRecForOtherObject.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRecForOtherObject.File_Column_Label__c = 'Dealer Name';
        geFileDetailRecForOtherObject.Order_Number__c = 2;
        geFileDetailRecForOtherObject.Data_Type__c = 'Text';
        geFileDetailRecForOtherObject.Field_API_Name__c ='Business_Phone__c';
        geFileDetailRecForOtherObject.Active__c = true;
        geFileDetailRecForOtherObject.Other_Object_API_Name__c = 'Business_Profile__c';
        insert geFileDetailRecForOtherObject;

        GE_File_Detail__c geFileDetailRecForImage = new GE_File_Detail__c ();
        geFileDetailRecForImage.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRecForImage.File_Column_Label__c = 'Image';
        geFileDetailRecForImage.Order_Number__c = 3;
        geFileDetailRecForImage.Data_Type__c = 'Text';
        geFileDetailRecForImage.Active__c = true;
        insert geFileDetailRecForImage;

        GE_File_Detail__c geFileDetailRecForDate = new GE_File_Detail__c ();
        geFileDetailRecForDate.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRecForDate.File_Column_Label__c = 'Date';
        geFileDetailRecForDate.Order_Number__c = 4;
        geFileDetailRecForDate.Data_Type__c = 'Date';
        geFileDetailRecForDate.Active__c = true;
        geFileDetailRecForDate.Field_API_Name__c = 'Date_Stocked_Out__c';
        insert geFileDetailRecForDate;

        GE_File_Column_Override_Info__c geFileColumnOverrideInfoRec1 = new GE_File_Column_Override_Info__c();
        geFileColumnOverrideInfoRec1.GE_File_Detail__c = geFileDetailRec.Id;
        geFileColumnOverrideInfoRec1.Actual_Column_Value__c = 'True';
        geFileColumnOverrideInfoRec1.Override_Column_Value__c = 'New';
        insert geFileColumnOverrideInfoRec1;

        GE_File_Column_Override_Info__c geFileColumnOverrideInfoRec2 = new GE_File_Column_Override_Info__c();
        geFileColumnOverrideInfoRec2.GE_File_Detail__c = geFileDetailRecForOtherObject.Id;
        geFileColumnOverrideInfoRec2.Actual_Column_Value__c = 'false';
        geFileColumnOverrideInfoRec2.Override_Column_Value__c = 'Old';
        insert geFileColumnOverrideInfoRec2;

        // FTP Config
        FTP_Config__c ftpConfigRec = new FTP_Config__c ();
        ftpConfigRec.FTP_URL__c ='download2.dealervu.com';
        ftpConfigRec.FTP_Username__c ='mc_ftptest';
        ftpConfigRec.FTP_Password__c ='123test123!!!';
        ftpConfigRec.Org_Name__c ='DEV01';
        ftpConfigRec.Name = 'Stock Unit';
        ftpConfigRec.Heroku_End_Point_URL__c ='https://blackpurl-som.herokuapp.com/FTPAPI/fetchAndPostFileToFTP';
        insert ftpConfigRec;
    }
    
    @isTest
    private static void testGenericExportFile() {
        
        String exportType = 'Stock Unit';
        Test.startTest();
        Database.executeBatch(new GenericExportBatch(exportType));
        Test.stopTest();
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals(1, attachmentList.size());
    }

    @isTest
    private static void testGenericExportFileForNotPublicImage() {

        List<GE_File_Config__c> fileConfigList = [SELECT Id, Use_Public_Image__c FROM GE_File_Config__c];     
        fileConfigList[0].Use_Public_Image__c = false;
        update fileConfigList[0];
        String exportType = 'Stock Unit';

        Attachment attachment = new Attachment();
        attachment.ParentId = GenericExportService.getParentId(); 
        attachment.Name = exportType;
        attachment.ContentType =exportType;
        attachment.Body = Blob.valueOf('fileContent');
        insert attachment;
        
        Test.startTest();
        Database.executeBatch(new GenericExportBatch(exportType));
        Test.stopTest();
        
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals(2, attachmentList.size());
    }
    
    @isTest
    private static void testGenericExportForDateTime() {

        List<GE_File_Detail__c> geFileDetailList = [SELECT Id, Data_Type__c FROM GE_File_Detail__c  WHERE Data_Type__c = 'Date'];
        geFileDetailList[0].Data_Type__c = 'Date/Time';
        geFileDetailList[0].Field_API_Name__c = 'Accounting_Last_Sync_Time_Category__c';
        update geFileDetailList[0];
        String exportType = 'Stock Unit';
        
        Test.startTest();
        Database.executeBatch(new GenericExportBatch(exportType));
        Test.stopTest();
        
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals('Date/Time', geFileDetailList[0].Data_Type__c);
    }
    
    @isTest
    private static void testIntextFileExport() {
		GE_File_Config__c fileConfigRec = new GE_File_Config__c(Object_API_Name__c = 'Part__c', File_Name__c = 'INTEXT.CSV');
        fileConfigRec.File_Content_Type__c ='.csv';
        fileConfigRec.Order_By_Clause__c = 'Name ASC';
        fileConfigRec.File_Separator__c = ';';
        fileConfigRec.Include_Column_Header__c = false;
        insert fileConfigRec;
        
        GE_File_Detail__c geFileDetailRec1 = new GE_File_Detail__c ();
        geFileDetailRec1.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRec1.File_Column_Label__c = 'Col1';
        geFileDetailRec1.Order_Number__c = 1;
        geFileDetailRec1.Data_Type__c = 'Text';
        geFileDetailRec1.Field_API_Name__c ='Notes__c/Part_Number__c';
        geFileDetailRec1.Active__c = true;
        insert geFileDetailRec1;
        
        GE_File_Detail__c geFileDetailRec2 = new GE_File_Detail__c ();
        geFileDetailRec2.GE_File_Config__c = fileConfigRec.Id;
        geFileDetailRec2.File_Column_Label__c = 'Col2';
        geFileDetailRec2.Order_Number__c = 2;
        geFileDetailRec2.Data_Type__c = 'Text';
        geFileDetailRec2.Field_API_Name__c = null;
        geFileDetailRec2.Active__c = true;
        insert geFileDetailRec2;
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part1 = TestUtil.createPart(false, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 10, 20, 50, 100, 100);
        part1.Notes__c = 'These are notes for Part.';
        part1.Intext_Part_Index__c = 1;
        part1.Publish_In_Feeds__c = true;
        insert part1;
        Part__c part2 = TestUtil.createPart(false, 'TestPart2', vendor.Id, 'TestPart2', testCategory.Id, 10, 20, 50, 100, 100);
        part2.Intext_Part_Index__c = 2;
        part2.Publish_In_Feeds__c = true;
        insert part2;
        
        Test.startTest();
        Database.executeBatch(new GenericExportBatch('INTEXT.CSV', 1, 1, system.today()));
        Test.stopTest();
        
        List<Attachment> attachmentList = [SELECT Id from Attachment WHERE Name like 'INTEXT%'];
        System.assertEquals(1, attachmentList.size());
    }
}
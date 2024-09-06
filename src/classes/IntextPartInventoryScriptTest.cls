/** 
* Author: Namarta Gocher
* Since: March 07,2022 
* Name: IntextPartInventoryScriptTest 
* Description: Test class of IntextPartInventoryScript
**/
@isTest
private without sharing class IntextPartInventoryScriptTest {

    @TestSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks();
        BPScriptUtility.disbaleTrigger('CustomerOwnedUnitTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);
        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);
        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);
        Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
        unitRec.New_Unit__c = True;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);

        String exportType = 'Stock Unit';

        Document__c documentRec = TestDataFactory.createDocument('Public image URL',unitRec.Id);     
        
        GE_File_Config__c fileConfigRec = TestDataFactory.createGEFileConfig();
        
        GE_File_Detail__c geFileDetailRec = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Make',1,'Text',true);
        geFileDetailRec.Field_API_Name__c = 'Unit_Make__r.Name';
        geFileDetailRec.Default_Value__c = 'steamrvllc';
        DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailRec);

        Business_Profile__c businessProfileRec = TestDataFactory.createNewBusinessProfile();
        

        GE_File_Detail__c geFileDetailRecForOtherObject = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Dealer Name',2,'Text',true);
        geFileDetailRec.Field_API_Name__c = 'Business_Phone__c';
        geFileDetailRecForOtherObject.Other_Object_API_Name__c = 'Business_Profile__c';
        DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailRecForOtherObject);

        GE_File_Detail__c geFileDetailRecForImage = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Image',3,'Text',true);

        GE_File_Detail__c geFileDetailRecForDate = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Date',4,'Date',true);
        geFileDetailRecForDate.Field_API_Name__c = 'Date_Stocked_Out__c';
        DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailRecForDate);

        GE_File_Column_Override_Info__c geFileColumnOverrideInfoRec1 = TestDataFactory.createGeFileColumnOverrideInfo(geFileDetailRec.Id,'True','New');
        
        GE_File_Column_Override_Info__c geFileColumnOverrideInfoRec2 = TestDataFactory.createGeFileColumnOverrideInfo(geFileDetailRec.Id,'False','Old');

        // FTP Config
        FTP_Config__c ftpConfigRec = TestDataFactory.createFTPConfig();
        
    }

    @isTest
    public static void runTest(){
        
        GE_File_Config__c fileConfigRec = TestDataFactory.createGEFileConfig();
        
        GE_File_Detail__c geFileDetailRec1 = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Col1',1,'Text',true);
        geFileDetailRec1.Field_API_Name__c ='Notes__c/Part_Number__c';
        DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailRec1);
        
        GE_File_Detail__c geFileDetailRec2 = TestDataFactory.createGEFileDetail(fileConfigRec.Id,'Col2',2,'Text',true);
        geFileDetailRec2.Field_API_Name__c = null;
        DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailRec2);
        
        Account vendor = TestDataFactory.createVendor('newacc');

        Category__c testCategory = TestDataFactory.createCategory('categoryName');

        Price_Level__c defaultPriceLevel = TestDataFactory.createPriceLevel( 'Default Price Level');
        defaultPriceLevel.Default__c = true;
        DMLUtility.updateSobjectList('Price_Level__c', defaultPriceLevel);

        Sales_Tax__c defaultSalesTax = TestDataFactory.createSalesTax('Test Sales Tax');
        defaultSalesTax.Default__c = true;
        DMLUtility.updateSobjectList('Sales_Tax__c', defaultSalesTax);

        Part__c part1 = TestDataFactory.createPart( vendor.Id,10,20, 50, 100, 100, testCategory.Id);
        part1.Notes__c = 'These are notes for Part.';
        part1.Intext_Part_Index__c = 1;
        part1.Publish_In_Feeds__c = true;
        DMLUtility.updateSobjectList('Part__c', part1);

        Part__c part2 = TestDataFactory.createPart(vendor.Id, 10, 20, 50, 100, 100, testCategory.Id);
        part2.Intext_Part_Index__c = 2;
        part2.Publish_In_Feeds__c = true;
        DMLUtility.updateSobjectList('Part__c', part2);
        
        try{
            Test.startTest();
            IntextPartInventoryScript.run(system.today());
            Test.stopTest();
        }
        catch(Exception e){
        }    
    }
}

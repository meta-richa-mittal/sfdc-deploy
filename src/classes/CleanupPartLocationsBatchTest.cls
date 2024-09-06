/**
 * Author: Reena Singh
 * Since: November 10, 2020
 * Name: UpdateAssignedLocationData_BatchTest
 * Description: Batch test class for  UpdateAssignedLocationData_Batch class
**/
@isTest
public without sharing  class CleanupPartLocationsBatchTest {
    @isTest
    private static void testGenericExportFile() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Assigned_Location_1__c = ';;';
        part.Assigned_Location_2__c = ';Test;';
        
        insert part;
        Test.startTest();
        Database.executeBatch(new CleanupPartLocationsBatch());
        Test.stopTest();
        List<Part__c> partList = [Select Assigned_Location_1__c from Part__c];
        System.assertEquals(null, partList[0].Assigned_Location_1__c);
    }
}
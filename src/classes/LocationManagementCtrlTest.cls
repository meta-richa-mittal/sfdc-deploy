@isTest
private without sharing class LocationManagementCtrlTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        Account vendorRec = TestDataFactory.createVendor('Test Vendor');
        Category__c categoryRec = TestDataFactory.createCategory('Test Category');
        Part__c partRec1 = TestDataFactory.samplePart(vendorRec.Id, 2, 2, 2, 2, 3, categoryRec.Id);
        insert partRec1;
        
        Location__c location1 = TestDataFactory.sampleLocation('Location 1');   
        Location__c location2 = TestDataFactory.sampleLocation('Location 2');
        Location__c location3 = TestDataFactory.sampleLocation('Location 3');
        List<Location__c> locationList = new List<Location__c>{location1, location2, location3};
        insert locationList;
    }
    
    @isTest
    private static void testGetLocationList() {
        Test.startTest();
        String encodedJson = BPUtility.getEncodedString('{"SortBy" : "CreatedDate","Reverse": true,"LocationSearchStr": "","StartIndex" : 0,"RecordCount" : 1}');
        String locations = BPUtility.getDecodedString(LocationManagementCtrl.getPaginatedLocationList(encodedJson));
        List<LocationWrapper> locationList = (List<LocationWrapper>) System.JSON.deserialize(locations, List<LocationWrapper>.class);
        Test.stopTest();
        
        system.assertEquals(1, locationList.size());
    }
    
    @isTest
    private static void testSaveLocationWithDuplicateName() {
        String encodedJson = BPUtility.getEncodedString('{"SortBy" : "CreatedDate","Reverse": true,"LocationSearchStr": "","StartIndex" : 0,"RecordCount" : 100}');
        String locations = BPUtility.getDecodedString(LocationManagementCtrl.getPaginatedLocationList(encodedJson));
        List<LocationWrapper> locationList = (List<LocationWrapper>) System.JSON.deserialize(locations, List<LocationWrapper>.class);
        
        Test.startTest();
        locationList[0].Name = 'Location 2';
        String response = LocationManagementCtrl.saveLocation(BPUtility.getEncodedString(system.JSON.serialize(locationList[0])));
        response = BPUtility.getDecodedString(response);
        Test.stopTest();
        system.assertEquals(true, response.containsIgnoreCase('Error'));
    }
    
    @isTest
    private static void testSaveLocation() {
        String encodedJson = BPUtility.getEncodedString('{"SortBy" : "CreatedDate","Reverse": true,"LocationSearchStr": "","StartIndex" : 0,"RecordCount" : 100}');
        String locations = BPUtility.getDecodedString(LocationManagementCtrl.getPaginatedLocationList(encodedJson));
        List<LocationWrapper> locationList = (List<LocationWrapper>) System.JSON.deserialize(locations, List<LocationWrapper>.class);
        
        Test.startTest();
        locationList[0].Name = 'Updated Location';
        String response = LocationManagementCtrl.saveLocation(BPUtility.getEncodedString(system.JSON.serialize(locationList[0])));
        Test.stopTest();
        
        system.assertEquals(1, [SELECT Name__c FROM Location__c WHERE Name__c = 'Updated Location'].size());
    }
    
    @isTest
    private static void testGetLocationUsedCounter() {
        Part__c partRec = [SELECT Assigned_Location_1__c FROM Part__c limit 1];
        partRec.Assigned_Location_1__c = ';Location 1;';
        update partRec;
        
        LocationWrapper locationObj = new LocationWrapper(new Location__c(Name__c = 'Location 1'));
        
        Test.startTest();
        String counterString = LocationManagementCtrl.getLocationUsedCounter(BPUtility.getEncodedString(system.JSON.serialize(locationObj)));
        counterString = BPUtility.getDecodedString(counterString);
        UsedLocationWrapper usedLocationObj = (UsedLocationWrapper) System.JSON.deserialize(counterString, UsedLocationWrapper.class);
        Test.stopTest();
        
        system.assertEquals(1, usedLocationObj.UsedCounter);
    }
    
    private class UsedLocationWrapper {
        public Integer UsedCounter;
    }
    
    @isTest
    private static void testRemoveLocation() {
        Part__c partRec = [SELECT Assigned_Location_1__c FROM Part__c limit 1];
        partRec.Assigned_Location_1__c = ';Location 1;';
        update partRec;
        
        String encodedJson = BPUtility.getEncodedString('{"SortBy" : "CreatedDate","Reverse": true,"LocationSearchStr": "","StartIndex" : 0,"RecordCount" : 100}');
        String locations = BPUtility.getDecodedString(LocationManagementCtrl.getPaginatedLocationList(encodedJson));
        List<LocationWrapper> locationList = (List<LocationWrapper>) System.JSON.deserialize(locations, List<LocationWrapper>.class);
        
        Test.startTest();
        LocationManagementCtrl.removeLocation(BPUtility.getEncodedString(system.JSON.serialize(locationList[0])));
        Test.stopTest();
        
        system.assertEquals(2, [SELECT Name FROM Location__c].size());
    }
    
    @isTest
    private static void testGetActiveLocationList() {
        Location__c location1 = [SELECT Id FROM Location__c WHERE Name__c = 'Location 1'];
        location1.Active__c = false;
        update location1;
        
        Test.startTest();
        List<LocationWrapper> locations = LocationManagementService.getActiveLocationList();
        Test.stopTest();
        
        system.assertEquals(2, locations.size());
    }
    
    @isTest
    private static void testGetLocationsList() {
        Part__c partRec = [SELECT Assigned_Location_1__c, Assigned_Location_2__c FROM Part__c limit 1];
        partRec.Assigned_Location_1__c = ';Location 1;Location 2';
        update partRec;
        
        Test.startTest();
        List<String> locations = LocationManagementService.getLocationsList(partRec);
        Test.stopTest();
        
        system.assertEquals(2, locations.size());
    }
}
@isTest
private without sharing class PartMovementReportServiceTest {

    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account accRec = TestDataFactory.createVendor('newacc');
        
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        
        Part__c partRec = TestDataFactory.createPart(accRec.Id, 10, 12, 15, 13, 2, catRec.Id);
        
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createPartFifoBucket(partRec.Id);
        
        Part_FIFO_Bucket_Activity_Line_Item__c partBucketLineItemRec = TestDataFactory.createPartFIFOBucketActivityLineItem(partBucketRec.Id);
        partBucketLineItemRec.Part__c = partRec.Id;
        DMLUtility.updateSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', partBucketLineItemRec);
    }

    @isTest
    private static void getPartIdsHavingActivityTest(){
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Part FIFO'};
        filterWrapper.Include_Quotes = false;
        String jsonStr = System.Json.serialize(filterWrapper);

        Test.startTest();
        Set<String> partIdSet =  PartMovementReportService.getPartIdsHavingActivity(jsonStr);
        System.assertEquals(1, partIdSet.size());
        Test.stopTest();
    }

    @isTest
    private static void getPartMovementActivityReportDataTest(){
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Part FIFO'};
        filterWrapper.Include_Quotes = false;
        String jsonStr = System.Json.serialize(filterWrapper);

        Part__c part = [Select Id from Part__c];
        Set<String> partIdSet =  PartMovementReportService.getPartIdsHavingActivity(jsonStr);
        String partIdSetJson = System.JSON.serialize(partIdSet);
        Test.startTest();
        String jsonNewString = PartMovementReportService.getPartMovementActivityReportData(jsonStr, partIdSetJson);
        //HomeSearchResultWrapper.ResultWrapper result = (HomeSearchFilterWrapper.ResultWrapper) System.JSON.deserialize(jsonNewString,HomeSearchFilterWrapper.ResultWrapper.class);
        Test.stopTest();
    }

    @isTest
    private static void getPartMovementDataWithNoActivityTest(){
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Part FIFO'};
        filterWrapper.Include_Quotes = false;
        String jsonStr = System.Json.serialize(filterWrapper);
        
        Set<String> partIdSet =  PartMovementReportService.getPartIdsHavingActivity(jsonStr);
        String lastRecordUniqueFieldValue;
        PartMovementReportService.ReportWrapper reportdata = (PartMovementReportService.ReportWrapper) System.JSON.deserialize(PartMovementReportService.getPartMovementDataWithNoActivity(jsonStr,lastRecordUniqueFieldValue,System.Json.serialize(partIdSet), true), PartMovementReportService.ReportWrapper.class);
        System.assertEquals(true, reportdata.IsProcessCompleted);
    }
}

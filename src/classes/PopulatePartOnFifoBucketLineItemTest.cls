@isTest
private without sharing class PopulatePartOnFifoBucketLineItemTest {

    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account accRec = TestDataFactory.createVendor('newacc');
        
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        
        Part__c partRec = TestDataFactory.createPart(accRec.Id, 10, 12, 15, 13, 2, catRec.Id);
        
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createPartFifoBucket(partRec.Id);
        
        Part_FIFO_Bucket_Activity_Line_Item__c partBucketLineItemRec = TestDataFactory.createPartFIFOBucketActivityLineItem(partBucketRec.Id);
        partBucketLineItemRec.Part__c = null;
        DMLUtility.updateSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', partBucketLineItemRec);
    }

    @isTest
    private static void FifoBucketLineItemBatchMethodsTest(){

        Test.startTest();
        Id batchprocessid = Database.executeBatch(new PopulatePartOnFifoBucketLineItemBatch());
        Part__c part = [Select Id from Part__c];
        Part_FIFO_Bucket_Activity_Line_Item__c partBucketLineItemRec1 = [Select Id, Part__c, Part_FIFO_Bucket__r.Part__c From
                                                                        Part_FIFO_Bucket_Activity_Line_Item__c];
        System.assertEquals(part.Id,partBucketLineItemRec1.Part_FIFO_Bucket__r.Part__c);
        Test.stopTest();
    }

}

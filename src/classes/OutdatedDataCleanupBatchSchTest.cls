@isTest
private class OutdatedDataCleanupBatchSchTest {

    @TestSetup
    static void makeData(){
        //Skip FLS check
        BP_Configurations__c config = BP_Configurations__c.getOrgDefaults();
        config.Bypass_FLS_Check__c = true;
        upsert config;

        SOM_Integration__c somStorageRec = new SOM_Integration__c();
        insert somStorageRec;
        insert new Attachment(ParentId = somStorageRec.Id, Name = 'Test', Body = Blob.valueOf('test'));

        File_Storage__c ftpFSRec = new File_Storage__c(Name__c = 'FTP');
        insert ftpFSRec;
        insert new Attachment(ParentId = ftpFSRec.Id, Name = 'Test', Body = Blob.valueOf('test'));

        insert new Log__c();
    }

    @isTest
    static void batchTest() {
        system.assertEquals(1, [Select Id from Attachment WHERE ParentId IN (Select Id From SOM_Integration__c)].size());
        system.assertEquals(1, [Select Id from Attachment WHERE ParentId IN (Select Id From File_Storage__c)].size());
        Test.startTest();
        String cronExpression = QBUtil.getCronExpForGivenTime(2);
        System.schedule('OutdatedDataCleanupBatchSchTest', cronExpression, new OutdatedDataCleanupBatchSch('File'));
        Database.executeBatch(new OutdatedDataCleanupBatchSch('File'));
        Test.stopTest();
        system.assertEquals(0, [Select Id from Attachment WHERE ParentId IN (Select Id From SOM_Integration__c)].size());
        system.assertEquals(0, [Select Id from Attachment WHERE ParentId IN (Select Id From File_Storage__c)].size());
    }
}
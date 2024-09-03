@isTest
private without sharing class QBvendorCreditDTOTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        
        Account vendor = TestDataFactory.createVendor('vendorName');

        BPScriptUtility.disbaleTrigger('PartTrigger');
        
        General_Configurations__c genConfig = TestDataFactory.createGeneralConfig(1);
        
        Account accRec = TestDataFactory.createVendor('newacc');
        
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        
        Part__c partRec = TestDataFactory.createPart(vendor.Id, 10, 12, 15, 13, 2, catRec.Id);
        
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createPartFifoBucket(partRec.Id);
        
        Vendor_Invoicing_Header__c vendorInvoiceHeaderRec = TestDataFactory.createVIHeader(vendor.Id,'Completed');
        
    }
    
    @isTest
    private static void QBvendorCreditDTOMethodTest(){
        
        String viHeaderQueryStr = 'SELECT ';
        for(String fieldName : AccountingVendorInvoice.objectToFieldMap.get('VIHeader')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            viHeaderQueryStr += fieldName + ', ';
        }
        viHeaderQueryStr = viHeaderQueryStr.substring(0, viHeaderQueryStr.length()-2);
        viHeaderQueryStr += ' FROM Vendor_Invoicing_Header__c Limit 1 ';
        Vendor_Invoicing_Header__c vendorInvoiceHeaderFinalRec = Database.query(viHeaderQueryStr);
        
        Vendor_Invoicing_Group__c vendorInvoicingGroup = TestDataFactory.createVendorInvoicingGroup(vendorInvoiceHeaderFinalRec.Id);
        vendorInvoicingGroup.VI_Discount__c = 2;
        DMLUtility.updateSobjectList('Vendor_Invoicing_Group__c', vendorInvoicingGroup);
        
        String viGroupQueryStr = 'SELECT ';
        for(String fieldName : AccountingVendorInvoice.objectToFieldMap.get('VIGroup')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            viGroupQueryStr += fieldName + ', ';
        }
        viGroupQueryStr = viGroupQueryStr.substring(0, viGroupQueryStr.length()-2);
        viGroupQueryStr += ' FROM Vendor_Invoicing_Group__c ';
        List<Vendor_Invoicing_Group__c> VIGroupsList = Database.query(viGroupQueryStr);
        
        String query = 'SELECT ' + String.join(AccountingFIFOBucket.fieldsList(), ',') + ' FROM Part_FIFO_Bucket__c ';
        List<Part_FIFO_Bucket__c> PartFIFOBucketList = Database.query(query);
        Test.startTest();
        AccountingVendorInvoice accVendorInvoiceRec = new AccountingVendorInvoice(vendorInvoiceHeaderFinalRec, VIGroupsList,PartFIFOBucketList);

        QBVendorCreditDTO qbVendorDTOobj = new QBVendorCreditDTO(accVendorInvoiceRec);
        Test.stopTest();
        System.assertEquals(1, PartFIFOBucketList.size());
    }
}
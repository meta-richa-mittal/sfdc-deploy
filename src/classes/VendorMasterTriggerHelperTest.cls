@isTest
private class VendorMasterTriggerHelperTest {
    static testMethod void beforeDeleteOperationTest() {
        Vendor_Master__c vmRec = new Vendor_Master__c();
        vmRec.Partner_Vendor_Master_Identifier__c = 'Test';
        DMLUtility.insertSobjectList('Vendor_Master__c', vmRec);

        try {
            DMLUtility.deleteSobjectList('Vendor_Master__c', vmRec);
        } catch(Exception e) {}

        System.assertEquals(1, [SELECT Id FROM Vendor_Master__c].size());
    }
}
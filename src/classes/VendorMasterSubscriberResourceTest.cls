/**
 * Author: Nidhi Sharma
 * Name: VendorMasterSubscriberResourceTest
 * Description: Apex test class which contains methods related to vendor master subscriber notification.
**/
@isTest
private class VendorMasterSubscriberResourceTest {
	@testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
    }
	
    static testMethod void notifyVendorMasterSubscriberTest_Success() {
    	
    	Vendor_Master__c vendorMasterRec = new Vendor_Master__c();
    	vendorMasterRec.Partner_Vendor_Master_Identifier__c = 'VM-00000001';
    	vendorMasterRec.Partner_Vendor_Master_Identifier__c = 'VM-00000001';
    	vendorMasterRec.Vendor_Name__c = 'Test';
    	insert vendorMasterRec;

    	VendorMasterWrapper vmObj = new VendorMasterWrapper(vendorMasterRec, null);
    	vmObj.Category = 'Test';
    	
    	String response = VendorMasterSubscriberResource.notifyVendorMasterSubscriber(vmObj);
    	System.assertEquals('Success', response);
    }
    
    static testMethod void notifyVendorMasterSubscriberTest_Failure() {
    	
    	Vendor_Master__c vendorMasterRec = new Vendor_Master__c();
    	vendorMasterRec.Partner_Vendor_Master_Identifier__c = 'VM-00000001';
    	vendorMasterRec.Partner_Vendor_Master_Identifier__c = 'VM-00000001';
    	vendorMasterRec.Vendor_Name__c = 'Test';
		
    	VendorMasterWrapper vmObj = new VendorMasterWrapper(vendorMasterRec, null);
    	vmObj.Category = 'Test';
    	
    	String response = VendorMasterSubscriberResource.notifyVendorMasterSubscriber(vmObj);
    	System.assertEquals('Error', response);
    }
}
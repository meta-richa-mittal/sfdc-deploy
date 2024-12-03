@isTest 
public class VendorOrderExportCtrlTest {
	
	@testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	IFW_IntegrationConfig__c ifwIntegration = TestUtil.createIFWConfigForXero(); 
		IFW_IntegrationConfigItem__c ifwConfigItem = TestUtil.createIFWConfigItemForXero('Journal Entry', ifwIntegration.Id);
        Account vendorRec = TestDataFactory.createVendor('Test Vendor');
        Vendor_Order_Header__c vOHeaderRec = TestDataFactory.createVendorOrderHeader(vendorRec.Id);
        Category__c categoryRec = TestDataFactory.createCategory('Test category');
        
        Part__c partRec = TestDataFactory.createPart(vendorRec.Id, 10, 10, 10, 10, 2, categoryRec.Id);
        Vendor_Order_Line_Item_Group__c vendorOrderLineItemGroupRec = TestDataFactory.createVendorOrderLineItemGroup(vOHeaderRec.Id, partRec.Id);
    }
      
    @isTest
    private static void genericVendorOrderExportCtrlTest() {
    	Vendor_Order_Header__c vOHeaderRec = [SELECT Id from Vendor_Order_Header__c LIMIT 1];
    	PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'Generic (.csv)';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
  		Test.setCurrentPage(pageRef);
  		VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
  		system.assertEquals(vendorOrderExportCtrl.contentType, 'text/csv#Vendor Order.csv');
    }
    
    @isTest
    private static void partsCanadaVendorOrderExportCtrlTest() {
    	Vendor_Order_Header__c vOHeaderRec = [SELECT Id from Vendor_Order_Header__c LIMIT 1];
    	PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'Parts Canada (.csv)';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
  		Test.setCurrentPage(pageRef);
  		VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
  		system.assertEquals(vendorOrderExportCtrl.contentType, 'text/csv#Vendor Order.csv');
    }
    
    @isTest
    private static void hondaEBizVendorOrderExportCtrlTest() {
    	Vendor_Order_Header__c vOHeaderRec = [SELECT Id from Vendor_Order_Header__c LIMIT 1];
    	PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'Honda eBiz';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
  		Test.setCurrentPage(pageRef);
  		VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
  		system.assertEquals(vendorOrderExportCtrl.contentType, 'text/plain/#HNVENDOR.DAT');
    }
    
    @isTest
    private static void hDnetAustraliaVendorOrderExportCtrlTest() {
    	Vendor_Order_Header__c vOHeaderRec = [SELECT Id, Name from Vendor_Order_Header__c LIMIT 1];
    	PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'HDnet Australia';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
  		Test.setCurrentPage(pageRef);
  		VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
  		system.assertEquals(vendorOrderExportCtrl.contentType, 'text/plain/#' + vOHeaderRec.Name + '.txt');
    }
    
    @isTest
    private static void bossWebVendorOrderExportCtrlTest() {
    	Vendor_Order_Header__c vOHeaderRec = [SELECT Id, Name from Vendor_Order_Header__c LIMIT 1];
    	PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'BossWeb';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
  		Test.setCurrentPage(pageRef);
  		VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
  		system.assertEquals(vendorOrderExportCtrl.contentType.contains('.txt'), true);
    }
    
    @isTest
    private static void yamahaAustraliaVendorOrderExportCtrlTest() {
        Yamaha_Australia_Config__c yamahaRec = new Yamaha_Australia_Config__c();
        yamahaRec.Dealer_Code__c = '123';
        yamahaRec.Sales_Person_Code__c = '123';
        yamahaRec.User_ID__c = '123';
        insert yamahaRec;
        
        Vendor_Order_Header__c vOHeaderRec = [SELECT Id, Name, Status__c from Vendor_Order_Header__c LIMIT 1];
        vOHeaderRec.Status__c = 'Open';
        update vOHeaderRec;
        
        PageReference pageRef = Page.VendorOrderExport;
        VendorOrderExportCtrl.VOExportParams paramObj = new VendorOrderExportCtrl.VOExportParams();
        paramObj.VOHeaderId = vOHeaderRec.Id;
        paramObj.ExportType = 'Yamaha Australia';
  		pageRef.getParameters().put('params', BPUtility.getEncodedString(System.JSON.serialize(paramObj)));
        Test.setCurrentPage(pageRef);
        VendorOrderExportCtrl vendorOrderExportCtrl = new VendorOrderExportCtrl();
        system.assertEquals(vendorOrderExportCtrl.contentType.contains('.txt'), false);
    }
}
/**
 * Author: Gaurav Tak
 * Since: July 06, 2018
 * Name: CustomerOrderCtrl_V2Test
 * Description: Controller test Class of CustomerOrder_V2.
**/
@isTest
public class CustomerOrderCtrl_V2Test {
	
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.createNameSpaceInGeneralConfig();
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        vendor.Vendor_Code__c = 'BP Vendor Code 1';
        insert vendor;
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        Account customerIndividual = TestUtil.createCustomer(true, 'Test Customer', 'test@blackpurl.com', 'Jaipur', '9874563210',defaultPriceLevel.Id, defaultSalesTax.Id, false, true, 'Individual' );
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, customerIndividual.Id);
        CO_Header__c coHeader2 = TestUtil.createCOHeader(true, customerIndividual.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', coHeader1.Id, 'Description', 100, True);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader1.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        CO_Deposit__c coDeposit = TestUtil.createCODeposit(true, coHeader1.Id, 'Debit', 500);
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customerIndividual.Id, unitmake.Id, unitmodel.Id, null);
    }
    
    @isTest
    private static void getCOHeaderDetailsByGridNameTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(coHeaderId, null));
    	CustomerOrderWrapper.COHeaderWrapper coHeaderWrapper = (CustomerOrderWrapper.COHeaderWrapper)System.JSON.deserialize(response, CustomerOrderWrapper.COHeaderWrapper.class);
    	system.assertEquals(coHeader1.Id,coHeaderWrapper.coHeaderRec.COHeaderId);
    }
    
    @isTest
    private static void createSOHeaderTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(coHeaderId));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperList = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(response, List<ServiceOrderWrapper.SOWrapper>.class);
        system.assertNotEquals(null, soWrapperList[0].SOInfo.Id);
    }
    
    @isTest
    private static void getSOMasterDataTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String createResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(coHeaderId));
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSOMasterData(coHeaderId));
    	ServiceOrderWrapper.SOMasterData masterDataObj = (ServiceOrderWrapper.SOMasterData)System.JSON.deserialize(response, ServiceOrderWrapper.SOMasterData.class);
    	system.assert(true, masterDataObj.COUList.size() > 0);
    }
    
    @isTest
    private static void getSOHeaderDetailsTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String createResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(coHeaderId));
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getSOHeaderDetails(coHeaderId,null));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperList = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(response, List<ServiceOrderWrapper.SOWrapper>.class);
        system.assertNotEquals(null, soWrapperList[0].SOInfo.Id);
    }
    
    @isTest
    private static void addLineItemsTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	Part__c part =[SELECT Id From Part__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String createResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(coHeaderId));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperList = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(createResponse, List<ServiceOrderWrapper.SOWrapper>.class);
    	CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(part.Id, null);
        String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(System.JSON.serialize(lineObj)),BPUtility.getEncodedString(soWrapperList[0].SOInfo.Id)));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperListResponse = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(response, List<ServiceOrderWrapper.SOWrapper>.class);
    	system.assert(true, soWrapperListResponse[0].SOGridItems[0].SOLIList[0].IsPart);
    }
    
    @isTest
    private static void updateSOLineItemsTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	Part__c part =[SELECT Id From Part__c][0];
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	//so header creation
    	String createResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(coHeaderId));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperList = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(createResponse, List<ServiceOrderWrapper.SOWrapper>.class);
    	
    	//adding line item
        CustomerOrderWrapper.LineItemWrapper lineObj = new CustomerOrderWrapper.LineItemWrapper(part.Id, null);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addLineItems(BPUtility.getEncodedString(System.JSON.serialize(lineObj)),BPUtility.getEncodedString(soWrapperList[0].SOInfo.Id)));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperListResponse = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(response, List<ServiceOrderWrapper.SOWrapper>.class);
    	
    	//updating line item
    	soWrapperListResponse[0].SOGridItems[0].SOLIList[0].QtyNeeded = 300.00 ;
        
        //update line item
        Test.startTest();
        String updateResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(
        	BPUtility.getEncodedString(System.JSON.serialize(soWrapperListResponse[0].SOGridItems[0].SOLIList[0])), 
        	BPUtility.getEncodedString(soWrapperListResponse[0].SOInfo.Id)));
        List<ServiceOrderWrapper.SOWrapper> soWrapperUpdateResponse = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(updateResponse, List<ServiceOrderWrapper.SOWrapper>.class);
    	Test.stopTest();
    	system.assertEquals(300.00, soWrapperUpdateResponse[0].SOGridItems[0].SOLIList[0].QtyNeeded);
    }
    
    @isTest
    private static void addPartsSmartItemsTest() {
    	CO_Header__c coHeader1 =[SELECT Id From CO_Header__c][0];
    	Part__c part =[SELECT Id, Part_Number__c, Vendor_Code__c From Part__c][0];
    	TestUtil.enableARIPartsmart();
    	TestUtil.createVendorCodeMappingForARIPartsmart(new Map<String, String>{'Partsmart Vendor Code 1' => 'BP Vendor Code 1'});
    	COService.SearchPartDetailWrapper partsInfo1 = new COService.SearchPartDetailWrapper();
    	partsInfo1.PartNumber = part.Part_Number__c;
    	partsInfo1.Manufacturer = 'Partsmart Vendor Code 1';
    	partsInfo1.Qty = 2;
    	
    	system.assertEquals(1, [Select Id from CO_Line_Item__c where CO_Header__c =: coHeader1.Id].size());
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPartsSmartItems_Updated(BPUtility.getEncodedString(System.JSON.serialize(new List<COService.SearchPartDetailWrapper>{partsInfo1})), BPUtility.getEncodedString('Merchandise'), BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString(Constants.ARI_Partsmart8)));
    	system.assertEquals(2, [Select Id from CO_Line_Item__c where CO_Header__c =: coHeader1.Id].size());
    	
    	Test.startTest();
    	String createResponse = BPUtility.getDecodedString(CustomerOrderCtrl_V2.createSOHeader(BPUtility.getEncodedString(coHeader1.Id)));
    	List<ServiceOrderWrapper.SOWrapper> soWrapperList = (List<ServiceOrderWrapper.SOWrapper>)System.JSON.deserialize(createResponse, List<ServiceOrderWrapper.SOWrapper>.class);
    	
    	system.assertEquals(0, [Select Id from Service_Order_Line_Item__c where Service_Order_Header__c =: soWrapperList[0].SOInfo.Id].size());
    	
	COService.SearchPartDetailWrapper partsInfo2 = new COService.SearchPartDetailWrapper();
   	partsInfo2.PartNumber = part.Part_Number__c;
   	partsInfo2.Manufacturer = 'Vendor Code not exist in BP';
   	partsInfo2.Qty = 2;
   	response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPartsSmartItems_Updated(BPUtility.getEncodedString(System.JSON.serialize(new List<COService.SearchPartDetailWrapper>{partsInfo1, partsInfo2})), BPUtility.getEncodedString('Service Job'), BPUtility.getEncodedString(soWrapperList[0].SOInfo.Id), BPUtility.getEncodedString(Constants.ARI_Partsmart8)));
    	/*Map<String, List<COService.SearchPartDetailWrapper>> partNotInBPList = (Map<String, List<COService.SearchPartDetailWrapper>>)System.JSON.deserialize(response, Map<String, List<COService.SearchPartDetailWrapper>>.class);
    	system.assertEquals(3, partNotInBPList.size());
        system.assertEquals(1, partNotInBPList.get('Parts not found').size());*/
         system.assertEquals(1, [Select Id from Service_Order_Line_Item__c where Service_Order_Header__c =: soWrapperList[0].SOInfo.Id].size()); 
      Test.stopTest();    	

    }
    
    @isTest
    private static void getTextHistoryForCOTest() {
        List<Account> customerList = [Select Id FROM Account WHERE Is_Customer__c = true limit 1];
        List<CO_Header__c> coHeaderList = [Select Id FROM CO_Header__c limit 1];
        
        String customerId = customerList.size() > 0 ? customerList[0].Id : null;
        String coHeaderId = coHeaderList.size() > 0 ? coHeaderList[0].Id : null;
        
        List<Message_History__c> msgHistoryToInsert = new List<Message_History__c>();
        Message_History__c msgHistoryRec1 = new Message_History__c();
        msgHistoryRec1.Activity__c = 'Text Message';
        msgHistoryRec1.Sent_To__c = customerId;
        msgHistoryRec1.SMS_Body__c = 'Test Text Message From CO';
        msgHistoryRec1.CO_Header__c = coHeaderId;
        msgHistoryRec1.SMS_Direction__c = Constants.SMS_DIRECTION_SENT;
        msgHistoryRec1.SMS_Sent_From__c = Constants.SMS_SENT_FROM_CO;
        msgHistoryRec1.Sent_By__c = UserInfo.getUserId();
        
        Message_History__c msgHistoryRec2 = new Message_History__c();
        msgHistoryRec2.Activity__c = 'Text Message';
        msgHistoryRec2.Sent_To__c = customerId;
        msgHistoryRec2.SMS_Body__c = 'Test Text Message From Customer';
        msgHistoryRec2.SMS_Direction__c = Constants.SMS_DIRECTION_SENT;
        msgHistoryRec2.SMS_Sent_From__c = Constants.SMS_SENT_FROM_CUSTOMER;
        msgHistoryRec2.Sent_By__c = UserInfo.getUserId();
        
        msgHistoryToInsert.add(msgHistoryRec1);
        msgHistoryToInsert.add(msgHistoryRec2);
        insert msgHistoryToInsert;
        
        String textHistoryJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getTextHistory(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(coHeaderId)));
        List<CustomerDetail.MessageHistory> textHistory = (List<CustomerDetail.MessageHistory>) System.JSON.deserialize(textHistoryJson, List<CustomerDetail.MessageHistory>.class);
        system.assertEquals(textHistory.size() , 2);
	}

    @isTest
    private static void addCustomerTest1() {
    	CO_Header__c coHeader1 =[SELECT Id FROM CO_Header__c][0];
    	Account customer = [SELECT Id FROM Account WHERE Is_Customer__c = true][0];
        Customer_Owned_Unit__c customerOwnedUnit = [SELECT Id FROM Customer_Owned_Unit__c][0];
        Service_Order_Header__c soHeader = TestDataFactory.createSOHeader(coHeader1.Id);
        Event__c eventRecWithSOHeader = TestDataFactory.createEventWithServiceHeader(customer.Id, customerOwnedUnit.Id, soHeader.Id);
        Price_Level__c priceLevel = TestUtil.createPriceLevel(false, 'Test');
        priceLevel.Default__c = true;
        insert priceLevel;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader1.Id, Status__c = 'Approved', Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Is_Stocked_In__c = false, Type__c = Constants.DEAL_ITEM_TYPE_TRADE_IN, Deal__c = deal.Id); 
        insert dealItem;
        Account_Type__c accountType = new Account_Type__c(Default__c = true, Applies_To__c = 'Customers');   
        insert accountType;
        Test.startTest();
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String customerId = BPUtility.getEncodedString(customer.Id);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addCustomer(coHeaderId, customerId));
        Test.stopTest();
    	ResponseWrapper responseObj = (ResponseWrapper)System.JSON.deserialize(response, ResponseWrapper.class);
        system.assertEquals(200, responseObj.responseCode);
}

    @isTest
    private static void addCustomerTest2() {
        CO_Header__c coHeader = TestUtil.createCOHeader(true, null);
        Price_Level__c priceLevel = TestUtil.createPriceLevel(false, 'Test');
        Customer_Owned_Unit__c customerOwnedUnit = [SELECT Id FROM Customer_Owned_Unit__c][0];
        Service_Order_Header__c soHeader = TestDataFactory.createSOHeader(coHeader.Id);
        Event__c eventRecWithSOHeader = TestDataFactory.createEventWithServiceHeader(null, customerOwnedUnit.Id, soHeader.Id);
        priceLevel.Default__c = true;
        insert priceLevel;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.Id, Status__c = 'Approved', Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Is_Stocked_In__c = false, Type__c = Constants.DEAL_ITEM_TYPE_TRADE_IN, Deal__c = deal.Id); 
        insert dealItem;
        Account_Type__c accountType = new Account_Type__c(Default__c = true, Applies_To__c = 'Customers');   
        insert accountType;
        Test.startTest();
    	String coHeaderId = BPUtility.getEncodedString(coHeader.Id);
    	String customerId = BPUtility.getEncodedString(null);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addCustomer(coHeaderId, customerId));
        Test.stopTest();
    	ResponseWrapper responseObj = (ResponseWrapper)System.JSON.deserialize(response, ResponseWrapper.class);
        system.assertEquals(200, responseObj.responseCode);
    }

    @isTest
    private static void addCustomerTest3() {
    	CO_Header__c coHeader1 =[SELECT Id FROM CO_Header__c][0];
        Customer_Owned_Unit__c customerOwnedUnit = [SELECT Id FROM Customer_Owned_Unit__c][0];
        Service_Order_Header__c soHeader = TestDataFactory.createSOHeader(coHeader1.Id);
        Event__c eventRecWithSOHeader = TestDataFactory.createEventWithServiceHeader(null, customerOwnedUnit.Id, soHeader.Id);
        Price_Level__c priceLevel = TestUtil.createPriceLevel(false, 'Test');
        priceLevel.Default__c = true;
        insert priceLevel;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader1.Id, Status__c = 'Approved', Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Is_Stocked_In__c = false, Type__c = Constants.DEAL_ITEM_TYPE_TRADE_IN, Deal__c = deal.Id); 
        insert dealItem;
        Account_Type__c accountType = new Account_Type__c(Default__c = true, Applies_To__c = 'Customers');   
        insert accountType;
        Test.startTest();
    	String coHeaderId = BPUtility.getEncodedString(coHeader1.Id);
    	String customerId = BPUtility.getEncodedString(null);
    	String response = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addCustomer(coHeaderId, customerId));
        Test.stopTest();
    	ResponseWrapper responseObj = (ResponseWrapper)System.JSON.deserialize(response, ResponseWrapper.class);
        system.assertEquals(200, responseObj.responseCode);
    }
}
/**
 * Author: Nidhi Sharma
 * Since: Sept 09, 2019
 * Name: PartCountControllerTest
 * Description: 
**/
@isTest()
private class PartCountControllerTest {
    
    @TestSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
        //Xero IFW_IntegrationConfig__c Record
		IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
       //Xero IFW_IntegrationConfigItem__c Record
       IFW_IntegrationConfigItem__c IFWConfigItemObj = new IFW_IntegrationConfigItem__c();
       IFWConfigItemObj.Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/ManualJournals';
       IFWConfigItemObj.HTTP_Method__c = 'POST';
       IFWConfigItemObj.Timeout__c = 5000;
       IFWConfigItemObj.IFW_IntegrationConfig__c = IFWConfigObj.Id;
       IFWConfigItemObj.Subscriber_Record_Id__c = 'a2G1K000003YyYkUAK';
       IFWConfigItemObj.Entity_Name__c = 'Journal Entry';
       IFWConfigItemObj.Entity_Action__c = 'Create;Update';
       insert IFWConfigItemObj;
        
        Count_Session__c countSessionRec = new Count_Session__c();
        countSessionRec.Name__c = 'Count #1';
        countSessionRec.Type__c = 'Random Count';
        countSessionRec.Status__c = 'In Progress';
        insert countSessionRec;
        
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category', 'Part', 'Test Desc', true, true);
        
        Location__c location1 = new Location__c(Name__c = 'Jaipur', Active__c = true);
        Location__c location2 = new Location__c(Name__c = 'Jodhpur', Active__c = true);
        Location__c location3 = new Location__c(Name__c = 'Ajmer', Active__c = false);
        insert new List<Location__c>{location1, location2, location3};
        
        Account vendor1 = TestUtil.createVendor(false, 'Test Vendor 1');
        vendor1.Active__c = true;
        vendor1.Vendor_Code__c = 'VDR1';
        Account vendor2 = TestUtil.createVendor(false, 'Test Vendor 2');
        vendor2.Active__c = true;
        vendor1.Vendor_Code__c = 'VDR2';
        insert new List<Account>{vendor1, vendor2};
        
		BPScriptUtility.disbaleTrigger('PartTrigger');
		BPScriptUtility.disbaleTrigger('CountSessionTrigger');

        Part__c part1 = TestUtil.createPart(false, 'Part #1', vendor1.Id, 'Test Part 1', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part2 = TestUtil.createPart(false, 'Part #2', vendor1.Id, 'Test Part 2', testCategory.Id, 10, 20, 50, 100, 0);
        Part__c part3 = TestUtil.createPart(false, 'Part #3', vendor2.Id, 'Test Part 3', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part4 = TestUtil.createPart(false, 'Part #1', vendor2.Id, 'Test Part 4', testCategory.Id, 10, 20, 50, 100, 100);
        insert new List<Part__c>{part1, part2, part3, part4};
    }
    
    static testMethod void getCountSessionListByTabNameTestSuccess() {
    	String response = BPUtility.getDecodedString(PartCountController.getCountSessionListByTabName(BPUtility.getEncodedString('Open Count')));
    	List<CountSessionWrapper> countSessionObjList = (List<CountSessionWrapper>) System.JSON.deserialize(response, List<CountSessionWrapper>.class);
    	system.assertEquals(1, countSessionObjList.size());
    }
	
    static testMethod void getActiveLocationListTest() {
    	String response = BPUtility.getDecodedString(PartCountController.getActiveLocationList());
    	List<LocationWrapper> locationObjList = (List<LocationWrapper>) System.JSON.deserialize(response, List<LocationWrapper>.class);
		system.assertEquals(2, locationObjList.size());
		system.assertEquals(true, (locationObjList[0].Name == 'Jaipur' || locationObjList[0].Name == 'Jodhpur'));
    }
    
    static testMethod void getVendorListTest() {
    	String response = BPUtility.getDecodedString(PartCountController.getVendorList());
    	List<Vendor> vendorObjList = (List<Vendor>) System.JSON.deserialize(response, List<Vendor>.class);
		system.assertEquals(2, vendorObjList.size());
		system.assertEquals(true, (vendorObjList[0].VendorName == 'Test Vendor 1' || vendorObjList[0].VendorName == 'Test Vendor 2'));
    }

	static testMethod void getAdjustmentCategoriesTest(){
		String jsonString = PartCountController.getAdjustmentCategories();
		 
	}

	static testMethod void getCountSessionSearchResultTest(){
		
	}

	static testMethod void deleteAllIssuesTest(){
		PartCountController.exportCountSession('countSessionId', 'lineItemTabName');
		Count_Session__c countSessionRec  = [Select Id,Name from Count_Session__c ];
		//System.assertEquals(1, countSessionRec.size());
		PartCountController.deleteAllIssues(BPUtility.getEncodedString(countSessionRec.Id));
		List<Count_Session__c> countSessionRec1  = [Select Id,Name from Count_Session__c ];
		System.assertEquals(1, countSessionRec1.size());
	}
    
    static testMethod void getPartCategoriesTest() {
    	String response = BPUtility.getDecodedString(PartCountController.getPartCategories());
    	List<CategoryService.CategoryWrapper> categoryObjList = 
    					(List<CategoryService.CategoryWrapper>) System.JSON.deserialize(response, List<CategoryService.CategoryWrapper>.class);
		system.assertEquals(1, categoryObjList.size());
		system.assertEquals('Test Category', categoryObjList[0].Name);
    }
    
    static testMethod void getCountSessionDetailByIdTest() {
    	List<Count_Session__c> countSessionRecList = [Select Id from Count_Session__c Limit 1];
    	String response = BPUtility.getDecodedString(PartCountController.getCountSessionDetailById(BPUtility.getEncodedString(countSessionRecList[0].Id)));
    	CountSessionWrapper countSessionObj = (CountSessionWrapper) System.JSON.deserialize(response, CountSessionWrapper.class);
    	system.assertEquals('Count #1', countSessionObj.Name);
		system.assertEquals('Random count', countSessionObj.Type);
    }
    
    static testMethod void saveCountSessionTest() {
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1';
        countSessionWrapperObj.Type = 'Cycle Count';
        countSessionWrapperObj.SelectedVendorIds = new List<String>{vendorList[0].Id};
        
    	String response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	system.assertEquals('Success', response);
    	Test.stopTest();
    }
    
    static testMethod void getCountSessionLineItemsByCountSessionIdTest() {
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1';
        countSessionWrapperObj.Type = 'Cycle Count';
        countSessionWrapperObj.SelectedVendorIds = new List<String>{vendorList[0].Id};
        
    	String response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	system.assertEquals('Success', response);
    	Test.stopTest();
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionListByTabName(BPUtility.getEncodedString('Open Count')));
    	List<CountSessionWrapper> countSessionObjList = (List<CountSessionWrapper>) System.JSON.deserialize(response, List<CountSessionWrapper>.class);
    	
    	PartCountService.PageInfoWrapper pageInfoObj = new PartCountService.PageInfoWrapper();
    	pageInfoObj.CurrentPage = 1;
    	pageInfoObj.PageSize = 10;
    	pageInfoObj.TabName = 'Uncounted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionObjList[1].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		CountSessionLineItemWrapper countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);

    	system.assertEquals(1, countSessionLineItemWrapperObj.CountSessionLineItems.size());
		system.assertEquals(10, countSessionLineItemWrapperObj.PageSize);
		system.assertEquals(1, countSessionLineItemWrapperObj.TotalRecords);
		system.assertEquals(100, countSessionLineItemWrapperObj.CountSessionLineItems[0].QtyAvailable);
		
    	pageInfoObj.TabName = 'Counted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionObjList[1].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		system.assertEquals(0, countSessionLineItemWrapperObj.CountSessionLineItems.size());
		system.assertEquals(10, countSessionLineItemWrapperObj.PageSize);
		system.assertEquals(0, countSessionLineItemWrapperObj.TotalRecords);
		
    }
    
    static testMethod void getSelectedPartInfoTest() {
    	
    	List<Count_Session__c> countSessionRecList = [Select Id from Count_Session__c where Type__c = 'Random Count'];
    	List<Part__c> partRecList = [Select Id from Part__c where Part_Number__c = 'Part #1'];
    	
    	String response = BPUtility.getDecodedString(PartCountController.getSelectedPartInfo(BPUtility.getEncodedString(countSessionRecList[0].Id), 
    																										BPUtility.getEncodedString(partRecList[0].Id)));
    	CountSessionLineItemWrapper.CountSessionLineItem countSessionLineItemObj = 
    				(CountSessionLineItemWrapper.CountSessionLineItem) System.JSON.deserialize(response, CountSessionLineItemWrapper.CountSessionLineItem.class);
    	
    	//Line Item not added in counted parts
    	system.assertEquals(null, countSessionLineItemObj.Id);
    	system.assertEquals(partRecList[0].Id, countSessionLineItemObj.PartId);
    	system.assertEquals(false, countSessionLineItemObj.IsAlreadyCounted);
    	system.assertEquals(false, countSessionLineItemObj.IsSelectedPart);
    	
    	//Line added in uncounted parts
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1'; 
        countSessionWrapperObj.Type = 'Cycle Count';
        countSessionWrapperObj.SelectedVendorIds = new List<String>{vendorList[0].Id};
        
    	response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	Test.stopTest();
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionListByTabName(BPUtility.getEncodedString('Open Count')));
    	List<CountSessionWrapper> countSessionObjList = (List<CountSessionWrapper>) System.JSON.deserialize(response, List<CountSessionWrapper>.class);
    	
    	PartCountService.PageInfoWrapper pageInfoObj = new PartCountService.PageInfoWrapper();
    	pageInfoObj.CurrentPage = 1;
    	pageInfoObj.PageSize = 10;
    	pageInfoObj.TabName = 'Uncounted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionObjList[1].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		CountSessionLineItemWrapper countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		
    	response = BPUtility.getDecodedString(PartCountController.getSelectedPartInfo(BPUtility.getEncodedString(countSessionObjList[1].Id), 
    																										BPUtility.getEncodedString(partRecList[0].Id)));
    	countSessionLineItemObj = (CountSessionLineItemWrapper.CountSessionLineItem) System.JSON.deserialize(response, CountSessionLineItemWrapper.CountSessionLineItem.class);
    	//Line Item not added in counted parts
    	system.assertEquals(countSessionLineItemWrapperObj.CountSessionLineItems[0].Id, countSessionLineItemObj.Id);
    	system.assertEquals(partRecList[0].Id, countSessionLineItemObj.PartId);
    	system.assertEquals(false, countSessionLineItemObj.IsAlreadyCounted);
    	system.assertEquals(true, countSessionLineItemObj.IsSelectedPart);
    }
    
    static testMethod void saveCountSessionLineItem() {
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1';
        countSessionWrapperObj.Type = 'Cycle Count';
        countSessionWrapperObj.SelectedVendorIds = new List<String>{vendorList[0].Id};
        
    	String response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	system.assertEquals('Success', response);
    	Test.stopTest();
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionListByTabName(BPUtility.getEncodedString('Open Count')));
    	List<CountSessionWrapper> countSessionObjList = (List<CountSessionWrapper>) System.JSON.deserialize(response, List<CountSessionWrapper>.class);
    	
    	PartCountService.PageInfoWrapper pageInfoObj = new PartCountService.PageInfoWrapper();
    	pageInfoObj.CurrentPage = 1;
    	pageInfoObj.PageSize = 10;
    	pageInfoObj.TabName = 'Uncounted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionObjList[1].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		CountSessionLineItemWrapper countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);

    	system.assertEquals(1, countSessionLineItemWrapperObj.CountSessionLineItems.size());
		system.assertEquals(0, countSessionLineItemWrapperObj.CountSessionLineItems[0].CountedQty);
		system.assertEquals(10, countSessionLineItemWrapperObj.PageSize);
		system.assertEquals(1, countSessionLineItemWrapperObj.TotalRecords);
		system.assertEquals(100, countSessionLineItemWrapperObj.CountSessionLineItems[0].QtyAvailable);
		
		countSessionLineItemWrapperObj.CountSessionLineItems[0].CountedQty = 3;
		response = BPUtility.getDecodedString(PartCountController.saveCountSessionLineItem(
														BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemWrapperObj.CountSessionLineItems[0]))));
    	system.assertEquals('success', response.toLowerCase());
    	
    	pageInfoObj.TabName = 'Counted Parts';
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionObjList[1].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		system.assertEquals(1, countSessionLineItemWrapperObj.CountSessionLineItems.size());
		system.assertEquals(3, countSessionLineItemWrapperObj.CountSessionLineItems[0].CountedQty);
    }

	static testMethod void resolveCountIssueTest() {
		List<Count_Session__c> countSessionRecList = [Select Id from Count_Session__c where Type__c = 'Random Count'];
    	List<Part__c> partRecList = [Select Id from Part__c where Part_Number__c = 'Part #1'];
    	
    	String response = BPUtility.getDecodedString(PartCountController.getSelectedPartInfo(BPUtility.getEncodedString(countSessionRecList[0].Id), 
    																										BPUtility.getEncodedString(partRecList[0].Id)));
    	CountSessionLineItemWrapper.CountSessionLineItem countSessionLineItemObj = 
    				(CountSessionLineItemWrapper.CountSessionLineItem) System.JSON.deserialize(response, CountSessionLineItemWrapper.CountSessionLineItem.class);
    	
    	//Line Item not added in counted parts
    	system.assertEquals(null, countSessionLineItemObj.Id);
    	system.assertEquals(partRecList[0].Id, countSessionLineItemObj.PartId);
    	system.assertEquals(0, countSessionLineItemObj.CountedQty);
    	system.assertEquals(false, countSessionLineItemObj.IsAlreadyCounted);
    	system.assertEquals(false, countSessionLineItemObj.IsSelectedPart);
    	
    	countSessionLineItemObj.CountedQty = 2;
    	countSessionLineItemObj.CountSessionId = countSessionRecList[0].Id;
    	response = BPUtility.getDecodedString(PartCountController.saveCountSessionLineItem(
														BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemObj))));
		
		PartCountService.PageInfoWrapper pageInfoObj = new PartCountService.PageInfoWrapper();
    	pageInfoObj.CurrentPage = 1;
    	pageInfoObj.PageSize = 10;
    	pageInfoObj.TabName = 'Counted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionRecList[0].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		CountSessionLineItemWrapper countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		
		system.assertEquals(1, countSessionLineItemWrapperObj.CountSessionLineItems.size());						
    	
		
    	String response1 = BPUtility.getDecodedString( PartCountController.resolveCountIssue(BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemObj)), BPUtility.getEncodedString(countSessionLineItemWrapperObj.CountSessionLineItems[0].Id)));
		system.assertEquals('success', response1.toLowerCase());
    					
    }

	static testMethod void checkForCompletedCountSession(){
		Count_Session__c countSessionRec  = [Select Id,Name from Count_Session__c Limit 1];
		String response = PartCountController.checkForCompletedCountSession(BPUtility.getEncodedString(countSessionRec.Id));
		System.assertEquals('Please wait while the uncounted parts list is being generated.', BPUtility.getDecodedString(response));
	}
    
    static testMethod void deleteCountSessionLineItem() {
		List<Count_Session__c> countSessionRecList = [Select Id from Count_Session__c where Type__c = 'Random Count'];
    	List<Part__c> partRecList = [Select Id from Part__c where Part_Number__c = 'Part #1'];
    	
    	String response = BPUtility.getDecodedString(PartCountController.getSelectedPartInfo(BPUtility.getEncodedString(countSessionRecList[0].Id), 
    																										BPUtility.getEncodedString(partRecList[0].Id)));
    	CountSessionLineItemWrapper.CountSessionLineItem countSessionLineItemObj = 
    				(CountSessionLineItemWrapper.CountSessionLineItem) System.JSON.deserialize(response, CountSessionLineItemWrapper.CountSessionLineItem.class);
    	
    	//Line Item not added in counted parts
    	system.assertEquals(null, countSessionLineItemObj.Id);
    	system.assertEquals(partRecList[0].Id, countSessionLineItemObj.PartId);
    	system.assertEquals(0, countSessionLineItemObj.CountedQty);
    	system.assertEquals(false, countSessionLineItemObj.IsAlreadyCounted);
    	system.assertEquals(false, countSessionLineItemObj.IsSelectedPart);
    	
    	countSessionLineItemObj.CountedQty = 2;
    	countSessionLineItemObj.CountSessionId = countSessionRecList[0].Id;
    	response = BPUtility.getDecodedString(PartCountController.saveCountSessionLineItem(
														BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemObj))));
		
		PartCountService.PageInfoWrapper pageInfoObj = new PartCountService.PageInfoWrapper();
    	pageInfoObj.CurrentPage = 1;
    	pageInfoObj.PageSize = 10;
    	pageInfoObj.TabName = 'Counted Parts';
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionRecList[0].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		CountSessionLineItemWrapper countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		
		system.assertEquals(1, countSessionLineItemWrapperObj.CountSessionLineItems.size());						
    	response = BPUtility.getDecodedString(PartCountController.deleteCountSessionLineItem(
    													BPUtility.getEncodedString(countSessionLineItemWrapperObj.CountSessionLineItems[0].Id)));
    	system.assertEquals('success', response.toLowerCase());
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionLineItemsByCountSessionId(
							BPUtility.getEncodedString(countSessionRecList[0].Id), BPUtility.getEncodedString(System.JSON.serialize(pageInfoObj))));
		countSessionLineItemWrapperObj = (CountSessionLineItemWrapper) System.JSON.deserialize(response, CountSessionLineItemWrapper.class);
		system.assertEquals(0, countSessionLineItemWrapperObj.CountSessionLineItems.size());				
    }
    
    static testMethod void finalizeCountSessionTest() {
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        List<Category__c> categoryList = [Select Id from Category__c where Name = 'Test Category'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1 Test Finalize';
        countSessionWrapperObj.Type = 'Cycle count';
        countSessionWrapperObj.SelectedCategoryIds = new List<String>{categoryList[0].Id};
        
    	String response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	system.assertEquals('Success', response);
    	
    	List<Count_Session__c> countSessionRecList = [Select id from Count_Session__c where Name__c = 'Count #1 Test Finalize'];
    	
    	response = BPUtility.getDecodedString(PartCountController.getCountSessionDetailById(BPUtility.getEncodedString(countSessionRecList[0].Id)));
    	CountSessionWrapper countSessionObj = (CountSessionWrapper) System.JSON.deserialize(response, CountSessionWrapper.class);
    	
    	Test.stopTest();
    	
    	Category__c testCategory = TestUtil.createCategory(true, 'Stock Adjustment', 'Adjustment', 'Test Desc', true, true);
        
    	countSessionObj.IsAdjustUncountedPartsToZeroQty = true;
    	countSessionObj.AdjustmentCategoryId = testCategory.Id;
    	response = BPUtility.getDecodedString(PartCountController.finalizeCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionObj))));
    	
    	system.assertEquals('success', response.toLowerCase());
    	countSessionRecList = [Select Id, Is_Adjust_Uncounted_Parts_To_Zero_Qty__c from Count_Session__c where Name__c = 'Count #1 Test Finalize'];
    	system.assertEquals(true, countSessionRecList[0].Is_Adjust_Uncounted_Parts_To_Zero_Qty__c);
    }
    
    static testMethod void processCountFileImportTest() {
    	List<Count_Session__c> countSessionRecList = [Select Id from Count_Session__c Limit 1];
    	String response = BPUtility.getDecodedString(PartCountController.getCountSessionDetailById(BPUtility.getEncodedString(countSessionRecList[0].Id)));
    	CountSessionWrapper countSessionObj = (CountSessionWrapper) System.JSON.deserialize(response, CountSessionWrapper.class);
    	system.assertEquals('Count #1', countSessionObj.Name);
		system.assertEquals('Random count', countSessionObj.Type);
		
		system.assertEquals(0, [Select Id, Part__c from Count_Session_Line_Item__c].size());
		
		List<Part__c> partRecList = [Select Id, Average_Cost__c, Last_Cost__c, Part_Number__c, Description__c, AvailableParts__c, Vendor__r.Name, Assigned_Location_1__c,
										 Assigned_Location_2__c from Part__c order By Description__c];
										 
		List<CountSessionLineItemWrapper.CountSessionLineItem> csliObjList = new List<CountSessionLineItemWrapper.CountSessionLineItem>();
		for(Integer i = 0; i < 3; i++) {
			CountSessionLineItemWrapper.CountSessionLineItem csliObj = new CountSessionLineItemWrapper.CountSessionLineItem(partRecList[i]);
			csliObj.PartNumber = (i == 2) ? 'Nidhi' : csliObj.PartNumber;
			csliObj.CountedQty = 30 + i;
			csliObj.Locations = 'Jai,Tri,Duo';
			csliObjList.add(csliObj);
		}
		CountSessionLineItemWrapper.CountSessionImportFileWrapper  csImportFileWrapperObj = new CountSessionLineItemWrapper.CountSessionImportFileWrapper();
		csImportFileWrapperObj.MergeDuplicateParts = false;
		csImportFileWrapperObj.CountSessionLineItems = csliObjList;
		response = BPUtility.getDecodedString(PartCountController.processCountFileImport(
						BPUtility.getEncodedString(countSessionRecList[0].Id), BPUtility.getEncodedString(System.JSON.serialize(csImportFileWrapperObj))));
		
		csliObjList.clear();
		CountSessionLineItemWrapper.CountSessionLineItem csliObj2 = new CountSessionLineItemWrapper.CountSessionLineItem(partRecList[1]);
		csliObj2.CountedQty = 35;
		csliObj2.Locations = 'Jai,Tri,Duo';
		csliObjList.add(csliObj2);
		CountSessionLineItemWrapper.CountSessionImportFileWrapper  csImportFileWrapperObj2 = new CountSessionLineItemWrapper.CountSessionImportFileWrapper();
		csImportFileWrapperObj2.MergeDuplicateParts = false;
		csImportFileWrapperObj2.CountSessionLineItems = csliObjList;
		response = BPUtility.getDecodedString(PartCountController.processCountFileImport(
						BPUtility.getEncodedString(countSessionRecList[0].Id), BPUtility.getEncodedString(System.JSON.serialize(csImportFileWrapperObj2))));
		
		List<Count_Session_Line_Item__c> csliRecList = [Select Id, Issue_Indicator__c, Part__c, Assigned_Location_1__c, Counted_Qty__c, Is_Counted__c, Is_Selected_Part__c 
															from Count_Session_Line_Item__c order By Issue_Indicator__c ASC NULLS FIRST];		

		System.assertEquals(4, csliRecList.size());
		System.assertEquals(true, (csliRecList[0].Is_Counted__c && !csliRecList[1].Is_Counted__c && !csliRecList[2].Is_Counted__c && !csliRecList[3].Is_Counted__c));
		System.assertEquals(null, csliRecList[0].Issue_Indicator__c);
		System.assertEquals(Constants.DUPLICATE_PART, csliRecList[1].Issue_Indicator__c);
		System.assertEquals(Constants.INVALID_PART, csliRecList[2].Issue_Indicator__c);
		System.assertEquals(Constants.MISSING_VENDOR, csliRecList[3].Issue_Indicator__c);
    }
    
    static testMethod void deleteCountSessionTest() {
    	Test.startTest();
    	List<Account> vendorList = [Select Id from Account where Name = 'Test Vendor 1'];
        
        CountSessionWrapper countSessionWrapperObj = new CountSessionWrapper();
        countSessionWrapperObj.Name = 'Count #1';
        countSessionWrapperObj.Type = 'Cycle Count';
        countSessionWrapperObj.SelectedVendorIds = new List<String>{vendorList[0].Id};
        
    	String response = BPUtility.getDecodedString(PartCountController.saveCountSession(BPUtility.getEncodedString(System.JSON.serialize(countSessionWrapperObj))));
    	List<Count_Session__c> countSessionRecList = [Select Id, Status__c from Count_Session__c Limit 1];
    	System.assertEquals(1, countSessionRecList.size());
    	String deleteResponse = BPUtility.getDecodedString(PartCountController.deleteCountSession(BPUtility.getEncodedString(countSessionRecList[0].Id)));
    	System.assertEquals(0, [Select Id from Count_Session__c where Id = :countSessionRecList[0].Id].size());
    	Test.stopTest();
    }
}
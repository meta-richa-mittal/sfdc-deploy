/**
 * Author: Durga Singh
 * Since: Sep 29, 2015
 * Name: ScenarioBasedTests
 * Description: It includes scenario based test cases.
**/
@isTest
private class ScenarioBasedTests {
 
// ------------------------------------Scenarios included for Part functionalities-----------------------------------------------------
 
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.bypassValidation();
        TestUtil.createNameSpaceInGeneralConfig();
        
        List<General_Configurations__c> config = [SELECT Id FROM General_Configurations__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        System.assertNotEquals(0, config.size());
        
        User testUser = TestUtil.createUser(true, 'a@b.c', 'Sharma', 'en_US', 'Shantanu.Sharma@metacube.com', 'sshar');
        User_Group__c userGroup = new User_Group__c(name='testing user group',OwnerId =testUser.id, Colour_Code__c='rgba(255,100,88,1)',Accounting_settings_export__c='Primary',
                                           Costs__c='Primary',Customer_invoicing__c='Primary',customers__c='Primary',Deal__c='Primary',fees__c='Primary',Internal_Service__c='Primary',
                                           kits__c='Secondary',labor__c='Secondary',Merchandise__c='Primary',Override_price__c='Primary',Oversell_inventory__c='Primary',parts__c='Primary',
                                           Price_file_import__c='Secondary',Price_Levels__c='Secondary',quick_sale__c='Secondary',Returns__c='Secondary',Sales_Taxes__c='Secondary',Service_job__c='Secondary',
                                           Special_order__c='None',stock_units__c='Secondary',System_Settings__c='Primary',Vendor_invoicing__c='Primary',Vendor_order__c='Primary',
                                           vendor_products__c='Primary',Vendor_receiving__c='Primary',vendors__c='Primary');
        insert userGroup;
        
        List<User_Group__c> userGroupList = [select Id from User_Group__c];
        String userId = UserInfo.getUserId();
        List<String> usersList = new List<String>();
        usersList.add(userId);
        
        UserSettingCtrl.assignUserToGroup(BPUtility.getEncodedString(System.JSON.serialize(usersList)), BPUtility.getEncodedString(userGroupList[0].Id));
    }
    
 
//------------------------------Scenarios Included for VendorOrder Functionalities----------------------------------------------------------------------

 /**
     * Name: groupAllSimilarVOLineItemTest 
     * Desc: Test to group all similar VOLineItems.
     * @param: 
     * @return: 
    **/
    
    static testMethod void groupAllSimilarVOLineItemTest() {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<SortAttrs>{new SortAttrs('Item', 'ASC')};
        //System.JSON.serialize(pageSort)
        boolean user = new VendorOrderCtrl().isPermittedToEditVOHeader ;
         
        Test.startTest();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Order_Lots__c = 2;
        insert part;
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(true, Vendor.Id);
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllSimilarVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        Test.stopTest();
        system.assertEquals(voLineItems.TotalLineItemGroups, 1);
        system.assertEquals(voLineItems.VendorOrderLineItemGroupList[0].Need, 50);
         }  
         
         
         
                /**
     * Name: getPaginatedItemsForVOHeaderForItemsTest
     * Desc: Test to find Line item for Items
     * @param: 
     * @return: 
    **/
    
    static testMethod void  getPaginatedItemsForVOHeaderForItemsTest () {
        
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
       
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(true, Vendor.Id);
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.getPaginatedItemsForVOHeader(BPUtility.getEncodedString('Items'), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems.TotalLineItemGroups, 0);                                                                                            
    }
    
    /*
     * Name: addVOLineItemFromSearchToAddTest 
     * Desc: Test to add VOLineItem from search.
     * @param: 
     * @return: 
    **/
    
   static testMethod void  addVOLineItemFromSearchToAddTest () {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
         
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Order_Lots__c = 1;
        insert part;
        
        Part__c part1 = TestUtil.createPart(false, 'partNumberP012', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part1.Packaged_Part__c = false;
        part1.Qty_On_Order__c = 0;
        part1.Order_Lots__c = 1;
        insert part1;

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(true, Vendor.Id);
        
        String LineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 60, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(null), true));
        Test.startTest();
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch, VendorOrderLineItemWrapper.class);
        String LineItemFromAddToSearch1 = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 60, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(voLineItems.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id), false));
        VendorOrderLineItemWrapper voLineItems1 = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch1, VendorOrderLineItemWrapper.class);
        system.assertEquals(voLineItems1.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Need, 60);
       
        
        
       
        
        String LineItemFromAddToSearch2 = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 30, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(null), true));
        VendorOrderLineItemWrapper voLineItems21 = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch2, VendorOrderLineItemWrapper.class);
        String LineItemFromAddToSearch21 = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 30, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(voLineItems21.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id), false));
        Test.stopTest();
        VendorOrderLineItemWrapper voLineItems22 = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch21, VendorOrderLineItemWrapper.class);
        system.assertEquals(voLineItems22.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Need, 30);

       
    }
    
            /**
     * Name: groupAllVOLineItemTest
     * Desc: Test to group all VOLineItems from COLI for different part.
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void  groupAllVOLineItemTest () {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true ;
        Part.Package_Qty__c = 22 ;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 100;
        part.Order_Lots__c = 1;
        part.Qty_On_Order__c = 0;
        insert part;
        
        Part__c part1 = TestUtil.createPart(false, 'partNumberP011', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part1.Packaged_Part__c = true ;
        Part1.Package_Qty__c = 22 ;
        Part1.Auto_reorder_Min__c = 0;
        part1.Auto_reorder_Max__c = 100;
        part1.Order_Lots__c = 1;
        part1.Qty_On_Order__c = 0;
        insert part1;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part1.Id, 130);
        
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, Vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems.TotalLineItemGroups, 2);
         // assertion change by subhrant  for voli stokcing function changes
        system.assertEquals(voLineItems.TotalRequiredForStocks, 0);
        system.assertEquals(voLineItems.TotalRequiredForCustomers, 0);
    }
    
                    /**
     * Name: addVendorTest
     * Desc: Test to add vendor and create vendor order
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void  addVendorTest () {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true ;
        Part.Package_Qty__c = 22 ;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 100;
        part.Order_Lots__c = 1;
        //part.Qty_On_Order__c = 0;
        insert part;
        

        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(true, Vendor.Id);
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems.TotalRequiredForStocks, 1); 
        system.assertEquals(voLineItems.TotalRequiredForCustomers, 1);                                                                                      
    }
    
                            /**
     * Name: removeLineItemFromOrderTest
     * Desc: Test to remove lineitem from vendor order.
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void  removeLineItemFromOrderTest () {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
       	
        Part__c part = TestUtil.createPart(false, 'partNumberP02', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Order_Lots__c = 1;
        insert part;
        
       Part__c part1 = TestUtil.createPart(false, 'partNumberP03', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part1.Packaged_Part__c = false;
        part1.Qty_On_Order__c = 0;
        part1.Order_Lots__c = 1;
        insert part1;

        
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        String LineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 60, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(null), true));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch, VendorOrderLineItemWrapper.class);
        
        Test.startTest();
        String LineItemFromAddToSearch1 = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(part1.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), 100, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(null), true));
        VendorOrderLineItemWrapper voLineItems1 = (VendorOrderLineItemWrapper) System.JSON.deserialize(LineItemFromAddToSearch1, VendorOrderLineItemWrapper.class);
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.removeLineItemFromOrder(BPUtility.getEncodedString(voLineItems1.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id), BPUtility.getEncodedString(voLineItems1.VendorOrderLineItemGroupList[0].Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems2 = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        Test.stopTest();
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems2.TotalLineItemGroups, 1);                                                                                       
    }
    
            
                                       /**
     * Name: finalizeVendorOrderTest
     * Desc: Test to check COLI order status and part records status after finalized vendor order.
     * @param: 
     * @return: 
    **/
    
    
    static testMethod void  finalizeVendorOrderTest () {
     
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true ;
        Part.Package_Qty__c = 22 ;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 100;
        part.Order_Lots__c = 1;
        //part.Qty_On_Order__c = 0;
        insert part;


        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
       
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        

        String groupLineItems = BPUtility.getDecodedString(VendorOrderCtrl.groupAllSimilarVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems.VendorOrderLineItemGroupList[0].Need, 154);
        
        
        
    }
    
    // Wrapper class for related list pagination and sorting combination
    public class VendorPaginationSorting {
        
        // Change count
        public Integer ChangesCount;
        
        // Current page number
        public Integer CurrentPage;
        
        // page size
        public Integer PageSize;
        
        // Sorting Attrs
        public List<SortAttrs> Sorting;
    }
    
    // SortAttrs for sorting attributes
    public class SortAttrs {
        
        // Field name
        public String FieldName;
        
        // Sort direction
        public String SortDirection;
        
        public SortAttrs(String FieldName, String SortDirection){
            this.FieldName = FieldName;
            this.SortDirection = SortDirection;
        }
    }
   // --------------------------------------------------------Complete Workflow Cases for various scenarios---------------------------------------------------------------




    
     static testMethod void commitRecevingActionTestforCustomer() {

        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        //System.JSON.serialize(pageSort)

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        //part.Qty_On_Order__c = 0;
        insert part;
        
        //Part__c part2 = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        //CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part2.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;

        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
            Test.startTest();
        String allLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addAllLineItemsToItemSubsection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(null), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems1 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(allLineItems, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        
        String UpdatedItemsSubsection = BPUtility.getDecodedString(VendorOrderReceivingCtrl.updateItemsSection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(part.id), BPUtility.getEncodedString(voLineReceiveItems1.VORGroupList[0].Id), 10, 8000, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(UpdatedItemsSubsection, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        
    
        COLineItemTriggerHelper.isTriggerExecute = false;
        COTriggerHelper.isTriggerExecute = false;
        String commitLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vorId)));
        
        List<Part__c> partList = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c from Part__c Limit 100];
        Test.stopTest();
        
        //system.assert(false, partList);
        system.assertEquals(partList[0].Qty_In_Stock__c, 320.00);
        system.assertEquals(partList[0].Qty_Committed__c, 150.00);
        system.assertEquals(partList[0].Qty_On_Order__c, 0);
        
        List<CO_Line_Item__c> colineitem12 = [select Part__c, Qty_Committed__c, Qty__c, Status__c from CO_Line_Item__c Limit 100];
        system.assertEquals(colineitem12[0].Qty_Committed__c, 150.00);
        
        List<Vendor_Order_Header__c> voHeader12 = [select Status__c,    Vendor__c from Vendor_Order_Header__c Limit 100];
        //system.assert(false, voHeader12);
    }
  
static testMethod void commitRecevingActionTestforStock() {

        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        //System.JSON.serialize(pageSort)

        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(false, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        
        insert new List<SObject>{vendor, testCategory, defaultPriceLevel, defaultSalesTax, customer};
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 100;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        part.Qty_On_Order__c = 0;
        //insert part;
        insert new List<SObject>{coHeader, part};
        
        //Part__c part2 = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 150);
        //CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part2.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        //insert voHeader;
        insert new List<SObject>{coLineItem,voHeader};
         
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), false,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
        Test.startTest();
        String allLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addAllLineItemsToItemSubsection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(null), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        //List<Vendor_Receiving_Group__c> vrg = [select Id, Recieved__c, (select Qty_Needed__c, Received__c from Vendor_Order_Line_Items__r) from Vendor_Receiving_Group__c];
        //system.assert(false, vrg[0].Vendor_Order_Line_Items__r);
        
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems1 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(allLineItems, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        
        VendorReceivingGroupTriggerHelper.isProcessed = false;
        
        String UpdatedItemsSubsection = BPUtility.getDecodedString(VendorOrderReceivingCtrl.updateItemsSection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(part.id), BPUtility.getEncodedString(voLineReceiveItems1.VORGroupList[0].Id), 9, 8000, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(UpdatedItemsSubsection, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        
        //system.assert(false, voLineReceiveItems);
        
        COLineItemTriggerHelper.isTriggerExecute = false;
        COTriggerHelper.isTriggerExecute = false;
        String commitLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vorId)));
        
         List<Vendor_Order_Line_Item__c> voliList = [select Qty_Needed__c, Received__c from Vendor_Order_Line_Item__c Limit 100];
        //system.assert(false, voliList);
        
        List<Part__c> partList = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c from Part__c Limit 100];
        
        
        //system.assert(false, partList);
        system.assertEquals(partList[0].Qty_In_Stock__c, 298.00);
        system.assertEquals(partList[0].Qty_Committed__c, 100.00);
        system.assertEquals(partList[0].Qty_On_Order__c, 22);
        
        List<CO_Line_Item__c> colineitem12 = [select Part__c, Qty_Committed__c, Qty__c, Status__c from CO_Line_Item__c Limit 100];
        system.assertEquals(colineitem12[0].Qty_Committed__c, 100.00);
        Test.stopTest();
        List<Vendor_Order_Header__c> voHeader12 = [select Status__c,    Vendor__c from Vendor_Order_Header__c Limit 100];
        //system.assert(false, voHeader12);
    }
    
 static testMethod void commitRecevingActionTestforCustomerPartialReceive() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        //CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        //Added by Nikhil - 22/05/2017
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c = 'Unit Deal', Customer__c=customer.Id,Order_status__c = 'Open');
        insert coHeader;
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        Test.startTest();
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        ActiveSalesOrder activesalesRec = new ActiveSalesOrder(coHeader);
        //system.assert(false,activesalesRec);
        ActiveSalesOrder.RelatedListPaginationSorting pageSort2 = new ActiveSalesOrder.RelatedListPaginationSorting();
        pageSort2.activeSalesOrdersCurrentPage = 1;
        pageSort2.activeSalesOrdersPageSize = 10;
        List<ActiveSalesOrder> activeSales = ActiveSalesOrder.getAllActiveSalesOrdersForPart(part.Id, System.JSON.serialize(pageSort2));
        system.assertEquals(activeSales[0].CommittedQty, 100);
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Integer total = ActiveSalesOrder.getTotalActiveSalesOrdersForPart(part.Id);
        system.assertEquals(total, 1);
      
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestData(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    

static testMethod void commitRecevingActionTestforStockPartialReceive() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        Test.startTest();
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), false,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataforStock(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    
    static testMethod void commitRecevingActionTestforBothCustomerAndStockPartialReceive() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        
        Test.startTest();
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllSimilarVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        String vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataforBothStockAndCustomer(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    
    static testMethod void commitRecevingActionTestforBothCustomerAndStockForMultipleCustomerOrder() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Account customer1 = TestUtil.createCustomer(true, 'customerName1', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, customer1.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 100);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        Test.startTest();
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllSimilarVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataforBothStockAndCustomerforMultipleCO(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    
    static testMethod void commitRecevingActionTestforCustomerHavingMultiParts() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        Part__c part2 = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part2.Id, 116);


        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        Test.startTest();
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataMultiParts(vendor.Id, vorId, voHeader.Id, part.Id, part2.Id);

        //VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems2 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(UpdatedItemsSubsection1, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
    }
    
    static testMethod void commitRecevingActionTestforVOGDetails() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        Test.startTest();
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllSimilarVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        List<CO_Line_Item__c> coli123 = [select Status__c, VO_Number__c, VO_Status__c, Expected_Delivery_Date__c from CO_Line_Item__c];
        system.assertEquals(coli123[0].VO_Status__c, 'On Order');
        system.assertEquals(coli123[0].Status__c, 'Ordered');
        
        List<Part__c> partList = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c from Part__c limit 100];
         // assertion change by subhrant  for voli stokcing function changes
        system.assertEquals(partList[0].Qty_On_Order__c, 214);
        
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataforVOGDetails(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    
        /*
     * Name: SOCompleteFlowTest
     * Desc: Test to check SO complete flow.
     * @param: 
     * @return: 
    **/
     static testMethod void SOCompleteFlow_partialReceiveTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Transaction_Type__c transactionType =  TestUtil.createTransactionType(true, 'Customer', 'Customer');
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        //Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, true, unitMake.Id, unitModel.Id);
        //Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, LabourCode.Id, Part.Id, 1, 5.0);    
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id);
        soHeaderRec.Transaction_Type__c = transactionType.Id;
        update soHeaderRec;
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        
        Test.StartTest();
        SOCompleteFlow_partialReceiveTestAsyncHandling(coHeader.Id, vendor.Id);
        Test.StopTest();
    }
    
    @future
    private static void SOCompleteFlow_partialReceiveTestAsyncHandling(String coHeaderId, String vendorId) {
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded = 500.00 ;
        
        
        ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
        COLineItemTriggerHelper.isTriggerExecute = false;
        COTriggerHelper.isTriggerExecute = false;
        
        String updatedSOLI = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0])), BPUtility.getEncodedString(coHeaderId)));
        String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        
        system.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.SOLIList[0].QtyNeeded, 500.00);
        
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendorId, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendorId);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeader.Id), true, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendorId, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
        String details1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), null));
        
        List<Contact> accList = [select Id, Name from Contact limit 100];
        system.assertEquals(accList.size(), 0);
    }
    
     static testMethod void ScenarioForMerchsection() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(True, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
         Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        Transaction_Type__c transactionType = TestUtil.createTransactionType(true, 'code', 'Customer');
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, false, unitMake.Id, unitModel.Id);
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 5.0, null, Part.Id, 500, 5.0); 
        
        String jSONString = '{"entityId" : "' + kitHeader.Id + '", "UUID" : ""}';
        String insertKitHeaderInMerchGridDetails = BPUtility.getDecodedString(CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeader.Id)));
        CustomerOrderWrapper.COHeaderWrapper coHeaderDetails1 = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(insertKitHeaderInMerchGridDetails, CustomerOrderWrapper.COHeaderWrapper.class);
        system.assertEquals(coHeaderDetails1.COKHList[0].COLIList[0].Item, 'TestPart - TestPart');
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 300);
        
        
        
        VendorOrderReceivingCtrl_PartialTest.ScenarioForMecrhsection_partialReceive(vendor.Id, part.Id, coHeader.Id);
    }
    
        /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingKitToSOTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part1.Id, 1, null);     
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 5);
        
        Test.StartTest();
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice, 36);
        //System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].KitPrice, 120);
        //System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[1].KitPrice, 60);
        
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].KitPrice = 130;
        
        Test.StopTest();
        String updatedSOKH = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0])), BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        //System.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.FixedPrice, 190);
    }
    
            /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingKitToMerchTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, false, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part1.Id, 1, null);     
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 5);
        String jSONString = '{"entityId" : "' + kitHeader.Id + '", "UUID" : ""}';
        String insertKitHeaderInMerchGridDetails = BPUtility.getDecodedString(CustomerOrderCtrl_V2.insertKitHeaderInMerchGrid(BPUtility.getEncodedString(jSONString), BPUtility.getEncodedString(coHeader.Id)));
        
        String COHeaderDetails1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));
        CustomerOrderWrapper.COHeaderWrapper coHeaderDetailsObj = (CustomerOrderWrapper.COHeaderWrapper) System.JSON.deserialize(COHeaderDetails1, CustomerOrderWrapper.COHeaderWrapper.class);
        System.assertEquals(coHeaderDetailsObj.COKHList[1].Price, 36.00);

        String coInvoiceItemJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemList(BPUtility.getEncodedString(coHeader.Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(coInvoiceItemJson, CustomerOrderWrapper.CheckoutWrapper.class);
        
        system.assertEquals(checkoutObj.InvoiceItemList[0].IsInvoiceable, true);
        system.assertEquals(checkoutObj.InvoiceItemList[1].IsInvoiceable, true);
    }
    
            /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingFixedKitToSOTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 200, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part1.Id, 1, null);     
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 5);
        kitHeader.Fixed_Price_Flag__c = true;
        kitHeader.Fixed_Price__c = 200;
        
        KitHeaderTriggerHelper.PermitRun_BeforeUpdate = true;
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        KitLineItemtriggerHelper.PermitRun_BeforeUpdate = true;
        KitLineItemtriggerHelper.PermitRun_BeforeDelete = true;
        update kitHeader;
        
        Test.StartTest();
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsObj1);
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice, 200);
        System.assertEquals(SOHeaderDetails1.contains('66'), true);
        System.assertEquals(SOHeaderDetails1.contains('133'), true);
        
        soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0].KitPrice = 120;
        Test.StopTest();

        String updatedSOKH = BPUtility.getDecodedString(CustomerOrderCtrl_V2.updateSOLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.SOLIList[0])), BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails2 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj2 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails2, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj2.SOList[0].SOGridItems[0].SOKH.FixedPrice, 200);
        system.assertEquals(SOHeaderDetails2.contains('80'), true);
    }
                /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingFixedKitlineitemToSOTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(false, 'Test Sales Tax', true, true, true);
        insert new List<SObject>{vendor, testCategory, defaultPriceLevel, defaultSalesTax};
        Part__c part = TestUtil.createPart(false, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(false, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        insert new List<SObject>{part,part1};
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(false, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(false, 'unitMakeName', '12A', true);
        insert new List<SObject>{labourCode,unitmake};//changed by Nikhil - 23/05/17
        Test.startTest();//changed by Nikhil - 23/05/17
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, true, true, KitHeader.Id, 100, null, Part1.Id, 1, 100);     
        
        KitLineItemtriggerHelper.PermitRun_BeforeUpdate = true;
        kitHeaderLineItem1.Kit_Price__c = 100;
        kitHeaderLineItem1.Fixed_Price__c = true;
        update kitHeaderLineItem1;
        
        Test.stopTest();
        VendorOrderReceivingCtrl_PartialTest.RecalculationLogicOnAddingFixedKitlineitemToSOTest_partial(coHeader.Id,kitHeader.Id,customer.Id);
    }
    
                        /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingServiceKitToSOTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part1.Id, 1, null);     
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem2 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 10, labourCode.Id, null, 1, 10);        
        
        Test.startTest();
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsObj1);
        Test.stopTest();
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice, 46);
    }
    
    /*
    * Name: updateSOKHLineItem
     * Desc: Test to update SOKH
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingServiceKitToSOTestA() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 1, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part1.Id, 1, null);     
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        Kit_Header_Line_Item__c kitHeaderLineItem2 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 10, labourCode.Id, null, 1, 10);        
        
        KitHeaderTriggerHelper.PermitRun_BeforeUpdate = true;
        kitHeader.Fixed_Price__c = 200;
        kitHeader.Fixed_Price_Flag__c= true;
        update kitHeader ;
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        Test.startTest();
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        //Test.startTest();
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsObj1);
        Test.stopTest();
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice, 200);
        // System.assertEquals(SOHeaderDetails1.contains('125'), false);
        System.assertEquals(SOHeaderDetails1.contains('62.50'), false);
        System.assertEquals(SOHeaderDetails1.contains('12.50'), false);
    }
    
            /*
    * Name: RecalculationLogicOnAddingKitToSOCoverBugTest
     * Desc: Bug covered when kit is added to SO and total price for kit line item is not correct
     * @param: 
     * @return: 
    **/
     static testMethod void RecalculationLogicOnAddingKitToSOCoverBugTest() {
        
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        pageSort.Sorting = new List<PaginationSorting.SortAttrs>{new PaginationSorting.SortAttrs('Item', 'ASC')};
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Average Cost', 20 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c part1 = TestUtil.createPart(true, 'TestPart1', vendor.Id, 'TestPart1', testCategory.Id, 5, 10, 25, 50, 50);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', defaultPriceLevel.Id, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(true, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        // fixed price flag for kit header is false and kit is service kit
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', null, false, true, unitMake.Id, unitModel.Id);
        // fixed price and flag both are false for both line item 
        Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, null, null, Part.Id, 5, null);
        KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
       Test.startTest(); 
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
        Test.stopTest(); 
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice, 120);
        //System.assert(false, soHeaderDetailsObj1 );
        System.assertEquals(soHeaderDetailsObj1.SOList[0].SOHeaderInfo.Total, 120);
        
        list<Service_Order_Line_Item__c> solis = [select  Qty_Needed__c, Kit_Price__c,  Retail_Price__c, qty_committed__c,  Total__c from Service_Order_Line_Item__c Limit 100];
        
        system.assertEquals(solis[0].Total__c, 120);
        
        


    }
    
     /*
     * Added by Nikhil - 10/03/17
     * Name: vendorOrderPartialStatusTest
     * Desc: Test to check VO status on partial receiving.
     * @param: 
     * @return: 
    **/
    
    static testMethod void vendorOrderPartialStatusTest() {

        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        
        Part__c part2 = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem1 = TestUtil.createCOLineItem(true, coHeader.Id, part2.Id, 120);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id; 
        insert voHeader;
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id),BPUtility.getEncodedString(voHeader.Id), true,BPUtility.getEncodedString( System.JSON.serialize(pageSort)),BPUtility.getEncodedString(System.JSON.serialize(pageSort)),BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id),BPUtility.getEncodedString(vendor.Id),BPUtility.getEncodedString(System.JSON.serialize(pageSort)),BPUtility.getEncodedString(System.JSON.serialize(pageSort)),BPUtility.getEncodedString(System.JSON.serialize(pageSort)));
        Test.StartTest();
        List<Vendor_Order_Header__c> vendorOrderList = [Select Id,Name,Purchase_Order_Type__c,Status__c,Total_Recieved__c,Total__c from Vendor_Order_Header__c limit 10];
        system.assertEquals(vendorOrderList[0].Status__c,'On Order'); 
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        //system.assert(false, voLineItems);
        system.assertEquals(voLineItems.VendorOrderLineItemGroupList[0].Status, 'On Order');
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(false, vendor.Id, 'In Progress');
        Id vorId = Id.valueOf(BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id),BPUtility.getEncodedString(null))));
        String VendorOrderReceiveItems = VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id),BPUtility.getEncodedString(vorId), true);
         
        //1st order
        Test.StopTest();
        VendorOrderReceivingCtrl_PartialTest.vendorOrderStatus_Partial(vorId,part2.Id,voHeader.Id,similarlineitem, voLineItems.VendorOrderLineItemGroupList[0].Id, vendor.Id); 
        
        //List<Vendor_Order_Header__c> vendorOrderUpdatedList = [Select Id,Name,Purchase_Order_Type__c,Status__c,Total_Recieved__c,Total__c from Vendor_Order_Header__c limit 10];  
         
    }
   
    
     /*
     * Added by Hitesh - 29/05/17
     * Name: commitReceivingFlowTest
     * Desc: Test to check VO, VR status on partial receiving.
     * @param: 
     * @return: 
    **/
    static testMethod void commitReceivingFlowTest(){
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true ;
        Part.Package_Qty__c = 22 ;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 100;
        part.Order_Lots__c = 1;
        part.Qty_On_Order__c = 0;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, Vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(similarlineitem, VendorOrderLineItemWrapper.class);
        
        system.assertEquals(voLineItems.TotalLineItemGroups, 1);
        // assertion change by subhrant  for voli stokcing function changes (stock line item deleted as Available + on order > MIN)
        system.assertEquals(voLineItems.TotalRequiredForStocks, 0);
        system.assertEquals(voLineItems.TotalRequiredForCustomers, 0);
    }
   
    /**
     * Name: getInvoiceSummaryOfPartTest 
     * Desc: Test to get Invoice Summary Of Part
     * @param: 
     * @return: 
    **/
    
    static testMethod void getInvoiceSummaryOfPartTest() {
     
       Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
    
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 20);
         
        list<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceHeaderlist );
       
        List<CO_Invoice_Item__c> COInvoiceItems = [select Category__c, CO_Line_Item__c, isActive__c, Item_Category_Code__c, Item_ID__c, Item_Type__c, Price__c, Qty__c from CO_Invoice_Item__c];
        //system.assert(false, COInvoiceItems );
        
        Test.startTest();
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderlist[0].Id);
        COService.finalizeOrder(BPUtility.getEncodedString(System.Json.serialize(chkoutObj.InvoiceItemList)), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'), null);
        Test.stopTest();
        
       
       // system.assert(false, coHeaderDetails1);
        /* system.assertEquals(coHeaderDetails1.COInvoiceHistoryRecs[0].NumberOfItems, 1);
        system.assertEquals(coHeaderDetails1.COInvoiceHistoryRecs[0].Total, 1100);
        system.assertEquals(coHeaderDetails1.coHeaderRec.OrderStatus, 'Closed'); */
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
        system.assertEquals(parts[0].AvailableParts__c, 80);
        
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Customer Invoices'};
  
        String jsonStr = System.Json.serialize(filterWrapper);
        
        List<CO_Invoice_Header__c> coInvoiceList = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceList);
        
        String customerdetails = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails, HomeSearchResultWrapper.ResultWrapper.class);
        //system.assert(false, details1);
        system.assertEquals(details1.CustomerInvoiceRecords[0].Invoice_Profit, 700);
         }  
         
         
         /**
     * Name: getInvoiceSummaryOfFeeFixedCostTest 
     * Desc: Test to get Invoice Summary Of Fee for Fixed Cost
     * @param: 
     * @return: 
    **/
    
    static testMethod void getInvoiceSummaryOfFeeFixedCostTest() {
     
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(false, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 100, True);
        fee.Cost_Rate__c = 30;
        fee.Is_Include_In_Profit_Calculation__c = true;
        insert fee;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(fee.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
         
        list<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceHeaderlist );
       
         List<CO_Invoice_Item__c> COInvoiceItems = [select Category__c, CO_Line_Item__c, isActive__c, Item_Category_Code__c, Item_ID__c, Item_Type__c, Price__c, Qty__c from CO_Invoice_Item__c];
        //system.assert(false, COInvoiceItems );
        
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        COService.finalizeOrder(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'), null);
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
       
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Customer Invoices'};
  
        String jsonStr = System.Json.serialize(filterWrapper);
        
        List<CO_Invoice_Header__c> coInvoiceList = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceList);
        
        String customerdetails = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails, HomeSearchResultWrapper.ResultWrapper.class);
        Test.stopTest();
       // system.assert(false, details1);
        system.assertEquals(details1.CustomerInvoiceRecords[0].Invoice_Profit, 70.00);
        
       }  
         
          /**
     * Name: getInvoiceSummaryOfFeePercentRetailTest 
     * Desc: Test to get Invoice Summary Of Fee for Percent Retail
     * @param: 
     * @return: 
    **/
    
    static testMethod void getInvoiceSummaryOfFeePercentRetailTest() {
     
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Fee__c fee = TestUtil.createFee(false, True, testCategory.Id, 'FeeCode', CoHeader.Id, 'Description', 120, True);
        fee.Cost_Rate__c = 30;
        fee.Is_Include_In_Profit_Calculation__c = true;
        fee.Cost_Method__c = 'Percent Retail';
        insert fee;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(fee.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
         
        list<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceHeaderlist );
       
         List<CO_Invoice_Item__c> COInvoiceItems = [select Category__c, CO_Line_Item__c, isActive__c, Item_Category_Code__c, Item_ID__c, Item_Type__c, Price__c, Qty__c from CO_Invoice_Item__c];
        //system.assert(false, COInvoiceItems );
        
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        COService.finalizeOrder(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'), null);
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
       
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Customer Invoices'};
  
        String jsonStr = System.Json.serialize(filterWrapper);
        
        List<CO_Invoice_Header__c> coInvoiceList = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceList);
        
        String customerdetails = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails, HomeSearchResultWrapper.ResultWrapper.class);
        Test.stopTest();
        //system.assert(false, details1);
        system.assertEquals(details1.CustomerInvoiceRecords[0].Invoice_Profit, 84.00);
         }  
         
         /**
     * Name: getInvoiceSummaryOfLabourPercentRetailTest 
     * Desc: Test to get Invoice Summary Of Labour for Percent Retail
     * @param: 
     * @return: 
    **/
    
    static testMethod void getInvoiceSummaryOfLabourPercentRetailTest() {
     
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(false, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 50, true);
        labourCode.Cost_Rate__c = 30;
        labourCode.Cost_Method__c = 'Percent Retail';
        insert labourCode;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(labourCode.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
         
        list<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceHeaderlist );
       
         List<CO_Invoice_Item__c> COInvoiceItems = [select Category__c, CO_Line_Item__c, isActive__c, Item_Category_Code__c, Item_ID__c, Item_Type__c, Price__c, Qty__c from CO_Invoice_Item__c];
        //system.assert(false, COInvoiceItems );
        
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        COService.finalizeOrder(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'), null);
        Test.stopTest();
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
       
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Customer Invoices'};
  
        String jsonStr = System.Json.serialize(filterWrapper);
        
        List<CO_Invoice_Header__c> coInvoiceList = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceList);
        
        String customerdetails = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails, HomeSearchResultWrapper.ResultWrapper.class);
        //system.assert(false, details1);
        system.assertEquals(details1.CustomerInvoiceRecords[0].Invoice_Profit, 350);
         }  
         
         /**
     * Name: getInvoiceSummaryOfLabourFixedCostTest 
     * Desc: Test to get Invoice Summary Of Labour for Fixed Cost
     * @param: 
     * @return: 
    **/
    
    static testMethod void getInvoiceSummaryOfLabourFixedCostTest() {
     
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Labour_Code__c labourCode = TestUtil.createLabourCode(false, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 50, true);
        labourCode.Cost_Rate__c = 30;
        insert labourCode;
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, UnitMake.Id, UnitModel.Id, null);
        
        String soHeader = ServiceJobService.createServiceJobWithSpecificFields(coHeader.Id, null, null, true, false);
        String SOHeaderDetails = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        //system.assert(false, soHeaderDetailsList);
        System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
        
        String lineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(labourCode.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
        String SOHeaderDetails1 = BPUtility.getDecodedString(ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
         
        list<CO_Invoice_Header__c> coInvoiceHeaderlist = [select  Status__c, Total_Payment__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceHeaderlist );
       
         List<CO_Invoice_Item__c> COInvoiceItems = [select Category__c, CO_Line_Item__c, isActive__c, Item_Category_Code__c, Item_ID__c, Item_Type__c, Price__c, Qty__c from CO_Invoice_Item__c];
        //system.assert(false, COInvoiceItems );
        
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id)));
        COService.finalizeOrder(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'), null);
        Test.stopTest();
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
     
        
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Customer Invoices'};
  
        String jsonStr = System.Json.serialize(filterWrapper);
        
        List<CO_Invoice_Header__c> coInvoiceList = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
        //system.assert(false, coInvoiceList);
        
        String customerdetails = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails, HomeSearchResultWrapper.ResultWrapper.class);
        //system.assert(false, details1);
        system.assertEquals(details1.CustomerInvoiceRecords[0].Invoice_Profit, 200);
         }  
         
         /**
         * Name: partOversoldInvoiceProfitTest 
         * Desc: Test to get Invoice Summary Of Part when part is Oversold
         * @param: 
         * @return: 
        **/
         
        static testMethod void partOversoldInvoiceProfitTest() {
            //Created test data to check scenario
            General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
            Account vendor = TestUtil.createVendor(true, 'Test Vendor');
            Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
            
               //Price level of 10% on MSRP
            Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
            Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
            
               // Part with available qty 100 and having MSRP $50
            Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
            
            Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
                // created customer order
            CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
            
            CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 120);
            coLineItem.Qty_Committed__c = 120 ;
            update coLineItem ;
            
            List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
            //system.assert(false, colineitemList);
            Test.startTest();
            String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
            String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Cash","Amount":"-110.000","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
            // Closing invoice
            CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
            String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":6600.000,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
            String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));
            Test.stopTest();
            String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
            PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
             system.assertEquals(partObjRec.OversoldQty, 20);
            //system.assert(false, partObjRec);
            
            
            List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
            system.assertEquals(parts[0].AvailableParts__c, 0);
            
            List<Id> fixedSearchResults = new List<Id>{part.Id};
            Test.setFixedSearchResults(fixedSearchResults);
            
            HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
            filterWrapper.Type.objects = new Set<String>{'Parts'};
            String jsonStr = System.Json.serialize(filterWrapper);
            
            String customerdetails1 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
            HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails1, HomeSearchResultWrapper.ResultWrapper.class);
            system.assertEquals(details1.PartRecords[0].Oversold_Qty, 20);
            system.assertEquals(details1.PartRecords[0].Oversold_Cost, 400);
            String resolveOversold = BPUtility.getDecodedString(ViewPartCtrl.resolveOversoldInStock(BPUtility.getEncodedString(System.JSON.serialize(partObjRec.PartFIFOBucketList))));
            PartDetailWrapper partObjRec1 = (PartDetailWrapper) System.JSON.deserialize(resolveOversold, PartDetailWrapper.class);
            
            //system.assert(false, partObjRec1);
            system.assertEquals(partObjRec1.AverageCost, 0 );
            system.assertEquals(partObjRec1.QtyInStock, 0);
            system.assertEquals(partObjRec1.TotalFIFORecords, 2);
            
            String FIFOHistory = BPUtility.getDecodedString(ViewPartCtrl.getHistoryRecords(BPUtility.getEncodedString(part.Id), true ));
            List<PartFIFOBucket> partObjRec2 = (List<PartFIFOBucket>) System.JSON.deserialize(FIFOHistory, List<PartFIFOBucket>.class);
            system.assertEquals(partObjRec2.size(), 2);
            
            HomeSearchFilterWrapper filterWrapper1 = new HomeSearchFilterWrapper();
            filterWrapper1.Type.objects = new Set<String>{'Customer Invoices'};
      
            String jsonStr1 = System.Json.serialize(filterWrapper1);
            
            List<CO_Invoice_Header__c> coInvoiceList11 = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
            //system.assert(false, coInvoiceList);
            
            String customerdetails2 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr1), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
            HomeSearchResultWrapper.ResultWrapper details2 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails2, HomeSearchResultWrapper.ResultWrapper.class);
            //system.assert(false, details2);
            system.assertEquals(details2.CustomerInvoiceRecords[0].Invoice_Profit, 4200);
     }
     
 static testMethod void storeCreditTest() {
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');

            // created customer order
            
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = Customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;
        
        //List<Store_Credit__c> StoreCredit = [Select Id from Store_Credit__c where id =: storecreditRec.id];
        
        String storeCredit = BPUtility.getDecodedString(NewViewCustomerCtrl.getCustomerStoreCreditbyCustomerId( BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        NewViewCustomerCtrl.StoreCreditJSONWrapper storeCreditDetails = (NewViewCustomerCtrl.StoreCreditJSONWrapper) System.JSON.deserialize(storeCredit, NewViewCustomerCtrl.StoreCreditJSONWrapper.class);
        //System.assert(false, storeCreditDetails);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 120);
        coLineItem.Qty_Committed__c = 120 ;
        update coLineItem ;
        
        List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
        //system.assert(false, colineitemList);
        
        Test.startTest();
        String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
        String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Store Credit","Amount":"6600","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
        // Closing invoice
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
        String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":6600.000,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
        String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));
        
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
         system.assertEquals(partObjRec.OversoldQty, 20);
        //system.assert(false, partObjRec);
        Test.stopTest();
     }
     

    static testMethod void saveStoreCreditTest() {
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');

            // created customer order
            
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = Customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;
        
        //List<Store_Credit__c> StoreCredit = [Select Id from Store_Credit__c where id =: storecreditRec.id];
        
        String storeCredit = BPUtility.getDecodedString(NewViewCustomerCtrl.getCustomerStoreCreditbyCustomerId( BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        NewViewCustomerCtrl.StoreCreditJSONWrapper storeCreditDetails = (NewViewCustomerCtrl.StoreCreditJSONWrapper) System.JSON.deserialize(storeCredit, NewViewCustomerCtrl.StoreCreditJSONWrapper.class);
        
        list <Store_Credit__c> creditScore = [select Id, CO_Header__c, CO_Invoice_Header__c,CO_Invoice_Header__r.Invoice_Number__c, Name, Amount__c, Reference__c,  createdDate FROM Store_Credit__c where Id =: storecreditRec.Id];
        
        
        //StoreCredit creditObject = new StoreCredit(creditScore[0]);
        List<StoreCredit> jsonstr1 = new List<StoreCredit>();
        
        for(Store_Credit__c storeCreditRec1 : creditScore){
            jsonstr1.add(new StoreCredit(storeCreditRec1));
        }
        
        String customerdetails =  BPUtility.getDecodedString(NewViewCustomerCtrl.saveCustomerStoreCredit(BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(jsonstr1)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        
        /* String customerInfo = BPUtility.getDecodedString(ViewCustomerCtrl.getCustomerInfo(BPUtility.getEncodedString(customer.Id)));
        CustomerDetail customers = (CustomerDetail) System.JSON.deserialize(customerInfo, CustomerDetail.class);
        system.assertEquals(customers.customerInfo.TotalStoreCredit, 20000); */
        
     }
     
     static testMethod void storeCreditOnPartReturnTest() {
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');

            // customer is credited for an amount
            
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = Customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;
        
        //List<Store_Credit__c> StoreCredit = [Select Id from Store_Credit__c where id =: storecreditRec.id];
        
        String storeCredit = BPUtility.getDecodedString(NewViewCustomerCtrl.getCustomerStoreCreditbyCustomerId( BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        NewViewCustomerCtrl.StoreCreditJSONWrapper storeCreditDetails = (NewViewCustomerCtrl.StoreCreditJSONWrapper) System.JSON.deserialize(storeCredit, NewViewCustomerCtrl.StoreCreditJSONWrapper.class);
        //System.assert(false, storeCreditDetails);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        // part returned
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, -2);
        
        List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
        Test.startTest();
        String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
        String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Store Credit","Amount":"-110","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
        // Closing invoice
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
        String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":-110,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
        String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));

        Test.stopTest();
        // Checking totals under store credits
        /* String customerInfo = BPUtility.getDecodedString(ViewCustomerCtrl.getCustomerInfo(BPUtility.getEncodedString(customer.Id)));
        CustomerDetail customers = (CustomerDetail) System.JSON.deserialize(customerInfo, CustomerDetail.class);
        system.assertEquals(customers.customerInfo.TotalStoreCredit, 10110); */
        
     }
     
      static testMethod void cancelVOPartialReceive() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        //CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        //Added by Nikhil - 22/05/2017
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c = 'Unit Deal', Customer__c=customer.Id,Order_status__c = 'Open');
        insert coHeader;
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Package_Cost__c = 440;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 200;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        
        Test.startTest();
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1; 
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        ActiveSalesOrder activesalesRec = new ActiveSalesOrder(coHeader);
        //system.assert(false,activesalesRec);
        ActiveSalesOrder.RelatedListPaginationSorting pageSort2 = new ActiveSalesOrder.RelatedListPaginationSorting();
        pageSort2.activeSalesOrdersCurrentPage = 1;
        pageSort2.activeSalesOrdersPageSize = 10;
        List<ActiveSalesOrder> activeSales = ActiveSalesOrder.getAllActiveSalesOrdersForPart(part.Id, System.JSON.serialize(pageSort2));
        system.assertEquals(activeSales[0].CommittedQty, 100);
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Integer total = ActiveSalesOrder.getTotalActiveSalesOrdersForPart(part.Id);
        system.assertEquals(total, 1);
      
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(null)));
        String VendorOrderReceiveItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        Test.stopTest();
        
        VendorOrderReceivingCtrl_PartialTest.createExcessTestDataAB(vendor.Id, vorId, voHeader.Id, part.Id);
    }
    
             /**
         * Name: partOversoldInvoiceProfitTest 
         * Desc: Test to get Invoice Summary Of Part when part is Oversold
         * @param: 
         * @return: 
        **/
         
        static testMethod void TransactionalDataSearchTest() {
            //Created test data to check scenario
            General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
            Account vendor = TestUtil.createVendor(true, 'Test Vendor');
            Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
            
               //Price level of 10% on MSRP
            Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
            Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
            
               // Part with available qty 100 and having MSRP $50
            Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
            
            Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
                // created customer order
            CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
            
            CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 120);
            coLineItem.Qty_Committed__c = 120 ;
            update coLineItem ;
            
            List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
            //system.assert(false, colineitemList);
            Test.startTest();
            String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
            String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Cash","Amount":"-110.000","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
            // Closing invoice
            CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
            String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":6600.000,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
            String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));
            Test.stopTest();
            
            TransactionalDataSearchTest_future(part.Id);
            
     }
     
     @future
    static void TransactionalDataSearchTest_future(String partId) {
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(partId)));
            PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
             system.assertEquals(partObjRec.OversoldQty, 20);
            //system.assert(false, partObjRec);
            

            
            HomeSearchFilterWrapper filterWrapper1 = new HomeSearchFilterWrapper();
            filterWrapper1.Type.objects = new Set<String>{'Invoiced Items'};
      
            String jsonStr1 = System.Json.serialize(filterWrapper1);
            
            List<CO_Invoice_Header__c> coInvoiceList11 = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
            //system.assert(false, coInvoiceList);
            
            String customerdetails2 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr1), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
            HomeSearchResultWrapper.ResultWrapper details2 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails2, HomeSearchResultWrapper.ResultWrapper.class);
            //system.assert(false, details2);
            system.assertEquals(details2.InvoicedItems[0].Item, 'TestPart');
            system.assertEquals(details2.InvoicedItems[0].Profit, 4200);
            system.assertEquals(details2.InvoicedItems[0].Price, 55);
            system.assertEquals(details2.InvoicedItems[0].Qty_Sold, 120);
            system.assertEquals(details2.InvoicedItems[0].Revenue, 6600);
            system.assertEquals(details2.InvoicedItems[0].Vendor, 'Test Vendor');
    }
     
     static testMethod void TransactionalDataOnPartReturnTest() {
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');

            // customer is credited for an amount
            
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = Customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;
        
        //List<Store_Credit__c> StoreCredit = [Select Id from Store_Credit__c where id =: storecreditRec.id];
        
        String storeCredit = BPUtility.getDecodedString(NewViewCustomerCtrl.getCustomerStoreCreditbyCustomerId( BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        NewViewCustomerCtrl.StoreCreditJSONWrapper storeCreditDetails = (NewViewCustomerCtrl.StoreCreditJSONWrapper) System.JSON.deserialize(storeCredit, NewViewCustomerCtrl.StoreCreditJSONWrapper.class);
        //System.assert(false, storeCreditDetails);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        // part returned
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, -2);
        
        List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
        Test.startTest();
        String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
        String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Store Credit","Amount":"-110","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
        // Closing invoice
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
        String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":-110,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
        String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));

        Test.stopTest();
                    
        HomeSearchFilterWrapper filterWrapper1 = new HomeSearchFilterWrapper();
        filterWrapper1.Type.objects = new Set<String>{'Invoiced Items'};
      
        String jsonStr1 = System.Json.serialize(filterWrapper1);
            
        List<CO_Invoice_Header__c> coInvoiceList11 = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
            //system.assert(false, coInvoiceList);
            
        String customerdetails2 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr1), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details2 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails2, HomeSearchResultWrapper.ResultWrapper.class);
        //system.assert(false, details2);
            system.assertEquals(details2.InvoicedItems[0].Item, 'TestPart');
            system.assertEquals(details2.InvoicedItems[0].Profit, -70);
            system.assertEquals(details2.InvoicedItems[0].Price, 55);
            system.assertEquals(details2.InvoicedItems[0].Qty_Sold, -2);
            system.assertEquals(details2.InvoicedItems[0].Revenue, -110);
            system.assertEquals(details2.InvoicedItems[0].Vendor, 'Test Vendor');
        
     }
     
          static testMethod void TransactionalDataOnPartReturnSummaryFormatTest() {
        VendorPaginationSorting pageSort = new VendorPaginationSorting();
        pageSort.ChangesCount = 0;
        pageSort.CurrentPage = 1;  
        pageSort.PageSize =  10;
        //System.JSON.serialize(pageSort)
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');

            // customer is credited for an amount
            
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = Customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;
        
        //List<Store_Credit__c> StoreCredit = [Select Id from Store_Credit__c where id =: storecreditRec.id];
        
        String storeCredit = BPUtility.getDecodedString(NewViewCustomerCtrl.getCustomerStoreCreditbyCustomerId( BPUtility.getEncodedString(customer.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        NewViewCustomerCtrl.StoreCreditJSONWrapper storeCreditDetails = (NewViewCustomerCtrl.StoreCreditJSONWrapper) System.JSON.deserialize(storeCredit, NewViewCustomerCtrl.StoreCreditJSONWrapper.class);
        //System.assert(false, storeCreditDetails);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        // part returned
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, -2);
        
        List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
        Test.startTest();
        String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
        String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Store Credit","Amount":"-110","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
        // Closing invoice
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
        String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":-110,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
        String details12 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));

        Test.stopTest();
                    
        HomeSearchFilterWrapper filterWrapper1 = new HomeSearchFilterWrapper();
        filterWrapper1.Type.objects = new Set<String>{'Invoiced Items'};
        filterWrapper1.IsSummaryFormat = true;
        String jsonStr1 = System.Json.serialize(filterWrapper1);
            
        List<CO_Invoice_Header__c> coInvoiceList11 = [select Total_Payment__c, Search_Tag__c, Invoice_Status__c, CO_Header__c from CO_Invoice_Header__c];
            //system.assert(false, coInvoiceList);
            
        String customerdetails2 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr1), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details2 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails2, HomeSearchResultWrapper.ResultWrapper.class);
        //system.assert(false, details2);
            system.assertEquals(details2.InvoicedItems[0].Item, 'TestPart');
            system.assertEquals(details2.InvoicedItems[0].Average_Profit, -35);
            system.assertEquals(details2.InvoicedItems[0].Total_Profit, -70);
            system.assertEquals(details2.InvoicedItems[0].Average_Price, -55.000);
            system.assertEquals(details2.InvoicedItems[0].Qty_Sold, -2);
            system.assertEquals(details2.InvoicedItems[0].Total_Revenue, -110.00000);
            system.assertEquals(details2.InvoicedItems[0].Vendor, 'Test Vendor');
     }
}
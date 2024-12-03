@isTest
public without sharing class WebsiteProductManagementTest {
    
    @TestSetup
    private static void createSampleData() {
        TestDataFactory.disableFLSChecks();
        
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
    	generalConfig.Enable_Shopify_Integration__c = true;
    	upsert generalConfig;
        
        TestUtil.activateShopifyIntegration();
        TestUtil.createShopifyConfiguration();
        
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigsForShopify();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [SELECT Id FROM IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForShopify('Token' , IFWConfigObjList[0].Id, 'POST');
        TestUtil.createIFWConfigItemForShopify('Product' , IFWConfigObjList[0].Id, 'GET');
        
        Account vendor = TestUtil.createVendor(true, 'Vendor');
        Tag__c tag = TestDataFactory.createTag('New Tag');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        testCategory.Type__c = 'Part';
        insert testCategory;
        
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Part', testCategory.Id, 10, 20, 50, 100, 100);
        Website_Product__c websiteProduct = TestUtil.createWebsiteProduct(true, part.Id, vendor.Name);
    }

    @isTest
    public static void getAllProductsTest() {
        Website_Product__c websiteProductRec = [SELECT Id, Title__c, Product_Vendor__c, Status__c FROM Website_Product__c Order BY Title__c ASC LIMIT 1];
        Datetime dateTimeWhenSearch = Datetime.now().addDays(12);
        Test.startTest();
        String productJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.getAllProducts(BPUtility.getEncodedString('{"StartIndex":0,"RecordCount":10,"SearchKeyword":"'+ websiteProductRec.Title__c +'","ProductVendorList":["'+ websiteProductRec.Product_Vendor__c +'"],"StatusList":["'+ websiteProductRec.Status__c +'"],"DateTimeWhenSearchExecuted":"'+ dateTimeWhenSearch +'"}')));
        Test.stopTest();
        List<WebsiteProductWrapper> productList = (List<WebsiteProductWrapper>) System.JSON.deserialize(productJSON, List<WebsiteProductWrapper>.class);
        system.assertEquals(1, productList.size());
    }

    @isTest
    public static void getProductStaticsTest() {
        Website_Product__c websiteProductRec = [SELECT Id, Title__c, Product_Vendor__c, Status__c FROM Website_Product__c Order BY Title__c ASC LIMIT 1];
        Test.startTest();
        String productStaticsJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.getProductStatics(BPUtility.getEncodedString('{"SearchKeyword":"'+ websiteProductRec.Title__c +'","ProductVendorList":["'+ websiteProductRec.Product_Vendor__c +'"],"StatusList":["'+ websiteProductRec.Status__c +'"]}')));
        Test.stopTest();
        Map<String, String> productStaticsMap = (Map<String, String>) JSON.deserialize(productStaticsJSON, Map<String, String>.class);
        String ProductCount = productStaticsMap.get('ProductCount');
        system.assertEquals('1', ProductCount);
    }

    @isTest
    public static void getWebsiteInfoTest() {
        Test.startTest();
        String websiteInfoJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.getWebsiteInfo());
        WebsiteInfoWrapper WebsiteInfoObj = (WebsiteInfoWrapper) System.JSON.deserialize(websiteInfoJSON, WebsiteInfoWrapper.class);
        Test.stopTest();
        System.assertEquals(Shopify_Configuration__c.getOrgDefaults().Website_Title__c, WebsiteInfoObj.Title);
    }

    @isTest
    public static void searchPartWithFiltersTest() {
        Test.startTest();
        String searchPartJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.searchPartWithFilters(BPUtility.getEncodedString('{"SearchText":"test","SearchableObjects":"Part__c","FilterValues":[]}')));
        Test.stopTest();
        List<SearchSuggestionJSON.ResultJSON> searchPartList = (List<SearchSuggestionJSON.ResultJSON>) System.JSON.deserialize(searchPartJSON, List<SearchSuggestionJSON.ResultJSON>.class);
        system.assertEquals(0, searchPartList.size());
    }

    @isTest
    public static void saveProductAndVariantsTest() { 
        Website_Product__c websiteProductRec = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC LIMIT 1];
        Part__c partRec = [SELECT Id, Part_Number__c, Description__c FROM Part__c ORDER BY Part_Number__c ASC LIMIT 1];
        Test.startTest();
        WebsiteProductManagementCtrl.saveProductAndVariants(BPUtility.getEncodedString('{"Title":"Test Title 1","ProductId":"112","VariantOptionList":[{"Label1":"Color","Label2":"Size","Label3":"Gender","Value1":"Red","Value2":"M","Value3":"Female"}]}'));
        Test.stopTest();
        List<Website_Product__c> websiteProductList = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC];
        System.assertEquals(2, websiteProductList.size());
    }

    @isTest
    public static void deleteProductVariantTest() {
        Test.setMock(HttpCalloutMock.class, new WebsiteProductMockResponseGenerator());
        Website_Product__c websiteProductRec = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC LIMIT 1];
        Test.startTest();
        WebsiteProductManagementCtrl.deleteProductVariant(BPUtility.getEncodedString(websiteProductRec.Id));
        Test.stopTest();
        List<Website_Product__c> websiteProductList = [SELECT Id, Delete_Pending__c FROM Website_Product__c Where Id =: websiteProductRec.Id ORDER BY Title__c ASC];
        if(websiteProductList.size() != 0) {
            System.assertEquals(true, websiteProductList[0].Delete_Pending__c);
        }
    }

    @isTest
    public static void getProductVendorTest() {
        Test.startTest();
        String productVendorJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.getProductVendor(BPUtility.getEncodedString('Vend')));
        Test.stopTest();
        List<String> productVendorList = (List<String>) System.JSON.deserialize(productVendorJSON, List<String>.class);
        system.assertEquals(1, productVendorList.size());
    }

    @isTest
    public static void pollProductsFromWebsiteTest() {
        Test.setMock(HttpCalloutMock.class, new WebsiteProductMockResponseGenerator());
        Test.startTest();
        WebsiteProductManagementCtrl.pollProductsFromWebsite();
        Test.stopTest();
        List<Website_Product__c> websiteProductList = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC];
        System.assertEquals(2, websiteProductList.size());
    }

    @isTest
    public static void isPollingInProgressTest() {
        Test.startTest();
        Boolean isPollingInProgress = WebsiteProductManagementCtrl.isPollingInProgress();
        Test.stopTest();
        System.assertEquals(false, isPollingInProgress);
    }

    @isTest
    public static void getProductVariantsByProductIdTest() {
        Website_Product__c websiteProductRec = [SELECT Id, Product_Id__c, Option_Value_1__c FROM Website_Product__c ORDER BY Title__c ASC LIMIT 1];
        Test.startTest();
        String productVariantJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.getProductVariantsByProductId(BPUtility.getEncodedString(websiteProductRec.Product_Id__c)));
        Test.stopTest();
        WebsiteProductVariantWrapper productVariant = (WebsiteProductVariantWrapper) System.JSON.deserialize(productVariantJSON, WebsiteProductVariantWrapper.Class);
        System.assertEquals(websiteProductRec.Option_Value_1__c, productVariant.VariantOptionList[0].Value1);
    }

    @isTest
    public static void searchBPVendorsTest() {
        Account Vendor = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        String BPVendorsJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.searchBPVendors(BPUtility.getEncodedString(Vendor.Name)));
        Test.stopTest();
        List<Vendor> BPVendorList = (List<Vendor>) System.JSON.deserialize(BPVendorsJSON, List<Vendor>.Class);
        system.assertEquals(1, BPVendorList.size());
    }

    @isTest
    public static void searchTagsTest() {
        Tag__c tag = [SELECT Id, Name__c FROM Tag__c LIMIT 1];
        Test.startTest();
        String tagJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.searchTags(BPUtility.getEncodedString(tag.Name__c)));
        Test.stopTest();
        List<TagWrapper> tagList = (List<TagWrapper>) System.JSON.deserialize(tagJSON, List<TagWrapper>.Class);
        system.assertEquals(1, tagList.size());
    }

    @isTest
    public static void searchCategoriesTest() {
        Category__c category = [SELECT Id, Name FROM Category__c LIMIT 1];
        Test.startTest();
        String categoryJSON = BPUtility.getDecodedString(WebsiteProductManagementCtrl.searchCategories(BPUtility.getEncodedString(category.Name)));
        Test.stopTest();
        List<CategoryService.CategoryWrapper> categoryList = (List<CategoryService.CategoryWrapper>) System.JSON.deserialize(categoryJSON, List<CategoryService.CategoryWrapper>.Class);
        system.assertEquals(1, categoryList.size());
    }

    @isTest
    public static void saveProductsTest() {
        Website_Product__c websiteProductRec = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC LIMIT 1];
        Part__c partRec = [SELECT Id, Part_Number__c, Description__c FROM Part__c ORDER BY Part_Number__c ASC LIMIT 1];
        Test.startTest();
        WebsiteProductManagementCtrl.saveProducts(BPUtility.getEncodedString('[{"Title":"Test Title 1","ProductId":"112","Status":"New","IsIgnored":true,"VariantOptions":"Red,M,Female","ProductVendor":"Hero","PartId":"'+ partRec.Id +'","PartCodeDesc":"'+ partRec.Part_Number__c + ' - ' + partRec.Description__c +'","OptionLabel1":"Color","OptionLabel2":"Size","OptionLabel3":"Gender","OptionValue1":"Red","OptionValue2":"M","OptionValue3":"Female"}]'));
        Test.stopTest();
        List<Website_Product__c> websiteProductList = [SELECT Id FROM Website_Product__c ORDER BY Title__c ASC];
        System.assertEquals(2, websiteProductList.size());
    }
}
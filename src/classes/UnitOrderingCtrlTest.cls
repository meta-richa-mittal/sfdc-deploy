@isTest
private class UnitOrderingCtrlTest {
    @testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
        BPScriptManager.createDefaultUnitProductType();
    }
    
    static testMethod void getVendorsListTest() {
        Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'COU';
        customerOwnedUnit.Status__c = 'Active';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        String jsonData = UnitOrderingCtrl.getVendorsList();
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        List<UnitOrderingWrapper.VendorWrapper> vendorList = (List<UnitOrderingWrapper.VendorWrapper>) System.JSON.deserialize(jsonData, List<UnitOrderingWrapper.VendorWrapper>.class);
        system.assertEquals('test',vendorList[0].VendorName);
        system.assertEquals(0,vendorList[0].UnitCount);
    }
    static testMethod void getVendorDetailsTest() {
        Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'COU';
        customerOwnedUnit.Status__c = 'Active';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        String jsonData = UnitOrderingCtrl.getVendorDetails(BPUtility.getEncodedString(vendor.id));
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        UnitOrderingWrapper.VendorWrapper vendorObj = (UnitOrderingWrapper.VendorWrapper) System.JSON.deserialize(jsonData, UnitOrderingWrapper.VendorWrapper.class);
        system.assertEquals('test',vendorObj.VendorName);
        system.assertEquals(0,vendorObj.UnitCount);
    }
    
     static testMethod void SetUnitPurchaseFlagForVendorTest() {
        Account vendor = TestUtil.createVendor(true,'test');
        test.startTest();
        String jsonData = UnitOrderingCtrl.SetUnitPurchaseFlagForVendor(BPUtility.getEncodedString(vendor.id));
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        List<UnitOrderingWrapper.VendorWrapper> vendorList = (List<UnitOrderingWrapper.VendorWrapper>) System.JSON.deserialize(jsonData, List<UnitOrderingWrapper.VendorWrapper>.class);
        system.assertEquals('test',vendorList[0].VendorName);
        system.assertEquals(0,vendorList[0].UnitCount);
        
     }
     static testMethod void getActiveOrderListTest() {
        Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'On Order';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        String jsonData = UnitOrderingCtrl.getActiveOrderList(BPUtility.getEncodedString(vendor.id));
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        List<UnitOrderingWrapper.UnitOrderWrapper> vendorList = (List<UnitOrderingWrapper.UnitOrderWrapper>) System.JSON.deserialize(jsonData, List<UnitOrderingWrapper.UnitOrderWrapper>.class);
        system.assertEquals('On Order',vendorList[0].Status);
    }
    static testMethod void removeOrderUnitTest(){
    	 Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'On Order';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        String jsonData = UnitOrderingCtrl.removeOrderUnit(BPUtility.getEncodedString(customerOwnedUnit.id),BPUtility.getEncodedString(vendor.id));
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        List<UnitOrderingWrapper.VendorWrapper> vendorList = (List<UnitOrderingWrapper.VendorWrapper>) System.JSON.deserialize(jsonData, List<UnitOrderingWrapper.VendorWrapper>.class);
        system.assertEquals(0,vendorList.size());
        
    }
    static testMethod void getOrderHistoryListTest() {
    	 Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Received';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        UnitOrderingWrapper.UnitOrderingFilterWrapper filterJson = new UnitOrderingWrapper.UnitOrderingFilterWrapper();
        filterJson.StartIndex = 0;
		filterJson.RecordCount = 50;
		filterJson.VendorId = vendor.id;        
        String jsonData = UnitOrderingCtrl.getOrderHistoryList(BPUtility.getEncodedString(System.JSON.serialize(filterJson)));
        test.stopTest();
        jsonData = BPUtility.getDecodedString(jsonData);
        List<UnitOrderingWrapper.UnitOrderWrapper> vendorList = (List<UnitOrderingWrapper.UnitOrderWrapper>) System.JSON.deserialize(jsonData, List<UnitOrderingWrapper.UnitOrderWrapper>.class);
        system.assertEquals('Received',vendorList[0].Status);
    }
    static testMethod void getUnitDetailsTest() {
    	Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Received';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        
        test.startTest();
        String response  = UnitOrderingCtrl.getUnitDetails(BPUtility.getEncodedString(customerOwnedUnit.id));
        test.stopTest();
        response = BPUtility.getDecodedString(response);
        List<UnitOrderingWrapper.UnitDetailsWrapper> unitList = (List<UnitOrderingWrapper.UnitDetailsWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.UnitDetailsWrapper>.class);
        system.assertNotEquals(null,unitList[0].UnitInfo.id);
    }
    
    static testMethod void saveUnitDetailsTest() {
    	Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Received';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        String query;   
        query = 'SELECT '; 
        for(String fieldName : UnitWrapper.fieldsListForUnitInfo()){
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Customer_Owned_Unit__c ';
        List<Customer_Owned_Unit__c> couList = new List<Customer_Owned_Unit__c>();
        couList = Database.query(query);
        Customer_Owned_Unit__c couObj = new Customer_Owned_Unit__c();
        if(couList.size()>0){
        	couObj = couList[0];
        }
        UnitOrderingWrapper.UnitDetailsWrapper unitObj = new UnitOrderingWrapper.UnitDetailsWrapper(couObj);
        String jsonString = System.JSON.serialize(unitObj);
        jsonString = BPUtility.getEncodedString(jsonString);
        test.startTest();
        String response = UnitOrderingCtrl.saveUnitDetails(jsonString);
        test.stopTest();
        response = BPUtility.getDecodedString(response);
        List<UnitOrderingWrapper.VendorWrapper> vendorList = (List<UnitOrderingWrapper.VendorWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.VendorWrapper>.class);
        system.assertEquals(1,vendorList.size());
    }
    
	static testMethod void savePriceAndCostTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Received';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        Unit_Price_Cost__c upc = new Unit_Price_Cost__c();
		upc.Type__c = 'Factory';
		upc.Customer_Owned_Unit__c = customerOwnedUnit.id;
		upc.CO_Invoice_Header__c = coInvoiceHeader.id;
		insert upc;
		String query;   
        query = 'SELECT '; 
        for(String fieldName : UnitWrapper.fieldsListForUnitPriceAndCostTracking()){
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Unit_Price_Cost__c ';
        List<Unit_Price_Cost__c> upcList = new List<Unit_Price_Cost__c>();
        upcList = Database.query(query);
        Unit_Price_Cost__c upcObj = new Unit_Price_Cost__c();
        if(upcList.size()>0){
        	upcObj = upcList[0];
        }
        
		UnitWrapper.PriceAndCostTrackingWrapper priceAndCost = new UnitWrapper.PriceAndCostTrackingWrapper(upcObj);
        List<UnitWrapper.PriceAndCostTrackingWrapper> priceAndCostList = new List<UnitWrapper.PriceAndCostTrackingWrapper>();
        priceAndCostList.add(priceAndCost);
		test.startTest();
        String response = UnitOrderingCtrl.savePriceAndCost(BPUtility.getEncodedString(customerOwnedUnit.id),BPUtility.getEncodedString(System.JSON.serialize(priceAndCostList)));
        test.stopTest();
        response = BPUtility.getDecodedString(response);
        List<UnitOrderingWrapper.UnitDetailsWrapper> unitList = (List<UnitOrderingWrapper.UnitDetailsWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.UnitDetailsWrapper>.class);
        system.assertEquals('Agra',unitList[0].UnitInfo.BillingCity);
	}
	static testMethod void removePriceAndCostTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Received';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        Unit_Price_Cost__c upc = new Unit_Price_Cost__c();
		upc.Type__c = 'Factory';
		upc.Customer_Owned_Unit__c = customerOwnedUnit.id;
		upc.CO_Invoice_Header__c = coInvoiceHeader.id;
		insert upc;
		test.startTest();
        String response = UnitOrderingCtrl.removePriceAndCost(BPUtility.getEncodedString(customerOwnedUnit.id),BPUtility.getEncodedString(upc.id));
        UnitOrderingCtrl uoc = new UnitOrderingCtrl();
        test.stopTest();
        response = BPUtility.getDecodedString(response);
        List<UnitOrderingWrapper.UnitDetailsWrapper> unitList = (List<UnitOrderingWrapper.UnitDetailsWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.UnitDetailsWrapper>.class);
        system.assertEquals('Agra',unitList[0].UnitInfo.BillingCity);
	}
	static testMethod void saveUnitReceivingTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'On Order';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;

        String query = 'SELECT ' + String.join(UnitOrderingWrapper.fieldsListForOrderUnit(), ',') + ' FROM Customer_Owned_Unit__c WHERE Id = \'' + customerOwnedUnit.Id + '\'';
        List<Customer_Owned_Unit__c> customerOwnedUnitList = (List<Customer_Owned_Unit__c>)Database.query(query);

        UnitOrderingWrapper.UnitOrderWrapper uow = new UnitOrderingWrapper.UnitOrderWrapper(customerOwnedUnitList[0]);
        List<UnitOrderingWrapper.UnitOrderWrapper> uowList = new List<UnitOrderingWrapper.UnitOrderWrapper>();
        uowList.add(uow);
        UnitOrderingService.UnitReceivingWrapper receivingObj = new UnitOrderingService.UnitReceivingWrapper();
        receivingObj.OrderedUnits = uowList;
		String jsonString = System.JSON.serialize(receivingObj);
		jsonString = BPUtility.getEncodedString(jsonString);
		test.startTest();
		String response = UnitOrderingCtrl.receiveUnit(jsonString);
        test.StopTest();
        system.assertEquals('SUCCESS',response);
        
	}
	static testMethod void saveUnitReceivingTestTwo() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Traded';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;

        String query = 'SELECT ' + String.join(UnitOrderingWrapper.fieldsListForOrderUnit(), ',') + ' FROM Customer_Owned_Unit__c WHERE Id = \'' + customerOwnedUnit.Id + '\'';
        List<Customer_Owned_Unit__c> customerOwnedUnitList = (List<Customer_Owned_Unit__c>)Database.query(query);

        UnitOrderingWrapper.UnitOrderWrapper uow = new UnitOrderingWrapper.UnitOrderWrapper(customerOwnedUnitList[0]);
        List<UnitOrderingWrapper.UnitOrderWrapper> uowList = new List<UnitOrderingWrapper.UnitOrderWrapper>();
        uowList.add(uow);
        UnitOrderingService.UnitReceivingWrapper receivingObj = new UnitOrderingService.UnitReceivingWrapper();
        receivingObj.OrderedUnits = uowList;
		String jsonString = System.JSON.serialize(receivingObj);
		jsonString = BPUtility.getEncodedString(jsonString);
		test.startTest();
		String response = UnitOrderingCtrl.receiveUnit(jsonString);
        test.StopTest();
        system.assertEquals('SUCCESS',response);
        
        
	}
	static testMethod void getUnitCategoryListTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Traded';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        Category__c category = testUtil.createCategory(true,'test category','Unit','test description',true,true);
        test.startTest();
        String response = UnitOrderingCtrl.getUnitCategoryList();
        test.stopTest();
        response = BPUtility.getDecodedString(response);
        List<CategoryService.CategoryWrapper> categoryList = (List<CategoryService.CategoryWrapper>) System.JSON.deserialize(response, List<CategoryService.CategoryWrapper>.class);
        system.assertEquals(true,categoryList[0].IsDefault);
	}
	static testMethod void applySortingOnActiveOrderListTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'On Order';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        UnitOrderingWrapper.SortingAttrs sortAttrs= new UnitOrderingWrapper.SortingAttrs();
        sortAttrs.FieldLabel = 'Status';
        sortAttrs.SortingOrder = 'ASC';
        String jsonString = system.json.serialize(sortAttrs);
        test.startTest();
		String response = UnitOrderingCtrl.applySortingOnActiveOrderList(BPUtility.getEncodedString(vendor.id),BPUtility.getEncodedString(jsonString));
        test.StopTest();
        response = BPUtility.getDecodedString(response);
		List<UnitOrderingWrapper.UnitOrderWrapper> unitList = (List<UnitOrderingWrapper.UnitOrderWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.UnitOrderWrapper>.class);
        system.assertEquals(1,unitList.size());
		
	}
	
	static testMethod void applySortingOnOrderHistoryListTest() {
		Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;
        Account acc = TestUtil.createCustomer(true, 'Test Customer', 'test@test.com', 'NY', '5214789630');
        CO_Header__c coHeader = TestUtil.createCOHeader(true,acc.id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true,coHeader.id,'Active');
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Unit_Type__c = 'ORDU';
        customerOwnedUnit.Status__c = 'Cancelled';
        customerOwnedUnit.Mileage_Type__c = 'Km';
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        UnitOrderingWrapper.SortingAttrs sortAttrs= new UnitOrderingWrapper.SortingAttrs();
        sortAttrs.FieldLabel = 'Status';
        sortAttrs.SortingOrder = 'ASC';
        String jsonString = system.json.serialize(sortAttrs);
        test.startTest();
        UnitOrderingWrapper.UnitOrderingFilterWrapper filterJson = new UnitOrderingWrapper.UnitOrderingFilterWrapper();
        filterJson.StartIndex = 0;
		filterJson.RecordCount = 50;
		filterJson.VendorId = vendor.id;  
		String response = UnitOrderingCtrl.applySortingOnOrderHistoryList(BPUtility.getEncodedString(System.JSON.serialize(filterJson)),BPUtility.getEncodedString(jsonString));
        test.StopTest();
        response = BPUtility.getDecodedString(response);
        //system.assert(false,response);
		List<UnitOrderingWrapper.UnitOrderWrapper> unitList = (List<UnitOrderingWrapper.UnitOrderWrapper>) System.JSON.deserialize(response, List<UnitOrderingWrapper.UnitOrderWrapper>.class);
        system.assertEquals(1,unitList.size());
    }
    
    @isTest
    private static void getBasePriceAndCostByMMSIdTest() {
        Unit_Make__c unitMake = TestUtil.createUnitMake(false, 'unitMakeName', '12A', true);
        unitMake.Enable_Unit_Pricing__c = true;
        insert unitMake;
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Unit_Sub_Model__c unitSubModel = TestUtil.createSubModel(unitmodel.Id);
        unitSubModel.Price__c= 20;
        unitSubModel.Cost__c = 30;
        update unitSubModel;
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitOrderingCtrl.getBasePriceAndCostByMMSId(BPUtility.getEncodedString(unitMake.Id), BPUtility.getEncodedString(unitmodel.Id), BPUtility.getEncodedString(unitSubModel.Id)));
        UnitPricingService.UnitPriceAndCostWrapper unitPriceAndCostObj = (UnitPricingService.UnitPriceAndCostWrapper) System.JSON.deserialize(result, UnitPricingService.UnitPriceAndCostWrapper.class);
        System.assertEquals(30, unitPriceAndCostObj.Cost);
        Test.stopTest();
    }
    
    @isTest
    private static void getDefaultFactoryOptionsByRecIdTest() {
        Account vendor = TestUtil.createVendor(false,'test');
        vendor.Unit_Purchases__c = true;
        insert vendor;       
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitMake = TestUtil.createUnitMake(false, 'unitMakeName', '12A', true);
        unitMake.Enable_Unit_Pricing__c = true;
        insert unitMake;
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        Factory_Option__c factoryOptionRec = TestUtil.createFactoryOption(true, 'Test1', 'Test1', 30, 34, unitmake.Id);
        Unit_Sub_Model__c unitSubModel = TestUtil.createSubModel(unitmodel.Id);
        unitSubModel.Price__c= 20;
        unitSubModel.Cost__c = 30;
        update unitSubModel;
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitOrderingCtrl.getDefaultFactoryOptionsByUnitId(BPUtility.getEncodedString(customerOwnedUnit.Id),BPUtility.getEncodedString(unitMake.Id), BPUtility.getEncodedString(unitmodel.Id), BPUtility.getEncodedString(unitSubModel.Id)));
        system.assertEquals(result.contains('Test1'), true);
        Test.stopTest();
    }
	
	@isTest
    private static void createBulkUnitsTest1() {
        Account vendor = TestUtil.createVendor(false,'test');
        insert vendor;  
        Account Customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        Unit_Make__c unitMake = TestUtil.createUnitMake(false, 'unitMakeName', '12A', true);
        unitMake.Enable_Unit_Pricing__c = true;
        insert unitMake;
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null, 'VIN123');
        customerOwnedUnit.Vendor__c = vendor.id;
        insert customerOwnedUnit;
        Test.startTest();
        String response = BPUtility.getDecodedString(UnitOrderingCtrl.createBulkUnits(BPUtility.getEncodedString(customerOwnedUnit.id), 5));
        ResponseWrapper result = (ResponseWrapper) System.JSON.deserialize(response, ResponseWrapper.class);
		
        system.assertEquals('Bulk units are successfully inserted', result.response);
        List<Customer_Owned_Unit__c> unitList = [SELECT Id FROM Customer_Owned_Unit__c];
        system.assertEquals(6, unitList.size());
        response = BPUtility.getDecodedString(UnitOrderingCtrl.createBulkUnits(BPUtility.getEncodedString(unitList[2].id), 5));
        result = (ResponseWrapper) System.JSON.deserialize(response, ResponseWrapper.class);
        system.assertEquals('Bulk units are successfully inserted', result.response);
        List<Customer_Owned_Unit__c> unitList1 = [SELECT Id FROM Customer_Owned_Unit__c];
        system.assertEquals(11, unitList1.size());
        Test.stopTest();
    }
}
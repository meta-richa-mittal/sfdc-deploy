public without sharing class CustomerOwnedUnitTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static Boolean forcefullyRunPopulateUnitIdLogic = false;
    
    // List to store trigger new list
    public static List<Customer_Owned_Unit__c> customerOwnerUnitNewList = new List<Customer_Owned_Unit__c>();
    
    // List to store trigger old list
    public static List<Customer_Owned_Unit__c> customerOwnerUnitOldList = new List<Customer_Owned_Unit__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Customer_Owned_Unit__c> customerOwnerUnitNewMap = new Map<Id, Customer_Owned_Unit__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Customer_Owned_Unit__c> customerOwnerUnitOldMap = new Map<Id, Customer_Owned_Unit__c>();
    
    private static final String UNIT_TYPE_STOCK = 'STOCK';
    private static final String UNIT_TYPE_COU = 'COU';
    private static final String UNIT_TYPE_ORDU = 'ORDU';
    private static final Integer UNIT_ID_NUMBER_OF_DIGITS = 5;
    
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;

    /**
    * Name: beforeInsertOperations
    * Desc: Run beforeInsertOperations method
    * @param:   
    **/
    public static void beforeInsertOperations(){
        validateSKUNumber();
        generateCOUId();
        for(Customer_Owned_Unit__c customerOwnerUnitRec : customerOwnerUnitNewList) {
            if(String.isNotBlank(customerOwnerUnitRec.VIN_Number__c) && customerOwnerUnitRec.VIN_Number__c == 'VIN Unknown') {
                customerOwnerUnitRec.VIN_Number__c = null;
            }
            if(customerOwnerUnitRec.Unit_Type__c == 'STOCK') {
                if(customerOwnerUnitRec.Publish_in_feeds__c == null) customerOwnerUnitRec.Publish_in_feeds__c = true;
                if(customerOwnerUnitRec.Date_Stocked_In__c == null) customerOwnerUnitRec.Date_Stocked_In__c = System.today();
            }
        }
    }
    
    /**
    * Name: generateCOUId
    * Desc: Calculate Unit  of COU based on Type Passed
    * @param:   (1)typeOfCOU - String - Type OF COU[COU,STOCK,ORDU] string
    *          
    * @return: Integer - count of COU based on Type Passed
    **/
    private static void generateCOUId(){
        List<Customer_Owned_Unit__c> stockcustomerOwnerUnitList = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> NonStockcustomerOwnerUnitList = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> stockUnitWithNoCategoryList = new List<Customer_Owned_Unit__c>();
        
        for(Customer_Owned_Unit__c customerOwnerUnitRec : customerOwnerUnitNewList){
            if(String.isBlank(customerOwnerUnitRec.Unit_Id__c)){
                NonStockcustomerOwnerUnitList.add(customerOwnerUnitRec);
            }
            if(customerOwnerUnitRec.Unit_Type__c == UNIT_TYPE_STOCK && String.isBlank(customerOwnerUnitRec.Stock_Id__c)){
                stockcustomerOwnerUnitList.add(customerOwnerUnitRec);
            }
            if(customerOwnerUnitRec.Unit_Type__c == UNIT_TYPE_STOCK && String.isBlank(customerOwnerUnitRec.Category__c)) {
                stockUnitWithNoCategoryList.add(customerOwnerUnitRec);
            }
        }
        populateUnitId(NonStockcustomerOwnerUnitList);
        populateStockId(stockcustomerOwnerUnitList);
        populateDefaultCategory(stockUnitWithNoCategoryList);
    }
    
    /**
    * Name: generateCount
    * Desc: Calculate count of COU based on Type Passed
    * @param:   (1)typeOfCOU - String - Type OF COU[COU,STOCK,ORDU] string
    *          
    * @return: Integer - count of COU based on Type Passed
    **/
    private static Integer generateCount(Boolean isStock){
        Integer countOfCOU=0;
        if(isStock){
        	List<Customer_Owned_Unit__c> unitList = [SELECT Max_Stock_Count__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' AND Max_Stock_Count__c != null 
        								ORDER BY Max_Stock_Count__c DESC LIMIT 1];
        	if(unitList.size() > 0) {
        		countOfCOU = Integer.valueOf(unitList[0].Max_Stock_Count__c);
        	}
        } else {
        	List<Customer_Owned_Unit__c> unitList = [SELECT Max_COU_Count__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c IN ('ORDU','COU','STOCK') 
        								AND Max_COU_Count__c != null ORDER BY Max_COU_Count__c DESC LIMIT 1];
        	if(unitList.size() > 0) {
        		countOfCOU = Integer.valueOf(unitList[0].Max_COU_Count__c);
        	}
        }
        return countOfCOU;
    }
    /**
    * Name: trailingZero
    * Desc: Returns the number passed with trailing Zeros 
    * @param:   (1)length - Integer  - Total number of digits possible in number
                (2)numberToAdjust - Number you want to convert
    *          
    * @return: String  - Returns the number passed with trailing Zeros 
    **/
    public static String trailingZero(Integer length,Integer numberToAdjust){
        String trailingZeroString = '';
        String numberAsString = numberToAdjust + '';
        for(Integer i =0 ;i < length - numberAsString.length();i++){
            trailingZeroString += '0';
        }
        return trailingZeroString + numberAsString;
    }
    private static void populateUnitId(List<Customer_Owned_Unit__c> NonStockCustomerOwnerUnitList){
        if(NonStockCustomerOwnerUnitList.size() > 0){
            Integer countValue = generateCount(false) + 1;
            for(Customer_Owned_Unit__c nonStockedCustomerOwnedUnit : NonStockCustomerOwnerUnitList){
                nonStockedCustomerOwnedUnit.Max_COU_Count__c = countValue;
                nonStockedCustomerOwnedUnit.Unit_Id__c = 'UNT-' +  trailingZero(UNIT_ID_NUMBER_OF_DIGITS,countValue).trim();
                countValue++;
            }
        }
        System.debug(NonStockCustomerOwnerUnitList);
    }
    private static void populateStockId(List<Customer_Owned_Unit__c> StockCustomerOwnerUnitList){
        if(StockCustomerOwnerUnitList.size() > 0) {
            Integer countValue = generateCount(true) + 1;
            for(Customer_Owned_Unit__c StockedCustomerOwnedUnit : StockCustomerOwnerUnitList){
                if(String.isBlank(StockedCustomerOwnedUnit.Stock_Id__c)) {
                    StockedCustomerOwnedUnit.Max_Stock_Count__c = countValue;
                    StockedCustomerOwnedUnit.Stock_Id__c = 'SKU-' +  trailingZero(UNIT_ID_NUMBER_OF_DIGITS,countValue).trim();
                    countValue++;
                }
            }
        }   
    }
    
    private static void populateDefaultCategory(List<Customer_Owned_Unit__c> stockUnitWithNoCategoryList) {
        if(stockUnitWithNoCategoryList.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Category__c> categoryList = [Select Id from Category__c where Type__c = 'Unit' AND Default__c = true limit 1];
            if(categoryList.size() > 0) {
                for(Customer_Owned_Unit__c stockUnitRec : stockUnitWithNoCategoryList) {
                    stockUnitRec.Category__c = categoryList[0].Id;
                }
            }
        }
    }
    
    public static void beforeUpdate() {
        validateSKUNumber();
    	validateConsignmentUnits();
    	populatesFieldsBeforeUpdate();
        populateCategoryChangeAccountingSyncFields();
        populateNITCJESyncFields();
        populateConsignmentSyncFields();
        cleanInActiveUnitOptionalFields();
    }
    
    public static void afterUpdate() {
        setUnitDataForCategoryChangeAccountSync();
        setUnitDataForNITCJESync();
        setUnitDataForConsignmentSync();
        setSKUDataForDP360Sync();
    }
    
    public static void populatesFieldsBeforeUpdate() {
        for(Customer_Owned_Unit__c unitRec : customerOwnerUnitNewList) {
            if(unitRec.Id != null && unitRec.Unit_Type__c == 'STOCK' && unitRec.Status__c != 'Sold' && customerOwnerUnitOldMap.get(unitRec.Id).Category__c != unitRec.Category__c && unitRec.Total_Cost__c != null && unitRec.Total_Cost__c != 0) {
                unitRec.Old_Category__c = customerOwnerUnitOldMap.get(unitRec.Id).Category__c;
            }
            if(String.isNotBlank(unitRec.VIN_Number__c) && unitRec.VIN_Number__c == 'VIN Unknown') {
                unitRec.VIN_Number__c = null;
            }
        }
    }
    
    public static void validateConsignmentUnits() {
    	Boolean isChangingConsignement = false;
    	Set<String> couIdSet = new Set<String>();
    	
        for(Customer_Owned_Unit__c unitRec : customerOwnerUnitNewList) {
        	if(unitRec.Consignment__c) {
        		if(String.isBlank(unitRec.VIN_Number__c)) {
	        		throw new BlackpurlException('VIN field must be populated, cannot flag as consignment');
	        	} else if(unitRec.Suggested_Price__c == null || unitRec.Agreed_Payout__c == null || unitRec.Suggested_Price__c == 0 || unitRec.Agreed_Payout__c == 0) {
	        		throw new BlackpurlException('Suggested price and Agreed payout be greater than zero');
	        	} else if(unitRec.Agreed_Payout__c > unitRec.Suggested_Price__c) {
	        		throw new BlackpurlException('Agreed payout cannot be greater than Suggested price');
	        	}
        	}
        	
        	if(unitRec.Id != null && unitRec.Unit_Type__c == 'COU' && (unitRec.Consignment__c != customerOwnerUnitOldMap.get(unitRec.Id).Consignment__c || 
        		(unitRec.Status__c == 'Inactive' && unitRec.Status__c != customerOwnerUnitOldMap.get(unitRec.Id).Status__c))) {
        		couIdSet.add(unitRec.Id);
        	}
        }
        if(couIdSet.size() > 0) {
        	List<Deal_Item__c> dealItemList = [Select Id, Customer_Owned_Unit__c from Deal_Item__c where Customer_Owned_Unit__c IN: couIdSet LIMIT 1];
        	if(dealItemList.size() > 0) {
        		Set<String> unitIdsActiveOnDealSet = new Set<String>();
        		for(Deal_Item__c dealItemRec : dealItemList) {
        			unitIdsActiveOnDealSet.add(dealItemRec.Customer_Owned_Unit__c);
        		}
        		unitIdsActiveOnDealSet.remove(null);
        		
        		for(Customer_Owned_Unit__c unitRec : customerOwnerUnitNewList) {
        			if(unitRec.Id != null && unitIdsActiveOnDealSet.contains(unitRec.Id)) {
        				if(unitRec.Consignment__c != customerOwnerUnitOldMap.get(unitRec.Id).Consignment__c) {
        					if(unitRec.Consignment__c) {
        						throw new BlackpurlException('Unit is active on a deal, cannot flag as consignment');
        					} else {
        						throw new BlackpurlException('This consignment is linked to an active deal');
        					}
			        	} else if(unitRec.Status__c == 'Inactive' && unitRec.Status__c != customerOwnerUnitOldMap.get(unitRec.Id).Status__c) {
			        		throw new BlackpurlException('Cannot deactivate unit as this consignment is linked to an active deal');
			        	}
        			}
		        }
        	}
        }
    }
    
    public static void populatesDP360SyncFields() {
        List<Customer_Owned_Unit__c> skuList = new List<Customer_Owned_Unit__c>();
        for(Customer_Owned_Unit__c unitRec : customerOwnerUnitNewList) {
            if(unitRec.Unit_Type__c == 'STOCK' && Trigger.isInsert) {
                skuList.add(unitRec);
            } else if(Trigger.isUpdate && (unitRec.Unit_Type__c == 'STOCK' || (unitRec.Consignment__c && unitRec.Unit_Type__c == 'COU')) && isDP360UnitFieldsUpdated(unitRec)) {
                skuList.add(unitRec);
            }
        }
        if(skuList.size() > 0 && DP360Service.isDP360Enabled()) {
            for(Customer_Owned_Unit__c unitRec : skuList) {
                if(DP360Service.isSyncUnitToDP360(unitRec)) unitRec.Available_For_DP360_Sync__c = true;
            }
        }
    }
    
    private static Boolean isDP360UnitFieldsUpdated(Customer_Owned_Unit__c unitRec) {
        for(String fieldName : DP360InventoryWrapper.dp360UpdateUnitFieldsList()) {
            if(unitRec != null && (customerOwnerUnitOldMap.get(unitRec.Id).get(fieldName) != customerOwnerUnitNewMap.get(unitRec.Id).get(fieldName))) {
                return true;
            }
        }
        return false;
    }

    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.manageUnitSyncFlag(customerOwnerUnitNewList);
        IntegrationSyncFlagService.manageUnitInvoiceJESyncFlag(customerOwnerUnitNewList);
    }
    
    public static void setSKUDataForDP360Sync() {
        if(DP360Service.isDP360Enabled()) {
            Set<Id> unitIdSet = new Set<Id>();
	        for(Customer_Owned_Unit__c unit : customerOwnerUnitNewList) {
	            if(unit.Available_For_DP360_Sync__c) {
                    if(Trigger.isInsert || (Trigger.isUpdate && isDP360UnitFieldsUpdated(unit) && unit.Unit_Type__c != 'ORDU')) {
                        unitIdSet.add(unit.Id);
                    } else if(Trigger.isUpdate && unit.Unit_Type__c == 'ORDU') {
                        unitIdSet.add(unit.Id);
                    }
	            }
	        }
            if(unitIdSet.size() > 0) {
                Database.executeBatch(new DP360InventoryBatch(unitIdSet), 10);
            }
        }
    }
        
    public static void setCOUDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(customerOwnerUnitNewList, IntegrationUtility.UNIT_INVOICE);  
    }
    
    /*public static void syncInventoryWithDP360() {
        if(GeneralConfiguration.getDP360DealerId() != null) {
            Set<Id> skuIdSet = new Set<Id>();
            for(Customer_Owned_Unit__c stockUnitRec : customerOwnerUnitNewList) {
                if(stockUnitRec.Unit_Type__c == UNIT_TYPE_STOCK && ((trigger.isInsert && String.isBlank(stockUnitRec.DP360_Inventory_Id__c)) || (trigger.isUpdate && 
                    (customerOwnerUnitOldMap.get(stockUnitRec.Id).Status__c != stockUnitRec.Status__c && stockUnitRec.Status__c == 'Sold')))) {
                    skuIdSet.add(stockUnitRec.Id);
                }
            }
            if(skuIdSet.size() > 0) { 
                DP360IntegrationCtrl.upsertInventoryInDP360(skuIdSet);
            }
        } 
        return;
    }*/

    public static void beforeDelete() {
        deleteAttachedDocuments();
    }
    
    public static void populateCategoryChangeAccountingSyncFields() {
        IntegrationSyncFlagService.manageStockUnitCategorySyncFlag( customerOwnerUnitNewList, customerOwnerUnitOldMap);
    }
    
    public static void setUnitDataForCategoryChangeAccountSync() {
    	IntegrationSyncFlagService.checkAndInitiateSyncBatch(customerOwnerUnitOldMap, customerOwnerUnitNewList, IntegrationUtility.STOCK_UNIT_CATEGORY);
    }
    
    public static void populateNITCJESyncFields() {
    	IntegrationSyncFlagService.manageNITCJESyncFlag( customerOwnerUnitNewList, customerOwnerUnitOldMap);
    }
    
    public static void setUnitDataForNITCJESync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(customerOwnerUnitNewList, IntegrationUtility.UNIT_NITC_JE);    
    }
    
    public static void populateConsignmentSyncFields() {
        IntegrationSyncFlagService.manageConsignmentSyncFlag(customerOwnerUnitNewList, customerOwnerUnitOldMap);
    }
    
    public static void setUnitDataForConsignmentSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(customerOwnerUnitNewList, IntegrationUtility.Unit_Consignment);    
    }

    private static void validateSKUNumber() {
        for(Customer_Owned_Unit__c couRec : customerOwnerUnitNewList){
            if(couRec.Unit_Type__c == UNIT_TYPE_STOCK && String.isNotBlank(couRec.Stock_Id__c) && couRec.Stock_Id__c.startsWithIgnoreCase('SKU-') && (Trigger.isInsert || customerOwnerUnitOldMap.get(couRec.Id).Stock_Id__c != couRec.Stock_Id__c)){
                couRec.addError('Manually entered stock numbers cannot begin with SKU-. Please enter a different stock number.');
            }
        }
    }

    private static void cleanInActiveUnitOptionalFields() {
        Set<String> productTypeIds = new Set<String>();
        for(Customer_Owned_Unit__c couRec : customerOwnerUnitNewList){
            if(couRec.Product_type__c != null && couRec.Product_type__c != customerOwnerUnitOldMap.get(couRec.Id).Product_type__c){
                productTypeIds.add(couRec.Product_type__c);
            }
        }
        if(!productTypeIds.isEmpty()) {
            Map<String, List<Unit_Product_Type_Field__c>> productTypeIdsToFieldMap = new Map<String, List<Unit_Product_Type_Field__c>>();
            for(Unit_Product_Type_Field__c fieldRec : [SELECT COU_API_Name__c, Unit_Product_Type__c FROM Unit_Product_Type_Field__c WHERE Unit_Product_Type__c IN: productTypeIds AND Active__c = false]) {
                if(!productTypeIdsToFieldMap.containsKey(fieldRec.Unit_Product_Type__c)) {
                    productTypeIdsToFieldMap.put(fieldRec.Unit_Product_Type__c, new List<Unit_Product_Type_Field__c>());
                }
                productTypeIdsToFieldMap.get(fieldRec.Unit_Product_Type__c).add(fieldRec);
            }
            for(Customer_Owned_Unit__c couRec : customerOwnerUnitNewList){
                if(productTypeIdsToFieldMap.containsKey(couRec.Product_type__c)) {
                    for(Unit_Product_Type_Field__c fieldRec : productTypeIdsToFieldMap.get(couRec.Product_type__c)) {
                        couRec.put(fieldRec.COU_API_Name__c, null);
                    }
                }
            }
        }
    }

    private static void deleteAttachedDocuments() {
        List<Document__c> documents = [SELECT Id FROM Document__c WHERE Unit__c IN :customerOwnerUnitOldList];
        DMLUtility.deleteSobjectList('Document__c', documents);
    }
}
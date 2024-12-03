/** 
* Author: Hitesh Gupta
* Since: Nov 3, 2017 
* Name: UnitOrderingService 
* Description: Apex class which contains all service methods related to Unit Ordering Page.
**/
public without sharing class UnitOrderingService {
    
    public static List<UnitOrderingWrapper.VendorWrapper> getVendorsList(){
        List<Account> vendorsList = [select Id, Name, Purchase_Tax__c, Country__c, Country__r.Name__c, Country__r.Currency_Code__c, Is_Foreign_Vendor__c, 
                                    Country__r.Currency_Name__c, Country__r.Flag_Encoded__c, Country__r.Conversion_Rate_With_Markup__c, Country__r.Backward_Conversion_Rate__c
                                    from Account where Is_Vendor__c = true AND Unit_Purchases__c = true]; 

        List<AggregateResult> orduCountViaVendorList = [Select COUNT(ID) orduCount, Vendor__c from Customer_Owned_Unit__c where Unit_Type__c = 'ORDU' AND Status__c = 'On Order' AND  Vendor__c In: vendorsList Group By Vendor__c];
                                        
        List<UnitOrderingWrapper.VendorWrapper> vendorList = new UnitOrderingWrapper.VendorWrapper().convertToWrapperList(vendorsList, orduCountViaVendorList);
        return vendorList;
    }
    
    public static UnitOrderingWrapper.VendorWrapper getVendorDetailsById(String vendorId){
        List<Account> vendorsList = [select Id, Name, Purchase_Tax__c, Country__c, Country__r.Name__c, Country__r.Currency_Code__c, Is_Foreign_Vendor__c, 
                                        Country__r.Currency_Name__c, Country__r.Flag_Encoded__c, Country__r.Conversion_Rate_With_Markup__c, Country__r.Backward_Conversion_Rate__c   
                                        from Account 
                                        where Is_Vendor__c = true
                                            AND Id = :vendorId]; 
                                            
        List<PO_Type__c> poTypeList = [SELECT Lead_Time__c FROM PO_Type__c WHERE Code__c =: 'STANDARD'];                              
        UnitOrderingWrapper.VendorWrapper vendorObj = new UnitOrderingWrapper.VendorWrapper(vendorsList[0], poTypeList.size() > 0 ? poTypeList[0] : null);
        return vendorObj;                                   
    }
    
    public static List<CategoryService.CategoryWrapper> getUnitCategoryList() {
        return CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => 'Unit'});
    }
    
    public static void SetUnitPurchaseFlagForVendor(String vendorId){
        Account acc = new Account();
        acc.Id = vendorId;
        acc.Unit_Purchases__c = true;
        update acc;
    }   
    
    public static List<UnitOrderingWrapper.UnitOrderWrapper> getActiveOrderList(String vendorId) {
        return new UnitOrderingWrapper.UnitOrderWrapper().convertToWrapperList(SOQLUtil.getActiveOrderList(vendorId, new Map<String, String>{'Formatted_Name__c' => 'ASC'}));
    }
    
    public static List<UnitOrderingWrapper.UnitOrderWrapper> getActiveOrderList(String vendorId, String JSONString) {
        UnitOrderingWrapper.SortingAttrs sortAttrs = (UnitOrderingWrapper.SortingAttrs) System.JSON.deserialize(jSONString, UnitOrderingWrapper.SortingAttrs.class);
        
        Map<String, String> fieldNameToSortOrderMap = new Map<String, String>();
        if(UnitOrderingWrapper.fieldLabelToFieldAPINameMap.containsKey(sortAttrs.FieldLabel)) {
            fieldNameToSortOrderMap.put(UnitOrderingWrapper.fieldLabelToFieldAPINameMap.get(sortAttrs.FieldLabel), sortAttrs.SortingOrder);
        }
        return new UnitOrderingWrapper.UnitOrderWrapper().convertToWrapperList(SOQLUtil.getActiveOrderList(vendorId, fieldNameToSortOrderMap));
    }
    
    public static void cancelOrderedUnit(String unitId) {
        Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c(Id = unitId);
        unitRec.Status__c = 'Cancelled';
        unitRec.Stock_Id__c = null;
        unitRec.Stocked_In_DateTime__c = system.now();
        if(String.isNotBlank(unitRec.Id)) {
            update unitRec;
        }
    }
    
    public static void savePriceAndCost(String unitId, String jSONString) {
        List<UnitWrapper.PriceAndCostTrackingWrapper> unitPriceAndCostList = (List<UnitWrapper.PriceAndCostTrackingWrapper>) System.JSON.deserialize(jSONString, List<UnitWrapper.PriceAndCostTrackingWrapper>.class);
        List<Unit_Price_Cost__c> upcList = new List<Unit_Price_Cost__c>();
        for(UnitWrapper.PriceAndCostTrackingWrapper factOptionObj : unitPriceAndCostList) {
            Unit_Price_Cost__c unitPriceAndCostRec = setUnitPriceAndCostFields(unitId, factOptionObj); 
            upcList.add(unitPriceAndCostRec);
        }
        if(AccessControl.ifObjectFieldIsCreateable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        upsert upcList;
    }
    
    public static void removePriceAndCost(String recordId) {
        if(AccessControl.ifObjectIsDeletable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete new Unit_Price_Cost__c(Id = recordId);
    } 
    
    public static Unit_Price_Cost__c setUnitPriceAndCostFields(String unitId, UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
        
        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c();

        unitPriceAndCostRec.Id = unitPriceAndCostObj.Id;
        unitPriceAndCostRec.Type__c = unitPriceAndCostObj.Type;
        unitPriceAndCostRec.Item_Description__c = unitPriceAndCostObj.ItemDescription;
        unitPriceAndCostRec.Qty__c = unitPriceAndCostObj.Quantity;
        unitPriceAndCostRec.Price__c = unitPriceAndCostObj.Price;
        if(unitPriceAndCostRec.Type__c == 'Factory' || unitPriceAndCostRec.Type__c == 'Base') {
            unitPriceAndCostRec.Price__c = unitPriceAndCostObj.TotalPrice;
        }
        unitPriceAndCostRec.Total_Price__c = unitPriceAndCostObj.TotalPrice; 
        unitPriceAndCostRec.Total_Cost__c = unitPriceAndCostObj.TotalCost;
        unitPriceAndCostRec.Taxable__c = unitPriceAndCostObj.Taxable != null ? unitPriceAndCostObj.Taxable : true;
        unitPriceAndCostRec.Customer_Owned_Unit__c = unitPriceAndCostObj.UnitId != null ? unitPriceAndCostObj.UnitId : unitId;
        unitPriceAndCostRec.Factory_Option__c = unitPriceAndCostObj.FactoryOptionId;

        return unitPriceAndCostRec;
    }
    
    private static List<UnitOrderingWrapper.UnitOrderWrapper> updateFieldsInWrapper(List<UnitOrderingWrapper.UnitOrderWrapper> unitOrderWrapperList) {
        // Create set of order units
        Set<String> orderUnitIdSet = new Set<String>();
        for(UnitOrderingWrapper.UnitOrderWrapper unitOrderWrapper : unitOrderWrapperList) {
            orderUnitIdSet.add(unitOrderWrapper.UnitId);
        }
        // Get Stocked units created from Ordered units and Create Map of Order Unit To Stock Unit Rec
        Map<String, Customer_Owned_Unit__c> orderUnitIdToStockUnitRecMap = new Map<String, Customer_Owned_Unit__c>(); 
        for(Customer_Owned_Unit__c unitRec : [SELECT Id, Referenced_Unit__c, Deal_Item__c, (SELECT Deal__r.CO_Header__r.Name, Deal__r.CO_Header__r.Id, Deal__r.CO_Header__r.Customer_Name__c FROM Deals_Units_Junction__r) FROM Customer_Owned_Unit__c WHERE Referenced_Unit__c IN : orderUnitIdSet]) {
            if(!orderUnitIdToStockUnitRecMap.containsKey(unitRec.Referenced_Unit__c)) {
                orderUnitIdToStockUnitRecMap.put(unitRec.Referenced_Unit__c, unitRec);
            }
        }
        // Update fields values in wrapper list
        for(UnitOrderingWrapper.UnitOrderWrapper unitOrderWrapper : unitOrderWrapperList) {
            // Check for cancelled order and not be added on deal units
            if(orderUnitIdToStockUnitRecMap.get(unitOrderWrapper.UnitId) != null && orderUnitIdToStockUnitRecMap.get(unitOrderWrapper.UnitId).Deal_Item__c != null) {
                for(Deal_Item__c dealItemRec: orderUnitIdToStockUnitRecMap.get(unitOrderWrapper.UnitId).Deals_Units_Junction__r) {
					if(dealItemRec.Id == orderUnitIdToStockUnitRecMap.get(unitOrderWrapper.UnitId).Deal_Item__c) {
                        unitOrderWrapper.CoId = dealItemRec.Deal__r.CO_Header__r.Id;
                        unitOrderWrapper.CoNumber = dealItemRec.Deal__r.CO_Header__r.Name;
                        unitOrderWrapper.CustomerName = dealItemRec.Deal__r.CO_Header__r.Customer_Name__c;
						break;	
					}
				}
            }
        }
        // Return updated wrapper
        return unitOrderWrapperList;
    }

    public static List<UnitOrderingWrapper.UnitOrderWrapper> getOrderHistoryList(String filterJson, String JSONString) {
        UnitOrderingWrapper.UnitOrderingFilterWrapper filterObj = (UnitOrderingWrapper.UnitOrderingFilterWrapper) System.JSON.deserialize(filterJson, UnitOrderingWrapper.UnitOrderingFilterWrapper.class);
        Map<String, String> fieldNameToSortOrderMap = new Map<String, String>();
        if(String.isNotBlank(JSONString)) {
            UnitOrderingWrapper.SortingAttrs sortAttrs = (UnitOrderingWrapper.SortingAttrs) System.JSON.deserialize(jSONString, UnitOrderingWrapper.SortingAttrs.class);
            if(UnitOrderingWrapper.fieldLabelToFieldAPINameMap.containsKey(sortAttrs.FieldLabel)) {
                fieldNameToSortOrderMap.put(UnitOrderingWrapper.fieldLabelToFieldAPINameMap.get(sortAttrs.FieldLabel), sortAttrs.SortingOrder);
            }
        } else {
            fieldNameToSortOrderMap.put('Stocked_In_DateTime__c', 'DESC');
        }

        List<UnitOrderingWrapper.UnitOrderWrapper> unitOrderWrapperList = new UnitOrderingWrapper.UnitOrderWrapper().convertToWrapperList(SOQLUtil.getOrderHistoryList(filterObj, fieldNameToSortOrderMap));
        return updateFieldsInWrapper(unitOrderWrapperList);
    }

    public static List<UnitOrderingWrapper.UnitDetailsWrapper> getUnitDetails(String unitId){
        List<Customer_Owned_Unit__c> COUList = SOQLUtil.getUnitByFieldName(new Map<String, String>{'Id' => unitId});
        List<UnitOrderingWrapper.UnitDetailsWrapper> couWrapperRec = new List<UnitOrderingWrapper.UnitDetailsWrapper>();
        for(Customer_Owned_Unit__c couRec : COUList) {
            UnitOrderingWrapper.UnitDetailsWrapper couObj = new UnitOrderingWrapper.UnitDetailsWrapper(couRec);
            couObj.UnitInfo.UnitOptionalFields = UnitProductTypeService.getUnitOptionalFieldsData(couRec.Product_Type__c, couRec.Id);
            couWrapperRec.add(couObj);
        }  
        return couWrapperRec;
        
    }
    
    public static String saveUnitDetails(String jSONString){
        try {
	        UnitOrderingWrapper.UnitDetailsWrapper unitObj = (UnitOrderingWrapper.UnitDetailsWrapper) System.JSON.deserialize(jSONString, UnitOrderingWrapper.UnitDetailsWrapper.class);    	
	        
            if(unitObj != null &&  unitObj.UnitInfo != null && unitObj.UnitInfo.IsAccruePurchaseTaxUntilThisUnitIsSold != null && unitObj.UnitInfo.IsAccruePurchaseTaxUntilThisUnitIsSold) {
                if(unitObj.UnitInfo.VendorId != null && ForeignExchangeUtil.isForeignVendor(unitObj.UnitInfo.VendorId)) {
                    throw new BlackPurlException(Constants.restrictionErrorForForeignVendor);
                }
            }

            Customer_Owned_Unit__c unitRec = ViewUnitCtrl.setUnitFields(unitObj.UnitInfo); 
	        
	        if(unitObj.UnitInfo.Make == null) {
	        	List<Unit_Make__c> makeList = [Select Name from Unit_Make__c where Name =: unitObj.UnitInfo.MakeName];
	        	if(makeList.size() == 0) {
	        		Unit_Make__c makeRec = new Unit_Make__c(Name = unitObj.UnitInfo.MakeName);
	        		insert makeRec;
	        		unitRec.Unit_Make__c = makeRec.Id;
	        	} else {
	        		unitRec.Unit_Make__c = makeList[0].Id;
	        	}
	        	
	        	
	        }
	        if(unitObj.UnitInfo.Model == null) {
	        	List<Unit_Model__c> modelList = [Select Name__c, Unit_Make__c from Unit_Model__c where Name__c =: unitObj.UnitInfo.ModelName AND Unit_Make__c =: unitRec.Unit_Make__c];
	        	if(modelList.size() == 0) {
	        		Unit_Model__c modelRec = new Unit_Model__c(Name__c = unitObj.UnitInfo.ModelName, Unit_Make__c = unitRec.Unit_Make__c);
		        	insert modelRec;
		        	unitRec.Unit_Model__c = modelRec.Id;
	        	} else {
	        		unitRec.Unit_Model__c = modelList[0].Id;
	        	}
	        }
	        if(unitObj.UnitInfo.SubModel == null && String.isNotBlank(unitObj.UnitInfo.SubModelName)) { 
	        	List<Unit_Sub_Model__c> subModelList = [Select Sub_Model_Name__c, Unit_Model__c from Unit_Sub_Model__c where Sub_Model_Name__c =: unitObj.UnitInfo.SubModelName AND Unit_Model__c =: unitRec.Unit_Model__c];
		    	if(subModelList.size() == 0) {
		    		Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c(Sub_Model_Name__c = unitObj.UnitInfo.SubModelName, Unit_Model__c = unitRec.Unit_Model__c);
		        	insert subModelRec;
		        	unitRec.Sub_Model__c = subModelRec.Id;
		    	} else {
		    		unitRec.Sub_Model__c = subModelList[0].Id;
		    	}
	        	
	        }
	        
	    validateAndSetDateFields(unitObj.UnitInfo, unitRec);
        
	        unitRec.Factory_Order_No__c = unitObj.UnitInfo.FactoryOrderNo;
	        unitRec.Unit_Id__c = unitObj.UnitInfo.UnitId;
	        
	        List<Customer_Owned_Unit__c> unitList = [Select Id from Customer_Owned_Unit__c where Unit_Id__c =: unitObj.UnitInfo.UnitId];
	        if(unitList.size() > 0 && unitList[0].Id != unitObj.UnitInfo.Id && String.isNotBlank(unitObj.UnitInfo.UnitId)) {
	            return 'Duplicate Stock Number';
	        }
	        
	        if(String.isNotBlank(unitObj.UnitInfo.VIN) && unitObj.UnitInfo.VIN != 'VIN Unknown') {
	            List<Customer_Owned_Unit__c> similarVINUnitList = SOQLUtil.getSimilarCOUs(unitObj.UnitInfo.VIN);
	            if(similarVINUnitList.size() > 0 && (String.isBlank(unitObj.UnitInfo.Id) || (similarVINUnitList[0].Id != unitObj.UnitInfo.Id))) {
	                return 'Duplicate VIN Number';
	            }
	        }
	        
	        if(unitObj.UnitInfo.Id != null) {
	            unitRec.Id = unitObj.UnitInfo.Id;
	        }
            if(unitRec.Id == null) {
                Unit_Service.populateNotesByModelSubmodelDesc(unitRec);
            }
	        
	        // Save Tags for units 
	        if(unitObj.UnitInfo.AssignedTags != null && unitObj.UnitInfo.AssignedTags.size() > 0) {
	            List<String> tagStrListForFields = TagUtil.convertTagListIntoTagString(unitObj.UnitInfo.AssignedTags);
	            if(tagStrListForFields.size() == 2) {
	                unitRec.Assigned_Tag_1__c = tagStrListForFields[0];
	                unitRec.Assigned_Tag_2__c = tagStrListForFields[1];
	            }
	        } else {
	            unitRec.Assigned_Tag_1__c = unitRec.Assigned_Tag_2__c = '';
	        }
	        upsert unitRec;
	        return unitRec.Id;
    	} catch(Exception e) {
    		if(e.getMessage().contains('duplicate value found') && e.getMessage().contains('Stock_Id__c')) {
    			throw new BlackPurlException('Duplicate Stock Number');
    		}
    		throw new BlackPurlException(e.getMessage());
    	}
    }
    
    private static void validateAndSetDateFields(UnitWrapper.UnitInfoWrapper unitInfo, Customer_Owned_Unit__c unitRec) {
    	if(unitInfo != null && unitInfo.Status != 'Temporary') {
			unitRec.Date_Ordered__c = String.isNotBlank(unitInfo.OrderedDate) ? 
	        						HomeSearchFilterInterface.getDateFromString(unitInfo.OrderedDate).Date() : Date.today();
	        if(String.isNotBlank(unitInfo.ExpectedDate)) {
	        	unitRec.Date_Expected__c = HomeSearchFilterInterface.getDateFromString(unitInfo.ExpectedDate).Date();
	        	if(unitRec.Date_Expected__c < unitRec.Date_Ordered__c) {
		        	throw new BlackpurlException('Date expected cannot be prior to ordered date');
		        }	
	        }
    	}		
    }
    
    public static String receiveUnits(String jSONString) {
        
        UnitReceivingWrapper receivingObj = (UnitReceivingWrapper) System.JSON.deserialize(jSONString, UnitReceivingWrapper.class);
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }

        Set<id> unitIds = new set<id>();
        for(UnitOrderingWrapper.UnitOrderWrapper unit : receivingObj.OrderedUnits) {
            unitIds.add(unit.UnitId);
        }

        Decimal totalUnitCost = 0;
        Map<Id, Account> orderUnitIdToVendorMap = new Map<Id, Account>();
        List<Customer_Owned_Unit__c> orderedUnitList = [SELECT id, Vendor__r.Is_Foreign_Vendor__c, Vendor__r.Country__r.Conversion_Rate_With_Markup__c, (SELECT Total_Cost__c FROM Unit_Prices_Costs__r WHERE Total_Cost__c != null) FROM Customer_Owned_Unit__c WHERE Id IN :unitIds];
        for(Customer_Owned_Unit__c unit : orderedUnitList) {
            if(unit.Vendor__r.Is_Foreign_Vendor__c) {
                orderUnitIdToVendorMap.put(unit.Id, unit.Vendor__r);
            }
            for(Unit_Price_Cost__c upc : unit.Unit_Prices_Costs__r) {
                totalUnitCost += upc.Total_Cost__c;
            }  
            if(totalUnitCost == 0 && (!Test.isRunningTest())) {
                throw new BlackPurlException('Zero cost units cannot be received. Please refresh the page and try again');
            }
        }
        
		receivingObj.OrderedUnits = upsertMakeModelSubModelForUnit(receivingObj.OrderedUnits);
		
        Map<String, Customer_Owned_Unit__c> orderedUnitsIdToReceivedUnitMap = new Map<String, Customer_Owned_Unit__c>();
        List<String> invoiceNumbers = new List<String>();
        for(UnitOrderingWrapper.UnitOrderWrapper unit : receivingObj.OrderedUnits) {
            invoiceNumbers.add(unit.InvoiceNumber); // List to validate InvoiceNumber(s) Duplicacy
            
            Customer_Owned_Unit__c cou = new Customer_Owned_Unit__c();
            cou.Id = unit.UnitId;
            cou.VIN_Number__c = unit.VIN;
            cou.Invoice_Number__c = unit.InvoiceNumber;
            cou.Status__c = 'Received';
            if(orderUnitIdToVendorMap.containsKey(unit.UnitId) && orderUnitIdToVendorMap.get(unit.UnitId).Is_Foreign_Vendor__c) {
                cou.FX_Conversion_Rate__c = orderUnitIdToVendorMap.get(unit.UnitId).Country__r.Conversion_Rate_With_Markup__c;
            }
            cou.ORDU_Stock_Id__c = unit.StockNumber;
            cou.Stock_Id__c = null;
            cou.Stocked_In_DateTime__c = String.isNotBlank(unit.StockedInDateTime) ? HomeSearchFilterInterface.getDateFromString(unit.StockedInDateTime) : system.now();
            cou.Unit_Make__c = unit.MakeId;
            cou.Unit_Model__c = unit.ModelId;
            cou.Sub_Model__c = unit.SubModelId;
            cou.Year__c = unit.Year;
            cou.Cylinders__c = unit.Cylinders; 
            if(GeneralConfiguration.getTaxIncludingPricing() && unit.TotalWithTaxBeforeOverridding != unit.TotalWithTax) {
                cou.Overridden_Total_Cost_With_Tax__c = unit.TotalWithTax.setScale(2, RoundingMode.HALF_UP); 
                cou.Tax_Amount__c = unit.TotalTaxAmount.setScale(2, RoundingMode.HALF_UP); 
            }
            orderedUnitsIdToReceivedUnitMap.put(unit.UnitId, cou);
        }
        
        List<Customer_Owned_Unit__c> alreadyReceivedCOUs = [SELECT Id FROM Customer_Owned_Unit__c WHERE Status__c = 'Received' AND Id In :orderedUnitsIdToReceivedUnitMap.keySet()];
        List<Customer_Owned_Unit__c> duplicateCOUs = [SELECT Id, Invoice_Number__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'ORDU' AND Status__c = 'Received' AND Invoice_Number__c In :invoiceNumbers];
        if(duplicateCOUs.isEmpty() && alreadyReceivedCOUs.isEmpty()) {
            Savepoint sp = Database.setSavepoint();
            try {
                Map<String, Customer_Owned_Unit__c> orderedUnitsIdToStockUnitMap = new Map<String, Customer_Owned_Unit__c>();
                
                //Step 1: Update Customer_Owned_Unit__c with VIN, InoviceNumber, status as "Received"
                
                if(!orderedUnitsIdToReceivedUnitMap.isEmpty()) {
                    update orderedUnitsIdToReceivedUnitMap.values();
                    // put all code here
                }
                
                /* Step 2: This of course would carry across all of the Price & Cost line items 
                   as well which will have the invoice# used for the REF# field in the line items on the Stock Unit record. */
                // 2.1: Load DO Customer_Owned_Unit__c for selected Ids
                List<Customer_Owned_Unit__c> receivedUnitsList = null;
                if(!orderedUnitsIdToReceivedUnitMap.isEmpty()) {
                    String query = 'Select ';
                    for(String fieldName : CustomerOwnedUnit.fieldsList()) {
                        query += fieldName + ', ';
                    }
                    query += 'Invoice_Number__c, Is_Accrue_Purchase_Tax_Until_Unit_Sold__c, Deal_Item__c, Deal_Item__r.Deal__r.Status__c, (SELECT Id, Deal__r.Status__c FROM Deals_Units_Junction__r) ';
                    Set<String> params = orderedUnitsIdToReceivedUnitMap.keySet();
                    query += ' from Customer_Owned_Unit__c where Id In :params';
                    receivedUnitsList = Database.query(query);
                    
                    //Step 2.2: Cloning & Creating as Stock Units with an "Available" status and "STOCK" type
                    String defaultUnitSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
                    Map<String, Customer_Owned_Unit__c> receivedUnitIdToStockUnitsMap = new Map<String, Customer_Owned_Unit__c>();
                    for(Customer_Owned_Unit__c receivedUnit : receivedUnitsList) {
                        SObject stockUnit = receivedUnit.clone(false, false, false, false);
                        stockUnit.put('Id',null);
                        
                        if(orderUnitIdToVendorMap.containsKey(receivedUnit.Id) && orderUnitIdToVendorMap.get(receivedUnit.Id).Is_Foreign_Vendor__c) {
                            stockUnit.put('FX_Conversion_Rate__c', orderUnitIdToVendorMap.get(receivedUnit.Id).Country__r.Conversion_Rate_With_Markup__c);
                        }
                        stockUnit.put('Unit_Type__c','Stock');
                        if(receivedUnit.Deal_Item__c != null && receivedUnit.Deal_Item__r.Deal__r.Status__c == 'In Progress') {
                        	stockUnit.put('Status__c','Reserved');
                        } else {
                        	stockUnit.put('Status__c','Available');
                        }
                        stockUnit.put('Stock_Id__c', receivedUnit.ORDU_Stock_Id__c);
                        stockUnit.put('ORDU_Stock_Id__c', null);
                        stockUnit.put('Unit_Id__c',null);
                        stockUnit.put('Date_Stocked_In__c', receivedUnit.Stocked_In_DateTime__c != null ? receivedUnit.Stocked_In_DateTime__c.date(): Date.today());
                        stockUnit.put('Referenced_Unit__c', receivedUnit.Id);
                        stockUnit.put('Stamp_Duty_Calculators__c', receivedUnit.Stamp_Duty_Calculators__c);
                        stockUnit.put('How_Acquired__c', 'Purchase');
                        stockUnit.put('Reference_Number__c', receivedUnit.Invoice_Number__c);
                        stockUnit.put('Acquired_From__c', receivedUnit.Vendor__c);
                        stockUnit.put('Acquisition_Cost__c', receivedUnit.Total_Cost__c);
                        if(receivedUnit.Is_Accrue_Purchase_Tax_Until_Unit_Sold__c) {
                        	receivedUnit.Total_Cost__c = receivedUnit.Total_Cost__c != null ? receivedUnit.Total_Cost__c : 0;
                        	receivedUnit.Tax_Amount__c = receivedUnit.Tax_Amount__c != null ? receivedUnit.Tax_Amount__c : 0;
                        	
                        	stockUnit.put('Trade_In_Value__c', receivedUnit.Total_Cost__c);
                        	stockUnit.put('Purchase_Tax_Credit__c', receivedUnit.Tax_Amount__c);
                        }
                        receivedUnitIdToStockUnitsMap.put(receivedUnit.Id, (Customer_Owned_Unit__c) stockUnit);
                    }
                    if(!receivedUnitIdToStockUnitsMap.isEmpty()) {
                        insert receivedUnitIdToStockUnitsMap.values();
                    }

                    // Step 2.3: Pull Unit_Price_Cost__c records of OrderedUnits received - clone/create new Unit_Price_Cost__c records under StockeUnits and save them
                    query = 'Select ';
                    for(String fieldName : UnitWrapper.fieldsListForUnitPriceAndCostTracking()) {
                        query += fieldName + ', ';
                    }
                    query = query.substring(0, query.length()-2);
                    query += ', ' + '(Select Id FROM Unit_Prices_Costs__r) ';
                    query += ' from Unit_Price_Cost__c where Customer_Owned_Unit__c In :params';
                    List<Unit_Price_Cost__c> unitPriceCostItemsOfOrderedUnits = Database.query(query);
                    
                    List<Unit_Price_Cost__c> newUnitPriceCostItems = new List<Unit_Price_Cost__c>();
                    for(Unit_Price_Cost__c upc : unitPriceCostItemsOfOrderedUnits) {
                        SObject upcItem = upc.clone(false, false, false, false);
                        if(orderUnitIdToVendorMap.containsKey(upc.Customer_Owned_Unit__c) && orderUnitIdToVendorMap.get(upc.Customer_Owned_Unit__c).Is_Foreign_Vendor__c) {
                            upcItem.put('Total_Cost__c', ForeignExchangeUtil.getConvertedAmountInLocalCurrency(upc.Total_Cost__c, orderUnitIdToVendorMap.get(upc.Customer_Owned_Unit__c).Country__r.Conversion_Rate_With_Markup__c));
                        }
                        upcItem.put('Customer_Owned_Unit__c', receivedUnitIdToStockUnitsMap.get(upc.Customer_Owned_Unit__c).Id);
                        upcItem.put('Ref_No__c', orderedUnitsIdToReceivedUnitMap.get(upc.Customer_Owned_Unit__c).Invoice_Number__c);
                    	upcItem.put('Related_Ordered_Unit_Price_Cost__c', upc.Id);
                        if(upcItem.get('Adjustment_Date__c') == null){
                            upcItem.put('Adjustment_Date__c', DateTime.newInstance(receivedUnitIdToStockUnitsMap.get(upc.Customer_Owned_Unit__c).Date_Stocked_In__c, Time.newInstance(0, 0, 0, 0)));
                        }
                        newUnitPriceCostItems.add((Unit_Price_Cost__c) upcItem);
                    }
                    newUnitPriceCostItems.addAll(createLCAOnStockUnits(receivingObj.LandedCostAdjustments, receivedUnitIdToStockUnitsMap.values()));
                    if(!newUnitPriceCostItems.isEmpty()) {
                        insert newUnitPriceCostItems;
                    }                   
                    updateDealItems(newUnitPriceCostItems, unitPriceCostItemsOfOrderedUnits, receivedUnitsList, receivedUnitIdToStockUnitsMap);
                    updateDealServiceUnits(receivedUnitIdToStockUnitsMap);
                }
            } catch(Exception e) {
                Database.rollback(sp);
                throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
            }
        } else {
            String duplicateInvoiceNumbers = '';
            if(duplicateCOUs.size() > 0) {
                for(Customer_Owned_Unit__c units : duplicateCOUs) {
                    duplicateInvoiceNumbers += units.Invoice_Number__c + ' ';
                }
            }
            return BPUtility.getEncodedString('{"DuplicateInvoiceNumbers" : "'+ duplicateInvoiceNumbers +'","HasError" : true, "ErrorMessage" : "' + (alreadyReceivedCOUs.isEmpty()? Label.Duplicate_Invoice_Number_Error_Msg : Label.Unit_Already_Received_Error_Msg) + '"}');
        }
        return 'SUCCESS';
    }
    
    private static List<Unit_Price_Cost__c> createLCAOnStockUnits(List<UnitWrapper.PriceAndCostTrackingWrapper> landedCostAdjustments, List<Customer_Owned_Unit__c> receivedUnits) {
        List<Unit_Price_Cost__c> upcInsertList = new List<Unit_Price_Cost__c>();
        if(landedCostAdjustments != null && receivedUnits != null && !receivedUnits.isEmpty()) {
            Map<Id, Decimal> foreignVendorIdToConversionRateMap = getForeignVendorIdToConversionRateMap(landedCostAdjustments);
            Integer noOfUnitsReceived = receivedUnits.size();
            Integer counter = 1;
            for(Customer_Owned_Unit__c receivedUnit : receivedUnits) {
                for(UnitWrapper.PriceAndCostTrackingWrapper lcaObj : landedCostAdjustments) {
                    if(lcaObj.TotalCost != null && lcaObj.TotalCost != 0) {
                        if(counter == 1) {  //LCA is distributed among all units and her cost is divided once because we are directly setting cost of LCA object. In next looping it is automatically distributed cost as pass by reference
                            lcaObj.TotalCost = lcaObj.TotalCost.divide(noOfUnitsReceived, 2, System.RoundingMode.DOWN);
                        }
                        Unit_Price_Cost__c baseUPCRec = setUnitPriceAndCostBasicFields(lcaObj, foreignVendorIdToConversionRateMap.get(lcaObj.VendorId));
                        baseUPCRec.Adjustment_Date__c = receivedUnit.Stocked_In_DateTime__c;
                        if(noOfUnitsReceived > 1 && String.isNotBlank(baseUPCRec.Vendor_Reference_Number__c)) {
                            baseUPCRec.Vendor_Reference_Number__c += '-' + counter;
                        }
                        baseUPCRec.Customer_Owned_Unit__c = receivedUnit.Id;
                        upcInsertList.add(baseUPCRec);
                    }
                }
                counter++;
            }
        }
        return upcInsertList;
    }

    private static Unit_Price_Cost__c setUnitPriceAndCostBasicFields(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj, Decimal conversionRateWithMarkup) {
        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c(Id = unitPriceAndCostObj.Id);
        unitPriceAndCostRec.Type__c = unitPriceAndCostObj.Type;
        unitPriceAndCostRec.Ref_No__c = unitPriceAndCostObj.RefNo;
        unitPriceAndCostRec.Item_Description__c = unitPriceAndCostObj.ItemDescription;
        unitPriceAndCostRec.Qty__c = unitPriceAndCostObj.Quantity;
        unitPriceAndCostRec.Price__c = unitPriceAndCostObj.Price;
        unitPriceAndCostRec.Total_Price__c = unitPriceAndCostObj.TotalPrice != null ? unitPriceAndCostObj.TotalPrice : 0; 
        unitPriceAndCostRec.Total_Cost__c = unitPriceAndCostObj.TotalCost;
        unitPriceAndCostRec.Adjustment_Date__c = String.isNotBlank(unitPriceAndCostObj.AdjustmentDate) ? HomeSearchFilterInterface.getDateFromString(unitPriceAndCostObj.AdjustmentDate) : system.today();
        if(unitPriceAndCostRec.Type__c == 'Factory' || unitPriceAndCostRec.Type__c == 'Base') {
            unitPriceAndCostRec.Price__c = unitPriceAndCostRec.Total_Price__c;
        }
        if(String.isNotBlank(unitPriceAndCostObj.UnitId)) {
            unitPriceAndCostRec.Customer_Owned_Unit__c = unitPriceAndCostObj.UnitId;
        }
        if(String.isNotBlank(unitPriceAndCostObj.CategoryId)) {
            unitPriceAndCostRec.Category__c = unitPriceAndCostObj.CategoryId;
        }
        if(String.isNotBlank(unitPriceAndCostObj.ApplicableTaxID)) {
            unitPriceAndCostRec.Applicable_Tax__c = unitPriceAndCostObj.ApplicableTaxID;
        }
        if(String.isNotBlank(unitPriceAndCostObj.VendorId)) {
            unitPriceAndCostRec.Vendor__c = (String.isNotBlank(unitPriceAndCostObj.VendorId) ? unitPriceAndCostObj.VendorId	 : null);
            unitPriceAndCostRec.Vendor_Reference_Number__c = unitPriceAndCostObj.VendorReferenceNumber;
            if(unitPriceAndCostObj.IsForeignVendor != null && unitPriceAndCostObj.IsForeignVendor) {
                conversionRateWithMarkup = (conversionRateWithMarkup != null && conversionRateWithMarkup != 0) ? conversionRateWithMarkup : 1;
                unitPriceAndCostRec.Total_Foreign_Cost__c = unitPriceAndCostObj.TotalCost;
                unitPriceAndCostRec.FX_Conversion_Rate__c = conversionRateWithMarkup;
                unitPriceAndCostRec.Total_Cost__c = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(unitPriceAndCostRec.Total_Foreign_Cost__c, conversionRateWithMarkup);
            }
        }
        return unitPriceAndCostRec;
    }

    private static Map<Id, Decimal> getForeignVendorIdToConversionRateMap(List<UnitWrapper.PriceAndCostTrackingWrapper> landedCostAdjustments) {
        Map<Id, Decimal> foreignVendorIdToConversionRateMap = new Map<Id, Decimal>();
        if(landedCostAdjustments != null) {
            for(UnitWrapper.PriceAndCostTrackingWrapper lcaObj : landedCostAdjustments) {
                if(String.isNotBlank(lcaObj.VendorId) && lcaObj.IsForeignVendor != null && lcaObj.IsForeignVendor) {
                    foreignVendorIdToConversionRateMap.put(lcaObj.VendorId, null);
                }
            }
            foreignVendorIdToConversionRateMap = ForeignExchangeUtil.getConversionRateWithMarkupByVendorIds(foreignVendorIdToConversionRateMap.keySet());
        }
        return foreignVendorIdToConversionRateMap;
    }
    
    public static List<UnitOrderingWrapper.UnitOrderWrapper> upsertMakeModelSubModelForUnit(List<UnitOrderingWrapper.UnitOrderWrapper> orderedUnits) {
    	Map<String, UnitOrderingWrapper.UnitOrderWrapper> makeNameToUnitMap = new Map<String, UnitOrderingWrapper.UnitOrderWrapper>();
    	Map<String, Map<String, String>> makeIdToModelNameToModelIdMap = new Map<String, Map<String, String>>();
    	Map<String, UnitOrderingWrapper.UnitOrderWrapper> subModelNameToUnitMap = new Map<String, UnitOrderingWrapper.UnitOrderWrapper>();
        
        Map<String, String> makeNameToMakeIdMap = new Map<String, String>();
        for(UnitOrderingWrapper.UnitOrderWrapper unit : orderedUnits) {
        	makeNameToMakeIdMap.put(unit.MakeName, null);
        }
        List<Unit_Make__c> makeList = [Select Name from Unit_Make__c where Name IN: makeNameToMakeIdMap.keySet()];
        
		for(Unit_Make__c make : makeList) {
			makeNameToMakeIdMap.put(make.Name, make.Id);
		}
        Map<String, Unit_Make__c> makeNameToRecInsertMap = new Map<String, Unit_Make__c>();
        for(String makeName : makeNameToMakeIdMap.keySet()) {
        	if(String.isBlank(makeNameToMakeIdMap.get(makeName))) {
        		makeNameToRecInsertMap.put(makeName, new Unit_Make__c(Name = makeName));
        	}
        }
        //All make inserted
        if(makeNameToRecInsertMap.size() > 0) {
        	insert makeNameToRecInsertMap.values();
        }
        
        Set<String> modelNameSet = new Set<String>();
	    for(UnitOrderingWrapper.UnitOrderWrapper unit : orderedUnits) {
	     	if(makeNameToRecInsertMap.containsKey(unit.MakeName)) {
	     		unit.MakeId = makeNameToRecInsertMap.get(unit.MakeName).Id;
	     	} else {
	     		unit.MakeId = makeNameToMakeIdMap.get(unit.MakeName);
	     	}
	     	makeIdToModelNameToModelIdMap.put(unit.MakeId, new Map<String, String>{unit.ModelName => null});
	     	modelNameSet.add(unit.ModelName);
	    }
        
        List<Unit_Model__c> modelList = [Select Name__c, Unit_Make__c from Unit_Model__c where Name__c IN: modelNameSet];
        
        for(Unit_Model__c model : modelList) {
        	if(makeIdToModelNameToModelIdMap.containsKey(model.Unit_Make__c)) {
        		makeIdToModelNameToModelIdMap.get(model.Unit_Make__c).put(model.Name__c, model.Id);
        	}
		}
		
		Map<String, Map<String , Unit_Model__c>> makeIdTomodelNameToUnitModelInsertMap = new Map<String, Map<String , Unit_Model__c>>();
        List<Unit_Model__c> modelToInsertList = new List<Unit_Model__c>();
        
        for(String makeId : makeIdToModelNameToModelIdMap.keySet()) {
        	for(String modelName : makeIdToModelNameToModelIdMap.get(makeId).keySet()) {
        		if(String.isBlank(makeIdToModelNameToModelIdMap.get(makeId).get(modelName))) {
        			modelToInsertList.add( new Unit_Model__c(Name__c = modelName, Unit_Make__c = makeId));
        		}
	        }
        }
        
        //Inserted all models
        if(modelToInsertList.size() > 0) {
        	insert modelToInsertList;
        }
        
        for(Unit_Model__c unitModel : modelToInsertList) {
        	if(makeIdToModelNameToModelIdMap.containsKey(unitModel.Unit_Make__c) && String.isBlank(makeIdToModelNameToModelIdMap.get(unitModel.Unit_Make__c).get(unitModel.Name__c))) {
        		makeIdToModelNameToModelIdMap.get(unitModel.Unit_Make__c).put(unitModel.Name__c, unitModel.Id);
        	}
        }
        
        //Set all model ids
        for(UnitOrderingWrapper.UnitOrderWrapper unit : orderedUnits) {
	     	if(String.isBlank(unit.ModelId) && makeIdToModelNameToModelIdMap.containsKey(unit.MakeId) && (makeIdToModelNameToModelIdMap.get(unit.MakeId)).containsKey(unit.ModelName)) {
	     		unit.ModelId = makeIdToModelNameToModelIdMap.get(unit.MakeId).get(unit.ModelName);
	     	}
	     	subModelNameToUnitMap.put(unit.SubModelName, unit);
	    }
	    
	    List<Unit_Sub_Model__c> subModelList = [Select Sub_Model_Name__c, Unit_Model__c from Unit_Sub_Model__c where Sub_Model_Name__c IN: subModelNameToUnitMap.keySet()];
        
        Map<String, Map<String, String>> modelIdToSubModelNameToIdMap = new Map<String, Map<String, String>>();
        for(Unit_Sub_Model__c subModel : subModelList) {
        	if(!modelIdToSubModelNameToIdMap.containsKey(subModel.Unit_Model__c)) {
        		modelIdToSubModelNameToIdMap.put(subModel.Unit_Model__c, new Map<String, String>());
        	}
        	modelIdToSubModelNameToIdMap.get(subModel.Unit_Model__c).put(subModel.Sub_Model_Name__c, subModel.Id);
		}
		
		Map<String, Unit_Sub_Model__c> subModelNameToUnitSubModelInsertMap = new Map<String, Unit_Sub_Model__c>();
		
		for(String subModelName : subModelNameToUnitMap.keySet()) {
			String modelId = subModelNameToUnitMap.get(subModelName).ModelId;
			Map<String, String> subModelNameToIdMap = modelIdToSubModelNameToIdMap.containsKey(modelId) ? modelIdToSubModelNameToIdMap.get(modelId) : null;
			if(subModelNameToIdMap != null && subModelNameToIdMap.containsKey(subModelName)) {
				subModelNameToUnitMap.get(subModelName).SubModelId = subModelNameToIdMap.get(subModelName);
			} else {
				subModelNameToUnitSubModelInsertMap.put(subModelName, new Unit_Sub_Model__c(Sub_Model_Name__c = subModelName, Unit_Model__c = modelId));
			}
        }
        if(subModelNameToUnitSubModelInsertMap.size() > 0) {
        	insert subModelNameToUnitSubModelInsertMap.values();
        }
        
        for(UnitOrderingWrapper.UnitOrderWrapper unit : orderedUnits) {
	     	if(subModelNameToUnitSubModelInsertMap.containsKey(unit.SubModelName)) {
	     		unit.SubModelId = subModelNameToUnitSubModelInsertMap.get(unit.SubModelName).Id;
	     	} else {
	     		unit.SubModelId = subModelNameToUnitMap.get(unit.SubModelName).SubModelId;
	     	}
	    }
        return orderedUnits;
    }
    
    private static void updateDealItems(List<Unit_Price_Cost__c> skuPriceCostItems, List<Unit_Price_Cost__c> unitPriceCostItemsOfOrderedUnits,List<Customer_Owned_Unit__c> ordUnitList, Map<String, Customer_Owned_Unit__c> receivedUnitIdToStockUnitsMap) {
    	List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();
        for(Customer_Owned_Unit__c ordUnit : ordUnitList) {
            if(receivedUnitIdToStockUnitsMap.containsKey(ordUnit.Id) ) {
                for(Deal_Item__c diRec: ordUnit.Deals_Units_Junction__r) {
                    Deal_Item__c dealItemRec = new Deal_Item__c(Id = diRec.Id, Customer_Owned_Unit__c = receivedUnitIdToStockUnitsMap.get(ordUnit.Id).Id);
                    dealItemListToUpdate.add(dealItemRec);
                }
            }
        }
        
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(dealItemListToUpdate.size() > 0) {
        	update dealItemListToUpdate;
        }
        updateUnitCostAndPrice(dealItemListToUpdate);
    }
    
    private static void updateUnitCostAndPrice(List<Deal_Item__c> dealItemRecList) {
		if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(AccessControl.ifObjectFieldIsAccessible('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCostList = [Select Id, Name, Unit_Price_Cost__c from Deal_Unit_Price_Cost__c where Deal_Item__c IN: dealItemRecList];
        Set<Id> unitCostPriceIdSet = new Set<Id>();
    	for(Deal_Unit_Price_Cost__c dupc : dealUnitPriceCostList) {
    		if(String.isNotBlank(dupc.Unit_Price_Cost__c)) {
    			unitCostPriceIdSet.add(dupc.Unit_Price_Cost__c);
    		}
		}
        Map<Id, Unit_Price_Cost__c> unitPriceCostIdToRecMap = new Map<Id, Unit_Price_Cost__c>([Select Id, (Select Id from Unit_Prices_Costs__r) FROM Unit_Price_Cost__c where Id IN: unitCostPriceIdSet]);
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCostUpdateList = new List<Deal_Unit_Price_Cost__c>();
		for(Deal_Unit_Price_Cost__c dupc : dealUnitPriceCostList) {
			if(dupc.Unit_Price_Cost__c != null && unitPriceCostIdToRecMap.containsKey(dupc.Unit_Price_Cost__c) && unitPriceCostIdToRecMap.get(dupc.Unit_Price_Cost__c).Unit_Prices_Costs__r.size() > 0) {
				dupc.Unit_Price_Cost__c = (unitPriceCostIdToRecMap.get(dupc.Unit_Price_Cost__c).Unit_Prices_Costs__r[0].Id);
				dealUnitPriceCostUpdateList.add(dupc);
			}
		}
		
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(dealUnitPriceCostUpdateList.size() > 0) {
        	update dealUnitPriceCostUpdateList;
        }
    }
    
    public static void updateDealServiceUnits(Map<String, Customer_Owned_Unit__c> orduIdToSkUnitMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = [Select Customer_Owned_Unit__c from Service_Order_Header__c where Customer_Owned_Unit__c IN: orduIdToSkUnitMap.keySet()];
    	
		for(Service_Order_Header__c soHeaderRec : soHeaderList) {
			if(orduIdToSkUnitMap.containsKey(soHeaderRec.Customer_Owned_Unit__c)) {
				soHeaderRec.Customer_Owned_Unit__c = orduIdToSkUnitMap.get(soHeaderRec.Customer_Owned_Unit__c).Id; 
			}
		}
		
		if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		if(soHeaderList.size() > 0 ) {
			update soHeaderList;
		}
    }
    
    public static String checkDuplicateVIN(String vin) {
        if(String.isNotBlank(vin)) {
            List<Customer_Owned_Unit__c> similarVINUnitList = SOQLUtil.getSimilarCOUs(vin);
            if(similarVINUnitList.size() > 0) {
                return '{"HasError" : true, "ErrorMessage" : "Duplicate VIN Number"}';
            }
            return 'SUCCESS';
        }
        return '{"HasError" : true, "ErrorMessage" : "VIN Number is required"}';
    }

    /**
     * Name: getAllPurchaseTaxList
     * Desc: Method to get all active purchase tax list 
     * @param: Vendor purchase tax id as default
     * @return: String 
    **/
    public static String getAllPurchaseTaxList(String vendorPurchaseTaxId) {
        List<Sales_Tax__c> salesTaxList = [SELECT Id, Name__c  FROM Sales_Tax__c WHERE Active__c = true AND Tax_Type__c = 'Purchase' Order by Name__c ASC];
        List<UnitOrderingWrapper.PurchaseTaxWrapper> purchaseTaxList = new List<UnitOrderingWrapper.PurchaseTaxWrapper>();
        for(Sales_Tax__c salesTaxRec : salesTaxList) {
            purchaseTaxList.add(new UnitOrderingWrapper.PurchaseTaxWrapper(salesTaxRec, salesTaxRec.Id == vendorPurchaseTaxId)); 
        }
        return system.JSON.serialize(purchaseTaxList);
    }

    /**
     * Name: setUnitsPurchaseTax
     * Desc: Set purchase tax on ordered units while receiving units
     * @param: (1) jSONString -Set of ordered units id set (2) Purchase tax id to which to be set
     * @return: List unit ordering wrapper
    **/
    public static List<UnitOrderingWrapper.UnitOrderWrapper> setUnitsPurchaseTax(Set<String> unitIdSet, String purchaseTaxId) {
        String query = 'SELECT ' + String.join(UnitOrderingWrapper.fieldsListForOrderUnit(), ',') 
                        + ', (Select Type__c, Total_Cost__c, Total_Price__c from Unit_Prices_Costs__r) FROM Customer_Owned_Unit__c WHERE Id In :unitIdSet Order BY Unit_Number__c ASC';
        List<Customer_Owned_Unit__c> couList = (List<Customer_Owned_Unit__c>)Database.query(query);
        
        List<Sales_Tax__c> purchaseTaxList = [SELECT Id, Name__c, Rate__c  FROM Sales_Tax__c WHERE Active__c = true AND Tax_Type__c = 'Purchase' AND Id =: purchaseTaxId Limit 1];
        List<Applicable_Taxes__c> applicableTaxList = new List<Applicable_Taxes__c>();

        if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
            applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>{purchaseTaxId});
        } 
        for(Customer_Owned_Unit__c couRec : couList) {
            if(purchaseTaxList.size() > 0 && couRec.Unit_Purchase_Tax__c != null) {
                couRec.Unit_Purchase_Tax__r.Rate__c = purchaseTaxList[0].Rate__c;
            }
            couRec.Unit_Purchase_Tax__c = purchaseTaxId;
            Decimal totalTaxAmount = 0;
            if(!TaxCalculation.IsEnhancedTaxCalculationApplicable) {
				if(purchaseTaxList.size() > 0 && purchaseTaxList[0].Rate__c != null) {
            		totalTaxAmount = (couRec.Taxable_Cost__c * purchaseTaxList[0].Rate__c) / 100;
            	}
			} else { // Logic to handle Enhanced tax calculation 
				for(Applicable_Taxes__c appTaxRec : applicableTaxList) {
					if(appTaxRec.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
						totalTaxAmount += (couRec.Taxable_Cost__c * appTaxRec.Sales_Tax_Item__r.Rate__c) / 100;
					} else {
						totalTaxAmount += TaxEngine.getEnhancedTaxAmount(couRec.Taxable_Cost__c, appTaxRec.Sales_Tax_Item__r);
					}
		        }
			}
            couRec.Tax_Amount__c = totalTaxAmount;
		}
        List<UnitOrderingWrapper.UnitOrderWrapper> unitList = new List<UnitOrderingWrapper.UnitOrderWrapper>();
        if(couList.size() > 0) {
            update couList;
            unitList = new UnitOrderingWrapper.UnitOrderWrapper().convertToWrapperList(couList);
        }
        return unitList;
	}

	//To create bulk specified number of units that are replica of passed unitId 
    public static BulkOrderingResponseWrapper createBulkUnits(String unitId, Integer numberOfUnits) {
        List<Customer_Owned_Unit__c> unitList = SOQLUtil.getUnitByFieldName(new Map<String, String>{'Id' => unitId});
        List<Customer_Owned_Unit__c> bulkUnitList = new List<Customer_Owned_Unit__c>();

        List<Unit_Price_Cost__c> unitPriceAndCostList = SOQLUtil.getUnitPriceCostDetailsByUnitIds(new Set<Id>{unitId});
        List<Unit_Price_Cost__c> bulkUnitPriceAndCostList = new List<Unit_Price_Cost__c>();
		
		//Response is initilized with success here since error is handled later with specific message
        BulkOrderingResponseWrapper responseObj = new BulkOrderingResponseWrapper();
        
        List<Database.SaveResult> resultList = new List<Database.SaveResult>();

        if(unitList.size() > 0) {
            for(integer i = 0; i < numberOfUnits; i++) {
                Customer_Owned_Unit__c cloneUnitRec = unitList[0].clone(false, false, false, false);
                cloneUnitRec.Unit_Id__c = null;
                cloneUnitRec.VIN_Number__c = null;
                cloneUnitRec.Stock_Id__c = null;
                bulkUnitList.add(cloneUnitRec);
            }

            resultList = DMLUtility.insertSobjectListAndGetResult('Customer_Owned_Unit__c', bulkUnitList, false);

            String errorMessage;
            Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c();
            for(Database.SaveResult result : resultList) {
                if(result.isSuccess()) {
                    if(unitPriceAndCostList.size() > 0) {
                        for(Unit_Price_Cost__c unitPriceAndCost : unitPriceAndCostList) {
                            unitPriceAndCostRec = unitPriceAndCost.clone(false, false, false, false);
                            unitPriceAndCostRec.Customer_Owned_Unit__c = result.getId();
                            bulkUnitPriceAndCostList.add(unitPriceAndCostRec);
                        }
                    } else {
                        unitPriceAndCostRec = new Unit_Price_Cost__c();
                        unitPriceAndCostRec.Type__c = 'Base';
                        unitPriceAndCostRec.Item_Description__c = 'Base - Unit';
                        unitPriceAndCostRec.Customer_Owned_Unit__c = result.getId();
                        bulkUnitPriceAndCostList.add(unitPriceAndCostRec);
                    }
					responseObj.TotalUnitsCreated++;
                } else {
                    List<Database.Error> errorList = result.getErrors();
                    errorMessage = errorList[0].getMessage(); 
                }
            }
            
            DMLUtility.insertSobjectList('Unit_Price_Cost__c', bulkUnitPriceAndCostList);
            
            if(numberOfUnits != responseObj.TotalUnitsCreated) {
                responseObj.responseStatus = 'Error';
                responseObj.response = errorMessage + ' was encountered while creating the additional units, {{TotalUnitsCreated}} of the request {{TotalUnitsToCreate}} units were created';
            } else {
                responseObj.responseStatus = 'Success';
                responseObj.response = 'Bulk units are successfully inserted';
            }
        } else {
            responseObj.responseStatus = 'Error';
            responseObj.response = 'Error was encountered while creating the additional units, {{TotalUnitsCreated}} of the request {{TotalUnitsToCreate}} units were created';
        }
        return responseObj;
    }

  	public static List<UnitOrderingWrapper.UnitOrderWrapper> getRequiredUnitListForOrder() {
        return new UnitOrderingWrapper.UnitOrderWrapper().convertToWrapperList(SOQLUtil.getRequiredUnitListForOrder());
    }
    
    public static String removeOrderUnitExistOnCO(String unitId) {
        String response = dealService.saveUnitStatus(unitId, 'Required');
        return response;
    }

    public class BulkOrderingResponseWrapper {
        public String response;
        public Integer totalUnitsCreated = 0;
        public String responseStatus;
    }

    public class UnitReceivingWrapper {
        public List<UnitWrapper.PriceAndCostTrackingWrapper> LandedCostAdjustments;
        public List<UnitOrderingWrapper.UnitOrderWrapper> OrderedUnits;
    }
}
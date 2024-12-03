/**
 * Author: Tarun Khandelwal
 * Since: June 05, 2015
 * Name: CustomerViewCtrl
 * Description: Controller Class of Customer Detail Page.
**/ 
global without sharing class ViewCustomerCtrl {
	public Decimal Home_Search_Grid_Page_Size { get{return GeneralConfiguration.getHomeSearchGridPageSize();} private set;}
    public Decimal Related_List_Page_Size { get{return GeneralConfiguration.getRelatedListPageSize();} private set;}
    public boolean Is_Widget_Removeable {get{return GeneralConfiguration.isWidgetRemoveable();}}
    public boolean Load_New_Customer_Order {get{return GeneralConfiguration.isLoadNewCustomerOrder();} private set;}
    public boolean Load_New_View_Customer {get{return GeneralConfiguration.isLoadNewViewCustomer();} private set;}
    public Decimal Sales_Tax_Rate {get{return GeneralConfiguration.getAustralianMarketSalesTaxRate();} private set;}
    
    global ViewCustomerCtrl (NewHomePageCtrl controller){}
    public ViewCustomerCtrl() {}
    
    global static String getCustomerInfo(String customerId) {return '';}

    global static String getRelatedCustomerByCustomerId1(String customerId) { return '';}
    
    global static String getRelatedCustomerByCustomerId(String customerId) { return '';}
    
    global static String updateRelatedCustomer(String relatedCustomerString) { return '';}

    global static String getCOUListByCustomerId(String customerId) { return '';}

    global static String removeCOURecord(String customerId, String recordId) { return '';}

    global static String removeCustomerContactRecord(String customerId, String recordId) { return '';}
    	
    global static String updateCustomerContactRelation(String jsonString) { return '';}
    
    /**
     * Name: getOtherSimilarCustomer
     * Desc: 
     * @param:  
     * @return:  
    **/
   @RemoteAction
    global static String getSimilarCOUs(String VINNumber){
        return NewViewCustomerCtrl.getSimilarCOUs(VINNumber);
    }
    
    /**
     * Name: getApplicableTaxList
     * Desc: To get Unit Details on Edit Stock unit Pop Up window
     * @param: 
     * @return: String - JSON string of Sales Tax info. 
    **/
    @RemoteAction
    global static String getApplicableTaxList() {
        String defaultUnitTaxId = Configurations__c.getOrgDefaults().Default_Tax_on_Unit__c;
        return BPUtility.getEncodedString(TaxUtility.getApplicableList(defaultUnitTaxId));
    }
    
    @RemoteAction
    global static String getActiveTagList() {
    	return BPUtility.getEncodedString(System.JSON.serialize(TagManagementCtrl.getActiveTagList()));
    }
    
    /**
     * Name: saveCOU
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String saveCOU(String customerId, String couJSONString) {
    	customerId = BPUtility.getDecodedString(customerId);
        couJSONString = BPUtility.getDecodedString(couJSONString);
        List<CustomerOwnedUnit> couObjList = CustomerOwnedUnit.parse(couJSONString);
        if(couObjList.size() == 0) {
        	return BPUtility.getEncodedString('{}');
        }
        Customer_Owned_Unit__c unitRec = NewViewCustomerCtrl.setUnitFields(couObjList[0]);
        List<Customer_Owned_Unit__c> oldUnitList = new List<Customer_Owned_Unit__c>();
        if(String.isNotBlank(couObjList[0].Id)) {
            oldUnitList = [SELECT Name, Status__c, VIN_Number__c, Total_Base_Unit_Price__c, (Select Id, Total_Price__c FROM Unit_Prices_Costs__r WHERE Id =: couObjList[0].BaseUnitId) 
                        FROM Customer_Owned_Unit__c WHERE Id =: couObjList[0].Id];
	        
	        if(oldUnitList.size() > 0) {
                if(oldUnitList[0].Status__c == 'Sold') {
                    return getErrorMessageForSoldUnit();
                } else if(oldUnitList[0].Status__c.equalsIgnoreCase('Reserved') && (String.isBlank(unitRec.VIN_Number__c) || unitRec.VIN_Number__c.equalsIgnoreCase('VIN Unknown')) && (String.isNotBlank(oldUnitList[0].VIN_Number__c) && !oldUnitList[0].VIN_Number__c.equalsIgnoreCase('VIN Unknown'))) {
	                return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Vin number can not be removed on reserved unit."}'); 
                } else {
                    unitRec.Status__c = oldUnitList[0].Status__c;
                }
	        }
        }
        List<Customer_Owned_Unit__c> unitList = new List<Customer_Owned_Unit__c>();
        if(couObjList[0].UnitType == 'ORDU' && String.isNotBlank(couObjList[0].UnitId)) {
            unitList = [Select Id from Customer_Owned_Unit__c WHERE Unit_Id__c =: couObjList[0].UnitId];
        } else if(couObjList[0].UnitType == 'STOCK' && String.isNotBlank(couObjList[0].StockId)) {
            unitList = [Select Id from Customer_Owned_Unit__c WHERE Stock_Id__c =: couObjList[0].StockId];
        }
        
        if(!String.isBlank(unitRec.Id) && unitRec.Unit_Type__c != 'ORDU' && couObjList.size() > 0 && !couObjList[0].IsActive) {
        	String errorMessage = getErrorMessageForActivelyUsedUnit(unitRec.Id);
        	if(!String.isBlank(errorMessage)) {
        		return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "'+errorMessage+'"}'); 
        	}
        }
        if(unitList.size() > 0 && unitList[0].Id != couObjList[0].Id && 
            ((couObjList[0].UnitType == 'STOCK' && String.isNotBlank(couObjList[0].StockId)) ||
            (couObjList[0].UnitType == 'ORDU' && String.isNotBlank(couObjList[0].UnitId)))) {
            return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Duplicate stock number"}');   
        }
        
        unitRec.Account__c = customerId;
        unitRec = NewViewCustomerCtrl.setUnitStatusField(unitRec);
        
        if(!String.isBlank(unitRec.Id) && unitRec.Unit_Type__c != 'ORDU' && couObjList.size() > 0 && !couObjList[0].IsActive) {
            unitRec.Status__c = 'Inactive';
        } else if(!String.isBlank(unitRec.Id) && couObjList.size() > 0 && couObjList[0].IsActive && couObjList[0].Status == 'Inactive'){
        	if(unitRec.Unit_Type__c == 'COU') {
        		unitRec.Status__c = 'Active';
	        } else if(unitRec.Unit_Type__c == 'STOCK') {
	        	unitRec.Status__c = 'Available';
	        }
        }        
        if(couObjList[0].Make == null) {
        	List<Unit_Make__c> makeList = [Select Name from Unit_Make__c where Name =: couObjList[0].MakeName];
        	if(makeList.size() == 0) {
        		Unit_Make__c makeRec = new Unit_Make__c(Name = couObjList[0].MakeName);
        		insert makeRec;
        		unitRec.Unit_Make__c = makeRec.Id;
        	} else {
        		unitRec.Unit_Make__c = makeList[0].Id;
        	}
        }
        if(couObjList[0].Model == null) {
        	List<Unit_Model__c> modelList = [Select Name__c, Unit_Make__c from Unit_Model__c where Name__c =: couObjList[0].ModelName AND Unit_Make__c =: unitRec.Unit_Make__c];
        	if(modelList.size() == 0) {
        		Unit_Model__c modelRec = new Unit_Model__c(Name__c = couObjList[0].ModelName, Unit_Make__c = unitRec.Unit_Make__c);
	        	insert modelRec;
	        	unitRec.Unit_Model__c = modelRec.Id;
        	} else {
        		unitRec.Unit_Model__c = modelList[0].Id;
        	}
        }
        if(couObjList[0].SubModel == null && String.isNotBlank(couObjList[0].SubModelName)) {
        	List<Unit_Sub_Model__c> subModelList = [Select Sub_Model_Name__c, Unit_Model__c from Unit_Sub_Model__c where Sub_Model_Name__c =: couObjList[0].SubModelName AND Unit_Model__c =: unitRec.Unit_Model__c];
	    	if(subModelList.size() == 0) {
	    		Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c(Sub_Model_Name__c = couObjList[0].SubModelName, Unit_Model__c = unitRec.Unit_Model__c);
	        	insert subModelRec;
	        	unitRec.Sub_Model__c = subModelRec.Id;
	    	} else {
	    		unitRec.Sub_Model__c = subModelList[0].Id;
	    	}
        }
        if(unitRec.Id == null) {
        	Unit_Service.populateNotesByModelSubmodelDesc(unitRec);
        	if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        } else {
        	if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        }
        upsert unitRec;
        
        if(AccessControl.ifObjectFieldIsCreateable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

        if(unitRec.Unit_Type__c == 'STOCK' && (oldUnitList.size() == 0 || couObjList[0].TotalBasePrice > 0 || couObjList[0].TotalBaseCost > 0)) {
            Unit_Price_Cost__c unitPriceAndCost = new Unit_Price_Cost__c();
            unitPriceAndCost.Id = couObjList[0].BaseUnitId;
            if(!oldUnitList.isEmpty() && !oldUnitList[0].Unit_Prices_Costs__r.isEmpty()) {
                Decimal prevTotalBaseUnitPrice = oldUnitList[0].Total_Base_Unit_Price__c != null ? oldUnitList[0].Total_Base_Unit_Price__c : 0;
                Decimal newTotalBaseUnitPrice = couObjList[0].TotalBasePrice != null ? couObjList[0].TotalBasePrice : 0;
                Decimal currentUPCPrice = oldUnitList[0].Unit_Prices_Costs__r[0].Total_Price__c;
                unitPriceAndCost.Total_Price__c = (currentUPCPrice != null ? currentUPCPrice : 0) + (newTotalBaseUnitPrice - prevTotalBaseUnitPrice);
            } else {
                unitPriceAndCost.Total_Price__c = couObjList[0].TotalBasePrice;
                unitPriceAndCost.Total_Cost__c = couObjList[0].TotalBaseCost;
            }
            unitPriceAndCost.Type__c = 'Base';
            unitPriceAndCost.Item_Description__c = 'Base unit';    
            unitPriceAndCost.Customer_Owned_Unit__c = unitRec.Id;
            upsert unitPriceAndCost;
        }
      
        return getCOUListById(unitRec.Id);
    }
    
    private static String getErrorMessageForActivelyUsedUnit(String unitId) {
    	List<Customer_Owned_Unit__c> couList = [Select Id, Unit_Type__c, Total_Cost__c, (SELECT Id FROM Service_Order_Headers__r WHERE SO_Status__c NOT IN: ServiceJobUtil.invoiceableStatusSet AND SO_Status__c != 'Invoiced'),
    												(SELECT Id, Type__c FROM Deals_Units_Junction__r WHERE ((Deal__r.Status__c =: 'Quotation' OR Deal__r.Status__c =: 'In Progress') 
    												AND (Type__c =: Constants.DEAL_ITEM_TYPE_UNIT OR (Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN 
    												AND Is_Stocked_In__c = false))))
    												from Customer_Owned_Unit__c WHERE Id =: unitId AND (Unit_Type__c =: 'COU' OR Unit_Type__c =: 'STOCK')];
    	
    	String errorMessage = '';
    	if(couList.size() > 0) {
    		if(couList[0].Service_Order_Headers__r.size() > 0) {
    			errorMessage = 'Unit is currently in use on a service job';
    		} else if(couList[0].Deals_Units_Junction__r.size() > 0 && couList[0].Unit_Type__c == 'COU' && couList[0].Deals_Units_Junction__r[0].Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
				errorMessage = 'Unit is currently selected as a trade-in on a deal';
    		} else if(couList[0].Deals_Units_Junction__r.size() > 0 && couList[0].Unit_Type__c == 'STOCK' && couList[0].Deals_Units_Junction__r[0].Type__c == Constants.DEAL_ITEM_TYPE_UNIT) { 
    			errorMessage = 'Unit is being sold on a deal';
    		} else if(couList[0].Unit_Type__c == 'STOCK' && couList[0].Total_Cost__c != 0) {
    			errorMessage = 'Cost of this unit is not zero';
    		}
    	}
    	return errorMessage;
    }
    
    
   /* private static Customer_Owned_Unit__c setCOUnitFields(CustomerOwnedUnit unitInfoObj) {
		
		Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c();
    	couRec.VIN_Number__c = unitInfoObj.VIN;
    	couRec.Unit_Type__c = unitInfoObj.UnitType;
    	couRec.Year__c = unitInfoObj.Year;
    	couRec.Unit_Make__c = unitInfoObj.Make;
		couRec.Unit_Model__c = unitInfoObj.Model;
		couRec.Sub_Model__c = unitInfoObj.SubModel;
    	couRec.Colour__c = unitInfoObj.Color;
    	couRec.Plate__c = unitInfoObj.Plate;
    	couRec.Mileage_Value__c = unitInfoObj.Mileage;
    	couRec.Mileage_Type__c = unitInfoObj.MileageType;
    	couRec.Key_No__c = unitInfoObj.KeyNo;
    	couRec.Engine_Serial_No__c = unitInfoObj.EngineSerialNumber;
    	couRec.Other_Serial_No__c = unitInfoObj.OtherSerialNumber;
    	couRec.Interior_Colour__c = unitInfoObj.InteriorColour;
    	couRec.Taxable__c = unitInfoObj.IsTaxable;
    	if(couRec.Taxable__c) {
    		couRec.Applicable_Tax__c = unitInfoObj.ApplicableTaxId;
    	} else {
    		couRec.Applicable_Tax__c = null;
    	}
    	couRec.Cylinders__c = unitInfoObj.Cylinders;
    	couRec.Displacement__c = unitInfoObj.Displacement;
    	couRec.Automatic__c = unitInfoObj.IsAutomatic;
    	couRec.Gears__c = unitInfoObj.Gears;
    	couRec.Status__c = unitInfoObj.Status;
    	couRec.New_Unit__c = unitInfoObj.IsNewUnit;
    	couRec.Category__c = unitInfoObj.CategoryId;
    	couRec.Date_Stocked_In__c = unitInfoObj.DateIn;
    	couRec.Date_Stocked_Out__c = unitInfoObj.DateOut;
    	couRec.Location__c = unitInfoObj.Location;
    	
    	return couRec;
	}*/
	
	/**
     * Name: getCOUListById
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    private static String getCOUListById(String unitId) {
        List<Customer_Owned_Unit__c> COUList = SOQLUtil.getUnitByFieldName(new Map<String, String>{'Id' => unitId});
        List<Unit_Price_Cost__c> unitAdjustmentList = ViewUnitCtrl.getUnitAdjustmentList(unitId);
        
        List<CustomerOwnedUnit> couObjList = new List<CustomerOwnedUnit>();
        for(Customer_Owned_Unit__c couRec : COUList) {
            couObjList.add(new CustomerOwnedUnit(couRec, unitAdjustmentList));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(couObjList));
    }
    
    /**
     * Name: getCOURecordById
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCOURecordById(String couId) {
    	return NewViewCustomerCtrl.getCOURecordById(couId);
    }
    
    /**
     * Name: getCustomerContactByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCustomerContactByCustomerId(String customerId) {
    	customerId = BPUtility.getDecodedString(customerId);
    	
        List<Contact> customerContactList = SOQLUtil.getCustomerContactByFieldName('AccountId', customerId);
        List<CustomerContact> customerContactObjList = new List<CustomerContact>();
        for(Contact customerContactRec : customerContactList) {
            customerContactObjList.add(new CustomerContact(customerContactRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(customerContactObjList));
    }
    
    /**
     * Name: getCustomerContactById
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCustomerContactById(String customerContactId) {
        return NewViewCustomerCtrl.getCustomerContactById(customerContactId);
    }
    
    
    /**     
     * Name: updateCustomerContact
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String updateCustomerContact(String jsonString) {
    	jsonString = BPUtility.getDecodedString(jsonString);
    	
    	//system.assert(false, jsonString);
        List<CustomerContact> customerContactObjList = CustomerContact.parse(jsonString);
        
        List<Contact> customerContactListToInsert = new List<Contact>();
        for(CustomerContact customerContactObj : customerContactObjList) {
            Contact customerContactRec = new Contact(AccountId = customerContactObj.ParentCustomer);
            customerContactRec.LastName = customerContactObj.LastName;
    
            customerContactRec.Is_Contact__c = (customerContactObj.IsContact != null && customerContactObj.IsContact);
            if(customerContactRec.Is_Contact__c) {
                customerContactRec.Phone = customerContactObj.Phone;
                customerContactRec.Extension__c = customerContactObj.Extension;
                customerContactRec.Email = customerContactObj.Email;
            } else {
                customerContactRec.Phone = null;
                customerContactRec.Extension__c = null;
                customerContactRec.Email = null;
            }
            customerContactRec.Is_Shipping_Address__c = (customerContactObj.IsShippingAddress != null && customerContactObj.IsShippingAddress);
            if(customerContactRec.Is_Shipping_Address__c) {
                if(String.isBlank(customerContactObj.ShippingStreet1) && String.isNotBlank(customerContactObj.ShippingStreet2)) {
                    customerContactRec.MailingStreet = '\n' + customerContactObj.ShippingStreet2;
                } else if(String.isBlank(customerContactObj.ShippingStreet2) && String.isNotBlank(customerContactObj.ShippingStreet1)) {
                    customerContactRec.MailingStreet = customerContactObj.ShippingStreet1 + '\n';
                } else if(String.isNotBlank(customerContactObj.ShippingStreet1) && String.isNotBlank(customerContactObj.ShippingStreet2)) {
                    customerContactRec.MailingStreet = customerContactObj.ShippingStreet1 + '\n' + customerContactObj.ShippingStreet2;
                }
                customerContactRec.MailingCity = customerContactObj.ShippingCity;
                customerContactRec.MailingState = customerContactObj.ShippingState;
                customerContactRec.MailingPostalCode = customerContactObj.ShippingPostalCode;
                customerContactRec.MailingCountry = customerContactObj.ShippingCountry;
                customerContactRec.Mailing_County_Parish__c = customerContactObj.ShippingCountyParish;
            } else {
                customerContactRec.MailingStreet = customerContactRec.MailingCity = customerContactRec.MailingState = 
                customerContactRec.MailingPostalCode = customerContactRec.MailingCountry = customerContactRec.Mailing_County_Parish__c = null;
            }
            if(customerContactObj.Id != null) {
                customerContactRec.Id = customerContactObj.Id;
            }
            customerContactListToInsert.add(customerContactRec);
        }
        DMLUtility.upsertSobjectList('Contact', customerContactListToInsert);
        return BPUtility.getEncodedString(customerContactListToInsert[0].Id);
    }
    
    private static String getErrorMessageForSoldUnit() {
        String errorMessage = 'Unit is sold and can not be modified';
	    return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "'+errorMessage+'"}'); 
    }
    
    @remoteAction
    global static String getSimilarUnits(String unitJSONString) {
    	unitJSONString = BPUtility.getDecodedString(unitJSONString);
    	//system.assert(false, unitJSONString);
    	CustomerOwnedUnit unitObj = (CustomerOwnedUnit) System.JSON.deserialize(unitJSONString, CustomerOwnedUnit.class);
    	//system.assert(false, unitObj);
    	Customer_Owned_Unit__c unitRecordFilterValue = setUnitFields(unitObj);
    	List<Customer_Owned_Unit__c> unitList = SOQLUtil.getOtherSimilarActiveUnits(unitRecordFilterValue);
    	List<UnitSuggestion> unitSuggestionList = new List<UnitSuggestion>();
        List<Customer_Owned_Unit__c> oldUnitList = new List<Customer_Owned_Unit__c>();
        
        if(String.isNotBlank(unitObj.Id)) {
	        oldUnitList = [SELECT Name, Status__c, VIN_Number__c FROM Customer_Owned_Unit__c WHERE Id =: unitObj.Id];
	        if(oldUnitList.size() > 0) {
                if(oldUnitList[0].Status__c == 'Sold') {
                	return getErrorMessageForSoldUnit();
                } else if(oldUnitList[0].Status__c.equalsIgnoreCase('Reserved') && (String.isBlank(unitRecordFilterValue.VIN_Number__c) || unitRecordFilterValue.VIN_Number__c.equalsIgnoreCase('VIN Unknown')) && (String.isNotBlank(oldUnitList[0].VIN_Number__c) && !oldUnitList[0].VIN_Number__c.equalsIgnoreCase('VIN Unknown'))) {
	                return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Vin number can not be removed on reserved unit."}'); 
                }
	        }
        }

    	for(Customer_Owned_Unit__c unitRec : unitList) {
    		if(String.isNotBlank(unitRecordFilterValue.VIN_Number__c) && String.isNotBlank(unitRec.VIN_Number__c)
    			&& unitRec.VIN_Number__c == unitRecordFilterValue.VIN_Number__c) {
    				unitSuggestionList.add(new UnitSuggestion(unitRec, 1));
			
			} else if( String.isNotBlank(unitRecordFilterValue.VIN_Number__c) && String.isNotBlank(unitRec.VIN_Number__c) && 
					unitRec.VIN_Number__c.length() == 17 && unitRecordFilterValue.VIN_Number__c.length() == 17 && 
    				unitRec.VIN_Number__c.subString(11, 17)== unitRecordFilterValue.VIN_Number__c.subString(11, 17)) 
    			{
    				unitSuggestionList.add(new UnitSuggestion(unitRec, 4));
			
			} else if(String.isNotBlank(unitRecordFilterValue.Plate__c) && unitRec.Plate__c == unitRecordFilterValue.Plate__c) {
				unitSuggestionList.add(new UnitSuggestion(unitRec, 2));
    			
    		} else if(String.isNotBlank(unitRecordFilterValue.Engine_Serial_No__c) && unitRec.Engine_Serial_No__c == unitRecordFilterValue.Engine_Serial_No__c) {
    				unitSuggestionList.add(new UnitSuggestion(unitRec, 3));
    			
    		} else if(String.isNotBlank(unitRecordFilterValue.Other_Serial_No__c) && unitRec.Other_Serial_No__c == unitRecordFilterValue.Other_Serial_No__c) {
    				unitSuggestionList.add(new UnitSuggestion(unitRec, 5));
    		}
    	}
    	unitSuggestionList.sort();
		Integer listSizeLimit = 7;
        if(unitSuggestionList.size() > listSizeLimit) {
            List<UnitSuggestion> unitSuggestionLimitedList = new List<UnitSuggestion>();
            for(Integer i = 0 ; i < listSizeLimit ; i++) {
                unitSuggestionLimitedList.add(unitSuggestionList[i]);
            }
            unitSuggestionList = new List<UnitSuggestion>();
            unitSuggestionList.addAll(unitSuggestionLimitedList);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(unitSuggestionList));
    }
    
    private static Customer_Owned_Unit__c setUnitFields(CustomerOwnedUnit unitObj) {
    	Customer_Owned_Unit__c unitRecord = new Customer_Owned_Unit__c();
    	unitRecord.Other_Serial_No__c = unitObj.OtherSerialNo;
    	unitRecord.Engine_Serial_No__c = unitObj.EngineSerialNo;
    	unitRecord.Plate__c = unitObj.Plate;
    	unitRecord.VIN_Number__c = unitObj.VIN;
    	return unitRecord;
    }
     /**Ticket #1284 04/11/2016 Subhrant singh
     * Name: getMakeList
     * Desc: To get Make List
     * @param: 0
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction 
    global static String getMakeList() {
    	List<Unit_Make__c> unitMakeList = SOQLUtil.getUnitMake();
    	List<UnitMake> unitmakeItemList = new List<UnitMake>();
    	for(Unit_Make__c unitmakerec : unitMakeList  ){
    		UnitMake ObjMake = new UnitMake(unitmakerec);
    		unitmakeItemList.add(ObjMake );
    	}
    	return BPUtility.getEncodedString(System.JSON.serialize(unitmakeItemList));
    }
    
    /**Ticket #1284 04/11/2016 Subhrant singh
     * Name: getModelList   
     * Desc: To get Make List
     * @param: 0
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction 
    global static String getModelList(String MakeId) {
    	MakeId = BPUtility.getDecodedString(MakeId);
    	List<Unit_Model__c> unitModelList = SOQLUtil.getUnitModel(MakeId);
    	List<UnitModel> unitModelItemList = new List<UnitModel>();
    	Set<String> UnitModelKey = new Set<String>(); 
    	for(Unit_Model__c unitModelrec : unitModelList  ){
    		if(UnitModelKey.contains(unitModelrec.Name__c)){
    		
    		}else{
    			UnitModelKey.add(unitModelrec.Name__c);
    			UnitModel objUnitModel = new UnitModel(unitModelrec);
    			unitModelItemList.add(objUnitModel );
    		}  
    	}  
    	return BPUtility.getEncodedString(System.JSON.serialize(unitModelItemList));
    }
    
     /**
     * Name: getRelatedCustomerByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getSubModelList(String ModelName,String MakeId) {
    	ModelName = BPUtility.getDecodedString(ModelName);
    	MakeId = BPUtility.getDecodedString(MakeId);
    	List<Unit_Sub_Model__c> unitSubModelList = SOQLUtil.getUnitSubModel( ModelName, MakeId) ;
    	List<UnitSubModel> unitSubModelItemList = new List<UnitSubModel>();
    	for(Unit_Sub_Model__c unitSubModelrec : unitSubModelList  ){
			if(String.isNotBlank(unitSubModelrec.Sub_Model_Name__c)) {
                unitSubModelItemList.add(new UnitSubModel(unitSubModelrec));
    	    }
    	}  
    	return BPUtility.getEncodedString(System.JSON.serialize(unitSubModelItemList));
    }
    
     /**
     * Name: getDefaultStockUnitData  
     * Desc: Get default data for new Stock Unit records
     * @param:  N/A
     * @return: String - Stock Unit JSON String.
    **/
    @remoteAction
    global static String getDefaultUnitCategory() {
        try{
            List<Category__c> defaultUnitCategories = SOQLUtil.getDefaultCategoryRecords(new Map<String, String>{'Type__c' => 'Unit', 'Status__c' => 'Active'});
            if(defaultUnitCategories.size() > 0) {
                Category__c defaultCategory = defaultUnitCategories[0];
                Category newCategory = new Category(defaultCategory);  
                return BPUtility.getEncodedString(System.JSON.serialize(newCategory));
            }
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        
        return BPUtility.getEncodedString('{}');
    }
	
	@RemoteAction 
    global static String getVehicleSpecification(String vin) {
    	try {
            return BPUtility.getEncodedString(BRPAPIManager.getVehicleSpecification(BPUtility.getDecodedString(vin)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getAllUnitMakes() {
        try {
           return BPUtility.getEncodedString(MakeModelSubModelService.getAllUnitMakes());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getAllUnitModels() {
        try {
           return BPUtility.getEncodedString(MakeModelSubModelService.getAllUnitModels());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getAllUnitSubModels() {
        try {
           return BPUtility.getEncodedString(MakeModelSubModelService.getAllUnitSubModels());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getMakeModelSubmodelList() {
        try {
           return BPUtility.getEncodedString(MakeModelSubModelService.getMakeModelSubmodelList());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
	 
    @RemoteAction
    global static String transferUnitOwnership(String unitId, String customerId) {
    	return ViewUnitCtrl.transferUnitOwnership(unitId, customerId);
    }
    	
    @RemoteAction 
    global static String getUnitDataFieldsConfig() {
    	return BPUtility.getEncodedString(System.JSON.serialize(GeneralConfiguration.getUnitDataFieldsConfig()));
    }
    
    @RemoteAction
    global static Boolean isUnitActiveOnDeal(String unitId) {
    	unitId = BPUtility.getDecodedString(unitId);
    	List<Customer_Owned_Unit__c> unitList = [Select Id, Consignment__c, (Select Id from Deals_Units_Junction__r LIMIT 1) from Customer_Owned_Unit__c where Id =: unitId];
    	if(unitList.size() > 0 && unitList[0].Deals_Units_Junction__r.size() > 0) {
    		return true;
    	}
    	return false;
    }
    
    @RemoteAction
    global static String getUnitCategories() {
        return BPUtility.getEncodedString(System.JSON.serialize(getUnitCategories('Unit')));
    }

    @RemoteAction
    global static String getUnitProductTypes() {
        return BPUtility.getEncodedString(System.JSON.serialize(UnitProductTypeService.getUnitProductTypeList()));
    }
    
    @RemoteAction 
    global static String getUnitOptionalFieldsData(String productTypeId, String unitId) {
        return BPUtility.getEncodedString(System.JSON.serialize(UnitProductTypeService.getUnitOptionalFieldsData(BPUtility.getDecodedString(productTypeId), BPUtility.getDecodedString(unitId))));
    }

    @RemoteAction
    global static String getCustomerContactMasterData() {
        List<Country__c> countryList = SOQLUtil.getAllCountry();
        List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();
        
        COUFieldWrapper cOUFieldWrapperObj = new COUFieldWrapper(countryList, countryWrapperList, new List<Sales_Tax__c>(), 
        new List<Price_Level__c>(), new List<Unit_Make__c>(), new List<Unit_Make__c>(), new List<Category__c>());
        return BPUtility.getEncodedString(System.JSON.serialize(cOUFieldWrapperObj, true));
    }

    @RemoteAction
    global static String getVendorsList() {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitOrderingService.getVendorsList()));
    }

    @remoteAction
    global static String getDefaultFactoryOptionsByUnitId(String unitId, String makeId, String modelId, String subModelId) {
    	return BPUtility.getEncodedString(UnitPricingService.getDefaultFactoryOptionsByRecId(BPUtility.getDecodedString(unitId), 
    											BPUtility.getDecodedString(makeId), BPUtility.getDecodedString(modelId), BPUtility.getDecodedString(subModelId)));
    }

    @RemoteAction
    global static String savePriceAndCost(String unitId, String jSONString) {
        jSONString = BPUtility.getDecodedString(jSONString);
        UnitOrderingService.savePriceAndCost(BPUtility.getDecodedString(unitId), jSONString);
        return UnitOrderingCtrl.getUnitDetails(unitId);
    }

    @RemoteAction
    global static String removePriceAndCost(String unitId, String recordId) {
        recordId = BPUtility.getDecodedString(recordId);
        UnitOrderingService.removePriceAndCost(recordId);
        return UnitOrderingCtrl.getUnitDetails(unitId);
    }
    
    public static List<Category> getUnitCategories(String catType) {
    	List<Category> categories = new List<Category>();
    	List<Category__c> unitCategories = SOQLUtil.getCategories(new Map<String, String>{'Type__c' => catType});
        for(Category__c catRec : unitCategories) {
        	categories.add(new Category(catRec)); 
        }
        return categories;
    }

    @RemoteAction
    public static String getAllStampDutyList() {
        return BPUtility.getEncodedString(System.JSON.serialize(StampDutyService.getAllStampDutyList()));
    }

    @RemoteAction
    global static String getStampDutyCalcMethodPickListValues(){
        return BPUtility.getEncodedString(Utility.getPicklistValues('Stamp_duty_calculators__c.Calculation_method__c'));
    }
    
    @RemoteAction
    global static String updateStampDutyCalAndDutiableValue(String dealItemId, String stampDutyCalId, String dutiableValue, string tempUnitId) {
        return DealService.updateStampDutyCalAndDutiableValue(dealItemId, stampDutyCalId, dutiableValue, tempUnitId);
    }
}
/** 
* Author: Tarun Khandelwal
* Since: Aug 07, 2018 
* Name: COFormService 
* Description: Service class which contains all methods related to CO forms.
**/
public without sharing class COFormService {
    
    private static String AUTOMATICALLY_CREATED = 'Automatically Created';
    private static String MANUAL_UPLOAD = 'Manual Upload';
    
    public static void insertDefaultCOForms(String coHeaderId, String sectionId) {
        insertDefaultCOForms(coHeaderId, sectionId, null);
    }
    
    public static void insertDefaultCOForms(String coHeaderId, String sectionId, String vendorProductId) {
        String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
            return;
        }
        if(AccessControl.ifObjectFieldIsAccessible('Linked_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Linked_Form__c> linkedFormList;
        if(vendorProductId != null) {
            linkedFormList = [SELECT Form__c, Form__r.Name, Form__r.Description__c, Form__r.Is_Manual_Upload__c, Form__r.Is_Editable__c, Form__r.Form_Edit_Config__c, Form__r.Edit_Modal_Name__c, Vendor_Product__c from Linked_Form__c 
                                                WHERE Vendor_Product__c =: vendorProductId];
        } else {
            linkedFormList = [SELECT Form__c, Form__r.Name, Form__r.Description__c, Form__r.Is_Manual_Upload__c, Form__r.Is_Editable__c, Form__r.Form_Edit_Config__c, Form__r.Edit_Modal_Name__c, Vendor_Product__c from Linked_Form__c 
                                                WHERE Grouping_Name__c =: sectionName AND Vendor_Product__c = null];
        }
        
        if(linkedFormList.size() == 0) {
            return;
        }
        
        List<CO_Form__c> coFormList = new List<CO_Form__c>();
        for(Linked_Form__c linkedFormRec : linkedFormList) {
            CO_Form__c coFormRec = new CO_Form__c();
            coFormRec.CO_Header__c = coHeaderId;
            if(sectionName == 'Deal') {
                coFormRec.Deal__c = sectionId;
            } else if(sectionName == 'Financing') {
                coFormRec.Deal_Finance__c = sectionId;
            } else if(sectionName == 'Service') {
                coFormRec.Service_Order_Header__c = sectionId;
            }
            if(String.isNotBlank(vendorProductId)) {
                coFormRec.Vendor_Product__c = vendorProductId;
            }
            coFormRec.Form_Name__c = linkedFormRec.Form__r.Name;
            coFormRec.Description__c = linkedFormRec.Form__r.Description__c;
            coFormRec.Form__c = linkedFormRec.Form__c;
            coFormRec.Linked_Form__c = linkedFormRec.Id;
            coFormRec.Vendor_Product__c = linkedFormRec.Vendor_Product__c;
            coFormRec.Source__c = AUTOMATICALLY_CREATED;
            coFormRec.Is_Manually_Uploaded__c = linkedFormRec.Form__r.Is_Manual_Upload__c;
            coFormRec.Is_Editable__c = linkedFormRec.Form__r.Is_Editable__c;
            coFormRec.Form_Edit_Config__c = linkedFormRec.Form__r.Form_Edit_Config__c;
            coFormRec.Edit_Modal_Name__c = linkedFormRec.Form__r.Edit_Modal_Name__c;
            coFormList.add(coFormRec);
        }
        
        if(coFormList.size() > 0) {
            DMLUtility.insertSobjectList('CO_Form__c', coFormList);
            
            copyAttachmentForCOForm(coFormList);
        }
    }
    
    public static List<FormRepositoryWrapper> getActiveFormsBySectionId(String sectionId) {
    	String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
        	return new List<FormRepositoryWrapper>();
        }
    	List<Form__c> activeFormList = FormSOQLUtil.getAvailableActiveFormsBySectionId(sectionId, sectionName);
    	List<FormRepositoryWrapper> activeFormObjList = new List<FormRepositoryWrapper>();
    	for(Form__c activeFormRec: activeFormList) {
    		activeFormObjList.add(new FormRepositoryWrapper(activeFormRec));
    	}
        return activeFormObjList;
    }
    
    public static Map<Id, List<COFormWrapper>> getCOFormsBySectionId(String sectionId) {
    	String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
        	return new Map<Id, List<COFormWrapper>>();
        }
        List<Id> sectionIdList = getSectionIdListBasedonSectionName(sectionId, sectionName);
        List<CO_Form__c> coFormList = FormSOQLUtil.getCOFormsListById(sectionIdList);
        
        Set<Id> formIdSet = new Set<Id>();
        for(CO_Form__c coForm: coFormList) {
        	formIdSet.add(coForm.Form__c);
        }
        Map<Id, Form__c> formIdToRecordMap = new Map<Id, Form__c>([SELECT Is_Active__c FROM Form__c WHERE Id IN :formIdSet]);
        Map<Id, List<COFormWrapper>> sectionIdToCOFormListMap = populateSectionIdToCOFormListMap(sectionId, sectionName, coFormList, formIdToRecordMap);
       	return sectionIdToCOFormListMap;
   	}
   	
   	public static void addFormsToSection(String coHeaderId, String sectionId, String formJson) {
        String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
        	return;
        }
   		List<COFormWrapper> coFormObjList = (List<COFormWrapper>) System.JSON.deserialize(formJson, List<COFormWrapper>.class);
   		
   		List<CO_Form__c> coFormList = new List<CO_Form__c>();
   		for(COFormWrapper coFormObj: coFormObjList) {
   			CO_Form__c coFormRec = new CO_Form__c();
            coFormRec.CO_Header__c = coHeaderId;
            if(sectionName == 'Deal') {
                coFormRec.Deal__c = sectionId;
            } else if(sectionName == 'Financing') {
                coFormRec.Deal_Finance__c = sectionId;
            } else if(sectionName == 'Service') {
                coFormRec.Service_Order_Header__c = sectionId;
            }
            coFormRec.Form_Name__c = coFormObj.FormName;
            coFormRec.Description__c = coFormObj.Description;
            coFormRec.Form__c = coFormObj.Id;
            coFormRec.Source__c = MANUAL_UPLOAD;
            coFormRec.Is_Manually_Uploaded__c = coFormObj.IsManualUpload;
            coFormRec.Is_Editable__c = coFormObj.IsEditable;
            coFormRec.Form_Edit_Config__c = coFormObj.FormEditConfig;
            coFormRec.Edit_Modal_Name__c = coFormObj.EditModalName;
            coFormList.add(coFormRec);
   		}
   		
        if(coFormList.size() > 0) {
            DMLUtility.insertSobjectList('CO_Form__c', coFormList);
            
            copyAttachmentForCOForm(coFormList);
        }
        
   	}
   	
   	public static void deleteCOForm(String coFormId) {
    	if(AccessControl.ifObjectIsDeletable('CO_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    	CO_Form__c coFormRec = new CO_Form__c();
    	coFormRec.Id = coFormId;
    	delete coFormRec;
    }
    
    public static void deleteCOFormUsingSectionId(Set<Id> sectionIdSet) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Form__c> coFormList = [Select Id from CO_Form__c where Service_Order_Header__c IN: sectionIdSet OR Deal_Finance__c IN: sectionIdSet
                                        OR Deal__c IN: sectionIdSet];
        if(coFormList.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('CO_Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete coFormList;
        }
    }
    
    public static Map<String, Decimal> getActiveFormsCount() {
        if(AccessControl.ifObjectFieldIsAccessible('Form__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        AggregateResult[] groupedResults = [select Grouping_Name__c form, count(Id)
												from Form__c where Is_Active__c = true
												group by Grouping_Name__c];
		for(AggregateResult res : groupedResults){
			sectionNameToActiveFormsCountMap.put(String.valueOf(res.get('form')), Integer.valueOf(res.get('expr0')));
		}	
		return sectionNameToActiveFormsCountMap;
    }
   	
   	private static List<Id> getSectionIdListBasedonSectionName(String sectionId, String sectionName) {
   		List<Id> sectionIdList = new List<Id>();
   		if(sectionName == 'All') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        	List<CO_Header__c> coHeaderList = [SELECT Id, (SELECT Id FROM Service_Order_Headers__r), (SELECT Id FROM Deals__r) FROM CO_Header__c WHERE Id =: sectionId];
        	if(coHeaderList.size() > 0) {
	        	for(Service_Order_Header__c soHeaderRec : coHeaderList[0].Service_Order_Headers__r) {
	        		sectionIdList.add(soHeaderRec.Id);
	        	}
	        	if(coHeaderList[0].Deals__r.size() > 0) {
                    sectionIdList.add(coHeaderList[0].Deals__r[0].Id); // Assuming there is only one deal per CO Header
	        		List<Deal_Finance__c> dealFinanceList = [SELECT Id FROM Deal_Finance__c WHERE Deal__c =: coHeaderList[0].Deals__r[0].Id];
	        		if(dealFinanceList.size() > 0) {
		        		sectionIdList.add(dealFinanceList[0].Id);
		        	}
	        	}
        	}
        } else {
        	sectionIdList.add(sectionId);
        }
        return sectionIdList;
   	}
   	
   	private static Map<Id, List<COFormWrapper>> populateSectionIdToCOFormListMap(String sectionId, String sectionName, List<CO_Form__c> coFormList, Map<Id, Form__c> formIdToRecordMap) {
   		Map<Id, List<COFormWrapper>> sectionIdToCOFormListMap = new Map<Id, List<COFormWrapper>>();
   		Boolean isFormActive;
   		if(sectionName != 'All') {
        	List<COFormWrapper> coFormObjList = new List<COFormWrapper>();
    		for(CO_Form__c coFormRec : coFormList) {
    			isFormActive = false;
    			if(String.isNotBlank(coFormRec.Form__c)) {
    				isFormActive = formIdToRecordMap.get(coFormRec.Form__c).Is_Active__c;
    			}
	   			coFormObjList.add(new COFormWrapper(coFormRec, isFormActive));
	   		}
	   		sectionIdToCOFormListMap.put(sectionId, coFormObjList);
    	} else {
    		for(CO_Form__c coFormRec : coFormList) {
    			isFormActive = false;
    			if(String.isNotBlank(coFormRec.Form__c)) {
    				isFormActive = formIdToRecordMap.get(coFormRec.Form__c).Is_Active__c;
    			}
    			Id recId;
	   			if(String.isNotBlank(coFormRec.Service_Order_Header__c)) {
	   				recId = coFormRec.Service_Order_Header__c;
	   			} else if(String.isNotBlank(coFormRec.Deal__c)) {
	   				recId = coFormRec.Deal__c;
	   			} else if(String.isNotBlank(coFormRec.Deal_Finance__c)) {
	   				recId = coFormRec.Deal_Finance__c;
	   			}
	   			if(!sectionIdToCOFormListMap.containsKey(recId)) {
	   				sectionIdToCOFormListMap.put(recId, new List<COFormWrapper>{});
	   			}
   				sectionIdToCOFormListMap.get(recId).add(new COFormWrapper(coFormRec, isFormActive));
	   		}
    	}
   		return sectionIdToCOFormListMap;
   	}
   	
   	private static void copyAttachmentForCOForm(List<CO_Form__c> coFormList) {
   	    Map<Id, Id> formIdToCOFormIdMap = new Map<Id, Id>();
        for(CO_Form__c coFormRec: coFormList) {
            formIdToCOFormIdMap.put(coFormRec.Form__c, coFormRec.Id);
        }
        if(formIdToCOFormIdMap.size() > 0) {
            insertAttachmentsForForms(formIdToCOFormIdMap);
        }
   	}
   	
   	private static void insertAttachmentsForForms(Map<Id, Id> formIdToCOFormIdMap) {
   		if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
   		List<Attachment> atachmentList = [SELECT Name, ContentType, Body, ParentId FROM Attachment WHERE ParentId IN :formIdToCOFormIdMap.keySet()];
   		List<Attachment> attachmentListToInsert = new List<Attachment>();
   		for(Attachment attRec : atachmentList) {
   			attachmentListToInsert.add(new Attachment(Name = attRec.Name, Body = attRec.Body, ContentType = attRec.ContentType, ParentId = formIdToCOFormIdMap.get(attRec.ParentId)));
   		}
   		if(attachmentListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Attachment', attachmentListToInsert);
   		}
   	}
    
    private static Map<String, Integer> sectionNameToActiveFormsCountMap = new Map<String, Integer>{
    																'Deal' => 0,
    																'Financing' => 0, 
    																'Service' => 0
    													};
    													
	public static COFormConfigWrapper getFormJson(String recordId) {
		String soId = null;
		String coId = recordId;
		String objectName = (Id.valueOf(recordId)).getSObjectType().getDescribe().getName();
		if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
			List<Service_Order_Header__c> serviceOrderHeaderList = [SELECT CO_Header__c 
											   FROM Service_Order_Header__c 
											   WHERE id =: recordId];
			soId = recordId;
			coId = serviceOrderHeaderList[0].CO_Header__c;
		}

		COFormConfigWrapper formConfigObj = new COFormConfigWrapper();
		
        List<Business_Profile__c> businessProfileList = [SELECT Id, Formatted_Business_Number__c, Business_Email__c, Business_Name__c, Business_Postal_Code__c, Business_City__c, Business_State__r.Name__c, Business_Street_Address1__c, Business_Street_Address2__c FROM Business_Profile__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
		if(businessProfileList.size() > 0) {
			formConfigObj.setBusinessFields(businessProfileList[0]);
		}
		
		List<CO_Header__c> coHeaderList = [SELECT Id, Name, Customer__r.Name, Customer__r.BillingStreet, Customer__r.BillingCity, Customer__r.BillingState, Customer__r.ShippingStreet, Customer__r.ShippingCity, Customer__r.ShippingState, Customer__r.ShippingPostalCode, Customer__r.ShippingCountry,
			Customer__r.FirstName__c, Customer__r.LastName__c, Customer__r.Formatted_Mobile_Number__c, Customer__r.Email__c, Customer__r.Birth_Date__c, 
			Customer__r.BillingPostalCode, Customer__r.Formatted_Home_number__c, Customer__r.Type__c, Customer__r.Formatted_Work_Number__c, Customer__r.Drivers_License__c, CreatedDate__c,
			(SELECT Id, Invoice_Number__r.Invoice_Date__c, Delivery_Date__c, Type__c, CO_Header__c, Deal_Total__c, Amount_Financed__c, Down_Payment__c,  
      Invoice_Number__r.Invoice_Number__c, Salesperson_Name__c, Sales_Tax_Total__c FROM Deals__r Order BY Name ASC LIMIT 1),
			(SELECT SO_Concern__c, SO_Cause__c, SO_Correction__c, SO_Notes_For_Customer__c, Name, Invoice_Number__r.Invoice_Number__c, Customer_Owned_Unit__r.Unit_Make__r.Name, Customer_Owned_Unit__r.Unit_Model__r.Name__c, Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c, Customer_Owned_Unit__r.Year__c, Customer_Owned_Unit__r.VIN_Number__c, Customer_Owned_Unit__r.Mileage_Value__c, Odometer_on_Arrival__c, Odometer_on_Departure__c FROM Service_Order_Headers__r WHERE Id =: soId) 
			FROM CO_Header__c WHERE Id =: coId];
			
		if(coHeaderList.size() > 0) {
			formConfigObj.setCOFields(coHeaderList[0]);
			formConfigObj.setCustomerFields(coHeaderList[0].Customer__r);
			if(coHeaderList[0].Deals__r.size() > 0) {
				formConfigObj.setDealFields(coHeaderList[0].Deals__r[0]);
				setDealUnitFields(coHeaderList[0].Deals__r[0].Id, formConfigObj);
				setDealTradeInFields(coHeaderList[0].Deals__r[0].Id, formConfigObj);
				if(coHeaderList[0].Deals__r[0].Type__c == Constants.FINANCED) {
					setDealFinancingFields(coHeaderList[0].Deals__r[0].Id, formConfigObj);
				}
                setOtherDealRelatedFields(coHeaderList[0].Deals__r, formConfigObj);
    		    formConfigObj.dealCalculatedField();
			}
			if(coHeaderList[0].Service_Order_Headers__r.size() > 0) {
				List<Service_Order_Line_Item__c> soliList = [SELECT Item_Desc__c,Item_Code__c,Item_Description__c,Qty_Needed__c 
															 FROM Service_Order_Line_Item__c 
															 WHERE Service_Order_Header__c =: coHeaderList[0].Service_Order_Headers__r[0].Id];
				formConfigObj.setServiceFields(coHeaderList[0].Service_Order_Headers__r[0]);
				formConfigObj.setServiceSOLIFields(soliList);
			}
		}
		return formConfigObj;
	}
	
	private static void setDealUnitFields(String dealId, COFormConfigWrapper formConfigObj) {
		List<Deal_Item__c> unitList = [SELECT Id, Type__c, Unit_Make__r.Name, Unit_Model__r.Name__c, Year__c, Customer_Owned_Unit__r.Unit_Make__r.Name, 
						Deal__r.Sales_Tax_Total__c, Deal__r.Invoice_Number__r.Invoice_Date__c, Sub_Model__r.Sub_Model_Name__c, Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c, 
						Customer_Owned_Unit__r.Colour__c, Customer_Owned_Unit__r.Interior_Colour__c, Colour__c, Customer_Owned_Unit__r.Stock_Id__c, Customer_Owned_Unit__r.Mileage_Value__c, 
						Customer_Owned_Unit__r.Unit_Model__r.Name__c, Customer_Owned_Unit__r.Year__c, Customer_Owned_Unit__r.VIN_Number__c, Stamp_Duty_Total__c, 
						Customer_Owned_Unit__r.Reg_Expiry_Date__c, Customer_Owned_Unit__r.Year_Of_1st_Rego__c, Customer_Owned_Unit__r.Plate__c, Customer_Owned_Unit__r.Displacement__c , 
						Customer_Owned_Unit__r.Formatted_Name__c, Customer_Owned_Unit__r.Other_Serial_No__c, Customer_Owned_Unit__r.Engine_Serial_No__c,
						Customer_Owned_Unit__r.Unit_Data_01__c, Customer_Owned_Unit__r.Unit_Data_02__c, Customer_Owned_Unit__r.Unit_Data_03__c, Customer_Owned_Unit__r.Unit_Data_04__c, Customer_Owned_Unit__r.Unit_Data_05__c, Customer_Owned_Unit__r.Unit_Data_06__c, Customer_Owned_Unit__r.Unit_Data_07__c, Customer_Owned_Unit__r.Unit_Data_08__c, Customer_Owned_Unit__r.Unit_Data_11__c, Customer_Owned_Unit__r.Date_Stocked_In__c, Customer_Owned_Unit__r.Compliance_Date__c, Rideaway_Pricing_Total__c, Customer_Owned_Unit__r.Notes__c, Customer_Owned_Unit__r.Cylinders__c, Customer_Owned_Unit__r.Unit_Data_09__c, Customer_Owned_Unit__r.Unit_Data_10__c, Customer_Owned_Unit__r.Unit_Data_12__c,Customer_Owned_Unit__r.Unit_Data_13__c, Customer_Owned_Unit__r.Unit_Data_14__c, 
						 (SELECT Id, Type__c, Total_Price__c, Price__c, Qty__c, Sales_Tax_Percentage__c, Price_When_Tax_Included__c FROM Deal_Unit_Prices_Costs__r),
                         (SELECT Id, Fee__c, Fee__r.code__c, Fee__r.Description__c, Fee__r.Assigned_Tag_1__c, Fee__r.Assigned_Tag_2__c, Part__r.Assigned_Tag_1__c, Part__r.Assigned_Tag_2__c, Price__c, Sales_Tax_Percentage__c, Price_When_Tax_Included__c, Qty__c, 
                            Part__c, Labour_Code__c, Labour_Code__r.Name__c, Item_Description__c, Item_Code__c, Product__c, Product__r.Type__c, Product__r.Term__c, Product__r.Description__c, Product__r.Price__c FROM Options_Fees__r Order BY Name ASC) 
						 FROM Deal_Item__c WHERE Deal__c =: dealId AND Type__c =: Constants.DEAL_ITEM_TYPE_UNIT Order BY Name ASC];
		if(unitList.size() > 0) {		
			formConfigObj.setDealUnitFields(unitList[0]);
			formConfigObj.setAllDealUnitFields(unitList);
            formConfigObj.setFirstFiveOptionFeeAndPart(unitList);
			setUnitPreviousOwnerFields(unitList[0].Customer_Owned_Unit__r.VIN_Number__c , formConfigObj);
		}
    	if(unitList.size() > 1) {   
        	formConfigObj.setSecondDealUnitFields(unitList[1]);
    	}
	}
	
	private static void setDealTradeInFields(String dealId, COFormConfigWrapper formConfigObj) {
		List<Deal_Item__c> tradeInList = [SELECT Id, Agreed_Value__c, Unit_Make__r.Name, Unit_Model__r.Name__c,Year__c, Sub_Model__r.Sub_Model_Name__c, Colour__c, 
						Customer_Owned_Unit__r.Unit_Make__r.Name, Customer_Owned_Unit__r.Year__c, Customer_Owned_Unit__r.Colour__c, Finance_Company__r.Name, Finance_Company__r.BillingStreet, Finance_Company__r.BillingCity, Finance_Company__r.BillingState, Finance_Company__r.BillingPostalCode,	
						Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c, Customer_Owned_Unit__r.Unit_Model__r.Name__c, Lien_Payout__c, 
						Customer_Owned_Unit__r.VIN_Number__c, Customer_Owned_Unit__r.Mileage_Value__c, Customer_Owned_Unit__r.Displacement__c, 
						Customer_Owned_Unit__r.Formatted_Name__c, Customer_Owned_Unit__r.Other_Serial_No__c, Customer_Owned_Unit__r.Engine_Serial_No__c, 
                        Customer_Owned_Unit__r.Year_Of_1st_Rego__c, Customer_Owned_Unit__r.Reg_Expiry_Date__c, Customer_Owned_Unit__r.Plate__c, Customer_Owned_Unit__r.Unit_Data_01__c, Customer_Owned_Unit__r.Stock_ID__c, Default_Unit_Sales_Tax_Percentage__c FROM Deal_Item__c WHERE Deal__c =: dealId 
						AND Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN ORDER BY Name ASC];
		if(tradeInList.size() > 0) {		
			formConfigObj.setDealTradeInFields(tradeInList[0]);
			formConfigObj.setAllDealTradeInFields(tradeInList);
		}
	}
	
	private static void setDealFinancingFields(String dealId, COFormConfigWrapper formConfigObj) {
    List<Deal_Finance__c> dealFinanceList = [SELECT Id, Estimated_Payment__c, Loan_Term__c, Interest_Rate__c, Term_Type__c, Payment_Frequency__c, Deal_Total__c, Co_Buyer__r.Name,
		                      Co_Buyer__r.Type__c, Co_Buyer__r.FirstName__c, Co_Buyer__r.LastName__c, Co_Buyer__r.billingStreet,
							  Co_Buyer__r.BillingCity, Co_Buyer__r.BillingState, Co_Buyer__r.BillingPostalCode, (select id, Deal__c, Item_Description__c, Price__c, Vendor_Product__c, Vendor_Product__r.Description__c , Vendor_Product__r.Price__c, Vendor_Product__r.Term__c from F_I_Products__r),
							  Finance_Company__r.Name, Finance_Company__r.BillingStreet, Finance_Company__r.BillingCity, Finance_Company__r.BillingState, Finance_Company__r.BillingPostalCode, Co_Buyer__r.Drivers_License__c FROM Deal_Finance__c WHERE Deal__c =: dealId 
							ORDER BY Name ASC LIMIT 1];
		if(dealFinanceList.size() > 0) {		
			formConfigObj.setDealFinancingFields(dealFinanceList[0]);
			formConfigObj.setFIProductFields(dealFinanceList[0].F_I_Products__r);
		}
	}
	
    private static void setOtherDealRelatedFields(List<Deal__c> dealRecList, COFormConfigWrapper formConfigObj) {
        if(dealRecList != null && dealRecList.size() == 0) return;
        if(dealRecList[0] != null) {
			List<CO_Deposit__c> dealDepositList = new List<CO_Deposit__c>();
			List<CO_Invoice_Payment__c> dealInvPaymentList = new List<CO_Invoice_Payment__c>();
            if(dealRecList[0].Invoice_Number__c != null) {
				dealInvPaymentList = [Select Id, Payment_Method__c, Amount__c from CO_Invoice_Payment__c where 
                                                                CO_Invoice_Header__c =: dealRecList[0].Invoice_Number__c];
			} else {
                dealDepositList = [Select Id, Deal__c, Payment_Method__c, Amount__c from CO_Deposit__c where Deal__c =: dealRecList[0].Id];
				dealInvPaymentList = [Select Id, Payment_Method__c, Amount__c from CO_Invoice_Payment__c where 
                                                                CO_Invoice_Header__r.Status__c = 'Active' AND CO_Invoice_Header__r.CO_Header__c =: dealRecList[0].CO_Header__c];
			}
            formConfigObj.setOtherDealRelatedFields(dealRecList[0], dealDepositList, dealInvPaymentList);
		}
	}
	
	private static void setUnitPreviousOwnerFields(String unitVinNumber, COFormConfigWrapper formConfigObj) {
		List<Customer_Owned_Unit__c> similarUnits = new List<Customer_Owned_Unit__c>(); 
		if(String.isNotBlank(unitVinNumber)) {
			similarUnits = SOQLUtil.getUnitByFieldName(new Map<String, String>{'VIN_Number__c' => unitVinNumber, 'Unit_Type__c' => 'COU', 'Status__c' => 'Transferred'});
		}
		formConfigObj.setUnitPreviousOwnerFields(similarUnits);
	} 
}
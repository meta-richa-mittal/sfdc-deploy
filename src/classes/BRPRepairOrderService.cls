/**
 * Author: Nidhi Sharma
 * Since: June 22, 2020
 * Name: BRPRepairOrderService
 * Description: Service class for BRP repair order xml creation
**/
public without sharing class BRPRepairOrderService {
    
    public static String methodType = 'ProcessRepairOrder';
    public static DateTime repairOrderCreationDate;
        
    public static String createRequestBody(Account accRec, List<Service_Order_Header__c> soHeaderList, 
    												Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap) {
    	return createXMLPayload(accRec, soHeaderList, soIdToIndividualTaxListMap);
    }
       
    public static String createXMLPayload(Account accRec, List<Service_Order_Header__c> soHeaderList, Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap) {
    	DOM.Document doc = new DOM.Document();
    	if(soHeaderList.size() > 0) {
    		repairOrderCreationDate = soHeaderList[0].CreatedDate;
    	}
    	dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, methodType);
    	
        createProcessRepairOrderDataAreaNode(root, accRec, soHeaderList, soIdToIndividualTaxListMap);
        
        return doc.toXmlString();
    }
    
    public static void createProcessRepairOrderDataAreaNode(dom.XmlNode root, Account accRec, List<Service_Order_Header__c> soHeaderList, 
    													Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap) {
        dom.XmlNode processRepairOrderDataArea = BRPUtility.addChildElement(root, 'ProcessRepairOrderDataArea');
        dom.XmlNode processNode = BRPUtility.addChildElement(processRepairOrderDataArea, 'Process');
        for(Integer i = 0; i < soHeaderList.size(); i++) {
        	String operationId = 'Service Job' + (i + 1); 
        	
        	List<Individual_Tax__c> individualTaxList = soIdToIndividualTaxListMap.containsKey(soHeaderList[i].Id) ? soIdToIndividualTaxListMap.get(soHeaderList[i].Id) :
        							new List<Individual_Tax__c>();
        	createRepairOrderNode(processRepairOrderDataArea, accRec, operationId, soHeaderList[i], individualTaxList);
        }
    }
    
    public static void createRepairOrderNode(dom.XmlNode processRepairOrderDataAreaNode, Account accRec, String operationId, Service_Order_Header__c soHeaderRec, 
    																	List<Individual_Tax__c> individualTaxList) {
    	dom.XmlNode repairOrder = BRPUtility.addChildElement(processRepairOrderDataAreaNode, 'RepairOrder');
    	createRepairOrderHeaderNode(repairOrder, accRec, soHeaderRec, individualTaxList);
    	createJobNode(repairOrder, accRec, operationId, soHeaderRec, individualTaxList);
    }
    
    public static void createRepairOrderHeaderNode(dom.XmlNode repairOrderNode, Account accRec, Service_Order_Header__c soHeaderRec, 
    															List<Individual_Tax__c> individualTaxList) {
    	dom.XmlNode repairOrderHeaderNode = BRPUtility.addChildElement(repairOrderNode, 'RepairOrderHeader');
    	BRPUtility.addChildElementWithValue(repairOrderHeaderNode, 'DocumentDateTime', soHeaderRec.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'));
    	
    	createDocumentIdentificationGroupNode(repairOrderHeaderNode);
    	//Owner Party Node
    	if(accRec != null) {
    		BRPUtility.createCustomerNode(repairOrderHeaderNode, 'OwnerParty', accRec);
    	} else if(String.isNotBlank(soHeaderRec.CO_Header__r.CO_Type__c) && 
    			(soHeaderRec.CO_Header__r.CO_Type__c == Constants.CASH_SALE || soHeaderRec.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE)) {
    		BRPUtility.createCustomerNodeForNonCustomerCO(repairOrderHeaderNode, 'OwnerParty', soHeaderRec.CO_Header__r.CO_Type__c);
    	}
    	createRepairOrderVehicleLINode(repairOrderHeaderNode, soHeaderRec);
    	
    	BRPUtility.addChildElementWithValue(repairOrderHeaderNode, 'RepairOrderOpenedDate', soHeaderRec.CreatedDate.format('yyyy-MM-dd'));
    	BRPUtility.addChildElementWithValue(repairOrderHeaderNode, 'RepairOrderCompletedDate', soHeaderRec.Invoice_Number__r.Invoice_Date__c.format('yyyy-MM-dd'));
    	
    	BRPUtility.addChildElementWithValue(repairOrderHeaderNode, 'OrderInternalNotes', 'Initial');
    	
    	createPriceNode(repairOrderHeaderNode, soHeaderRec);
    	BRPUtility.createTaxNode(repairOrderHeaderNode, individualTaxList);
    	createSplitsNode(repairOrderHeaderNode, soHeaderRec);
    	BRPUtility.addChildElementWithValue(repairOrderHeaderNode, 'CustomerAppointmentNumber', soHeaderRec.Invoice_Number__r.Invoice_Number__c);
    }
    
    public static void createJobNode(dom.XmlNode repairOrder, Account accRec, String operationId, Service_Order_Header__c soHeaderRec, 
    															List<Individual_Tax__c> individualTaxList) {
    	dom.XmlNode jobNode = BRPUtility.addChildElement(repairOrder, 'Job');
    	BRPUtility.addChildElementWithValue(jobNode, 'JobNumberString', soHeaderRec.CO_Header__r.Name + '-' + OperationId);
    	BRPUtility.addChildElementWithValue(jobNode, 'OperationID', operationId);
    	BRPUtility.addChildElementWithValue(jobNode, 'OperationName', soHeaderRec.Name__c);
    	
    	dom.XmlNode codesAndCommentsExpandedNode = BRPUtility.addChildElement(jobNode, 'CodesAndCommentsExpanded');
    	String miscNotes = ((soHeaderRec.SO_Cause__c != null ? soHeaderRec.SO_Cause__c + ' ' : '') +
    					(soHeaderRec.SO_Concern__c != null ? soHeaderRec.SO_Concern__c + ' ' : '') +
    					(soHeaderRec.SO_Correction__c != null ? soHeaderRec.SO_Correction__c : ''));
    	miscNotes = miscNotes.length() > 8000 ? miscNotes.subString(0, 8000) : miscNotes;
    	BRPUtility.addChildElementWithValue(codesAndCommentsExpandedNode, 'MiscellaneousNotes', miscNotes);
    	Decimal totalBilledHrs = 0;
    	
    	Set<Decimal> laborPriceSet = new Set<Decimal>();
    	for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
    		if(soliRec.Part__c != null) {
    			createServicePartNode(jobNode, soliRec);
    		} else if(soliRec.Labour_Code__c != null) {
    			totalBilledHrs += soliRec.Qty_Needed__c != null ? soliRec.Qty_Needed__c : 0; 
    			createServiceLaborNode(jobNode, soliRec);
    			
    			if(soliRec.Kit_Price__c != null) {
    				laborPriceSet.add((soliRec.Kit_Price__c).setScale(2, RoundingMode.HALF_UP));
    			}
    		}
    	}
    	
    	if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party') {
    		String claimNumber = soHeaderRec.Claims__r.size() > 0 ? soHeaderRec.Claims__r[0].Claim_Number__c : '';
	    	dom.XmlNode warrantyClaimNode = BRPUtility.addChildElement(jobNode, 'WarrantyClaim');
	    	BRPUtility.addChildElementWithValue(warrantyClaimNode, 'ClaimNumberString', claimNumber);
    	}
    	
    	dom.XmlNode pricingNode = BRPUtility.addChildElement(jobNode, 'Pricing');
    	for(Decimal laborPrice : laborPriceSet) {
    		BRPUtility.createPricingNode(pricingNode, 'Sold', null, laborPrice);
    	}
    	
    	String technicianNames = '';
    	for(Technician_Hour__c techHrRec : soHeaderRec.Technician_Hours__r) {
    		if(String.isNotBlank(techHrRec.Technician__r.Technician_Name__c)) {
    			technicianNames += techHrRec.Technician__r.Technician_Name__c + ',';
    		}
    	}
    	technicianNames = technicianNames.length() > 0 ? technicianNames.subString(0, technicianNames.length() - 1) : technicianNames;
    	
    	BRPUtility.addChildElementWithValue(jobNode, 'LaborActualHoursNumeric', String.valueOf(totalBilledHrs));
    	BRPUtility.addChildElementWithValue(jobNode, 'ServiceTechnicianParty', technicianNames);
    	
    	String billToPartyType = 'customer';
    	if(soHeaderRec.Transaction_Type__r.Type__c == 'Internal' || soHeaderRec.Transaction_Type__r.Type__c == 'Stock Unit') {
    		billToPartyType = 'dealer';
    	} else if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party') {
    		billToPartyType = 'manufacturer';
    	}
    	BRPUtility.addChildElementWithValue(jobNode, 'BillToPartyType', billToPartyType);
    }
    public static void createDocumentIdentificationGroupNode(dom.XmlNode repairOrderHeaderNode) {
    	dom.XmlNode docIdentificationGroup = BRPUtility.addChildElement(repairOrderHeaderNode, 'DocumentIdentificationGroup');
    	dom.XmlNode docIdentification = BRPUtility.addChildElement(docIdentificationGroup, 'DocumentIdentification');
    	BRPUtility.addChildElementWithValue(docIdentification, 'DocumentID', methodType);
    	BRPUtility.addChildElementWithValue(docIdentification, 'AgencyRoleCode', 'Dealer');
    }
    
    public static void createRepairOrderVehicleLINode(dom.XmlNode repairOrderHeader, Service_Order_Header__c soRec) {
    	dom.XmlNode repairOrderVehicleLI = BRPUtility.addChildElement(repairOrderHeader, 'RepairOrderVehicleLineItem');
    	dom.XmlNode vehicle = BRPUtility.addChildElement(repairOrderVehicleLI, 'Vehicle');
    	BRPUtility.addChildElementWithValue(vehicle, 'VehicleID', soRec.Customer_Owned_Unit__r.VIN_Number__c);
    	
    	if(soRec.Customer_Owned_Unit__r.Mileage_Type__c != null) {
	    	String odometerOut = soRec.Odometer_on_Departure__c != null ? String.valueOf(soRec.Odometer_on_Departure__c.round(System.RoundingMode.UP)) : '';
	    	if(soRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || soRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
	    		String mileageTypeValue = (soRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? 'kilometer' : 'mile';
	    		BRPUtility.addChildElementWithAttribute(repairOrderVehicleLI, 'NewOdometerDistanceMeasure', odometerOut, 'UnitCode', mileageTypeValue);
	    	} else {
	    		BRPUtility.addChildElementWithAttribute(repairOrderVehicleLI, 'NewOdometerTimeMeasure', odometerOut, 'UnitCode', 'hour');
	    	}
    	}
    }
    
    public static void createPriceNode(dom.XmlNode repairOrderHeader, Service_Order_Header__c soRec) {
    	dom.XmlNode priceNode = BRPUtility.addChildElement(repairOrderHeader, 'Price');
    	BRPUtility.addChildElementWithValue(priceNode, 'PriceCode', 'Sold');
    	BRPUtility.addChildElementWithAttribute(priceNode, 'ChargeAmount', String.valueOf(soRec.Total__c), 'currencyID', BRPUtility.CurrencyCode);
    }
    
    public static void createSplitsNode(dom.XmlNode repairOrderHeader, Service_Order_Header__c soRec) {
    	dom.XmlNode splitsNode = BRPUtility.addChildElement(repairOrderHeader, 'Splits');
    	
    	BRPUtility.addChildElementWithValue(splitsNode, 'SplitsTypeCode', 'Total');
    	
    	dom.XmlNode pricingNode = BRPUtility.addChildElement(splitsNode, 'Pricing');
    	BRPUtility.createPricingNode(pricingNode, 'Sold', null, soRec.Total__c);
    	
    	String customerPercent = (soRec.Transaction_Type__r.Type__c == 'Customer') ? '1.00000000' : '0.00000000';
    	String internalPercent = (soRec.Transaction_Type__r.Type__c == 'Internal' || soRec.Transaction_Type__r.Type__c == 'Stock Unit') ? '1.00000000' : '0.00000000';
    	String warrantyPercent = (soRec.Transaction_Type__r.Type__c == 'Third-Party') ? '1.00000000' : '0.00000000';
    	BRPUtility.addChildElementWithValue(splitsNode, 'CustomerPercent', customerPercent);
    	BRPUtility.addChildElementWithValue(splitsNode, 'InternalPercent', internalPercent);
    	BRPUtility.addChildElementWithValue(splitsNode, 'WarrantyPercent', warrantyPercent);
    }
    
    public static void createServicePartNode(dom.XmlNode jobNode, Service_Order_Line_Item__c soliRec) {
    	dom.XmlNode servicePartsNode = BRPUtility.addChildElement(jobNode, 'ServiceParts');
    	
    	BRPUtility.addChildElementWithValue(servicePartsNode, 'ItemIdDescription', soliRec.Part__r.Description__c);
    	BRPUtility.addChildElementWithAttribute(servicePartsNode, 'ItemQuantity', String.valueOf(soliRec.Qty_Needed__c), 'unitCode', 'ea');
    	
    	dom.XmlNode pricingNode = BRPUtility.addChildElement(servicePartsNode, 'Pricing');
    	BRPUtility.createPricingNode(pricingNode, 'Sold', null, soliRec.Kit_Price__c);
    	BRPUtility.createPricingNode(pricingNode, 'Suggested Retail', null, soliRec.Retail_Price__c);
    	
    	Decimal cost = (soliRec.CO_Line_Item__r.Adjusted_Cost_Coli__c != null && soliRec.CO_Line_Item__r.Qty__c != null && soliRec.CO_Line_Item__r.Qty__c != 0) 
    						? (soliRec.CO_Line_Item__r.Adjusted_Cost_Coli__c/soliRec.CO_Line_Item__r.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0;
    	BRPUtility.createPricingNode(pricingNode, 'Cost', 'FIFO', cost);
    	
    	dom.XmlNode itemIdentificationGroupNode = BRPUtility.addChildElement(servicePartsNode, 'ItemIdentificationGroup');
    	dom.XmlNode itemIdentificationNode = BRPUtility.addChildElement(itemIdentificationGroupNode, 'ItemIdentification');
    	BRPUtility.addChildElementWithValue(itemIdentificationNode, 'ItemID', soliRec.Part__r.Part_Number__c);
    }
    
    public static void createServiceLaborNode(dom.XmlNode jobNode, Service_Order_Line_Item__c soliRec) {
    	dom.XmlNode serviceLaborNode = BRPUtility.addChildElement(jobNode, 'ServiceLabor');
    	
    	soliRec.Qty_Needed__c = soliRec.Qty_Needed__c != null ? soliRec.Qty_Needed__c : 0;
    	soliRec.Kit_Price__c = soliRec.Kit_Price__c != null ? soliRec.Kit_Price__c : 0;
    	Decimal perItemCost = (soliRec.Total_Cost__c != null && soliRec.Qty_Needed__c != 0) ? 
    									(soliRec.Total_Cost__c / soliRec.Qty_Needed__c).setScale(2, RoundingMode.HALF_UP): 0;
    	
    	BRPUtility.addChildElementWithAttribute(serviceLaborNode, 'LaborRateAmount', String.valueOf(soliRec.Kit_Price__c), 'currencyID', BRPUtility.CurrencyCode);
    	
    	dom.XmlNode pricingNode = BRPUtility.addChildElement(serviceLaborNode, 'Pricing');
    	BRPUtility.createPricingNode(pricingNode, 'Sold', null, soliRec.Kit_Price__c);
    	BRPUtility.createPricingNode(pricingNode, 'Suggested Retail', null, soliRec.Retail_Price__c);
    	BRPUtility.createPricingNode(pricingNode, 'Cost', null, perItemCost);
    	
    	BRPUtility.addChildElementWithValue(serviceLaborNode, 'LaborActualHoursNumeric', String.valueOf(soliRec.Qty_Needed__c));
    }
    
    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'COInvoiceHeader'       => new Set<String>{ 
        									'Id',
                                            'CO_Header__r.Customer__c'
                                            },
        
        'SoHeader'            => new Set<String>{ 
        										'Name__c',
        										'SO_Cause__c',
        										'SO_Concern__c',
        										'SO_Correction__c',
        										'Odometer_on_Departure__c',
        										'Customer_Owned_Unit__r.VIN_Number__c',
        										'Customer_Owned_Unit__r.Mileage_Type__c',
        										'Total__c',
        										'Tax_Amount__c',
        										'Transaction_Type__r.Type__c',
        										'CreatedDate',
        										'Invoice_Number__r.Invoice_Date__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.CO_Type__c',
                                                'Total_Labour_Cost__c',
                                                'Total_Fee_Cost__c',
                                                'Total_Labour_Cost__c',
                                                'Total_Shop_Supplies_Cost__c',
                                                'Total_Related_Sublet_Cost__c'
                                },
        'SOLI'            => new Set<String>{ 
        										'Service_Order_Header__c',
                                                'Qty_Needed__c',
                                                'Kit_Price__c',
                                                'Retail_Price__c',
                                                'Total_Cost__c',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Description__c',
                                                'Sublet__c',
                                                'Labour_Code__c',
                                                'CO_Line_Item__r.Adjusted_Cost_Coli__c',
                                                'CO_Line_Item__r.Qty__c'
                                },
       'TechnicianHour'			=> new Set<String> {
										     'Technician__r.Technician_Name__c'
					       		},
       'IndividualTax'            => new Set<String>{ 
       											'Tax_Amount__c',
                                                'Tax_Rate__c',
                                                'Taxable_Amount__c',
                                                'Service_Order_Line_Item__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c',
												'Sales_Tax_Item__r.Name__c'
                                }
    };
}
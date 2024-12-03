/** 
* Author: Manoj Sharma
* Since: June 25, 2020 
* Name: BRPRetailDeliveryReportingService 
* Description: Apex service class to send unit data on BRP.
**/
public without sharing class BRPRetailDeliveryReportingService {
    public static String methodType = 'ProcessRetailDeliveryReporting';
        
    public static String createRequestBody(List<Deal__c> dealList) {
    	return createXMLPayload(dealList);
    }
       
    public static String createXMLPayload(List<Deal__c> dealList) {
    	DOM.Document doc = new DOM.Document();
    	dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, methodType);
        createProcessRetailDeliveryReportingDataAreaNode(root, dealList);
        
        return doc.toXmlString();
    }
    
    public static void createProcessRetailDeliveryReportingDataAreaNode(dom.XmlNode root, List<Deal__c> dealList) {
        dom.XmlNode processRetailDeliveryReportingDataArea = BRPUtility.addChildElement(root, 'ProcessRetailDeliveryReportingDataArea');
        dom.XmlNode processNode = BRPUtility.addChildElement(processRetailDeliveryReportingDataArea, 'Process');
        for(Deal__c dealRec : dealList) {
        	createRetailDeliveryReportingNode(processRetailDeliveryReportingDataArea, dealRec);//TODO
        }
    }
    
    public static void createRetailDeliveryReportingNode(dom.XmlNode processRetailDeliveryReportingDataArea, Deal__c dealRec) {
    	dom.XmlNode retailDeliveryReporting = BRPUtility.addChildElement(processRetailDeliveryReportingDataArea, 'RetailDeliveryReporting');
		createRetailDeliveryReportingHeaderNode(retailDeliveryReporting, dealRec);
		for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
			if(dealItemRec.Type__c != 'Trade In') {
				createRetailDeliveryReportingVehicleLineItemNode(retailDeliveryReporting, dealItemRec, dealRec);
			}
		}
    }
    
    public static void createRetailDeliveryReportingHeaderNode(dom.XmlNode retailDeliveryReporting, Deal__c dealRec) {
        dom.XmlNode retailDeliveryReportingHeader = BRPUtility.addChildElement(retailDeliveryReporting, 'RetailDeliveryReportingHeader');
        BRPUtility.addChildElementWithValue(retailDeliveryReportingHeader, 'DocumentDateTime', dealRec.Invoice_Number__r.Invoice_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'));
        createDocumentIdentificationGroupNode(retailDeliveryReportingHeader);
		BRPUtility.addChildElementWithValue(retailDeliveryReportingHeader, 'SalesDate', String.valueOf((dealRec.Invoice_Number__r.Invoice_Date__c).format('yyyy-MM-dd')));
		BRPUtility.addChildElementWithValue(retailDeliveryReportingHeader, 'SaleCategoryString', 'Initial');
		BRPUtility.addChildElementWithValue(retailDeliveryReportingHeader, 'SaleSubCategoryString', dealRec.Invoice_Number__r.Invoice_Number__c);
		createPartyNode(retailDeliveryReportingHeader, dealRec.CO_Header__r.Customer__r, false); // To create buyer party node
		if(dealRec.Co_Buyer__c != null ) {
			createPartyNode(retailDeliveryReportingHeader, dealRec.Co_Buyer__r, true);
		}
		
		createSoldFinanceNode(retailDeliveryReportingHeader, dealRec);
		for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
			if(dealItemRec.Type__c == 'Trade In') {
				createTradeInVehicleCreditNode(retailDeliveryReportingHeader, dealItemRec);
			}
		}
    }
    
    public static void createRetailDeliveryReportingVehicleLineItemNode(dom.XmlNode retailDeliveryReporting, Deal_Item__c dealItemRec, Deal__c dealRec) {

    	dom.XmlNode retailDeliveryReportingVehicleLineItem = BRPUtility.addChildElement(retailDeliveryReporting, 'RetailDeliveryReportingVehicleLineItem');
		dom.XmlNode vehicle = BRPUtility.addChildElement(retailDeliveryReportingVehicleLineItem, 'Vehicle');
		if(dealItemRec.Customer_Owned_Unit__r.New_Unit__c) {
			BRPUtility.addChildElementWithValue(vehicle, 'SaleClassCode', 'New');
		} else {
			BRPUtility.addChildElementWithValue(vehicle, 'SaleClassCode', 'Used');
		}
		BRPUtility.addChildElementWithValue(vehicle, 'VehicleID', dealItemRec.Customer_Owned_Unit__r.VIN_Number_Formula__c);
		Decimal MileageValue = dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c != null ? dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c : 0;
		Integer migeageValueInt = Integer.valueOf(MileageValue.setScale(0, RoundingMode.CEILING));
		
		if(dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
			String mileageTypeValue = (dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? 'kilometer' : 'mile';
			BRPUtility.addChildElementWithAttribute(retailDeliveryReportingVehicleLineItem, 'DeliveryDistanceMeasure', String.valueOf(migeageValueInt), 'UnitCode', mileageTypeValue);
		} else {
			BRPUtility.addChildElementWithAttribute(retailDeliveryReportingVehicleLineItem, 'DeliveryDistanceMeasure', String.valueOf(migeageValueInt), 'UnitCode', 'hour');
		}	
		BRPUtility.addChildElementWithValue(retailDeliveryReportingVehicleLineItem, 'VehicleStockString',dealItemRec.Customer_Owned_Unit__r.Stock_Id__c);

		dom.XmlNode salesPersonParty = BRPUtility.addChildElement(retailDeliveryReportingVehicleLineItem, 'SalesPersonParty');
		dom.XmlNode specifiedPerson = BRPUtility.addChildElement(salesPersonParty, 'SpecifiedPerson');
		BRPUtility.addChildElementWithValue(specifiedPerson, 'FamilyName', dealRec.Salesperson_Name__c);

		dom.XmlNode pricing = BRPUtility.addChildElement(retailDeliveryReportingVehicleLineItem, 'Pricing');
		dom.XmlNode price = BRPUtility.addChildElement(pricing, 'Price');
		BRPUtility.addChildElementWithValue(price, 'PriceCode', 'Sold');
		BRPUtility.addChildElementWithAttribute(price, 'ChargeAmount', String.valueOf(dealItemRec.Customer_Owned_Unit__r.Total_Price__c != null ? dealItemRec.Customer_Owned_Unit__r.Total_Price__c : 0.00), 'currencyID', BRPUtility.CurrencyCode);

		dom.XmlNode dealerCostPrice = BRPUtility.addChildElement(retailDeliveryReportingVehicleLineItem, 'DealerCostPrice');
		BRPUtility.addChildElementWithValue(dealerCostPrice, 'PriceCode', 'Sold');
		BRPUtility.addChildElementWithAttribute(dealerCostPrice, 'ChargeAmount', String.valueOf(dealItemRec.Customer_Owned_Unit__r.Total_Cost__c != null ? dealItemRec.Customer_Owned_Unit__r.Total_Cost__c : 0.00), 'currencyID', BRPUtility.CurrencyCode);

    }
    
    public static void createDocumentIdentificationGroupNode(dom.XmlNode retailDeliveryReportingHeader) {
    	dom.XmlNode docIdentificationGroup = BRPUtility.addChildElement(retailDeliveryReportingHeader, 'DocumentIdentificationGroup');
    	dom.XmlNode docIdentification = BRPUtility.addChildElement(docIdentificationGroup, 'DocumentIdentification');
    	BRPUtility.addChildElementWithValue(docIdentification, 'DocumentID', 'ProcessRetailDeliveryReporting');
    	BRPUtility.addChildElementWithValue(docIdentification, 'AgencyRoleCode', 'Dealer');
    }
    
    public static void createPartyNode(dom.XmlNode retailDeliveryReportingHeader, Account customerRec, Boolean isCoBuyer) {
		dom.XmlNode specifiedParty;
		if(isCoBuyer) {
			specifiedParty = BRPUtility.addChildElement(retailDeliveryReportingHeader, 'Co-BuyerParty');
		} else {
			specifiedParty = BRPUtility.addChildElement(retailDeliveryReportingHeader, 'BuyerParty');
		}
    	dom.XmlNode specifiedEntity;
    	if(String.isNotBlank(customerRec.Type__c) && customerRec.Type__c == 'Business') {
    		
    		specifiedEntity = BRPUtility.addChildElement(specifiedParty, 'SpecifiedOrganization');
    		BRPUtility.addChildElementWithValue(specifiedEntity, 'CompanyName', customerRec.Name);
    		
    		dom.XmlNode primaryContact = BRPUtility.addChildElement(specifiedEntity, 'PrimaryContact');
    		BRPUtility.addChildElementWithValue(primaryContact, 'TypeCode', 'Company Contact');
    		
    		dom.XmlNode specifiedPerson = BRPUtility.addChildElement(specifiedEntity, 'SpecifiedPerson');
    		BRPUtility.addChildElementWithValue(specifiedPerson, 'FamilyName', customerRec.Name);
    		
    		BRPUtility.createTelephoneCommunicationNode(specifiedEntity, customerRec);
    		BRPUtility.createURICommunicationNode(specifiedEntity, customerRec);
    		
    	} else {
    		specifiedEntity = BRPUtility.addChildElement(specifiedParty, 'SpecifiedPerson');
    		BRPUtility.addChildElementWithValue(specifiedEntity, 'GivenName', customerRec.FirstName__c);
    		BRPUtility.addChildElementWithValue(specifiedEntity, 'FamilyName', customerRec.LastName__c);
    		
    		BRPUtility.createTelephoneCommunicationNode(specifiedEntity, customerRec);
    		BRPUtility.createURICommunicationNode(specifiedEntity, customerRec);
    	}
    	
    	dom.XmlNode postalAddress = BRPUtility.addChildElement(specifiedEntity, 'PostalAddress');
		String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
        List<String> bsList = billingStreet.split('\n');
		BRPUtility.addChildElementWithValue(postalAddress, 'LineOne', (bsList.size() > 0) ? bsList[0] : '');
		BRPUtility.addChildElementWithValue(postalAddress, 'CityName', customerRec.BillingCity);
		
		BRPUtility.createCountryIdElement(postalAddress, customerRec.BillingCountry);
		BRPUtility.addChildElementWithValue(postalAddress, 'Postcode', customerRec.BillingPostalCode);
		if(String.isNotBlank(customerRec.BillingState)) {
			BRPUtility.addChildElementWithValue(postalAddress, 'StateOrProvinceCountrySub-DivisionID', 
										customerRec.BillingState.length() > 6 ? customerRec.BillingState.subString(0, 6) : customerRec.BillingState);
		}
    }
    
    public static void createSoldFinanceNode(dom.XmlNode retailDeliveryReportingHeader,  Deal__c dealRec) {
    	dom.XmlNode soldFinance = BRPUtility.addChildElement(retailDeliveryReportingHeader, 'SoldFinance');
    	dom.XmlNode financing = BRPUtility.addChildElement(soldFinance, 'Financing');
    	BRPUtility.addChildElementWithValue(financing, 'FinanceTypeString', ((dealRec.Type__c != null && dealRec.Type__c == 'Financed') ? 'financed': 'paid in full'));
    }
    
    
    public static void createTradeInVehicleCreditNode(dom.XmlNode retailDeliveryReportingHeader, Deal_Item__c dealItemRec) {
		dom.XmlNode tradeInVehicleCredit = BRPUtility.addChildElement(retailDeliveryReportingHeader, 'TradeInVehicleCredit');
		dom.XmlNode vehicle = BRPUtility.addChildElement(tradeInVehicleCredit, 'Vehicle');
    	BRPUtility.addChildElementWithValue(vehicle, 'Model', dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c);
    	BRPUtility.addChildElementWithValue(vehicle, 'ModelYear', String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year__c));	
		BRPUtility.addChildElementWithValue(vehicle, 'ModelDescription', dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c);	
		BRPUtility.addChildElementWithValue(vehicle, 'VehicleID', dealItemRec.Customer_Owned_Unit__r.VIN_Number_Formula__c);
    	BRPUtility.addChildElementWithValue(vehicle, 'ManufacturerName', dealItemRec.Customer_Owned_Unit__r.Make_Name__c);	
		dom.XmlNode pricing = BRPUtility.addChildElement(tradeInVehicleCredit, 'Pricing');
		BRPUtility.addChildElementWithValue(pricing, 'PriceSourceCode', 'TotalVehicleCost');
		BRPUtility.addChildElementWithAttribute(pricing, 'ChargeAmount', String.valueOf(dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0.00), 'currencyID', BRPUtility.CurrencyCode);

		if(dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
			String mileageTypeValue = (dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? 'kilometer' : 'mile';
			BRPUtility.addChildElementWithAttribute(pricing, 'TradeInDistanceMeasure', String.valueOf(dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c), 'UnitCode', mileageTypeValue);
		} else {
			BRPUtility.addChildElementWithAttribute(pricing, 'TradeInDistanceMeasure', String.valueOf(dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c), 'UnitCode', 'hour');
		}	

    }
    
    
    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'COInvoiceHeader'       => new Set<String>{ 
                                            'Invoice_Date__c',
                                            'Invoice_Number__c',
                                            'Total__c',
                                            'Checkout_Type__c',
                                            'CO_Header__r.Customer__r.Name',
                                            'Sub_Total__c'
                                            },
        'Deal'            => new Set<String>{ 
        										'Name',
        										'Invoice_Number__r.Invoice_Date_Formula__c',
        										'Invoice_Number__r.Invoice_Date__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.Customer__r.Type__c',
												'CO_Header__r.Customer__r.Name',
												'CO_Header__r.Customer__r.Work_Number__c',
												'CO_Header__r.Customer__r.Work_Email__c',
												'CO_Header__r.Customer__r.FirstName__c',
												'CO_Header__r.Customer__r.LastName__c',
												'CO_Header__r.Customer__r.Home_Number__c',
												'CO_Header__r.Customer__r.Email__c',
												'CO_Header__r.Customer__r.Other_Email__c',
												'CO_Header__r.Customer__r.BillingCity',
												'CO_Header__r.Customer__r.BillingStreet',
												'CO_Header__r.Customer__r.BillingState',
												'CO_Header__r.Customer__r.BillingCountry',
												'CO_Header__r.Customer__r.BillingPostalCode',
												'CO_Header__r.Customer__r.Mobile__c',
												'Type__c',
												'Salesperson_Name__c',
                                                'Co_Buyer__c',
                                                'Co_Buyer__r.Type__c',
                                                'Co_Buyer__r.Name',
                                                'Co_Buyer__r.Work_Number__c',
                                                'Co_Buyer__r.Work_Email__c',
                                                'Co_Buyer__r.FirstName__c',
                                                'Co_Buyer__r.LastName__c',
                                                'Co_Buyer__r.Home_Number__c',
                                                'Co_Buyer__r.Mobile__c',
                                                'Co_Buyer__r.Email__c',
                                                'Co_Buyer__r.Other_Email__c',
                                                'Co_Buyer__r.BillingCity',
                                                'Co_Buyer__r.BillingStreet',
                                                'Co_Buyer__r.BillingState',
                                                'Co_Buyer__r.BillingCountry',
                                                'Co_Buyer__r.BillingPostalCode'
                                                },
		'DealItem'       => new Set<String> { 
													'Name',
													'Type__c',
													'Agreed_Value__c',
													'Customer_Owned_Unit__c',
													'Customer_Owned_Unit__r.Unit_Make__c',
													'Customer_Owned_Unit__r.Unit_Model__r.Name__c',
													'Customer_Owned_Unit__r.Year__c',
													'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
													'Customer_Owned_Unit__r.VIN_Number_Formula__c',
													'Customer_Owned_Unit__r.Make_Name__c',
													'Customer_Owned_Unit__r.Mileage_Type__c',
													'Customer_Owned_Unit__r.Mileage_Value__c',
													'Customer_Owned_Unit__r.New_Unit__c',
													'Customer_Owned_Unit__r.Total_Price__c',
													'Customer_Owned_Unit__r.Total_Cost__c',
													'Customer_Owned_Unit__r.Stock_Id__c'
												}
	};
}
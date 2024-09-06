public without sharing class BRPPartsInvoiceService {
    
    public static String MethodType = 'ProcessPartsInvoice';
    
    public static String createRequestBody() {
        DOM.Document doc = new DOM.Document();
        dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, MethodType);
        return doc.toXmlString();
    }
        
    public static String createRequestBody(CO_Invoice_Header__c coInvoiceRec, Account customerRec, List<CO_Line_Item__c> coliRecs) {
        DOM.Document doc = new DOM.Document();
        dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, MethodType);
        createProcessPartsInvoiceDataAreaNode(root, coInvoiceRec, customerRec, coliRecs);
        return doc.toXmlString();
    }
    
    public static void createProcessPartsInvoiceDataAreaNode(dom.XmlNode root, CO_Invoice_Header__c coInvoiceRec, Account customerRec, List<CO_Line_Item__c> coliRecs) {
        coInvoiceRec.Total__c = coInvoiceRec.Total__c != null ? coInvoiceRec.Total__c : 0.00;
        dom.XmlNode partsInvoiceDataArea = BRPUtility.addChildElement(root, 'ProcessPartsInvoiceDataArea');
        BRPUtility.addChildElement(partsInvoiceDataArea, 'Process');
        dom.XmlNode partsInvoiceNode = BRPUtility.addChildElement(partsInvoiceDataArea, 'PartsInvoice');
        
        createInvoiceHeaderNode(partsInvoiceNode, coInvoiceRec, customerRec, coliRecs);
    }
    
    private static void createInvoiceHeaderNode(dom.XmlNode parentNode, CO_Invoice_Header__c coInvoiceRec, Account customerRec, List<CO_Line_Item__c> coliRecs) {
    	dom.XmlNode partsInvoiceHeaderNode = BRPUtility.addChildElement(parentNode, 'PartsInvoiceHeader');
    	dom.XmlNode documentIdentificationGroupNode = BRPUtility.addChildElement(partsInvoiceHeaderNode, 'DocumentIdentificationGroup');
        dom.XmlNode documentIdentificationNode = BRPUtility.addChildElement(documentIdentificationGroupNode, 'DocumentIdentification');
        
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'DocumentID', MethodType);
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'AgencyRoleCode', 'Dealer');
        
        BRPUtility.addChildElementWithValue(partsInvoiceHeaderNode, 'TransactionTypeCode', 'Initial');
        
        Decimal totalQtySold = 0;
        List<Individual_Tax__c> individualTaxList = new List<Individual_Tax__c>();
        for(CO_Line_Item__c coliRec: coliRecs) {
        	coliRec.Qty__c = coliRec.Qty__c != null ? coliRec.Qty__c : 1;
            totalQtySold += (coliRec.Qty__c);
            individualTaxList.addAll(coliRec.Individual_Taxes__r);
        }
        
        BRPUtility.addChildElementWithValue(partsInvoiceHeaderNode, 'TotalPartPiecesNumeric', String.valueOf(totalQtySold.round(System.RoundingMode.UP)));
        BRPUtility.addChildElementWithAttribute(partsInvoiceHeaderNode, 'SubtotalBeforeDiscountsAmount', String.valueOf(coInvoiceRec.Sub_Total__c.setScale(2, RoundingMode.HALF_UP)), 'currencyID', BRPUtility.CurrencyCode);
        BRPUtility.addChildElementWithAttribute(partsInvoiceHeaderNode, 'TotalDiscountAmount', String.valueOf(0.00), 'currencyID', BRPUtility.CurrencyCode);
        BRPUtility.addChildElementWithAttribute(partsInvoiceHeaderNode, 'SubtotalIncludingDiscount', String.valueOf(coInvoiceRec.Sub_Total__c.setScale(2, RoundingMode.HALF_UP)), 'currencyID', BRPUtility.CurrencyCode);
        
        BRPUtility.createTaxNode(partsInvoiceHeaderNode, individualTaxList);
        
        BRPUtility.addChildElementWithAttribute(partsInvoiceHeaderNode, 'TotalAmount', String.valueOf(coInvoiceRec.Total__c.setScale(2, RoundingMode.HALF_UP)), 'currencyID', BRPUtility.CurrencyCode);
        BRPUtility.addChildElementWithValue(partsInvoiceHeaderNode, 'ProcessCode', coInvoiceRec.Checkout_Type__c == 'Deal' ? 'Internal' : 'Retail');
        
        //SoldToParty Node
    	if(customerRec != null) {
    		BRPUtility.createCustomerNode(partsInvoiceHeaderNode, 'SoldToParty', customerRec);
    	} else if(String.isNotBlank(coInvoiceRec.CO_Header__r.CO_Type__c) && coInvoiceRec.CO_Header__r.CO_Type__c == Constants.CASH_SALE) {
    		BRPUtility.createCustomerNodeForNonCustomerCO(partsInvoiceHeaderNode, 'SoldToParty', coInvoiceRec.CO_Header__r.CO_Type__c);
    	}
        
        BRPUtility.addChildElementWithValue(partsInvoiceHeaderNode, 'DealerOrderNumberString', coInvoiceRec.Invoice_Number__c);
        BRPUtility.addChildElementWithValue(partsInvoiceHeaderNode, 'PartsOrderReceivedDateTime', coInvoiceRec.Invoice_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'));
        
        createSoldByNode(partsInvoiceHeaderNode, coInvoiceRec);
        
        createInvoiceLinesNode(parentNode, coliRecs);
    }
    
    private static void createSoldByNode(dom.XmlNode parentNode, CO_Invoice_Header__c coInvoiceRec) {
    	BRPUtility.addChildElementWithValue(BRPUtility.addChildElement(BRPUtility.addChildElement(parentNode, 'SoldByParty'), 'SpecifiedPerson'), 'ID', coInvoiceRec.Salesperson__c);
    }
    
    private static void createChargeNode(dom.XmlNode parentNode) {
    	dom.XmlNode chargeNode = BRPUtility.addChildElement(parentNode, 'Charges');
    	BRPUtility.addChildElementWithAttribute(chargeNode, 'DeliveryChargeAmount', String.valueOf(0.00), 'currencyID', BRPUtility.CurrencyCode);
    }
    
    private static void createIndividualTaxNode(dom.XmlNode parentNode, Individual_Tax__c indTaxRec) {
    	indTaxRec.Tax_Rate__c = indTaxRec.Tax_Rate__c != null ? indTaxRec.Tax_Rate__c : 0.00;
        Decimal taxAmount = ((indTaxRec.Tax_Rate__c * (indTaxRec.Taxable_Amount__c != null ? indTaxRec.Taxable_Amount__c : 0.00)) / 100).setScale(2, RoundingMode.HALF_UP);
        
        dom.XmlNode taxNode = BRPUtility.addChildElement(parentNode, 'Tax');
        BRPUtility.addChildElementWithValue(taxNode, 'TaxTypeCode', 'Sales');
        BRPUtility.addChildElementWithAttribute(taxNode, 'TaxAmount', String.valueOf(taxAmount), 'currencyID', BRPUtility.CurrencyCode);
        BRPUtility.addChildElementWithValue(taxNode, 'TaxRatePercent', String.valueOf((indTaxRec.Tax_Rate__c / 100).setScale(8)));
        BRPUtility.addChildElementWithAttribute(taxNode, 'TotalTaxableAmount', String.valueOf(indTaxRec.Taxable_Amount__c != null ? indTaxRec.Taxable_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00), 'currencyID', BRPUtility.CurrencyCode);
    }
    
    private static void createInvoiceLinesNode(dom.XmlNode parentNode, List<CO_Line_Item__c> coliRecs) {
    	for(CO_Line_Item__c coliRec: coliRecs) {
        	if(BRPUtility.getAllBRPVendorsIdSet().contains(coliRec.Part__r.Vendor__c)) {
        		dom.XmlNode partsInvoiceLineNode = BRPUtility.addChildElement(parentNode, 'PartsInvoiceLine');
        		dom.XmlNode partsProductItemNode = BRPUtility.addChildElement(partsInvoiceLineNode, 'PartsProductItem');
        		createProductItemNode(partsProductItemNode, coliRec);
        		
        		BRPUtility.addChildElementWithAttribute(partsInvoiceLineNode, 'OrderQuantity', String.valueOf((coliRec.Qty__c != null ? coliRec.Qty__c : 1)), 'unitCode', 'ea');
        
		        // price fields for each line item
		        createPriceNodes(partsInvoiceLineNode, coliRec);
		        
		        createChargeNode(partsInvoiceLineNode);
		        
		        // tax lines for each tax
		        for(Individual_Tax__c indTaxRec: coliRec.Individual_Taxes__r) {
		            createIndividualTaxNode(partsInvoiceLineNode, indTaxRec);
		        }
        	}
        }
    }
    
    private static void createProductItemNode(dom.XmlNode parentNode, CO_Line_Item__c coliRec) {
    	BRPUtility.addChildElementWithValue(parentNode, 'PartItemDescription', coliRec.Part__r.Description__c);
        dom.XmlNode itemIdentificationNode = BRPUtility.addChildElement(BRPUtility.addChildElement(parentNode, 'ItemIdentificationGroup'), 'ItemIdentification');
        BRPUtility.addChildElementWithValue(itemIdentificationNode, 'ItemID', coliRec.Part__r.Part_Number__c);
    }
    
    private static void createPriceNodes(dom.XmlNode parentNode, CO_Line_Item__c coliRec) {
    	for(String priceField: BRPUtility.BRPPriceFieldsList) {
            Decimal chargeAmount = 0.00;
            if(priceField == 'Sold') {
                chargeAmount = coliRec.Price__c != null ? coliRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            } else if(priceField == 'Suggested Retail Price') {
                chargeAmount = coliRec.Part__r.Retail_Price__c != null ? coliRec.Part__r.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            } else if(priceField == 'Cost') {
            	if(coliRec.Adjusted_Cost_Coli__c != null && coliRec.Qty__c != 0) {
            		chargeAmount = (coliRec.Adjusted_Cost_Coli__c/coliRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
            	} else {
            		chargeAmount = coliRec.Part__r.Last_Cost__c != null ? coliRec.Part__r.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            	}
            }
            dom.XmlNode priceNode = BRPUtility.addChildElement(parentNode, 'Price');
            BRPUtility.addChildElementWithValue(priceNode, 'PriceCode', priceField);
            BRPUtility.addChildElementWithAttribute(priceNode, 'ChargeAmount', String.valueOf(chargeAmount), 'currencyID', BRPUtility.CurrencyCode);
            BRPUtility.addChildElementWithValue(priceNode, 'PriceDescription', priceField == 'Cost' ? 'FIFO' : '');
        }
    }
    
    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'COInvoiceHeader'       => new Set<String>{ 
                                            'Invoice_Date__c',
                                            'Invoice_Number__c',
                                            'Total__c',
                                            'Checkout_Type__c',
                                            'CO_Header__r.Customer__c',
                                            'Sub_Total__c',
                                            'Salesperson__c',
                                            'CO_Header__r.CO_Type__c'
                                            },
        'COLineItem'            => new Set<String>{ 
                                                'Qty__c',
                                                'Price__c',
                                                'Adjusted_Cost_Coli__c',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Description__c',
                                                'Part__r.Vendor__c',
                                                'Part__r.Last_Cost__c',
                                                'Part__r.Retail_Price__c',
                                                'Deal__c',
                                                'Invoice_Number__c'
                                },
       'IndividualTax'            => new Set<String>{ 
                                                'Tax_Amount__c',
                                                'Tax_Rate__c',
                                                'Taxable_Amount__c',
                                                'Sales_Tax_Item__r.Name__c'
                                }
    };
}
/** 
* Author: Richa Mittal
* Since: Feb 10, 2021
* Name: PrintOrderFulfillmentCtrl 
* Description: Apex class which contains print order fulfillment related methods.
**/
global without sharing class PrintOrderFulfillmentCtrl {
    
    public String coInvId {get;private set;}
    public String brandingLocationId {get;private set;}
	public OrderFulfillmentWrapper OrderFulfillmentObj {get; private set;}
	public Boolean isHidePartNumbersOnDocuments{get{return GeneralConfiguration.isHidePartNumbersOnDocuments();} private set;}
    public Boolean isIncludeMSRPAndDiscountOnPartLines{get{return GeneralConfiguration.isIncludeMSRPAndDiscountOnPartLines();} private set;}
    
    public PrintOrderFulfillmentCtrl() {
        coInvId = ApexPages.currentPage().getParameters().get('id');
        brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
        if(String.isBlank(coInvId)) {
            return;
        }
        
        List<CO_Invoice_Header__c> coInvoiceList = PrintCustomerOrderInvoiceCtrl.getCustomerOrderInvoiceHeaders(new List<Id>{coInvId});
        List<CO_Line_Item__c> coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coInvoiceList[0].CO_Header__c);
        List<CO_Kit_Header__c> coKitHeaders = SOQLUtil.getCOKHByCOHeaderId(coInvoiceList[0].CO_Header__c);
        List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coLineItems, coKitHeaders);
        Map<String, CO_Line_Item__c> coLiIdToRecMap = new Map<String, CO_Line_Item__c>();
        for(CO_Line_Item__c coli: coLineItems) {
        	coLiIdToRecMap.put(coli.Id, coli);
        }
        
        BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
	    OrderFulfillmentObj = new OrderFulfillmentWrapper(coInvoiceList[0], COKHList, coLiIdToRecMap, brandingLocationObj);
    }
    
    public class OrderFulfillmentWrapper {
    	public PrintCustomerOrderInvoiceCtrl.COInvoiceDetail COInvoice {get; set;}
    	public CustomerDetail.Company CompanyInfo {get; set;}
    	public List<SectionWrapper> LineItemsSectionList {get; set;}
    	public String CustomerInvoiceWarrantyText{get; set;}
    	public String COHeaderNumber {get; set;}
    	
    	public OrderFulfillmentWrapper(CO_Invoice_Header__c coInvoiceHeader, List<COHeaderWrapper.COKitHeader> COKHList, Map<String, CO_Line_Item__c> coLiIdToRecMap, 
    									BrandingLocationWrapper brandingLocationObj) {
            this.COHeaderNumber = coInvoiceHeader.CO_Header__r.Name;    
            this.COInvoice = new PrintCustomerOrderInvoiceCtrl.COInvoiceDetail(coInvoiceHeader); 
            
            if(brandingLocationObj != null) {
                this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
                this.CustomerInvoiceWarrantyText = (brandingLocationObj.DisclaimerforCustomerInvoice != null) ? brandingLocationObj.DisclaimerforCustomerInvoice : '';
            }
            this.CompanyInfo.BusinessPhone = this.CompanyInfo.FormattedBusinessPhone != null ? this.CompanyInfo.FormattedBusinessPhone: '';
            
            SectionWrapper thisShipment = new SectionWrapper(Constants.THIS_SHIPMENT, coInvoiceHeader.Invoice_Number__c, coInvoiceHeader.Tracking_Number__c);
            SectionWrapper notYetShipped = new SectionWrapper(Constants.NOT_YET_SHIPPED, '', '');
            Map<String, SectionWrapper> previousShipmentMap = new Map<String, SectionWrapper>();
            
            this.LineItemsSectionList = new List<SectionWrapper>();
            for(COHeaderWrapper.COKitHeader cokhRec: COKHList) {
            	if(cokhRec.COLIList.size() > 0) {
            		String invoiceNumber = '';
            		String trackingNumber = '';
            		Decimal totalWithTax = 0;
            		for(COLineItem coli: cokhRec.COLIList) {
            			CO_Line_Item__c coliRec = coLiIdToRecMap.containsKey(coli.CoLineItemId) ? coLiIdToRecMap.get(coli.CoLineItemId) : null;
            			if(coliRec != null) {
            				invoiceNumber = coliRec.Invoice_Number__c != null ? coliRec.Invoice_Number__r.Invoice_Number__c : '';
        					trackingNumber = coliRec.Tracking_Number__c != null ? coliRec.Tracking_Number__c : '';
            				totalWithTax += getcoliTotalWithTax(coliRec);
            			}
            		}
            		
            		if(String.isBlank(cokhRec.COLIList[0].Invoice)) {
            			notYetShipped.SectionTotal += totalWithTax;
	            		notYetShipped.COKHList.add(cokhRec);
	            	} else if(cokhRec.COLIList[0].Invoice == coInvoiceHeader.Name) {
	            		thisShipment.SectionTotal += totalWithTax;
	            		thisShipment.COKHList.add(cokhRec);
	            	} else {
	            		if(!previousShipmentMap.containsKey(invoiceNumber)) {
	            			previousShipmentMap.put(invoiceNumber, new SectionWrapper(Constants.PREVIOUS_SHIPMENT, invoiceNumber, trackingNumber));
	            		}
	            		previousShipmentMap.get(invoiceNumber).SectionTotal += totalWithTax;
	            		previousShipmentMap.get(invoiceNumber).COKHList.add(cokhRec);
	            	}
            	}
            }
            this.LineItemsSectionList.add(thisShipment);
            if(previousShipmentMap.size() > 0) {
            	this.LineItemsSectionList.addAll(previousShipmentMap.values());
            } else {
            	this.LineItemsSectionList.add(new SectionWrapper(Constants.PREVIOUS_SHIPMENT, '', ''));
            }
            this.LineItemsSectionList.add(notYetShipped);
    	}
    }
    
    public class SectionWrapper {
    	public String SectionName {get; set;}
    	public String InvoiceNumber {get; set;}
    	public String TrackingNumber {get; set;}
    	public Decimal SectionTotal {get; set;}
    	public List<COHeaderWrapper.COKitHeader> COKHList {get; set;}
    	
    	public SectionWrapper(String sectionName, String invoiceNumber, String trackingNumber) {
    		this.SectionName = sectionName;
    		this.InvoiceNumber = invoiceNumber;
			this.TrackingNumber = trackingNumber;
			this.SectionTotal = 0;
			this.COKHList = new List<COHeaderWrapper.COKitHeader>();
    	}
    }
    
    private static Decimal getcoliTotalWithTax(CO_Line_Item__c coliRec) {
    	coliRec.Qty__c = (coliRec.Qty__c == null) ? 0 : coliRec.Qty__c;
        coliRec.Price__c = (coliRec.Price__c == null) ? 0 : coliRec.Price__c;
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
        	coliRec.Price_When_Tax_Included__c = (coliRec.Price_When_Tax_Included__c == null) ? 0 : coliRec.Price_When_Tax_Included__c;
			return (coliRec.Price_When_Tax_Included__c * coliRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
		} else {
			Decimal coliTaxAmount = 0;
			for(Individual_Tax__c individualTaxRec : coliRec.Individual_Taxes__r) {
            	if(individualTaxRec.Enhanced_Tax_Amount__c != null) {
            		coliTaxAmount += individualTaxRec.Enhanced_Tax_Amount__c;
            	} else {
            		individualTaxRec.Tax_Rate__c = (individualTaxRec.Tax_Rate__c != null) ? individualTaxRec.Tax_Rate__c : 0;
            		coliTaxAmount += (individualTaxRec.Tax_Rate__c * coliRec.Qty__c * coliRec.Price__c) / 100;
            	}
            }
            return ((coliRec.Price__c * coliRec.Qty__c) + coliTaxAmount).setScale(2, RoundingMode.HALF_UP);
		}
    }
}
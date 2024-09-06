public without sharing class NewPrintMerchandiseCtrl {
	
	public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
	public PrintCustomerOrderInvoiceCtrl.COMerchandiseDetail COMerchandiseDetailObj {get; private set;}
	public CustomerDetail.Company CompanyInfo {get; set;}
	public List<PrintCustomerOrderInvoiceCtrl.ServiceDetail> Services {get; set;}
	public PrintCustomerOrderInvoiceCtrl.CustomerMerchandies custmerMercRec {get; set;}
    public List<COLineItem> DealMerchCOLineItem {get; set;}
	
	public NewPrintMerchandiseCtrl() {
		COMerchandiseDetailObj = new PrintCustomerOrderInvoiceCtrl.COMerchandiseDetail();
		Id coHeaderId;
		String coHeaderIdStr = ApexPages.currentPage().getParameters().get('id');
		String brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
		//Setting the Company Information
		BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
		if(brandingLocationObj != null) {
                this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
            }
		
		if(!String.isBlank(coHeaderIdStr)) {
			try {
				coHeaderId = Id.valueOf(coHeaderIdStr);
				List<CO_Header__c> coHeadersList = PrintCustomerOrderInvoiceCtrl.getCustomerOrderDetails(coHeaderId);
				this.custmerMercRec = new PrintCustomerOrderInvoiceCtrl.CustomerMerchandies(coHeadersList[0]);
                this.DealMerchCOLineItem = getDealMerchandiseDetails(BPUtility.getEncodedString(coHeaderId));
				getMerchandiseDetails(BPUtility.getEncodedString(coHeaderId), brandingLocationId);
			} catch(Exception e) {
				System.debug(e.getMessage());
			}
		}
		
        if(!String.isBlank(coHeaderIdStr)) {
        	List<Id> sohIds = new List<Id>();
        	Map<Id, Service_Order_Header__c> soHeaderIdToSOHeaderRecMap = new Map<Id, Service_Order_Header__c>([SELECT Id, CO_Header__c FROM Service_Order_Header__c where CO_Header__c =: coHeaderId]);
        	if((soHeaderIdToSOHeaderRecMap.keySet()).size() > 0) {
        		this.Services = new List<PrintCustomerOrderInvoiceCtrl.ServiceDetail>();
        		sohIds.addAll(soHeaderIdToSOHeaderRecMap.keySet());
        		system.debug(sohIds);
        		List<Service_Order_Header__c> soHeadersList = PrintCustomerOrderInvoiceCtrl.getServiceOrderHeaders(new List<Id>{coHeaderId}, sohIds);
                for(Service_Order_Header__c soHeader : soHeadersList) {
                    List<Service_Order_Kit_Header__c> sokitHeadersList = SOQLUtil.getSOKHBySOHeaderId(soHeader.Id);
                    this.Services.add(new PrintCustomerOrderInvoiceCtrl.ServiceDetail(null, soHeader, sokitHeadersList));
                }	
        	}
        }
	}
	
    /**
     * Name: getCOInvoiceDetails
     * Desc: 
     * @param:  (1) coInvoiceIdStr
     * @return: String - JSON String
    **/
    public void getMerchandiseDetails(String coHeaderId, String brandingLocationId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
    	List<CO_Line_Item__c> coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeaderId);
        List<CO_Kit_Header__c> coKitHeaders = SOQLUtil.getCOKHByCOHeaderId(coHeaderId);
        List<CO_Header__c> coHeadersList = PrintCustomerOrderInvoiceCtrl.getCustomerOrderDetails(coHeaderId);
        List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coLineItems, coKitHeaders);
		
        BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
        if(coLineItems == null) {
            coLineItems = new List<CO_Line_Item__c>();
        }
        
        Decimal subtotal = 0;
        Decimal salesTax = 0;
        Decimal priceOverrides = 0;
        
        Decimal total_Part = 0;
        Decimal total_Laobur = 0;
        Decimal total_Sublet = 0;
        Decimal total_Fee = 0;
        Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();            
            //Decimal australianMarketTaxRate = (Australian_Market__c.getInstance().get(Constants.NAMESPACE + 'Sales_Tax_Rate__c') != null) ? 
                                                //Decimal.valueOf(String.valueOf(Australian_Market__c.getInstance().get(Constants.NAMESPACE + 'Sales_Tax_Rate__c'))) : 0;
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        
        for(CO_Line_Item__c coLineItemRec : coLineItems) {
            coLineItemRec.Qty__c = (coLineItemRec.Qty__c == null) ? 0 : coLineItemRec.Qty__c;
            coLineItemRec.Price__c = (coLineItemRec.Price__c == null) ? 0 : coLineItemRec.Price__c;
            coLineItemRec.Retail__c = (coLineItemRec.Retail__c == null) ? 0 : coLineItemRec.Retail__c;
            coLineItemRec.Tax__c = (coLineItemRec.Tax__c == null) ? 0 : coLineItemRec.Tax__c;
            
            for(Individual_Tax__c individualTaxRec : coLineItemRec.Individual_Taxes__r) {
            	Decimal taxValue;
            	if(salesTaxNameToTaxValue.containsKey(individualTaxRec.Sales_Tax_Item__r.Name__c)) {
            		taxValue = salesTaxNameToTaxValue.get(individualTaxRec.Sales_Tax_Item__r.Name__c);
            	} else {
            		taxValue = 0;
            	}
            	if(individualTaxRec.Enhanced_Tax_Amount__c != null) {
            		taxValue += individualTaxRec.Enhanced_Tax_Amount__c;
            	} else {
            		taxValue += (individualTaxRec.Tax_Rate__c * coLineItemRec.Qty__c * coLineItemRec.Price__c) / 100;
            	}
            	salesTaxNameToTaxValue.put(individualTaxRec.Sales_Tax_Item__r.Name__c, taxValue);
            }
            
            if(coLineItemRec.Kit_Price_With_Price_Level__c == null  ){
                coLineItemRec.Kit_Price_With_Price_Level__c = coLineItemRec.Price__c;
            }
            if(coLineItemRec.CO_Kit_Header__c != null ){
                priceOverrides += coLineItemRec.Qty__c * (coLineItemRec.Price__c - coLineItemRec.Kit_Price_With_Price_Level__c);
            }else If(coLineItemRec.CO_Kit_Header__c == null ){
                priceOverrides += coLineItemRec.Qty__c * (coLineItemRec.Price__c - coLineItemRec.Actual_Kit_Price__c);
            }
            
            if(!isTaxIncludingPricing) {
                if(coLineItemRec.Part__c != null) {
                    total_Part += coLineItemRec.Qty__c * coLineItemRec.Price__c;
                }
                if(coLineItemRec.Fee__c != null) {
                    total_Fee += coLineItemRec.Qty__c * coLineItemRec.Price__c;
                }
                subtotal += coLineItemRec.Qty__c * coLineItemRec.Price__c;
                salesTax += (coLineItemRec.Qty__c * coLineItemRec.Price__c * coLineItemRec.Tax__c) / 100;
            } else {
            	if(coLineItemRec.Price__c == null) {
            		coLineItemRec.Price__c = 0;

            	}
            	if(coLineItemRec.Tax__c == null) {
            		coLineItemRec.Tax__c = 0;

            	}
            	if(coLineItemRec.Part__c != null) {
                    total_Part += (coLineItemRec.Qty__c * coLineItemRec.Price__c) + 
                    			((coLineItemRec.Qty__c * coLineItemRec.Price__c * coLineItemRec.Tax__c) / 100);
                }
                if(coLineItemRec.Fee__c != null) {
                    total_Fee += (coLineItemRec.Qty__c * coLineItemRec.Price__c) + 
                    			((coLineItemRec.Qty__c * coLineItemRec.Price__c * coLineItemRec.Tax__c) / 100);
                }
                subtotal += coLineItemRec.Sub_Total_With_Tax__c;
            }
        }
        List<PrintCustomerOrderInvoiceCtrl.CustomerMerchandies> cusRec =  new  List<PrintCustomerOrderInvoiceCtrl.CustomerMerchandies>();
        for(CO_Header__c coHeaderRec : coHeadersList ){
        	cusRec.add(new PrintCustomerOrderInvoiceCtrl.CustomerMerchandies(coHeaderRec) ); 
        }
        
        CO_Invoice_Header__c coHeaderInvoiceRec = new CO_Invoice_Header__c();
        if(coHeadersList.size() > 0) {
        	coHeaderInvoiceRec = (coHeadersList[0].CO_Invoice_Headers__r.size() > 0) ? coHeadersList[0].CO_Invoice_Headers__r[0] : new CO_Invoice_Header__c();
        }

        if(coLineItems.size() > 0) {
            COMerchandiseDetailObj = new PrintCustomerOrderInvoiceCtrl.COMerchandiseDetail(COKHList, subtotal, salesTax, priceOverrides, total_Part, total_Laobur, total_Sublet, total_Fee, salesTaxNameToTaxValue, cusRec, coHeaderInvoiceRec, brandingLocationObj);
        }
    } 

    /**
     * Name: getDealMerchandiseDetails
     * Desc: 
     * @param:  (1) coInvoiceId
     * @return: List of COLineItem
    **/
    private List<COLineItem> getDealMerchandiseDetails(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        List<CO_Line_Item__c> coliList = SOQLUtil.getDealMerchCOLineItemByCOHeaderId(coHeaderId);
        List<COLineItem> COLineItemWrapperList = new List<COLineItem>();
        for(CO_Line_Item__c coliRec : coliList) {
            COLineItemWrapperList.add(new COLineItem(coliRec));
        }
        return COLineItemWrapperList;
    }
}
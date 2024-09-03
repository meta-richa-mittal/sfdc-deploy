/**
 * Name: PrintCustomerOrderInvoiceCtrl 
 * Description: 
 * 
**/
global without sharing class PrintCustomerOrderInvoiceCtrl {
    global PrintCustomerOrderInvoiceCtrl (NewHomePageCtrl controller){
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    
    public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
    public boolean isDisplayTaxInvoice { get{return GeneralConfiguration.isDisplayTaxInvoice();} private set;}
    

    
    public static Map<String, String> merchandiseNameToType = new Map<String, String>{'Part'    => 'Part',
                                                                                      'Fee'     => 'Fee',
                                                                                      'Labour'  => 'Labour',
                                                                                      'Sublet'  => 'Sublet'};
                                                                                      
    //public String  dateFormat { get{ return Constants.localeToDateTimeFmtMap.containsKey(UserInfo.getLocale())? Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale()):Constants.localeToDateTimeFmtMap.get('en_AU') ;}private set;}
    public String  dateFormat { get{ return BPUtility.getDateFormat();}private set;}

    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    Public String coId {get;private set;}
    Public String isFinalizedStr {get;Private set;}
    public boolean isFinalized {get;private set;}
    public String headerText {get;private set;}
    public String headerText1 {get;private set;}
    public boolean isBindBalanceDue {get;private set;}
    public String brandingLocationId {get;private set;}
    public Boolean isHidePartNumbersOnDocuments{get{return GeneralConfiguration.isHidePartNumbersOnDocuments();} private set;}
    public Boolean isHideKitDetailsOnDocuments{get{return GeneralConfiguration.isHideKitDetailsOnDocuments();} private set;}
    public Boolean isIncludeMSRPAndDiscountOnPartLines{get{return GeneralConfiguration.isIncludeMSRPAndDiscountOnPartLines();} private set;}
    public Decimal ARBalanceDue {get; private set;}
    public String DealFormId { get{return GeneralConfiguration.getFormIdToIncludeOnDealDocuments();} private set;}
    
    public CustomerOrderInvoiceDetail CustomerOrderInvoiceDetailRecord{get; private set;}
    
    public PrintCustomerOrderInvoiceCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
        coId = ApexPages.currentPage().getParameters().get('id');
        isFinalizedStr  = ApexPages.currentPage().getParameters().get('isFinalized');
        brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
        string selectedSectionJson =  BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('SelectedSectionsIds'));
        List<SelectedSectionsWrapper> selectedSectionsList  = new List<SelectedSectionsWrapper>();
        if(String.isNotBlank(selectedSectionJson)){
            selectedSectionsList = (List<SelectedSectionsWrapper>)System.JSON.deserialize(selectedSectionJson, List<SelectedSectionsWrapper>.class);
        }
        if(isFinalizedStr == 'true'){
        	isFinalized = true;
        } else {
	        isFinalized = false;
	    }
        if(coId  == '' || coId == 'undefined' || coId == null){
            return;
        }else{
        //coId= BPUtility.getEncodedString(coId);
        	
        	String COInvoiceDetailJson;
	        if(String.isNotBlank(brandingLocationId)) {
	        	//brandingLocationId= BPUtility.getEncodedString(brandingLocationId);
                COInvoiceDetailJson = BPUtility.getEncodedString(getInvoiceDetails(coId, isFinalized, brandingLocationId, selectedSectionsList));
	        } else {
                COInvoiceDetailJson = BPUtility.getEncodedString(getInvoiceDetails(coId, isFinalized, null, selectedSectionsList));
	        }
        
        if(String.isNotBlank(COInvoiceDetailJson)) {
                COInvoiceDetailJson = BPUtility.getDecodedString(COInvoiceDetailJson);
                CustomerOrderInvoiceDetailRecord = (CustomerOrderInvoiceDetail)JSON.deserialize(COInvoiceDetailJson, CustomerOrderInvoiceDetail.class);
            }
        }
        
        this.isBindBalanceDue = false; 
        if(CustomerOrderInvoiceDetailRecord.COInvoice.CheckoutType != 'Internal'
            || (CustomerOrderInvoiceDetailRecord.COInvoice.CheckoutType == 'Internal' && CustomerOrderInvoiceDetailRecord.COInvoice.Status != 'Closed')) {
            this.isBindBalanceDue = true;
        } else if(CustomerOrderInvoiceDetailRecord.COInvoice.CheckoutType == 'Internal' && CustomerOrderInvoiceDetailRecord.COInvoice.Status == 'Closed') {
            this.isBindBalanceDue = false;
        }
        Boolean isQuoteInvoice = (!isFinalized && CustomerOrderInvoiceDetailRecord.OrderStatus == 'Quote') ? true : false;
        if(isQuoteInvoice) {
            headerText = headerText1 = 'QUOTE';
        } else {
            headerText = 'INVOICE';
            headerText1= 'TAX INVOICE';
            if ((CustomerOrderInvoiceDetailRecord.COKHList.size() > 0 && CustomerOrderInvoiceDetailRecord.COKHList[0].COLIList[0].DealId != null) ||
                (CustomerOrderInvoiceDetailRecord.DealCOKHList.size() > 0 && CustomerOrderInvoiceDetailRecord.DealCOKHList[0].COLIList[0].DealId != null && CustomerOrderInvoiceDetailRecord.COInvoice.CheckoutType != null) ||
                (CustomerOrderInvoiceDetailRecord.Services.size() > 0 && CustomerOrderInvoiceDetailRecord.Services[0].IsDealService && CustomerOrderInvoiceDetailRecord.COInvoice.CheckoutType != null)) {
                headerText = headerText1 = 'INTERNAL INVOICE';
            }
        }
    }
    
    public void getARBalanceDue() {
        if(isFinalized && CustomerOrderInvoiceDetailRecord.COInvoice.hasChargeOnAccountPayment) {
            this.ARBalanceDue = COService.getCOInvoiceARBalance(CustomerOrderInvoiceDetailRecord.COInvoice.InvoiceId);
        }
    }

    @RemoteAction
    global static String emailSelectedDocument(String documentJSON, String emailAddressJson) {
        documentJSON = BPUtility.getDecodedString(documentJSON);
        emailAddressJson = BPUtility.getDecodedString(emailAddressJson);
        
        List<SendEmail.DocumentWrapper> docWrapperList = (List<SendEmail.DocumentWrapper>) system.JSON.deserialize(documentJSON, List<SendEmail.DocumentWrapper>.class);
        SendEmail.EmailAddressWrapper emailAddressObj = (SendEmail.EmailAddressWrapper) system.JSON.deserialize(emailAddressJson, SendEmail.EmailAddressWrapper.class);
        
        List<String> ccEmailList = String.isNotBlank(emailAddressObj.CcEmail) ? new List<String>{emailAddressObj.CcEmail} : new List<String>();
        String response = SendEmail.sendSelectedDocument(docWrapperList, new List<String>{emailAddressObj.ToEmail}, ccEmailList, null, emailAddressObj.OptionalMessage, emailAddressObj.ReplyTo);
        
        // Add internal comment for emailed documents
        COService.addIntCommentForCOEmailedDocs(docWrapperList, emailAddressObj);
        
        return response;
    }
    
    @RemoteAction
    global static String emailInvoicePdf( String COInvoiceHeaderID, String emailAddressJson){
        COInvoiceHeaderID = BPUtility.getDecodedString(COInvoiceHeaderID );
        emailAddressJson= BPUtility.getDecodedString(emailAddressJson);
        return sendEmailInvoicePdf(COInvoiceHeaderID, emailAddressJson, null);
    }
    
    @RemoteAction
    global static String emailInvoicePdfWithBrandingLocation(String COInvoiceHeaderID, String emailAddressJson, String brandingLocationId) {
    	COInvoiceHeaderID = BPUtility.getDecodedString(COInvoiceHeaderID);
        emailAddressJson= BPUtility.getDecodedString(emailAddressJson);
        brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
    	return sendEmailInvoicePdf(COInvoiceHeaderID, emailAddressJson, brandingLocationId);
    }
    
    private static String sendEmailInvoicePdf(String documentToEmailId, String emailAddressJson, String brandingLocationId) {
        SendEmail.EmailAddressWrapper emailAddressObj = (SendEmail.EmailAddressWrapper) system.JSON.deserialize(emailAddressJson, SendEmail.EmailAddressWrapper.class);
        
        List<String> emailList = String.isNotBlank(emailAddressObj.ToEmail) ? new List<String>{emailAddressObj.ToEmail} : new List<String>(); 
        List<String> ccEmailList = String.isNotBlank(emailAddressObj.CcEmail) ? new List<String>{emailAddressObj.CcEmail} : new List<String>();
        SendEmail.pageNameToEmail = String.isNotBlank(emailAddressObj.PageName) ? emailAddressObj.PageName : null;
        String subject = '';
        String optionalMessage = String.isNotBlank(emailAddressObj.OptionalMessage) ? emailAddressObj.OptionalMessage : '';
        String objectName = (Id.valueOf(documentToEmailId)).getSObjectType().getDescribe().getName();
        if(objectName.endsWithIgnoreCase('Payment_On_Account__c')) {
            List<Payment_On_Account__c> poaList = [Select Name, Customer__r.Name from Payment_On_Account__c where Id =: documentToEmailId];
            if(!poaList.isEmpty()) {
                subject = 'Payment Receipt - ' + poaList[0].Name + ' - ' + poaList[0].Customer__r.Name;
                return SendEmail.sendInvoice(emailList, ccEmailList, subject, optionalMessage, documentToEmailId, null, brandingLocationId);
            }
            return 'error';
        }
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id, CO_Header__r.Customer__c, CO_Header__r.CO_Type__c, Invoice_Number__c, CO_Header__r.Customer_Name__c from CO_Invoice_Header__c where Id =: documentToEmailId];
        if(String.isNotBlank(SendEmail.pageNameToEmail) && coInvoiceHeaderList.size() > 0) {
        	subject = SendEmail.pageNameToFileNameMap.get(SendEmail.pageNameToEmail) + ' - ' + coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
        } else if (coInvoiceHeaderList.size() > 0 ) {
            subject = 'Invoice - ' + coInvoiceHeaderList[0].Invoice_Number__c +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
        }
        String isFinalized = 'true';
        String response = SendEmail.sendInvoice(emailList, ccEmailList, subject, optionalMessage, documentToEmailId ,isFinalized, brandingLocationId, emailAddressObj.ReplyTo);
        if(response == 'success') {
            if(coInvoiceHeaderList.size() > 0) {
                Message_History__c msgRec = new Message_History__c(Sent_By__c = UserInfo.getUserId(), CO_Invoice_Header__c = documentToEmailId, 
                                                        Activity__c = 'Emailed Invoice', Email__c = emailAddressObj.ToEmail, SMS_Body__c = 'Email Invoice PDF');
                if(coInvoiceHeaderList[0].CO_Header__r.CO_Type__c == Constants.CHECKOUT_TYPE_CUSTOMER && 
                        coInvoiceHeaderList[0].CO_Header__r.Customer__c != null) {
                    msgRec.Sent_To__c = coInvoiceHeaderList[0].CO_Header__r.Customer__c;
                }
                DMLUtility.insertSobjectList('Message_History__c', msgRec);
                SendEmail.DocumentWrapper docWrapperObj = new SendEmail.DocumentWrapper();
                docWrapperObj.COHeaderId = coInvoiceHeaderList[0].CO_Header__r.Id;
                docWrapperObj.DocumentName = 'Invoice - ' + coInvoiceHeaderList[0].Invoice_Number__c;
                COService.addIntCommentForCOEmailedDocs(new List<SendEmail.DocumentWrapper>{docWrapperObj}, emailAddressObj);
            }
        }
        return response;
    }
    
    // Start: Ticket#1984: Depricated By Hitesh 3 May 2017
    /**
     * Name: getCOInvoiceDetails
     * Desc: 
     * @param:  (1) coInvoiceIdStr
     * @return: String - JSON String
    **/
    @RemoteAction
    // Edited by kajal 12/08/2016 deal invoice
    global static String getCOInvoiceDetails(String coInvoiceIdStr) {
        return '';
    }

    
    /**
     * Name: getCOInvoiceDetailsWithFinalize
     * Desc: 
     * @param:  (1) coInvoiceIdStr (2) isFinalized
     * @return: String - JSON String
    **/
    @RemoteAction
    global static String getCOInvoiceDetailsWithFinalize(String coInvoiceIdStr, Boolean isFinalized) {
        coInvoiceIdStr = BPUtility.getDecodedString(coInvoiceIdStr);
        return BPUtility.getEncodedString(getInvoiceDetails(coInvoiceIdStr, isFinalized, null,  new List<SelectedSectionsWrapper>()));
    }
    
    @RemoteAction
    global static String getCOInvoiceDetailsWithBrandingLocation(String coInvoiceIdStr, Boolean isFinalized, String brandingLocationId) {
        coInvoiceIdStr = BPUtility.getDecodedString(coInvoiceIdStr);
        brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
        return BPUtility.getEncodedString(getInvoiceDetails(coInvoiceIdStr, isFinalized, brandingLocationId, new List<SelectedSectionsWrapper>()));
    }
    
    private static String getInvoiceDetails(String coInvoiceIdStr, Boolean isFinalized, String brandingLocationId, List<SelectedSectionsWrapper> selectedSectionsList) {
        String coInvoiceDetails;
        //try{
            Id coInvoiceId = coInvoiceIdStr;
            Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();  
            List<CO_Invoice_Header__c> coInvoices = getCustomerOrderInvoiceHeaders(new List<Id>{coInvoiceId});
            if(coInvoices.size() > 0) {
                List<Id> coliIds = new List<Id>();
                List<Id> sohIds = new List<Id>();
                Set<Id> sohTaxableItemIds = new Set<Id>();
                List<Id> cokhIds = new List<Id>();
                List<Id> dealIds = new List<Id>();// Added by kajal 12/08/2016 deal invoice
                List<Id> soPaymentRoleIds = new List<Id>();
                boolean isMerchSectionSelected = false;
                Boolean displayMerchNotes = false;
                String invoiceType = '';
                if(!isFinalized){
                    for(SelectedSectionsWrapper selectedSectionsRec: selectedSectionsList) {
                        if(selectedSectionsRec.sectionName == 'Parts & accessories') {
                            isMerchSectionSelected = true;
                            displayMerchNotes = true;
                        } else if(selectedSectionsRec.sectionName == 'Service job'){
                            sohIds.add(selectedSectionsRec.sectionId);
                        } else if(selectedSectionsRec.sectionName == 'Unit deal') {
                            dealIds.add(selectedSectionsRec.sectionId);
                        }
                    }
                }
                if(coInvoices[0].CO_Invoice_Items__r != null) {
                    for(CO_Invoice_Item__c coInvoiceItem : coInvoices[0].CO_Invoice_Items__r) {
                        /*if(coInvoiceItem.CO_Line_Item__c != null) {
                            coliIds.add(coInvoiceItem.CO_Line_Item__c);
                        }
                        if(coInvoiceItem.Service_Order_Header__c != null) {
                            sohIds.add(coInvoiceItem.Service_Order_Header__c);
                        }
                        if(coInvoiceItem.CO_Kit_Header__c != null) {
                            cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                        }
                        // Added by kajal 12/08/2016 deal invoice
                        if(coInvoiceItem.Deal__c != null) {
                            dealIds.add(coInvoiceItem.Deal__c);
                        }*/
                        if(!isFinalized) {
                            if(coInvoiceItem.CO_Line_Item__c != null && coInvoiceItem.CO_Line_Item__r.Option_Fee__c == null && coInvoiceItem.CO_Line_Item__r.Deal__c == null && isMerchSectionSelected) {
                                coliIds.add(coInvoiceItem.CO_Line_Item__c);
                            }

                            if(coInvoiceItem.Service_Order_Header__c != null && sohIds.contains(coInvoiceItem.Service_Order_Header__c)) {
                                if(coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') {
                                    sohTaxableItemIds.add(coInvoiceItem.Service_Order_Header__c);
                                } else if(coInvoiceItem.SO_Payment_Role__c != null && coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible' && coInvoiceItem.Service_Order_Header__r.Deal__c == null) {
                                    soPaymentRoleIds.add(coInvoiceItem.SO_Payment_Role__c);
                                }
                                if((coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') && coInvoiceItem.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
                                    invoiceType = 'Third-Party';
                                }
                            }

                            if(coInvoiceItem.CO_Kit_Header__c != null && coInvoiceItem.CO_Kit_Header__r.Deal__c == null  && isMerchSectionSelected) {
                                cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                            }
                        } else{
                            if(coInvoiceItem.CO_Line_Item__c != null) {
                                coliIds.add(coInvoiceItem.CO_Line_Item__c);
                            }
                            if(coInvoiceItem.Service_Order_Header__c != null) {
                                if(coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') {
                                    sohTaxableItemIds.add(coInvoiceItem.Service_Order_Header__c);
                                } else if(coInvoiceItem.SO_Payment_Role__c != null && coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible' && coInvoiceItem.Service_Order_Header__r.Deal__c == null) {
                                    soPaymentRoleIds.add(coInvoiceItem.SO_Payment_Role__c);
                                }
                                sohIds.add(coInvoiceItem.Service_Order_Header__c);
                                if((coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') && coInvoiceItem.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
                                    invoiceType = 'Third-Party';
                                }
                            }
                            if(coInvoiceItem.CO_Kit_Header__c != null) {
                                cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                            }
                            if(coInvoiceItem.Deal__c != null) {
                                dealIds.add(coInvoiceItem.Deal__c);
                            }
                            if(coInvoiceItem.CO_Line_Item__c != null && coInvoiceItem.CO_Line_Item__r.Option_Fee__c == null && coInvoiceItem.CO_Line_Item__r.Deal__c == null) {
                                displayMerchNotes = true;
                            }
                        }
                    }
                }

                CO_Invoice_Header__c coInvRec = coInvoices[0];
                if(!isFinalized){
                    TaxCalculation.isInvoiced = isFinalized;
                }
                if(!isFinalized){
                    CO_Invoice_Header__c coInvRecOfTotal;

                    coInvRecOfTotal = PrintCustomerOrderInvoiceService.calculateInvoicePreviewTotals(new List<CO_Invoice_Header__c>{coInvoices[0]}, coliIds, sohIds, soPaymentRoleIds, cokhIds, dealIds, invoiceType);
                    coInvRec.Part_Total__c = coInvRecOfTotal.Part_Total__c;
                    coInvRec.Fee_Total__c = coInvRecOfTotal.Fee_Total__c;
                    coInvRec.Lien_Payout_Total__c = coInvRecOfTotal.Lien_Payout_Total__c;
                    coInvRec.Shop_Supplies_Total__c = coInvRecOfTotal.Shop_Supplies_Total__c;
                    coInvRec.Labour_Total__c = coInvRecOfTotal.Labour_Total__c;
                    coInvRec.F_I_Total__c = coInvRecOfTotal.F_I_Total__c;
                    coInvRec.Unit_Total__c = coInvRecOfTotal.Unit_Total__c;
                    coInvRec.Sublet_Total__c = coInvRecOfTotal.Sublet_Total__c;
                    coInvRec.Warranty_Product_Total__c = coInvRecOfTotal.Warranty_Product_Total__c;
                    coInvRec.Other_Product_Total__c = coInvRecOfTotal.Other_Product_Total__c;
                    coInvRec.SalesTax_Total__c = coInvRecOfTotal.SalesTax_Total__c;
                    coInvRec.Total__c = coInvRecOfTotal.Total__c;
                    coInvRec.Discount_Amount__c = coInvRecOfTotal.Discount_Amount__c;   
                    coInvRec.Stamp_Duty_Total__c = coInvRecOfTotal.Stamp_Duty_Total__c;
                    coInvRec.Deductible_Total__c = coInvRecOfTotal.Deductible_Total__c; 
                }
                Id coId = coInvoices[0].CO_Header__c;
                List<CO_Header__c> coHeadersList = getCustomerOrderHeaders(new List<Id>{coId}, coliIds);
                //System.assert(false, coHeadersList[0].CO_Line_Items__r);
                List<Service_Order_Header__c> soHeadersList = getServiceOrderHeaders(new List<Id>{coId}, sohIds);
                List<CO_Kit_Header__c> coKitHeadersList = getKitHeaders(new List<Id>{coId}, cokhIds);
                List<Deal_Item__c> dealItemList = getDealHeaders(new List<Id>{coId}, dealIds);// Added by kajal 12/08/2016 deal invoice
                List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coHeadersList[0].CO_Line_Items__r, coKitHeadersList);
                List<Deal_Finance__c> dealFinanceList = new List<Deal_Finance__c>();
                if(dealIds.size() > 0) {
                    dealFinanceList = SOQLUtil.getDealFinanceRecord(new Map<String, String>{'Deal__c' => dealIds[0]});
                }
                //System.assert(false, COKHList);             
                Map<String, String> unitIdToProductTypeIdMap = new Map<String, String>();
                for(Service_Order_Header__c soHeaderRec : soHeadersList) {
                    if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party' && soHeaderRec.SO_Payment_Roles__r.size() > 0) {
                        soPaymentRoleIds.add(soHeaderRec.SO_Payment_Roles__r[0].Id);
                    }
                    if(String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Product_type__c)) unitIdToProductTypeIdMap.put(soHeaderRec.Customer_Owned_Unit__c, soHeaderRec.Customer_Owned_Unit__r.Product_type__c);
                }

                Map<Id, Customer_Owned_Unit__c> unitIdToRecMap;
                if(!unitIdToProductTypeIdMap.isEmpty()) {
                    List<FilterJSON> filerObjList = new List<FilterJSON>{
                        new FilterJSON('Unit_Product_Type__c', 'IN', String.join(unitIdToProductTypeIdMap.values(), ',')),
                        new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
                        new FilterJSON('Include_In_SO_Document__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE)
                    };
                    UnitProductTypeService.OptionalFieldAPINameToRecMap = UnitProductTypeService.getUnitOptionalFieldAPINameToRecMap(filerObjList);
                    UnitProductTypeService.UnitDataFieldsAPINameToLabelMap = GeneralConfiguration.getUnitDataFieldsAPINameToLabelMap();
                    unitIdToRecMap = Unit_Service.getUnitIdToRecMap(unitIdToProductTypeIdMap.keySet(), Unit_Service.UnitPrimaryFields, new List<String>(UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()));
                }
                BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
                
                CustomerOrderInvoiceDetail coInvoiceDetailObj = new CustomerOrderInvoiceDetail(coInvRec, coHeadersList, 
                                                        soHeadersList, COKHList, coHeadersList[0].CO_Line_Items__r, coKitHeadersList, brandingLocationObj, dealItemList, dealFinanceList, unitIdToRecMap);
                
                if(displayMerchNotes) {
                    coInvoiceDetailObj.PartSalesNotes = (coHeadersList[0].Merchandise_Notes_For_Customer__c != null) ? ServiceJobService.getDeclineAddedNotesList(coHeadersList[0].Merchandise_Notes_For_Customer__c.split('\n')) : new List<String>();
                }
                
                List<Individual_Tax__c> individualItemsList = new List<Individual_Tax__c>();
                if(!coInvRec.CO_Header__r.Is_Legacy_CO__c) {
                    Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
                    if(!isFinalized) {TaxCalculation.isInvoiced = isFinalized;}
                    individualItemsList = COService.getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, coliIds, cokhIds, 
                                                                    sohTaxableItemIds, dealIds, soPaymentRoleIds);
                    
                    salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList, invoiceType);
                    TaxCalculation.isInvoiced = true;
                
                } else {
                    if(coInvRec.Legacy_Tax_Label_1__c != null && coInvRec.Legacy_Tax_Amount_1__c != null) {
                        salesTaxNameToTaxValue.put(coInvRec.Legacy_Tax_Label_1__c, coInvRec.Legacy_Tax_Amount_1__c);
                    }
                    if(coInvRec.Legacy_Tax_Label_2__c != null && coInvRec.Legacy_Tax_Amount_2__c != null) {
                        salesTaxNameToTaxValue.put(coInvRec.Legacy_Tax_Label_2__c, coInvRec.Legacy_Tax_Amount_2__c);
                    }
                    if(coInvRec.Legacy_Tax_Label_3__c != null && coInvRec.Legacy_Tax_Amount_3__c != null) {
                        salesTaxNameToTaxValue.put(coInvRec.Legacy_Tax_Label_3__c, coInvRec.Legacy_Tax_Amount_3__c);
                    }
                }
                
                coInvoiceDetailObj.COInvoice.SalesTaxList.addAll(TaxEngine.setTaxDetails(salesTaxNameToTaxValue));
                
                if(dealIds.size() == 0){
                    coInvoiceDetailObj.COInvoice.TotalTradeIns = 0;
                } else {
                	coInvoiceDetailObj.COInvoice.SoldBy = (!isFinalized || String.isBlank(coHeadersList[0].Deals__r[0].Salesperson_Name__c)) 
                								? coInvoiceDetailObj.COInvoice.SoldBy : coHeadersList[0].Deals__r[0].Salesperson_Name__c;
                }
                coInvoiceDetailObj.MerchSalespersons = (String.isNotBlank(coHeadersList[0].Salesperson_Names__c) ? coHeadersList[0].Salesperson_Names__c : coHeadersList[0].Owner__r.Name);
                String dealMerchSPNames = COSalespersonTriggerHelper.getNewSalespersonNames('', coHeadersList[0].CO_Salespersons__r);
                coInvoiceDetailObj.DealMerchSalespersons = (String.isNotBlank(dealMerchSPNames) ? dealMerchSPNames : coHeadersList[0].Owner__r.Name);
                coInvoiceDetails = System.JSON.serialize(coInvoiceDetailObj);// Edited by kajal 12/08/2016 deal invoice
            }
        /*} catch(Exception e) {
            coInvoiceDetails = '{}';
        }*/
        return coInvoiceDetails;
    }
        
    /**
     * Name: getCOInvoiceDetails
     * Desc: 
     * @param:  (1) coInvoiceIdStr
     * @return: String - JSON String
    **/
    @RemoteAction
    global static String getMerchandiseDetails(String coHeaderId, Boolean isAustralianMarket) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        List<CO_Line_Item__c> coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeaderId);
        List<CO_Kit_Header__c> coKitHeaders = SOQLUtil.getCOKHByCOHeaderId(coHeaderId);
        List<CO_Header__c> coHeadersList = getCustomerOrderDetails(coHeaderId);
        List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coLineItems, coKitHeaders);
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        
        BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
        brandingLocationObj.setDefaultBrandingLocation((businessProfileList.size() > 0 ? businessProfileList[0] : new Business_Profile__c()));
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
                taxValue += (individualTaxRec.Tax_Rate__c * coLineItemRec.Qty__c * coLineItemRec.Price__c) / 100;
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
        List<CustomerMerchandies> cusRec =  new  List<CustomerMerchandies>();
        for(CO_Header__c coHeaderRec : coHeadersList ){
            cusRec.add(new CustomerMerchandies(coHeaderRec) );
        }
        
        CO_Invoice_Header__c coHeaderInvoiceRec = new CO_Invoice_Header__c();
        if(coHeadersList.size() > 0) {
            coHeaderInvoiceRec = (coHeadersList[0].CO_Invoice_Headers__r.size() > 0) ? coHeadersList[0].CO_Invoice_Headers__r[0] : new CO_Invoice_Header__c();
        }
        
        COMerchandiseDetail COMerchandiseDetailObj = new COMerchandiseDetail();
        if(coLineItems.size() > 0) {
            COMerchandiseDetailObj = new COMerchandiseDetail(COKHList, subtotal, salesTax, priceOverrides, total_Part, total_Laobur, total_Sublet, total_Fee, salesTaxNameToTaxValue, cusRec, coHeaderInvoiceRec, brandingLocationObj);
        }
        System.debug(COMerchandiseDetailObj);
        return BPUtility.getEncodedString(System.JSON.serialize(COMerchandiseDetailObj));
    }
    
    /**
     * Name: CustomerOrderInvoice
     * Description: Wrapper class
     * 
    **/
    public class CustomerOrderInvoiceDetail {
        public COInvoiceDetail COInvoice {get; set;}
        public List<TransactionDetail> Transactions {get; set;}
        public List<MerchandiseDetail> Merchandises {get; set;}
        public List<COHeaderWrapper.COKitHeader> DealCOKHList {get; set;}
        public List<COHeaderWrapper.COKitHeader> COKHList {get; set;} 
        public List<ServiceDetail> Services {get; set;}
        public Boolean IsShowProviderInfoOnPrintPage {get; set;}
        public Boolean IsHideHoursRateOnServiceDocuments{get; private set;}
        public Boolean IsTaxIncludingPricing {get; set;}
        public Boolean IsItemizedByLaborCode {get; set;}
        public CustomerDetail.Company CompanyInfo {get; set;}
        public DealDetails DealInfo {get; set;}
        public String CO_Header_Id {get; set;}   // Ticket:1984: Added By Pooja 15 May 2017
        public Decimal AmountPaid {get; set;} 
        public Decimal BalanceDue {get; set;}
        //public Decimal TotalDeductible {get; set;} 
        public String CustomerInvoiceWarrantyText{get; set;}
        public Boolean IsSignatureLineforCustomerInvoice{get; set;}
        public String OrderStatus {get; set;}
        public List<String> PartSalesNotes {get; private set;}
        public String MerchSalespersons {get; private set;}
        public String DealMerchSalespersons {get; set;}
         
        public CustomerOrderInvoiceDetail(CO_Invoice_Header__c coInvoiceHeader,
                                    List<CO_Header__c> coHeadersList, 
                                    List<Service_Order_Header__c> soHeadersList,
                                    List<COHeaderWrapper.COKitHeader> COKHList,
                                    List<CO_Line_Item__c> coliList,
                                    List<CO_Kit_Header__c> coKitHeadersList,
                                    BrandingLocationWrapper brandingLocationObj,
                                    List<Deal_Item__c>  dealItemList,
                                    List<Deal_Finance__c> dealFinanceList, 
                                    Map<Id, Customer_Owned_Unit__c> unitIdToRecMap
                                ) {
            this.CO_Header_Id = coHeadersList[0].Name;  // Ticket:1984: Added By Pooja 15 May 2017       
            this.OrderStatus = coHeadersList[0].Order_status__c;
            this.PartSalesNotes = new List<String>();
            this.COInvoice = new COInvoiceDetail(coInvoiceHeader);
            this.IsHideHoursRateOnServiceDocuments = GeneralConfiguration.isHideHoursRateOnServiceDocument();
            this.IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.IsItemizedByLaborCode = GeneralConfiguration.isCalculationMethodAvailable() && GeneralConfiguration.isItemizedByLaborCode();
            this.Transactions = new List<TransactionDetail>();
            
            Decimal amountPaidByFinance = 0;
            Decimal amountPaidByCustomer = 0;
	        if(dealFinanceList != null && dealFinanceList.size() > 0) {
                for(CO_Deposit__c coDepositRec : coHeadersList[0].CO_Deposits__r) {
                    if(coDepositRec.Payment_Method__c != 'Invoice') {
                        coDepositRec.Amount__c = coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
                        if(coDepositRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
                            amountPaidByFinance += coDepositRec.Amount__c;
                        } else {
                            amountPaidByCustomer += coDepositRec.Amount__c;
                        }
                    }
                }
            }

            this.DealInfo = new DealDetails(dealItemList, dealFinanceList);
            if(dealFinanceList.size() > 0 && coHeadersList[0].Deals__r[0].Status__c != 'Invoiced') {
                this.DealInfo.DealFinanceObj.DownPayment = this.DealInfo.DealFinanceObj.DownPayment != null ? this.DealInfo.dealFinanceObj.DownPayment : 0;
                this.DealInfo.DueFromCustomer = this.DealInfo.DealFinanceObj.DownPayment - amountPaidByCustomer;
                Decimal amountFinanced = (coHeadersList[0].Deal_Total__c - this.DealInfo.dealFinanceObj.DownPayment);
                this.DealInfo.DueFromFinancing = DealService.getActualAmountFinanced(amountFinanced, this.DealInfo.DealFinanceObj, this.IsTaxIncludingPricing) - amountPaidByFinance;
                this.DealInfo.DueFromFinancing = (this.DealInfo.DueFromFinancing < 0 ? 0 : this.DealInfo.DueFromFinancing);
            }
            
            Decimal usedDealDeposit = 0;
            this.AmountPaid = 0;
            if(coInvoiceHeader.CO_Invoice_Payments__r != null && coInvoiceHeader.CO_Invoice_Payments__r.size() > 0) {
                for(CO_Invoice_Payment__c coPaymentRec : coInvoiceHeader.CO_Invoice_Payments__r) {
                    coPaymentRec.Amount__c = coPaymentRec.Amount__c != null ? coPaymentRec.Amount__c : 0;
                    if(String.isBlank(coPaymentRec.Reverse_Link__c) && !coPaymentRec.Payment_Method__c.equalsIgnoreCase('Financing') &&
                      (String.isBlank(coPaymentRec.Deposit_Payment_Method__c) || !coPaymentRec.Deposit_Payment_Method__c.equalsIgnoreCase('Financing'))) {
                        if(coPaymentRec.Payment_Method__c.equalsIgnoreCase('Use Deal Deposit') && this.DealInfo.DealFinanceObj != null) {
                            if(usedDealDeposit < this.DealInfo.DealFinanceObj.DownPayment) {
                                TransactionDetail txnObj = new TransactionDetail(coPaymentRec);
                                txnObj.Amount = ((usedDealDeposit + coPaymentRec.Amount__c) <= this.DealInfo.DealFinanceObj.DownPayment ? coPaymentRec.Amount__c : (this.DealInfo.DealFinanceObj.DownPayment - usedDealDeposit));
                                usedDealDeposit += txnObj.Amount;
                                this.Transactions.add(txnObj);
                            }
                        } else {
                    this.Transactions.add(new TransactionDetail(coPaymentRec));
                }
                    if(coPaymentRec.Payment_Method__c != 'Charge Account') {
                        this.AmountPaid += coPaymentRec.Amount__c;
                    }
                }
            }      
            }      
            this.Merchandises = new List<MerchandiseDetail>();           
            if(coliList != null) {
                //System.assert(false, coliList.size());
                for(CO_Line_Item__c coliRec : coliList) {
                    this.Merchandises.add(new MerchandiseDetail(COInvoice, coliRec));
                } 
            }
            if(coKitHeadersList != null) {
                for(CO_Kit_Header__c COKH : coKitHeadersList){
                    if(COKH.CO_Line_Items__r != null){
                        for(CO_Line_Item__c coliRec : COKH.CO_Line_Items__r) {
                            this.Merchandises.add(new MerchandiseDetail(COInvoice, coliRec));
                        } 
                    }
                }
            }           
            this.Services = new List<ServiceDetail>();
            //this.TotalDeductible = 0;
            if(coHeadersList != null) {
                Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKitHeaderListMap = getSOIdToSOKitHeaderListMap(soHeadersList);
                for(Service_Order_Header__c soHeader: soHeadersList) {
                    List<Service_Order_Kit_Header__c> sokhList = soHeaderIdToSOKitHeaderListMap.containsKey(soHeader.Id) ? soHeaderIdToSOKitHeaderListMap.get(soHeader.Id) : new List<Service_Order_Kit_Header__c>();
                    Customer_Owned_Unit__c unitRec = unitIdToRecMap != null ? unitIdToRecMap.get(soHeader.Customer_Owned_Unit__c) : soHeader.Customer_Owned_Unit__r;
                    ServiceDetail serviceObj = new ServiceDetail(COInvoice, soHeader, sokhList, unitRec);
                    /* if(serviceObj.ProviderDetail != null && serviceObj.ProviderDetail.TotalThirdPartyDeductibleAmount != null) {
                    	this.TotalDeductible -= serviceObj.ProviderDetail.TotalThirdPartyDeductibleAmount;
                    } */
                    this.Services.add(serviceObj);
                }
            }
            
            this.COKHList = new List<COHeaderWrapper.COKitHeader>();
            this.DealCOKHList = new List<COHeaderWrapper.COKitHeader>();
            for(COHeaderWrapper.COKitHeader kitHeader : COKHList){
                if((String.isNotBlank(kitHeader.id) && String.isNotBlank(kitHeader.DealId)) || (String.isBlank(kitHeader.id) && kitHeader.COLIList.size() > 0 && String.isNotBlank(kitHeader.COLIList[0].DealId))) {
                    this.DealCOKHList.add(kitHeader);
                } else {
                    this.COKHList.add(kitHeader);
                }
            }
            if(brandingLocationObj != null) {
            	this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
                this.CustomerInvoiceWarrantyText = (brandingLocationObj.DisclaimerforCustomerInvoice != null) ? brandingLocationObj.DisclaimerforCustomerInvoice : '';
                this.IsSignatureLineforCustomerInvoice = brandingLocationObj.IsSignatureforCustomerInvoice;
            }
            
            // Added By Pooja 13 Feb. 2017
            this.CompanyInfo.BusinessPhone = this.CompanyInfo.FormattedBusinessPhone != null ? this.CompanyInfo.FormattedBusinessPhone: '';
            
            /*this.DealItemList = new List<DealWrapper.UnitSectionWrapper>();
            for(Deal_Item__c dealItemRec : dealItemList) {
                this.DealItemList.add(new DealWrapper.UnitSectionWrapper(dealItemRec));
            }*/
            
            for(DealUnitDetails dealUnitRec : DealInfo.UnitList) {
                Decimal unitTotal = dealUnitRec.BaseUnitPriceTotal;
                
                for(DealWrapper.FactoryOption factoryRec : dealUnitRec.FactoryOptionList) {
                    unitTotal += factoryRec.TotalPrice;
                }
                for(DealWrapper.DealerInstalledOption dealerRec : dealUnitRec.DealerOptionList) {
                    unitTotal += dealerRec.TotalPrice;
                }
                dealUnitRec.DealUnitPriceAndCostTotal = unitTotal;
            }
            
            if(coHeadersList.size() > 0 && coHeadersList[0].Deals__r.size() > 0 && dealItemList.size() > 0){
                this.DealInfo.DealTotal = (coHeadersList[0].Deal_Total__c != null ? coHeadersList[0].Deal_Total__c : 0);
                this.COInvoice.TotalTradeIns = (coHeadersList[0].Deals__r[0].Trade_In_Total__c != null ? coHeadersList[0].Deals__r[0].Trade_In_Total__c : 0);   
                this.COInvoice.SubTotal = this.COInvoice.SubTotal + this.COInvoice.TotalTradeIns;
            	this.COInvoice.Total += this.COInvoice.TotalTradeIns;
            }
        	
        	this.IsShowProviderInfoOnPrintPage = false;
        	if((coInvoiceHeader.Status__c == 'Closed' && coInvoiceHeader.Checkout_Type__c == 'Third-Party') || 
        			(coInvoiceHeader.Status__c == 'Active' && dealItemList.size() == 0 && coliList.size() == 0 && coKitHeadersList.size() == 0 
            		&& soHeadersList.size() > 0 && soHeadersList[0].Provider__c != null)) {
            	String providerId = soHeadersList[0].Provider__c;
            	for(Service_Order_Header__c soHeader : soHeadersList) {
            		if(soHeader.Provider__c != null && providerId == soHeader.Provider__c) {
            			this.IsShowProviderInfoOnPrintPage = true;
            		} else {
            			this.IsShowProviderInfoOnPrintPage = false;
            			break;
            		}
            	}
            }
            
            Decimal invTotal = (this.IsTaxIncludingPricing ? this.COInvoice.SubTotal : this.COInvoice.Total);
            if(this.AmountPaid > invTotal) {
                this.AmountPaid = invTotal;
	            }
            this.BalanceDue = invTotal - this.AmountPaid;
            /* if(coInvoiceHeader.Status__c != 'Closed') {
                this.BalanceDue += this.TotalDeductible;
            } */
	    }
    }
    
    /**
     * Name: COInvoiceDetail
     * Description: Wrapper class
     * 
    **/
    public class COInvoiceDetail {
        public String StoreCityProv {get; private set;}
        public String StorePostal {get; private set;}
        public String StoreBusinessNumber {get; private set;}
        public String StoreWebsite {get; private set;}
        
        
        public String COType {get; private set;}
        public String CustomerName {get; private set;}
        public String CustomerNumber {get; private set;}
        public String CustomerPONumber {get; private set;}
        public String CustomerAddress {get; private set;}
        public String CustomerAddress2 {get; private set;}
        public String CustomerCityProv {get; private set;}
        public String CustomerPostal {get; private set;}
        public String CustomerState {get; private set;}
        public String CheckoutType {get; private set;}
        public String CustomerEmail {get; private set;}
        public String CustomerPhone {get; private set;}
        
        public String InvoiceId {get; private set;}
        public String InvoiceNumber {get; private set;}
        public String InvoiceDate {get; private set;}
        public Date InvoiceDateOnly {get; private set;}
        public String FormattedInvoiceDate {get; private set;}
        public String Status {get; private set;}
        public String SoldBy {get; private set;}
        
        public Decimal TotalUnits {get; private set;}
        public Decimal TotalTradeIns {get; private set;}
        public Decimal TotalLienPayout {get; private set;}
        public Decimal TotalWarranty {get; private set;}
        public Decimal TotalOtherProducts {get; private set;}
        public Decimal TotalParts {get; private set;}
        public Decimal TotalLabour {get; private set;}
        public Decimal TotalSublet {get; private set;}
        public Decimal TotalFees {get; private set;}
        public Decimal TotalShopSupplies {get; private set;}
        public Decimal StampDuty {get; private set;}
        public Decimal SubTotal {get; private set;}
        public Decimal TotalFinanceProducts {get; private set;}
        public String CompanyLocale {get; private set;}
        public Decimal SalesTax {get; private set;}
        public Decimal Total {get; private set;}
        public Decimal MerchandiseTotal {get; private set;}
        public Decimal DealMerchandiseTotal {get; private set;}
        public String CurrentDate {get; private set;} // Ticket:1984: Added By Pooja 15 May 2017
        public String FormattedCurrentDate {get; private set;} 
        public Decimal DiscountAmount {get; private set;}
        public Boolean IsDisplayDiscountAmount {get; private set;}
        public Decimal TotalDeductible {get; private set;}
        public List<TaxDetail> SalesTaxList {get; private set;}
        public List<CO_Invoice_Item__c> COInvoiceItems {get; private set;}
        public String COInvoiceStatus {get; private set;}
        public Boolean hasChargeOnAccountPayment;
        
        public COInvoiceDetail(CO_Invoice_Header__c coInvoiceHeader) {
            TotalTradeIns = 0;
            TotalUnits = 0;
            TotalParts  = 0;
            TotalLabour = 0;
            TotalSublet = 0;
            TotalFees   = 0;
            TotalShopSupplies = 0;
            SubTotal    = 0;
            StampDuty   = 0;
            SalesTax    = 0;
            Total       = 0;
            MerchandiseTotal = 0;
            DealMerchandiseTotal = 0;
            TotalLienPayout = 0;
            CurrentDate =  BPUtility.getFormatedDateTime(System.now());  // Ticket:1984: Added By Pooja 15 May 2017
            this.FormattedCurrentDate = (System.now()).format('MMMM dd, yyyy');
            if(coInvoiceHeader != null) {
                this.hasChargeOnAccountPayment = (coInvoiceHeader.Total_Charge_On_Account__c != null && coInvoiceHeader.Total_Charge_On_Account__c != 0);
                this.COType  = coInvoiceHeader.CO_Header__r.CO_Type__c;
                CustomerName        = coInvoiceHeader.CO_Header__r.Customer__r.Name;
                CustomerNumber = coInvoiceHeader.CO_Header__r.Customer__r.Customer_Number__c;
                this.CustomerPONumber = coInvoiceHeader.CO_Header__r.Customer_PO_Number__c;
                String billingStreet = (coInvoiceHeader.CO_Header__r.Customer__r.BillingStreet == null ) ? '' : coInvoiceHeader.CO_Header__r.Customer__r.BillingStreet;

                List<String> bsList = billingStreet.split('\n');
                this.CustomerAddress = (bsList.size() > 0) ? bsList[0].replace(',', ' ') : '';
                this.CustomerAddress2 = (bsList.size() > 1) ? bsList[1].replace(',', ' ') : '';
                CustomerCityProv    = coInvoiceHeader.CO_Header__r.Customer__r.BillingCity;
                CustomerCityProv    = (CustomerCityProv != null && CustomerCityProv != '') ? (CustomerCityProv ) : '';
                CustomerPostal      = coInvoiceHeader.CO_Header__r.Customer__r.BillingPostalCode;
                CustomerState      = coInvoiceHeader.CO_Header__r.Customer__r.BillingState;
                
                if(coInvoiceHeader.CO_Header__r.Customer__r.Preferred_Email__c == null) {
                if(coInvoiceHeader.CO_Header__r.Customer__r.Email__c != null) {
                    this.CustomerEmail = coInvoiceHeader.CO_Header__r.Customer__r.Email__c;
                } else if(coInvoiceHeader.CO_Header__r.Customer__r.Work_Email__c != null) {
                    this.CustomerEmail = coInvoiceHeader.CO_Header__r.Customer__r.Work_Email__c;
                } else if(coInvoiceHeader.CO_Header__r.Customer__r.Other_Email__c != null) {
                    this.CustomerEmail = coInvoiceHeader.CO_Header__r.Customer__r.Other_Email__c;
                }
                } else {
                    this.CustomerEmail = coInvoiceHeader.CO_Header__r.Customer__r.Preferred_Email__c;
                }
                
                 if(coInvoiceHeader.CO_Header__r.Customer__r.Preferred_Phone__c == null) {
                                if(coInvoiceHeader.CO_Header__r.Customer__r.Home_Number__c != null) {
                                        this.CustomerPhone = coInvoiceHeader.CO_Header__r.Customer__r.Formatted_Home_number__c;
                                } else if(coInvoiceHeader.CO_Header__r.Customer__r.Mobile__c != null) {
                                        this.CustomerPhone = coInvoiceHeader.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
                                } else if(coInvoiceHeader.CO_Header__r.Customer__r.Work_Number__c != null) {
                                        this.CustomerPhone = coInvoiceHeader.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                                }
                        } else {
                                this.CustomerPhone = coInvoiceHeader.CO_Header__r.Customer__r.Formatted_Preferred_Phone__c;
                        }                
                InvoiceId       = coInvoiceHeader.Id;
                InvoiceNumber   = (coInvoiceHeader.Invoice_Number__c == null) ? '' : coInvoiceHeader.Invoice_Number__c;
                //InvoiceDate     = coInvoiceHeader.CreatedDate.format('MM/dd/yyyy');
                InvoiceDate     = (coInvoiceHeader.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(coInvoiceHeader.Invoice_Date__c) : '';
                this.InvoiceDateOnly = coInvoiceHeader.Invoice_Date_Formula__c;
                this.FormattedInvoiceDate = (coInvoiceHeader.Invoice_Date__c != null) ? (coInvoiceHeader.Invoice_Date__c).format('MMMM dd, yyyy') : '';
                Status          = coInvoiceHeader.Status__c;
                SoldBy          = coInvoiceHeader.CreatedBy.Name;
                
                this.CompanyLocale = GeneralConfiguration.getCompanyLocale();
                this.IsDisplayDiscountAmount = coInvoiceHeader.Is_Discount_Shown__c;
                this.DiscountAmount = (coInvoiceHeader.Discount_Amount__c != null) ? coInvoiceHeader.Discount_Amount__c : 0;
                this.CheckoutType = coInvoiceHeader.Checkout_Type__c;
                this.TotalUnits = (coInvoiceHeader.Unit_Total__c != null ? coInvoiceHeader.Unit_Total__c : 0);
                
                this.TotalWarranty = (coInvoiceHeader.Warranty_Product_Total__c != null ? coInvoiceHeader.Warranty_Product_Total__c : 0);
                this.TotalOtherProducts = (coInvoiceHeader.Other_Product_Total__c != null ? coInvoiceHeader.Other_Product_Total__c : 0);
                this.TotalParts = (coInvoiceHeader.Part_Total__c != null ? coInvoiceHeader.Part_Total__c : 0);
                this.TotalLabour = (coInvoiceHeader.Labour_Total__c != null ? coInvoiceHeader.Labour_Total__c : 0);
                this.TotalSublet = (coInvoiceHeader.Sublet_Total__c != null ? coInvoiceHeader.Sublet_Total__c : 0);
                this.TotalFees = (coInvoiceHeader.Fee_Total__c != null ? coInvoiceHeader.Fee_Total__c : 0);
                this.TotalLienPayout = (coInvoiceHeader.Lien_Payout_Total__c != null ? coInvoiceHeader.Lien_Payout_Total__c : 0);
                this.TotalShopSupplies = (coInvoiceHeader.Shop_Supplies_Total__c != null ? coInvoiceHeader.Shop_Supplies_Total__c : 0);
                this.TotalFinanceProducts = (coInvoiceHeader.F_I_Total__c != null ? coInvoiceHeader.F_I_Total__c : 0);
                this.StampDuty = (coInvoiceHeader.Stamp_Duty_Total__c != null ? coInvoiceHeader.Stamp_Duty_Total__c : 0);
                
                this.TotalDeductible = (coInvoiceHeader.Deductible_Total__c != null ? coInvoiceHeader.Deductible_Total__c : 0);
                this.SalesTax = (coInvoiceHeader.SalesTax_Total__c != null ? coInvoiceHeader.SalesTax_Total__c : 0);
                
                if(String.isNotBlank(coInvoiceHeader.Checkout_Type__c) && coInvoiceHeader.Checkout_Type__c != 'Customer' && coInvoiceHeader.Checkout_Type__c != 'Third-Party') {
                    this.TotalDeductible = 0;
                }
                
                this.SubTotal = this.TotalUnits + this.TotalParts + this.TotalLabour + this.TotalSublet + this.TotalFees + this.TotalLienPayout + this.TotalWarranty + 
                                this.TotalOtherProducts + this.StampDuty + this.TotalShopSupplies + this.TotalDeductible + this.TotalFinanceProducts;
                this.Total = GeneralConfiguration.getTaxIncludingPricing() ? this.SubTotal : this.SubTotal + this.SalesTax;                
                this.COInvoiceItems = coInvoiceHeader.CO_Invoice_Items__r != null ? coInvoiceHeader.CO_Invoice_Items__r : null;
                this.COInvoiceStatus = coInvoiceHeader.Status__c;
            }
            this.SalesTaxList = new List<TaxDetail>();
        }

    }  
    
    /**
     * Name: TransactionDetail
     * Description: Wrapper class
     * 
    **/
    public class TransactionDetail {
        public boolean IsDeposit {get; private set;}
        public boolean IsPayment {get; private set;}
        public String Method {get; private set;}
        public String TransactionDate {get; private set;}
        public Date TransactionDateOnly {get; private set;}
        public decimal Amount {get; private set;}
        public String ReferenceNo {get; private set;}
        
        public TransactionDetail(CO_Deposit__c coDepositRec) {
            IsDeposit   = true;
            IsPayment   = false;
            Method      = coDepositRec.Payment_Method__c;
            Amount      = coDepositRec.Amount__c;
            TransactionDate = (coDepositRec.Payment_Date__c != null) ? BPUtility.getFormatedDateTime(coDepositRec.Payment_Date__c) : BPUtility.getFormatedDateTime(Date.today());
        	TransactionDateOnly = coDepositRec.Payment_Date__c;
            ReferenceNo = String.isNotBlank(coDepositRec.Reference__c) ? coDepositRec.Reference__c : '';
        }
        
        public TransactionDetail(CO_Invoice_Payment__c coPaymentRec) {
            IsPayment   = true;
            IsDeposit   = false;
            Method      = coPaymentRec.Payment_Method__c;
            Amount      = coPaymentRec.Amount__c;
            TransactionDate = (coPaymentRec.Payment_Date__c != null) ? BPUtility.getFormatedDateTime(coPaymentRec.Payment_Date__c) : BPUtility.getFormatedDateTime(Date.today());
        	TransactionDateOnly = coPaymentRec.Payment_Date__c;
            ReferenceNo = String.isNotBlank(coPaymentRec.Reference__c) ? coPaymentRec.Reference__c : '';
        }
    }
    
     public static List<CO_Header__c> getCustomerOrderDetails(Id CoheaderId) {
         List<CO_Header__c> coHeaderRec = [SELECT Id, 
                                                        Name,
                                                        Status__c,
                                                        CreatedDate,
                                                        CreatedBy.Name,
                                                        Customer__c,
                                                        CO_Type__c,
                                                        Salesperson_Names__c,
                                                        Owner__r.Name,
                                                        Customer_PO_Number__c,
                                                        Customer__r.Name,
                                                        Customer__r.BillingStreet,
                                                        Customer__r.BillingCity,
                                                        Customer__r.BillingState,
                                                        Customer__r.BillingPostalCode,
                                                        Customer__r.BillingCountry,
                                                        Customer__r.ShippingStreet,
                                                        Customer__r.ShippingCity,
                                                        Customer__r.ShippingState,
                                                        Customer__r.ShippingPostalCode,
                                                        Customer__r.ShippingCountry,
                                                        Customer__r.Preferred_Phone__c,
                                                        Customer__r.Preferred_Email__c,
                                                        Customer__r.Formatted_Preferred_Phone__c,
                                                        Customer__r.Formatted_Work_Number__c,
                                                        Customer__r.Formatted_Mobile_Number__c,
                                                        Customer__r.Formatted_Home_number__c,                                                       
                                                        Customer__r.Email__c,
                                                        Customer__r.Work_Email__c,
                                                        Customer__r.Other_Email__c,                                                       
                                                        Customer__r.Customer_Number__c,
                                                        (Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null AND Deal__c != null Order By CreatedDate),
                                                        (Select Name, Invoice_Date__c, Invoice_Number__c, CreatedBy.Name, Status__c, Is_Discount_Shown__c, Discount_Amount__c From CO_Invoice_Headers__r 
                                                                where Status__c = 'Closed' Order By LastModifiedDate Desc limit 1)
                                                        from CO_Header__c WHERE Id =: CoheaderId
                                       ];
        return coHeaderRec;
     }
    
    public class MerchandiseDetail {
        public String Type {get; private set;}
        public String ItemDesc {get; private set;}
        public String ItemCode {get; private set;}
        public String ItemDescription {get; private set;}
        public decimal Qty {get; private set;}
        public decimal Price {get; private set;}
        public decimal Total {get; private set;}
        
        public MerchandiseDetail(COInvoiceDetail coInvoice, CO_Line_Item__c coli) {
            this.ItemCode = (coli.Item_Code__c != null) ? coli.Item_Code__c : '';
            this.ItemDescription = (coli.Item_Description__c != null) ? coli.Item_Description__c : '';
            this.ItemDesc = this.ItemCode + ' - ' + this.ItemDescription;
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            coli.Tax__c = (coli.Tax__c != null) ? coli.Tax__c : 0;
            coli.Price__c = (coli.Price__c != null) ? coli.Price__c : 0;
            coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
            coli.Qty_Committed__c = (coli.Qty_Committed__c != null) ? coli.Qty_Committed__c : 0;
            
            this.Qty = (coli.Part__c != null && !coli.Part__r.Non_Inventory_Part__c && coli.Qty__c > 0 && (coli.Qty__c != coli.Qty_Committed__c)
                        && coli.CO_Header__r.Order_Status__c != 'Quote') ? coli.Qty_Committed__c : coli.Qty__c;
               
            if(coli.Fee__c != null) {
                this.Type = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Fee');
            } else if(coli.Part__c != null) {
                this.Type = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Part');
            } else {
                this.Type = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Labour');
            }
            
            if(isTaxIncludingPricing) {
                if(coli.Deal__c != null) {
                    Price = (coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    Decimal taxAmount = (coli.Price__c * coli.Tax__c / 100);
                    Price = (coli.Price__c + taxAmount).setScale(2, RoundingMode.HALF_UP);
                }
                Total = Price * Qty;
            } else {
                Price = coli.Price__c;
                Total = (coli.Part__c != null && !coli.Part__r.Non_Inventory_Part__c && coli.Qty__c > 0 && (coli.Qty__c != coli.Qty_Committed__c) && coli.CO_Header__r.Order_Status__c != 'Quote') ? (coli.Price__c * coli.Qty_Committed__c) : coli.Sub_Total_Without_Tax__c;
            }
            
            if(coli.Deal__c != null) {
                coInvoice.DealMerchandiseTotal += this.Total;
            } else {
                coInvoice.MerchandiseTotal += this.Total;
            }
        }
    }
    
    /**
    * Namae: ProviderDetail
    * Description: Wrapper Modal class
    */
    public class ProviderDetail {
        public String Name {get; private set;}
        public String AddressLine1 {get; private set;}
        public String AddressLine2 {get; private set;}
        public String AddressLine3 {get; private set;}
        public String AddressLine4 {get; private set;}
        public String ClaimNumber {get; private set;}
        public Decimal TotalThirdPartyDeductibleAmount {get; private set;} 
        public String VendorTaxId {get; private set;}
        
        public ProviderDetail(String name, System.Address billingAddress, String claimNumber, Decimal totalThirdPartyDeductibleAmount, String vendorTaxId) {
            this.Name = name;
            List<String> bsList = (billingAddress.street != null)? billingAddress.street.split('\n') : null;
            this.AddressLine1 = (bsList != null && bsList.size() > 0) ? bsList[0] : '';
            this.AddressLine2 = (bsList != null && bsList.size() > 1) ? bsList[1] : '';
            this.AddressLine3 = billingAddress.city;
            this.AddressLine3 = (billingAddress.city != null && billingAddress.city != '') ? (billingAddress.city + ', ' + billingAddress.state) : billingAddress.state;
            this.AddressLine4 = billingAddress.postalCode;
            this.ClaimNumber = claimNumber;
            this.TotalThirdPartyDeductibleAmount = totalThirdPartyDeductibleAmount;
            this.VendorTaxId = vendorTaxId;
        }
    }
    
    /**
     * Name: ServiceDetail
     * Description: Wrapper class
     * 
    **/
    public class ServiceDetail {
        public String Name {get; private set;}
        public decimal Total {get; private set;}
        public Boolean IsDealService {get; private set;}
        public decimal MileageIn {get; private set;}
        public decimal MileageOut {get; private set;}
        public String MileageType {get; private set;}
        public String Unit {get; private set;} 
        public ServiceJobWorksheetWrapper.UnitInfoWrapper UnitDetails{get; private set;}
        public List<String> Notes {get; private set;}
        public Decimal ShopSupplyTotal {get; private set;}
        public Set<String> ShopSupplyDetailSet {get; private set;}
        public Boolean isShopSupplySetValid {get; private set;}
        public String transactionType {get; private set;} 
        public String Salespersons {get; private set;} 
        
        /* Start: Added by richa 06/04/2017 */
        public List<String> CauseList {get; private set;}
        public List<String> CorrectionList {get; private set;}
        public List<String> ConcernList {get; private set;}
        /* End: Added by richa 06/04/2017 */
        
        public List<ServiceItemsDetail> ServiceItems {get; private set;}
        public List<SOHeaderWrapper.SOGrid> SOGridItems {get; private set;}
        public Boolean isDeductibleInvItem {get; private set;}
        public ProviderDetail ProviderDetail {get; private set;}
        
        public ServiceDetail(COInvoiceDetail coInvoice, Service_Order_Header__c soHeader, Customer_Owned_Unit__c unitRec) {
            this.IsDealService = soHeader.Deal__c != null ? true : false;
            this.Salespersons = (String.isNotBlank(soHeader.Salesperson_Names__c) ? soHeader.Salesperson_Names__c : soHeader.CO_Header__r.Owner__r.Name);
            this.isDeductibleInvItem = false;
            this.transactionType = (soHeader.Transaction_Type__c != null && soHeader.Transaction_Type__r.Type__c != null) ? soHeader.Transaction_Type__r.Type__c : '';
            Decimal DeductibleAmount = 0;
            if(coInvoice.COInvoiceItems != null) {
                for(CO_Invoice_Item__c coInvoiceItem: coInvoice.COInvoiceItems) {
                    if(coInvoiceItem.Service_Order_Header__c == soHeader.Id) {
                        if(coInvoiceItem.SO_Payment_Role__r != null && coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') {
                            this.isDeductibleInvItem = true;
                            DeductibleAmount = coInvoiceItem.SO_Payment_Role__r.Total_Amount__c;
                            break;
                        }
                    }
                 }
             }
            
            // Service details
            Name    = soHeader.Name__c;
            Total   = 0;

            /* Start: Commented and Added by richa 06/04/2017 */
            /* Correction  = soHeader.SO_Correction__c;
            Cause   = soHeader.SO_Cause__c;
            Concern = soHeader.SO_Concern__c; */
            
            this.CauseList = (soHeader.SO_Cause__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Cause__c.split('\n')) : new List<String>();
            this.CorrectionList = (soHeader.SO_Correction__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Correction__c.split('\n')) : new List<String>();
            this.ConcernList = (soHeader.SO_Concern__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Concern__c.split('\n')) : new List<String>();
            Unit = '';
            /* End: Commented and Added by richa 06/04/2017 */

            this.Notes = (soHeader.SO_Notes_For_Customer__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Notes_For_Customer__c.split('\n')) : new List<String>();

            if(soHeader.Customer_Owned_Unit__c != null) {
                Boolean showDash = false;
                MileageIn   = soHeader.Odometer_on_Arrival__c;
                MileageOut  = soHeader.Odometer_on_Departure__c;
                MileageType = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Mileage_Type__c') && String.isNotBlank(unitRec.Mileage_Type__c) ? unitRec.Mileage_Type__c : null;
                if(soHeader.Customer_Owned_Unit__r.Year__c != null) {
                    Unit += soHeader.Customer_Owned_Unit__r.Year__c;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name !=null && soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null && soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
                    showDash = true;
                }
                
                if(soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null && soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.VIN_Number__c != null) {
                    if(showDash) {
                        Unit += ' - ';
                    }
                    Unit += soHeader.Customer_Owned_Unit__r.VIN_Number__c;
                }
                if(UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Plate__c') && String.isNotBlank(unitRec.Plate__c)) Unit += ' - ' + unitRec.Plate__c;
                UnitDetails = new ServiceJobWorksheetWrapper.UnitInfoWrapper(unitRec);
            }
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            // Service Line Items
            ServiceItems = new List<ServiceItemsDetail>();
            if(soHeader != null && soHeader.Service_Order_Line_Items__r != null) {
                for(Service_Order_Line_Item__c soli : soHeader.Service_Order_Line_Items__r) {
                    ServiceItems.add(new ServiceItemsDetail(coInvoice, soli));
                    if(isTaxIncludingPricing) {
                        decimal Price = 0;
                        if(soli.Deal_Item__c != null) {
                            Price = (soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                        } else {
                            Decimal taxAmount = (soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                            Price = (soli.Kit_Price__c + taxAmount).setScale(2, RoundingMode.HALF_UP);
                        }
                        //this.Total += Price * soli.Qty_Needed__c;
                    } else {
                        //this.Total += soli.Kit_Price__c * soli.Qty_Needed__c;
                    }
                }
            }
            if(!this.isDeductibleInvItem) {
                this.Total = soHeader.Total__c;
            } else {
                this.Total = DeductibleAmount;
            }
            
            if(soHeader.Provider__c != null) {
                Decimal thirdPartyDeductibleAmount = 0;
                if(!soHeader.SO_Payment_Roles__r.isEmpty()) {
                    for(SO_Payment_Role__c soPaymentRole: soHeader.SO_Payment_Roles__r) {
                        thirdPartyDeductibleAmount += soPaymentRole.Total_Amount__c;
                    }
                }
                this.ProviderDetail = new ProviderDetail(soHeader.Provider__r.Name, soHeader.Provider__r.BillingAddress, (!soHeader.Claims__r.isEmpty()) ? soHeader.Claims__r[0].Provider_Claim_Number__c : null, thirdPartyDeductibleAmount, soHeader.Provider__r.Vendor_Tax_Id__c); 
            }
        }
        
        public ServiceDetail(COInvoiceDetail coInvoice, Service_Order_Header__c soHeader, List<Service_Order_Kit_Header__c> soKitHeaderList, Customer_Owned_Unit__c unitRec) {
            this.IsDealService = soHeader.Deal__c != null ? true : false;
            this.Salespersons = (String.isNotBlank(soHeader.Salesperson_Names__c) ? soHeader.Salesperson_Names__c : soHeader.CO_Header__r.Owner__r.Name);
            this.transactionType = (soHeader.Transaction_Type__c != null && soHeader.Transaction_Type__r.Type__c != null) ? soHeader.Transaction_Type__r.Type__c : '';
            this.isDeductibleInvItem = false;
            Decimal DeductibleAmount = 0;
            if(coInvoice != null && coInvoice.COInvoiceItems != null) {
                for(CO_Invoice_Item__c coInvoiceItem: coInvoice.COInvoiceItems) {
                    if(coInvoiceItem.Service_Order_Header__c == soHeader.Id) {
                        if(coInvoiceItem.SO_Payment_Role__r != null && coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') {
                            this.isDeductibleInvItem = true;
                            DeductibleAmount = coInvoiceItem.SO_Payment_Role__r.Total_Amount__c;
                            break;
                        }
                    }
                }
            }
            
            // Service details
            Name    = soHeader.Name__c;
            Total   = 0;

            /* Start: Commented and Added by richa 06/04/2017 */
            /* Correction  = soHeader.SO_Correction__c;
            Cause   = soHeader.SO_Cause__c;
            Concern = soHeader.SO_Concern__c; */
            /* End: Commented and Added by richa 06/04/2017 */
            
            this.ShopSupplyTotal = (soHeader.Total_Shop_Supplies__c != null) ? soHeader.Total_Shop_Supplies__c : 0;
            this.CauseList = (soHeader.SO_Cause__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Cause__c.split('\n')) : new List<String>();
            this.CorrectionList = (soHeader.SO_Correction__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Correction__c.split('\n')) : new List<String>();
            this.ConcernList = (soHeader.SO_Concern__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Concern__c.split('\n')) : new List<String>();
            this.Notes = (soHeader.SO_Notes_For_Customer__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeader.SO_Notes_For_Customer__c.split('\n')) : new List<String>();
            
            Unit = '';
            if(soHeader.Customer_Owned_Unit__c != null) {
                Boolean showDash = false;
                MileageIn   = soHeader.Odometer_on_Arrival__c;
                MileageOut  = soHeader.Odometer_on_Departure__c;
                MileageType = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Mileage_Type__c') && String.isNotBlank(unitRec.Mileage_Type__c) ? unitRec.Mileage_Type__c : null;
                if(soHeader.Customer_Owned_Unit__r.Year__c != null) {
                    Unit += soHeader.Customer_Owned_Unit__r.Year__c;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name !=null && soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Unit_Make__r.Name;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null && soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
                    showDash = true;
                }
                
                if(soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null && soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c !='') {
                    Unit += ' ' + soHeader.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
                    showDash = true;
                }
                if(soHeader.Customer_Owned_Unit__r.VIN_Number__c != null) {
                    if(showDash) {
                        Unit += ' - ';
                    }
                    Unit += soHeader.Customer_Owned_Unit__r.VIN_Number__c;
                }
                if(UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Plate__c') && String.isNotBlank(unitRec.Plate__c)) Unit += ' - ' + unitRec.Plate__c;
                UnitDetails = new ServiceJobWorksheetWrapper.UnitInfoWrapper(unitRec);
            }
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            // Service Line Items
            ServiceItems = new List<ServiceItemsDetail>();
            if(soHeader != null && soHeader.Service_Order_Line_Items__r != null) {
                for(Service_Order_Line_Item__c soli : soHeader.Service_Order_Line_Items__r) {
                    ServiceItems.add(new ServiceItemsDetail(coInvoice, soli));
                    if(isTaxIncludingPricing) {
                        decimal Price = 0;
                        if(soli.Deal_Item__c != null) {
                            Price = (soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                        } else {
                            Decimal taxAmount = (soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                            Price = (soli.Kit_Price__c + taxAmount).setScale(2, RoundingMode.HALF_UP);
                        }
                    }
                }
            }
            
            if(!this.isDeductibleInvItem) {
                this.Total = soHeader.Total__c;
            } else {
                this.Total = DeductibleAmount;
            }
            
            // Start: Added by richa 14 april
            this.SOGridItems = new List<SOHeaderWrapper.SOGrid>();
            List<DateTime> sortedDateTimeList = new List<dateTime>();
            Set<Id> soliIdSet = new Set<Id>();
            for(Service_Order_Kit_Header__c soKHRec : soKitHeaderList) {
                sortedDateTimeList.add( soKHRec.CreatedDate );
                
                this.SOGridItems.add(new SOHeaderWrapper.SOGrid(soKHRec, soKHRec.Service_Order_Line_Items__r, true));
                for(Service_Order_Line_Item__c soliRec : sokhRec.Service_Order_Line_Items__r) {
                    soliIdSet.add(soliRec.Id);
                } 
            }
            Integer lastIndexValue = 0;
            ShopSupplyDetailSet = new Set<String>();
            
            for(Service_Order_Line_Item__c soliRec : soHeader.Service_Order_Line_Items__r) {
                if(!soliRec.Is_Hidden__c) {
                    if(!soliIdSet.contains(soliRec.Id)) {
                        for(Integer i = lastIndexValue; i < sortedDateTimeList.size(); i++){
                            system.debug(i);
                            if(sortedDateTimeList[i] < soliRec.CreatedDate){
                                lastIndexValue ++;
                            } else {
                                break;
                            }
                        }
                        if(this.SOGridItems.size() > lastIndexValue){
                            this.SOGridItems.add(lastIndexValue, new SOHeaderWrapper.SOGrid(new Service_Order_Kit_Header__c(), new List<Service_Order_Line_Item__c>{soliRec}, false));

                            if(sortedDateTimeList.size() > lastIndexValue){
                                sortedDateTimeList.add(lastIndexValue, soliRec.CreatedDate);
                            } else {
                                sortedDateTimeList.add(soliRec.CreatedDate);
                            }

                            lastIndexValue++;
                        } else {
                            this.SOGridItems.add(new SOHeaderWrapper.SOGrid(new Service_Order_Kit_Header__c(), new List<Service_Order_Line_Item__c>{soliRec}, false));
                            lastIndexValue++;
                        }
                        
                        if(soliRec.Labour_Code__c != null && soliRec.Labour_Code__r.Calculate_Supplies__c && soliRec.Labour_Code__r.Supplies_Detail__c != null) {
                            for(String shopSupplyDetailStr : soliRec.Labour_Code__r.Supplies_Detail__c.split('\n')) {
                                ShopSupplyDetailSet.add(shopSupplyDetailStr);
                            }
                        }
                    }
                }
            }
             if(ShopSupplyDetailSet.size() > 0){
                isShopSupplySetValid = true;
            }
            
            if(soHeader.Provider__c != null) {
                Decimal thirdPartyDeductibleAmount = 0;
                if(!soHeader.SO_Payment_Roles__r.isEmpty()) {
                    for(SO_Payment_Role__c soPaymentRole: soHeader.SO_Payment_Roles__r) {
                        thirdPartyDeductibleAmount += soPaymentRole.Total_Amount__c;
                    }
                }
                this.ProviderDetail = new ProviderDetail(soHeader.Provider__r.Name, soHeader.Provider__r.BillingAddress, (!soHeader.Claims__r.isEmpty()) ? soHeader.Claims__r[0].Provider_Claim_Number__c : null, thirdPartyDeductibleAmount, soHeader.Provider__r.Vendor_Tax_Id__c);
            }
        }
    }
    
    /**
     * Name: ServiceItemsDetail
     * Description: Wrapper class
     * 
    **/
    public class ServiceItemsDetail {
        public String Type {get; private set;}
        public String ItemDesc {get; private set;}
        
        /* START: Added By Tarun - #170 - 09/23/2016 */
        public String ItemCode {get; private set;}
        public String ItemDescription {get; private set;}

        public decimal Qty {get; private set;}
        public decimal Price {get; private set;}
        public decimal Total {get; private set;}
        
        public ServiceItemsDetail(COInvoiceDetail coInvoice, Service_Order_Line_Item__c soli) {
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(soli.Tax_Percent__c == null) {
                soli.Tax_Percent__c = 0;
            }
            if(soli.Qty_Needed__c == null) {
                soli.Qty_Needed__c = 0;
            }
            if(soli.Kit_Price__c == null) {
                soli.Kit_Price__c = 0;
            }
            Qty = soli.Qty_Needed__c;
            if(soli.Fee__c != null) {
                // Fee
                Type = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Fee');
                if(!isTaxIncludingPricing) {
                    //coInvoice.TotalFees += soli.Qty_Needed__c * soli.Kit_Price__c;
                } else {
                    if(soli.Deal_Item__c != null) {
                        //coInvoice.TotalFees += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        Decimal taxAmount = (soli.Qty_Needed__c * soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                        //coInvoice.TotalFees += ((soli.Qty_Needed__c * soli.Kit_Price__c) + taxAmount).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            } else if(soli.Part__c != null) {
                // Part
                Type    = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Part');
                if(!isTaxIncludingPricing) {
                    //coInvoice.TotalParts += soli.Qty_Needed__c * soli.Kit_Price__c;
                } else {
                    if(soli.Deal_Item__c != null) {
                        //coInvoice.TotalParts += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        Decimal taxAmount = (soli.Qty_Needed__c * soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                        //coInvoice.TotalParts += ((soli.Qty_Needed__c * soli.Kit_Price__c) + taxAmount).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            } else {
                // Labour
                Type = PrintCustomerOrderInvoiceCtrl.merchandiseNameToType.get('Labour');
                if(!isTaxIncludingPricing) {
                    //coInvoice.TotalLabour += soli.Qty_Needed__c * soli.Kit_Price__c;
                } else {
                    if(soli.Deal_Item__c != null) {
                        //coInvoice.TotalLabour += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        Decimal taxAmount = (soli.Qty_Needed__c * soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                        //coInvoice.TotalLabour += ((soli.Qty_Needed__c * soli.Kit_Price__c) + taxAmount).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            
            /* START: Added By Tarun - #170 - 09/23/2016 */
            this.ItemCode = (soli.Item_Code__c != null) ? soli.Item_Code__c : '';
            this.ItemDescription = (soli.Item_Description__c != null) ? soli.Item_Description__c : '';
            this.ItemDesc = this.ItemCode + ' - ' + this.ItemDescription;
            
            if(isTaxIncludingPricing) {
                if(soli.Deal_Item__c != null) {
                    Price = (soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    Decimal taxAmount = (soli.Kit_Price__c * soli.Tax_Percent__c / 100);
                    Price = (soli.Kit_Price__c + taxAmount).setScale(2, RoundingMode.HALF_UP);
                }
                Total = Price * Qty;
            } else {
                Price = soli.Kit_Price__c;
                Total = soli.Kit_Price__c * Qty;
            }
            
            // Calculations for Invoice
            if(soli.Deal_Item__c == null) {
                //coInvoice.SalesTax += (soli.Kit_Price__c * Qty * soli.Tax_Percent__c / 100).setScale(2, RoundingMode.HALF_UP);
            }
            //coInvoice.SubTotal += this.Total;
        }
    }
    
    public static List<CO_Invoice_Header__c> getCustomerOrderInvoiceHeaders(List<Id> coInvoiceIdsList) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Deposit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        // Edited by kajal 12/08/2016 deal invoice
        List<CO_Invoice_Header__c> coInvoices = [SELECT Id, 
                                                        Name,
                                                        Invoice_Number__c,
                                                        Is_Discount_Shown__c,
                                                        Discount_Amount__c,
                                                        Warranty_Product_Total__c,
                                                        Other_Product_Total__c,
                                                        Invoice_Date__c,
                                                        Invoice_Date_Formula__c,
                                                        Status__c,
                                                        Part_Total__c,
                                                        Fee_Total__c,
                                                        Lien_Payout_Total__c,
                                                        Shop_Supplies_Total__c,
                                                        Labour_Total__c,
                                                        Unit_Total__c,
                                                        Sublet_Total__c,
                                                        F_I_Total__c,
                                                        Sub_Total__c,
                                                        SalesTax_Total__c,
                                                        Stamp_Duty_Total__c,
                                                        Total__c,
                                                        Deductible_Total__c,
                                                        Checkout_Type__c,
                                                        Total_Charge_On_Account__c,
                                                        AccountingId__c,
                                                        Xero_Accounting_Id__c,
                                                        CreatedDate,
                                                        CreatedBy.Name,
                                                        CO_Header__c,
                                                        CO_Header__r.Name,
                                                        Legacy_Tax_Label_1__c,
                                                        Legacy_Tax_Label_2__c,
                                                        Legacy_Tax_Label_3__c,
                                                        Legacy_Tax_Amount_1__c,
                                                        Legacy_Tax_Amount_2__c,
                                                        Legacy_Tax_Amount_3__c,
                                                        CO_Header__r.Status__c,
                                                        CO_Header__r.Is_Legacy_CO__c,
                                                        CO_Header__r.CO_Type__c,
                                                        CO_Header__r.Customer_PO_Number__c,
                                                        CO_Header__r.Customer__c,
                                                        CO_Header__r.Customer__r.Name,
                                                        CO_Header__r.Customer__r.Customer_Number__c,
                                                        CO_Header__r.Customer__r.BillingStreet,
                                                        CO_Header__r.Customer__r.BillingCity,
                                                        CO_Header__r.Customer__r.BillingState,
                                                        CO_Header__r.Customer__r.BillingPostalCode,
                                                        CO_Header__r.Customer__r.BillingCountry,
                                                        CO_Header__r.Customer__r.Email__c,
                                                        CO_Header__r.Customer__r.Home_Number__c,
                                                        CO_Header__r.Customer__r.Mobile__c,
                                                        CO_Header__r.Customer__r.Preferred_Phone__c,
                                                        CO_Header__r.Customer__r.Work_Number__c,
                                                        CO_Header__r.Customer__r.Home_Number_SMS__c,
                                                        CO_Header__r.Customer__r.Mobile_Number_SMS__c, 
                                                        CO_Header__r.Customer__r.Preferred_SMS__c,
                                                        CO_Header__r.Customer__r.Work_Number_SMS__c,
                                                        CO_Header__r.Customer__r.Other_Email__c,
                                                        CO_Header__r.Customer__r.Preferred_Email__c,
                                                        CO_Header__r.Customer__r.Work_Email__c,
                                                        CO_Header__r.Customer__r.Formatted_Preferred_Phone__c,
                                                        CO_Header__r.Customer__r.Formatted_Work_Number__c,
                                                        CO_Header__r.Customer__r.Formatted_Mobile_Number__c,
                                                        CO_Header__r.Customer__r.Formatted_Home_number__c,
                                                        Tracking_Number__c,
                                                        Invoice_Status__c,
                                                        
                                                        (SELECT isActive__c, CO_Line_Item__c, CO_Kit_Header__c, Service_Order_Header__c, Service_Order_Header__r.Transaction_Type__r.Type__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName, SO_Payment_Role__r.Total_Amount__c, Deal__c, Deal__r.Lien_Payout_Total__c, CO_Invoice_Header__r.Status__c, CO_Line_Item__r.Option_Fee__c, CO_Line_Item__r.Deal__c, CO_Kit_Header__r.Deal__c, Service_Order_Header__r.Deal__c FROM CO_Invoice_Items__r), // Ticket#1984: isActive__c: Added By Hitesh 3 May 2017
                                                        (SELECT Name, 
                                                                LastModifiedDate,  
                                                                Payment_Date__c,
                                                                Payment_Method__c, 
                                                                Amount__c, 
                                                                Reverse_Link__c, 
                                                                Deposit_Payment_Method__c,
                                                                Reference__c 
                                                                FROM CO_Invoice_Payments__r
                                                                WHERE Amount__c != 0
                                                                ORDER BY Payment_Date__c DESC
                                                        ),
                                                        (SELECT Name, 
                                                                LastModifiedDate, 
                                                                Payment_Method__c, 
                                                                Payment_Date__c, 
                                                                Amount__c,
                                                                Reference__c 
                                                                FROM CO_Deposits__r
                                                                WHERE Amount__c != 0
                                                                ORDER BY Payment_Date__c DESC
                                                        )
                                                        FROM CO_Invoice_Header__c 
                                                        WHERE Id IN: coInvoiceIdsList
                                                ];
        return coInvoices;
    }
    
    public static List<CO_Header__c> getCustomerOrderHeaders(List<Id> coIdsList, List<Id> coliIds) {
        List<CO_Header__c> coHeadersList = new List<CO_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
       
        if(coIdsList != null && coIdsList.size() > 0) {
            String query = 'SELECT ';
            
            for(String fieldsName : COHeader.fieldsList()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            
            query += '(SELECT ';
            for(String fieldsName : DealWrapper.getDealFields()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' From Deals__r), '; 
            query += '(Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null AND Deal__c != null Order By CreatedDate), ';
            
            query += '(SELECT Id, Amount__c, Payment_Method__c from CO_Deposits__r where Payment_Method__c != \'Invoice\'), ';
            query += '(SELECT ';
            for(String fieldsName : COLineItem.fieldsList()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            
            query += ' FROM CO_Line_Items__r WHERE Service_Order_Line_Item__c = null AND Id IN: coliIds ORDER BY Name, CreatedDate) FROM CO_Header__c WHERE Id IN: coIdsList';
            
            coHeadersList = Database.query(query);
            /**
            coHeadersList = [SELECT Id, 
                                    Name,
                                    Total_COLI__c,
                                    Total_SO__c,
                                    Total_Deposit__c,
                                    Total_Payment__c,
                                    Total_Order_Value__c,
                                    (SELECT Id,
                                            Name, 
                                            Item_ID__c,
                                            CO_Header__c,
                                            CO_Header__r.Name,
                                            CO_Header__r.Customer__c,
                                            CO_Header__r.CO_Type__c,
                                            CO_Header__r.Customer__r.Name,
                                            CO_Header__r.Owner__c,
                                            CO_Header__r.Owner__r.Name,
                                            CO_Header__r.Order_status__c,
                                            Qty__c,
                                            Qty_Committed__c,
                                            Price__c,
                                            Item_Code__c,
                                            Item_Description__c,
                                            Part__r.Name,
                                            Part__r.Part_Id__c,
                                            Part__r.Part_Number__c,
                                            Part__r.Description__c,
                                            Part__r.AvailableParts__c,
                                            Part__r.Vendor__c,
                                            Special_Order__c,
                                            Tax__c,
                                            Retail__c,
                                            Closed_CO_Invoice_link__c,
                                            VO_Number__c,
                                            VO_Status__c,
                                            Expected_Delivery_Date__c,
                                            CreatedDate,
                                            Fee__c,
                                            Fee__r.Fee_Unique_Name__c,
                                            Fixed_Price__c,
                                            CO_Fixed_KitLineItem__c,
                                            Actual_Kit_Price__c,
                                            Kit_Price_With_Price_Level__c,
                                            CO_Kit_Header__r.Id,
                                            Sub_Total_With_Tax__c,
                                            Sub_Total_Without_Tax__c,
                                            Tax_Amount__c,
                                            Oversold_Qty__c,
                                            Is_Temporary__c 
                                            FROM CO_Line_Items__r 

                                            WHERE Is_In_Service_Order__c = false
                                            AND Is_Temporary__c = false 
                                            AND Id IN: coliIds
                                    )
                                    FROM CO_Header__c 
                                    WHERE Id IN: coIdsList
                            ];
                            **/
        }
        
        return coHeadersList;
    }
    
    public static List<Service_Order_Header__c> getServiceOrderHeaders(List<Id> coIdsList, List<Id> sohIds) {
        List<Service_Order_Header__c> soHeadersList = new List<Service_Order_Header__c>();
         if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
          if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
          if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(coIdsList != null && coIdsList.size() > 0) {
        	for(Service_Order_Header__c soHeader : [SELECT Id, 
                                    Name__c,
                                    Total__c,
                                    SO_Correction__c, 
                                    SO_Cause__c,
                                    SO_Concern__c, 
                                    Total_Shop_Supplies__c, 
                                    Customer_Owned_Unit__c,
                                    Customer_Owned_Unit__r.VIN_Number__c,
                                    Customer_Owned_Unit__r.Unit_Make__r.Name,
                                    Customer_Owned_Unit__r.Unit_Model__r.Name__c,
                                    Customer_Owned_Unit__r.Submodel__r.Name__c, // Added by richa 06/02/2017
                                    Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c, // Added By Pooja 5 May 2017
                                    Customer_Owned_Unit__r.Year__c,
                                    Customer_Owned_Unit__r.Unit_Id__c,
                                    Customer_Owned_Unit__r.Stock_Id__c,
                                    Customer_Owned_Unit__r.Unit_Type__c,
                                    Customer_Owned_Unit__r.Unit_Model__r.Sub_Model__c,
                                    Customer_Owned_Unit__r.Formatted_Name__c,
                                    Customer_Owned_Unit__r.Product_type__c,
                                    Odometer_on_Arrival__c,
                                    Odometer_on_Departure__c,
                                    Co_Header__c,
                                    SO_Notes_For_Customer__c,
                                    Provider__c,
                                    Provider__r.Name,
                                    Provider__r.BillingAddress,
                                    Provider__r.Vendor_Tax_Id__c,
                                    Deal__c, 
                                    Transaction_Type__r.Type__c, 
                                    Salesperson_Names__c, 
                                    CO_Header__r.Owner__r.Name,
                                    (Select Provider_Claim_Number__c from Claims__r),
                                    (SELECT Total_Amount__c FROM SO_Payment_Roles__r WHERE RecordType.DeveloperName='Deductible'),
                                    (SELECT Id, 
                                            Item_Code__c,
                                            Item_Description__c,
                                            Item_Desc__c, 
                                            Kit_Price__c, 
                                            Labour_Code__c, 
                                            Labour_Code__r.Supplies_Detail__c,
                                            Labour_Code__r.Calculate_Supplies__c,
                                            Part__c, 
                                            Qty_Needed__c, 
                                            Total__c, 
                                            Fee__c, 
                                            Tax_Percent__c,
                                            Tax_Amount__c,
                                            Deal_Item__c,
                                            CreatedDate, // Start: Added by richa 14 april
                                            Part__r.Vendor__c,
                                            Is_Fixed_Kit_LineItem_SO__c,
                                            Actual_Retail_Price__c,
                                            Qty_Committed__c,
                                            CO_Line_Item__c,
                                            CO_Line_Item__r.Closed_CO_Invoice_link__c,
                                            CO_Line_Item__r.CO_Status__c,
                                            CO_Line_Item__r.Status__c,
                                            Part__r.Non_Inventory_Part__c,
                                            CO_Line_Item__r.Special_Order__c,
                                            CO_Line_Item__r.Oversold_Qty__c,
                                            Deal__c,
                                            Retail_Price__c,
                                            Fixed_Price__c,
                                            Part__r.AvailableParts__c,
                                            Service_Order_Kit_Header__c,
                                            Option_Fee__c, // End: Added by richa 14 april
                                            CO_Line_Item__r.Vendor_Order_Header__r.Status__c,// Start: Added by richa issue #1879 25 april
                                            Price_When_Tax_Included__c,
                                            CO_Line_Item__r.VO_Number__c,// End: Added by richa issue #1879 25 april
                                            Is_Environmental_Fee__c,
                                            Sublet__c,
                                            Is_Hidden__c,
                                            Status__c,
                                            Cost__c,
                                            Sublet__r.Cost_Method__c,
                                            Sublet__r.Cost__c,
                                            Vendor_Order_Header__r.Status__c,
                                            VO_Number__c,
                                            Type__c,
                                            Part__r.Assigned_Location_1__c,
                                            Part__r.Assigned_Location_2__c,
                                            Service_Order_Header__r.SO_Status__c,
                                            Part__r.Is_Superseded__c,
                                            CO_Line_Item__r.Qty__c,
                                            CO_Line_Item__r.Pulled__c,
                                            Part__r.Cassons_ID__c,
                                            Part__r.Cassons_SOH__c,
                                            Part__r.Part_Number__c,
                                            Part__r.Description__c,
                                            Part__r.Qty_On_Order__c,
                                            Part__r.Vendor__r.Is_Foreign_Vendor__c,
                                            UUID__c,
                                            Discount__c,
                                            Calculated_Customer_Price__c,
                                            Commit_Order_Controls__c 
                                            FROM Service_Order_Line_Items__r
                                            Order BY CreatedDate ASC, Name ASC
                                    ),
                                    (Select Id, Kit_Header__r.Cause__c, Kit_Header__r.Correction__c, Kit_Header__r.Concern__c from Service_Order_Kit_Headers__r) 
                                    FROM Service_Order_Header__c
                                    WHERE Id IN: sohIds
                                    ORDER By Name ASC
                            ]) {
                            	soHeadersList.add(soHeader);
                            }
        }
        return soHeadersList;
    }
    
    
    public static List<CO_Kit_Header__c> getKitHeaders(List<Id> coIdsList, List<Id> cokhIds) {
        List<CO_Kit_Header__c> coKitHeadersList = new List<CO_Kit_Header__c>();
         if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
          if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(coIdsList != null && cokhIds.size() > 0) {
            coKitHeadersList = [SELECT Id, 
                                    CO_Header__c,
                                    Kit_Header__c,
                                    Price__c,
                                    Tax_Amount__c,
                                    Actual_Kit_Price__c, 
                                    CreatedDate,
                                    Kit_Header__r.Kit_Unique_Name__c,
                                    Can_Split__c,
                                    Service_Kit__c,
                                    Deal__c,
                                    Fixed_Price_Flag__c,
                                    CO_Fixed_KitHeader__c,
                                    UUID__c, 
                                    (SELECT Id,
                                            Name,
                                            Item_ID__c , 
                                            CO_Header__c,
                                            CO_Header__r.Name,
                                            CO_Header__r.Customer__c,
                                            CO_Header__r.Customer__r.Name,
                                            CO_Header__r.Owner__c,
                                            CO_Header__r.Owner__r.Name,
                                            CO_Header__r.Order_status__c,
                                            Qty__c,
                                            Qty_Committed__c,
                                            Item_Code__c,
                                            Item_Description__c,
                                            Price__c,
                                            Part__r.Name,
                                            Part__r.Part_Id__c,
                                            Part__r.Part_Number__c,
                                            Part__r.Non_Inventory_Part__c,
                                            Part__r.Description__c,
                                            Part__r.AvailableParts__c,
                                            Part__r.Vendor__c,
                                            Special_Order__c,
                                            Tax__c,
                                            Retail__c,
                                            Closed_CO_Invoice_link__c,
                                            VO_Number__c,
                                            VO_Status__c,
                                            Expected_Delivery_Date__c,
                                            CreatedDate,
                                            Fee__c,
                                            Fee__r.Fee_Unique_Name__c,
                                            Fixed_Price__c,
                                            CO_Fixed_KitLineItem__c,
                                            Actual_Kit_Price__c,
                                            Kit_Price_With_Price_Level__c,
                                            CO_Kit_Header__r.Id,
                                            Sub_Total_With_Tax__c,
                                            Sub_Total_Without_Tax__c,
                                            Tax_Amount__c,
                                            Oversold_Qty__c,
                                            Is_Temporary__c,
                                            Deal__c,
                                            Option_Fee__c,
                                            Related_Option_And_Fees__c,
                                            Actual_Retail_Price__c,
                                            Status__c,
                                            CO_Status__c,
                                            Vendor_Order_Header__r.Status__c,
                                            Price_When_Tax_Included__c,
                                            Is_Environmental_Fee__c,
                                            Is_In_Merch_Section__c,
                                            Merchandise_Commit_Order_controls__c,
                                            Part__r.Assigned_Location_1__c,
                                            Part__r.Assigned_Location_2__c,
                                            Part__r.Is_Superseded__c,
                                            Pulled__c,
                                            Part__r.Cassons_ID__c,
                                            Part__r.Cassons_SOH__c,
                                            Part__r.Qty_On_Order__c,
                                            Part__r.Vendor__r.Is_Foreign_Vendor__c,
                                            UUID__c, 
                                            Discount__c 
                                            FROM CO_Line_Items__r 
                                            WHERE Service_Order_Line_Item__c = null
                                    		Order by Name, CreatedDate
                                    )
                                    FROM CO_Kit_Header__c
                                    WHERE Id IN: cokhIds
                                    ORDER BY CreatedDate
                            ];
        }
        
        return coKitHeadersList;
    }
    // START: Added by kajal 12/08/2016 deal invoice
    public static List<Deal_Item__c> getDealHeaders(List<Id> coIdsList, List<Id> dealIds) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(dealIds != null && dealIds.size() > 0) {
    
            String query = 'SELECT Id, ';
            /*
            for(String fieldsName : DealWrapper.getDealFields()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            */
            query += '(SELECT Id';
            
            /*for(String fieldsName : DealItem.getDealItemFields()){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            */
            query += ' FROM Deal_Items__r) FROM Deal__c WHERE Id IN: dealIds';
            List<Deal__c> dealList = Database.query(query);
            
            if(dealList.size() > 0) {
                Set<String> dealItemId = new Set<String>();
                for(Deal__c dealRec : dealList) {
                    for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r)
                    dealItemId.add(dealItemRec.Id);
                }
                query = 'SELECT ';
                
                for(String fieldsName : DealItem.getDealItemFields()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                
                query += '(SELECT ';
                
                for(String fieldsName : DealWrapper.getOptionAndFeeFields()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                
                query = query.substring(0, query.length()-2);
                query += ' FROM Options_Fees__r), ';
                query += '(SELECT ';
                
                for(String fieldsName : DealWrapper.getDealUnitPriceCost()){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length()-2);
                query += ' FROM Deal_Unit_Prices_Costs__r ORDER BY Type__c ASC, Unit_Price_Cost__r.Name ASC) FROM Deal_Item__c WHERE Id IN: dealItemId';
                dealItemList = Database.query(query);
            }
        }
            
        return dealItemList;
    }
    // End: Added by kajal 12/08/2016 deal invoice

    /**
     * Name: COInvoiceDetail
     * Description: Wrapper class
     * 
    **/
    public class COMerchandiseDetail {
        // List of CO Line Items
        public List<COHeaderWrapper.COKitHeader> COKHList{get; set;}
        public GridTotal gridTotal {get; set;}
        public List<CustomerMerchandies> custmerMercRec {get; set;}
        public COInvoice COInvoiceRec {get; set;}
        public CustomerDetail.Company CompanyInfo {get; set;}
        
        public COMerchandiseDetail() {
            this.custmerMercRec = new  List<CustomerMerchandies>();
        }
        
        public COMerchandiseDetail(List<COHeaderWrapper.COKitHeader> COKHList, Decimal subtotal, Decimal salesTax, Decimal priceOverrides, 
                                            Decimal total_Part, Decimal total_Laobur, Decimal total_Sublet, Decimal total_Fee,
                                            Map<String, Decimal> salesTaxNameToTaxValue, List<CustomerMerchandies> custmerMercRec, CO_Invoice_Header__c coHeaderInvoiceRec, BrandingLocationWrapper brandingLocationObj) {
            this.custmerMercRec = new  List<CustomerMerchandies>();
            this.COKHList = COKHList;
            this.gridTotal = new GridTotal(subtotal, salesTax, priceOverrides, total_Part, total_Laobur, total_Sublet, total_Fee, salesTaxNameToTaxValue);
            this.custmerMercRec =  custmerMercRec; 
            this.COInvoiceRec = new COInvoice(coHeaderInvoiceRec);
            if(brandingLocationObj != null) {
                this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
            }

            // Added By Pooja 13 Feb. 2017
            this.CompanyInfo.BusinessPhone = formatphonenumber(this.CompanyInfo.BusinessPhone);



        }
    }
    
    /**
     * Name: COInvoice
     * Description: Wrapper class
     * 
    **/
    public class COInvoice {
        public String InvoiceNumber {get; private set;}
        public String InvoiceDate {get; private set;}
        public String InvoiceStatus {get; private set;}
        public String SoldBy {get; private set;}


        
         public COInvoice(CO_Invoice_Header__c coInvoiceHeaderObj){
            InvoiceNumber = (coInvoiceHeaderObj.Invoice_Number__c == null) ? '' : coInvoiceHeaderObj.Invoice_Number__c;
            InvoiceDate = (coInvoiceHeaderObj.Invoice_Date__c != null) ? BPUtility.getExtendedDateFormatWithoutTime(coInvoiceHeaderObj.Invoice_Date__c) : '';
            InvoiceStatus = coInvoiceHeaderObj.Status__c;
            SoldBy = coInvoiceHeaderObj.CreatedBy.Name;


         }
    }
    
    public class CustomerMerchandies {
        public String StoreCityProv {get; set;}
        public String StorePostal {get; set;}
        public String StoreBusinessNumber {get; set;}
        public String StoreWebsite {get; set;}
        
        public String CustomerName {get; set;}
        public String CustomerAddress {get; set;}
        public String CustomerAddress2 {get; set;}
        public String CustomerCityProv {get; set;}
        public String CustomerPostal {get; set;}
        public String CustomerShippingAddress {get; set;}
        public String CustomerShippingAddress2 {get; set;}
        public String CustomerShippingCityProv {get; set;}
        public String CustomerShippingPostal {get; set;}
        public String CustomerEmail {get; set;}
        public String CustomerPhone {get; set;}
        
        public String CONumber {get; set;}
        public String CODate {get; set;}
        public String COSoldBy {get; set;}
        public String COType {get; set;}
        public String COStatus {get; set;}
        public String CustomerNumber {get; set;}
        public String PONumber {get; set;}
        public String DealMerchSalespersons {get; set;}
        
        public CustomerMerchandies(CO_Header__c coHeaderRec) {
            if(coHeaderRec != null) {
                CustomerName        = coHeaderRec.Customer__r.Name;
                String billingStreet = (coHeaderRec.Customer__r.BillingStreet == null ) ? '' : coHeaderRec.Customer__r.BillingStreet;

                List<String> bsList = billingStreet.split('\n');
                this.CustomerAddress = (bsList.size() > 0) ? bsList[0] : '';
                this.CustomerAddress2 = (bsList.size() > 1) ? bsList[1] : '';
                CustomerCityProv    = coHeaderRec.Customer__r.BillingCity;
                CustomerCityProv    = String.isnotBlank(CustomerCityProv) ? (CustomerCityProv + ', ' + coHeaderRec.Customer__r.BillingState) : coHeaderRec.Customer__r.BillingState;
                CustomerPostal      = coHeaderRec.Customer__r.BillingPostalCode;
                
                String shippingStreet = (coHeaderRec.Customer__r.ShippingStreet == null ) ? '' : coHeaderRec.Customer__r.ShippingStreet;
                List<String> shippingStreetList = shippingStreet.split('\n');
                this.CustomerShippingAddress = (shippingStreetList.size() > 0) ? shippingStreetList[0] : '';
                this.CustomerShippingAddress2 = (shippingStreetList.size() > 1) ? shippingStreetList[1] : '';
                CustomerShippingCityProv    = coHeaderRec.Customer__r.ShippingCity;
                CustomerShippingCityProv    =  String.isnotBlank(CustomerShippingCityProv) ? (CustomerShippingCityProv + ', ' + coHeaderRec.Customer__r.ShippingState) : coHeaderRec.Customer__r.ShippingState;
                CustomerShippingPostal      =  coHeaderRec.Customer__r.ShippingPostalCode;

                this.COSoldBy = (String.isNotBlank(coHeaderRec.Salesperson_Names__c) ? coHeaderRec.Salesperson_Names__c : coHeaderRec.CreatedBy.Name);
                String salespersonNames = COSalespersonTriggerHelper.getNewSalespersonNames('', coHeaderRec.CO_Salespersons__r);
                this.DealMerchSalespersons = (String.isNotBlank(salespersonNames) ? salespersonNames : coHeaderRec.Owner__r.Name);
                this.CustomerNumber = coHeaderRec.Customer__r.Customer_Number__c != null ? coHeaderRec.Customer__r.Customer_Number__c : '';
                if(coHeaderRec.Customer__r.Preferred_Email__c == null) {
                    if(coHeaderRec.Customer__r.Email__c != null) {
                        this.CustomerEmail = coHeaderRec.Customer__r.Email__c;
                    } else if(coHeaderRec.Customer__r.Work_Email__c != null) {
                        this.CustomerEmail = coHeaderRec.Customer__r.Work_Email__c;
                    } else if(coHeaderRec.Customer__r.Other_Email__c != null) {
                        this.CustomerEmail = coHeaderRec.Customer__r.Other_Email__c;
                    }
                } else {
                    this.CustomerEmail = coHeaderRec.Customer__r.Preferred_Email__c;
                }
                
                if(coHeaderRec.Customer__r.Preferred_Phone__c == null) {
                    if(coHeaderRec.Customer__r.Formatted_Home_number__c != null) {
                        this.CustomerPhone = coHeaderRec.Customer__r.Formatted_Home_number__c;
                    } else if(coHeaderRec.Customer__r.Formatted_Mobile_Number__c != null) {
                        this.CustomerPhone = coHeaderRec.Customer__r.Formatted_Mobile_Number__c;
                    } else if(coHeaderRec.Customer__r.Formatted_Work_Number__c != null) {
                        this.CustomerPhone = coHeaderRec.Customer__r.Formatted_Work_Number__c;
                    }
                } else {
                    this.CustomerPhone = coHeaderRec.Customer__r.Formatted_Preferred_Phone__c;
                }     
                this.CONumber  = coHeaderRec.Name;
                this.CODate = (coHeaderRec.CreatedDate != null) ? BPUtility.getFormatedDateTime(coHeaderRec.CreatedDate) : '';
                this.COType  = coHeaderRec.CO_Type__c;                
                this.COStatus = coHeaderRec.Status__c;
                this.PONumber = coHeaderRec.Customer_PO_Number__c;
            }
        }

         
    }
    public class GridTotal {
        public Decimal SubTotal {get; private set;}
        public Decimal SalesTax {get; private set;}
        public Decimal PriceOverrides {get; private set;}
        
        public Decimal Total_Part {get; private set;}
        public Decimal Total_Laobur {get; private set;}
        public Decimal Total_Sublet {get; private set;}
        public Decimal Total_Fee {get; private set;}
        public List<IndividualTax> SalesTaxList;
        
        public GridTotal(Decimal subtotal, Decimal salesTax, Decimal priceOverride, 
                          Decimal total_Part, Decimal total_Laobur, Decimal total_Sublet, Decimal total_Other,Map<String, Decimal> salesTaxNameToTaxValue){
            this.SubTotal = Subtotal.setScale(2, RoundingMode.HALF_UP);                                  
            this.SalesTax = salesTax.setScale(2, RoundingMode.HALF_UP);
            this.PriceOverrides = priceOverride.setScale(2, RoundingMode.HALF_UP);
            
            this.Total_Part = total_Part.setScale(2, RoundingMode.HALF_UP);
            this.Total_Laobur = total_Laobur.setScale(2, RoundingMode.HALF_UP);
            this.Total_Sublet = total_Sublet.setScale(2, RoundingMode.HALF_UP);
            this.Total_Fee = total_Other.setScale(2, RoundingMode.HALF_UP);
            this.SalesTaxList = new List<IndividualTax>();
            for(String taxName : salesTaxNameToTaxValue.keySet()) {
                this.SalesTaxList.add(new IndividualTax(taxName, salesTaxNameToTaxValue.get(taxName))); 

            }
        }
    }
    public class IndividualTax {
        public String TaxName {get; private set;}
        public Decimal TaxValue {get; private set;}
       
        public IndividualTax(String taxName, Decimal taxValue) {
            this.TaxName = taxName;
            this.TaxValue = (taxValue != null) ? taxValue.setScale(2, RoundingMode.HALF_UP) : 0;
        }
    }
    
   public class DealDetails {
        public List<DealUnitDetails> UnitList {get; private set;}
        public List<DealTradeInDetails> TradeInList {get; private set;}
        public DealWrapper.DealFinanceWrapper DealFinanceObj {get; set;}
        public Decimal DealTotal {get; set;}
        public String DealType {get; private set;}
        public List<String> NotesForCustomer {get; private set;}
        public Decimal DueFromCustomer {get; set;}
        public Decimal DueFromFinancing {get; set;}
        public String CoBuyerName {get; set;}
        public String Salespersons {get; set;}

        public DealDetails(List<Deal_Item__c> dealItemList, List<Deal_Finance__c> dealFinanceList) {
            this.UnitList = new List<DealUnitDetails>();
            this.TradeInList = new List<DealTradeInDetails>();
            this.DealTotal = this.DueFromCustomer = this.DueFromFinancing = 0;
            
            /* Start: Added by richa 14 april */
            Set<Id> dealItemIds = new Set<Id>();
            
            for(Deal_Item__c dealItemRec : dealItemList) {
                dealItemIds.add(dealItemRec.Id);
                this.DealType = dealItemRec.Deal__r.Type__c;
                this.Salespersons = (String.isNotBlank(dealItemRec.Deal__r.Salesperson_Name__c) ? dealItemRec.Deal__r.Salesperson_Name__c : dealItemRec.Deal__r.CO_Header__r.Owner__r.Name);
                this.CoBuyerName = dealItemRec.Deal__r.Co_Buyer__c != null ? dealItemRec.Deal__r.Co_Buyer__r.Name : null;
                this.NotesForCustomer = (dealItemRec.Deal__r.Notes_For_Customer__c != null) ?  dealItemRec.Deal__r.Notes_For_Customer__c.split('\n') : new List<String>();
            }
            if(dealFinanceList.size() > 0) {
                this.DealFinanceObj = new DealWrapper.DealFinanceWrapper(dealFinanceList[0]);
            }
            
            Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
            List<Deal_Kit_Header__c> dealKitHeaderList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealItemIds));
            for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderList) {
                if(dealItemIdToDKHListMap.containsKey(dealKitHeaderRec.Deal_Item__c)) {
                    List<Deal_Kit_Header__c> dealKitHeaders = dealItemIdToDKHListMap.get(dealKitHeaderRec.Deal_Item__c);
                    dealKitHeaders.add(dealKitHeaderRec);
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, dealKitHeaders);
                } else {
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, new List<Deal_Kit_Header__c>{dealKitHeaderRec});
                }
            }
            /* End: Added by richa 14 april */
            
            for(Deal_Item__c dealItemRec : dealItemList) {
                if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT) {
                    //this.UnitList.add(new DealUnitDetails(dealItemRec)); // Commented by richa 14 april
                    List<Deal_Kit_Header__c> dealKitHeaders = new List<Deal_Kit_Header__c>();
                    if(dealItemIdToDKHListMap.containsKey(dealItemRec.Id)) {
                        dealKitHeaders = dealItemIdToDKHListMap.get(dealItemRec.Id);
                    }
                    this.UnitList.add(new DealUnitDetails(dealItemRec, dealKitHeaders)); // Added by richa 14 april
                } else if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                    this.TradeInList.add(new DealTradeInDetails(dealItemRec));
                }
            }
        }
    }
    
    public class DealUnitDetails {
    public String ItemDesc {get; private set;}
    public Decimal BaseUnitPriceTotal {get; private set;}
    public Decimal BaseUnitPriceTax {get; private set;}
    public Decimal DealUnitPriceAndCostTotal {get; set;}
    public List<DealWrapper.FactoryOption> FactoryOptionList {get; private set;}
    public List<DealWrapper.DealerInstalledOption> DealerOptionList {get; private set;}
    public List<DealWrapper.OptionAndFeeInfo> OptionAndFeeList {get; private set;}
    public List<DealWrapper.DealKitHeader> DealKitHeaderList {get; private set;}
        
        public DealUnitDetails(Deal_Item__c dealItemRec) {
            this.BaseUnitPriceTotal = 0;
            this.BaseUnitPriceTax = 0;
            this.DealUnitPriceAndCostTotal = 0;
            this.FactoryOptionList = new List<DealWrapper.FactoryOption>();
            this.DealerOptionList = new List<DealWrapper.DealerInstalledOption>();
            this.OptionAndFeeList = new List<DealWrapper.OptionAndFeeInfo>();
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing(); 
            
            this.ItemDesc = getDescriptionOfUnit(dealItemRec);
            
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                DealWrapper.OptionAndFeeInfo optionAndFeeObj = new DealWrapper.OptionAndFeeInfo(optionAndFeeRec);
                this.OptionAndFeeList.add(new DealWrapper.OptionAndFeeInfo(optionAndFeeRec));
            }
            
            for(Deal_Unit_Price_Cost__c DealUnitpriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r){
                if(DealUnitpriceCostRec.Type__c != 'Factory' && (DealUnitpriceCostRec.Total_Price__c == null || DealUnitpriceCostRec.Total_Price__c == 0)) {
    				continue;
            	}
            	
            	if(DealUnitpriceCostRec.Price__c == null) {
                    DealUnitpriceCostRec.Price__c = 0;
                }
                if(DealUnitpriceCostRec.Qty__c == null) {
                    DealUnitpriceCostRec.Qty__c = 0;
                }
                if(DealUnitpriceCostRec.Sales_Tax_Percentage__c == null) {
                    DealUnitpriceCostRec.Sales_Tax_Percentage__c = 0;
                }
                    
                if(DealUnitpriceCostRec.Type__c == 'Factory'){
                    DealWrapper.FactoryOption factoryOptionRec = new DealWrapper.FactoryOption(DealUnitpriceCostRec);
                    factoryOptionRec.SalesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP)) * DealUnitpriceCostRec.Price__c.setScale(2, RoundingMode.HALF_UP) * (DealUnitpriceCostRec.Qty__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.FactoryOptionList.add(factoryOptionRec);
                    
                } else if(DealUnitpriceCostRec.Type__c == 'Dealer') {
                    DealWrapper.DealerInstalledOption dealerInstalledOptionRec = new DealWrapper.DealerInstalledOption(DealUnitpriceCostRec);
                    dealerInstalledOptionRec.SalesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP)) * DealUnitpriceCostRec.Price__c.setScale(2, RoundingMode.HALF_UP) * (DealUnitpriceCostRec.Qty__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.DealerOptionList.add(dealerInstalledOptionRec);
                    
                } else if(DealUnitpriceCostRec.Type__c == 'Base') {
                    Decimal salesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c * DealUnitpriceCostRec.Price__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.BaseUnitPriceTax += salesTax;
                    
                    if(isTaxIncludingPricing) {
	                    this.BaseUnitPriceTotal += (DealUnitpriceCostRec.Price_When_Tax_Included__c != null) ? (DealUnitpriceCostRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : 
	                    	DealUnitpriceCostRec.Price__c + salesTax;
                    } else {
                    	this.BaseUnitPriceTotal += DealUnitpriceCostRec.Price__c;
                    }
                }
            }
            
            this.BaseUnitPriceTotal = this.BaseUnitPriceTotal.setScale(2, RoundingMode.HALF_UP);
            this.BaseUnitPriceTax = this.BaseUnitPriceTax.setScale(2, RoundingMode.HALF_UP);
        }
        
        public DealUnitDetails(Deal_Item__c dealItemRec, List<Deal_Kit_Header__c> dealKitHeaderList) {
            this.BaseUnitPriceTotal = 0;
            this.BaseUnitPriceTax = 0;
            this.DealUnitPriceAndCostTotal = 0;
            this.FactoryOptionList = new List<DealWrapper.FactoryOption>();
            this.DealerOptionList = new List<DealWrapper.DealerInstalledOption>();
            this.OptionAndFeeList = new List<DealWrapper.OptionAndFeeInfo>();
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing(); 
            
            this.ItemDesc = getDescriptionOfUnit(dealItemRec);
            
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                DealWrapper.OptionAndFeeInfo optionAndFeeObj = new DealWrapper.OptionAndFeeInfo(optionAndFeeRec);
                this.OptionAndFeeList.add(new DealWrapper.OptionAndFeeInfo(optionAndFeeRec));
            }
            
            for(Deal_Unit_Price_Cost__c DealUnitpriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r){
                if(DealUnitpriceCostRec.Type__c != 'Factory' && (DealUnitpriceCostRec.Total_Price__c == null || DealUnitpriceCostRec.Total_Price__c == 0)) {
    				continue;
            	}
            	 
                if(DealUnitpriceCostRec.Price__c == null) {
                    DealUnitpriceCostRec.Price__c = 0;
                }
                if(DealUnitpriceCostRec.Qty__c == null) {
                    DealUnitpriceCostRec.Qty__c = 0;
                }
                if(DealUnitpriceCostRec.Sales_Tax_Percentage__c == null) {
                    DealUnitpriceCostRec.Sales_Tax_Percentage__c = 0;
                }
                
                if(DealUnitpriceCostRec.Type__c == 'Factory'){
                    DealWrapper.FactoryOption factoryOptionRec = new DealWrapper.FactoryOption(DealUnitpriceCostRec);
                    factoryOptionRec.SalesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP)) * DealUnitpriceCostRec.Price__c.setScale(2, RoundingMode.HALF_UP) * (DealUnitpriceCostRec.Qty__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.FactoryOptionList.add(factoryOptionRec);
                    
                } else if(DealUnitpriceCostRec.Type__c == 'Dealer') {
                    DealWrapper.DealerInstalledOption dealerInstalledOptionRec = new DealWrapper.DealerInstalledOption(DealUnitpriceCostRec);
                    dealerInstalledOptionRec.SalesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP)) * DealUnitpriceCostRec.Price__c.setScale(2, RoundingMode.HALF_UP) * (DealUnitpriceCostRec.Qty__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.DealerOptionList.add(dealerInstalledOptionRec);
                    
                } else if(DealUnitpriceCostRec.Type__c == 'Base') {
                    Decimal salesTax = ((DealUnitpriceCostRec.Sales_Tax_Percentage__c * DealUnitpriceCostRec.Price__c) / 100).setScale(2, RoundingMode.HALF_UP);
                    this.BaseUnitPriceTax += salesTax;
                    
                    if(isTaxIncludingPricing) {
	                    this.BaseUnitPriceTotal += (DealUnitpriceCostRec.Price_When_Tax_Included__c != null) ? (DealUnitpriceCostRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP) : 
	                    	DealUnitpriceCostRec.Price__c + salesTax;
                    } else {
                    	this.BaseUnitPriceTotal += DealUnitpriceCostRec.Price__c;
                    }
                
                }
            }
            this.BaseUnitPriceTotal = this.BaseUnitPriceTotal.setScale(2, RoundingMode.HALF_UP);
            this.BaseUnitPriceTax = this.BaseUnitPriceTax.setScale(2, RoundingMode.HALF_UP);
            
            this.DealKitHeaderList = new List<DealWrapper.DealKitHeader>();
            this.DealKitHeaderList = getDealKitHeaderList(dealItemRec.Options_Fees__r, dealKitHeaderList);
        }
    }
    
    public class DealTradeInDetails {
      public String ItemDesc {get; private set;}
      public Decimal AgreedValue {get; private set;}
      public Decimal SalesTax {get; private set;}
        
        public DealTradeInDetails(Deal_Item__c dealItemRec) {
            this.AgreedValue = 0;
            this.SalesTax = 0;
            this.ItemDesc = getDescriptionOfUnit(dealItemRec);
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            this.AgreedValue = (dealItemRec.Agreed_Value__c != null) ? -dealItemRec.Agreed_Value__c : 0;
            if(dealItemRec.Default_Unit_Sales_Tax_Percentage__c == null) {
                dealItemRec.Default_Unit_Sales_Tax_Percentage__c = 0;
            }
            if(isTaxIncludingPricing) {
                this.SalesTax = this.AgreedValue - (this.AgreedValue / (1 + (dealItemRec.Default_Unit_Sales_Tax_Percentage__c / 100)));
            } else {
                this.SalesTax = ((this.AgreedValue * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP);
            }
        }
    }
    
    public class TaxDetail{
      public String TaxName {get; private set;}
      public Decimal TaxAmount {get; private set;}
        
        public TaxDetail(String taxName, Decimal taxAmount){
            if(taxAmount == null){
                taxAmount = 0;
            }
            this.TaxName = taxName;
            this.TaxAmount = taxAmount;
        }
        
    }
    
    public static List<DealWrapper.DealKitHeader> getDealKitHeaderList(List<Option_Fee__c> optionAndFeeListObj, List<Deal_Kit_Header__c> dealKitHeaders) {

        List<DealWrapper.DealKitHeader> dealKitHeaderObjList = new List<DealWrapper.DealKitHeader>();
        List<DateTime> sortedDateTimeList = new List<dateTime>();
        Set<Id> optionAndFeeIdSet = new Set<Id>();
        for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaders) {
            sortedDateTimeList.add(dealKitHeaderRec.CreatedDate);
            
            dealKitHeaderObjList.add(new DealWrapper.DealKitHeader(dealKitHeaderRec, dealKitHeaderRec.Options_Fees__r, true));
            for(Option_Fee__c optionAndFeeRec : dealKitHeaderRec.Options_Fees__r) {
                optionAndFeeIdSet.add(optionAndFeeRec.Id);
            } 
        } 
        
        Integer lastIndexValue = 0;
        for(Option_Fee__c optionAndFeeRec : optionAndFeeListObj) {
            if(!optionAndFeeIdSet.contains(optionAndFeeRec.Id)) {
                for(Integer i = lastIndexValue; i < sortedDateTimeList.size(); i++){
                    system.debug(i);
                    if(sortedDateTimeList[i] < optionAndFeeRec.CreatedDate){
                        lastIndexValue ++;
                    } else {
                        break;
                    }
                }
                if(dealKitHeaderObjList.size() > lastIndexValue){
                    dealKitHeaderObjList.add(lastIndexValue, new DealWrapper.DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    
                    if(sortedDateTimeList.size() > lastIndexValue){
                        sortedDateTimeList.add(lastIndexValue, optionAndFeeRec.CreatedDate);
                    } else {
                        sortedDateTimeList.add(optionAndFeeRec.CreatedDate);
                    }
                    
                    lastIndexValue++;
                } else {
                    dealKitHeaderObjList.add(new DealWrapper.DealKitHeader(new Deal_Kit_Header__c(), new List<Option_Fee__c>{optionAndFeeRec}, false));
                    lastIndexValue++;
                }
            }
        }
        return dealKitHeaderObjList;
    }
    
    private static String getDescriptionOfUnit(Deal_Item__c dealItemRec) {
        String itemDesc = '';
        if(dealItemRec.Customer_Owned_Unit__c == null) {
            itemDesc += (dealItemRec.Year__c != null) ? (dealItemRec.Year__c + ' '): '';
            if(dealItemRec.Unit_Make__c != null) {
                itemDesc += (dealItemRec.Unit_Make__r.Name != null) ? (dealItemRec.Unit_Make__r.Name + ' ') : '';
            }
            if(dealItemRec.Unit_Model__c != null) {
                itemDesc += (dealItemRec.Unit_Model__r.Name__c != null) ? (dealItemRec.Unit_Model__r.Name__c + ' '): '';
                itemDesc += (dealItemRec.Unit_Model__r.Sub_Model__c != null) ? (dealItemRec.Unit_Model__r.Sub_Model__c) : '';
            }
        } else {
            itemDesc += (dealItemRec.Customer_Owned_Unit__r.VIN_Number__c == null) ? 'VIN Unknown ' : dealItemRec.Customer_Owned_Unit__r.VIN_Number__c + ' ';
            itemDesc += (dealItemRec.Customer_Owned_Unit__r.Year__c != null) ? (dealItemRec.Customer_Owned_Unit__r.Year__c + ' '): '';
            
            if(dealItemRec.Customer_Owned_Unit__r.Unit_Make__c != null) {
                itemDesc += (dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name != null) ? (dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name + ' ') : '';
            }
            if(dealItemRec.Customer_Owned_Unit__r.Unit_Model__c != null) {
                itemDesc += (dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null) ? (dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c + ' '): '';
                itemDesc += (dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null) ? (dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c ) : '';
            }
        }
        return itemDesc;
    }

    public static Map<Id, List<Service_Order_Kit_Header__c>> getSOIdToSOKitHeaderListMap(List<Service_Order_Header__c> soHeadersList) {
        Set<Id> soHeaderIdSet = new Set<Id>();
        for(Service_Order_Header__c soHeader: soHeadersList) {
            soHeaderIdSet.add(soHeader.Id);
        }
        List<Service_Order_Kit_Header__c> sokitHeadersList = SOQLUtil.getSOKHBySOHeaderId(soHeaderIdSet);
        Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKitHeaderListMap = new Map<Id, List<Service_Order_Kit_Header__c>>();
        for(Service_Order_Kit_Header__c sokhRec: sokitHeadersList) {
            if(!soHeaderIdToSOKitHeaderListMap.containsKey(sokhRec.Service_Order_Header__c)) {
                soHeaderIdToSOKitHeaderListMap.put(sokhRec.Service_Order_Header__c, new List<Service_Order_Kit_Header__c>());
            }
            soHeaderIdToSOKitHeaderListMap.get(sokhRec.Service_Order_Header__c).add(sokhRec);
        }
        return soHeaderIdToSOKitHeaderListMap;
    }
    
    public static String formatphonenumber(String cphone) {
        String fphone = cphone.replaceAll('\\D','');
        if(fphone.length() == 10) {
            fphone = formatphonenum(fphone);
            return fphone;
        } else {
            return cphone;
        }
    }
        
    static String formatphonenum (String s) {
        s = '(' + s.substring(0, 3) + ') ' + s.substring(3, 6) + '-' + s.substring(6);
        return s;
    }

    public class SelectedSectionsWrapper {
        public String sectionName;
        public String sectionId;
    }
}
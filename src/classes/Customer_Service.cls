public without sharing class Customer_Service {

    public static List<IFW_IntegrationConfig__c> integrationConfigList;

    public static List<Customer> getCustomerList() {
    	List<Account> customerList = [Select Id, Name from Account where Is_Customer__c = true AND Active__c = true Order By Name ASC];
    	List<Customer> customerObjList = new List<Customer>();
    	for(Account customerRec : customerList) {
    		customerObjList.add(new Customer(customerRec.Id, customerRec.Name));
    	}
    	return customerObjList;
    }
	
    public static String addCustomerToCO(String coId, String customerId) {
    	try{
            if(String.isBlank(coId)) {
                coId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder());
            } else {
                COTriggerHelper.isRetainItemPrices = true;
            }
            updateCOWithCustomer(BPUtility.escapeSingleQuotes(coId), customerId);
            return System.JSON.serialize(new ResponseWrapper(200, 'success'));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void updateCOWithCustomer(String coHeaderId, String customerId) {
        CO_Header__c coHeaderRec = new CO_Header__c(
            Id = coHeaderId,
            Customer__c = customerId,
            Customer_Shipping_Address__c = null,
            Customer_Contact__c = null,
            Parts_Bulk_Discount_Percent__c = 0,
            Fees_Bulk_Discount_Percent__c = 0,
            Is_Tax_Based_On_Customer_Address__c = false
        );
        Account newCustomerRec;
    	if(String.isBlank(customerId)) {
            coHeaderRec.CO_Type__c = Constants.CASH_SALE;
            coHeaderRec.Selling_Group__c = Constants.CASH_SALE;
        } else {
            coHeaderRec.CO_Type__c = Constants.CHECKOUT_TYPE_CUSTOMER;
            coHeaderRec.Selling_Group__c = Constants.PART_SALE;
            if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Account> newCustomerList = [SELECT Name, Price_Level__c, Account_Type__c FROM Account WHERE Id = :customerId];
            if(newCustomerList.size() == 0) throw new BlackPurlException(BlackPurlException.getErrorMessage('Invalid Customer Id', null));
            newCustomerRec = newCustomerList[0];
        }

        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [SELECT Customer__r.Account_Type__c, Customer__r.Price_Level__c, NumberOfDeals__c, Customer_Name__c, 
            TotalNumberOfSOHeader__c, Is_Tax_Based_On_Customer_Address__c, 
            (Select Id FROM Service_Order_Headers__r WHERE Provider__c = null AND Is_Tax_Based_On_Customer_Address__c = true LIMIT 1), 
            (Select Id FROM Deals__r WHERE Is_Tax_Based_On_Customer_Address__c = true LIMIT 1), 
            (Select Id FROM Tax_Exemptions__r WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER) 
            FROM CO_Header__c where Id = :coHeaderId];
        
        if(coHeaderList.size() == 0) throw new BlackPurlException(BlackPurlException.getErrorMessage('Invalid CO Header Id', null));
        Boolean isTaxBasedOnCustAddressOnCO = (coHeaderList[0].Is_Tax_Based_On_Customer_Address__c || !coHeaderList[0].Service_Order_Headers__r.isEmpty() || !coHeaderList[0].Deals__r.isEmpty());

        DMLUtility.deleteSobjectList('Tax_Exemption__c', coHeaderList[0].Tax_Exemptions__r);
        if(coHeaderList[0].TotalNumberOfSOHeader__c > 0) {
            updateSOHeaders(coHeaderId);
        }
        if(coHeaderList[0].NumberOfDeals__c > 0) {
            updateDealTradeIns(coHeaderId);
        }

        updateCOPricingAndTax(coHeaderRec, customerId, (isTaxBasedOnCustAddressOnCO || isCalculatePLandTax(newCustomerRec, coHeaderList[0])));
        createChangeCustomerInternalComment(newCustomerRec, coHeaderList[0]);
    }

    private static void createChangeCustomerInternalComment(Account newCustomerRec, CO_Header__c existingCOHeaderRec) {
        String comment = 'Customer changed from ';
        comment += (existingCOHeaderRec.Customer__c == null ? existingCOHeaderRec.Customer_Name__c : '<a href="#/ViewCustomer?Id='+ existingCOHeaderRec.Customer__c +'" target="_blank">' + existingCOHeaderRec.Customer_Name__c + '</a>');
        comment += ' to ';
        comment += (newCustomerRec == null ? 'CASH SALE' : '<a href="#/ViewCustomer?Id='+ newCustomerRec.Id +'" target="_blank">' + newCustomerRec.Name + '</a>.');
        COService.addInternalCommentToCO(existingCOHeaderRec.Id, comment);
    }

    private static Boolean isCalculatePLandTax(Account newCustomerRec, CO_Header__c existingCOHeaderRec) {
        String oldPriceLevel = existingCOHeaderRec.Customer__r.Price_Level__c;
        String oldAccountType = existingCOHeaderRec.Customer__r.Account_Type__c;
        String newPriceLevel, newAccountType;
        
        if(existingCOHeaderRec.Is_Tax_Based_On_Customer_Address__c || !existingCOHeaderRec.Service_Order_Headers__r.isEmpty() || !existingCOHeaderRec.Deals__r.isEmpty()) {
            return true;
        } else if(String.isBlank(existingCOHeaderRec.Customer__c) || newCustomerRec == null) {
            List<Price_Level__c> priceLevelList = [SELECT Id FROM Price_Level__c WHERE Default__c = true LIMIT 1];
            List<Account_Type__c> accountTypeList = [SELECT Id FROM Account_Type__c WHERE Default__c = true AND Applies_To__c = 'Customers' LIMIT 1]; 
            
            if(priceLevelList.size() > 0) {
                if(String.isBlank(existingCOHeaderRec.Customer__c)) {
                    oldPriceLevel = priceLevelList[0].Id;
                } else {
                    newPriceLevel = priceLevelList[0].Id;
                }
            }
            if(accountTypeList.size() > 0) {
                if(String.isBlank(existingCOHeaderRec.Customer__c)) {
                    oldAccountType = accountTypeList[0].Id;
                } else {
                    newAccountType = accountTypeList[0].Id;
                }
            }
        } else if(newCustomerRec != null) {
            newPriceLevel = newCustomerRec.Price_Level__c;
            newAccountType = newCustomerRec.Account_Type__c;
        }
        
        return (newPriceLevel != oldPriceLevel || newAccountType != oldAccountType);
    }

    private static void updateSOHeaders(String coHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = [SELECT Provider__c, Job_Type__c, Customer_Owned_Unit__r.Is_Generic_Unit__c, (SELECT Id FROM Events__r) 
                                                        FROM Service_Order_Header__c WHERE CO_Header__c = :coHeaderId AND 
                                                        SO_Status__c NOT IN :ServiceJobUtil.invoiceableStatusSet AND 
                                                        Invoice_Number__c = null AND Deal__r.Invoice_Number__c = null];
        List<Event__c> appointmentsToDelete = new List<Event__c>();
        for(Service_Order_Header__c soHeader: soHeaderList) {
            if(!soHeader.Customer_Owned_Unit__r.Is_Generic_Unit__c) soHeader.Customer_Owned_Unit__c = null;
            soHeader.Parts_Bulk_Discount_Percent__c = 0;
            soHeader.Fees_Bulk_Discount_Percent__c = 0;
            soHeader.Labor_Bulk_Discount_Percent__c = 0;
            soHeader.Sublet_Bulk_Discount_Percent__c = 0;
            soHeader.Is_Tax_Based_On_Customer_Address__c = false;
            appointmentsToDelete.addAll(soHeader.Events__r);
        }
        
        if(soHeaderList.size() > 0) {
            if(appointmentsToDelete.size() > 0) {
                delete appointmentsToDelete;
            }
            SOTriggerHelper.updatePLFields(soHeaderList);
    		SOTriggerHelper.refreshTaxExemptions = true;
            update soHeaderList;
        }
    }

    private static void updateDealTradeIns(String coHeaderId) {
        List<Deal__c> dealList = [Select Id, Is_Tax_Based_On_Customer_Address__c, (SELECT Id, Deal__c FROM Deal_Items__r WHERE Type__c = :Constants.DEAL_ITEM_TYPE_TRADE_IN AND Is_Stocked_In__c = false) FROM Deal__c WHERE CO_Header__c =: coHeaderId];
        if(!dealList.isEmpty()) {
            if(!dealList[0].Deal_Items__r.isEmpty()) {
                DealItemTriggerHelper.isForceStopTrigger = true;
                delete dealList[0].Deal_Items__r;
                DealItemTriggerHelper.isForceStopTrigger = false;
            }
            if(dealList[0].Is_Tax_Based_On_Customer_Address__c) {
                dealList[0].Is_Tax_Based_On_Customer_Address__c = false;
                DealTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Deal__c', dealList);
                DealTriggerHelper.isForceStopTrigger = false;
            }
        }
    }
    
    private static void updateCOPricingAndTax(CO_Header__c coHeaderRec, String customerId, Boolean isCalculatePLandTax){ 
        if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        try {
            setTriggerFlagsForPLAndTaxCalc(isCalculatePLandTax);
            update coHeaderRec;
            resetTriggerFlagsAfterPLAndTaxCalc();
            
            COKH_Recalcualtion.changePriceWhenCustomerIsChanged(coHeaderRec.Id);
            SO_KLI_Recalculation.changePriceWhenCustomerIsChanged(new Set<Id>(), coHeaderRec.Id);
            DealKH_Recalculation.changePriceWhenCustomerIsChanged(customerId, coHeaderRec.Id);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    private static void setTriggerFlagsForPLAndTaxCalc(Boolean isCalculatePLandTax) {
        COTriggerHelper.isCalculatePLandTax = isCalculatePLandTax;
        COLineItemTriggerHelper.isCalculatePriceLevel = false;
        COLineItemTriggerHelper.isTotalCalculated = true;
        COTriggerHelper.isRecalculateCOPLAndTax = true;
    }

    private static void resetTriggerFlagsAfterPLAndTaxCalc() {
        COLineItemTriggerHelper.isTotalCalculated = false;
    }
    
    public static CustomerInvoiceHistory getInvoiceHistory(String customerId, String invoicePageSortAttrsJSON) {
        PaginationSorting invoiceSortAttrs = (PaginationSorting) System.JSON.deserialize(invoicePageSortAttrsJSON, PaginationSorting.class);
        
        if(!AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> invoiceList = 
            [SELECT CO_Header__c, Invoice_Number__c, Invoice_Date__c, Total__c, Checkout_Type__c, 
                (SELECT Deal__c, SO_Payment_Role__r.RecordType.DeveloperName, Service_Order_Header__c, CO_Line_Item__c, CO_Kit_Header__c,
                        Service_Order_Header__r.SO_Concern__c, CO_Line_Item__r.Part__c, CO_Line_Item__r.Part__r.Part_Number__c,
                        CO_Line_Item__r.Fee__c, CO_Line_Item__r.Fee__r.Code__c, CO_Kit_Header__r.Kit_Header__r.Code__c, CO_Line_Item__r.Deal__c 
                        FROM CO_Invoice_Items__r WHERE CO_Line_Item__r.Deal__c = null AND Service_Order_Header__r.Deal__c = null) 
             FROM CO_Invoice_Header__c WHERE CO_Header__r.Customer__c =: customerId AND Invoice_Status__c = 'Closed' AND Checkout_Type__c != 'Deal'
                ORDER BY Invoice_Date__c DESC];
        
        Integer totalInvoice = invoiceList.size();
        Decimal invoicesTotalAmount = 0; 
        for(CO_Invoice_Header__c invoiceRec : invoiceList) {
            invoicesTotalAmount += invoiceRec.Total__c != null ? invoiceRec.Total__c : 0;
        }
        invoiceList = TaxExemption.getPaginatedRecords(invoiceList, invoiceSortAttrs.CurrentPage, invoiceSortAttrs.PageSize);
        
        CustomerInvoiceHistory invoiceHistoryObj = new CustomerInvoiceHistory(invoiceList, totalInvoice);
        invoiceHistoryObj.InvoicesTotalAmount = invoicesTotalAmount;
        return invoiceHistoryObj;
    }
    
    public static String getARPaymentsByCustomerAccId(String customerId, Boolean isInvoiceIncluded) {
    	try {
	    	List<ARPaymentWrapper> ARPaymentObjList = getARPaymentsByCustAccId(customerId, isInvoiceIncluded);
            if(isInvoiceIncluded) {
    		    return BPUtility.getEncodedString(System.JSON.serialize(ARPaymentObjList));
            }
            return (ARPaymentObjList.size() > 0) ? BPUtility.getEncodedString(System.JSON.serialize(ARPaymentObjList, true)) : BPUtility.getEncodedString(System.JSON.serialize('No unapplied credits returned, please select a different payment method.'));
    	} catch(BlackPurlException ex) {
            if(ex.getMessage().contains('Error fetching data from Xero') || ex.getMessage().contains('Error fetching unapplied payments from Quickbooks online')) {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', ex.getMessage())));
            } else {
                throw ex;
            }
        } catch (Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }

    public static void saveIFWConfig() {
        if(integrationConfigList != null && !integrationConfigList.isEmpty()) {
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationConfigList);
        }
    }

    public static List<ARPaymentWrapper> getARPaymentsByCustAccId(String customerId, Boolean isInvoiceIncluded) {
        return getARPaymentsByCustAccId(customerId, isInvoiceIncluded, true);
    }

    public static List<ARPaymentWrapper> getARPaymentsByCustAccId(String customerId, Boolean isInvoiceIncluded, Boolean performDML) {
        List<ARPaymentWrapper> ARPaymentObjList = new List<ARPaymentWrapper>();
        List<Account> customerRecList = [Select AccountingId__c, Xero_Customer_Accounting_Id__c from Account where Id =: customerId];
        if(customerRecList.size() > 0) {
            Set<String> failedARCreditIds = new Set<String>();
            List<IFW_IntegrationConfig__c> integrationConfigList;
            if(!QBUtil.isQBEnabled()) {
                BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
                if(integrationRec != null) {
                    if(integrationRec.integrationName == 'Xero') {
                        if(String.isBlank(customerRecList[0].Xero_Customer_Accounting_Id__c)) {
                            throw new BlackPurlException('Customer is not synced to Xero');
                        }
                        
                        integrationConfigList = BaseIntegration.getParentByName('Xero');
                        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
                        String whereClause;
                        XeroResponseWrapper responseWrapper;
                        Boolean errorFetchingData = false;
                        if(isInvoiceIncluded) {
                            whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&AmountDue!=0&&Status!="VOIDED"&&Status!="DELETED"';
                            responseWrapper = XeroService.getDataFromXero('Invoice', whereClause, integrationConfigList[0]);
                            if(responseWrapper == null) {
                                errorFetchingData = true;
                            } else {
                                for(XeroInvoiceDTO xeroInvoice : responseWrapper.Invoices) {
                                    ARPaymentObjList.add(new ARPaymentWrapper(xeroInvoice));
                                }
                            }
                        }
                        
                        List<XeroCreditNoteDTO> xeroCreditNotesList = new List<XeroCreditNoteDTO>();
                        List<XeroUnappliedPaymentDTO> xeroOverPaymentsList = new List<XeroUnappliedPaymentDTO>();
                        List<XeroUnappliedPaymentDTO> xeroPrePaymentsList = new List<XeroUnappliedPaymentDTO>();
                        
                        // fetch credit notes from Xero
                        if(!errorFetchingData) {
                            whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&RemainingCredit!=0&&Status!="VOIDED"&&Status!="DELETED"';
                            responseWrapper = XeroService.getDataFromXero('Credit Note', whereClause, integrationConfigList[0]);
                            if(responseWrapper == null) {
                                errorFetchingData = true;
                            } else {
                                xeroCreditNotesList = responseWrapper.CreditNotes;
                            }
                        }

                        // fetch pre payments from xero
                        if(!errorFetchingData) {
                            whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&Status!="VOIDED"';
                            responseWrapper = XeroService.getDataFromXero('Prepayment', whereClause, integrationConfigList[0]);
                            if(responseWrapper == null) {
                                errorFetchingData = true;
                            } else {
                                xeroPrePaymentsList = responseWrapper.Prepayments;
                            }
                        }

                        // fetch over payments from xero
                        if(!errorFetchingData) {
                            whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&Status!="VOIDED"';
                            responseWrapper = XeroService.getDataFromXero('Overpayment', whereClause, integrationConfigList[0]);
                            if(responseWrapper == null) {
                                errorFetchingData = true;
                            } else {
                                xeroOverPaymentsList = responseWrapper.Overpayments;
                            }
                        }
                        if(performDML) {
                            update integrationConfigList;
                        }
                        if(errorFetchingData) {
                            throw new BlackPurlException('Error fetching data from Xero');
                        }

                        // get ar payments not synced to Xero if there are unapplied credits present in Xero
                        if(xeroCreditNotesList.size() > 0 || xeroPrePaymentsList.size() > 0 || xeroOverPaymentsList.size() > 0) {
                            failedARCreditIds = getFailedARCreditSet('XERO');
                        }
                        
                        for(XeroCreditNoteDTO xeroCreditNote : xeroCreditNotesList) {
                            if(!failedARCreditIds.contains(xeroCreditNote.CreditNoteID)) {
                                ARPaymentObjList.add(new ARPaymentWrapper(xeroCreditNote));
                            }
                        }

                        Integer paymentCounter = 1;
                        for(XeroUnappliedPaymentDTO xeroPrePayment : xeroPrePaymentsList) {
                            if(!failedARCreditIds.contains(xeroPrePayment.PrepaymentID) && xeroPrePayment.RemainingCredit != 0) {
                                if(String.isBlank(xeroPrePayment.Reference)) {
                                    xeroPrePayment.Reference = AccountingUtil.UNAPPLIED_PAYMENT + ' ' + paymentCounter;
                                    paymentCounter++;
                                }
                                ARPaymentObjList.add(new ARPaymentWrapper(xeroPrePayment));
                            }
                        }

                        for(XeroUnappliedPaymentDTO xeroOverPayment : xeroOverPaymentsList) {
                            if(!failedARCreditIds.contains(xeroOverPayment.OverpaymentID) && xeroOverPayment.RemainingCredit != 0) {
                                if(String.isBlank(xeroOverPayment.Reference)) {
                                    xeroOverPayment.Reference = AccountingUtil.UNAPPLIED_PAYMENT + ' ' + paymentCounter;
                                    paymentCounter++;
                                }
                                ARPaymentObjList.add(new ARPaymentWrapper(xeroOverPayment));
                            }
                        }
                    }
                }
            } else {
                if(String.isBlank(customerRecList[0].AccountingId__c)) {
                    throw new BlackPurlException('Customer is not synced to QB');
                }
                integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
                if(integrationConfigList.isEmpty()) throw new BlackPurlException('IFW record for ' + QBUtil.QUICKBOOKS_ONLINE + ' doesn\'t exists');
                try{
                    if(isInvoiceIncluded) {
                        List<QBInvoiceDTO> unpaidInvoiceList = QBService.getUnpaidInvoicesFromQB(customerRecList[0].AccountingId__c, integrationConfigList[0], null);
                        for(QBInvoiceDTO qbInvoice : unpaidInvoiceList) {
                            ARPaymentObjList.add(new ARPaymentWrapper(qbInvoice, 'Invoice'));
                        }
                    }
                    List<QBInvoiceDTO> unappliedCreditList = QBService.getUnappliedCreditsFromQB(customerRecList[0].AccountingId__c, integrationConfigList[0], null);

                    List<QBPaymentDTO> unappliedPaymentList = QBService.getUnappliedPaymentsFromQB(customerRecList[0].AccountingId__c, integrationConfigList[0]);


                    // get ar payments not synced to QB if there are unapplied credits present in QB
                    if(unappliedCreditList.size() > 0 || unappliedPaymentList.size() > 0) {
                        failedARCreditIds = getFailedARCreditSet('QB');
                    }
                    
                    for(QBInvoiceDTO qbInvoice : unappliedCreditList) {
                        if(!failedARCreditIds.contains(qbInvoice.Id)) {
                            ARPaymentObjList.add(new ARPaymentWrapper(qbInvoice, 'CreditMemo'));
                        }
                    }
                    
                    Integer paymentCounter = 1;
                    for(QBPaymentDTO qbPayment : unappliedPaymentList) {
                        if(qbPayment.UnappliedAmt != 0 && !failedARCreditIds.contains(qbPayment.Id)) {
                            if(string.isBlank(qbPayment.PaymentRefNum)) {
                                qbPayment.PaymentRefNum = AccountingUtil.UNAPPLIED_PAYMENT + ' ' + paymentCounter;
                                paymentCounter++;
                            }
                            ARPaymentObjList.add(new ARPaymentWrapper(qbPayment));
                        }
                    }
                } catch (Exception e) {
                    if(performDML) {
                        QBCalloutManager.updateRecords(integrationConfigList[0]);
                    }
                    throw new BlackPurlException('Error fetching unapplied payments from Quickbooks online');
                }
                if(performDML) {
                    QBCalloutManager.updateRecords(integrationConfigList[0]);
                }
            }
        }
        ARPaymentObjList.sort();
        return ARPaymentObjList;
    }

    public static String getPaidCOAInvoiceList(String customerId, String paidCOAInvoicePageSortAttrsJSON) {
        PaginationSorting invoiceSortAttrs = (PaginationSorting)System.JSON.deserialize(paidCOAInvoicePageSortAttrsJSON, PaginationSorting.class);
        List<ARPaymentWrapper> arPaymentObjList = new List<ARPaymentWrapper>();
        String query = 'SELECT AccountingId__c, Xero_Accounting_Id__c, Total__c, Invoice_Number__c, Invoice_Date__c FROM CO_Invoice_Header__c WHERE CO_Header__r.Customer__c =: customerId AND Total_Charge_On_Account__c != 0 AND AR_Balance__c = 0 AND ';
        query += QBUtil.isQBEnabled() ? 'AccountingId__c != null' : 'Xero_Accounting_Id__c != null';
        query += ' ORDER BY Invoice_Date__c DESC, Invoice_Number__c DESC';
        List<CO_Invoice_Header__c> coInvRecList = Database.query(query);
        Integer totalInvoice = coInvRecList.size();
        coInvRecList = TaxExemption.getPaginatedRecords(coInvRecList, invoiceSortAttrs.CurrentPage, invoiceSortAttrs.PageSize);
        for(CO_Invoice_Header__c coInvRec : coInvRecList) {
            arPaymentObjList.add(new ARPaymentWrapper(coInvRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new Map<String, Object>{
                                                                                            'TotalPaidCOAInvoiceRecords' => totalInvoice,
                                                                                            'PaidCOAInvoiceList' => arPaymentObjList
                                                                                        }));
    }

    public static String getPOAHistoryList(String customerId, String poaHistoryPageSortAttrsJSON) {
        PaginationSorting invoiceSortAttrs = (PaginationSorting)System.JSON.deserialize(poaHistoryPageSortAttrsJSON, PaginationSorting.class);
        List<POAWrapper> poaHistoryObjList = new List<POAWrapper>();
        List<Payment_on_Account__c> poaRecList = [SELECT Id, Name, Payment_Date__c, Payment_Method__c, Reference__c, Total_Payment__c, 
                                                    (SELECT Id FROM AR_Payments__r) FROM Payment_on_Account__c 
                                                    WHERE Payment_Method__c != 'Payment Surcharge' AND Customer__c = :customerId ORDER BY CreatedDate Desc];
        Integer totalInvoice = poaRecList.size();
        poaRecList = TaxExemption.getPaginatedRecords(poaRecList, invoiceSortAttrs.CurrentPage, invoiceSortAttrs.PageSize);
        for(Payment_on_Account__c poaRec : poaRecList) {
            poaHistoryObjList.add(new POAWrapper(poaRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new Map<String, Object>{
                                                                                            'TotalPOAHistoryRecords' => totalInvoice,
                                                                                            'POAHistoryList' => poaHistoryObjList
                                                                                        }));
    }

    private static Set<String> getFailedARCreditSet(String activeIntegrationName) {
        Set<String> failedARCreditIds = new Set<String>();
        for(AR_Payment__c arPaymentRec: [SELECT Invoice_Accounting_Id__c, Payment_on_Account__r.Available_For_QB_AR_Payment_Sync__c, Available_For_Xero_Sync__c 
                FROM AR_Payment__c WHERE Amount_Paid__c < 0 AND (Payment_on_Account__r.Available_For_QB_AR_Payment_Sync__c = true 
                OR Available_For_Xero_Sync__c = true)]) {
            if(arPaymentRec.Invoice_Accounting_Id__c != null && ((activeIntegrationName == 'QB' && arPaymentRec.Payment_on_Account__r.Available_For_QB_AR_Payment_Sync__c) 
                || (activeIntegrationName == 'XERO' && arPaymentRec.Available_For_Xero_Sync__c))) {
                failedARCreditIds.add(arPaymentRec.Invoice_Accounting_Id__c);
            }
        }
        return failedARCreditIds;
    }

    public static String validateChangeCustomerAction(String coHeaderId, Boolean isCustomerDeletedFromCO) {
    	try{
            Map<String, Set<String>> validationErrorToErrorTextSetMap = new Map<String, Set<String>>();
            List<CO_Header__c> coHeaderList = [Select Id, Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, (Select Id From CO_Invoice_Headers__r Where Invoice_Status__c = 'Closed' Limit 1), (Select Work_Status__c, SO_Status__c, Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Labor_Bulk_Discount_Percent__c, Sublet_Bulk_Discount_Percent__c From Service_Order_Headers__r), 
                                        (Select Status__c From Deals__r), (Select Id From Vendor_Order_Line_Items__r Limit 1) From CO_Header__c Where Id =: coHeaderId];
            if(coHeaderList.size() > 0) {
                List<CO_Invoice_Payment__c> coipList = [Select Payment_Method__c, Amount__c From CO_Invoice_Payment__c Where (Payment_Method__c  = 'AR Credit' OR Payment_Method__c  = 'Store Credit') AND (CO_Invoice_Header__r.CO_Header__c =: coHeaderId)];
                List<CO_Deposit__c> coDepositList = [Select Payment_Method__c, Amount__c From CO_Deposit__c Where (Payment_Method__c  = 'AR Credit' OR Payment_Method__c  = 'Store Credit') AND (CO_Header__c =: coHeaderId)];
                List<Deal_Item__c> dealItemList = [Select Is_Stocked_In__c From Deal_Item__c Where Type__c = 'Trade In' AND Deal__r.CO_Header__c =: coHeaderId];
                Set<String> errorsSet = validateErrors(coHeaderList[0], coipList, coDepositList, dealItemList, isCustomerDeletedFromCO);
                if(errorsSet.size() > 0) {
                    validationErrorToErrorTextSetMap.put('Error' , errorsSet);
                } else {
                    Set<String> warningSet = validateWarnings(coHeaderList[0], dealItemList, isCustomerDeletedFromCO);
                    if(warningSet.size() > 0) {
                        validationErrorToErrorTextSetMap.put('Warnings' , warningSet);
                    }
                }
            }
            return System.JSON.serialize(validationErrorToErrorTextSetMap);
    	} catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static Set<String> validateErrors(CO_Header__c coHeaderRec, List<CO_Invoice_Payment__c> coipList, List<CO_Deposit__c> coDepositList, List<Deal_Item__c> dealItemList, Boolean isCustomerDeletedFromCO) {
        Set<String> errorsSet = new Set<String>();
        if(coHeaderRec.CO_Invoice_Headers__r.size() > 0) {
            errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_INVOICE_GENERATED);
        }

        Decimal storeCreditDepositTotal = 0;
        Decimal storeCreditPaymentTotal = 0;
        for(CO_Invoice_Payment__c coipRec : coipList) {
            if(coipRec.Payment_Method__c == 'AR Credit') {
                errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_AR_CREDIT_PAYMENT);
            } else if (coipRec.Payment_Method__c == 'Store Credit') {
                storeCreditPaymentTotal += coipRec.Amount__c != null ? coipRec.Amount__c : 0;
            }
        }

        for(CO_Deposit__c coDepositRec : coDepositList) {
            if(coDepositRec.Payment_Method__c == 'AR Credit') {
                errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_AR_CREDIT_DEPOSIT);
            } else if (coDepositRec.Payment_Method__c == 'Store Credit') {
                storeCreditDepositTotal += coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
            }
        }
        if(storeCreditPaymentTotal != 0) {
            errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_STORE_CREDIT_PAYMENT);
        }
        if(storeCreditDepositTotal != 0) {
            errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_STORE_CREDIT_DEPOSIT);
        }
        if(isCustomerDeletedFromCO) {
            if(coHeaderRec.Service_Order_Headers__r.size() > 0) {
                errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_SERVICE_JOB);
            }
            if(coHeaderRec.Deals__r.size() > 0) {
                errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_DEAL);
            }
            if(coHeaderRec.Vendor_Order_Line_Items__r.size() > 0) {
                errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_SPECIAL_ORDER);
            }
        } else {
            for(Service_Order_Header__c soRec : coHeaderRec.Service_Order_Headers__r) {
                if(ServiceJobUtil.isJobComplete(soRec.SO_Status__c)) {
                    errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_COMPLETED_SERVICE_JOB);
                }
            }

            for(Deal__c dealRec : coHeaderRec.Deals__r) {
                if(dealRec.Status__c == 'Approved') {
                    errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_APPROVED_DEAL);
                } 
            }

            for(Deal_Item__c dealItemRec : dealItemList) {
                if(dealItemRec.Is_Stocked_In__c) {
                    errorsSet.add(CustomerOrderUtil.CHANGE_CUSTOMER_ERROR_STOCKED_IN_TRADE_IN);
                }
            }
        }
        return errorsSet;
    } 

    public static Set<String> validateWarnings(CO_Header__c coHeaderRec, List<Deal_Item__c> dealItemList, Boolean isCustomerDeletedFromCO) {
        Set<String> warningSet = new Set<String>();
        if(!isCustomerDeletedFromCO) {
            if(coHeaderRec.Service_Order_Headers__r.size() > 0) {
                warningSet.add('{"HasServiceJob":"true"}');
            }
            if(dealItemList.size() > 0) {
                warningSet.add('{"HasTradeIn":"true"}');
            }

            if(coHeaderRec.Service_Order_Headers__r.size() > 0) {
                List<Event__c> appointmentList = [Select Id From Event__c Where Service_Order_Header__r.CO_Header__c =: coHeaderRec.Id];
                if(appointmentList.size() > 0) {
                    warningSet.add('{"HasServiceAppoitment":"true"}');
                }
            }
        }
        if((coHeaderRec.Parts_Bulk_Discount_Percent__c != null && coHeaderRec.Parts_Bulk_Discount_Percent__c != 0) || (coHeaderRec.Fees_Bulk_Discount_Percent__c != null && coHeaderRec.Fees_Bulk_Discount_Percent__c != 0)) {
            warningSet.add('{"HasBulkDiscount":"true"}');
        } else if(coHeaderRec.Service_Order_Headers__r.size() > 0) {
            for(Service_Order_Header__c soRec : coHeaderRec.Service_Order_Headers__r) {
                if((soRec.Parts_Bulk_Discount_Percent__c != null && soRec.Parts_Bulk_Discount_Percent__c != 0) || (soRec.Fees_Bulk_Discount_Percent__c != null && soRec.Fees_Bulk_Discount_Percent__c != 0) ||
                    (soRec.Sublet_Bulk_Discount_Percent__c != null && soRec.Sublet_Bulk_Discount_Percent__c != 0) || (soRec.Labor_Bulk_Discount_Percent__c != null && soRec.Labor_Bulk_Discount_Percent__c != 0)) {
                    warningSet.add('{"HasBulkDiscount":"true"}');
                    break;
                }
            }
        }
        return warningSet;
    } 

    public static List<Country__c> getCountryList() {
        String query = 'SELECT ' + String.join(Country.fieldsList(), ', ') + ' FROM Country__c ORDER BY Default__c DESC, Name__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(!AccessControl.ifObjectFieldIsAccessible('Country__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static List<State__c> getStateList() {
        String query = 'SELECT ' + String.join(State.fieldsList(), ', ') + ' FROM State__c ORDER BY Default__c DESC, Name__c ASC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(!AccessControl.ifObjectFieldIsAccessible('State__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static ResponseWrapper populateCustomerTaxesOnCO(Id sectionId, Id accountId, Boolean isInsert) {
        ResponseWrapper resObj = new ResponseWrapper('success', 'Customer taxes populated successfully');
        if(GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c) {
            List<Sales_Tax_Item__c> automatedTaxRateList = getCustomerTaxesByAddress(accountId);
            if(automatedTaxRateList == null || automatedTaxRateList.isEmpty()) {
                resObj = new ResponseWrapper('error', 'Customer address needs to be fully populated in order to obtain tax rates based on their address');
            } else if(isInsert) {
                createAutomatedTaxOverrideRecords(sectionId, automatedTaxRateList, TaxUtility.AUTOMATED_CUSTOMER);
            }
        }
        return resObj;
    }
    
    public static void populateStoreTaxesOnCO(Id sectionId) {
        List<Sales_Tax_Item__c> salesTaxList = [SELECT Id, Name__c, Active__c, Rate_Type__c, Rate__c, Category__c, Category__r.Name, Tax_Type__c, Is_Automated__c, Automated_Tax_Rate_Name__c FROM Sales_Tax_Item__c WHERE Active__c = true AND Is_Automated__c = true];
        createAutomatedTaxOverrideRecords(sectionId, salesTaxList, TaxUtility.AUTOMATED_STORE);
    }

    public static List<Sales_Tax_Item__c> getCustomerTaxesByAddress(Id accountId) {
        List<TaxRateWrapper.TaxRate> taxRateList = ZipTaxService.getTaxRates(accountId);
        if(taxRateList != null && !taxRateList.isEmpty()) {
            return ZipTaxService.createTaxRateRecFromAutomatedTaxRates(taxRateList);
        }
        return new List<Sales_Tax_Item__c>(); 
    }

    private static void createAutomatedTaxOverrideRecords(String sectionId, List<Sales_Tax_Item__c> automatedTaxRateList, String taxRecType) {
        if(String.isNotBlank(sectionId) && automatedTaxRateList != null && !automatedTaxRateList.isEmpty()) {
            List<String> taxExemptRecTypeList = new List<String>{taxRecType};
            String objName = ((Id.valueOf(sectionId)).getSObjectType().getDescribe().getName()).substringAfter(Constants.NAMESPACE);
            
            List<Tax_Exemption__c> taxExemptionInsertList = new List<Tax_Exemption__c>();
            for(Sales_Tax_Item__c taxRec : automatedTaxRateList) {
                if(taxRec.Is_Automated__c) {
                    Tax_Exemption__c taxExemptRec = new Tax_Exemption__c();
                    taxExemptRec.put(objName, sectionId);
                    taxExemptRec.Sales_Tax_Item__c = taxRec.Id;
                    taxExemptRec.Rate_Override__c = taxRec.Rate__c;
                    taxExemptRec.Description__c = taxRec.Automated_Tax_Rate_Name__c;
                    taxExemptRec.Type__c = taxRecType;
                    taxExemptionInsertList.add(taxExemptRec);
                }
            }
            DMLUtility.insertSobjectList('Tax_Exemption__c', taxExemptionInsertList);
        }
    }

    public static List<String> specialCharsNotAllowedInNameSet = new List<String>{':', '>', '<'};
}
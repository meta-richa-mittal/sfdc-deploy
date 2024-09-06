public without sharing class Customer_Service {

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
    		coId = String.isBlank(coId) ? BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder()) : coId;
            updateCOWithCustomer(BPUtility.escapeSingleQuotes(coId), customerId);
            return System.JSON.serialize(new ResponseWrapper(200, 'success'));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void updateCOWithCustomer(String coHeaderId, String customerId) {
        CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId, Customer__c = customerId);
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
        List<CO_Header__c> coHeaderList = [SELECT Customer__r.Account_Type__c, Customer__r.Price_Level__c, NumberOfDeals__c, 
                                            TotalNumberOfSOHeader__c, Customer_Name__c FROM CO_Header__c where Id = :coHeaderId];
        
        if(coHeaderList.size() == 0) throw new BlackPurlException(BlackPurlException.getErrorMessage('Invalid CO Header Id', null));
        if(coHeaderList[0].TotalNumberOfSOHeader__c > 0) {
            updateSOHeaders(coHeaderId);
        }
        if(coHeaderList[0].NumberOfDeals__c > 0) {
            updateDealTradeIns(coHeaderId);
        }

        updateCOPricingAndTax(coHeaderRec, customerId, isCalculatePLandTax(newCustomerRec, coHeaderList[0]));
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
        
        if(String.isBlank(existingCOHeaderRec.Customer__c) || newCustomerRec == null) {
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
                    oldAccountType = priceLevelList[0].Id;
                } else {
                    newAccountType = priceLevelList[0].Id;
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
        List<Service_Order_Header__c> soHeaderList = [SELECT Provider__c, Job_Type__c, Customer_Owned_Unit__c, (SELECT Id FROM Events__r) 
                                                        FROM Service_Order_Header__c WHERE CO_Header__c = :coHeaderId AND 
                                                        Work_Status__c != :Constants.SERVICE_ORDER_STATUS_TO_CHECKOUT AND 
                                                        Invoice_Number__c = null AND Deal__r.Invoice_Number__c = null];
        List<Event__c> appointmentsToDelete = new List<Event__c>();
        for(Service_Order_Header__c soHeader: soHeaderList) {
            soHeader.Customer_Owned_Unit__c = null;
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
        List<Deal_Item__c> tradeInList = [SELECT Id FROM Deal_Item__c WHERE Deal__r.CO_Header__c = :coHeaderId AND Type__c = :Constants.DEAL_ITEM_TYPE_TRADE_IN AND 
                                            Is_Stocked_In__c = false];
        if(tradeInList.size() > 0) {
            DealItemTriggerHelper.isForceStopTrigger = true;
            delete tradeInList;
            DealItemTriggerHelper.isForceStopTrigger = false;
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
            [SELECT CO_Header__c, Invoice_Number__c, Invoice_Date__c, Total__c, 
                (SELECT Deal__c, SO_Payment_Role__r.RecordType.DeveloperName, Service_Order_Header__c, CO_Line_Item__c, CO_Kit_Header__c,
                        Service_Order_Header__r.SO_Concern__c, CO_Line_Item__r.Part__c, CO_Line_Item__r.Part__r.Part_Number__c,
                        CO_Line_Item__r.Fee__c, CO_Line_Item__r.Fee__r.Code__c, CO_Kit_Header__r.Kit_Header__r.Code__c
                        FROM CO_Invoice_Items__r WHERE CO_Line_Item__r.Deal__c = null AND Service_Order_Header__r.Deal__c = null) 
             FROM CO_Invoice_Header__c WHERE CO_Header__r.Customer__c =: customerId AND Invoice_Status__c = 'Closed' AND Checkout_Type__c != 'Deal'
                ORDER BY Invoice_Date__c DESC];
        
        Integer totalInvoice = invoiceList.size();
        invoiceList = TaxExemption.getPaginatedRecords(invoiceList, invoiceSortAttrs.CurrentPage, invoiceSortAttrs.PageSize);
        
        CustomerInvoiceHistory invoiceHistoryObj = new CustomerInvoiceHistory(invoiceList, totalInvoice);
        return invoiceHistoryObj;
    }
    
    public static String getARPaymentsByCustomerAccId(String customerId, Boolean isInvoiceIncluded) {
    	List<ARPaymentWrapper> ARPaymentObjList = new List<ARPaymentWrapper>();
    	try {
	    	List<Account> customerRecList = [Select AccountingId__c, Xero_Customer_Accounting_Id__c from Account where Id =: customerId];
	    	if(customerRecList.size() > 0) {
                Set<String> failedARCreditIds = new Set<String>();
	    		if(QBUtil.isQBEnabled()) {
	    			if(String.isBlank(customerRecList[0].AccountingId__c)) {
	    				throw new BlackPurlException('Customer is not synced to QB');
	    			}
	    			
                    if(isInvoiceIncluded) {
                        List<QuickBookQueryService.QuickBooksEntity> unpaidInvoiceList = QBIntegrationService.getUnpaidInvoicesFromQB(customerRecList[0].AccountingId__c);
                        for(QuickBookQueryService.QuickBooksEntity qbInvoice : unpaidInvoiceList) {
                            ARPaymentObjList.add(new ARPaymentWrapper(qbInvoice, 'Invoice'));
                        }
                    }
                    List<QuickBookQueryService.QuickBooksEntity> unappliedCreditList = QBIntegrationService.getUnappliedCreditsFromQB(customerRecList[0].AccountingId__c);

                    List<QuickBookQueryService.QuickBooksEntity> unappliedPaymentList = QBIntegrationService.getUnappliedPaymentsFromQB(customerRecList[0].AccountingId__c);

                    // get ar payments not synced to QB if there are unapplied credits present in QB
                    if(unappliedCreditList.size() > 0 || unappliedPaymentList.size() > 0) {
                        failedARCreditIds = getFailedARCreditSet('QB');
                    }
                    
                    for(QuickBookQueryService.QuickBooksEntity qbInvoice : unappliedCreditList) {
                        if(!failedARCreditIds.contains(qbInvoice.Id)) {
                            ARPaymentObjList.add(new ARPaymentWrapper(qbInvoice, 'CreditMemo'));
                        }
	    			}
                    
                    Integer paymentCounter = 1;
                    for(QuickBookQueryService.QuickBooksEntity qbPayment : unappliedPaymentList) {
                        if(Decimal.valueOf(qbPayment.UnappliedAmt) != 0 && !failedARCreditIds.contains(qbPayment.Id)) {
                            if(string.isBlank(qbPayment.PaymentRefNum)) {
                                qbPayment.PaymentRefNum = COInvoicePaymentService.UNAPPLIED_PAYMENT + ' ' + paymentCounter;
                                paymentCounter++;
                            }
                            ARPaymentObjList.add(new ARPaymentWrapper(qbPayment, 'Payment'));
                        }
	    			}

	    			if(QuickBookQueryService.refreshToken != null) {
						QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
					}
	    		} else {
	    			BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
	    			if(integrationRec != null) {
	    				if(integrationRec.integrationName == 'Xero') {
	    					if(String.isBlank(customerRecList[0].Xero_Customer_Accounting_Id__c)) {
	    						throw new BlackPurlException('Customer is not synced to Xero');
	    					}
	    					
	    					List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
	    					if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
	    					String whereClause;
                            XeroResponseWrapper responseWrapper;
                            if(isInvoiceIncluded) {
                                whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&AmountDue!=0&&Status!="VOIDED"&&Status!="DELETED"';
                                responseWrapper = XeroService.getDataFromXero('Invoice', whereClause, integrationConfigList[0]);
                                if(responseWrapper == null) return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Error fetching invoices from Xero')));
                                
                                for(XeroInvoiceDTO xeroInvoice : responseWrapper.Invoices) {
                                    ARPaymentObjList.add(new ARPaymentWrapper(xeroInvoice));
			    			    }
                            }
                            
                            whereClause = 'Contact.ContactID == Guid("' + customerRecList[0].Xero_Customer_Accounting_Id__c + '")&&RemainingCredit!=0&&Status!="VOIDED"&&Status!="DELETED"';
			    			responseWrapper = XeroService.getDataFromXero('Credit Note', whereClause, integrationConfigList[0]);
				        	update integrationConfigList;
			    			
			    			if(responseWrapper == null) {
		    					throw new BlackPurlException('Error fetching credit notes from Xero');
			    			}

                            // get ar payments not synced to Xero if there are unapplied credits present in Xero
                            if(responseWrapper.CreditNotes.size() > 0) {
                                failedARCreditIds = getFailedARCreditSet('XERO');
                            }
                            
			    			for(XeroCreditNoteDTO xeroCreditNote : responseWrapper.CreditNotes) {
                                if(!failedARCreditIds.contains(xeroCreditNote.CreditNoteID)) {
								    ARPaymentObjList.add(new ARPaymentWrapper(xeroCreditNote));
                                }
			    			}
	    				}
	    			}
	    		}
	    	}
            ARPaymentObjList.sort();
            if(isInvoiceIncluded) {
    		    return BPUtility.getEncodedString(System.JSON.serialize(ARPaymentObjList));
            }
            return (ARPaymentObjList.size() > 0) ? BPUtility.getEncodedString(System.JSON.serialize(ARPaymentObjList, true)) : BPUtility.getEncodedString(System.JSON.serialize('No unapplied credits returned, please select a different payment method.'));
    	} catch (Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
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
            List<CO_Header__c> coHeaderList = [Select Id, (Select Id From CO_Invoice_Headers__r Where Invoice_Status__c = 'Closed' Limit 1), (Select Work_Status__c From Service_Order_Headers__r), 
                                        (Select Status__c From Deals__r), (Select Id From Vendor_Order_Line_Items__r Limit 1) From CO_Header__c Where Id =: coHeaderId];
            if(coHeaderList.size() > 0) {
                List<CO_Invoice_Payment__c> coipList = [Select Payment_Method__c, Amount__c From CO_Invoice_Payment__c Where (Payment_Method__c  = 'AR Credit' OR Payment_Method__c  = 'Store Credit') AND (CO_Invoice_Header__r.CO_Header__c =: coHeaderId)];
                List<CO_Deposit__c> coDepositList = [Select Payment_Method__c, Amount__c From CO_Deposit__c Where (Payment_Method__c  = 'AR Credit' OR Payment_Method__c  = 'Store Credit') AND (CO_Header__c =: coHeaderId)];
                List<Deal_Item__c> dealItemList = [Select Is_Stocked_In__c From Deal_Item__c Where Type__c = 'Trade In' AND Deal__r.CO_Header__c =: coHeaderId];
                Set<String> errorsSet = validateErrors(coHeaderList[0], coipList, coDepositList, dealItemList, isCustomerDeletedFromCO);
                if(errorsSet.size() > 0) {
                    validationErrorToErrorTextSetMap.put('Error' , errorsSet);
                } else if(!isCustomerDeletedFromCO) {
                    Set<String> warningSet = validateWarnings(coHeaderList[0], dealItemList);
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
                if(soRec.Work_Status__c == 'Complete') {
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

    public static Set<String> validateWarnings(CO_Header__c coHeaderRec, List<Deal_Item__c> dealItemList) {
        Set<String> warningSet = new Set<String>();
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
        return warningSet;
    } 
}
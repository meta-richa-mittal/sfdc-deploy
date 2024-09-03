/**
 * Author: Manoj Sharma
 * Since: May 26, 2022
 * Name: QBService
 * Description: Apex class for QB integration methods
**/
public without sharing class QBService extends BaseIntegrationService {

    public static Map<String,String> entityNameToEntityToQueryMap = new Map<String,String>{
        IntegrationUtility.CUSTOMER => 'Customer',
        IntegrationUtility.VENDOR => 'Vendor',
        IntegrationUtility.INVOICE => 'Invoice',
        IntegrationUtility.CREDIT_MEMO => 'CreditMemo',
        IntegrationUtility.PAYMENT => 'Payment',
        IntegrationUtility.JOURNAL_ENTRY => 'JournalEntry',
        IntegrationUtility.VENDOR_CREDIT => 'VendorCredit',
        IntegrationUtility.ITEM => 'Item',
        IntegrationUtility.ACCOUNT => 'Account',
        IntegrationUtility.TAX_RATE => 'TaxRate',
        IntegrationUtility.TAX_CODE => 'TaxCode',
        IntegrationUtility.BILL => 'Bill',
        IntegrationUtility.INVOICE_PAYMENT => 'Payment',
        IntegrationUtility.REFUND_RECEIPT => 'refundreceipt',
        IntegrationUtility.SALES_RECEIPT => 'salesreceipt'
    };

    public static String entityToReactivate = '';
    public static final Integer RECORDS_PER_PAGE = 100;

    public static Set<String> entitySetToSyncAfterGetCall = new Set<String>{ IntegrationUtility.CUSTOMER,
                                                                             IntegrationUtility.VENDOR,
                                                                             IntegrationUtility.ITEM_CATEGORY
                                                                            };
    public QBService(IFW_IntegrationConfig__c integrationConfigRec) {
        this.integrationConfigRec = integrationConfigRec;
        this.integrationName = integrationConfigRec.Integration_Name__c;
        this.failedRecordsMap = new Map<String, List<Object>>();
    }

    public override Map<String, List<Object>> getAndResetFailedRecordsMap() {
        Map<String, List<Object>> failedMap = this.failedRecordsMap.clone();
        this.failedRecordsMap = new Map<String, List<Object>>();
        return failedMap;
    }
    
    public void writeToFailedRecordsMap(String key, List<Object> failedObjects) {
        if(!this.failedRecordsMap.containsKey(key)) {
            this.failedRecordsMap.put(key, new List<Object>());
        }
        this.failedRecordsMap.get(key).addAll(failedObjects);
    }
    
    public override List<WebService_Log__c> sync(List<Object> syncObjList, List<sObject> sobjListToSync, String entityType, 
                                                           Map<String, String> qbEntityNameToActionMap) {
        if(qbEntityNameToActionMap != null) integrationConfigItemList = getIntegrationConfigItemByFieldValues(integrationConfigRec.Id, qbEntityNameToActionMap);
        try {
            if(integrationConfigItemList.size() == 0) throw new BlackpurlException('Endpoint configurations not defined');
            Object payload = generatePayload(entityType, syncObjList, sobjListToSync);
            if(payload == null) {
                return (BaseIntegration.webServiceLogs != null ? BaseIntegration.webServiceLogs : new List<WebService_Log__c>());
            }

            // Check If Entity already synced to qb OR not?
            String qbAccIdFromGETReq;
            if(entityType != IntegrationUtility.INVOICE && !entityType.containsIgnoreCase(IntegrationUtility.BATCH)) { // if invoice created in QB then sync payment
        		qbAccIdFromGETReq = fetchEntityFromQB(payload, sobjListToSync, entityType, integrationConfigItemList[0], syncObjList);
        	}

            if(String.isBlank(qbAccIdFromGETReq) || this.isSendRequestRequiredForGET || entitySetToSyncAfterGetCall.contains(entityType)) {
                Map<String, Object> reqObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(payload, true));
                if(String.isNotBlank(qbAccIdFromGETReq)) {
                    reqObj.put('Id', qbAccIdFromGETReq);
                }
                reqObj.remove('SFId');
                postEntityToQB(Json.serialize(reqObj), integrationConfigItemList, sobjListToSync, syncObjList, entityType, payload);
        	}
        	
        } catch(HttpRequestException e) {
            checkForRetryLogic(e, syncObjList);
            
        } catch(Exception e) {
        	
            handleBPError(e.getMessage(), syncObjList, sobjListToSync, entityType);
            
            checkForRetryLogic(e, syncObjList);
            
            this.errorLogs.add(new LogService().createErrorLog('qbService', 'sync()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              syncObjList+'', LogService.QUICKBOOKS, false,'Error'));
        }
        return (BaseIntegration.webServiceLogs != null ? BaseIntegration.webServiceLogs : new List<WebService_Log__c>());
    }
    
    private void postEntityToQB(String reqBody, List<IFW_IntegrationConfigItem__c> integrationConfigItemList,
                                        List<sObject> sobjListToSync, List<Object> syncObjList, String entityType, Object payloadWithSFId) {
        
        // HTTP Method GET is coming because it is changed in GET API call above.
        if(integrationConfigItemList[0].HTTP_Method__c == 'GET') {
            integrationConfigItemList[0].HTTP_Method__c = 'POST';
        }
        performCalloutandHandleResponse(integrationConfigItemList[0], reqBody, entityType, payloadWithSFId, sobjListToSync, syncObjList);

        if(entityType == IntegrationUtility.INVOICE) {
            syncCOInvoicePayment(syncObjList, sobjListToSync, IntegrationUtility.INVOICE_PAYMENT);
        }
    }
    
    
    //Perform Callout and handle response
    public void performCalloutandHandleResponse(IFW_IntegrationConfigItem__c integrationConfigItem, String requestBody, String entityType, Object payload, List<sObject> sobjListToSync, List<Object> syncObjList) {
        HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, integrationConfigItem, requestBody, new List<customHttpHeaderWrapper>(), entityType);
        handleResponse(response, payload, sobjListToSync, entityType, null, syncObjList);
    }
    
    private String handleResponse(HttpResponse response, Object payload, List<sObject> sobjListToSync, String entityType, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse, List<Object> syncObjList) {
        if(entityType.containsIgnoreCase(IntegrationUtility.BATCH) && response != null) {
            handleBatchResponse(response.getBody(), sobjListToSync, entityType);
        } else if(response != null && String.valueOf(response.getStatusCode()) == '200') {
            return handleSuccessResponse(response.getBody(), payload, sobjListToSync, entityType, null);
        } else if(qbQueryResponse != null) {
            return handleSuccessResponse(null, payload, sobjListToSync, entityType, qbQueryResponse);
        } else {
            //Error Handling
            handleErrorResponse(response, payload, sobjListToSync, entityType, syncObjList);
        }
        return '';
    }
    
    private void handleBatchResponse(String responseBody, List<sObject> sobjListToSync, String entityType) {
        QBBatchDTO batchResponseJson = (QBBatchDTO)JSON.deserialize(responseBody, QBBatchDTO.class);
        if(entityType == IntegrationUtility.BATCH_CUSTOMER) {
            handleBatchCustomerResponse(batchResponseJson, (List<Account>)sobjListToSync);
        } else if(entityType == IntegrationUtility.BATCH_VENDOR) {
            handleBatchVendorResponse(batchResponseJson, (List<Account>)sobjListToSync);
        }
    }

    private String handleSuccessResponse(String responseBody, Object payload, List<sObject> sobjListToSync, String entityType, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBResponseWrapper qbResponseWrapper = String.isNotBlank(responseBody) ? (QBResponseWrapper) System.JSON.deserialize(responseBody, QBResponseWrapper.class) : null;
        String accId;
        if(entityType == IntegrationUtility.CO_DEPOSIT) {
            accId = handleCODepositResponse(qbResponseWrapper, payload, (List<CO_Deposit__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.CUSTOMER) {
            accId = handleCustomerResponse(qbResponseWrapper, payload, (List<Account>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.VENDOR) {
            accId = handleVendorResponse(qbResponseWrapper, payload, (List<Account>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.CO_INVOICE_PAYMENT) {
            accId = handleCOInvoicePaymentResponse(qbResponseWrapper, payload, (List<CO_Invoice_Payment__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.STORE_CREDIT) {
            accId = handleStoreCreditResponse(qbResponseWrapper, payload, (List<Store_Credit__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.COUNT_SESSION_JE) {
            accId = handleCountSessionJEResponse(qbResponseWrapper, payload, (List<Count_Session__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.VENDOR_RECEIVING) {
            accId = handleVendorReceivingResponse(qbResponseWrapper, payload, (List<Vendor_Receiving_Header__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.PART_FIFO) {
            accId = handlePartFIFOResponse(qbResponseWrapper, payload, (List<Part_FIFO_Bucket__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM) {
            accId = handlePartFIFOBucketActivityLineItemResponse(qbResponseWrapper, payload, (List<Part_FIFO_Bucket_Activity_Line_Item__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.HOURS_LOGGED) {
            accId = handleHoursLoggedResponse(qbResponseWrapper, payload, (List<Hours_Logged__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.VO_INVOICE) {
            accId = handleVOInvoiceResponse(qbResponseWrapper, payload, (List<Hours_Logged__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.VO_INVOICE_VARIANCE_JE) {
            accId = handleVOInvoiceVarianceJEResponse(qbResponseWrapper, payload, (List<Hours_Logged__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
            accId = handleUnitInvoiceJEResponse(qbResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.PART_CATEGORY) {
            accId = handlePartCategoryResponse(qbResponseWrapper, payload, (List<Part__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            accId = handleStockUnitCategoryResponse(qbResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.VO_RETURN) {
            accId = handleVOReturnResponse(qbResponseWrapper, payload, (List<Return_CR_Header__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.STOCK_TRADE_IN) {
            accId = handleStockTradeInResponse(qbResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
            accId = handleUnitNITCJEResponse(qbResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.QB_AR_PAYMENT) {
            accId = handleARPaymentResponse(qbResponseWrapper, payload, (List<Payment_on_Account__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.PAYMENT_ON_ACCOUNT) {
            accId = handlePaymentOnAccountResponse(qbResponseWrapper, payload, (List<Payment_on_Account__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.ITEM_CATEGORY) {
            accId = handleItemCategoryResponse(qbResponseWrapper, payload, (List<Category__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.UNIT_PRICE_COST) {
            accId = handleUnitPriceAndCostResponse(qbResponseWrapper, payload, (List<Unit_Price_Cost__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.INVOICE) {
            accId = handleCOInvoiceResponse(qbResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.LIEN_PAYOUT) {
            accId = handleLienPayoutResponse(qbResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.CO_INVOICE_JE) {
            handleCOInvoiceJEResponse(qbResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync, qbQueryResponse);
        }  else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            accId = handleInvoicePaymentResponse(qbResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.UNIT_CONSIGNMENT) {
            handleConsignmentResponse(qbResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE) {
            accId = handleUnitInvoiceResponse(qbResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync, qbQueryResponse);
        } else if(entityType == IntegrationUtility.VO_RETURN_VARIANCE_JE) {
            accId = handleRVOVarianceJEResponse(qbResponseWrapper, payload, (List<Hours_Logged__c>)sobjListToSync, qbQueryResponse);
        } if(entityType == IntegrationUtility.CASH_RECONCILIATION) {
            accId = handleCashReconciliationResponse(qbResponseWrapper, payload, (List<Cash_Reconciliation__c>)sobjListToSync, qbQueryResponse);
        }
        return accId;
    }

    private void handleErrorResponse(HttpResponse httpResponse, Object payload, List<sObject> sobjListToSync, String entityType, List<Object> syncObjList) {
    	String responseBody = httpResponse.getBody();
        Map<String, Object> entityDTOMap = (Map<String, Object>) JSON.deserializeUntyped(System.JSON.serialize(payload));
        setDataForSObject(sobjListToSync, (String)entityDTOMap.get('SFId'), responseBody, entityType);

        HttpErrorDTO.QBErrorDTO errorResponse = (HttpErrorDTO.QBErrorDTO) System.JSON.deserialize(httpResponse.getBody(), HttpErrorDTO.QBErrorDTO.class);
        if(String.isNotBlank(entityToReactivate) && errorResponse != null && errorResponse.Fault != null && errorResponse.Fault.Error != null && 
            errorResponse.Fault.Error.size() > 0 && (validateCustomerReactivation(errorResponse) || validateVendorReactivation(errorResponse))) {
            if(reactivateRelatedTransaction(payload, sobjListToSync, entityType, syncObjList)) return;
        } else if(errorResponse != null && errorResponse.Fault != null && errorResponse.Fault.Error != null && 
            errorResponse.Fault.Error.size() > 0 && validateDuplicateDocError(errorResponse)) {
            updateDuplicateTransactionDocNumber(payload, sobjListToSync, entityType, syncObjList);
            return;
        }
        throw new HttpRequestException(httpResponse.getBody() + ' - ' + AccountingUtil.STATUS_CODE_TEXT + httpResponse.getStatusCode());
    }

    private String handleConsignmentResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBBaseInvoiceDTO reqVendorCreditObj = (QBBaseInvoiceDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.CreditMemo != null) || (qbQueryResponse != null && qbQueryResponse.CreditMemo != null && qbQueryResponse.CreditMemo.size() > 0)) {
            Customer_Owned_Unit__c unitRecToUpdate = new Customer_Owned_Unit__c();
            unitRecToUpdate.Id = reqVendorCreditObj.SFId;
            unitRecToUpdate.Available_For_QB_Consignment_Sync__c = false;
            unitRecToUpdate.Accounting_Last_Sync_Time_Consignment__c = System.now();
            if(qbResponseWrapper != null && qbResponseWrapper.CreditMemo != null) {
                unitRecToUpdate.QB_Consignment_Accounting_Id__c = qbResponseWrapper.CreditMemo.Id;
                unitRecToUpdate.Accounting_Response_Consignment__c = (qbResponseWrapper + '').abbreviate(32768);
                unitRecToUpdate.Sync_Token_For_Consignment__c = qbResponseWrapper.CreditMemo.SyncToken;
                sobjListToSync.add(unitRecToUpdate);
            } else {
                for(QBInvoiceDTO creditMemo : qbQueryResponse.CreditMemo) {
                    if((creditMemo.Id == reqVendorCreditObj.Id) || (reqVendorCreditObj.PrivateNote == creditMemo.PrivateNote && String.isNotBlank(reqVendorCreditObj.PrivateNote) && String.isNotBlank(creditMemo.PrivateNote))) {
                        unitRecToUpdate.QB_Consignment_Accounting_Id__c = creditMemo.Id;
                        unitRecToUpdate.Accounting_Response_Consignment__c = (creditMemo + '').abbreviate(32768);
                        unitRecToUpdate.Sync_Token_For_Consignment__c = creditMemo.SyncToken;
                        sobjListToSync.add(unitRecToUpdate);
                        break;
                    }
                }
            }
            reqVendorCreditObj.SyncToken = unitRecToUpdate.Sync_Token_For_Consignment__c;
            return unitRecToUpdate.QB_Consignment_Accounting_Id__c;
        }
        return '';
    }

    private String handleCOInvoiceJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            CO_Invoice_Header__c coInvoiceUpdate = new CO_Invoice_Header__c();
            coInvoiceUpdate.Id = reqJournalEntryObj.SFId;
            coInvoiceUpdate.availForQBJournalEntrySync__c = false;
            coInvoiceUpdate.accountingLastSyncTimeForJE__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                coInvoiceUpdate.JournalEntryAccountingId__c = qbResponseWrapper.JournalEntry.Id;
                coInvoiceUpdate.AccountingResponseForJournalEntry__c = (qbResponseWrapper + '').abbreviate(32768);
                coInvoiceUpdate.SyncTokenForJournalEntry__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(coInvoiceUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        coInvoiceUpdate.JournalEntryAccountingId__c = journalEntry.Id;
                        coInvoiceUpdate.AccountingResponseForJournalEntry__c = (journalEntry + '').abbreviate(32768);
                        coInvoiceUpdate.SyncTokenForJournalEntry__c = journalEntry.SyncToken;
                        sobjListToSync.add(coInvoiceUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = coInvoiceUpdate.SyncTokenForJournalEntry__c;               
            return coInvoiceUpdate.JournalEntryAccountingId__c;
        }
        return '';
    }

    private String handleCOInvoiceResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBBaseInvoiceDTO reqObj = (QBBaseInvoiceDTO)payload;
        CO_Invoice_Header__c coInvoiceUpdate = new CO_Invoice_Header__c();
        if(qbResponseWrapper != null && (qbResponseWrapper.SalesReceipt != null || qbResponseWrapper.RefundReceipt != null  || qbResponseWrapper.Invoice != null  || qbResponseWrapper.CreditMemo != null)) {
            coInvoiceUpdate.Id = reqObj.SFId;
            coInvoiceUpdate.availForQBSync__c = false;
            coInvoiceUpdate.accountingLastSyncTime__c = system.now();
            coInvoiceUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
            if(qbResponseWrapper.SalesReceipt != null) {
                coInvoiceUpdate.AccountingId__c = qbResponseWrapper.SalesReceipt.Id;
                coInvoiceUpdate.SyncToken__c = qbResponseWrapper.SalesReceipt.SyncToken;
            } else if(qbResponseWrapper.RefundReceipt != null) {
                coInvoiceUpdate.AccountingId__c = qbResponseWrapper.RefundReceipt.Id;
                coInvoiceUpdate.SyncToken__c = qbResponseWrapper.RefundReceipt.SyncToken;
            } else if(qbResponseWrapper.Invoice != null) {
                coInvoiceUpdate.AccountingId__c = qbResponseWrapper.Invoice.Id;
                coInvoiceUpdate.SyncToken__c = qbResponseWrapper.Invoice.SyncToken;
            } else if(qbResponseWrapper.CreditMemo != null) {
                coInvoiceUpdate.AccountingId__c = qbResponseWrapper.CreditMemo.Id;
                coInvoiceUpdate.SyncToken__c = qbResponseWrapper.CreditMemo.SyncToken;
            }
            sobjListToSync.add(coInvoiceUpdate);  
            return coInvoiceUpdate.AccountingId__c;
        }
        return '';
    }

    private String handleUnitPriceAndCostResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        Unit_Price_Cost__c upcToUpdate = new Unit_Price_Cost__c();

        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;

            upcToUpdate.Id = reqJournalEntryObj.SFId;
            upcToUpdate.availForQBSync__c = false;
            upcToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                upcToUpdate.AccountingId__c = qbResponseWrapper.JournalEntry.Id;
                upcToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                upcToUpdate.SyncToken__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(upcToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        upcToUpdate.AccountingId__c = journalEntry.Id;
                        upcToUpdate.AccountingResponse__c = (journalEntry + '').abbreviate(32768);
                        upcToUpdate.SyncToken__c = journalEntry.SyncToken;
                        sobjListToSync.add(upcToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = upcToUpdate.SyncToken__c;                        
            return upcToUpdate.AccountingId__c;
        } else if((qbResponseWrapper != null && qbResponseWrapper.VendorCredit != null) || (qbQueryResponse != null && qbQueryResponse.VendorCredit != null && qbQueryResponse.VendorCredit.size() > 0)) {
            QBVendorCreditDTO reqVendorCreditObj = (QBVendorCreditDTO)payload;

            upcToUpdate.Id = reqVendorCreditObj.SFId;
            upcToUpdate.availForQBSync__c = false;
            upcToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.VendorCredit != null) {
                upcToUpdate.AccountingId__c = qbResponseWrapper.VendorCredit.Id;
                upcToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                upcToUpdate.SyncToken__c = qbResponseWrapper.VendorCredit.SyncToken;
                sobjListToSync.add(upcToUpdate);
            } else {
                for(QBVendorCreditDTO vendorCredit : qbQueryResponse.VendorCredit) {
                    if((vendorCredit.Id == reqVendorCreditObj.Id) || (reqVendorCreditObj.PrivateNote == vendorCredit.PrivateNote && String.isNotBlank(reqVendorCreditObj.PrivateNote) && String.isNotBlank(vendorCredit.PrivateNote))) {
                        upcToUpdate.AccountingId__c = vendorCredit.Id;
                        upcToUpdate.AccountingResponse__c = (vendorCredit + '').abbreviate(32768);
                        upcToUpdate.SyncToken__c = vendorCredit.SyncToken;
                        sobjListToSync.add(upcToUpdate);
                        break;
                    }
                }
            }                
            reqVendorCreditObj.SyncToken = upcToUpdate.SyncToken__c;                                    
            return upcToUpdate.AccountingId__c;
        } else if((qbResponseWrapper != null && qbResponseWrapper.Bill != null) || (qbQueryResponse != null && qbQueryResponse.Bill != null && qbQueryResponse.Bill.size() > 0)) {
            QBVendorBillDTO reqBillObj = (QBVendorBillDTO)payload;

            upcToUpdate.Id = reqBillObj.SFId;
            upcToUpdate.availForQBSync__c = false;
            upcToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.Bill != null) {
                upcToUpdate.AccountingId__c = qbResponseWrapper.Bill.Id;
                upcToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                upcToUpdate.SyncToken__c = qbResponseWrapper.Bill.SyncToken;
                sobjListToSync.add(upcToUpdate);
            } else {
                for(QBVendorBillDTO bill : qbQueryResponse.Bill) {
                    if((bill.Id == reqBillObj.Id) || (reqBillObj.PrivateNote == bill.PrivateNote && String.isNotBlank(reqBillObj.PrivateNote) && String.isNotBlank(bill.PrivateNote))) {
                        upcToUpdate.AccountingId__c = bill.Id;
                        upcToUpdate.AccountingResponse__c = (bill + '').abbreviate(32768);
                        upcToUpdate.SyncToken__c = bill.SyncToken;
                        sobjListToSync.add(upcToUpdate);
                        break;
                    }
                }
            }                
            reqBillObj.SyncToken = upcToUpdate.SyncToken__c;                                            
            return upcToUpdate.AccountingId__c;
        } else if((qbResponseWrapper != null && qbResponseWrapper.CreditMemo != null) || (qbQueryResponse != null && qbQueryResponse.CreditMemo != null && qbQueryResponse.CreditMemo.size() > 0)) {
            QBCreditMemoDTO reqCreditMemoObj = (QBCreditMemoDTO)payload;

            upcToUpdate.Id = reqCreditMemoObj.SFId;
            upcToUpdate.availForQBSync__c = false;
            upcToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.CreditMemo != null) {
                upcToUpdate.AccountingId__c = qbResponseWrapper.CreditMemo.Id;
                upcToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                upcToUpdate.SyncToken__c = qbResponseWrapper.CreditMemo.SyncToken;
                sobjListToSync.add(upcToUpdate);
            } else {
                for(QBInvoiceDTO creditMemo : qbQueryResponse.CreditMemo) {
                    if((creditMemo.Id == reqCreditMemoObj.Id) || (reqCreditMemoObj.PrivateNote == creditMemo.PrivateNote && String.isNotBlank(reqCreditMemoObj.PrivateNote) && String.isNotBlank(creditMemo.PrivateNote))) {
                        upcToUpdate.AccountingId__c = creditMemo.Id;
                        upcToUpdate.AccountingResponse__c = (creditMemo + '').abbreviate(32768);
                        upcToUpdate.SyncToken__c = creditMemo.SyncToken;
                        sobjListToSync.add(upcToUpdate);
                        break;
                    }
                }
            }                
            reqCreditMemoObj.SyncToken = upcToUpdate.SyncToken__c;                                                      
            return upcToUpdate.AccountingId__c;
        } else if((qbResponseWrapper != null && qbResponseWrapper.Invoice != null) || (qbQueryResponse != null && qbQueryResponse.Invoice != null && qbQueryResponse.Invoice.size() > 0)) {
            QBInvoiceDTO reqInvoiceObj = (QBInvoiceDTO)payload;

            upcToUpdate.Id = reqInvoiceObj.SFId;
            upcToUpdate.availForQBSync__c = false;
            upcToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.Invoice != null) {
                upcToUpdate.AccountingId__c = qbResponseWrapper.Invoice.Id;
                upcToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                upcToUpdate.SyncToken__c = qbResponseWrapper.Invoice.SyncToken;
                sobjListToSync.add(upcToUpdate);
            } else {
                for(QBInvoiceDTO invoice : qbQueryResponse.Invoice) {
                    if((invoice.Id == reqInvoiceObj.Id) || (reqInvoiceObj.PrivateNote == invoice.PrivateNote && String.isNotBlank(reqInvoiceObj.PrivateNote) && String.isNotBlank(invoice.PrivateNote))) {
                        upcToUpdate.AccountingId__c = invoice.Id;
                        upcToUpdate.AccountingResponse__c = (invoice + '').abbreviate(32768);
                        upcToUpdate.SyncToken__c = invoice.SyncToken;
                        sobjListToSync.add(upcToUpdate);
                        break;
                    }
                }
            }                
            reqInvoiceObj.SyncToken = upcToUpdate.SyncToken__c;                                                                  
            return upcToUpdate.AccountingId__c;
        }
        return '';
    }

    private String handleCODepositResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            CO_Deposit__c coDepositToUpdate = new CO_Deposit__c();
            coDepositToUpdate.Id = reqJournalEntryObj.SFId;
            coDepositToUpdate.availForQBJournalEntrySync__c = false;
            coDepositToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                coDepositToUpdate.AccountingIdForJournalEntry__c = qbResponseWrapper.JournalEntry.Id;
                coDepositToUpdate.AccountingResponseForJournalEntry__c = (qbResponseWrapper + '').abbreviate(32768);
                coDepositToUpdate.SyncTokenForJournalEntry__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(coDepositToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        coDepositToUpdate.AccountingIdForJournalEntry__c = journalEntry.Id;
                        coDepositToUpdate.AccountingResponseForJournalEntry__c = (journalEntry + '').abbreviate(32768);
                        coDepositToUpdate.SyncTokenForJournalEntry__c = journalEntry.SyncToken;
                        sobjListToSync.add(coDepositToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = coDepositToUpdate.SyncTokenForJournalEntry__c;                                                                  
            return coDepositToUpdate.AccountingIdForJournalEntry__c;
        }
        return '';
    } 

    private String handleCashReconciliationResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Cash_Reconciliation__c cashReconToUpdate = new Cash_Reconciliation__c();
            cashReconToUpdate.Id = reqJournalEntryObj.SFId;
            cashReconToUpdate.Available_For_QB_Sync__c = false;
            cashReconToUpdate.Accounting_Last_Sync_Time__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                cashReconToUpdate.Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                cashReconToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                cashReconToUpdate.Sync_Token__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(cashReconToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        cashReconToUpdate.Accounting_Id__c = journalEntry.Id;
                        cashReconToUpdate.Accounting_Response__c = (journalEntry + '').abbreviate(32768);
                        cashReconToUpdate.Sync_Token__c = journalEntry.SyncToken;
                        sobjListToSync.add(cashReconToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = cashReconToUpdate.Sync_Token__c;                                                                  
            return cashReconToUpdate.Accounting_Id__c;
        }
        return '';
    }

    private String handleCOInvoicePaymentResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            CO_Invoice_Payment__c coipToUpdate = new CO_Invoice_Payment__c();
            coipToUpdate.Id = reqJournalEntryObj.SFId;
            coipToUpdate.availForQBJournalEntrySync__c = false;
            coipToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                coipToUpdate.AccountingIdForJournalEntry__c = qbResponseWrapper.JournalEntry.Id;
                coipToUpdate.AccountingResponseForJournalEntry__c = (qbResponseWrapper + '').abbreviate(32768);
                coipToUpdate.SyncTokenForJournalEntry__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(coipToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        coipToUpdate.AccountingIdForJournalEntry__c = journalEntry.Id;
                        coipToUpdate.AccountingResponseForJournalEntry__c = (journalEntry + '').abbreviate(32768);
                        coipToUpdate.SyncTokenForJournalEntry__c = journalEntry.SyncToken;
                        sobjListToSync.add(coipToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = coipToUpdate.SyncTokenForJournalEntry__c;                                                                                 
            return coipToUpdate.AccountingIdForJournalEntry__c;
        }
        return '';
    }

    private String handleCustomerResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBCustomerDTO reqCustomerObj = (QBCustomerDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.Customer != null) || (qbQueryResponse != null && qbQueryResponse.Customer != null && qbQueryResponse.Customer.size() > 0)) {
            Account customerToUpdate = new Account();
            customerToUpdate.Id = reqCustomerObj.SFId;
            customerToUpdate.availForQBSync__c = false;
            customerToUpdate.accountingLastSyncTime__c = system.now();
            customerToUpdate.QB_Updated_Fields__c = null;
            if(qbResponseWrapper != null && qbResponseWrapper.Customer != null) {
                customerToUpdate.AccountingId__c = qbResponseWrapper.Customer.Id;
                customerToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                customerToUpdate.SyncToken__c = qbResponseWrapper.Customer.SyncToken;
                sobjListToSync.add(customerToUpdate);
            } else {
                for(QBCustomerDTO customer : qbQueryResponse.Customer) {
                    if((customer.Id == reqCustomerObj.Id) || (reqCustomerObj.DisplayName == customer.DisplayName && String.isNotBlank(reqCustomerObj.DisplayName) && String.isNotBlank(customer.DisplayName))) {
                        customerToUpdate.AccountingId__c = customer.Id;
                        customerToUpdate.AccountingResponse__c = (customer + '').abbreviate(32768);
                        customerToUpdate.SyncToken__c = customer.SyncToken;
                        sobjListToSync.add(customerToUpdate);
                        break;
                    }
                }
            }                
            reqCustomerObj.SyncToken = customerToUpdate.SyncToken__c;                                                                                         
            return customerToUpdate.AccountingId__c;
        }
        return '';
    }

    private void handleBatchCustomerResponse(QBBatchDTO qbResponseWrapper, List<sObject> sobjListToSync) {
        if(qbResponseWrapper.BatchItemResponse != null) {
            for(QBBatchDTO.BatchItemResponse batchResponse : qbResponseWrapper.BatchItemResponse) {
                Account acc = new Account(Id = batchResponse.bId);
                acc.accountingLastSyncTime__c = system.now();
                if(batchResponse.Fault != null) {
                    acc.AccountingResponse__c = String.valueOf(batchResponse.Fault).abbreviate(32768);
                    sobjListToSync.add(acc);
                } else if(batchResponse.Customer != null && batchResponse.Customer.Id != null) {
                    acc.availForQBSync__c =  false;
                    acc.QB_Updated_Fields__c = null;
                    acc.AccountingId__c =  batchResponse.Customer.Id;
                    acc.SyncToken__c = batchResponse.customer.synctoken;
                    acc.AccountingResponse__c = String.valueOf(batchResponse.Customer).abbreviate(32768);
                    sobjListToSync.add(acc);
                }
            }
        } 
    }

    private void handleBatchVendorResponse(QBBatchDTO qbResponseWrapper, List<sObject> sobjListToSync) {
        if(qbResponseWrapper.BatchItemResponse != null) {
            for(QBBatchDTO.BatchItemResponse batchResponse : qbResponseWrapper.BatchItemResponse) {
                Account acc = new Account(Id = batchResponse.bId);
                acc.Vendor_AccountingLastSyncTime__c = system.now();
                if(batchResponse.Fault != null) {
                    acc.Vendor_AccountingResponse__c = String.valueOf(batchResponse.Fault).abbreviate(32768);
                    sobjListToSync.add(acc);
                } else if(batchResponse.Vendor != null && batchResponse.Vendor.Id != null) {
                    acc.Vendor_AvailForQBSync__c =  false;
                    acc.Vendor_QB_Updated_Fields__c = null;
                    acc.Vendor_AccountingId__c =  batchResponse.Vendor.Id;
                    acc.Vendor_SyncToken__c = batchResponse.Vendor.synctoken;
                    acc.Vendor_AccountingResponse__c = String.valueOf(batchResponse.Vendor).abbreviate(32768);
                    sobjListToSync.add(acc);
                }
            }
        } 
    }

    private String handleVendorResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBVendorDTO reqVendorObj = (QBVendorDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.Vendor != null) || (qbQueryResponse != null && qbQueryResponse.Vendor != null && qbQueryResponse.Vendor.size() > 0)) {
            Account vendorToUpdate = new Account();
            vendorToUpdate.Id = reqVendorObj.SFId;
            vendorToUpdate.Vendor_AvailForQBSync__c = false;
            vendorToUpdate.Vendor_AccountingLastSyncTime__c = system.now();
            vendorToUpdate.Vendor_QB_Updated_Fields__c = null;
            if(qbResponseWrapper != null && qbResponseWrapper.Vendor != null) {
                vendorToUpdate.Vendor_AccountingId__c = qbResponseWrapper.Vendor.Id;
                vendorToUpdate.Vendor_AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                vendorToUpdate.Vendor_SyncToken__c = qbResponseWrapper.Vendor.SyncToken;
                sobjListToSync.add(vendorToUpdate);
            } else {
                for(QBVendorDTO vendor : qbQueryResponse.Vendor) {
                    if((vendor.Id == reqVendorObj.Id) || (reqVendorObj.DisplayName == vendor.DisplayName && String.isNotBlank(reqVendorObj.DisplayName) && String.isNotBlank(vendor.DisplayName))) {
                        vendorToUpdate.Vendor_AccountingId__c = vendor.Id;
                        vendorToUpdate.Vendor_AccountingResponse__c = (vendor + '').abbreviate(32768);
                        vendorToUpdate.Vendor_SyncToken__c = vendor.SyncToken;
                        sobjListToSync.add(vendorToUpdate);
                        break;
                    }
                }
            }                
            reqVendorObj.SyncToken = vendorToUpdate.Vendor_SyncToken__c;                                                                                                        
            return vendorToUpdate.Vendor_AccountingId__c;
        }
        return '';
    }

    private String handleStoreCreditResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Store_Credit__c storeCreditToUpdate = new Store_Credit__c();
            storeCreditToUpdate.Id = reqJournalEntryObj.SFId;
            storeCreditToUpdate.availForQBSync__c = false;
            storeCreditToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                storeCreditToUpdate.AccountingId__c = qbResponseWrapper.JournalEntry.Id;
                storeCreditToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                storeCreditToUpdate.SyncToken__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(storeCreditToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        storeCreditToUpdate.AccountingId__c = journalEntry.Id;
                        storeCreditToUpdate.AccountingResponse__c = (journalEntry + '').abbreviate(32768);
                        storeCreditToUpdate.SyncToken__c = journalEntry.SyncToken;
                        sobjListToSync.add(storeCreditToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = storeCreditToUpdate.SyncToken__c;                                                                                                                       
            return storeCreditToUpdate.AccountingId__c;
        }
        return '';
    }

    private String handleCountSessionJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Count_Session__c countSessionToUpdate = new Count_Session__c();
            countSessionToUpdate.Id = reqJournalEntryObj.SFId;
            countSessionToUpdate.Available_For_QB_Sync__c = false;
            countSessionToUpdate.Accounting_Last_Sync_Time__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                countSessionToUpdate.QB_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                countSessionToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                countSessionToUpdate.Accounting_Sync_Token__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(countSessionToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        countSessionToUpdate.QB_Accounting_Id__c = journalEntry.Id;
                        countSessionToUpdate.Accounting_Response__c = (journalEntry + '').abbreviate(32768);
                        countSessionToUpdate.Accounting_Sync_Token__c = journalEntry.SyncToken;
                        sobjListToSync.add(countSessionToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = countSessionToUpdate.Accounting_Sync_Token__c;                                                                                                                                      
            return countSessionToUpdate.QB_Accounting_Id__c;
        }
        return '';
    }

    private String handleVendorReceivingResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Vendor_Receiving_Header__c vendorReceivingToUpdate = new Vendor_Receiving_Header__c();
            vendorReceivingToUpdate.Id = reqJournalEntryObj.SFId;
            vendorReceivingToUpdate.availForQBJournalEntrySync__c = false;
            vendorReceivingToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                vendorReceivingToUpdate.AccountingIdForJournalEntry__c = qbResponseWrapper.JournalEntry.Id;
                vendorReceivingToUpdate.AccountingResponseForJournalEntry__c = (qbResponseWrapper + '').abbreviate(32768);
                vendorReceivingToUpdate.SyncTokenForJournalEntry__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(vendorReceivingToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        vendorReceivingToUpdate.AccountingIdForJournalEntry__c = journalEntry.Id;
                        vendorReceivingToUpdate.AccountingResponseForJournalEntry__c = (journalEntry + '').abbreviate(32768);
                        vendorReceivingToUpdate.SyncTokenForJournalEntry__c = journalEntry.SyncToken;
                        sobjListToSync.add(vendorReceivingToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = vendorReceivingToUpdate.SyncTokenForJournalEntry__c;                                                                                                                                                  
            return vendorReceivingToUpdate.AccountingIdForJournalEntry__c;
        }
        return '';
    }

    private String handlePartFIFOResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Part_FIFO_Bucket__c partFIFOToUpdate = new Part_FIFO_Bucket__c();
            partFIFOToUpdate.Id = reqJournalEntryObj.SFId;
            partFIFOToUpdate.availForQBSync__c = false;
            partFIFOToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                partFIFOToUpdate.AccountingId__c = qbResponseWrapper.JournalEntry.Id;
                partFIFOToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                partFIFOToUpdate.SyncToken__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(partFIFOToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        partFIFOToUpdate.AccountingId__c = journalEntry.Id;
                        partFIFOToUpdate.AccountingResponse__c = (journalEntry + '').abbreviate(32768);
                        partFIFOToUpdate.SyncToken__c = journalEntry.SyncToken;
                        sobjListToSync.add(partFIFOToUpdate);
                        break;
                    }
                }
            }                
            reqJournalEntryObj.SyncToken = partFIFOToUpdate.SyncToken__c;                                                                                                                                                                
            return partFIFOToUpdate.AccountingId__c;
        }
        return '';
    }

    private String handlePartFIFOBucketActivityLineItemResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Part_FIFO_Bucket_Activity_Line_Item__c partFIFOLIToUpdate = new Part_FIFO_Bucket_Activity_Line_Item__c();
            partFIFOLIToUpdate.Id = reqJournalEntryObj.SFId;
            partFIFOLIToUpdate.availForQBSync__c = false;
            partFIFOLIToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                partFIFOLIToUpdate.AccountingId__c = qbResponseWrapper.JournalEntry.Id;
                partFIFOLIToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                partFIFOLIToUpdate.SyncToken__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(partFIFOLIToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        partFIFOLIToUpdate.AccountingId__c = journalEntry.Id;
                        partFIFOLIToUpdate.AccountingResponse__c = (journalEntry + '').abbreviate(32768);
                        partFIFOLIToUpdate.SyncToken__c = journalEntry.SyncToken;
                        sobjListToSync.add(partFIFOLIToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = partFIFOLIToUpdate.SyncToken__c;                                                                                                                                                                
            return partFIFOLIToUpdate.AccountingId__c;
        }
        return '';
    }

    private String handleHoursLoggedResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Hours_Logged__c hoursLoggedToUpdate = new Hours_Logged__c();
            hoursLoggedToUpdate.Id = reqJournalEntryObj.SFId;
            hoursLoggedToUpdate.Available_For_QB_Sync__c = false;
            hoursLoggedToUpdate.Accounting_Last_Sync_Time__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                hoursLoggedToUpdate.QB_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                hoursLoggedToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                hoursLoggedToUpdate.Accounting_Sync_Token__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(hoursLoggedToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        hoursLoggedToUpdate.QB_Accounting_Id__c = journalEntry.Id;
                        hoursLoggedToUpdate.Accounting_Response__c = (journalEntry + '').abbreviate(32768);
                        hoursLoggedToUpdate.Accounting_Sync_Token__c = journalEntry.SyncToken;
                        sobjListToSync.add(hoursLoggedToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = hoursLoggedToUpdate.Accounting_Sync_Token__c;                                                                                                                                                                
            return hoursLoggedToUpdate.QB_Accounting_Id__c;
        }
        return '';
    }

    private String handleVOInvoiceResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBBaseVendorInvoiceDTO reqObj = (QBBaseVendorInvoiceDTO)payload;
        Vendor_Invoicing_Header__c vohToUpdate = new Vendor_Invoicing_Header__c();
        if(qbResponseWrapper != null && (qbResponseWrapper.Bill != null || qbResponseWrapper.VendorCredit != null)) {
            vohToUpdate.Id = reqObj.SFId;
            vohToUpdate.availForQBSync__c = false;
            vohToUpdate.accountingLastSyncTime__c = system.now();
            vohToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
            if(qbResponseWrapper.Bill != null) {
                vohToUpdate.AccountingId__c = qbResponseWrapper.Bill.Id;
                vohToUpdate.SyncToken__c = qbResponseWrapper.Bill.SyncToken;
            } else if(qbResponseWrapper.VendorCredit != null) {
                vohToUpdate.AccountingId__c = qbResponseWrapper.VendorCredit.Id;
                vohToUpdate.SyncToken__c = qbResponseWrapper.VendorCredit.SyncToken;
            }
            sobjListToSync.add(vohToUpdate);  
            reqObj.SyncToken = vohToUpdate.SyncToken__c;                                                                                                                                                                 
            return vohToUpdate.AccountingId__c;
        }
        return '';
    }
     
    private String handleUnitInvoiceResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBVendorBillDTO reqObj = (QBVendorBillDTO)payload;
        Customer_Owned_Unit__c couRecord = new Customer_Owned_Unit__c();
        if((qbResponseWrapper != null && qbResponseWrapper.Bill != null) || (qbQueryResponse != null && qbQueryResponse.Bill != null && qbQueryResponse.Bill.size() > 0)) {
            couRecord.Id = reqObj.SFId;
            couRecord.availForQBSync__c = false;
            couRecord.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.Bill != null) {
                couRecord.AccountingId__c = qbResponseWrapper.Bill.Id;
                couRecord.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                couRecord.SyncToken__c = qbResponseWrapper.Bill.SyncToken;
                sobjListToSync.add(couRecord);
            } else {
                for(QBVendorBillDTO bill : qbQueryResponse.Bill) {
                    if((bill.Id == reqObj.Id) || (reqObj.PrivateNote == bill.PrivateNote && String.isNotBlank(reqObj.PrivateNote) && String.isNotBlank(bill.PrivateNote))) {
                        couRecord.AccountingId__c = bill.Id;
                        couRecord.AccountingResponse__c = (bill + '').abbreviate(32768);
                        couRecord.SyncToken__c = bill.SyncToken;
                        sobjListToSync.add(couRecord);
                        break;
                    }
                }
            }
            reqObj.SyncToken = couRecord.SyncToken__c;                                                                                                                                                                 
            return couRecord.AccountingId__c;
        }
        return '';
    }
     
    private String handleLienPayoutResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBVendorBillDTO reqObj = (QBVendorBillDTO)payload;
        Deal_Item__c dealItem = new Deal_Item__c();
        if(qbResponseWrapper != null && qbResponseWrapper.Bill != null) {
            dealItem.Id = reqObj.SFId;
            dealItem.Lien_Payout_Avail_For_QB_Sync__c = false;
            dealItem.Lien_Payout_Accounting_Last_Sync_Time__c = system.now();
            dealItem.Lien_Payout_Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
            dealItem.Lien_Payout_Accounting_Id__c = qbResponseWrapper.Bill.Id;
            dealItem.Lien_Payout_Sync_Token__c = qbResponseWrapper.Bill.SyncToken;
            sobjListToSync.add(dealItem);  
            reqObj.SyncToken = dealItem.Lien_Payout_Sync_Token__c;                                                                                                                                                                 
            return dealItem.Lien_Payout_Accounting_Id__c;
        }
        return '';
    }

    private String handleVOInvoiceVarianceJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Vendor_Invoicing_Header__c vohToUpdate = new Vendor_Invoicing_Header__c();
            vohToUpdate.Id = reqJournalEntryObj.SFId;
            vohToUpdate.Available_For_QB_Variance_JE_Sync__c = false;
            vohToUpdate.Accounting_Last_Sync_Time_Variance_JE__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                vohToUpdate.QB_Variance_JE_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                vohToUpdate.Accounting_Response_Variance_JE__c = (qbResponseWrapper + '').abbreviate(32768);
                vohToUpdate.Sync_Token_For_Variance_JE__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(vohToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        vohToUpdate.QB_Variance_JE_Accounting_Id__c = journalEntry.Id;
                        vohToUpdate.Accounting_Response_Variance_JE__c = (journalEntry + '').abbreviate(32768);
                        vohToUpdate.Sync_Token_For_Variance_JE__c = journalEntry.SyncToken;
                        sobjListToSync.add(vohToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = vohToUpdate.Sync_Token_For_Variance_JE__c;                                                                                                                                                                 
            return vohToUpdate.QB_Variance_JE_Accounting_Id__c;
        }
        return '';
    }

    private String handleRVOVarianceJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Return_CR_Header__c voReturnToUpdate = new Return_CR_Header__c();
            voReturnToUpdate.Id = reqJournalEntryObj.SFId;
            voReturnToUpdate.Available_For_QB_Variance_JE_Sync__c = false;
            voReturnToUpdate.Accounting_Last_Sync_Time_Variance_JE__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                voReturnToUpdate.QB_Variance_JE_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                voReturnToUpdate.Accounting_Response_Variance_JE__c = (qbResponseWrapper + '').abbreviate(32768);
                voReturnToUpdate.Sync_Token_For_Variance_JE__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(voReturnToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        voReturnToUpdate.QB_Variance_JE_Accounting_Id__c = journalEntry.Id;
                        voReturnToUpdate.Accounting_Response_Variance_JE__c = (journalEntry + '').abbreviate(32768);
                        voReturnToUpdate.Sync_Token_For_Variance_JE__c = journalEntry.SyncToken;
                        sobjListToSync.add(voReturnToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = voReturnToUpdate.Sync_Token_For_Variance_JE__c;                                                                                                                                                                 
            return voReturnToUpdate.QB_Variance_JE_Accounting_Id__c;
        }
        return '';
    }

    private String handleUnitInvoiceJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Customer_Owned_Unit__c couToUpdate = new Customer_Owned_Unit__c();
            couToUpdate.Id = reqJournalEntryObj.SFId;
            couToUpdate.Available_For_QB_Unit_Invoice_JE_Sync__c = false;
            couToUpdate.Accounting_Last_Sync_Time_Unit_JE__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                couToUpdate.QB_Accounting_Id_Unit_Invoice_JE__c = qbResponseWrapper.JournalEntry.Id;
                couToUpdate.Accounting_Response_Unit_Invoice_JE__c = (qbResponseWrapper + '').abbreviate(32768);
                couToUpdate.Sync_Token_For_Unit_Invoice_JE__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(couToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        couToUpdate.QB_Accounting_Id_Unit_Invoice_JE__c = journalEntry.Id;
                        couToUpdate.Accounting_Response_Unit_Invoice_JE__c = (journalEntry + '').abbreviate(32768);
                        couToUpdate.Sync_Token_For_Unit_Invoice_JE__c = journalEntry.SyncToken;
                        sobjListToSync.add(couToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = couToUpdate.Sync_Token_For_Unit_Invoice_JE__c;                                                                                                                                                                 
            return couToUpdate.QB_Accounting_Id_Unit_Invoice_JE__c;
        }
        return '';
    }

    private String handlePartCategoryResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Part__c partToUpdate = new Part__c();
            partToUpdate.Id = reqJournalEntryObj.SFId;
            partToUpdate.Avail_For_QB_Sync_Category__c = false;
            partToUpdate.Accounting_Last_Sync_Time_Category__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                partToUpdate.Accounting_Id_Category__c = qbResponseWrapper.JournalEntry.Id;
                partToUpdate.Accounting_Response_Category__c = (qbResponseWrapper + '').abbreviate(32768);
                partToUpdate.Sync_Token_Category__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(partToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        partToUpdate.Accounting_Id_Category__c = journalEntry.Id;
                        partToUpdate.Accounting_Response_Category__c = (journalEntry + '').abbreviate(32768);
                        partToUpdate.Sync_Token_Category__c = journalEntry.SyncToken;
                        sobjListToSync.add(partToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = partToUpdate.Sync_Token_Category__c;                                                                                                                                                                 
            return partToUpdate.Accounting_Id_Category__c;
        }
        return '';
    }

    private String handleStockUnitCategoryResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Customer_Owned_Unit__c couToUpdate = new Customer_Owned_Unit__c();
            couToUpdate.Id = reqJournalEntryObj.SFId;
            couToUpdate.Avail_For_QB_Sync_Category__c = false;
            couToUpdate.Accounting_Last_Sync_Time_Category__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                couToUpdate.Accounting_Id_Category__c = qbResponseWrapper.JournalEntry.Id;
                couToUpdate.Accounting_Response_Category__c = (qbResponseWrapper + '').abbreviate(32768);
                couToUpdate.Sync_Token_Category__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(couToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        couToUpdate.Accounting_Id_Category__c = journalEntry.Id;
                        couToUpdate.Accounting_Response_Category__c = (journalEntry + '').abbreviate(32768);
                        couToUpdate.Sync_Token_Category__c = journalEntry.SyncToken;
                        sobjListToSync.add(couToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = couToUpdate.Sync_Token_Category__c;                                                                                                                                                                 
            return couToUpdate.Accounting_Id_Category__c;
        }
        return '';
    }

    private String handleVOReturnResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        Return_CR_Header__c voReturnToUpdate = new Return_CR_Header__c();
        if((qbResponseWrapper != null && qbResponseWrapper.VendorCredit != null) || (qbQueryResponse != null && qbQueryResponse.VendorCredit != null && qbQueryResponse.VendorCredit.size() > 0)) {
            QBVendorCreditDTO reqVendorCreditObj = (QBVendorCreditDTO)payload;
            voReturnToUpdate.Id = reqVendorCreditObj.SFId;
            voReturnToUpdate.Available_For_QB_Sync__c = false;
            voReturnToUpdate.Accounting_Last_Sync_Time__c = System.now();
            if(qbResponseWrapper != null && qbResponseWrapper.VendorCredit != null) {
                voReturnToUpdate.Accounting_Id__c = qbResponseWrapper.VendorCredit.Id;
                voReturnToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                voReturnToUpdate.Sync_Token__c = qbResponseWrapper.VendorCredit.SyncToken;
                sobjListToSync.add(voReturnToUpdate);
            } else {
                for(QBVendorCreditDTO vendorCredit : qbQueryResponse.VendorCredit) {
                    if((vendorCredit.Id == reqVendorCreditObj.Id) || (reqVendorCreditObj.PrivateNote == vendorCredit.PrivateNote && String.isNotBlank(reqVendorCreditObj.PrivateNote) && String.isNotBlank(vendorCredit.PrivateNote))) {
                        voReturnToUpdate.Accounting_Id__c = vendorCredit.Id;
                        voReturnToUpdate.Accounting_Response__c = (vendorCredit + '').abbreviate(32768);
                        voReturnToUpdate.Sync_Token__c = vendorCredit.SyncToken;
                        sobjListToSync.add(voReturnToUpdate);
                        break;
                    }
                }
            }
            reqVendorCreditObj.SyncToken = voReturnToUpdate.Sync_Token__c;                                                                                                                                                                
            return voReturnToUpdate.Accounting_Id__c;
        } else if((qbResponseWrapper != null && qbResponseWrapper.Bill != null) || (qbQueryResponse != null && qbQueryResponse.Bill != null && qbQueryResponse.Bill.size() > 0)) {
            QBVendorBillDTO reqBillObj = (QBVendorBillDTO)payload;

            voReturnToUpdate.Id = reqBillObj.SFId;
            voReturnToUpdate.Available_For_QB_Sync__c = false;
            voReturnToUpdate.Accounting_Last_Sync_Time__c = System.now();
            if(qbResponseWrapper != null && qbResponseWrapper.Bill != null) {
                voReturnToUpdate.Accounting_Id__c = qbResponseWrapper.Bill.Id;
                voReturnToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                voReturnToUpdate.Sync_Token__c = qbResponseWrapper.Bill.SyncToken;
                sobjListToSync.add(voReturnToUpdate);
            } else {
                for(QBVendorBillDTO bill : qbQueryResponse.Bill) {
                    if((bill.Id == reqBillObj.Id) || (reqBillObj.PrivateNote == bill.PrivateNote && String.isNotBlank(reqBillObj.PrivateNote) && String.isNotBlank(bill.PrivateNote))) {
                        voReturnToUpdate.Accounting_Id__c = bill.Id;
                        voReturnToUpdate.Accounting_Response__c = (bill + '').abbreviate(32768);
                        voReturnToUpdate.Sync_Token__c = bill.SyncToken;
                        sobjListToSync.add(voReturnToUpdate);
                        break;
                    }
                }
            }                
            reqBillObj.SyncToken = voReturnToUpdate.Sync_Token__c;                                            
            return voReturnToUpdate.Accounting_Id__c;
        } 
        return '';
    }

    private String handleStockTradeInResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Deal_Item__c dealItemToUpdate = new Deal_Item__c();
            dealItemToUpdate.Id = reqJournalEntryObj.SFId;
            dealItemToUpdate.Avail_For_QB_Sync__c = false;
            dealItemToUpdate.Accounting_Last_Sync_Time__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                dealItemToUpdate.Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                dealItemToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                dealItemToUpdate.Sync_Token__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(dealItemToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        dealItemToUpdate.Accounting_Id__c = journalEntry.Id;
                        dealItemToUpdate.Accounting_Response__c = (journalEntry + '').abbreviate(32768);
                        dealItemToUpdate.Sync_Token__c = journalEntry.SyncToken;
                        sobjListToSync.add(dealItemToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = dealItemToUpdate.Sync_Token__c;                                                                                                                                                                
            return dealItemToUpdate.Accounting_Id__c;
        }
        return '';
    }

    private String handleUnitNITCJEResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Customer_Owned_Unit__c couToUpdate = new Customer_Owned_Unit__c();
            couToUpdate.Id = reqJournalEntryObj.SFId;
            couToUpdate.Available_For_QB_NITC_JE_Sync__c = false;
            couToUpdate.Accounting_Last_Sync_Time_NITC_JE__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                couToUpdate.QB_NITC_JE_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                couToUpdate.Accounting_Response_NITC_JE__c = (qbResponseWrapper + '').abbreviate(32768);
                couToUpdate.Sync_Token_For_NITC_JE__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(couToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        couToUpdate.QB_NITC_JE_Accounting_Id__c = journalEntry.Id;
                        couToUpdate.Accounting_Response_NITC_JE__c = (journalEntry + '').abbreviate(32768);
                        couToUpdate.Sync_Token_For_NITC_JE__c = journalEntry.SyncToken;
                        sobjListToSync.add(couToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = couToUpdate.Sync_Token_For_NITC_JE__c;                                                                                                                                                                
            return couToUpdate.QB_NITC_JE_Accounting_Id__c;
        }
        return '';
    }

    private String handleARPaymentResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBPaymentDTO reqPaymentObj = (QBPaymentDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.Payment != null) || (qbQueryResponse != null && qbQueryResponse.Payment != null && qbQueryResponse.Payment.size() > 0)) {
            Payment_on_Account__c paymentOnAccountToUpdate = new Payment_on_Account__c();
            paymentOnAccountToUpdate.Id = reqPaymentObj.SFId;
            paymentOnAccountToUpdate.Available_For_QB_AR_Payment_Sync__c = false;
            paymentOnAccountToUpdate.QB_AR_Payment_Last_Sync_Time__c = system.now();

            if(qbResponseWrapper != null && qbResponseWrapper.Payment != null) {
                paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Id__c = qbResponseWrapper.Payment.Id;
                paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                paymentOnAccountToUpdate.QB_AR_Payment_Sync_Token__c = qbResponseWrapper.Payment.SyncToken;
                sobjListToSync.add(paymentOnAccountToUpdate);
            } else {
                for(QBPaymentDTO payment : qbQueryResponse.Payment) {
                    if((payment.Id == reqPaymentObj.Id)) {
                        paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Id__c = payment.Id;
                        paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Response__c = (payment + '').abbreviate(32768);
                        paymentOnAccountToUpdate.QB_AR_Payment_Sync_Token__c = payment.SyncToken;
                        sobjListToSync.add(paymentOnAccountToUpdate);
                        break;
                    }
                }
            }
            reqPaymentObj.SyncToken = paymentOnAccountToUpdate.QB_AR_Payment_Sync_Token__c;                                                                                                                                                                
            return paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Id__c;
        }
        return '';
    }

    private String handleInvoicePaymentResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBPaymentDTO reqPaymentObj = (QBPaymentDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.Payment != null) || (qbQueryResponse != null && qbQueryResponse.Payment != null && qbQueryResponse.Payment.size() > 0)) {
            CO_Invoice_Header__c coInvoiceToUpdate = new CO_Invoice_Header__c();
            if(sobjListToSync.size() > 0) coInvoiceToUpdate = (CO_Invoice_Header__c)sobjListToSync[sobjListToSync.size() - 1];
            coInvoiceToUpdate.Id = reqPaymentObj.SFId;
            coInvoiceToUpdate.availForQBCOInvoicePayment__c = false;
            coInvoiceToUpdate.accountingLastSyncTimeForCOInvPayment__c = system.now();

            if(qbResponseWrapper != null && qbResponseWrapper.Payment != null) {
                coInvoiceToUpdate.AccountingIdForCOInvoicePayment__c = qbResponseWrapper.Payment.Id;
                coInvoiceToUpdate.AccountingResponseForCOInvoicePayment__c = (qbResponseWrapper + '').abbreviate(32768);
                coInvoiceToUpdate.SyncTokenForCOInvoicePayment__c = qbResponseWrapper.Payment.SyncToken;
                if(sobjListToSync.size() == 0) sobjListToSync.add(coInvoiceToUpdate);
            } else {
                for(QBPaymentDTO payment : qbQueryResponse.Payment) {
                    if((payment.Id == reqPaymentObj.Id) || 
                        (String.isNotBlank(payment.PaymentRefNum) && String.isNotBlank(reqPaymentObj.PaymentRefNum) && 
                        payment.PaymentRefNum == reqPaymentObj.PaymentRefNum) && 
                        String.isNotBlank(payment.PrivateNote) && String.isNotBlank(reqPaymentObj.PrivateNote) && 
                        payment.PrivateNote == reqPaymentObj.PrivateNote) {
                        coInvoiceToUpdate.AccountingIdForCOInvoicePayment__c = payment.Id;
                        coInvoiceToUpdate.AccountingResponseForCOInvoicePayment__c = (payment + '').abbreviate(32768);
                        coInvoiceToUpdate.SyncTokenForCOInvoicePayment__c = payment.SyncToken;
                        if(sobjListToSync.size() == 0) sobjListToSync.add(coInvoiceToUpdate);
                        break;
                    }
                }
            }
            reqPaymentObj.SyncToken = coInvoiceToUpdate.SyncTokenForCOInvoicePayment__c;                                                                                                                                                                
            return coInvoiceToUpdate.AccountingIdForCOInvoicePayment__c;
        }
        return '';
    }

    private String handlePaymentonAccountResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) || (qbQueryResponse != null && qbQueryResponse.JournalEntry != null && qbQueryResponse.JournalEntry.size() > 0)) {
            Payment_on_Account__c poaToUpdate = new Payment_on_Account__c();
            poaToUpdate.Id = reqJournalEntryObj.SFId;
            poaToUpdate.Available_For_QB_Sync__c = false;
            poaToUpdate.Accounting_Last_Sync_Time__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.JournalEntry != null) {
                poaToUpdate.QB_Accounting_Id__c = qbResponseWrapper.JournalEntry.Id;
                poaToUpdate.Accounting_Response__c = (qbResponseWrapper + '').abbreviate(32768);
                poaToUpdate.Accounting_Sync_Token__c = qbResponseWrapper.JournalEntry.SyncToken;
                sobjListToSync.add(poaToUpdate);
            } else {
                for(QBJournalEntryDTO journalEntry : qbQueryResponse.JournalEntry) {
                    if((journalEntry.Id == reqJournalEntryObj.Id) || (reqJournalEntryObj.PrivateNote == journalEntry.PrivateNote && String.isNotBlank(reqJournalEntryObj.PrivateNote) && String.isNotBlank(journalEntry.PrivateNote))) {
                        poaToUpdate.QB_Accounting_Id__c = journalEntry.Id;
                        poaToUpdate.Accounting_Response__c = (journalEntry + '').abbreviate(32768);
                        poaToUpdate.Accounting_Sync_Token__c = journalEntry.SyncToken;
                        sobjListToSync.add(poaToUpdate);
                        break;
                    }
                }
            }
            reqJournalEntryObj.SyncToken = poaToUpdate.Accounting_Sync_Token__c;                                                                                                                                                                
            return poaToUpdate.QB_Accounting_Id__c;
        }
        return '';
    }

    private String handleItemCategoryResponse(QBResponseWrapper qbResponseWrapper, Object payload, List<sObject> sobjListToSync, QBQueryResponseWrapper.QBResponseWrapper qbQueryResponse) {
        QBItemDTO reqItemObj = (QBItemDTO)payload;
        if((qbResponseWrapper != null && qbResponseWrapper.Item != null) || (qbQueryResponse != null && qbQueryResponse.Item != null && qbQueryResponse.Item.size() > 0)) {
            Category__c categoryToUpdate = new Category__c();
            categoryToUpdate.Id = reqItemObj.SFId;
            categoryToUpdate.availForQBSync__c = false;
            categoryToUpdate.accountingLastSyncTime__c = system.now();
            if(qbResponseWrapper != null && qbResponseWrapper.Item != null) {
                categoryToUpdate.AccountingId__c = qbResponseWrapper.Item.Id;
                categoryToUpdate.AccountingResponse__c = (qbResponseWrapper + '').abbreviate(32768);
                categoryToUpdate.SyncToken__c = qbResponseWrapper.Item.SyncToken;
                sobjListToSync.add(categoryToUpdate);
            } else {
                for(QBItemDTO item : qbQueryResponse.Item) {
                    if((item.Id == reqItemObj.Id) || (item.Name == reqItemObj.Name)) {
                        categoryToUpdate.AccountingId__c = item.Id;
                        categoryToUpdate.AccountingResponse__c = (item + '').abbreviate(32768);
                        categoryToUpdate.SyncToken__c = item.SyncToken;
                        sobjListToSync.add(categoryToUpdate);
                        break;
                    }
                }
            }
            reqItemObj.SyncToken = categoryToUpdate.SyncToken__c;                                                                                                                                                                
            return categoryToUpdate.AccountingId__c;
        }
        return '';
    }

    private Object generatePayload(String entityType, List<Object> syncObjList, List<sObject> sobjListToSync) {
        Object payload;
        if(entityType == IntegrationUtility.CO_DEPOSIT) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            payload = createCODepositPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CUSTOMER) {
            payload = createCustomerPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VENDOR) {
            payload = createVendorPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CO_INVOICE_PAYMENT) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            payload = createCOInvoicePaymentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.STORE_CREDIT) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            payload = createStoreCreditPayload(syncObjList);
        } else if(entityType == IntegrationUtility.COUNT_SESSION_JE) {
            payload = createCountSessionPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VENDOR_RECEIVING) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createVendorReceivingPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_FIFO) {
            payload = createPartFIFOPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createPartFIFOBucketActivityLineItemPayload(syncObjList);
        } else if(entityType == IntegrationUtility.HOURS_LOGGED) {
            payload = createHoursLoggedPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_INVOICE) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createVOInvoicePayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_INVOICE_VARIANCE_JE) {
            payload = createVIVarianceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
            payload = createUnitInvoiceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_CATEGORY) {
            payload = createPartCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            payload = createStockUnitCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.STOCK_TRADE_IN) {
            payload = createStockTradeInPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
            payload = createUnitNITCJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.QB_AR_PAYMENT) {
            payload = createARPaymentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PAYMENT_ON_ACCOUNT) {
            payload = createPaymentOnAccountPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_RETURN) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createVOReturnPayload(syncObjList);
        } else if(entityType == IntegrationUtility.ITEM_CATEGORY) {
            payload = createItemCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_PRICE_COST) {
            payload = createUnitPriceAndCostPayload(syncObjList);
        } else if(entityType == IntegrationUtility.INVOICE) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            payload = createCOInvoicePayload(syncObjList);
            QBBaseInvoiceDTO reqJCOInvoiceObj = (QBBaseInvoiceDTO)payload;
            if(reqJCOInvoiceObj != null && reqJCOInvoiceObj.Line != null && reqJCOInvoiceObj.Line.size() == 0) {
                CO_Invoice_Header__c coInvoiceHeaderToUpdate = new CO_Invoice_Header__c();
                coInvoiceHeaderToUpdate.Id = reqJCOInvoiceObj.SFId;
                coInvoiceHeaderToUpdate.availForQBSync__c = false;
                coInvoiceHeaderToUpdate.AccountingResponse__c = QBUtil.CO_INVOICE_NO_LI_MSG;
                sobjListToSync.add(coInvoiceHeaderToUpdate);
                return null;
            }
        } else if(entityType == IntegrationUtility.LIEN_PAYOUT) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createLienpayoutPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CO_INVOICE_JE) {
            payload = createCOInvoiceJEPayload(syncObjList);
            QBJournalEntryDTO reqJournalEntryObj = (QBJournalEntryDTO)payload;
            if(reqJournalEntryObj != null && reqJournalEntryObj.Line != null && reqJournalEntryObj.Line.size() == 0) {
                CO_Invoice_Header__c coInvoiceHeaderToUpdate = new CO_Invoice_Header__c();
                coInvoiceHeaderToUpdate.Id = reqJournalEntryObj.SFId;
                coInvoiceHeaderToUpdate.availForQBJournalEntrySync__c = false;
                coInvoiceHeaderToUpdate.AccountingResponseForJournalEntry__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                coInvoiceHeaderToUpdate.accountingLastSyncTimeForJE__c = system.now();
                sobjListToSync.add(coInvoiceHeaderToUpdate);
                return null;
            }
        } else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            payload = createInvoicePaymentPayload(syncObjList, sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_CONSIGNMENT) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            payload = createConsignmentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE) {
            entityToReactivate = IntegrationUtility.VENDOR;
            payload = createUnitInvoicePayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_RETURN_VARIANCE_JE) {
            payload = createRVOVarianceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.BATCH_CUSTOMER && !syncObjList.isEmpty()) {
            payload = syncObjList[0];
        } else if(entityType == IntegrationUtility.BATCH_VENDOR && !syncObjList.isEmpty()) {
            payload = syncObjList[0];
        } if(entityType == IntegrationUtility.CASH_RECONCILIATION) {
            payload = createCashReconciliationPayload(syncObjList);
        } 
        return payload;
    }

    private Object createRVOVarianceJEPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbVIVarianceJEObj;
        for(Object viObj : syncObjList) {
            qbVIVarianceJEObj = new QBJournalEntryDTO((AccountingVendorReturn) viObj);
        }
        return qbVIVarianceJEObj;
    }

    private Object createUnitInvoicePayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        AccountingUnit accountingUnitObj = (AccountingUnit)syncObjList[0];
        accountingunitObj.DueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(accountingUnitObj.CreatedDate, accountingUnitObj.Vendor.AccountingId, integrationConfigRec, this.qbTermsList);
        QBVendorBillDTO qbBillDTOObj = new QBVendorBillDTO(accountingUnitObj);
        return qbBillDTOObj;
    }

    private Object createConsignmentPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        QBCreditMemoDTO dtoObj = new QBCreditMemoDTO((AccountingUnit)syncObjList[0]);
        return dtoObj;
    }
    
    private Object createInvoicePaymentPayload(List<Object> syncObjList, List<sObject> sobjListToSync) {
        if(syncObjList.size() == 0) return null;
        AccountingCustomerInvoice accountingCustomerInvoiceObj = (AccountingCustomerInvoice)syncObjList[0];
        if(sobjListToSync.size() > 0) {
            CO_Invoice_Header__c coInvoiceRecObj = (CO_Invoice_Header__c)sobjListToSync[sobjListToSync.size() - 1];
            accountingCustomerInvoiceObj.AccountingCOInvoiceHeaderRec.AccountingId = coInvoiceRecObj.AccountingId__c;
        }
        return new QBPaymentDTO(accountingCustomerInvoiceObj);
    }

    private Object createCOInvoiceJEPayload(List<Object> syncObjList){
        if(syncObjList.size() == 0) return null;
        QBJournalEntryDTO qbCOInvoiceJEObj = new QBJournalEntryDTO((AccountingCustomerInvoice) syncObjList[0]);
        return qbCOInvoiceJEObj;
    }

    private Object createLienpayoutPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        AccountingLienPayout accountingLienPayoutObj = (AccountingLienPayout)syncObjList[0];
        accountingLienPayoutObj.DueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(accountingLienPayoutObj.InvoiceDate,accountingLienPayoutObj.FinanceCompany.AccountingId, integrationConfigRec, this.qbTermsList);
        QBVendorBillDTO qbBillDTOObj = new QBVendorBillDTO(accountingLienPayoutObj);
        return qbBillDTOObj;
    }

    private Object createCOInvoicePayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        AccountingCustomerInvoice accountingCustomerInvoiceObj = (AccountingCustomerInvoice)syncObjList[0];
        QBInvoiceDTO qbInvoiceDTOObj = new QBInvoiceDTO(accountingCustomerInvoiceObj);
        if(accountingCustomerInvoiceObj.SyncingObjectType == IntegrationUtility.INVOICE) {
            Date dueDate = QBInvoiceDueDateService.getCustomerInvoiceDueDate(accountingCustomerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceDate, accountingCustomerInvoiceObj.AccountingCOInvoiceHeaderRec.customer.AccountingId, integrationConfigRec, this.qbTermsList);
            qbInvoiceDTOObj.DueDate = dueDate.format();
        }
        
        return qbInvoiceDTOObj;
    }

    private Object createUnitPriceAndCostPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;

        AccountingUnitPriceAndCost accountingUnitPriceAndCostObj = (AccountingUnitPriceAndCost)syncObjList[0];
        if(String.isNotBlank(accountingUnitPriceAndCostObj.VendorId)) {
            entityToReactivate = IntegrationUtility.VENDOR;
            if(accountingUnitPriceAndCostObj.TotalCost != null && accountingUnitPriceAndCostObj.TotalCost < 0) {
                return new QBVendorCreditDTO(accountingUnitPriceAndCostObj);
            } else {
                return new QBVendorBillDTO(accountingUnitPriceAndCostObj);
            }
        } else if(String.isNotBlank(accountingUnitPriceAndCostObj.CustomerId)) {
            entityToReactivate = IntegrationUtility.CUSTOMER;
            if(accountingUnitPriceAndCostObj.TotalCost != null && accountingUnitPriceAndCostObj.TotalCost < 0) {
                return new QBInvoiceDTO(accountingUnitPriceAndCostObj);
            } else {
                return new QBCreditMemoDTO(accountingUnitPriceAndCostObj);
            }
        } 
        return new QBJournalEntryDTO(accountingUnitPriceAndCostObj);
    }

    private Object createItemCategoryPayload(List<Object> syncObjList) {
        QBItemDTO qbItemCategoryObj;
        for(Object categoryObj : syncObjList) {
            qbItemCategoryObj = new QBItemDTO((AccountingItemCategory) categoryObj);
        }
        return qbItemCategoryObj;
    }
    private Object createVOReturnPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        AccountingVendorReturn accountingVendorReturnObj = (AccountingVendorReturn)syncObjList[0];
        if(accountingVendorReturnObj.Total != null && accountingVendorReturnObj.Total < 0) {
            return new QBVendorBillDTO(accountingVendorReturnObj);
        } else {
            return new QBVendorCreditDTO(accountingVendorReturnObj);
        }
    }

    private Object createPaymentOnAccountPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        return new QBJournalEntryDTO((AccountingPaymentOnAccount) syncObjList[0]);
    }

    private Object createARPaymentPayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        return new QBPaymentDTO((AccountingPaymentOnAccount) syncObjList[0]);
    }

    private Object createUnitNITCJEPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbUnitNITCJEObj;
        for(Object couObj : syncObjList) {
            qbUnitNITCJEObj = new QBJournalEntryDTO((AccountingUnit) couObj, IntegrationUtility.UNIT_NITC_JE);
        }
        return qbUnitNITCJEObj;
    }

    private Object createStockTradeInPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbStockTradeInObj;
        for(Object stockTradeObj : syncObjList) {
            qbStockTradeInObj = new QBJournalEntryDTO((AccountingDealItem) stockTradeObj);
        }
        return qbStockTradeInObj;
    }



    private Object createStockUnitCategoryPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbStockUnitCategoryObj;
        for(Object couObj : syncObjList) {
            qbStockUnitCategoryObj = new QBJournalEntryDTO((AccountingUnit) couObj, IntegrationUtility.STOCK_UNIT_CATEGORY);
        }
        return qbStockUnitCategoryObj;
    }

    private Object createPartCategoryPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbPartCategoryObj;
        for(Object partObj : syncObjList) {
            qbPartCategoryObj = new QBJournalEntryDTO((AccountingPart) partObj);
        }
        return qbPartCategoryObj;
    }

    private Object createVIVarianceJEPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbVIVarianceJEObj;
        for(Object viObj : syncObjList) {
            qbVIVarianceJEObj = new QBJournalEntryDTO((AccountingVendorInvoice) viObj);
        }
        return qbVIVarianceJEObj;
    }

    private Object createUnitInvoiceJEPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbUnitInvoiceJEObj;
        for(Object couObj : syncObjList) {
            qbUnitInvoiceJEObj = new QBJournalEntryDTO((AccountingUnit) couObj, IntegrationUtility.UNIT_INVOICE_JE);
        }
        return qbUnitInvoiceJEObj;
    }

    private Object createVOInvoicePayload(List<Object> syncObjList) {
        if(syncObjList.size() == 0) return null;
        AccountingVendorInvoice vendorInvoiceObj = (AccountingVendorInvoice)syncObjList[0];
        if(vendorInvoiceObj.AccountingVIHeaderRec.TotalAmt != null && vendorInvoiceObj.AccountingVIHeaderRec.TotalAmt < 0) {
            return (new QBVendorCreditDTO(vendorInvoiceObj));
        } else {
            QBVendorBillDTO billObj = new QBVendorBillDTO(vendorInvoiceObj);
            billObj.DueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(vendorInvoiceObj.AccountingVIHeaderRec.InvoiceDate, 
                                        vendorInvoiceObj.AccountingVIHeaderRec.VendorAccountingId, integrationConfigRec, this.qbTermsList);
            return billObj;
        }
    }

    private Object createHoursLoggedPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbHoursLoggedJEObj;
        for(Object hoursLoggedObj : syncObjList) {
            qbHoursLoggedJEObj = new QBJournalEntryDTO((AccountingHoursLogged) hoursLoggedObj);
        }
        return qbHoursLoggedJEObj;
    }

    private Object createPartFIFOBucketActivityLineItemPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbPartFIFOBucketActivityLineItemObj;
        for(Object partFIFOLIObj : syncObjList) {
            qbPartFIFOBucketActivityLineItemObj = new QBJournalEntryDTO((AccountingFIFOBucketActivityLineItem) partFIFOLIObj);
        }
        return qbPartFIFOBucketActivityLineItemObj;
    }

    private Object createPartFIFOPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbPartFIFOJEObj;
        for(Object partFIFOObj : syncObjList) {
            qbPartFIFOJEObj = new QBJournalEntryDTO((AccountingFIFOBucket) partFIFOObj);
        }
        return qbPartFIFOJEObj;
    }

    private Object createVendorReceivingPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbVendorReceivingObj;
        for(Object vReceivingObj : syncObjList) {
            qbVendorReceivingObj = new QBJournalEntryDTO((AccountingVendorReceiving) vReceivingObj);
        }
        return qbVendorReceivingObj;
    }

    private Object createCountSessionPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbCountSessionObj;
        for(Object cSessionObj : syncObjList) {
            qbCountSessionObj = new QBJournalEntryDTO((AccountingCountSession) cSessionObj);
        }
        return qbCountSessionObj;
    }

    private Object createStoreCreditPayload(List<Object> syncObjList){
        QBJournalEntryDTO qbStoreCreditJEObj;
        for(Object sCreditObj : syncObjList) {
            qbStoreCreditJEObj = new QBJournalEntryDTO((AccountingStoreCredit) sCreditObj);
        }
        return qbStoreCreditJEObj;
    }

    private Object createCODepositPayload(List<Object> syncObjList) {
        QBJournalEntryDTO qbDepositJEObj;
        for(Object coDepositObj : syncObjList) {
            qbDepositJEObj = new QBJournalEntryDTO((AccountingCODeposit) coDepositObj);
        }
        return qbDepositJEObj;
    }

    private Object createCashReconciliationPayload(List<Object> syncObjList) {
        QBJournalEntryDTO qbDepositJEObj;
        for(Object cashReconObj : syncObjList) {
            qbDepositJEObj = new QBJournalEntryDTO((AccountingCashReconciliation) cashReconObj);
        }
        return qbDepositJEObj;
    }

    private Object createCOInvoicePaymentPayload(List<Object> syncObjList) {
        QBJournalEntryDTO qbCOIPJEObj;
        for(Object coipObj : syncObjList) {
            qbCOIPJEObj = new QBJournalEntryDTO((AccountingCOInvoicePayment) coipObj);
        }
        return qbCOIPJEObj;
    }

    private Object createCustomerPayload(List<Object> syncObjList) {
        QBCustomerDTO qbCustomerObj;
        for(Object customerObj : syncObjList) {
            qbCustomerObj = new QBCustomerDTO((AccountingCustomer) customerObj);
        }
        return qbCustomerObj;
    }

    private Object createVendorPayload(List<Object> syncObjList) {
        QBVendorDTO qbVendorObj;
        for(Object vendorObj : syncObjList) {
            qbVendorObj = new QBVendorDTO((AccountingVendor) vendorObj);
        }
        return qbVendorObj;
    }

    private String fetchEntityFromQB(Object payload, List<sObject> sobjListToSync, String entityType, IFW_IntegrationConfigItem__c integrationConfigItemRec, List<Object> syncObjList) {
        String qbAccIdFromGETReq;
        String syncToken = getQBWrapperFieldsFromPayload(payload, 'SyncToken');
        if(this.isSendRequestRequiredForGET || syncToken != null) { // run from script or retry handler
            HttpResponse GETResponse = getQBGETReqResponse(payload, integrationConfigItemRec, entityType);
            if(GETResponse != null) {
                QBQueryResponseWrapper response = (QBQueryResponseWrapper)System.JSON.deserialize(GETResponse.getBody(), QBQueryResponseWrapper.class);
                if(response != null && response.QueryResponse != null && ((response.QueryResponse.TotalCount != null && response.QueryResponse.TotalCount > 0) || (response.QueryResponse.maxResults != null && response.QueryResponse.maxResults > 0))) {
                    qbAccIdFromGETReq = handleResponse(null, payload, sobjListToSync, entityType, response.QueryResponse, syncObjList);
                }
            }
        }
        return qbAccIdFromGETReq;
    }

    private HttpResponse getQBGETReqResponse(Object payload, IFW_IntegrationConfigItem__c integrationConfigItemRec, String entityType) {
    	String qbAccIdFromPayload, qbDocNumberFromPayload, query, qbDisplayNameFromPayload, endpoint, qbUniqueNameFromPayload;
        List<String> filterConditionList = new List<String>();
       
        qbAccIdFromPayload = getQBWrapperFieldsFromPayload(payload, 'Id');
        qbDocNumberFromPayload = getQBWrapperFieldsFromPayload(payload, 'DocNumber');
        qbDisplayNameFromPayload = getQBWrapperFieldsFromPayload(payload, 'DisplayName');
        if(entityType == IntegrationUtility.ITEM_CATEGORY) {
            qbUniqueNameFromPayload = getQBWrapperFieldsFromPayload(payload, 'Name');
        } else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            qbUniqueNameFromPayload = getQBWrapperFieldsFromPayload(payload, 'PaymentRefNum');
        }
        if(String.isNotBlank(qbAccIdFromPayload) || String.isNotBlank(qbDocNumberFromPayload) || String.isNotBlank(qbDisplayNameFromPayload) || String.isNotBlank(qbUniqueNameFromPayload)) { // acc Id is not updated in BP when transaction first tried to sync
            if(String.isNotBlank(qbAccIdFromPayload)) {
                filterConditionList.add('Id = \'' + qbAccIdFromPayload + '\'');
            } else if (String.isNotBlank(qbDocNumberFromPayload)) {
                filterConditionList.add('DocNumber = \'' + qbDocNumberFromPayload + '\'');
            } else if (String.isNotBlank(qbDisplayNameFromPayload)) {
                filterConditionList.add('DisplayName = \'' + BPUtility.escapeSingleQuotes(qbDisplayNameFromPayload) + '\'');
            }  else if (String.isNotBlank(qbUniqueNameFromPayload)) {
                if(entityType == IntegrationUtility.ITEM_CATEGORY) {
                    filterConditionList.add('Name = \'' + qbUniqueNameFromPayload + '\'');
                } else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
                    filterConditionList.add('PaymentRefNum = \'' + qbUniqueNameFromPayload + '\'');
                }
            }
            query = QBCalloutManager.getRecordsFilterQuery(entityNameToEntityToQueryMap.get(integrationConfigItemRec.Entity_Name__c), filterConditionList, 0, null);
            
            integrationConfigItemRec.HTTP_Method__c = 'GET';
            if(String.isNotBlank(integrationConfigItemRec.Endpoint_URL__c)) {
                endpoint = integrationConfigItemRec.Endpoint_URL__c;
                // Endpoint manipuation for GET call in QB
                integrationConfigItemRec.Endpoint_URL__c = (integrationConfigItemRec.Endpoint_URL__c).substringBeforeLast('{{company_id}}/') + '{{company_id}}/query';
            }
            HttpResponse getResponse = performGETCallout(integrationConfigItemRec, query);
            integrationConfigItemRec.Endpoint_URL__c = endpoint; //Resetting endpoint to actual endpoint.
            if(getResponse.getStatusCode() == 200 || getResponse.getStatusCode() == 201) {
                return getResponse;
            } else {
                throw new BlackpurlException('Error fetching data from QB:' + getResponse.getBody());
            }
        }
    	return null;
    }

    private HttpResponse performGETCallout(IFW_IntegrationConfigItem__c integrationConfigItemRec, String query) {
    	Map<String, String> urlParamMap = new Map<String, String>();
        if(String.isNotBlank(query)) urlParamMap.put('query', query);
        return BaseIntegration.performCallout(integrationConfigRec, integrationConfigItemRec, null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
    }

    private String getQBWrapperFieldsFromPayload(Object payload, String entity) {
        if(payload != null) {
            Map<String, Object> reqObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(payload));
            return (String)reqObj.get(entity);
        }
    	return null;
    }

    private void handleBPError(String errorMeaage, List<Object> syncObjList, List<sObject> sobjListToSync, String entityType) {
        for(Object obj: syncObjList) {
            Map<String, Object> entityDTOMap = (Map<String, Object>) JSON.deserializeUntyped(System.JSON.serialize(obj));
            setDataForSObject(sobjListToSync, (String)entityDTOMap.get('Id'), errorMeaage, entityType);
        }
    }
    
    private void setDataForSObject(List<sObject> sobjListToSync, String sfId, String response, String entityType) {
    	Sobject objectName = Schema.getGlobalDescribe().get(Id.valueOf(sfId).getSObjectType().getDescribe().getName()).newSObject();
        objectName.put('Id', sfId);
        objectName.put(XeroUtility.entityTypeToAccResponseAPINameMap.get(entityType), response);
        sobjListToSync.add(objectName);
    }

    private void checkForRetryLogic(Exception e, List<Object> syncObjList) {
        Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(QBUtil.QUICKBOOKS_ONLINE);
        String errorKeywordWhileSyncing;
        for(String errorType : errorTypeToRetryConfigListMap.keySet()) {
            if(e.getMessage() != null && (e.getMessage().containsIgnoreCase(errorType) || 
                e.getMessage().containsIgnoreCase(AccountingUtil.STATUS_CODE_TEXT + errorTypeToRetryConfigListMap.get(errorType).Error_Code__c))) {
                errorKeywordWhileSyncing = errorType;
                break;
            }
        }
        
        if(String.isNotBlank(errorKeywordWhileSyncing) && retryRequestNumber <= XeroUtility.MAX_RETRY_COUNT) {
            this.writeToFailedRecordsMap(errorKeywordWhileSyncing, syncObjList);
        }
    }

    private void syncCOInvoicePayment(List<Object> syncObjList, List<sObject> sobjListToSync, String entityType) {
        AccountingCustomerInvoice customerInvoiceRec = (AccountingCustomerInvoice)syncObjList[0];
        if(customerInvoiceRec.SyncingObjectType == QBUtil.INVOICE && customerInvoiceRec.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount > 0) {
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{entityType => IntegrationUtility.CREATE_ACTION};
        	sync(syncObjList, sobjListToSync, entityType, integrationEntityNameToActionMap);
        }
    }

    public static List<QBInvoiceDTO> getUnpaidInvoicesFromQB(String customerRefNumber, IFW_IntegrationConfig__c integrationConfigRec, Set<String> invoiceAccountingIdSet) {
        List<QBInvoiceDTO> invoiceList = new List<QBInvoiceDTO>();
        List<QBInvoiceDTO> invoiceListFromQB = new List<QBInvoiceDTO>();
        List<String> filterConditions = new List<String>();
        if(String.isNotBlank(customerRefNumber)) {
            filterConditions.add('customerref =\'' + customerRefNumber + '\'');
        }
        if(invoiceAccountingIdSet != null && !invoiceAccountingIdSet.isEmpty()) {
            String idString = '';
            for(String idStr : invoiceAccountingIdSet) {
                idString += '\'' + idStr + '\',';
            }
            idString = idString.removeEnd(',');
            filterConditions.add('id IN (' + idString + ')');
        } else {
            filterConditions.add('balance !=\'0\'');
        }
		Integer pageNumber = 0;

        do {
            invoiceListFromQB = new List<QBInvoiceDTO>();
            QBQueryResponseWrapper.QBResponseWrapper qbResponse = QBCalloutManager.getData(IntegrationUtility.INVOICE, filterConditions, integrationConfigRec, pageNumber, RECORDS_PER_PAGE);
            if(qbResponse != null && qbResponse.Invoice != null && qbResponse.Invoice.size() > 0) {
                invoiceListFromQB = qbResponse.Invoice;
                invoiceList.addAll(invoiceListFromQB);
            } 
            pageNumber++;
        } while(invoiceListFromQB.size() >= RECORDS_PER_PAGE);
        
        return invoiceList;
   	}

   	public static List<QBInvoiceDTO> getUnappliedCreditsFromQB(String customerRefNumber, IFW_IntegrationConfig__c integrationConfigRec, Set<String> creditsAccountingIdSet) {
        List<QBInvoiceDTO> creditMemoList = new List<QBInvoiceDTO>();
        List<QBInvoiceDTO> creditMemoListFromQB = new List<QBInvoiceDTO>();
		Integer pageNumber = 0;
    	List<String> filterConditions = new List<String>();
        if(String.isNotBlank(customerRefNumber)) {
            filterConditions.add('customerref =\'' + customerRefNumber + '\'');
        }
        if(creditsAccountingIdSet != null && !creditsAccountingIdSet.isEmpty()) {
            String idString = '';
            for(String idStr : creditsAccountingIdSet) {
                idString += '\'' + idStr + '\',';
            }
            idString = idString.removeEnd(',');
            filterConditions.add('id IN (' + idString + ')');
        } else {
            filterConditions.add('RemainingCredit !=\'0\'');
        }
        do {
            creditMemoList = new List<QBInvoiceDTO>();
            QBQueryResponseWrapper.QBResponseWrapper qbResponse = QBCalloutManager.getData(QBUtil.CREDIT_MEMO, filterConditions, integrationConfigRec, pageNumber, RECORDS_PER_PAGE);
            if(qbResponse != null && qbResponse.CreditMemo != null && qbResponse.CreditMemo.size() > 0) {
                creditMemoListFromQB = (List<QBInvoiceDTO>)qbResponse.CreditMemo;
                creditMemoList.addAll(creditMemoListFromQB);
            } 
            pageNumber++;
        } while(creditMemoListFromQB.size() >= RECORDS_PER_PAGE);
        return creditMemoList;
   	}

    public static List<QBPaymentDTO> getUnappliedPaymentsFromQB(String customerRefNumber, IFW_IntegrationConfig__c integrationConfigRec) {
        Integer apiCount = 0;
        List<QBPaymentDTO> qbPaymentResponseList = new List<QBPaymentDTO>();
        QBQueryResponseWrapper.QBResponseWrapper qbResponse;
        do {
            List<String> filterConditions = new List<String>{'customerref =\'' + customerRefNumber + '\''};
            qbResponse = QBCalloutManager.getData(IntegrationUtility.PAYMENT, filterConditions, integrationConfigRec, apiCount, 100);
            if(qbResponse != null && qbResponse.Payment != null && qbResponse.Payment.size() > 0) {
                qbPaymentResponseList.addAll(qbResponse.Payment);
            } 
            apiCount++;
        } while(qbResponse != null && qbResponse.Payment != null && qbResponse.Payment.size() == 100);
        return qbPaymentResponseList;
   	}

    private Boolean validateCustomerReactivation(HttpErrorDTO.QBErrorDTO errorResponse) {
        return errorResponse.Fault.Error[0].code == '6250' || (errorResponse.Fault.Error[0].code == '2500' 
                && errorResponse.Fault.Error[0].Detail.containsIgnoreCase(QBUtil.ASSIGNED_CUSTOMER_DELETED));
    }

    private Boolean validateVendorReactivation(HttpErrorDTO.QBErrorDTO errorResponse) {
        return (errorResponse.Fault.Error[0].code == '2500' 
                && errorResponse.Fault.Error[0].Detail.containsIgnoreCase(QBUtil.ASSIGNED_VENDOR_DELETED));
    }

    private Boolean validateDuplicateDocError(HttpErrorDTO.QBErrorDTO errorResponse) {
        return (errorResponse.Fault.Error[0].code == '6140' 
                && errorResponse.Fault.Error[0].Detail.containsIgnoreCase(QBUtil.DUPLICATE_DOC_NUMBER));
    }

    private Boolean reactivateRelatedTransaction(Object payload, List<sObject> sobjListToSync, String entityType, List<Object> syncObjList) {
        String fieldName;
        if(entityToReactivate.equalsIgnoreCase(IntegrationUtility.CUSTOMER)) {
            if(QBUtil.journalEntryEntities.contains(entityType)) fieldName = 'EntityRef';
            else if(entityType == IntegrationUtility.INVOICE || entityType == IntegrationUtility.UNIT_PRICE_COST || 
                    entityType == IntegrationUtility.UNIT_CONSIGNMENT) fieldName = 'CustomerRef';
        } else if(entityToReactivate.equalsIgnoreCase(IntegrationUtility.VENDOR)) {
            if(QBUtil.journalEntryEntities.contains(entityType)) fieldName = 'EntityRef';
            else if(entityType == IntegrationUtility.VO_INVOICE || entityType == IntegrationUtility.UNIT_PRICE_COST || 
                    entityType == IntegrationUtility.VO_RETURN || entityType == IntegrationUtility.UNIT_INVOICE || 
                    entityType == IntegrationUtility.LIEN_PAYOUT) fieldName = 'VendorRef';
        }

        String accId = getInnerEntityAccIdFromJSON(payload, fieldName);
        if(String.isNotBlank(accId)) {
            activateEntity(accId, entityToReactivate);
            sync(syncObjList, sobjListToSync, entityType, null);
            return true;
        }
        return false;
    }

    private String getInnerEntityAccIdFromJSON(Object payload, String fieldName) {
        if(String.isBlank(fieldName)) return null;
        JSONParser parser = JSON.createParser(System.JSON.serialize(payload));
        while(parser.nextToken() != null) {
            if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == fieldName)) {
                while (parser.nextToken() !=  JSONToken.END_OBJECT) {
                    if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'value')) {
                        parser.nextToken();
                        return parser.getText();
                    }
                }
            }
        }
        return null;
    }

    private void activateEntity(String entityAccId, String entityType) {
        Object qbEntityObj;
        
        QBResponseWrapper qbResponse = QBCalloutManager.getDataByQBId(entityType.toLowerCase(), entityAccId, integrationConfigRec);
        if(qbResponse != null) {
            if(qbResponse.Customer != null) {
                if(Boolean.valueOf(qbResponse.Customer.Active)) return;
                qbEntityObj = (Object)new QBCustomerDTO(entityAccId, qbResponse.Customer.SyncToken, true);
            } else if(qbResponse.Vendor != null) {
                if(Boolean.valueOf(qbResponse.Vendor.Active)) return;
                qbEntityObj = (Object)new QBVendorDTO(entityAccId, qbResponse.Vendor.SyncToken, true);
            }

            if(qbEntityObj == null) return;
            List<IFW_IntegrationConfigItem__c> integrationConfigItemList = getIntegrationConfigItemByFieldValues(integrationConfigRec.Id, 
                                                    new Map<String, String>{entityType => IntegrationUtility.UPDATE_ACTION});
            if(integrationConfigItemList.isEmpty()) throw new BlackpurlException('Endpoint configuration for ' + entityType.toLowerCase() + ' is not defined');
            
            HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, integrationConfigItemList[0], Json.serialize(qbEntityObj, true), new List<customHttpHeaderWrapper>(), entityType);
            if(response.getStatusCode() != 200) throw new BlackpurlException(response.getBody());
        }
    }

    private void updateDuplicateTransactionDocNumber(Object payload, List<sObject> sobjListToSync, String entityType, List<Object> syncObjList) {
        QBInvoiceDTO qbEntityObj;
        List<String> filterConditions = new List<String>();
        filterConditions.add('DocNumber = \'' + getQBWrapperFieldsFromPayload(payload, 'DocNumber') + '\'');
        if(integrationConfigItemList.isEmpty()) throw new BlackpurlException('Endpoint configuration for ' + entityType.toLowerCase() + ' is not defined');
        
        QBQueryResponseWrapper.QBResponseWrapper qbResponseWrapper = QBCalloutManager.getData(entityNameToEntityToQueryMap.get(integrationConfigItemList[0].Entity_Name__c), filterConditions, integrationConfigRec);
        if(qbResponseWrapper != null) {
            if(qbResponseWrapper.SalesReceipt != null && qbResponseWrapper.SalesReceipt.size() > 0) {
                qbEntityObj = new QBInvoiceDTO(qbResponseWrapper.SalesReceipt[0].Id, qbResponseWrapper.SalesReceipt[0].SyncToken, qbResponseWrapper.SalesReceipt[0].DocNumber + '.');
            } else if(qbResponseWrapper.RefundReceipt != null && qbResponseWrapper.RefundReceipt.size() > 0) {
                qbEntityObj = new QBInvoiceDTO(qbResponseWrapper.RefundReceipt[0].Id, qbResponseWrapper.RefundReceipt[0].SyncToken, qbResponseWrapper.RefundReceipt[0].DocNumber + '.');
            } else if(qbResponseWrapper.Invoice != null && qbResponseWrapper.Invoice.size() > 0) {
                qbEntityObj = new QBInvoiceDTO(qbResponseWrapper.Invoice[0].Id, qbResponseWrapper.Invoice[0].SyncToken, qbResponseWrapper.Invoice[0].DocNumber + '.');
            } else if(qbResponseWrapper.CreditMemo != null && qbResponseWrapper.CreditMemo.size() > 0) {
                qbEntityObj = new QBInvoiceDTO(qbResponseWrapper.CreditMemo[0].Id, qbResponseWrapper.CreditMemo[0].SyncToken, qbResponseWrapper.CreditMemo[0].DocNumber + '.');
            }

            if(qbEntityObj == null) return;
            
            HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, integrationConfigItemList[0], Json.serialize(qbEntityObj, true), new List<customHttpHeaderWrapper>(), entityType);
            if(response.getStatusCode() == 200) sync(syncObjList, sobjListToSync, entityType, null);
            
        }
    }
}
/**
 * Author: Gaurav Tak
 * Since: February 15, 2019
 * Name: XeroService
**/
public without sharing class XeroService extends BaseIntegrationService {
    
    public XeroService(IFW_IntegrationConfig__c integrationConfigRec) {
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
                                                           Map<String, String> xeroEntityNameToActionMap) {
        List<IFW_IntegrationConfigItem__c> integrationConfigItemList = getIntegrationConfigItemByFieldValues(integrationConfigRec.Id, 
                                                                                                                xeroEntityNameToActionMap);
        try {
            if(integrationConfigItemList.size() == 0) throw new BlackpurlException('Endpoint configurations not defined');
            Map<String, List<Object>> payload = generatePayload(entityType, syncObjList, sobjListToSync);
            if(payload == null) {
                return (BaseIntegration.webServiceLogs != null ? BaseIntegration.webServiceLogs : new List<WebService_Log__c>());
            }
            
            // Check If Entity already synced to Xero OR not?
            String xeroAccIdFromGETReq = fetchEntityFromXero(payload, integrationConfigItemList, sobjListToSync, entityType);
            
            // If entity if not synced already, need to send POST call to sync entity
            // There can be following cases - 
            //      1. This is first time sync
            //      2. Retry logic / Syncing Script when transaction not created Xero
            //      3. If we want to update existing successfull Transaction
            if(String.isBlank(xeroAccIdFromGETReq)) {
            	postEntityToXero(payload, integrationConfigItemList, sobjListToSync, syncObjList, entityType);
        	} else if(entityType == IntegrationUtility.INVOICE) { // if invoice created in Xero then sync payment
        		syncCOInvoicePayment(syncObjList, sobjListToSync, IntegrationUtility.INVOICE_PAYMENT, xeroAccIdFromGETReq);
        	}
        	
        } catch(HttpRequestException e) {
            checkForRetryLogic(e, syncObjList);
            
        } catch(Exception e) {
        	
            handleBPError(e.getMessage(), syncObjList, sobjListToSync, entityType);
            
            checkForRetryLogic(e, syncObjList);
            
            this.errorLogs.add(new LogService().createErrorLog('XeroService', 'sync()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              syncObjList+'', LogService.XERO, false,'Error'));
        }
        return (BaseIntegration.webServiceLogs != null ? BaseIntegration.webServiceLogs : new List<WebService_Log__c>());
    }
    
    // Method to fetch Entity Accounting Id from Xero if already there.
    private String fetchEntityFromXero(Map<String, List<Object>> payload, List<IFW_IntegrationConfigItem__c> integrationConfigItemList,
                                        List<sObject> sobjListToSync, String entityType) {
        String xeroAccIdFromPayload, xeroAccIdFromGETReq;
        HttpResponse GETResponse;
        
        if(this.isSendRequestRequiredForGET) { // run from script or retry handler
            xeroAccIdFromPayload = getXeroAccountingIdFromPayload(payload);
            if(String.isBlank(xeroAccIdFromPayload)) { // acc Id is not updated in BP when transaction first tried to sync
                GETResponse = getXeroGETReqResponse(integrationConfigItemList[0], payload);
                xeroAccIdFromGETReq = getXeroAccountingIdFromGETResponse(GETResponse, payload, entityType);
                if(String.isNotBlank(xeroAccIdFromGETReq) && GETResponse != null) {
                    handleResponse(GETResponse, payload, sobjListToSync, entityType);
                }
            }
        }
        return xeroAccIdFromGETReq;
    }
    
    private void postEntityToXero(Map<String, List<Object>> payload, List<IFW_IntegrationConfigItem__c> integrationConfigItemList,
                                        List<sObject> sobjListToSync, List<Object> syncObjList, String entityType) {
        String requestBody = replaceReservedKeywordFromRequestBody(payload);
                
        // HTTP Method GET is coming because it is changed in GET API call above.
        if(integrationConfigItemList[0].HTTP_Method__c == 'GET') {
            integrationConfigItemList[0].HTTP_Method__c = 'POST';
        }
        if(integrationConfigItemList[0].Entity_Name__c == IntegrationUtility.CONTACTS) {
            integrationConfigItemList[0].Endpoint_URL__c += '?summarizeErrors=false';
        }
        // Perform callout and response handling
        performCalloutandHandleResponse(integrationConfigItemList[0], requestBody, entityType, payload, sobjListToSync);
        
        // In case of CO Invoice syncing, we need to also sync CO Invoice Payment
        if(entityType == IntegrationUtility.INVOICE) {
            syncCOInvoicePayment(syncObjList, sobjListToSync, IntegrationUtility.INVOICE_PAYMENT, null);
        }
    }
    
    private void checkForRetryLogic(Exception e, List<Object> syncObjList) {
        Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(XeroUtility.XERO);
        String errorKeywordWhileSyncing;
        for(String errorType : errorTypeToRetryConfigListMap.keySet()) {
            if(e.getMessage() != null && e.getMessage().containsIgnoreCase(errorType)) {
                errorKeywordWhileSyncing = errorType;
                break;
            }
        }
        
        if(String.isNotBlank(errorKeywordWhileSyncing) && retryRequestNumber <= XeroUtility.MAX_RETRY_COUNT) {
            this.writeToFailedRecordsMap(errorKeywordWhileSyncing, syncObjList);
        }
    }
    
    private String getXeroAccountingIdFromPayload(Map<String, List<Object>> payload) {
    	for(String syncEntityType : payload.keySet()) {
    		if(XeroUtility.syncingEntityTypeToXeroAccIdNameMap.containsKey(syncEntityType) && payload.containsKey(syncEntityType) && 
    			payload.get(syncEntityType).size() > 0) {
    			
    			String xeroAccIdName = XeroUtility.syncingEntityTypeToXeroAccIdNameMap.get(syncEntityType);
    			Map<String, Object> reqObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(payload.get(syncEntityType)[0]));
    			return (String)reqObj.get(xeroAccIdName);
    		}
    	}
    	return null;
    }
    
    private HttpResponse getXeroGETReqResponse(IFW_IntegrationConfigItem__c integrationConfigItemRec, Map<String, List<Object>> payload) {
    	String whereClause = XeroUtility.getWhereClauseForGETReq(payload);
    	if(String.isNotBlank(whereClause)) {
    		integrationConfigItemRec.HTTP_Method__c = 'GET';
            HttpResponse getResponse = performGETCallout(integrationConfigItemRec, whereClause);
            
            if(getResponse.getStatusCode() == 200 || getResponse.getStatusCode() == 201) {
            	return getResponse;
            } else {
            	throw new BlackpurlException('Error fetching data from Xero: ' + getResponse.getBody());
            }
        }
    	return null;
    }
    
    private String getXeroAccountingIdFromGETResponse(HttpResponse GETResponse, Map<String, List<Object>> payload, String entityType) {
    	for(String syncEntityType: payload.keySet()) {
    		Map<String, Object> resWrapperObj = (Map<String, Object>)JSON.deserializeUntyped(GETResponse.getBody());
    		List<Object> syncEntityObjList = (List<Object>)resWrapperObj.get(syncEntityType);
    		
    		if(resWrapperObj.containsKey(syncEntityType) && resWrapperObj.get(syncEntityType) != null && syncEntityObjList.size() > 0 && 
    			payload.containsKey(syncEntityType) && payload.get(syncEntityType).size() > 0 &&
    			XeroUtility.syncingEntityTypeToXeroAccIdNameMap.containsKey(syncEntityType)) {
    			
    			Map<String, Object> reqObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(payload.get(syncEntityType)[0]));
    			Map<String, Object> resObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(syncEntityObjList[0]));
    			
    			String xeroAccIdName = XeroUtility.syncingEntityTypeToXeroAccIdNameMap.get(syncEntityType);
    			if(entityType == IntegrationUtility.INVOICE_PAYMENT || (resObj.get('Url') != null && (String)resObj.get('Url') == (String)reqObj.get('Url'))) {
    				return (String)resObj.get(xeroAccIdName);
    			}
    		}
    	}
    	return null;
    }
    
    private HttpResponse performGETCallout(IFW_IntegrationConfigItem__c integrationConfigItemRec, String whereClause) {
    	Map<String, String> urlParamMap = new Map<String, String>{'where' => EncodingUtil.urlEncode(whereClause,'UTF-8')};
        return BaseIntegration.performCallout(integrationConfigRec, integrationConfigItemRec, null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
    }
    
    private String replaceReservedKeywordFromRequestBody(Map<String, List<Object>> payload) {
    	String requestBody = System.JSON.serialize(payload, true);
        if(requestBody != null) {
            requestBody = requestBody.replace('"JournalDate":', '"Date":');
            requestBody = requestBody.replace('"InvDate":', '"Date":');
        }
        return requestBody;
    }
    
    //Perform Callout and handle response
    public void performCalloutandHandleResponse(IFW_IntegrationConfigItem__c integrationConfigItem, String requestBody, String entityType, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
		HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, integrationConfigItem, requestBody, new List<customHttpHeaderWrapper>(), entityType);
        handleResponse(response, payload, sobjListToSync, entityType);
    }
    
    private Map<String, List<Object>> generatePayload(String entityType, List<Object> syncObjList, List<sObject> sobjListToSync) {
        Map<String, List<Object>> payload;
        if(entityType == IntegrationUtility.ITEM_CATEGORY) {
            payload = createItemCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_FIFO) {
            payload = createPartFifoBucketPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM) {
            payload = createPartFifoBucketActivityLineItemPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PART_CATEGORY) {
            payload = createPartCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CO_DEPOSIT) {
            payload = createCODepositPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_CONSIGNMENT) {
            payload = createConsignmentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VENDOR) {
            payload = createVendorPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CO_INVOICE_PAYMENT) {
            payload = createCOInvoicePaymentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CUSTOMER) {
            payload = createCustomerPayload(syncObjList);
        } else if(entityType == IntegrationUtility.STORE_CREDIT) {
            payload = createStoreCreditPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_PRICE_COST) {
            payload = createUnitPriceAndCostPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VENDOR_RECEIVING) {
            //system.assert(false, syncObjList);
            payload = createVendorReceivingPayload(syncObjList);
        } else if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            payload = createStockUnitCategoryPayload(syncObjList);
        } else if(entityType == IntegrationUtility.INVOICE) {
            payload = createCOInvoicePayload(syncObjList);
            AccountingCustomerInvoice accountingCustomerInvoiceObj = (AccountingCustomerInvoice)syncObjList[0];
            String syncObjectName = '';
            if(accountingCustomerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
                syncObjectName = 'CreditNotes';
            } else {
                syncObjectName = 'Invoices';
            }
            List<XeroBaseInvoiceDTO> requestCOInvoiceList = (List<XeroBaseInvoiceDTO>)payload.get(syncObjectName);
            for(Object obj: payload.get(syncObjectName)) {
                XeroBaseInvoiceDTO reqJCOInvoiceObj = (XeroBaseInvoiceDTO)obj;
                if(reqJCOInvoiceObj != null && reqJCOInvoiceObj.LineItems != null && reqJCOInvoiceObj.LineItems.size() == 0) {
                    CO_Invoice_Header__c coInvoiceHeaderToUpdate = new CO_Invoice_Header__c();
                    coInvoiceHeaderToUpdate.Id = requestCOInvoiceList[0].SFId;
                    coInvoiceHeaderToUpdate.Available_For_Xero_Sync__c = false;
                    coInvoiceHeaderToUpdate.AccountingResponse__c = AccountingUtil.XERO_CO_INVOICE_NO_LI_MSG;
                    sobjListToSync.add(coInvoiceHeaderToUpdate);
                    return null;
                }
            }
        } else if(entityType == IntegrationUtility.STOCK_TRADE_IN) {
            payload = createStockTradeInPayload(syncObjList);
        } else if(entityType == IntegrationUtility.LIEN_PAYOUT) {
            payload = createLienpayoutPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_INVOICE) {
            payload = createVOInvoicePayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_INVOICE_VARIANCE_JE) {
            payload = createVIVarianceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            payload = createInvoicePaymentPayload(syncObjList, sobjListToSync);
        } else if(entityType == IntegrationUtility.AR_PAYMENT) {
            payload = createARPaymentPayload(syncObjList);
        } else if(entityType == IntegrationUtility.PAYMENT_ON_ACCOUNT) {
            payload = createPaymentOnAccountPayload(syncObjList);
        } else if(entityType == IntegrationUtility.CO_INVOICE_JE) {
            payload = createCOInvoiceJEPayload(syncObjList);
            List<XeroJournalEntryDTO> requestCOJEList = (List<XeroJournalEntryDTO>)payload.get('ManualJournals');
            for(Object obj: payload.get('ManualJournals')) {
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                if(reqJournalEntryObj != null && reqJournalEntryObj.JournalLines != null && reqJournalEntryObj.JournalLines.size() == 0) {
                    CO_Invoice_Header__c coInvoiceHeaderToUpdate = new CO_Invoice_Header__c();
                    coInvoiceHeaderToUpdate.Id = requestCOJEList[0].SFId;
                    coInvoiceHeaderToUpdate.Available_For_Xero_CO_Invoice_JE_Sync__c = false;
                    coInvoiceHeaderToUpdate.AccountingResponseForJournalEntry__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                    coInvoiceHeaderToUpdate.accountingLastSyncTimeForJE__c = system.now();
                    sobjListToSync.add(coInvoiceHeaderToUpdate);
                    return null;
                }
            }
        } else if(entityType == IntegrationUtility.VO_RETURN) {
            payload = createVOReturnPayload(syncObjList);
        } else if(entityType == IntegrationUtility.VO_RETURN_VARIANCE_JE) {
            payload = createRVOVarianceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE) {
            payload = createUnitInvoicePayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
            payload = createUnitInvoiceJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.HOURS_LOGGED) {
            payload = createHoursLoggedPayload(syncObjList);
        } else if(entityType == IntegrationUtility.COUNT_SESSION_JE) {
            payload = createCountSessionJEPayload(syncObjList);
        } else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
            payload = createUnitNITCJEPayload(syncObjList);
        }  else if(entityType == IntegrationUtility.CASH_RECONCILIATION) {
            payload = createCashReconciliationPayload(syncObjList);
        }
        return payload;
    } 
    
    private Map<String, List<XeroItemDTO>> createItemCategoryPayload(List<Object> syncObjList) {
        List<XeroItemDTO> xeroDTOList = new List<XeroItemDTO>();
        for(Object accCategoryObj : syncObjList) {
            xeroDTOList.add(new XeroItemDTO((AccountingItemCategory)accCategoryObj));
        }
        return new Map<String, List<XeroItemDTO>>{'Items' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createPartFifoBucketPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object accPartFifoBucketObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingFIFOBucket) accPartFifoBucketObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createCOInvoicePaymentPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object accCOInvoicePayment : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingCOInvoicePayment) accCOInvoicePayment)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createPartFifoBucketActivityLineItemPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object accPartFifoBucketActivityLineitemObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingFIFOBucketActivityLineItem)accPartFifoBucketActivityLineitemObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createPartCategoryPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object accPartObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingPart) accPartObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createCODepositPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object coDepositObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingCODeposit) coDepositObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createHoursLoggedPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object hoursLoggedObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingHoursLogged) hoursLoggedObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createCountSessionJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object countSessioObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingCountSession) countSessioObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }

    private Map<String, List<XeroJournalEntryDTO>> createCashReconciliationPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object cashReconObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingCashReconciliation) cashReconObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createUnitNITCJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object unitObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingUnit) unitObj, IntegrationUtility.UNIT_NITC_JE)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroContactDTO>> createVendorPayload(List<Object> syncObjList) {
        List<XeroContactDTO> xeroDTOList = new List<XeroContactDTO>();
        for(Object vendorObj : syncObjList) {
            xeroDTOList.add(new XeroContactDTO((AccountingVendor) vendorObj)); 
        }
        return new Map<String, List<XeroContactDTO>>{'Contacts' => xeroDTOList};
    }
    
     private Map<String, List<XeroContactDTO>> createCustomerPayload(List<Object> syncObjList) {
        List<XeroContactDTO> xeroDTOList = new List<XeroContactDTO>();
        for(Object customerObj : syncObjList) {
            xeroDTOList.add(new XeroContactDTO((AccountingCustomer) customerObj)); 
        }
        return new Map<String, List<XeroContactDTO>>{'Contacts' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createStoreCreditPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object accStoreCreditObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingStoreCredit)accStoreCreditObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<Object>> createUnitPriceAndCostPayload(List<Object> syncObjList) {
        List<Object> xeroDTOList = new List<Object>();
        AccountingUnitPriceAndCost accountingUnitPriceAndCostObj = (AccountingUnitPriceAndCost)syncObjList[0];
        
        Map<String, List<Object>> syncEntityNameToDTOListMap = new Map<String, List<Object>>();
        String entityName;
        for(Object accUnitPriceAndCostObj : syncObjList) {
            if(String.isNotBlank(accountingUnitPriceAndCostObj.VendorId)) {
                
                if(accountingUnitPriceAndCostObj.TotalCost != null && accountingUnitPriceAndCostObj.TotalCost < 0) {
                    entityName = 'CreditNotes';
                    xeroDTOList.add((Object) (new XeroCreditNoteDTO(accountingUnitPriceAndCostObj))); 
                } else {
                    entityName = 'Invoices';
                    setUnitPriceAndCostDueDate(accountingUnitPriceAndCostObj, integrationConfigRec);
                    xeroDTOList.add((Object) (new XeroInvoiceDTO(accountingUnitPriceAndCostObj))); 
                }

            } else if(String.isNotBlank(accountingUnitPriceAndCostObj.CustomerId)) {

                if(accountingUnitPriceAndCostObj.TotalCost != null && accountingUnitPriceAndCostObj.TotalCost < 0) {
                    entityName = 'Invoices';
                    setUnitPriceAndCostDueDate(accountingUnitPriceAndCostObj, integrationConfigRec);
                    xeroDTOList.add((Object) (new XeroInvoiceDTO(accountingUnitPriceAndCostObj))); 
                } else {
                    entityName = 'CreditNotes';
                    xeroDTOList.add((Object) (new XeroCreditNoteDTO(accountingUnitPriceAndCostObj))); 
                }

            } else {
                entityName = 'ManualJournals';
                xeroDTOList.add((Object) (new XeroJournalEntryDTO(accountingUnitPriceAndCostObj))); 
            }
        }
        return new Map<String, List<Object>>{entityName => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createVendorReceivingPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object vendorReceivingObj : syncObjList) {
            //system.assert(false,vendorReceivingObj);
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingVendorReceiving) vendorReceivingObj)); 
            //system.assert(false,xeroDTOList);
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createStockUnitCategoryPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object stockUnitObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingUnit) stockUnitObj, IntegrationUtility.STOCK_UNIT_CATEGORY)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
   private Map<String, List<XeroJournalEntryDTO>> createStockTradeInPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object dealItemObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingDealItem) dealItemObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroBaseInvoiceDTO>> createCOInvoicePayload(List<Object> syncObjList) {
        AccountingCustomerInvoice accountingCustomerInvoiceObj = (AccountingCustomerInvoice)syncObjList[0];
        String syncObjectName = '';
        XeroBaseInvoiceDTO xeroInvoiceDTOObj;
        if(accountingCustomerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
            syncObjectName = 'CreditNotes';
            xeroInvoiceDTOObj = new XeroCreditNoteDTO(accountingCustomerInvoiceObj);
        } else {
            syncObjectName = 'Invoices';
            setCustomerInvoiceDueDate(accountingCustomerInvoiceObj, integrationConfigRec);
            xeroInvoiceDTOObj = new XeroInvoiceDTO(accountingCustomerInvoiceObj);
        }
        return new Map<String, List<XeroBaseInvoiceDTO>>{syncObjectName => new List<XeroBaseInvoiceDTO>{xeroInvoiceDTOObj}};
    }
    
    private Map<String, List<Object>> createVOInvoicePayload(List<Object> syncObjList) {
        
        List<Object> xeroDTOList = new List<Object>();
        AccountingVendorInvoice vendorInvoiceObj = (AccountingVendorInvoice)syncObjList[0];
        String entityName;
        for(Object accountingVendorObject : syncObjList) {
            if(vendorInvoiceObj.AccountingVIHeaderRec.TotalAmt != null && vendorInvoiceObj.AccountingVIHeaderRec.TotalAmt < 0) {
                entityName = 'CreditNotes';
                xeroDTOList.add((Object) (new XeroCreditNoteDTO(vendorInvoiceObj)));
            } else {
                entityName = 'Invoices';
                setVendorInvoiceDueDate(vendorInvoiceObj, integrationConfigRec);
                xeroDTOList.add((Object) (new XeroInvoiceDTO(vendorInvoiceObj)));             
            }
        }
        return new Map<String, List<Object>>{entityName => xeroDTOList};
    }

    private Map<String, List<Object>> createVIVarianceJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object unitObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingVendorInvoice) unitObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<Object>> createRVOVarianceJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object rvoObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingVendorReturn) rvoObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<Object>> createConsignmentPayload(List<Object> syncObjList) {
        AccountingUnit consignmentUnitObj = (AccountingUnit)syncObjList[0];
        return new Map<String, List<XeroCreditNoteDTO>>{'CreditNotes' => new List<XeroCreditNoteDTO>{new XeroCreditNoteDTO(consignmentUnitObj)}};
    }
    
    private Map<String, List<Object>> createVOReturnPayload(List<Object> syncObjList) {
        List<Object> xeroDTOList = new List<Object>();
        String entityName;
        AccountingVendorReturn vendorReturnObj = (AccountingVendorReturn)syncObjList[0];

        if(vendorReturnObj.Total != null && vendorReturnObj.Total < 0) {
            entityName = 'Invoices';
            setVOReturnDueDate(vendorReturnObj, integrationConfigRec);
            xeroDTOList.add((Object) (new XeroInvoiceDTO(vendorReturnObj))); 
        } else {
            entityName = 'CreditNotes';
            xeroDTOList.add((Object) (new XeroCreditNoteDTO(vendorReturnObj))); 
        }

        return new Map<String, List<Object>>{entityName => xeroDTOList};
    }
    
    private Map<String, List<XeroBaseInvoiceDTO>> createUnitInvoicePayload(List<Object> syncObjList) {
        List<XeroBaseInvoiceDTO> xeroDTOList = new List<XeroBaseInvoiceDTO>();
        
        for(Object unitObj : syncObjList) {
        	setUnitInvoiceDueDate((AccountingUnit) unitObj, integrationConfigRec);
            xeroDTOList.add(new XeroInvoiceDTO((AccountingUnit) unitObj));
        }   
        return new Map<String, List<XeroBaseInvoiceDTO>>{'Invoices' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createUnitInvoiceJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object unitObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingUnit)unitObj, IntegrationUtility.UNIT_INVOICE_JE));
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroInvoicePaymentDTO>> createInvoicePaymentPayload(List<Object> syncObjList, List<sObject> sobjListToSync) {
        AccountingCustomerInvoice customerInvoiceObj = (AccountingCustomerInvoice)syncObjList[0];
        Map<String, sObject> invoiceSFIdToRecMap = new Map<String, sObject>();
        for(sObject sObjRec: sobjListToSync) {
            invoiceSFIdToRecMap.put(sObjRec.Id, sObjRec);
        }
        CO_Invoice_Header__c coInvoiceRecObj = (invoiceSFIdToRecMap.containsKey(customerInvoiceObj.Id) ? ((CO_Invoice_Header__c)invoiceSFIdToRecMap.get(customerInvoiceObj.Id)) : null);
        return new Map<String, List<XeroInvoicePaymentDTO>>{'Payments' => new List<XeroInvoicePaymentDTO>{new XeroInvoicePaymentDTO(customerInvoiceObj, coInvoiceRecObj)}};
    }
    
    private Map<String, List<XeroInvoicePaymentDTO>> createARPaymentPayload(List<Object> syncObjList) {
    	List<XeroInvoicePaymentDTO> xeroInvPaymentDTOList = new List<XeroInvoicePaymentDTO>();
        for(Object arPayment : syncObjList) {
            xeroInvPaymentDTOList.add(new XeroInvoicePaymentDTO((AccountingARPayment) arPayment)); 
        }
        return new Map<String, List<XeroInvoicePaymentDTO>>{'Payments' => xeroInvPaymentDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createPaymentOnAccountPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object paymentOnAccountJEObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingPaymentOnAccount)paymentOnAccountJEObj));
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private Map<String, List<XeroLienPayoutDTO>> createLienpayoutPayload(List<Object> syncObjList) {
        List<XeroLienPayoutDTO> xeroDTOList = new List<XeroLienPayoutDTO>();
        for(Object lienPayout : syncObjList) {
            setLienPayoutDueDate((AccountingLienPayout) lienPayout, integrationConfigRec);
            xeroDTOList.add(new XeroLienPayoutDTO((AccountingLienPayout) lienPayout)); 
        }
        return new Map<String, List<XeroLienPayoutDTO>>{'Invoices' => xeroDTOList};
    }
    
    private Map<String, List<XeroJournalEntryDTO>> createCOInvoiceJEPayload(List<Object> syncObjList) {
        List<XeroJournalEntryDTO> xeroDTOList = new List<XeroJournalEntryDTO>();
        for(Object coInvoiceJEObj : syncObjList) {
            xeroDTOList.add(new XeroJournalEntryDTO((AccountingCustomerInvoice)coInvoiceJEObj)); 
        }
        return new Map<String, List<XeroJournalEntryDTO>>{'ManualJournals' => xeroDTOList};
    }
    
    private void handleResponse(HttpResponse response, Map<String, List<Object>> payload, List<sObject> sobjListToSync, String entityType) {
        if(String.valueOf(response.getStatusCode()) == '200') {
            handleBulkResponse(response, payload, sobjListToSync, entityType);
        } else {
            //Error Handling
            handleErrorResponse(response, payload, sobjListToSync, entityType, null);
        }
    }

    private void handleBulkResponse(HttpResponse response, Map<String, List<Object>> payload, List<sObject> sobjListToSync, String entityType) {
        if(entityType == IntegrationUtility.CUSTOMER || entityType == IntegrationUtility.VENDOR) {
            handleBulkCustomerVendorResponse(response, payload, sobjListToSync, entityType);
        } else {
            handleSuccessResponse(response.getBody(), payload, sobjListToSync, entityType);
        }
    }

    private void handleBulkCustomerVendorResponse(HttpResponse httpResponse, Map<String, List<Object>> payload, List<sObject> sobjListToSync, String entityType) {
        XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper) System.JSON.deserialize(httpResponse.getBody(), XeroResponseWrapper.class);
        
        XeroResponseWrapper customerVendorSuccessResWrapper = new XeroResponseWrapper();
        customerVendorSuccessResWrapper.Contacts = new List<XeroContactDTO>();

        Map<String, String> contactNumberToErrorResponseMap = new Map<String, String>();

        for(XeroContactDTO xeroObj : xeroResponseWrapper.Contacts) {
            if(!xeroObj.StatusAttributeString.containsIgnoreCase('Error')) {
                customerVendorSuccessResWrapper.Contacts.add(xeroObj);
            } else {
                contactNumberToErrorResponseMap.put(xeroObj.ContactNumber, System.JSON.serialize(xeroObj));
            }
        } 

        if(customerVendorSuccessResWrapper.Contacts.size() > 0) {
            handleSuccessResponse(System.JSON.serialize(customerVendorSuccessResWrapper), payload, sobjListToSync, entityType);
        }
        if(contactNumberToErrorResponseMap.size() > 0) {
            handleErrorResponse(httpResponse, payload, sobjListToSync, entityType, contactNumberToErrorResponseMap);
        }     
    }

    private void handleSuccessResponse(String responseBody, Map<String, List<Object>> payload, List<sObject> sobjListToSync, String entityType) {
        XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper) System.JSON.deserialize(responseBody, XeroResponseWrapper.class);
        if(entityType == IntegrationUtility.ITEM_CATEGORY) {
            handleItemCategoryResponse(xeroResponseWrapper, payload, (List<Category__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.PART_FIFO) {
            handlePartFIFOBucketResponse(xeroResponseWrapper, payload, (List<Part_FIFO_Bucket__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM) {
            handlePartFIFOBucketActivityLineItemResponse(xeroResponseWrapper, payload, (List<Part_FIFO_Bucket_Activity_Line_Item__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.PART_CATEGORY) {
            handlePartCategoryResponse(xeroResponseWrapper, payload, (List<Part__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.CO_DEPOSIT) {
            handleCODepositResponse(xeroResponseWrapper, payload, (List<CO_Deposit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_CONSIGNMENT) {
            handleConsignmentResponse(xeroResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VENDOR) {
            handleVendorResponse(xeroResponseWrapper, payload, (List<Account>)sobjListToSync);
        } else if(entityType == IntegrationUtility.CO_INVOICE_PAYMENT) {
            handleCOInvoicePaymentResponse(xeroResponseWrapper, payload, (List<CO_Invoice_Payment__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.CUSTOMER) {
            handleCustomerResponse(xeroResponseWrapper, payload, (List<Account>)sobjListToSync);
        } else if(entityType == IntegrationUtility.STORE_CREDIT) {
            handleStoreCreditResponse(xeroResponseWrapper, payload, (List<Store_Credit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_PRICE_COST) {
            handleUnitPriceAndCostResponse(xeroResponseWrapper, payload, (List<Unit_Price_Cost__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            handleStockUnitCategoryResponse(xeroResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VENDOR_RECEIVING) {
            handleVendorReceivingResponse(xeroResponseWrapper, payload, (List<Vendor_Receiving_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.INVOICE) {
            handleCOInvoiceResponse(xeroResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.STOCK_TRADE_IN) {
            handleStockTradeInResponse(xeroResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VO_INVOICE) {
            handleVOInvoiceResponse(xeroResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VO_INVOICE_VARIANCE_JE) {
            handleVIVarianceJEResponse(xeroResponseWrapper, payload, (List<Vendor_Invoicing_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            handleInvoicePaymentResponse(xeroResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.AR_PAYMENT) {
        	handleARPaymentResponse(xeroResponseWrapper, payload, (List<AR_Payment__c>)sobjListToSync);
        }  else if(entityType == IntegrationUtility.PAYMENT_ON_ACCOUNT) {
        	handlePaymentOnAccountResponse(xeroResponseWrapper, payload, (List<AR_Payment__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.LIEN_PAYOUT) {
            handleLienPayoutResponse(xeroResponseWrapper, payload, (List<Deal_Item__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.CO_INVOICE_JE) {
            handleCOInvoiceJEResponse(xeroResponseWrapper, payload, (List<CO_Invoice_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VO_RETURN) {
            handleVOReturnResponse(xeroResponseWrapper, payload, (List<Return_VO_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.VO_RETURN_VARIANCE_JE) {
            handleRVOVarianceJEResponse(xeroResponseWrapper, payload, (List<Return_VO_Header__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE) {
            handleUnitInvoiceResponse(xeroResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
        	handleUnitInvoiceJEResponse(xeroResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.HOURS_LOGGED) {
            handleHoursLoggedResponse(xeroResponseWrapper, payload, (List<Hours_Logged__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.COUNT_SESSION_JE) {
            handleCountSessionJEResponse(xeroResponseWrapper, payload, (List<Count_Session__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
            handleUnitNITCJEResponse(xeroResponseWrapper, payload, (List<Customer_Owned_Unit__c>)sobjListToSync);
        } else if(entityType == IntegrationUtility.CASH_RECONCILIATION) {
            handleCashReconciliationResponse(xeroResponseWrapper, payload, (List<Cash_Reconciliation__c>)sobjListToSync);
        }  
    }
    
    private void handleErrorResponse(HttpResponse httpResponse, Map<String, List<Object>> payload, List<sObject> sobjListToSync, String entityType, Map<String, String> errorResponseMap) {
    	String responseBody = httpResponse.getBody();
    	if(entityType == IntegrationUtility.INVOICE_PAYMENT) {
            Map<String, sObject> invoiceSFIdToRecMap = new Map<String, sObject>();
            for(sObject sObjRec: sobjListToSync) {
                invoiceSFIdToRecMap.put(sObjRec.Id, sObjRec);
            }
            for(Object obj: payload.get('Payments')) { // assuming there is a single request and response object
                XeroInvoicePaymentDTO reqPaymentObj = (XeroInvoicePaymentDTO)obj;
                CO_Invoice_Header__c coInvoiceToUpdate = (invoiceSFIdToRecMap.containsKey(reqPaymentObj.SFId) ? ((CO_Invoice_Header__c)invoiceSFIdToRecMap.get(reqPaymentObj.SFId)) : 
                                                            new CO_Invoice_Header__c(Id = reqPaymentObj.SFId));
                coInvoiceToUpdate.AccountingResponseForCOInvoicePayment__c = responseBody.abbreviate(32768);
                if(!invoiceSFIdToRecMap.containsKey(reqPaymentObj.SFId)) sobjListToSync.add(coInvoiceToUpdate);
            }
        } else {
        	List<Object> DTOList = new List<Object>();
	    	for(String syncingType: XeroUtility.entityTypeToSyncTypeMap.get(entityType)) {
	    		if(payload.containsKey(syncingType)) {
	    			DTOList = payload.get(syncingType);
	    			break;
	    		}
	    	} 

            for(Object obj: DTOList) {
	    		Map<String, Object> entityDTOMap = (Map<String, Object>) JSON.deserializeUntyped(System.JSON.serialize(obj));
                if((entityType == IntegrationUtility.CUSTOMER || entityType == IntegrationUtility.VENDOR) && errorResponseMap != null && errorResponseMap.size() > 0) {
                    responseBody = System.JSON.serialize(errorResponseMap.get((String)entityDTOMap.get('ContactNumber')));
                    if(errorResponseMap.get((String)entityDTOMap.get('ContactNumber')) == null) continue;
                } 
                setDataForSObject(sobjListToSync, (String)entityDTOMap.get('SFId'), responseBody, entityType);
			}
        }
    	
        HttpErrorDTO errorResponse = (HttpErrorDTO) System.JSON.deserialize(httpResponse.getBody(), HttpErrorDTO.class);
        throw new HttpRequestException(httpResponse.getBody());
    }

    private void handleBPError(String errorMeaage, List<Object> syncObjList, List<sObject> sobjListToSync, String entityType) {
    	if(entityType == IntegrationUtility.INVOICE_PAYMENT && sobjListToSync.size() > 0) {
            CO_Invoice_Header__c coInvoiceToUpdate = (CO_Invoice_Header__c)sobjListToSync[sobjListToSync.size() - 1];
            coInvoiceToUpdate.AccountingResponseForCOInvoicePayment__c = errorMeaage.abbreviate(32768);
        } else {
	    	for(Object obj: syncObjList) {
	    		Map<String, Object> entityDTOMap = (Map<String, Object>) JSON.deserializeUntyped(System.JSON.serialize(obj));
	            setDataForSObject(sobjListToSync, (String)entityDTOMap.get('Id'), errorMeaage, entityType);
			}
        }
    }
    
    private void setDataForSObject(List<sObject> sobjListToSync, String sfId, String response, String entityType) {
    	Sobject objectName = Schema.getGlobalDescribe().get(Id.valueOf(sfId).getSObjectType().getDescribe().getName()).newSObject();
        objectName.put('Id', sfId);
        objectName.put(XeroUtility.entityTypeToAccResponseAPINameMap.get(entityType), response);
        sobjListToSync.add(objectName);
    }
    
    private void handleItemCategoryResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.Items != null && !xeroResponseWrapper.Items.isEmpty()) {
            for(Object obj: payload.get('Items')) { // assuming there is a single request and response object
                XeroItemDTO reqItemObj = (XeroItemDTO)obj;
                Category__c categoryObjToUpdate = new Category__c();
                categoryObjToUpdate.Id = reqItemObj.SFId;
                categoryObjToUpdate.Available_For_Xero_Sync__c = false;
                categoryObjToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.Items[0].ItemID;
                categoryObjToUpdate.AccountingResponse__c = (xeroResponseWrapper.Items[0] + '').abbreviate(32768);
                categoryObjToUpdate.accountingLastSyncTime__c = system.now();
                categoryObjToUpdate.QB_Updated_Fields__c = null;
                sobjListToSync.add(categoryObjToUpdate);
            }
        }
    }
    
    private void handlePartFIFOBucketResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Part_FIFO_Bucket__c partFIFOBucketToUpdate = new Part_FIFO_Bucket__c();
                partFIFOBucketToUpdate.Id = reqJournalEntryObj.SFId;
                partFIFOBucketToUpdate.Available_For_Xero_Sync__c = false;
                partFIFOBucketToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                partFIFOBucketToUpdate.AccountingResponse__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                partFIFOBucketToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(partFIFOBucketToUpdate);
            }
        }
    }
    
    private void handlePartFIFOBucketActivityLineItemResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLineItemToUpdate = new Part_FIFO_Bucket_Activity_Line_Item__c();
                partFIFOBucketActivityLineItemToUpdate.Id = reqJournalEntryObj.SFId;
                partFIFOBucketActivityLineItemToUpdate.Available_For_Xero_Sync__c = false;
                partFIFOBucketActivityLineItemToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                partFIFOBucketActivityLineItemToUpdate.AccountingResponse__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                partFIFOBucketActivityLineItemToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(partFIFOBucketActivityLineItemToUpdate);
            }
        }
    }
    
    private void handlePartCategoryResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Part__c partCategoryToUpdate = new Part__c();
                partCategoryToUpdate.Id = reqJournalEntryObj.SFId;
                partCategoryToUpdate.Available_For_Xero_Sync__c = false;
                partCategoryToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                partCategoryToUpdate.Accounting_Response_Category__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                partCategoryToUpdate.Accounting_Last_Sync_Time_Category__c = system.now();
                sobjListToSync.add(partCategoryToUpdate);
            }
        }
    }
    
    private void handleCODepositResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                CO_Deposit__c coDepositToUpdate = new CO_Deposit__c();
                coDepositToUpdate.Id = reqJournalEntryObj.SFId;
                coDepositToUpdate.Available_For_Xero_Sync__c = false;
                coDepositToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                coDepositToUpdate.AccountingResponseForJournalEntry__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                coDepositToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(coDepositToUpdate);
            }
        }
    }

    private void handleCashReconciliationResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Cash_Reconciliation__c cashReconToUpdate = new Cash_Reconciliation__c();
                cashReconToUpdate.Id = reqJournalEntryObj.SFId;
                cashReconToUpdate.Available_For_Xero_Sync__c = false;
                cashReconToUpdate.Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                cashReconToUpdate.Accounting_Response__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                cashReconToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(cashReconToUpdate);
            }
        }
    }
    
    private void handleConsignmentResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.CreditNotes != null && !xeroResponseWrapper.CreditNotes.isEmpty()) {
            for(Object obj: payload.get('CreditNotes')) { // assuming there is a single request and response object
                XeroCreditNoteDTO reqCreditNoteObj = (XeroCreditNoteDTO)obj;
                Customer_Owned_Unit__c cosignmentUnitToUpdate = new Customer_Owned_Unit__c();
                cosignmentUnitToUpdate.Id = reqCreditNoteObj.SFId;
                cosignmentUnitToUpdate.Available_For_Xero_Consignment_Sync__c = false;
                cosignmentUnitToUpdate.Xero_Consignment_Accounting_Id__c = xeroResponseWrapper.CreditNotes[0].CreditNoteID;
                cosignmentUnitToUpdate.Accounting_Response_Consignment__c = (xeroResponseWrapper.CreditNotes[0] + '').abbreviate(32768);
                cosignmentUnitToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(cosignmentUnitToUpdate);
            }
        }
    }
    
private void handleVendorResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<Account> sobjListToSync) {
        Map<String, XeroContactDTO> contactNumberToContactResponseMap = new Map<String, XeroContactDTO>();
        for(XeroContactDTO xeroObj : xeroResponseWrapper.Contacts) {
            contactNumberToContactResponseMap.put(xeroObj.ContactNumber,xeroObj);
        }
        if(xeroResponseWrapper.Contacts != null && !xeroResponseWrapper.Contacts.isEmpty()) {
            for(Object obj: payload.get('Contacts')) { 
                XeroContactDTO reqVendorObj = (XeroContactDTO)obj;
                if(contactNumberToContactResponseMap.get(reqVendorObj.ContactNumber) != null) {
                    Account accToUpdate = new Account();
                    accToUpdate.Id = reqVendorObj.SFId;
                    accToUpdate.Available_For_Xero_Vendor_Sync__c = false;
                    accToUpdate.Xero_Vendor_Accounting_Id__c = contactNumberToContactResponseMap.get(reqVendorObj.ContactNumber).ContactID;
                    accToUpdate.Vendor_AccountingResponse__c = (contactNumberToContactResponseMap.get(reqVendorObj.ContactNumber) + '').abbreviate(32768);
                    accToUpdate.Vendor_AccountingLastSyncTime__c = system.now();
                    accToUpdate.Vendor_QB_Updated_Fields__c = null;
                    accToUpdate.QB_Updated_Fields__c = null;
                    sobjListToSync.add(accToUpdate);
                }
            }
        } 
    }
    private void handleCustomerResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<Account> sobjListToSync) {
        Map<String, XeroContactDTO> contactNumberToContactResponseMap = new Map<String, XeroContactDTO>();
        for(XeroContactDTO xeroObj : xeroResponseWrapper.Contacts) {
            contactNumberToContactResponseMap.put(xeroObj.ContactNumber,xeroObj);
        }
        if(xeroResponseWrapper.Contacts != null && !xeroResponseWrapper.Contacts.isEmpty()) {
            for(Object obj: payload.get('Contacts')) { 
                XeroContactDTO reqCustomerObj = (XeroContactDTO)obj;
                if(contactNumberToContactResponseMap.get(reqCustomerObj.ContactNumber) != null) {
                    Account accToUpdate = new Account();
                    accToUpdate.Id = reqCustomerObj.SFId;
                    accToUpdate.Available_For_Xero_Customer_Sync__c = false;
                    accToUpdate.Xero_Customer_Accounting_Id__c = contactNumberToContactResponseMap.get(reqCustomerObj.ContactNumber).ContactID;
                    accToUpdate.AccountingResponse__c = (contactNumberToContactResponseMap.get(reqCustomerObj.ContactNumber) + '').abbreviate(32768);
                    accToUpdate.accountingLastSyncTime__c = system.now();
                    accToUpdate.QB_Updated_Fields__c = null;
                    accToUpdate.Vendor_QB_Updated_Fields__c = null;
                    sobjListToSync.add(accToUpdate);
                }
            }
        } 
    }
    
    private void handleCOInvoicePaymentResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                CO_Invoice_Payment__c coInvoicePaymentUpdate = new CO_Invoice_Payment__c();
                coInvoicePaymentUpdate.Id = reqJournalEntryObj.SFId;
                coInvoicePaymentUpdate.Available_For_Xero_Sync__c = false;
                coInvoicePaymentUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                coInvoicePaymentUpdate.AccountingResponseForJournalEntry__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                coInvoicePaymentUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(coInvoicePaymentUpdate);
            }
        }
    }
    
   private void handleStoreCreditResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Store_Credit__c storeCreditToUpdate = new Store_Credit__c();
                storeCreditToUpdate.Id = reqJournalEntryObj.SFId;
                storeCreditToUpdate.Available_For_Xero_Sync__c = false;
                storeCreditToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                storeCreditToUpdate.AccountingResponse__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                storeCreditToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(storeCreditToUpdate);
            }
        }
    }
      
    private void handleHoursLoggedResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Hours_Logged__c hoursLoggedToUpdate = new Hours_Logged__c();
                hoursLoggedToUpdate.Id = reqJournalEntryObj.SFId;
                hoursLoggedToUpdate.Available_For_Xero_Sync__c = false;
                hoursLoggedToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                hoursLoggedToUpdate.Accounting_Response__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(10000);
                hoursLoggedToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(hoursLoggedToUpdate);
            }
        }
    }
    
    private void handleCountSessionJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            String accountingRes;
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Count_Session__c countSessionToUpdate = new Count_Session__c();
                countSessionToUpdate.Id = reqJournalEntryObj.SFId;
                countSessionToUpdate.Available_For_Xero_Sync__c = false;
                countSessionToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                accountingRes = (xeroResponseWrapper.ManualJournals[0] + '');
                countSessionToUpdate.Accounting_Response__c = accountingRes.length() > 32768 ?  accountingRes.subString(accountingRes.length() - 32768,  accountingRes.length()) : accountingRes;
                countSessionToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(countSessionToUpdate);
            }
        }
    }
    
    private void handleUnitNITCJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Customer_Owned_Unit__c unitToUpdate = new Customer_Owned_Unit__c();
                unitToUpdate.Id = reqJournalEntryObj.SFId;
                unitToUpdate.Available_For_Xero_NITC_JE_Sync__c = false;
                unitToUpdate.Xero_NITC_JE_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                unitToUpdate.Accounting_Response_NITC_JE__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                unitToUpdate.Accounting_Last_Sync_Time_NITC_JE__c = system.now();
                sobjListToSync.add(unitToUpdate);
            }
        }
    }
    
    private void handleUnitPriceAndCostResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        String syncingObjectName;
        if(xeroResponseWrapper.Invoices != null && !xeroResponseWrapper.Invoices.isEmpty()) {
            syncingObjectName = 'Invoices';
        } else if(xeroResponseWrapper.CreditNotes != null && !xeroResponseWrapper.CreditNotes.isEmpty()) {
            syncingObjectName = 'CreditNotes';
        } else if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            syncingObjectName = 'ManualJournals';
        }
        if(String.isNotBlank(syncingObjectName)) {
            
            for(Object obj: payload.get(syncingObjectName)) {
                Unit_Price_Cost__c unitPriceAndCostToUpdate = new Unit_Price_Cost__c();
                unitPriceAndCostToUpdate.Available_For_Xero_Sync__c = false;
            
                if(syncingObjectName == 'ManualJournals') {
                    XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                    unitPriceAndCostToUpdate.Id = reqJournalEntryObj.SFId;
                    unitPriceAndCostToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                    unitPriceAndCostToUpdate.AccountingResponse__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                    
                } else {
                    XeroBaseInvoiceDTO invoiceObj = (XeroBaseInvoiceDTO)obj;
                    unitPriceAndCostToUpdate.Id = invoiceObj.SFId;
                    if(syncingObjectName == 'Invoices') {
                        unitPriceAndCostToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
                        unitPriceAndCostToUpdate.AccountingResponse__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
                    } else if(syncingObjectName == 'CreditNotes') {
                        unitPriceAndCostToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.CreditNotes[0].CreditNoteID;
                        unitPriceAndCostToUpdate.AccountingResponse__c = (xeroResponseWrapper.CreditNotes[0] + '').abbreviate(32768);
                    }
                }
                
                unitPriceAndCostToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(unitPriceAndCostToUpdate);
            }
        }
    }
    
    private void handleVendorReceivingResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Vendor_Receiving_Header__c vendorReceivingHeaderToUpdate = new Vendor_Receiving_Header__c();
                vendorReceivingHeaderToUpdate.Id = reqJournalEntryObj.SFId;
                vendorReceivingHeaderToUpdate.Available_For_Xero_Sync__c = false;
                vendorReceivingHeaderToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                vendorReceivingHeaderToUpdate.AccountingResponseForJournalEntry__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                vendorReceivingHeaderToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(vendorReceivingHeaderToUpdate);
            }
        }
    } 
    
    private void handleStockUnitCategoryResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Customer_Owned_Unit__c stockUnitToUpdate = new Customer_Owned_Unit__c();
                stockUnitToUpdate.Id = reqJournalEntryObj.SFId;
                stockUnitToUpdate.Available_For_Xero_JE_Sync__c = false;
                stockUnitToUpdate.Xero_JE_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                stockUnitToUpdate.Accounting_Response_Category__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                stockUnitToUpdate.Accounting_Last_Sync_Time_Category__c = system.now();
                sobjListToSync.add(stockUnitToUpdate);
            }
        }
    }
    
    private void handleCOInvoiceResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        String syncingObjectName;
        if(xeroResponseWrapper.Invoices != null && !xeroResponseWrapper.Invoices.isEmpty()) {
            syncingObjectName = 'Invoices';
        } else if(xeroResponseWrapper.CreditNotes != null && !xeroResponseWrapper.CreditNotes.isEmpty()) {
            syncingObjectName = 'CreditNotes';
        }
        if(String.isNotBlank(syncingObjectName)) {
            for(Object obj: payload.get(syncingObjectName)) { // assuming there is a single request and response object
                XeroBaseInvoiceDTO reqCOInvoiceObj = (XeroBaseInvoiceDTO)obj;
                CO_Invoice_Header__c coInvoiceToUpdate = new CO_Invoice_Header__c();
                coInvoiceToUpdate.Id = reqCOInvoiceObj.SFId;
                coInvoiceToUpdate.Available_For_Xero_Sync__c = false;
                if(syncingObjectName == 'Invoices') {
                    coInvoiceToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
                    coInvoiceToUpdate.AccountingResponse__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
                } else if(syncingObjectName == 'CreditNotes') {
                    coInvoiceToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.CreditNotes[0].CreditNoteID;
                    coInvoiceToUpdate.AccountingResponse__c = (xeroResponseWrapper.CreditNotes[0] + '').abbreviate(32768);
                }
                coInvoiceToUpdate.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(coInvoiceToUpdate);
            }
        }
    }
    
    private void handleVOInvoiceResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if (payload.containsKey('Invoices')) {
            for(Object obj: payload.get('Invoices')) {
                XeroInvoiceDTO reqVOInvoiceObj = (XeroInvoiceDTO)obj;
                Vendor_Invoicing_Header__c voInvoiceRec = new Vendor_Invoicing_Header__c(Id = reqVOInvoiceObj.SFId);
                voInvoiceRec.Available_For_Xero_Sync__c = false;
                voInvoiceRec.Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
                voInvoiceRec.AccountingResponse__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
                voInvoiceRec.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(voInvoiceRec);
            }
        } else if (payload.containsKey('CreditNotes')) {
            for(Object obj: payload.get('CreditNotes')) {
                XeroCreditNoteDTO reqVOInvoiceObj = (XeroCreditNoteDTO)obj;
                Vendor_Invoicing_Header__c voCreditNoteRec = new Vendor_Invoicing_Header__c(Id = reqVOInvoiceObj.SFId);
                voCreditNoteRec.Available_For_Xero_Sync__c = false;
                voCreditNoteRec.Xero_Accounting_Id__c = xeroResponseWrapper.CreditNotes[0].CreditNoteID;
                voCreditNoteRec.AccountingResponse__c = (xeroResponseWrapper.CreditNotes[0] + '').abbreviate(32768);
                voCreditNoteRec.accountingLastSyncTime__c = system.now();
                sobjListToSync.add(voCreditNoteRec);
            }
        }
    }

    private void handleVIVarianceJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Vendor_Invoicing_Header__c voInvoiceRec = new Vendor_Invoicing_Header__c(Id = reqJournalEntryObj.SFId);
                voInvoiceRec.Available_For_Xero_Variance_JE_Sync__c = false;
                voInvoiceRec.Xero_Variance_JE_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                voInvoiceRec.Accounting_Response_Variance_JE__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                voInvoiceRec.Accounting_Last_Sync_Time_Variance_JE__c = system.now();
                sobjListToSync.add(voInvoiceRec);
            }
        }
    }
    
    private void handleRVOVarianceJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Return_CR_Header__c voReturnToUpdate = new Return_CR_Header__c(Id = reqJournalEntryObj.SFId);
                voReturnToUpdate.Available_For_Xero_Variance_JE_Sync__c = false;
                voReturnToUpdate.Xero_Variance_JE_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                voReturnToUpdate.Accounting_Response_Variance_JE__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                voReturnToUpdate.Accounting_Last_Sync_Time_Variance_JE__c = system.now();
                sobjListToSync.add(voReturnToUpdate);
            }
        }
    }
    
    private void handleInvoicePaymentResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.Payments != null && !xeroResponseWrapper.Payments.isEmpty()) {
            Map<String, sObject> invoiceSFIdToRecMap = new Map<String, sObject>();
            for(sObject sObjRec: sobjListToSync) {
                invoiceSFIdToRecMap.put(sObjRec.Id, sObjRec);
            }
            for(Object obj: payload.get('Payments')) { // assuming there is a single request and response object
                XeroInvoicePaymentDTO reqPaymentObj = (XeroInvoicePaymentDTO)obj;
                CO_Invoice_Header__c coInvoiceToUpdate = (invoiceSFIdToRecMap.containsKey(reqPaymentObj.SFId) ? ((CO_Invoice_Header__c)invoiceSFIdToRecMap.get(reqPaymentObj.SFId)) : 
                                                            new CO_Invoice_Header__c(Id = reqPaymentObj.SFId));
                coInvoiceToUpdate.Available_For_Xero_Invoice_Payment_Sync__c = false;
                coInvoiceToUpdate.Xero_CO_Invoice_Payment_Accounting_Id__c = xeroResponseWrapper.Payments[0].PaymentID;
                coInvoiceToUpdate.AccountingResponseForCOInvoicePayment__c = (xeroResponseWrapper.Payments[0] + '').abbreviate(32768);
                coInvoiceToUpdate.accountingLastSyncTimeForCOInvPayment__c = system.now();
                if(!invoiceSFIdToRecMap.containsKey(reqPaymentObj.SFId)) sobjListToSync.add(coInvoiceToUpdate);
            }
        }
    }
    
    private void handleARPaymentResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
    	
        Map<String, XeroInvoicePaymentDTO> invoiceIdToPaymentResponseMap = new Map<String, XeroInvoicePaymentDTO>();
        for(XeroInvoicePaymentDTO xeroObj : xeroResponseWrapper.Payments) {
            if(xeroObj.Invoice != null) {
                invoiceIdToPaymentResponseMap.put(xeroObj.Invoice.InvoiceId, xeroObj);
            } else if(xeroObj.CreditNote != null) {
                invoiceIdToPaymentResponseMap.put(xeroObj.CreditNote.CreditNoteID, xeroObj);
            } else if(xeroObj.Overpayment != null) {
                invoiceIdToPaymentResponseMap.put(xeroObj.Overpayment.OverpaymentID, xeroObj);
            } else if(xeroObj.Prepayment != null) {
                invoiceIdToPaymentResponseMap.put(xeroObj.Prepayment.PrepaymentID, xeroObj);
            }
        }
        
        if(xeroResponseWrapper.Payments != null && !xeroResponseWrapper.Payments.isEmpty()) {
            for(Object obj: payload.get('Payments')) { 
                XeroInvoicePaymentDTO reqARPaymentObj = (XeroInvoicePaymentDTO)obj;
                AR_Payment__c arPaymentToUpdate = new AR_Payment__c();
                arPaymentToUpdate.Id = reqARPaymentObj.SFId;
                arPaymentToUpdate.Available_For_Xero_Sync__c = false;
                if(reqARPaymentObj.Invoice != null) {
                    arPaymentToUpdate.Xero_Accounting_Id__c = invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Invoice.InvoiceId).PaymentID;
                    arPaymentToUpdate.Accounting_Response__c = (invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Invoice.InvoiceId) + '').abbreviate(32768);
                } else if(reqARPaymentObj.CreditNote != null) {
                    arPaymentToUpdate.Xero_Accounting_Id__c = invoiceIdToPaymentResponseMap.get(reqARPaymentObj.CreditNote.CreditNoteID).PaymentID;
                    arPaymentToUpdate.Accounting_Response__c = (invoiceIdToPaymentResponseMap.get(reqARPaymentObj.CreditNote.CreditNoteID) + '').abbreviate(32768);
                } else if(reqARPaymentObj.Overpayment != null) {
                    arPaymentToUpdate.Xero_Accounting_Id__c = invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Overpayment.OverpaymentID).PaymentID;
                    arPaymentToUpdate.Accounting_Response__c = (invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Overpayment.OverpaymentID) + '').abbreviate(32768);
                } else if(reqARPaymentObj.Prepayment != null) {
                    arPaymentToUpdate.Xero_Accounting_Id__c = invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Prepayment.PrepaymentID).PaymentID;
                    arPaymentToUpdate.Accounting_Response__c = (invoiceIdToPaymentResponseMap.get(reqARPaymentObj.Prepayment.PrepaymentID) + '').abbreviate(32768);
                }
                arPaymentToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(arPaymentToUpdate);
            }
        }
    }
    
    private void handlePaymentOnAccountResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Payment_On_Account__c paymentOnAccountRecordToUpdate = new Payment_On_Account__c();
                paymentOnAccountRecordToUpdate.Id = reqJournalEntryObj.SFId;
                paymentOnAccountRecordToUpdate.Available_For_Xero_Sync__c = false;
                paymentOnAccountRecordToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                paymentOnAccountRecordToUpdate.Accounting_Response__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                paymentOnAccountRecordToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(paymentOnAccountRecordToUpdate);
            }
        }
    }
    
    private void handleLienPayoutResponse(XeroResponseWrapper xeroResponseWrapper,Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        for(Object obj: payload.get('Invoices')) { 
            XeroLienPayoutDTO reqLienPayoutObj = (XeroLienPayoutDTO)obj;
            Deal_Item__c dealItemRec = new Deal_Item__c(Id = reqLienPayoutObj.SFId);
            dealItemRec.Lien_Payout_Avail_For_Xero_Sync__c = false;
            dealItemRec.Lien_Payout_Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
            dealItemRec.Lien_Payout_Accounting_Response__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
            dealItemRec.Lien_Payout_Accounting_Last_Sync_Time__c = system.now();
            sobjListToSync.add(dealItemRec);
        }
    }
    
    private void handleStockTradeInResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                Deal_Item__c dealItemToUpdate = new Deal_Item__c();
                dealItemToUpdate.Id = reqJournalEntryObj.SFId;
                dealItemToUpdate.Available_For_Xero_Sync__c = false;
                dealItemToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                dealItemToUpdate.Accounting_Response__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                dealItemToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(dealItemToUpdate);
            }
        }
    }
    
    private void handleCOInvoiceJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty()) {
            for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
                XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                CO_Invoice_Header__c coInvoiceHeaderToUpdate = new CO_Invoice_Header__c();
                coInvoiceHeaderToUpdate.Id = reqJournalEntryObj.SFId;
                coInvoiceHeaderToUpdate.Available_For_Xero_CO_Invoice_JE_Sync__c = false;
                coInvoiceHeaderToUpdate.Xero_CO_Invoice_JE_Accounting_Id__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                coInvoiceHeaderToUpdate.AccountingResponseForJournalEntry__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
                coInvoiceHeaderToUpdate.accountingLastSyncTimeForJE__c = system.now();
                //system.assert(false, dealItemToUpdate);
                sobjListToSync.add(coInvoiceHeaderToUpdate);
            }
        }
    }
    
    private void handleVOReturnResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        String syncingObjectName;
        if(xeroResponseWrapper.Invoices != null && !xeroResponseWrapper.Invoices.isEmpty()) {
            syncingObjectName = 'Invoices';
        } else if(xeroResponseWrapper.CreditNotes != null && !xeroResponseWrapper.CreditNotes.isEmpty()) {
            syncingObjectName = 'CreditNotes';
        }
        if(String.isNotBlank(syncingObjectName)){ 
            for(Object obj: payload.get(syncingObjectName)) {
                XeroBaseInvoiceDTO reqVOReturnObj = (XeroBaseInvoiceDTO)obj;
            
                Return_CR_Header__c voReturnToUpdate = new Return_CR_Header__c();
                voReturnToUpdate.Id = reqVOReturnObj.SFId;
                voReturnToUpdate.Available_For_Xero_Sync__c = false;
                if(syncingObjectName == 'Invoices') {
                    voReturnToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
                    voReturnToUpdate.Accounting_Response__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
                } else if(syncingObjectName == 'CreditNotes') {
                    voReturnToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.CreditNotes[0].CreditNoteID;
                    voReturnToUpdate.Accounting_Response__c = (xeroResponseWrapper.CreditNotes[0] + '').abbreviate(32768);
                }
                voReturnToUpdate.Accounting_Last_Sync_Time__c = system.now();
                sobjListToSync.add(voReturnToUpdate);
            }
        }
    }
    
    private void handleUnitInvoiceResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        for(Object obj: payload.get('Invoices')) { // assuming there is a single request and response object
            XeroBaseInvoiceDTO reqUnitInvoiceObj = (XeroBaseInvoiceDTO)obj;
            
            Customer_Owned_Unit__c unitToUpdate = new Customer_Owned_Unit__c();
            unitToUpdate.Id = reqUnitInvoiceObj.SFId;
            unitToUpdate.Available_For_Xero_Sync__c = false;
            unitToUpdate.Xero_Accounting_Id__c = xeroResponseWrapper.Invoices[0].InvoiceID;
            unitToUpdate.AccountingResponse__c = (xeroResponseWrapper.Invoices[0] + '').abbreviate(32768);
            unitToUpdate.accountingLastSyncTime__c = system.now();
            sobjListToSync.add(unitToUpdate);
        }
    }
    
    private void handleUnitInvoiceJEResponse(XeroResponseWrapper xeroResponseWrapper, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        
        for(Object obj: payload.get('ManualJournals')) { // assuming there is a single request and response object
            XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
            Customer_Owned_Unit__c stockUnitToUpdate = new Customer_Owned_Unit__c();
            stockUnitToUpdate.Id = reqJournalEntryObj.SFId;
            stockUnitToUpdate.Available_For_Xero_Unit_Invoice_JE_Sync__c = false;
            stockUnitToUpdate.Xero_Accounting_Id_Unit_Invoice_JE__c = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
            stockUnitToUpdate.Accounting_Response_Unit_Invoice_JE__c = (xeroResponseWrapper.ManualJournals[0] + '').abbreviate(32768);
            stockUnitToUpdate.Accounting_Last_Sync_Time_Unit_JE__c = system.now();
            sobjListToSync.add(stockUnitToUpdate);
        }
    }
    
    private void syncCOInvoicePayment(List<Object> syncObjList, List<sObject> sobjListToSync, 
    									String entityType, String coInvXeroAccountingId) {
        AccountingCustomerInvoice customerInvoiceRec = (AccountingCustomerInvoice)syncObjList[0];
        if(String.isBlank(customerInvoiceRec.AccountingCOInvoiceHeaderRec.XeroAccountingId) && String.isNotBlank(coInvXeroAccountingId)) {
        	customerInvoiceRec.AccountingCOInvoiceHeaderRec.XeroAccountingId = coInvXeroAccountingId;
        }
        if(customerInvoiceRec.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount != 0) {
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{entityType => IntegrationUtility.CREATE_ACTION};
        	sync(syncObjList, sobjListToSync, entityType, integrationEntityNameToActionMap);
        }
    }
    
    public static String getContactsXeroId(String whereClause, IFW_IntegrationConfig__c integrationConfigRec) {
        List<XeroContactDTO> contactListFromXero = getContactsFromXero(whereClause, integrationConfigRec);
        List<String> contactsXeroIdList = new List<String>();
        for(XeroContactDTO xeroContactRec : contactListFromXero) {
            contactsXeroIdList.add(xeroContactRec.ContactID);
        }
        return (contactsXeroIdList.size() > 0 ? contactsXeroIdList[0] : null);
    }
    
    public static List<XeroContactDTO> getContactsFromXero(String whereClause, IFW_IntegrationConfig__c integrationConfigRec) {
        List<XeroContactDTO> contactListFromXero = new List<XeroContactDTO>();
        XeroResponseWrapper responseWrapper = getDataFromXero('Contacts', whereClause, integrationConfigRec);
        if(responseWrapper != null && responseWrapper.Contacts != null && responseWrapper.Contacts.size() > 0) {
            contactListFromXero = responseWrapper.Contacts;
        }
        return contactListFromXero;
    }
    
    public static XeroResponseWrapper getDataFromXero(String entityName, String whereClause, IFW_IntegrationConfig__c integrationConfigRec) {
        return getDataFromXero(entityName, whereClause, integrationConfigRec, null);
    }

    public static XeroResponseWrapper getDataFromXero(String entityName, String whereClause, IFW_IntegrationConfig__c integrationConfigRec, Map<String, String> urlParamMap) {
        XeroResponseWrapper responseWrapper;
        List<IFW_IntegrationConfigItem__c> configItemList =
                IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                              'Entity_Name__c' => entityName,'HTTP_Method__c' => 'GET'});
        if(urlParamMap == null) {
            urlParamMap = new Map<String, String>{'where' => EncodingUtil.urlEncode(whereClause,'UTF-8')};
        }
        if(configItemList.size() > 0) {
            HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, configItemList[0], null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                responseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
            }
        }
        return responseWrapper;
    }
    
    /*public void handleGETResponseFromXero(String entityName, String whereClause, Map<String, List<Object>> payload, List<sObject> sobjListToSync) {
        //List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
        //if(integrationConfigList.size() > 0) {
            String configItemEntityName = (XeroUtility.commonEntityNameToEntityNameMap.get(IntegrationUtility.JOURNAL_ENTRY).contains(entityName)? IntegrationUtility.JOURNAL_ENTRY : entityName);
            List<IFW_IntegrationConfigItem__c> configItemList =
                    IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                                  'Entity_Name__c' => configItemEntityName,'HTTP_Method__c' => 'GET'});
            Map<String, String> urlParamMap = new Map<String, String>{'where' => EncodingUtil.urlEncode(whereClause,'UTF-8')};
            
            if(configItemList.size() > 0) {
                //GET Call
                HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, configItemList[0], null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
                system.debug('RESPONSE FROM GET ' + response);
                
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                	XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper) System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
       				system.debug('XeroResponseWrapper from GET' + xeroResponseWrapper);
       				
       				//FOR JE
                	if(xeroResponseWrapper.ManualJournals != null && !xeroResponseWrapper.ManualJournals.isEmpty() && 
                	XeroUtility.commonEntityNameToEntityNameMap.get(IntegrationUtility.JOURNAL_ENTRY).contains(entityName)) {
                        if ( entityName == IntegrationUtility.CO_INVOICE_JE && isSendRequestRequiredForPOST) {                          
                            if(payload.containsKey('ManualJournals')) {
                                for(Object obj: payload.get('ManualJournals')) {
                                    XeroJournalEntryDTO reqJournalEntryObj = (XeroJournalEntryDTO)obj;
                                    reqJournalEntryObj.ManualJournalID = xeroResponseWrapper.ManualJournals[0].ManualJournalID;
                                }   
                            }
                            String requestBody = System.JSON.serialize(payload, true);
                            if(requestBody != null) {
                                requestBody = requestBody.replace('"JournalDate":', '"Date":');
                                requestBody = requestBody.replace('"InvDate":', '"Date":');
                            }
                            configItemList[0].HTTP_Method__c = 'POST';
                            performCalloutandHandleResponse(configItemList[0], requestBody, entityName, payload, sobjListToSync); 
                        } else  {
                            handleResponse(response, payload, sobjListToSync, entityName);
                        }
                	} else if(xeroResponseWrapper.Payments != null && !xeroResponseWrapper.Payments.isEmpty() && entityName == IntegrationUtility.INVOICE_PAYMENT) { 
                		handleResponse(response, payload, sobjListToSync, entityName);
                	} else {
                		String requestBody = System.JSON.serialize(payload, true);
			            if(requestBody != null) {
			                requestBody = requestBody.replace('"JournalDate":', '"Date":');
			                requestBody = requestBody.replace('"InvDate":', '"Date":');
			            }
			            system.debug('Config ITem' + configItemList[0]);
			            configItemList[0].HTTP_Method__c = 'POST';
                		performCalloutandHandleResponse(configItemList[0], requestBody, entityName, payload, sobjListToSync); 
                	}
                } else {
                    throw new BlackpurlException('There is some error fetching JE details from xero.');
                }
            }
        //}
    }*/
    
    private static void setVendorInvoiceDueDate(AccountingVendorInvoice vendorInvoiceObj, IFW_IntegrationConfig__c integrationConfigRec) {
        vendorInvoiceObj.AccountingVIHeaderRec.DueDate = setBillDueDateFromContact(vendorInvoiceObj.vendor.XeroVendorAccountingId, vendorInvoiceObj.AccountingVIHeaderRec.InvoiceDate, integrationConfigRec);
        if(vendorInvoiceObj.AccountingVIHeaderRec.DueDate == null) {
            vendorInvoiceObj.AccountingVIHeaderRec.DueDate = setBillDueDateFromOrg(vendorInvoiceObj.AccountingVIHeaderRec.InvoiceDate, integrationConfigRec);
            if(vendorInvoiceObj.AccountingVIHeaderRec.DueDate == null) {
                vendorInvoiceObj.AccountingVIHeaderRec.DueDate = setBillDefaultDueDate(vendorInvoiceObj.AccountingVIHeaderRec.InvoiceDate);
            }
        }
    }
    
    private static void setUnitInvoiceDueDate(AccountingUnit unitInvoiceObj, IFW_IntegrationConfig__c integrationConfigRec) {
        unitInvoiceObj.DueDate = setBillDueDateFromContact(unitInvoiceObj.XeroVendorAccountingId, unitInvoiceObj.CreatedDate, integrationConfigRec);
        if(unitInvoiceObj.DueDate == null) {
            unitInvoiceObj.DueDate = setBillDueDateFromOrg(unitInvoiceObj.CreatedDate, integrationConfigRec);
            if(unitInvoiceObj.DueDate == null) {
                unitInvoiceObj.DueDate = setBillDefaultDueDate(unitInvoiceObj.CreatedDate);
            }
        }
    }

    private static void setUnitPriceAndCostDueDate(AccountingUnitPriceAndCost unitPriceCostObj, IFW_IntegrationConfig__c integrationConfigRec) {
        if(String.isNotBlank(unitPriceCostObj.VendorId)) {
            unitPriceCostObj.DueDate = setBillDueDateFromContact(unitPriceCostObj.VendorAccountingId, unitPriceCostObj.AdjustmentDate, integrationConfigRec);
        } else if(String.isNotBlank(unitPriceCostObj.CustomerId)) {
            unitPriceCostObj.DueDate = setBillDueDateFromContact(unitPriceCostObj.CustomerAccountingId, unitPriceCostObj.AdjustmentDate, integrationConfigRec);
        }
        if(unitPriceCostObj.DueDate == null) {
            unitPriceCostObj.DueDate = setBillDueDateFromOrg(unitPriceCostObj.AdjustmentDate, integrationConfigRec);
            if(unitPriceCostObj.DueDate == null) {
                unitPriceCostObj.DueDate = setBillDefaultDueDate(unitPriceCostObj.AdjustmentDate);
            }
        }
    }

    private static void setVOReturnDueDate(AccountingVendorReturn vendorReturnObj, IFW_IntegrationConfig__c integrationConfigRec) {
        vendorReturnObj.DueDate = setBillDueDateFromContact(vendorReturnObj.XeroVendorAccountingId, vendorReturnObj.CreditedDate, integrationConfigRec);

        if(vendorReturnObj.DueDate == null) {
            vendorReturnObj.DueDate = setBillDueDateFromOrg(vendorReturnObj.CreditedDate, integrationConfigRec);
            if(vendorReturnObj.DueDate == null) {
                vendorReturnObj.DueDate = setBillDefaultDueDate(vendorReturnObj.CreditedDate);
            }
        }
    }

    private static void setLienPayoutDueDate(AccountingLienPayout accountingLienPayoutObj, IFW_IntegrationConfig__c integrationConfigRec) {
        accountingLienPayoutObj.DueDate = setBillDueDateFromContact(accountingLienPayoutObj.FinanceCompany.AccountingId, accountingLienPayoutObj.InvoiceDate, integrationConfigRec);
        if(accountingLienPayoutObj.DueDate == null) {
            accountingLienPayoutObj.DueDate = setBillDueDateFromOrg(accountingLienPayoutObj.InvoiceDate, integrationConfigRec);
            if(accountingLienPayoutObj.DueDate == null) {
                accountingLienPayoutObj.DueDate = setBillDefaultDueDate(accountingLienPayoutObj.InvoiceDate);
            }
        }
    }

    private static void setCustomerInvoiceDueDate(AccountingCustomerInvoice customerInvoiceObj, IFW_IntegrationConfig__c integrationConfigRec) {
        customerInvoiceObj.AccountingCOInvoiceHeaderRec.DueDate = setCOInvoiceDueDateFromContact(customerInvoiceObj.AccountingCOInvoiceHeaderRec.XeroCustomerAccountingId, customerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceDate, integrationConfigRec);
        if(customerInvoiceObj.AccountingCOInvoiceHeaderRec.DueDate == null) {
            customerInvoiceObj.AccountingCOInvoiceHeaderRec.DueDate = setCOInvoiceDueDateFromOrg(customerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceDate, integrationConfigRec);
            if(customerInvoiceObj.AccountingCOInvoiceHeaderRec.DueDate == null) {
                customerInvoiceObj.AccountingCOInvoiceHeaderRec.DueDate = setBillDefaultDueDate(customerInvoiceObj.AccountingCOInvoiceHeaderRec.InvoiceDate);
            }
        }
    }
    
    private static Date setBillDueDateFromContact(String vendorAccountingId, Date invoiceDate, IFW_IntegrationConfig__c integrationConfigRec) {
        if(String.isBlank(vendorAccountingId)) throw new BlackpurlException('Vendor is not synced to xero.');
        
        List<IFW_IntegrationConfigItem__c> contactConfigItemList =IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                                 'Entity_Name__c' => IntegrationUtility.CONTACTS, 'HTTP_Method__c' => 'GET'});
        
        if(contactConfigItemList.size() == 0) throw new BlackpurlException('Config item to get contact is not defined.');
        if(contactConfigItemList.size() > 0 && String.isNotBlank(vendorAccountingId)) {
            contactConfigItemList[0].Endpoint_URL__c += '/' + vendorAccountingId;
            HttpResponse contactResponse = BaseIntegration.performCallout(integrationConfigRec, contactConfigItemList[0], null, new List<customHttpHeaderWrapper>(), IntegrationUtility.VENDOR);
            if(contactResponse.getStatusCode() == 200) {
                XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(contactResponse.getBody(), XeroResponseWrapper.class);
                if(xeroResponseWrapper.Contacts != null && !xeroResponseWrapper.Contacts.isEmpty() 
                    && xeroResponseWrapper.Contacts[0].PaymentTerms != null && xeroResponseWrapper.Contacts[0].PaymentTerms.Bills != null) {
                    return XeroUtility.getDueDate(invoiceDate, xeroResponseWrapper.Contacts[0].PaymentTerms.Bills.Type, xeroResponseWrapper.Contacts[0].PaymentTerms.Bills.Day);
                }
            } else {
                throw new BlackpurlException('There is some error fetching vendor details from xero: ' + contactResponse.getBody());
            }
        }
        return null;
    }

    private static Date setCOInvoiceDueDateFromContact(String customerAccountingId, Date invoiceDate, IFW_IntegrationConfig__c integrationConfigRec) {
        if(String.isBlank(customerAccountingId)) throw new BlackpurlException('Customer is not synced to xero.');
        
        List<IFW_IntegrationConfigItem__c> contactConfigItemList =IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                                 'Entity_Name__c' => IntegrationUtility.CONTACTS, 'HTTP_Method__c' => 'GET'});
        
        if(contactConfigItemList.size() == 0) throw new BlackpurlException('Config item to get contact is not defined.');
        if(contactConfigItemList.size() > 0 && String.isNotBlank(customerAccountingId)) {
            contactConfigItemList[0].Endpoint_URL__c += '/' + customerAccountingId;
            HttpResponse contactResponse = BaseIntegration.performCallout(integrationConfigRec, contactConfigItemList[0], null, new List<customHttpHeaderWrapper>(), IntegrationUtility.VENDOR);
            if(contactResponse.getStatusCode() == 200) {
                XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(contactResponse.getBody(), XeroResponseWrapper.class);
                if(xeroResponseWrapper.Contacts != null && !xeroResponseWrapper.Contacts.isEmpty() 
                    && xeroResponseWrapper.Contacts[0].PaymentTerms != null && xeroResponseWrapper.Contacts[0].PaymentTerms.Sales != null) {
                    return XeroUtility.getDueDate(invoiceDate, xeroResponseWrapper.Contacts[0].PaymentTerms.Sales.Type, xeroResponseWrapper.Contacts[0].PaymentTerms.Sales.Day);
                }
            } else {
                throw new BlackpurlException('There is some error fetching customer details from xero: ' + contactResponse.getBody());
            }
        }
        return null;
    }
    
    private static Date setBillDueDateFromOrg(Date invoiceDate, IFW_IntegrationConfig__c integrationConfigRec) {
        List<IFW_IntegrationConfigItem__c> orgConfigItemList =IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                                 'Entity_Name__c' => IntegrationUtility.ORGANISATION, 'HTTP_Method__c' => 'GET'});
        
        if(orgConfigItemList.size() == 0) throw new BlackpurlException('Config item to get organization is not defined.');
        
        
        if(orgConfigItemList.size() > 0) {
            HttpResponse orgResponse = BaseIntegration.performCallout(integrationConfigRec, orgConfigItemList[0], null, new List<customHttpHeaderWrapper>(), IntegrationUtility.ORGANISATION);
            if(orgResponse.getStatusCode() == 200) {
                XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(orgResponse.getBody(), XeroResponseWrapper.class);
                if(xeroResponseWrapper.Organisations != null && !xeroResponseWrapper.Organisations.isEmpty() 
                    && xeroResponseWrapper.Organisations[0].PaymentTerms != null && xeroResponseWrapper.Organisations[0].PaymentTerms.Bills != null) {
                    return XeroUtility.getDueDate(invoiceDate, xeroResponseWrapper.Organisations[0].PaymentTerms.Bills.Type, xeroResponseWrapper.Organisations[0].PaymentTerms.Bills.Day);
                }
            } else {
                throw new BlackpurlException('There is some error fetching organization details from xero: ' + orgResponse.getBody());
            }
        }
        return null;
    }

    private static Date setCOInvoiceDueDateFromOrg(Date invoiceDate, IFW_IntegrationConfig__c integrationConfigRec) {
        List<IFW_IntegrationConfigItem__c> orgConfigItemList =IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, Object>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id,
                                                                 'Entity_Name__c' => IntegrationUtility.ORGANISATION, 'HTTP_Method__c' => 'GET'});
        
        if(orgConfigItemList.size() == 0) throw new BlackpurlException('Config item to get organization is not defined.');
        
        
        if(orgConfigItemList.size() > 0) {
            HttpResponse orgResponse = BaseIntegration.performCallout(integrationConfigRec, orgConfigItemList[0], null, new List<customHttpHeaderWrapper>(), IntegrationUtility.ORGANISATION);
            if(orgResponse.getStatusCode() == 200) {
                XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(orgResponse.getBody(), XeroResponseWrapper.class);
                if(xeroResponseWrapper.Organisations != null && !xeroResponseWrapper.Organisations.isEmpty() 
                    && xeroResponseWrapper.Organisations[0].PaymentTerms != null && xeroResponseWrapper.Organisations[0].PaymentTerms.Sales != null) {
                    return XeroUtility.getDueDate(invoiceDate, xeroResponseWrapper.Organisations[0].PaymentTerms.Sales.Type, xeroResponseWrapper.Organisations[0].PaymentTerms.Sales.Day);
                }
            } else {
                throw new BlackpurlException('There is some error fetching organization details from xero: ' + orgResponse.getBody());
            }
        }
        return null;
    }
    
    private static Date setBillDefaultDueDate(Date invoiceDate) {
        return invoiceDate;
    }
    
    public static void deleteEntity(BaseIntegrationService integrationRec, String accountingId, String entityName) {
    	if(integrationRec != null && String.isNotBlank(accountingId) && String.isNotBlank(entityName)) {
    		
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{entityName => IntegrationUtility.DELETE_ACTION};
	    	List<IFW_IntegrationConfigItem__c> integrationConfigItemList = 
	    					integrationRec.getIntegrationConfigItemByFieldValues(integrationRec.integrationConfigRec.Id, integrationEntityNameToActionMap);
	    	if(integrationConfigItemList.size() == 0) throw new BlackpurlException('Endpoint configuration missing for delete action related to ' + entityName);
	    																	
    		String requestBody;
	    	if(entityName == IntegrationUtility.INVOICE_PAYMENT) {
	    		integrationConfigItemList[0].Endpoint_URL__c += '/' + accountingId;
	    		requestBody = '{"Status": "DELETED"}';
	    		
	    	} else if(entityName == IntegrationUtility.INVOICE) {
	    		requestBody = '{"InvoiceID": "' + accountingId + '", "Status":"VOIDED"}';
	    		
	    	} else if(entityName == IntegrationUtility.CREDIT_NOTE) {
	    		requestBody = '{"CreditNoteID": "' + accountingId + '", "Status":"VOIDED"}';
	    		
	    	} else if(entityName == IntegrationUtility.JOURNAL_ENTRY) {
	    		requestBody = '{"ManualJournalID": "' + accountingId + '","Status": "VOIDED"}';
	    	} 
	    	
	    	if(String.isNotBlank(requestBody)) {
				HttpResponse response = BaseIntegration.performCallout(integrationRec.integrationConfigRec, 
													integrationConfigItemList[0], requestBody, new List<customHttpHeaderWrapper>(), entityName);
	    		system.debug('::entityName:: ' + entityName + ' &&&& ::accountingId:: ' + accountingId);
	    		system.debug('::Response Code:: ' + response.getStatusCode());
	    		system.debug('::Response Body:: ' + response.getBody());
                if(response.getStatusCode() != 200 && response.getStatusCode() != 201) { 
                    throw new BlackPurlException(response.getBody() + '\n' + entityName + '\n' + requestBody);
                }
	    	}
    	}
    }

    public static List<XeroInvoiceDTO> getUnpaidInvoicesFromXero(IFW_IntegrationConfig__c integrationConfigRec, Set<String> invoiceAccountingIdSet) {
        List<XeroInvoiceDTO> invoiceList = new List<XeroInvoiceDTO>();
        String idString = '';
        if(invoiceAccountingIdSet != null && !invoiceAccountingIdSet.isEmpty()) {
            for(String idStr : invoiceAccountingIdSet) {
                idString += idStr + ',';
            }
            idString = idString.removeEnd(',');
        } 

        XeroResponseWrapper responseWrapper = XeroService.getDataFromXero('Invoice', null, integrationConfigRec, new Map<String, String>{'IDs' => idString});
        if(responseWrapper != null) {
            invoiceList = responseWrapper.Invoices;
        }
        return invoiceList;
   	}

   	public static List<XeroCreditNoteDTO> getUnappliedCreditsFromXero(IFW_IntegrationConfig__c integrationConfigRec, Set<String> creditsAccountingIdSet) {
        List<XeroCreditNoteDTO> xeroCreditNotesList = new List<XeroCreditNoteDTO>();
        String whereClause = '';
        if(creditsAccountingIdSet != null && !creditsAccountingIdSet.isEmpty()) {
            for(String idStr : creditsAccountingIdSet) {
                if(String.isNotBlank(whereClause)) whereClause += ' OR ';
                whereClause += 'ID=Guid("' + idStr + '")';
            }
        } 

        XeroResponseWrapper responseWrapper = XeroService.getDataFromXero('Credit Note', whereClause, integrationConfigRec, null);
        if(responseWrapper != null) {
            xeroCreditNotesList = responseWrapper.CreditNotes;
        }
        return xeroCreditNotesList;
   	}
}
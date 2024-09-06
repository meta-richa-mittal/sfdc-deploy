global without sharing class CustomerInvoiceService {
    
    public static String syncingObjectType = '';
    public static final Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static final String TAX_NOT_APPLICABLE = 'NotApplicable';
    public static Map<Id, List<F_I_Product__c>> dealIdToFIProductsMap = new Map<Id, List<F_I_Product__c>>();
    public static List<Log__c> errorLogToInsert;
    private static Set<Id> applicableSalesTaxSet = new Set<Id>();
    private static Boolean isNonTaxableLIExists = false;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
	public static Boolean updateCOInvoice = false;
    
    global static void syncCustomerInvoices(Set<Id> customerInvoiceIds) {
        AccSync_CustomerInvoice_Batch.runCustomerInvoicesForSync(customerInvoiceIds, 10);
    }
    
   public static QBUtil.BatchResultWrapper syncAccountingServer(List<AccountingCustomerInvoice> customerInvoiceRecordList, List<CO_Invoice_Header__c> customerInvoiceListToUpdate) {
        errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            syncToQuickBooks(customerInvoiceRecordList, customerInvoiceListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static void syncToQuickBooks(List<AccountingCustomerInvoice> customerInvoiceRecordList, List<CO_Invoice_Header__c> customerInvoiceListToUpdate) {
        if(customerInvoiceRecordList == null || customerInvoiceRecordList.size() == 0) {
            return;
        }
        if(customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.customer == null || customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.customer.AccountingId == null) {
            return;
        }
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c();
        coInvoiceHeader.Id = customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        Decimal invoiceTotal = customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.InvoiceTotal;
        Boolean isAnyLineItemAvailableTOPostToQB = true;
        try {
            if(customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.CheckoutType == 'Third-Party') {
              syncingObjectType = (invoiceTotal >= 0) ? QBUtil.INVOICE : QBUtil.CREDIT_MEMO;
            } else {
              syncingObjectType = getSyncingObjectName(invoiceTotal, customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.isChargeOnAccountPaymentMethod);
            }
            
            if(String.isNotBlank(customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.SyncToken)) {
                String updatedSyncToken = getUpdatedSyncToken(syncingObjectType, customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.AccountingId);
                customerInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.SyncToken = updatedSyncToken;
            }
            
            // Send request to create/update Invoice
            String customerInvoiceJSONBody = getInvoiceJSONString(syncingObjectType, customerInvoiceRecordList[0]);
            system.debug('== customerInvoiceJSONBody == ' + customerInvoiceJSONBody);
            if(String.isBlank(customerInvoiceJSONBody)) {
              isAnyLineItemAvailableTOPostToQB = false;
            }
            coInvoiceHeader = syncInvoiceToQB(customerInvoiceJSONBody, new List<CO_Invoice_Header__c>{coInvoiceHeader}, customerInvoiceRecordList[0]);
            system.debug('== coInvoiceHeader == ' + coInvoiceHeader);
            
        } catch(Exception e) {
            if(isAnyLineItemAvailableTOPostToQB) {
            coInvoiceHeader.availForQBSync__c = true;
              coInvoiceHeader.AccountingResponse__c = e.getMessage();
              errorLogToInsert.add(new LogService().createErrorLog('CustomerInvoiceService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              customerInvoiceRecordList[0] + LogService.METHOD_PARAM_SEPERATOR + customerInvoiceListToUpdate, LogService.QUICKBOOKS, false));
          } else {
            coInvoiceHeader.AccountingResponse__c = QBUtil.CO_INVOICE_NO_LI_MSG;
              coInvoiceHeader.availForQBSync__c = false;
          }
        }
        
        if(customerInvoiceListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            DMLUtility.updateSobjectListWithRetry(customerInvoiceListToUpdate);
            customerInvoiceListToUpdate = new List<CO_Invoice_Header__c>();
        }
        customerInvoiceListToUpdate.add(coInvoiceHeader); 
    }
    
    private static CO_Invoice_Header__c syncInvoiceToQB(String customerInvoiceJSONBody, List<CO_Invoice_Header__c> coInvoiceHeaderList, AccountingCustomerInvoice customerInvoiceRecord) {
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c();
        if(coInvoiceHeaderList.size() > 0) {
            coInvoiceHeader = coInvoiceHeaderList[0];
            if(String.isBlank(customerInvoiceJSONBody)) {
                coInvoiceHeader.AccountingResponse__c = QBUtil.CO_INVOICE_NO_LI_MSG;
                coInvoiceHeader.availForQBSync__c = false;
            } else {
                coInvoiceHeader = sendRequestToQBForCreateInvoice(new List<AccountingCustomerInvoice>{customerInvoiceRecord}, new List<CO_Invoice_Header__c>{coInvoiceHeader}, customerInvoiceJSONBody);
            }
        }
        return coInvoiceHeader;
    }
    
    private static CO_Invoice_Header__c sendRequestToQBForCreateInvoice(List<AccountingCustomerInvoice> customerInvoiceRecordList, List<CO_Invoice_Header__c> coInvoiceHeaderRecList,
                                                         String customerInvoiceJSONBody) {
         if(customerInvoiceRecordList == null  || coInvoiceHeaderRecList == null || customerInvoiceRecordList.size() == 0 || coInvoiceHeaderRecList.size() == 0) {
          return new CO_Invoice_Header__c();
        }  
         CO_Invoice_Header__c coInvoiceHeaderRec = coInvoiceHeaderRecList[0];
         AccountingCustomerInvoice customerInvoiceRecord = customerInvoiceRecordList[0];
         system.debug('updateCOInvoice \n\n' + updateCOInvoice);                                              
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.SyncToken == null || updateCOInvoice) {
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks(syncingObjectType, customerInvoiceJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB(syncingObjectType, customerInvoiceJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            system.debug('Response of Create Invoice \n\n' + res);
            
            if(res.getStatusCode() == 200) { 
                String invoiceResonseObj = res.getBody();
                if(syncingObjectType == QBUtil.SALES_RECEIPT) {
                    ResponseQuickBooksSalesReceipt customerInvoicePostResponse = (ResponseQuickBooksSalesReceipt)System.JSON.deserialize(invoiceResonseObj, ResponseQuickBooksSalesReceipt.class);
                    coInvoiceHeaderRec = setInvoiceData(new List<CO_Invoice_Header__c>{coInvoiceHeaderRec}, CustomerInvoicePostResponse.SalesReceipt.Id, customerInvoicePostResponse.SalesReceipt.SyncToken, false);
                } else if(syncingObjectType == QBUtil.REFUND_RECEIPT) {
                    ResponseQuickBooksRefundReceipt customerInvoicePostResponse = (ResponseQuickBooksRefundReceipt)System.JSON.deserialize(invoiceResonseObj, ResponseQuickBooksRefundReceipt.class);
                    coInvoiceHeaderRec = setInvoiceData(new List<CO_Invoice_Header__c>{coInvoiceHeaderRec}, CustomerInvoicePostResponse.RefundReceipt.Id, customerInvoicePostResponse.RefundReceipt.SyncToken, false);
                } else if(syncingObjectType == QBUtil.INVOICE) {
                    ResponseQuickBooksCustomerInvoice customerInvoicePostResponse = (ResponseQuickBooksCustomerInvoice)System.JSON.deserialize(invoiceResonseObj, ResponseQuickBooksCustomerInvoice.class);
                    coInvoiceHeaderRec = setInvoiceData(new List<CO_Invoice_Header__c>{coInvoiceHeaderRec}, CustomerInvoicePostResponse.Invoice.Id, customerInvoicePostResponse.Invoice.SyncToken, false);
                    customerInvoiceRecord.AccountingCOInvoiceHeaderRec.AccountingId = coInvoiceHeaderRec.AccountingId__c;
                    if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount > 0) {
                    	/* NOTE: As there is no more callout after COInvoicePaymentService service, refresh token is saved in COInvoicePaymentService service */
                      	coInvoiceHeaderRec = COInvoicePaymentService.syncAccountingServer(new List<AccountingCustomerInvoice> {customerInvoiceRecord}, coInvoiceHeaderRec);
                    }
                } else if(syncingObjectType == QBUtil.CREDIT_MEMO) {
                    ResponseQuickBooksCreditMemo customerInvoicePostResponse = (ResponseQuickBooksCreditMemo)System.JSON.deserialize(invoiceResonseObj, ResponseQuickBooksCreditMemo.class);
                    coInvoiceHeaderRec = setInvoiceData(new List<CO_Invoice_Header__c>{coInvoiceHeaderRec}, CustomerInvoicePostResponse.CreditMemo.Id, customerInvoicePostResponse.CreditMemo.SyncToken, false);
                }
            } else {
              errorLogToInsert.add(new LogService().createErrorLog('CustomerInvoiceService', 'sendRequestToQBForCreateInvoice() '+syncingObjectType, res.getBody(), res.getStatusCode(), null, 
                                              customerInvoiceRecord + LogService.METHOD_PARAM_SEPERATOR + coInvoiceHeaderRec + LogService.METHOD_PARAM_SEPERATOR + customerInvoiceJSONBody, LogService.QUICKBOOKS, false));
            }
            String response = customerInvoiceJSONBody + '\n\n\n' + res.getBody() + 
                                                        ((res.getStatusCode() != 200) ? ('\n\n'+ res.getStatus()) : '');
            coInvoiceHeaderRec.AccountingResponse__c = QBUtil.truncateString(response, 131072);
        } else {
            if(syncingObjectType == QBUtil.INVOICE && customerInvoiceRecord.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount > 0) {
            	/* NOTE: As there is no more callout after COInvoicePaymentService service, refresh token is saved in COInvoicePaymentService service */
                coInvoiceHeaderRec = COInvoicePaymentService.syncAccountingServer(new List<AccountingCustomerInvoice> {customerInvoiceRecord}, coInvoiceHeaderRec);
            } else {
                coInvoiceHeaderRec.availForQBSync__c = false;
                coInvoiceHeaderRec.accountingLastSyncTime__c = system.now(); 
            }
        }
        return coInvoiceHeaderRec;
    }
    
    private static CO_Invoice_Header__c setInvoiceData(List<CO_Invoice_Header__c> coInvoiceHeaderRecList, String accountingId, String syncToken, Boolean isAvailForQBSync) {
        if(coInvoiceHeaderRecList == null || coInvoiceHeaderRecList.size() == 0){
            return new CO_Invoice_Header__c();
        }
        coInvoiceHeaderRecList[0].AccountingId__c = accountingId;
        coInvoiceHeaderRecList[0].SyncToken__c = syncToken;
        if(isAvailForQBSync != null) {
            coInvoiceHeaderRecList[0].availForQBSync__c = isAvailForQBSync;
            coInvoiceHeaderRecList[0].accountingLastSyncTime__c = system.now(); 
        }
        return coInvoiceHeaderRecList[0];
    }
    
    private static String getInvoiceJSONString(String syncingObjectType, AccountingCustomerInvoice customerInvoiceRecord) {
        String customerInvoiceJSONBody = '';
        if(syncingObjectType == QBUtil.SALES_RECEIPT || syncingObjectType == QBUtil.REFUND_RECEIPT) {
            QuickBooksSalesOrRefundReceipt QCI = new QuickBooksSalesOrRefundReceipt(customerInvoiceRecord);
            if(QCI.line != null && QCI.line.size() == 0){
                return null;
            }
            customerInvoiceJSONBody = system.JSON.serialize(QCI);
        } else if(syncingObjectType == QBUtil.INVOICE || syncingObjectType == QBUtil.CREDIT_MEMO) {
            QuickBooksCustomerInvoiceOrCreditMemo QCI = new QuickBooksCustomerInvoiceOrCreditMemo(customerInvoiceRecord);
            if(QCI.line != null && QCI.line.size() == 0){
                return null;
            }
            customerInvoiceJSONBody = system.JSON.serialize(QCI);
        }
        return customerInvoiceJSONBody;
    }
    
    private static String getUpdatedSyncToken(String syncingObjectType, String invoiceAccId) {
        //HttpResponse invoiceObj = QuickbookConnector.getRequestFromQuickBooks(syncingObjectType, invoiceAccId);
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB(syncingObjectType, invoiceAccId);
		HttpResponse invoiceObj = responseObj.Response;
		refreshToken = responseObj.RefreshToken;
		refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        String updatedSyncToken;
        if(invoiceObj.getStatusCode() == 200) { 
            if(syncingObjectType == QBUtil.SALES_RECEIPT) {
                ResponseQuickBooksSalesReceipt customerInvoiceGetResponce = (ResponseQuickBooksSalesReceipt)System.JSON.deserialize(invoiceObj.getBody(), ResponseQuickBooksSalesReceipt.class);
                updatedSyncToken = customerInvoiceGetResponce.SalesReceipt.SyncToken;
            } else if(syncingObjectType == QBUtil.REFUND_RECEIPT) {
                ResponseQuickBooksRefundReceipt customerInvoiceGetResponce = (ResponseQuickBooksRefundReceipt)System.JSON.deserialize(invoiceObj.getBody(), ResponseQuickBooksRefundReceipt.class);
                updatedSyncToken = customerInvoiceGetResponce.RefundReceipt.SyncToken;
            } else if(syncingObjectType == QBUtil.INVOICE) {
                ResponseQuickBooksCustomerInvoice customerInvoiceGetResponce = (ResponseQuickBooksCustomerInvoice)System.JSON.deserialize(invoiceObj.getBody(), ResponseQuickBooksCustomerInvoice.class);
                updatedSyncToken = customerInvoiceGetResponce.Invoice.SyncToken;
            } else if(syncingObjectType == QBUtil.CREDIT_MEMO) {
                ResponseQuickBooksCreditMemo customerInvoiceGetResponce = (ResponseQuickBooksCreditMemo)System.JSON.deserialize(invoiceObj.getBody(), ResponseQuickBooksCreditMemo.class);
                updatedSyncToken = customerInvoiceGetResponce.CreditMemo.SyncToken;
            }
        } else {
            errorLogToInsert.add(new LogService().createErrorLog('CustomerInvoiceService', 'getUpdatedSyncToken()', invoiceObj.getBody(), invoiceObj.getStatusCode(), null, 
                                              syncingObjectType + LogService.METHOD_PARAM_SEPERATOR + invoiceAccId, LogService.QUICKBOOKS, false));
        }
        return updatedSyncToken;
    }
    
    public static String getSyncingObjectName(Decimal invoiceTotal, Boolean isChargeAccount) {
        String objectType = '';
        if(invoiceTotal >= 0 && !isChargeAccount) {
            objectType = QBUtil.SALES_RECEIPT;
        } else if(invoiceTotal < 0 && !isChargeAccount) {
            objectType = QBUtil.REFUND_RECEIPT;
        } else if(invoiceTotal >= 0 && isChargeAccount) {
            objectType = QBUtil.INVOICE;
        } else if(invoiceTotal < 0 && isChargeAccount) {
            objectType = QBUtil.CREDIT_MEMO;
        }
        return objectType;
    }
    
    private static List<QuickBooksCustomerInvoiceItemsHelper> getAllAccountingCOInvoiceItemsRecs(AccountingCustomerInvoice customerInvoiceRecord) {
        Boolean isAccrueTradeTaxUntilUnitSold = GeneralConfiguration.getAccrueTradeTaxUntilUnitSold();
        applicableSalesTaxSet = new Set<Id>();
        isNonTaxableLIExists = false;
        Decimal price, total;
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        List<QuickBooksCustomerInvoiceItemsHelper> itemsList = new List<QuickBooksCustomerInvoiceItemsHelper>();
        if(customerInvoiceRecord.AccountingCOInvoiceItemsRecs != null && customerInvoiceRecord.AccountingCOInvoiceItemsRecs.size() > 0) {
            List<Id> coliIds = new List<Id>();
            List<Id> sohIds = new List<Id>();
            List<Id> cokhIds = new List<Id>();
            List<Id> dealIds = new List<Id>();
            List<Id> soHeadersWithThirdPartyCheckoutList = new List<Id>();
            system.debug('***' + customerInvoiceRecord.AccountingCOInvoiceItemsRecs);
            
            for(AccountingCustomerInvoice.AccountingCOInvoiceItem coInvoiceItem : customerInvoiceRecord.AccountingCOInvoiceItemsRecs) {
                if(coInvoiceItem.COLineItemId != null) {
                    coliIds.add(coInvoiceItem.COLineItemId);
                }
                if(coInvoiceItem.SOHeaderId != null) {
                    sohIds.add(coInvoiceItem.SOHeaderId);
                    if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CheckoutType == 'Third-Party') {
                        soHeadersWithThirdPartyCheckoutList.add(coInvoiceItem.SOHeaderId);
                    }
                }
                if(coInvoiceItem.COKitHeaderId != null) {
                    cokhIds.add(coInvoiceItem.COKitHeaderId);
                }
                if(coInvoiceItem.DealId != null) {
                    dealIds.add(coInvoiceItem.DealId);
                }
                if(coInvoiceItem.SOPaymentRoleId != null && customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CheckoutType == 'Customer') {
                    List<Category__c> deductibleCategory = SOQLUtil.getDefaultCategoryRecords(new Map<String, String>{'Type__c' => 'Deductible', 'Status__c' => 'Active'});
                    if(deductibleCategory.size() > 0) {
                        itemCategoryAccountingId = deductibleCategory[0].AccountingId__c;
                        itemCategoryName = deductibleCategory[0].Name;
                    }
                    taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                    isNonTaxableLIExists = true;
                    QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper('Claim deductible', coInvoiceItem.Total, coInvoiceItem.Total, 1, coInvoiceItem.Total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                    itemsList.add(invoiceItem);
                }
            }
            
            Id coId = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderId;
            List<CO_Header__c> coHeadersList = getCustomerOrderHeaders(new List<Id>{coId}, coliIds);
            List<Service_Order_Header__c> soHeadersList = getServiceOrderHeaders(new List<Id>{coId}, sohIds);
            List<CO_Kit_Header__c> coKitHeadersList = getKitHeaders(new List<Id>{coId}, cokhIds);
            List<Deal_Item__c> dealItemList = getDealHeaders(new List<Id>{coId}, dealIds);
            List<F_I_Product__c> dealFIProductList = new List<F_I_Product__c>();
            for(Id dealId: dealIds) {
                if(dealIdToFIProductsMap != null && dealIdToFIProductsMap.containsKey(dealId)) {
                    for(F_I_Product__c FIProduct: dealIdToFIProductsMap.get(dealId)) {
                        dealFIProductList.add(FIProduct);
                    }
                }
            }
            
            for(CO_Header__c coHeaderRec: coHeadersList) {
                for(CO_Line_Item__c coLIRec: coHeaderRec.CO_Line_Items__r) {
                    if(coLIRec.Part__c != null) {
                        itemCategoryAccountingId = (coHeaderRec.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c)) ? coHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c : coLIRec.Part__r.Category__r.AccountingId__c;
                        itemCategoryName = (coHeaderRec.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coHeaderRec.Transaction_Type__r.Part_Category__r.Name)) ? coHeaderRec.Transaction_Type__r.Part_Category__r.Name : coLIRec.Part__r.Category__r.Name;

                    } else if(coLIRec.Fee__c != null) {
                        itemCategoryAccountingId = coLIRec.Fee__r.Category__r.AccountingId__c;
                        itemCategoryName = coLIRec.Fee__r.Category__r.Name;
                    }
                    if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(coLIRec.Id)) {
                        price = (coLIRec.Price_When_Tax_Included__c != null ? coLIRec.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(coLIRec.Id));
                    } else {
                        price = (coLIRec.Price__c != null ? coLIRec.Price__c : 0);
                    }
                    total = (coLIRec.Qty__c != null ? coLIRec.Qty__c : 0) * price;
                    String ItemCode = (coLIRec.Item_Code__c != null) ? coLIRec.Item_Code__c : '';
                    String ItemDescription = (coLIRec.Item_Description__c != null) ? coLIRec.Item_Description__c : '';
                    String Item = ItemCode + ' - ' + ItemDescription;
                    taxCodeAccountingId = coLIRec.Applicable_Tax__c != null ? coLIRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                    if(coLIRec.Applicable_Tax__c != null) {
                        applicableSalesTaxSet.add(coLIRec.Applicable_Tax__c);
                    } else {
                        isNonTaxableLIExists = true;
                    }
                    QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, coLIRec.Qty__c, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                    itemsList.add(invoiceItem);
                }
            } 
            if(soHeadersWithThirdPartyCheckoutList.size() > 0) {
                List<Category__c> deductibleCategory = SOQLUtil.getDefaultCategoryRecords(new Map<String, String>{'Type__c' => 'Deductible', 'Status__c' => 'Active'});
                if(deductibleCategory.size() > 0) {
                    itemCategoryAccountingId = deductibleCategory[0].AccountingId__c;
                    itemCategoryName = deductibleCategory[0].Name;
                }
                List<String> recordTypeList = new List<String>{'Deductible', 'Customer'};
                AggregateResult[] result = [SELECT SUM(Total_Amount__c) FROM SO_Payment_Role__c WHERE Service_Order_Header__c =:soHeadersWithThirdPartyCheckoutList  AND RecordType.DeveloperName in :recordTypeList];
                total = (Decimal)result[0].get('expr0');
                total = total != null ? total*-1 : 0;
                taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                
                if(total != 0) {
                	isNonTaxableLIExists = true;
                	QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper('Claim deductible', total, total, 1, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                	itemsList.add(invoiceItem);
                }
            }
            for(Service_Order_Header__c soHeaderRec: soHeadersList) {
                if(!(soHeaderRec.Transaction_Type__r.Type__c != null && (soHeaderRec.Transaction_Type__r.Type__c == 'Internal' || soHeaderRec.Transaction_Type__r.Type__c == 'Stock Unit')) && !(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party' && customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CheckoutType == 'Customer')) {
                    for(Service_Order_Line_Item__c soLIRec: soHeaderRec.Service_Order_Line_Items__r) {
                        Decimal qty = (soLIRec.Qty_Needed__c != null ? soLIRec.Qty_Needed__c : 0);
                        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(soLIRec.Id)) {
                          	Decimal totalPriceWithTax = ((soLIRec.Price_When_Tax_Included__c != null ? soLIRec.Price_When_Tax_Included__c : 0)*qty).setScale(2, RoundingMode.HALF_UP);
                          	Decimal totalTax = ((customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(soLIRec.Id))*qty).setScale(2, RoundingMode.HALF_UP);
                          	total = (totalPriceWithTax - totalTax).setScale(2, RoundingMode.HALF_UP);
                      	} else {
                          	total = (soLIRec.Kit_Price__c != null ? ((soLIRec.Kit_Price__c.setScale(2, RoundingMode.HALF_UP))*qty).setScale(2, RoundingMode.HALF_UP) : 0);
                      	}
                        if(soLIRec.Part__c != null) {
                            itemCategoryAccountingId = !String.isBlank(soHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c) ? soHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c : soLIRec.Part__r.Category__r.AccountingId__c;
                            itemCategoryName = !String.isBlank(soHeaderRec.Transaction_Type__r.Part_Category__r.Name) ? soHeaderRec.Transaction_Type__r.Part_Category__r.Name : soLIRec.Part__r.Category__r.Name;
                        } else if(soLIRec.Fee__c != null) {
                            itemCategoryAccountingId = soLIRec.Fee__r.Category__r.AccountingId__c;
                            itemCategoryName = soLIRec.Fee__r.Category__r.Name;
                        } else if(soLIRec.Labour_Code__c != null) {
                            itemCategoryAccountingId = !String.isBlank(soHeaderRec.Transaction_Type__r.Labour_Category__r.AccountingId__c) ? soHeaderRec.Transaction_Type__r.Labour_Category__r.AccountingId__c : soLIRec.Labour_Code__r.Category__r.AccountingId__c;
                            itemCategoryName = !String.isBlank(soHeaderRec.Transaction_Type__r.Labour_Category__r.Name) ? soHeaderRec.Transaction_Type__r.Labour_Category__r.Name : soLIRec.Labour_Code__r.Category__r.Name;
                        } else if(soLIRec.Sublet__c != null) {
                            itemCategoryAccountingId = soLIRec.Sublet__r.Category__r.AccountingId__c;
                            itemCategoryName = soLIRec.Sublet__r.Category__r.Name;
                        }
                        String ItemCode = (soLIRec.Item_Code__c != null) ? soLIRec.Item_Code__c : '';
                        String ItemDescription = (soLIRec.Item_Description__c != null) ? soLIRec.Item_Description__c : '';
                        String Item = ItemCode + ' - ' + ItemDescription;
                        taxCodeAccountingId = soLIRec.Applicable_Tax__c != null ? soLIRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                        if(soLIRec.Applicable_Tax__c != null) {
                            applicableSalesTaxSet.add(soLIRec.Applicable_Tax__c);
                        } else {
                            isNonTaxableLIExists = true;
                        }
                        Decimal defaultQty = 1;
                        QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, total, defaultQty, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                        itemsList.add(invoiceItem);
                    }
                }
            }
                
            for(CO_Kit_Header__c coKitHeaderRec: coKitHeadersList) {
                for(CO_Line_Item__c coKitHeaderLIRec: coKitHeaderRec.CO_Line_Items__r) {
                    if(coKitHeaderLIRec.Part__c != null) {
                        itemCategoryAccountingId = (coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__r.AccountingId__c)) ? coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__r.AccountingId__c : coKitHeaderLIRec.Part__r.Category__r.AccountingId__c;
                        itemCategoryName = (coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Name)) ? coKitHeaderLIRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Name : coKitHeaderLIRec.Part__r.Category__r.Name;

                    } else if(coKitHeaderLIRec.Fee__c != null) {
                        itemCategoryAccountingId = coKitHeaderLIRec.Fee__r.Category__r.AccountingId__c;
                        itemCategoryName = coKitHeaderLIRec.Fee__r.Category__r.Name;
                    }
                    if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(coKitHeaderLIRec.Id)) {
                        price = (coKitHeaderLIRec.Price_When_Tax_Included__c != null ? coKitHeaderLIRec.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(coKitHeaderLIRec.Id));
                    } else {
                        price = (coKitHeaderLIRec.Price__c != null ? coKitHeaderLIRec.Price__c : 0);
                    }
                    total = (coKitHeaderLIRec.Qty__c != null ? coKitHeaderLIRec.Qty__c : 0) * price;
                    String ItemCode = (coKitHeaderLIRec.Item_Code__c != null) ? coKitHeaderLIRec.Item_Code__c : '';
                    String ItemDescription = (coKitHeaderLIRec.Item_Description__c != null) ? coKitHeaderLIRec.Item_Description__c : '';
                    String Item = ItemCode + ' - ' + ItemDescription;
                    taxCodeAccountingId = coKitHeaderLIRec.Applicable_Tax__c != null ? coKitHeaderLIRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                    if(coKitHeaderLIRec.Applicable_Tax__c != null) {
                        applicableSalesTaxSet.add(coKitHeaderLIRec.Applicable_Tax__c);
                    } else {
                        isNonTaxableLIExists = true;
                    }
                    QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, coKitHeaderLIRec.Qty__c, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                    itemsList.add(invoiceItem);
                }
            }
            
            Set<String> defaultCategoryTypeSet = new Set<String>{'Unit', 'Trade-in', 'Stocked Trade', 'Tax', 'Lien Payout'};
            Map<String, Category__c> categoryTypeToRecMap = new Map<String, Category__c>();
            List<Category__c> systemDefaultCategoryList = [SELECT AccountingId__c, Name, Type__c FROM Category__c WHERE Type__c IN :defaultCategoryTypeSet AND Default__c = true AND Active__c = true];
            for(Category__c categoryRec: systemDefaultCategoryList) {
                categoryTypeToRecMap.put(categoryRec.Type__c, categoryRec);
            }
            
            String firstUnitSoldOnDealCategoryIncomeGLAccId = '';
            String firstUnitSoldOnDealCategoryIncomeGLName = '';
            for(Deal_Item__c dealItem : dealItemList) {
                if(dealItem.Type__c == Constants.DEAL_ITEM_TYPE_UNIT) {
                    firstUnitSoldOnDealCategoryIncomeGLAccId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                    firstUnitSoldOnDealCategoryIncomeGLName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                    break;
                }
            }
            
            for(Deal_Item__c dealItem : dealItemList) {
                if(dealItem.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                    if(dealItem.Is_Stocked_In__c) {
                        itemCategoryAccountingId = categoryTypeToRecMap.get('Stocked Trade').AccountingId__c;
                        itemCategoryName = categoryTypeToRecMap.get('Stocked Trade').Name;
                    } else {
                        itemCategoryAccountingId = categoryTypeToRecMap.get('Trade-in').AccountingId__c;
                        itemCategoryName = categoryTypeToRecMap.get('Trade-in').Name;
                    }
                    String Item = 'Trade In';
                    Item += String.isNotBlank(QBUtil.getDealUnitName(dealItem)) ? '-' : '';
                    Item += QBUtil.getDealUnitName(dealItem);
                    dealItem.Actual_Cash_Value__c = dealItem.Actual_Cash_Value__c != null ? dealItem.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
                    total = price = dealItem.Actual_Cash_Value__c * -1;
                    if(dealItem.Applicable_Tax__c != null) {
                    	taxCodeAccountingId = dealItem.Applicable_Tax__r.Accounting_Id__c;
                    	applicableSalesTaxSet.add(dealItem.Applicable_Tax__c);
                    } else {
                    	taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                    	isNonTaxableLIExists = true;
                    }
                    QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, 1, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                    itemsList.add(invoiceItem);
                    
                    Decimal agreedValue = (dealItem.Agreed_Value__c != null) ? dealItem.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
                    Decimal salesTaxPercentageOnAgreedValue = (dealItem.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItem.Default_Unit_Sales_Tax_Percentage__c : 0;
                    Decimal preTaxAgreedValue = customerInvoiceRecord.isTaxIncludingPricing ? (agreedValue / (1 + (salesTaxPercentageOnAgreedValue / 100))).setScale(2, RoundingMode.HALF_UP) : agreedValue;
                    Decimal variance = preTaxAgreedValue - dealItem.Actual_Cash_Value__c;
                    if(variance != 0) {
                        Item = 'Trade In';
                        Item += String.isNotBlank(QBUtil.getDealUnitName(dealItem)) ? '-' : '';
                        Item += QBUtil.getDealUnitName(dealItem);
                        Item += '-Variance';
                        itemCategoryAccountingId = firstUnitSoldOnDealCategoryIncomeGLAccId;
                        itemCategoryName = firstUnitSoldOnDealCategoryIncomeGLName;
                        price = variance*-1;
                        Decimal qty = 1;
                        total = qty*price;
                        taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                        isNonTaxableLIExists = true;
                        itemsList.add(new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, qty, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId));
                    }
                    
                    //Trade In Unit - Lien Payout Info
                    if(dealItem.Lien_Payout__c != null && dealItem.Lien_Payout__c > 0 && categoryTypeToRecMap.containsKey('Lien Payout')) {
                        Item = 'Lien payout:' + (!String.isBlank(dealItem.Customer_Owned_Unit__r.VIN_Number__c) ? (' ' + dealItem.Customer_Owned_Unit__r.VIN_Number__c) : '') 
                                    +  (!String.isBlank(dealItem.Finance_Company__r.Name) ? (' ' + dealItem.Finance_Company__r.Name) : '');
                        price = dealItem.Lien_Payout__c;
                        total = dealItem.Lien_Payout__c;
                        Decimal qty = 1;
                        itemCategoryAccountingId = categoryTypeToRecMap.get('Lien Payout').AccountingId__c;
                        itemCategoryName = categoryTypeToRecMap.get('Lien Payout').Name;
                        taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                        isNonTaxableLIExists = true;
                        itemsList.add(new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, qty, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId));
                    }
                } else {
                    for(Option_Fee__c optionAndFee : dealItem.Options_Fees__r) {
                        if(optionAndFee.Part__c != null) {
                            itemCategoryAccountingId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                            itemCategoryName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                        } else if(optionAndFee.Fee__c != null) {
                            if(optionAndFee.CO_Line_Item__c != null || optionAndFee.Service_Order_Line_Item__c != null) {
                                itemCategoryAccountingId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                                itemCategoryName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                            } else {
                                itemCategoryAccountingId = optionAndFee.Fee__r.Category__r.AccountingId__c;
                                itemCategoryName = optionAndFee.Fee__r.Category__r.Name;
                            }
                        } else if(optionAndFee.Labour_Code__c != null) {
                            itemCategoryAccountingId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                            itemCategoryName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                        } else if(optionAndFee.Product__c != null) {
                            if(optionAndFee.Product__r.Type__c == Constants.SUBLET) {
                            itemCategoryAccountingId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                              itemCategoryName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                            } else {
                            itemCategoryAccountingId = optionAndFee.Product__r.Category__r.AccountingId__c != null ? optionAndFee.Product__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                              itemCategoryName = optionAndFee.Product__r.Category__r.Name != null ? optionAndFee.Product__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                            }
                        }
                        String ItemCode = (optionAndFee.Item_Code__c != null) ? optionAndFee.Item_Code__c : '';
                        String ItemDescription = (optionAndFee.Item_Description__c != null) ? optionAndFee.Item_Description__c : '';
                        String Item = ItemCode + ' - ' + ItemDescription;
                        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(optionAndFee.Id)) {
                            price = (optionAndFee.Price_When_Tax_Included__c != null ? optionAndFee.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(optionAndFee.Id));
                        } else {
                            price = (optionAndFee.Price__c != null ? optionAndFee.Price__c : 0);
                        }
                        total = (optionAndFee.Qty__c != null ? optionAndFee.Qty__c : 0) * price;
                        taxCodeAccountingId = optionAndFee.Applicable_Tax__c != null ? optionAndFee.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                        if(optionAndFee.Applicable_Tax__c != null) {
                            applicableSalesTaxSet.add(optionAndFee.Applicable_Tax__c);
                        } else {
                            isNonTaxableLIExists = true;
                        }
                        QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, optionAndFee.Qty__c, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                        itemsList.add(invoiceItem);
                    }
                    for(Deal_Unit_Price_Cost__c dealUnitPriceandCost : dealItem.Deal_Unit_Prices_Costs__r){
                        itemCategoryAccountingId = dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItem.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                        itemCategoryName = dealItem.Customer_Owned_Unit__r.Category__r.Name != null ? dealItem.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                        String Item = dealUnitPriceandCost.Type__c == 'Base' ? QBUtil.getDealUnitName(dealItem) : dealUnitPriceandCost.Item_Description__c;
                        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(dealUnitPriceandCost.Id)) {
                            price = (dealUnitPriceandCost.Price_When_Tax_Included__c != null ? dealUnitPriceandCost.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(dealUnitPriceandCost.Id));
                        } else {
                            price = (dealUnitPriceandCost.Price__c != null ? dealUnitPriceandCost.Price__c : 0);
                        }
                        total = (dealUnitPriceandCost.Qty__c != null ? dealUnitPriceandCost.Qty__c : 0) * price;
                        taxCodeAccountingId = dealUnitPriceandCost.Applicable_Tax__c != null ? dealUnitPriceandCost.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                        if(dealUnitPriceandCost.Applicable_Tax__c != null) {
                            applicableSalesTaxSet.add(dealUnitPriceandCost.Applicable_Tax__c);
                        } else {
                            isNonTaxableLIExists = true;
                        }
                        QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, dealUnitPriceandCost.Qty__c, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                        itemsList.add(invoiceItem);
                    }
                    
                   
                }
                if(dealItem.Stamp_Duty_Total__c != null && dealItem.Stamp_Duty_Total__c != 0){
                    List<Category__c> stampDutyCategory = SOQLUtil.getDefaultCategoryRecords(new Map<String, String>{'Type__c' => 'Stamp Duty', 'Status__c' => 'Active'});
                    total = dealItem.Stamp_Duty_Total__c != null ? dealItem.Stamp_Duty_Total__c  : 0;
                    if(stampDutyCategory.size() > 0) {
                        itemCategoryAccountingId = stampDutyCategory[0].AccountingId__c;
                        itemCategoryName = stampDutyCategory[0].Name;
                    }
                    taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
                    isNonTaxableLIExists = true;
                    QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper('Stamp Duty', total, total, 1, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                    itemsList.add(invoiceItem);
                }
            }
            
            for(F_I_Product__c FIProduct : dealFIProductList){
              itemCategoryAccountingId = FIProduct.Vendor_Product__r.Category__r.AccountingId__c != null ? FIProduct.Vendor_Product__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                itemCategoryName = FIProduct.Vendor_Product__r.Category__r.Name != null ? FIProduct.Vendor_Product__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
                String Item = FIProduct.Item_Description__c;
                if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(FIProduct.Id)) {
                    price = (FIProduct.Price_When_Tax_Included__c != null ? FIProduct.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(FIProduct.Id));
                } else {
                    price = (FIProduct.Price__c != null ? FIProduct.Price__c : 0);
                }
                total = (FIProduct.Price__c != null ? FIProduct.Price__c : 0);
                taxCodeAccountingId = FIProduct.Applicable_Tax__c != null ? FIProduct.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
                if(FIProduct.Applicable_Tax__c != null) {
                    applicableSalesTaxSet.add(FIProduct.Applicable_Tax__c);
                } else {
                    isNonTaxableLIExists = true;
                }
                QuickBooksCustomerInvoiceItemsHelper invoiceItem = new QuickBooksCustomerInvoiceItemsHelper(Item, total, price, 1, total, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);
                itemsList.add(invoiceItem);
            }
        }
        return itemsList;
    }
    
    private static List<CO_Header__c> getCustomerOrderHeaders(List<Id> coIdsList, List<Id> coliIds) {
        List<CO_Header__c> coHeadersList = new List<CO_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
       
        if(coIdsList != null && coIdsList.size() > 0) {
            String query = 'SELECT ';
            for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COHeader')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query += '(SELECT ';
            for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COLineItem')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            
            query += ' FROM CO_Line_Items__r WHERE Service_Order_Line_Item__c = NULL AND Id IN: coliIds) FROM CO_Header__c WHERE Id IN: coIdsList';
            coHeadersList = Database.query(query);
        }
        return coHeadersList;
    }
    
    private static List<Service_Order_Header__c> getServiceOrderHeaders(List<Id> coIdsList, List<Id> sohIds) {
        List<Service_Order_Header__c> soHeadersList = new List<Service_Order_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(coIdsList != null && coIdsList.size() > 0) {
            soHeadersList = [SELECT Name__c, Total__c, Correction__c, Cause__c, Concern__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.VIN_Number__c,
                                    Customer_Owned_Unit__r.Unit_Make__r.Name, Customer_Owned_Unit__r.Unit_Model__r.Name__c, Customer_Owned_Unit__r.Year__c,
                                    Odometer_on_Arrival__c, Odometer_on_Departure__c, CO_Header__c, Notes_For_Customer__c, Transaction_Type__r.Type__c,
                                    Transaction_Type__r.Part_Category__r.AccountingId__c, Transaction_Type__r.Part_Category__r.Name,
                                    Transaction_Type__r.Labour_Category__r.AccountingId__c, Transaction_Type__r.Labour_Category__r.Name,
                                    (SELECT Item_Code__c, Item_Description__c, Item_Desc__c, Kit_Price__c, Labour_Code__c, Part__c, Qty_Needed__c, Total__c, 
                                            Price_When_Tax_Included__c, Fee__c, Tax_Percent__c, Tax_Amount__c, Part__r.Taxable__c, Part__r.Category__c,
                                            Part__r.Category__r.AccountingId__c, Part__r.Category__r.Name, Fee__r.Taxable__c, Fee__r.Category__c,
                                            Fee__r.Category__r.AccountingId__c, Fee__r.Category__r.Name, Labour_Code__r.Taxable__c,
                                            Labour_Code__r.Category__c, Labour_Code__r.Category__r.AccountingId__c, Labour_Code__r.Category__r.Name,
                                            Sublet__c, Sublet__r.Category__c, Sublet__r.Category__r.AccountingId__c, Sublet__r.Category__r.Name,
                                            Applicable_Tax__c, Applicable_Tax__r.Accounting_Id__c
                                            FROM Service_Order_Line_Items__r )
                                    FROM Service_Order_Header__c WHERE Id IN: sohIds ];
        }
        return soHeadersList;
    }
    
    
    private static List<CO_Kit_Header__c> getKitHeaders(List<Id> coIdsList, List<Id> cokhIds) {
        List<CO_Kit_Header__c> coKitHeadersList = new List<CO_Kit_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(coIdsList != null && cokhIds.size() > 0) {
            coKitHeadersList = [SELECT CO_Header__c, Kit_Header__c, Price__c, Tax_Amount__c, Actual_Kit_Price__c, CreatedDate, Kit_Header__r.Kit_Unique_Name__c,
                                    Can_Split__c, Service_Kit__c, Fixed_Price_Flag__c, CO_Fixed_KitHeader__c,
                                    (SELECT Name, Item_ID__c, CO_Header__c, CO_Header__r.Name, CO_Header__r.Customer__c, CO_Header__r.Customer__r.Name,
                                            CO_Header__r.Owner__c, CO_Header__r.Owner__r.Name, CO_Header__r.Order_status__c, Qty__c, Qty_Committed__c,
                                            Item_Code__c, Item_Description__c, Price__c, Part__r.Name, Part__r.Part_Id__c, Part__r.Part_Number__c,
                                            Part__r.Description__c, Part__r.AvailableParts__c, Part__r.Vendor__c, Special_Order__c, Tax__c, Retail__c,
                                            Closed_CO_Invoice_link__c, VO_Number__c, VO_Status__c, Expected_Delivery_Date__c, CreatedDate, Fee__c,
                                            Fee__r.Fee_Unique_Name__c, Fixed_Price__c, CO_Fixed_KitLineItem__c, Actual_Kit_Price__c, Kit_Price_With_Price_Level__c,
                                            CO_Kit_Header__r.Id, Sub_Total_With_Tax__c, Sub_Total_Without_Tax__c, Price_When_Tax_Included__c, Tax_Amount__c,
                                            Oversold_Qty__c, Is_Temporary__c, Part__r.Taxable__c, Part__r.Category__c, Part__r.Category__r.AccountingId__c,
                                            Part__r.Category__r.Name, Fee__r.Taxable__c, Fee__r.Category__c, Fee__r.Category__r.AccountingId__c,
                                            Fee__r.Category__r.Name, Applicable_Tax__c, Applicable_Tax__r.Accounting_Id__c, CO_Header__r.Transaction_Type__r.Type__c,
                                            CO_Header__r.Transaction_Type__r.Part_Category__r.AccountingId__c, CO_Header__r.Transaction_Type__r.Part_Category__r.Name, 
                                            CO_Header__r.Transaction_Type__c, CO_Header__r.Transaction_Type__r.Part_Category__c 
                                            FROM CO_Line_Items__r WHERE Is_In_Service_Order__c = false)
                                    FROM CO_Kit_Header__c WHERE Id IN: cokhIds];
        }
        return coKitHeadersList;
    }
    
    private static List<Deal_Item__c> getDealHeaders(List<Id> coIdsList, List<Id> dealIds) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(dealIds != null && dealIds.size() > 0) {
            String query = 'SELECT Id, (SELECT Id FROM Deal_Items__r), ';
            // Child Query For Deal F&I Products
            query += '(SELECT ';
            for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('DealFIProduct')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' FROM F_I_Products__r) FROM Deal__c WHERE Id IN: dealIds';
            
            List<Deal__c> dealList = Database.query(query);
            if(dealList.size() > 0) {
                Set<String> dealItemId = new Set<String>();
                for(Deal__c dealRec : dealList) {
                    for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
                        dealItemId.add(dealItemRec.Id);
                    }
                    
                    if(dealIdToFIProductsMap != null) {
                        dealIdToFIProductsMap.put(dealRec.Id, dealRec.F_I_Products__r);
                    }
                }
                query = 'SELECT ';
                for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('DealItems')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query += '(SELECT ';
                for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('OptionAndFees')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length() - 2);
                query += ' FROM Options_Fees__r), ';
                query += '(SELECT ';
                
                for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('DealUnitPriceCost')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length()-2);
                query += ' FROM Deal_Unit_Prices_Costs__r) FROM Deal_Item__c WHERE Id IN: dealItemId';
                dealItemList = Database.query(query);
            }
        }
        return dealItemList;
    }
    
    public class QuickBooksSalesOrRefundReceipt {
        public String Id;
        public String SyncToken;
        public String DocNumber;  
        public Date TxnDate;
        public List<QuickBooksCustomerInvoiceItemsWrapper> Line;
        public QuickBooksCustomerRefWrapper CustomerRef;
        public Decimal TotalAmt;
        public String PrintStatus;
        public String PaymentRefNum;
        public String GlobalTaxCalculation;
        public Decimal Balance;
        public String PrivateNote;
        public AccountRefWrapper DepositToAccountRef;
        public QBTxnTaxDetailWrapper TxnTaxDetail;
        
        public QuickBooksSalesOrRefundReceipt(AccountingCustomerInvoice customerInvoiceRecord) {
            this.Id = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.AccountingId;
            this.SyncToken = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.SyncToken;
            this.DocNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber; 
            this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate);
            this.Line = new List<QuickBooksCustomerInvoiceItemsWrapper>();
            for(QuickBooksCustomerInvoiceItemsHelper coInvoiceItemRec : getAllAccountingCOInvoiceItemsRecs(customerInvoiceRecord)) {
                this.Line.add(new QuickBooksCustomerInvoiceItemsWrapper(coInvoiceItemRec));
            }
            this.TotalAmt = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
            if(syncingObjectType == QBUtil.REFUND_RECEIPT && this.TotalAmt < 0) {
                this.TotalAmt *= -1;
                customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax *= -1;
                for(AccountingCustomerInvoice.TaxDetail taxDetailRec : customerInvoiceRecord.taxDetails) {
                    taxDetailRec.TaxAmount *= -1;
                    taxDetailRec.TaxableAmount *= -1;
                }
            }
            
            if(QBUtil.isQBTaxCodesEnabled) {
                if(customerInvoiceRecord.isTaxIncludingPricing) {
                    this.GlobalTaxCalculation = 'TaxInclusive';
                } else {
                    this.GlobalTaxCalculation = 'TaxExcluded';
                }
                this.TxnTaxDetail = new QBTxnTaxDetailWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax,
                                                        customerInvoiceRecord.taxDetails, applicableSalesTaxSet, isNonTaxableLIExists);
            } else {
                this.GlobalTaxCalculation = TAX_NOT_APPLICABLE;
                // Adding Taxes as line item of Invoice - #4158
                for(AccountingCustomerInvoice.TaxDetail taxRec : customerInvoiceRecord.taxDetails) {
                    if(taxRec.TaxAmount != null && taxRec.TaxAmount != 0) {
                        this.Line.add(new QuickBooksCustomerInvoiceItemsWrapper(taxRec));
                    }
                }
            }
            
            this.CustomerRef = new QuickBooksCustomerRefWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer);
            this.PrintStatus = 'PrintComplete';
            this.PaymentRefNum = 'To Print';
            this.Balance = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
            
            if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber != null) {
                this.PrivateNote = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CustomerName + ';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber;
            }
            this.DepositToAccountRef = new AccountRefWrapper(AccountingUtil.getChartofAccount('Customer Deposits'));
        }
     }
     
     public class QuickBooksCustomerInvoiceOrCreditMemo {
         
        public String Id;
        public String SyncToken;
        public String DocNumber;  
        public Date TxnDate;
        public List<QuickBooksCustomerInvoiceItemsWrapper> Line;
        public QuickBooksCustomerRefWrapper CustomerRef;
        public Decimal TotalAmt;
        public String PrintStatus;
        public String GlobalTaxCalculation;
        public Decimal Balance;
        public String PrivateNote;
        public QBTxnTaxDetailWrapper TxnTaxDetail;
        
        public QuickBooksCustomerInvoiceOrCreditMemo(AccountingCustomerInvoice customerInvoiceRecord) {
            this.Id = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.AccountingId;
            this.SyncToken = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.SyncToken;
            this.DocNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber; 
            this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate);
            this.Line = new List<QuickBooksCustomerInvoiceItemsWrapper>();
            for(QuickBooksCustomerInvoiceItemsHelper coInvoiceItemRec : getAllAccountingCOInvoiceItemsRecs(customerInvoiceRecord)) {
                this.Line.add(new QuickBooksCustomerInvoiceItemsWrapper(coInvoiceItemRec));
            }
            this.TotalAmt = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
            if(syncingObjectType == QBUtil.CREDIT_MEMO && this.TotalAmt < 0) {
                this.TotalAmt *= -1;
                customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax *= -1;
                for(AccountingCustomerInvoice.TaxDetail taxDetailRec : customerInvoiceRecord.taxDetails) {
                    taxDetailRec.TaxAmount *= -1;
                    taxDetailRec.TaxableAmount *= -1;
                }
            }
            
            if(QBUtil.isQBTaxCodesEnabled) {
                if(customerInvoiceRecord.isTaxIncludingPricing) {
                    this.GlobalTaxCalculation = 'TaxInclusive';
                } else {
                    this.GlobalTaxCalculation = 'TaxExcluded';
                }
                this.TxnTaxDetail = new QBTxnTaxDetailWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax,
                                                        customerInvoiceRecord.taxDetails, applicableSalesTaxSet, isNonTaxableLIExists);
            } else {
                this.GlobalTaxCalculation = TAX_NOT_APPLICABLE;
                // Adding Taxes as line item of Invoice - #4158
                for(AccountingCustomerInvoice.TaxDetail taxRec : customerInvoiceRecord.taxDetails) {
                    if(taxRec.TaxAmount != null && taxRec.TaxAmount != 0) {
                        this.Line.add(new QuickBooksCustomerInvoiceItemsWrapper(taxRec));
                    }
                }
            }
            
            this.CustomerRef = new QuickBooksCustomerRefWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer);
            this.PrintStatus = 'PrintComplete';
            this.Balance = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
            
            if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber != null) {
                this.PrivateNote = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CustomerName + ';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber;
            }
        }
     }   
     
     
    public class QuickBooksCustomerInvoiceItemsWrapper {
        
        public String Description;
        public Decimal Amount;
        public String DetailType;
        public QuickBooksInvoiceItemSalesItemLineDetailWrappper SalesItemLineDetail;
        
        public QuickBooksCustomerInvoiceItemsWrapper(QuickBooksCustomerInvoiceItemsHelper coInvoiceItemRec) {
            this.Description = coInvoiceItemRec.Description; 
            this.Amount = coInvoiceItemRec.Amount;
            if(syncingObjectType == QBUtil.REFUND_RECEIPT || syncingObjectType == QBUtil.CREDIT_MEMO) {
                this.Amount *= -1;
            }
            this.DetailType = 'SalesItemLineDetail';   
            this.SalesItemLineDetail = new QuickBooksInvoiceItemSalesItemLineDetailWrappper(coInvoiceItemRec);              
        }
        
        public QuickBooksCustomerInvoiceItemsWrapper(AccountingCustomerInvoice.TaxDetail taxItemObj) {
            this.Description = taxItemObj.Name; 
            this.Amount = taxItemObj.TaxAmount;
            /*if(syncingObjectType == QBUtil.REFUND_RECEIPT || syncingObjectType == QBUtil.CREDIT_MEMO) {
                this.Amount *= -1;
            }*/
            this.DetailType = 'SalesItemLineDetail';   
            this.SalesItemLineDetail = new QuickBooksInvoiceItemSalesItemLineDetailWrappper(taxItemObj);              
        }
    }
     
    public class QuickBooksInvoiceItemSalesItemLineDetailWrappper {
        public Decimal UnitPrice;
        public Decimal Qty;
        public QuickBooksItemRefWrapper ItemRef;
        public QBInnerEntityWrapper TaxCodeRef;
        
        public QuickBooksInvoiceItemSalesItemLineDetailWrappper(QuickBooksCustomerInvoiceItemsHelper coInvoiceItemRec) {
            this.UnitPrice = coInvoiceItemRec.UnitPrice; 
            this.Qty = coInvoiceItemRec.Qty;
            if(syncingObjectType == QBUtil.REFUND_RECEIPT || syncingObjectType == QBUtil.CREDIT_MEMO) {
                this.Qty *= -1;
            }
            if(coInvoiceItemRec.ItemCategoryAccountingId != null){
                this.ItemRef = new QuickBooksItemRefWrapper(coInvoiceItemRec.ItemCategoryAccountingId, coInvoiceItemRec.ItemCategoryName);
            }
            if(QBUtil.isQBTaxCodesEnabled) {
                this.TaxCodeRef = new QBInnerEntityWrapper(coInvoiceItemRec.TaxCodeAccountingId, '');
            }
        }
        
        public QuickBooksInvoiceItemSalesItemLineDetailWrappper(AccountingCustomerInvoice.TaxDetail taxItemObj) {
            if(taxItemObj.AccountingId != null) {
                this.ItemRef = new QuickBooksItemRefWrapper(taxItemObj.AccountingId, taxItemObj.CategoryName);
            }
        }
    }
     
    public class QuickBooksItemRefWrapper {
        public String value; 
        public String name;
        public QuickBooksItemRefWrapper(String ItemCategoryAccountingId, String ItemCategoryNam) {
            this.value = ItemCategoryAccountingId;    
            this.name = ItemCategoryNam;        
        }
    }
     
    public class QuickBooksCustomerRefWrapper {
        public String value; 
        public String name;
        public QuickBooksCustomerRefWrapper(AccountingCustomerInvoice.CustomerWrapper customerRef) {
            this.value = customerRef.AccountingId;    
            this.name = customerRef.Name;       
        }
    }
     
    public class AccountRefWrapper {
        public String value;
        public AccountRefWrapper(String AccountRef) {
            this.value = AccountRef;
        }
    }
     
    public class ResponseQuickBooksSalesReceipt {
        public QuickBooksSalesOrRefundReceipt SalesReceipt; 
    }
     
    public class ResponseQuickBooksRefundReceipt {
        public QuickBooksSalesOrRefundReceipt RefundReceipt;
    }
     
    public class ResponseQuickBooksCustomerInvoice {
        public QuickBooksCustomerInvoiceOrCreditMemo invoice;
    }
     
    public class ResponseQuickBooksCreditMemo {
        public QuickBooksCustomerInvoiceOrCreditMemo CreditMemo;
    }
    
    public class QuickBooksCustomerInvoiceItemsHelper {
        public String Description;
        public Decimal Amount;
        public Decimal UnitPrice;
        public Decimal Qty;
        public Decimal TaxInclusiveAmt;
        public String ItemCategoryAccountingId;
        public String ItemCategoryName;
        public String TaxCodeAccountingId;
        
        public QuickBooksCustomerInvoiceItemsHelper(String description, Decimal amount, Decimal unitPrice, Decimal qty, Decimal taxInclusiveAmt, String itemCategoryAccountingId, String itemCategoryName, String taxCodeAccountingId) {
            this.Description = description; 
            this.Amount = amount;
            this.UnitPrice = unitPrice;
            this.Qty = qty;
            this.TaxInclusiveAmt = taxInclusiveAmt;   
            this.ItemCategoryAccountingId = itemCategoryAccountingId;   
            this.ItemCategoryName = itemCategoryName;  
            this.TaxCodeAccountingId = taxCodeAccountingId;
        }
     }
}
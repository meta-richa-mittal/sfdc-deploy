public without sharing class COPaymentService {
    
    public static final String AR_PAYMENT = 'AR Payment';
    private static Log__c logRec;
    public static CO_Invoice_Payment__c createCOPaymentRecord(COInvoicePayment coInvoicePaymentObj) {
        CO_Invoice_Payment__c coInvoicePaymentRec = new CO_Invoice_Payment__c();
        coInvoicePaymentRec.Amount__c = coInvoicePaymentObj.Amount;
        coInvoicePaymentRec.Payment_Method__c = coInvoicePaymentObj.PaymentMethod ;
        coInvoicePaymentRec.CO_Invoice_Header__c = coInvoicePaymentObj.COInvoiceHeaderId;
        coInvoicePaymentRec.Is_Reverse__c = (coInvoicePaymentObj.IsReverse != null) ? coInvoicePaymentObj.IsReverse : false;
        coInvoicePaymentRec.Id = coInvoicePaymentObj.COInvoicePaymentId;
        coInvoicePaymentRec.Cash_Drawer__c  = coInvoicePaymentObj.CashDrawerId;
        if(coInvoicePaymentObj.PaymentDate != null) {
        DateTime dtValue = HomeSearchFilterInterface.getDateFromString(coInvoicePaymentObj.PaymentDate);
            coInvoicePaymentRec.Payment_Date__c = Date.newInstance(dtValue.year(), dtValue.month(), dtValue.day());
        } else {
            coInvoicePaymentRec.Payment_Date__c = date.today();
        }
        
        if(coInvoicePaymentObj.ReverseLink != null) {
            coInvoicePaymentRec.Reverse_Link__c = coInvoicePaymentObj.ReverseLink;
            coInvoicePaymentRec.Reverse_Payment_From__c = coInvoicePaymentObj.ReverseLink;
        }
        
        if(coInvoicePaymentRec.Payment_Method__c == Constants.AR_CREDIT) {
        	coInvoicePaymentRec.AR_Credit_Accounting_Id__c = coInvoicePaymentObj.ARCreditAccId;
            coInvoicePaymentRec.AR_Credit_Number__c = coInvoicePaymentObj.ARCreditNumber;
            coInvoicePaymentRec.Unapplied_Payment_Type__c = coInvoicePaymentObj.UnappliedPaymentType;
        }
        coInvoicePaymentRec.Customer_Name__c = coInvoicePaymentObj.CustomerId;
        coInvoicePaymentRec.Reference__c = coInvoicePaymentObj.ReferenceNumber;
        coInvoicePaymentRec.Payment_Terminal__c = String.isNotBlank(coInvoicePaymentObj.PaymentTerminalId) ? coInvoicePaymentObj.PaymentTerminalId : null;
        coInvoicePaymentRec.Deposit_Payment_Method__c = coInvoicePaymentObj.DepositPaymentMethod;
        return coInvoicePaymentRec;
    }

    public static String processARCRPaymentToAccounting(String coInvPaymentId) {
        List<CO_Invoice_Payment__c> coInvPaymentList = [SELECT Name, Amount__c, AR_Credit_Accounting_Id__c, AR_Credit_Number__c, Payment_Date__c, 
                                                        Payment_Method__c, CO_Invoice_Header__r.CO_Header__r.Name, 
                                                        CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c, 
                                                        CO_Invoice_Header__r.CO_Header__r.Customer__r.Xero_Customer_Accounting_Id__c, 
                                                        AR_Credit_Invoice_Accounting_Id__c, Unapplied_Payment_Type__c FROM CO_Invoice_Payment__c WHERE Id =: coInvPaymentId];

        if(coInvPaymentList.size() == 0) throw new BlackPurlException('Invalid Payment Id');
        return processARCRToAccounting(coInvPaymentList);
    }

    public static String processARCRDepositToAccounting(String coDepositId) {
        List<CO_Deposit__c> coDepositList = [SELECT Name, Amount__c, AR_Credit_Accounting_Id__c, AR_Credit_Number__c, Payment_Date__c, 
                                                        Payment_Method__c, CO_Header__r.Name, 
                                                        CO_Header__r.Customer__r.AccountingId__c, 
                                                        CO_Header__r.Customer__r.Xero_Customer_Accounting_Id__c, 
                                                        AR_Credit_Invoice_Accounting_Id__c, Unapplied_Payment_Type__c FROM CO_Deposit__c WHERE Id =: coDepositId];

        if(coDepositList.size() == 0) throw new BlackPurlException('Invalid Deposit Id');
        return processARCRToAccounting(coDepositList);
    }

    private static String processARCRToAccounting(List<SObject> arcrTxnRecList) {
        String status = 'Error', actualErrorMsg = '';
        String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        List<IFW_IntegrationConfig__c> integrationConfigList;
        try {
            if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                integrationConfigList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE, 'Enabled__c' => true});
                if(integrationConfigList.isEmpty()) throw new BlackpurlException('QB config is not defined');
                status = postInvoiceForARCreditPaymentInQB(arcrTxnRecList, integrationConfigList[0]);
            } else if(activeIntegrationName == 'Xero') {
                integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems('Xero', 
                            new Map<String, String>{IntegrationUtility.INVOICE_PAYMENT => IntegrationUtility.CREATE_ACTION});
                if(integrationConfigList.size() == 0) throw new BlackpurlException('Xero config is not defined');
                if(integrationConfigList[0].IFW_IntegrationConfigItems__r.size() == 0) throw new BlackpurlException('Config item for Payment not defined');
                status = applyPaymentToARCreditInXero(arcrTxnRecList, integrationConfigList);
            }
        } catch(Exception e) {
            actualErrorMsg = e.getMessage();
            status = handleExceptionForARCRPayment(e.getMessage(), activeIntegrationName, arcrTxnRecList, integrationConfigList);
        }

        if(status == 'Error') {
            deleteTransactionsRelatedToARCRPayment(activeIntegrationName, arcrTxnRecList, new List<Log__c>{logRec});
        } else if(!arcrTxnRecList.isEmpty()) {
            String invoiceNumber = (String)arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Number__c');
            List<CO_Invoice_Header__c> coInvHeaderList = [SELECT Id FROM CO_Invoice_Header__c WHERE AutoNumberHolder__r.Name =:invoiceNumber];
            if(!coInvHeaderList.isEmpty()) {
                coInvHeaderList[0].AR_Balance__c = 0;
                DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvHeaderList);
            }
        }

        // update refresh tokens for OAuth 2
        AccountingUtil.updateRefreshTokensForOAuth2(activeIntegrationName, integrationConfigList);
        return (actualErrorMsg == QBUtil.AR_CREDIT_TOO_LONG_ERR_MSG) ? actualErrorMsg : status;
    }

    private static String handleExceptionForARCRPayment(String errorMsg, String activeIntegrationName, List<SObject> arcrTxnRecList, 
                                                        List<IFW_IntegrationConfig__c> integrationConfigList) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        String integrationType = '';
        String status = 'Error';
        if(errorMsg.contains(Constants.READ_TIMED_OUT_ERROR_MESSAGE)) {
            if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                integrationType = LogService.QUICKBOOKS;
                status = reCheckARCRInvoiceInQB(arcrTxnRecList, null, integrationConfigList[0]);
            } else if(activeIntegrationName == 'Xero') {
                integrationType = LogService.XERO;
                String arcrAccId = (arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Accounting_Id__c') != null) ? 
                                String.valueOf(arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Accounting_Id__c')) : '';
                if(arcrAccId != null && integrationConfigList != null && integrationConfigList.size() > 0) {
                    status = reCheckARCreditInXero(arcrTxnRecList, arcrAccId, integrationConfigList);
                }
            }
        }
        if(status == 'Error') {
            logRec = new LogService().createErrorLog('COService', 'processARCRPaymentToAccounting() - exeption', errorMsg, 
                LogService.NOT_APPLICABLE, null, String.valueOf(arcrTxnRecList[0]), integrationType, false, 'Info');
        }
        return status;
    }

    private static void deleteTransactionsRelatedToARCRPayment(String activeIntegrationName, List<SObject> arcrTxnRecList, List<Log__c> logRecList) {
        if(arcrTxnRecList.size() == 0) return;
        // delete invoice created in QB
        if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
            String arcrAccId = (arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Invoice_Accounting_Id__c') != null) ? 
                                String.valueOf(arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Invoice_Accounting_Id__c')) : '';
            if(String.isNotBlank(arcrAccId)) {
                QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(arcrAccId, '0'), QBUtil.INVOICE);
            }
        }

        // delete payment record created in BP
        if(!AccessControl.ifObjectIsDeletable('CO_Deposit__c')){throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_DELETABLE);}
        if(!AccessControl.ifObjectIsDeletable('CO_Invoice_Payment__c')){throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_DELETABLE);}
        delete arcrTxnRecList;

        // create error log
        if(logRecList != null && logRecList.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', logRecList);
        }

    }

    private static String postInvoiceForARCreditPaymentInQB(List<SOBject> arcrTxnRecList, IFW_IntegrationConfig__c integrationConfigRec) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        string invAccountingGl;
        String objName = String.valueOf(arcrTxnRecList[0].getSObjectType());
        if(AccountingUtil.isNewPaymentAccountingApplicable((Date)arcrTxnRecList[0].get('Payment_Date__c')) && objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            Map<String, Category__c> categoryTypeToDefaultRecMap = AccountingUtil.getTypeToDefaultCategoryMap(new List<String>{AccountingIntegrationSettingsCtrl.CHECKOUT_CLEARING});
            if(categoryTypeToDefaultRecMap.size() == 0 || !categoryTypeToDefaultRecMap.containsKey(AccountingIntegrationSettingsCtrl.CHECKOUT_CLEARING)) throw new BlackPurlException('Checkout Clearing default category does not exists');
            invAccountingGl = categoryTypeToDefaultRecMap.get(AccountingIntegrationSettingsCtrl.CHECKOUT_CLEARING).AccountingId__c;
        } else {
            Map<String, Category__c> categoryTypeToDefaultRecMap = AccountingUtil.getTypeToDefaultCategoryMap(new List<String>{'Customer Deposits'});
            if(categoryTypeToDefaultRecMap.size() == 0 || !categoryTypeToDefaultRecMap.containsKey('Customer Deposits')) throw new BlackPurlException('Customer Deposits default category does not exists');
            invAccountingGl = categoryTypeToDefaultRecMap.get('Customer Deposits').AccountingId__c;
        }
        String invoiceReqBody = System.JSON.serialize(new QBInvoiceDTO(arcrTxnRecList[0], invAccountingGl), true);
        
        List<IFW_IntegrationConfigItem__c> ifwConfigItemList = IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, String>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id, 'Entity_Name__c' => IntegrationUtility.INVOICE});
        if(ifwConfigItemList.isEmpty()) throw new BlackpurlException('QB config is not defined');

        String status = 'Error';
        HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, ifwConfigItemList[0], invoiceReqBody, new List<customHttpHeaderWrapper>(), new Map<String, String>(), IntegrationUtility.ARCR_PAYMENT);
        
        if(response.getStatusCode() == 200) {
            QBResponseWrapper qbPostResponse = 
                (QBResponseWrapper)System.JSON.deserialize(response.getBody(), QBResponseWrapper.class);
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'AR_Credit_Invoice_Accounting_Id__c', qbPostResponse.invoice.Id);
            status = applyARCreditToInvoiceInQB(arcrTxnRecList, integrationConfigRec);
        } else {
            if(response.getBody().contains(Constants.READ_TIMED_OUT_ERROR_MESSAGE)) {
                status = reCheckARCRInvoiceInQB(arcrTxnRecList, 'Invoice', integrationConfigRec);
            }
            if(status == 'Error') {
                logRec = new LogService().createErrorLog('COService', 'applyARCreditToInvoiceInQB() - invoice',response.getBody(), 
                        String.valueOf(response.getStatusCode()), null, invoiceReqBody, LogService.QUICKBOOKS, false, 'Info');
            }
        }
        return status;
    }

    private static String applyARCreditToInvoiceInQB(List<SObject> arcrTxnRecList, IFW_IntegrationConfig__c integrationConfigRec) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        Map<String, Category__c> categoryTypeToDefaultRecMap = AccountingUtil.getTypeToDefaultCategoryMap(new List<String>{'Customer Deposits'});
        if(categoryTypeToDefaultRecMap.size() == 0 || !categoryTypeToDefaultRecMap.containsKey('Customer Deposits')) throw new BlackPurlException('Customer Deposits default category does not exists');
        
        String status = 'Error';
        String qbPaymentJSONBody = System.JSON.serialize(new QBPaymentDTO(arcrTxnRecList[0]), true);
        List<IFW_IntegrationConfigItem__c> ifwConfigItemList = IFW_SOQLUtil.getIntegrationConfigItem(new Map<String, String>{'IFW_IntegrationConfig__c' => integrationConfigRec.Id, 'Entity_Name__c' => IntegrationUtility.INVOICE_PAYMENT});
        if(ifwConfigItemList.isEmpty()) throw new BlackpurlException('QB config is not defined');

        HttpResponse response = BaseIntegration.performCallout(integrationConfigRec, ifwConfigItemList[0], qbPaymentJSONBody, new List<customHttpHeaderWrapper>(), new Map<String, String>(), IntegrationUtility.ARCR_PAYMENT);

        if(response.getStatusCode() == 200) {
            QBResponseWrapper qbPaymentPostResponse = 
                (QBResponseWrapper)System.JSON.deserialize(response.getBody(), QBResponseWrapper.class);
            arcrTxnRecList[0].put(Constants.NAMESPACE + 'AccountingIdForJournalEntry__c', qbPaymentPostResponse.Payment.Id);
            arcrTxnRecList[0].put(Constants.NAMESPACE + 'SyncTokenForJournalEntry__c', qbPaymentPostResponse.Payment.SyncToken);
            arcrTxnRecList[0].put(Constants.NAMESPACE + 'accountingLastSyncTime__c', System.now());
            arcrTxnRecList[0].put(Constants.NAMESPACE + 'AccountingResponseForJournalEntry__c', 
                            QBUtil.truncateString((qbPaymentJSONBody + '\n\n' + response.getBody()), 131072));
            
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Deposit__c')){throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_UPDATABLE);}
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c')){throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_UPDATABLE);}
            update arcrTxnRecList;
            status = 'Success';
        } else {
            if(response.getBody().contains(Constants.READ_TIMED_OUT_ERROR_MESSAGE)) {
                status = reCheckARCRInvoiceInQB(arcrTxnRecList, 'Payment', integrationConfigRec);
            }
            if(status == 'Error') {
                logRec = new LogService().createErrorLog('COService', 'applyARCreditToInvoiceInQB() - payment', response.getBody(), 
                        String.valueOf(response.getStatusCode()), null, qbPaymentJSONBody, LogService.QUICKBOOKS, false, 'Info');
            }
        }
        return status;
    }

    private static String reCheckARCRInvoiceInQB(List<SObject> arcrTxnRecList, String entityName, IFW_IntegrationConfig__c integrationConfigRec) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        // Send get request
        String docNumber = '';
        if(String.valueOf(arcrTxnRecList[0].get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c')) == AR_PAYMENT) {
            docNumber = String.valueOf(arcrTxnRecList[0].get('Name')) + '_USED';
        } else if (arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Number__c') != null) {
            docNumber = String.valueOf(arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Number__c')) + '_USED'; 
        }
        if(String.isBlank(docNumber)) {
            return 'Error';
        }
        List<String> filterConditions = new List<String>{'DocNumber =\'' + docNumber + '\''};

        QBQueryResponseWrapper.QBResponseWrapper qbGetResponse = QBCalloutManager.getData(QBUtil.INVOICE, filterConditions, integrationConfigRec);
        if(qbGetResponse != null && qbGetResponse.Invoice != null && qbGetResponse.Invoice.size() > 0) {
            if((entityName == 'Payment' || String.isBlank(entityName)) && qbGetResponse.Invoice[0].Balance == 0) { // if AR Credit Invoice status is Paid
                if(qbGetResponse.Invoice[0].LinkedTxn != null && qbGetResponse.Invoice[0].LinkedTxn.size() > 0)
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'AccountingIdForJournalEntry__c', qbGetResponse.Invoice[0].LinkedTxn[0].TxnId);
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'accountingLastSyncTime__c', System.now());
                
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Deposit__c')){throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_UPDATABLE);}
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c')){throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_UPDATABLE);}
                update arcrTxnRecList;
                return 'Success';
            } else if(entityName == 'Invoice' || String.isBlank(entityName)) {
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'AR_Credit_Invoice_Accounting_Id__c', qbGetResponse.Invoice[0].Id);
                return applyARCreditToInvoiceInQB(arcrTxnRecList, integrationConfigRec);
            }
        }
        return 'Error';
    }

    private static String applyPaymentToARCreditInXero(List<SObject> arcrTxnRecList, List<IFW_IntegrationConfig__c> configRecList) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        if(configRecList.size() == 0) throw new BlackpurlException('Xero config is not defined');
        String requestBody = system.JSON.serialize(new Map<String, List<XeroInvoicePaymentDTO>>{'Payments' => new List<XeroInvoicePaymentDTO>{new XeroInvoicePaymentDTO(arcrTxnRecList[0])}}, true);
        requestBody = requestBody != null ? requestBody.replace('"InvDate":', '"Date":') : requestBody;

        HttpResponse response = BaseIntegration.performCallout(configRecList[0], configRecList[0].IFW_IntegrationConfigItems__r[0], requestBody, new List<customHttpHeaderWrapper>(), IntegrationUtility.ARCR_PAYMENT);
        String status = 'Error';
        if(response.getStatusCode() == 200) {
            XeroResponseWrapper xeroResWrapperObj = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
            if(xeroResWrapperObj.Payments != null && !xeroResWrapperObj.Payments.isEmpty()) {
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'Xero_Accounting_Id__c', xeroResWrapperObj.Payments[0].PaymentID);
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'accountingLastSyncTime__c', System.now());
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'AccountingResponseForJournalEntry__c', (requestBody + '\n' + xeroResWrapperObj.Payments[0]).abbreviate(32768));
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Deposit__c')){throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_UPDATABLE);}
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c')){throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_UPDATABLE);}
                update arcrTxnRecList;
                status = 'Success';
            }
        } else {
            String arcrAccId = (arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Accounting_Id__c') != null) ? 
                                String.valueOf(arcrTxnRecList[0].get(Constants.NAMESPACE + 'AR_Credit_Accounting_Id__c')) : '';
            if(response.getBody().contains(Constants.READ_TIMED_OUT_ERROR_MESSAGE) && arcrAccId != null) {
                status = reCheckARCreditInXero(arcrTxnRecList, arcrAccId, configRecList);
            }
            if(status == 'Error') {
                logRec = new LogService().createErrorLog('COService', 'applyPaymentToARCreditInXero()', response.getBody(), 
                        String.valueOf(response.getStatusCode()), null, requestBody, LogService.XERO, false, 'Info');
            }
        }
        return status;
    }

    private static String reCheckARCreditInXero(List<SObject> arcrTxnRecList, String arCreditAccId, List<IFW_IntegrationConfig__c> configRecList) {
        if(arcrTxnRecList.size() == 0) return 'Error';
        if(configRecList.size() == 0) throw new BlackpurlException('Xero config is not defined');
        String whereClause = 'CreditNoteID == Guid("' + arCreditAccId + '")';
        XeroResponseWrapper responseWrapper = XeroService.getDataFromXero('Credit Note', whereClause, configRecList[0]);

        if(responseWrapper != null && responseWrapper.CreditNotes != null && responseWrapper.CreditNotes.size() > 0) {
            if(responseWrapper.CreditNotes[0].RemainingCredit == 0 && responseWrapper.CreditNotes[0].Payments != null 
                && responseWrapper.CreditNotes[0].Payments.size() > 0) { // if Credit Note status is Paid
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'AccountingIdForJournalEntry__c', responseWrapper.CreditNotes[0].Payments[0].PaymentID);
                arcrTxnRecList[0].put(Constants.NAMESPACE + 'accountingLastSyncTime__c', System.now());
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Deposit__c')){throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_UPDATABLE);}
                if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c')){throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_UPDATABLE);}
                update arcrTxnRecList;
                return 'Success';
            }
        }
        return 'Error';
    }
}
/**
 * Author: Richa Mittal
 * Since: Sept 19, 2022
 * Name: QBCalloutManager
 * Description: Apex class for containing methods related to QB API calls 
**/
public without sharing class QBCalloutManager {

    public static String redirect_URI = 'https://login.salesforce.com/apex/' + Constants.NAMESPACE + 'Quickbooks_oauth_callback';
    private static IFW_IntegrationConfig__c ifwIntegrationRec;
    
    public static QBQueryResponseWrapper.QBResponseWrapper getData(String entityType, String query, IFW_IntegrationConfig__c ifwConfigRec) {
        return (QBQueryResponseWrapper.QBResponseWrapper)getDataHandler(entityType, query, null, ifwConfigRec);
    }

    public static QBQueryResponseWrapper.QBResponseWrapper getData(String entityType, List<String> filterList, IFW_IntegrationConfig__c ifwConfigRec) {
        return getData(entityType, getQuery(entityType, filterList), ifwConfigRec);
    }

    public static QBQueryResponseWrapper.QBResponseWrapper getData(String entityType, List<String> filterList, IFW_IntegrationConfig__c ifwConfigRec, 
                                            Integer pageNumber, Integer recordsPerPage) {
        return getData(entityType, getQuery(entityType, filterList, pageNumber, recordsPerPage), ifwConfigRec);
    }

    public static QBResponseWrapper getDataByQBId(String entityType, String qbId, IFW_IntegrationConfig__c ifwConfigRec) {
        return (QBResponseWrapper)getDataHandler(entityType, null, qbId, ifwConfigRec);
    }

    public static QBReportWrapper getReportData(String conditionClause, IFW_IntegrationConfig__c ifwConfigRec) {
        return (QBReportWrapper)getDataHandler('reports', null, conditionClause, ifwConfigRec);
    }
    
    public static QBQueryResponseWrapper.QBResponseWrapper getDataAndUpdateRecords(String entityType, String query, IFW_IntegrationConfig__c ifwConfigRec) {
        try {
            QBQueryResponseWrapper.QBResponseWrapper resObj = getData(entityType, query, ifwConfigRec);
            updateRecords(ifwIntegrationRec);
            return resObj;
        } catch(Exception e) {
            updateRecords(ifwIntegrationRec);
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static QBQueryResponseWrapper.QBResponseWrapper getDataAndUpdateRecords(String entityType, List<String> filterList, IFW_IntegrationConfig__c ifwConfigRec) {
        try {
            QBQueryResponseWrapper.QBResponseWrapper resObj = getData(entityType, filterList, ifwConfigRec);
            updateRecords(ifwIntegrationRec);
            return resObj;
        } catch(Exception e) {
            updateRecords(ifwIntegrationRec);
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static QBQueryResponseWrapper.QBResponseWrapper getDataAndUpdateRecords(String entityType, List<String> filterList, IFW_IntegrationConfig__c ifwConfigRec, 
                                            Integer pageNumber, Integer recordsPerPage) {
        try {
            QBQueryResponseWrapper.QBResponseWrapper resObj = getData(entityType, filterList, ifwConfigRec, pageNumber, recordsPerPage);
            updateRecords(ifwIntegrationRec);
            return resObj;
        } catch(Exception e) {
            updateRecords(ifwIntegrationRec);
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static QBResponseWrapper getDataByQBIdAndUpdateRecords(String entityType, String qbId, IFW_IntegrationConfig__c ifwConfigRec) {
        try {
            QBResponseWrapper resObj = getDataByQBId(entityType, qbId, ifwConfigRec);
            updateRecords(ifwIntegrationRec);
            return resObj;
        } catch(Exception e) {
            updateRecords(ifwIntegrationRec);
            throw new BlackPurlException(e.getMessage());
        }
    }

    public static HttpResponse fetchAccessToken(String code, String realmId) {
        Map<String, Object> fieldsMap = new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE, 'Enabled__c' => true};
        List<IFW_IntegrationConfig__c> ifwConfigList = IFW_SOQLUtil.getIntegrationConfig(fieldsMap);
        if(ifwConfigList.size() == 0 || String.isBlank(ifwConfigList[0].Client_Id_Long__c) || String.isBlank(ifwConfigList[0].Client_Secret_Long__c)) {
            throw new BlackPurlException('Some configurations are missing.');
        }
        
        String encodedString = EncodingUtil.base64Encode(Blob.valueOf(ifwConfigList[0].Client_Id_Long__c + ':' + ifwConfigList[0].Client_Secret_Long__c));
        String endPoint = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
        String oAuthCode = code;
        
        if(GeneralConfiguration.getConfigurationByName('qb_redirect_uri') != null) {
        	redirect_URI = GeneralConfiguration.getConfigurationByName('qb_redirect_uri') + '/apex/' + Constants.NAMESPACE + 'Quickbooks_oauth_callback';
        }
        String requestBody = 'grant_type=authorization_code&code=' + oAuthCode + '&redirect_uri=' + redirect_URI;
        
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();
        httpReq.setMethod('POST');
        httpReq.setEndPoint(endPoint);
        httpReq.setHeader('Authorization' , 'Basic '+encodedString);
        httpReq.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
        httpReq.setBody(requestBody);
        return http.send(httpReq);
    }

    public static HttpResponse disconnect() {
        WebService_Log__c wsLog = new WebService_Log__c();
        wsLog.CalloutStartTime__c = double.valueOf(DateTime.now().GetTime());
        wsLog.Name = QBUtil.QUICKBOOKS_ONLINE + ' ' + String.valueOf(Datetime.now());
        Map<String, Object> fieldsMap = new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE, 'Enabled__c' => true};
        List<IFW_IntegrationConfig__c> ifwConfigList = IFW_SOQLUtil.getIntegrationConfig(fieldsMap);
        if(ifwConfigList.size() == 0) {
        	throw new BlackPurlException('IFW config does not exist');
        }
        
        String APIURL = 'https://developer.api.intuit.com/v2/oauth2/tokens/revoke?token=' + ifwConfigList[0].Refresh_Token__c;
        String encodedString = EncodingUtil.base64Encode(Blob.valueOf(ifwConfigList[0].Client_Id_Long__c + ':' + ifwConfigList[0].Client_Secret_Long__c));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(APIURL);
        req.setMethod('POST');
        req.setTimeout(BaseIntegration.DEFAULT_TIMEOUT);
        req.setHeader('Authorization' , 'Basic '+ encodedString);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        Http http = new Http();
        HttpResponse res = http.send(req);
        wsLog.IFW_IntegrationConfig__c = ifwConfigList[0].Id;
        wsLog.Callout_End_Time__c = Double.valueOf(DateTime.now().getTime());
        wslog.Response_Code__c = String.valueOf(res.getStatusCode());
        wsLog.Response_Body__c = res.getBody().abbreviate(32768);
        wslog.Status__c = res.getStatus();
        wsLog.endpoint__c = APIURL;   
        wsLog.Entity_Name__c = 'disconnect';     
        DMLUtility.insertSobjectList('WebService_Log__c', wsLog);
        return res;
    }

    public static void updateRecords(IFW_IntegrationConfig__c ifwConfigRec) {
        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigRec);
        if(BaseIntegration.webServiceLogs != null) DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
    }

    private static Object getDataHandler(String entityType, String query, String qbId, IFW_IntegrationConfig__c ifwConfigRec) {
        try {
            entityType = QBService.entityNameToEntityToQueryMap.containsKey(entityType) ? QBService.entityNameToEntityToQueryMap.get(entityType) : entityType;
            if(ifwConfigRec == null || ifwConfigRec.Id == null) ifwConfigRec = getIFWRecordWithItemForGETCallout();
            ifwIntegrationRec = ifwConfigRec;
            IFW_IntegrationConfigItem__c ifwConfigItemRec = getIFWItemRecordForGETCallout(ifwConfigRec).clone(); // cloned so that the updated end point url is not reflected in the original ifwConfigRec
            
            String entityEndPoint = String.isNotBlank(query) ? query : entityType;
            ifwConfigItemRec.Endpoint_URL__c += getUpdatedEndPointURL(entityEndPoint, qbId);
            
            Map<String, String> urlParams = (String.isBlank(query) || query.contains('reports')) ? new Map<String, String>() : new Map<String, String>{'query' => query};

            HttpResponse res = BaseIntegration.performCallout(ifwConfigRec, ifwConfigItemRec, null, new List<CustomHttpHeaderWrapper>(), urlParams);
            if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                if(String.isNotBlank(query)) {
                    QBQueryResponseWrapper response = (QBQueryResponseWrapper)System.JSON.deserialize(res.getBody(), QBQueryResponseWrapper.class);
                    if(response != null && response.QueryResponse != null) return response.QueryResponse;
                } else {
                    if(entityType == 'reports') {
                        return (QBReportWrapper)System.JSON.deserialize(res.getBody(), QBReportWrapper.class);
                    }
                    return (QBResponseWrapper)System.JSON.deserialize(res.getBody(), QBResponseWrapper.class);
                }
            } else {
                handleErrorResponse(res);
            }
        } catch(BlackPurlException bpEx) {
            throw new BlackPurlException(bpEx.getMessage());
        } catch(Exception e) {
            Log__c logRecToInsert = new LogService().createErrorLog('QBCalloutManager', 'getData()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                        null, LogService.QUICKBOOKS, false);
            DMLUtility.insertSobjectList('Log__c', logRecToInsert);
            throw new BlackPurlException(e.getMessage()); // this will be catched in the method from where this is called so log record would be inserted
        }
        return null;
    }

    private static String getQuery(String entityType, List<String> filterList) {
        return getQuery(entityType, filterList, null, null);
    }

    private static IFW_IntegrationConfig__c getIFWRecordWithItemForGETCallout() {
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
        
        if(integrationConfigList.isEmpty()) throw new BlackPurlException('IFW record for ' + QBUtil.QUICKBOOKS_ONLINE + ' doesn\'t exists');
        return integrationConfigList[0];
    }

    private static IFW_IntegrationConfigItem__c getIFWItemRecordForGETCallout(IFW_IntegrationConfig__c ifwConfigRec) {
        if(ifwConfigRec == null || ifwConfigRec.Id == null) throw new BlackPurlException('IFW record for ' + QBUtil.QUICKBOOKS_ONLINE + ' doesn\'t exists');
        List<IFW_IntegrationConfigItem__c> configItemList = ifwConfigRec.IFW_IntegrationConfigItems__r;
        if(configItemList.isEmpty()) {
            Map<String, Object> fieldsMap = new Map<String, Object>{'HTTP_Method__c' => 'GET', 'IFW_IntegrationConfig__c' => ifwConfigRec.Id};
            configItemList = IFW_SOQLUtil.getIntegrationConfigItem(fieldsMap);
        }

        if(configItemList.isEmpty()) throw new BlackPurlException('IFW config record for ' + QBUtil.QUICKBOOKS_ONLINE + ' GET API doesn\'t exists');
        return configItemList[0];
    }

    private static String getUpdatedEndPointURL(String entityEndPoint, String qbId) {
        if(String.isBlank(entityEndPoint)) return '';
        
        String endPoint = (entityEndPoint.startsWithIgnoreCase('select') ? '/query' : ('/' + entityEndPoint));
        if(String.isNotBlank(qbId)) endPoint += ('/' + qbId);
        return endPoint;
    }

    private static String getQuery(String entityType, List<String> filterList, Integer pageNumber, Integer recordsPerPage) {
        String query = 'Select ';
        query += entityTypeToFieldsToQueryMap.containsKey(entityType) ? entityTypeToFieldsToQueryMap.get(entityType) : '*';
        query += ' from ' + entityType; 
        
        String whereClause = '';
        for(String filterCondition : filterList) {
            whereClause += ((whereClause.length() > 0) ? ' AND ' : ' WHERE ') + filterCondition ;
        }
        query += whereClause;
        
        if(pageNumber != null && pageNumber != 0) {
            query += ' STARTPOSITION '+ ((pageNumber * (recordsPerPage != null ? recordsPerPage : 100)) + 1);
        }
        return EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
    }

    // This method return query string for given entity and its filter 
    public static String getRecordsFilterQuery(String entityType, List<String> filterConditionList, Integer pageNumber, Integer recordsPerPage) {
        String query = 'Select ';
        query += entityTypeToFieldsToQueryMap.containsKey(entityType) ? entityTypeToFieldsToQueryMap.get(entityType) : '*';
        query += ' from ' + entityType; 
        
        String whereClause = '';
        for(String filterCondition : filterConditionList) {
            whereClause += ((whereClause.length() > 0) ? ' AND ' : ' WHERE ') + filterCondition ;
        }
        query += whereClause;
        
        if(pageNumber != null && pageNumber != 0){
            query += ' STARTPOSITION '+ ((pageNumber * (recordsPerPage != null ? recordsPerPage : 100)) + 1);
        }

        return EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
    }
    
    private static void handleErrorResponse(HttpResponse response) {
        String responseString = response.getBody();
        try {
            responseString = parseXML(response);
        } catch(Exception e) {
            // if response is not in the XML format it would be handled here and responseString will have original response body
            if(responseString.contains('invalid_grant')) {
                responseString = 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.';
            }
        }
        throw new BlackPurlException(responseString);
    }

    private static String parseXML(HttpResponse response) {
        Dom.Document doc = response.getBodyDocument();
        Dom.XMLNode address = doc.getRootElement();
        String responseStatus = '';
        for(DOM.XMLNode xmlnodeobj : address.getChildElements()){       
            for(DOM.XMLNode xmlnodeobj1 : xmlnodeobj.getChildElements()){     
                for(DOM.XMLNode xmlnodeobj2 : xmlnodeobj1.getChildElements()){   
                    if(xmlnodeobj2.getName() == 'Message'){
                        responseStatus = xmlnodeobj2.getText();
                        List<String> messageList = responseStatus.split(';');
                        if(messageList.size() > 1){
                            responseStatus = messageList[1];
                            if(messageList[1].contains('errorCode=')){
                                responseStatus = messageList[1].replace('errorCode=', '');
                            }
                        }
                    }   
                }   
            }  
        }
        return responseStatus;
    }

    private static Map<String, String> entityTypeToFieldsToQueryMap = new Map<String, String>{
        'Customer' => String.join(new List<String>{ 'Id', 'SyncToken', 'DisplayName'},', '),
        'Vendor' => String.join(new List<String>{ 'Id', 'SyncToken', 'Active', 'DisplayName'},', '),
        'TaxCode' => String.join(new List<String>{ 'Id', 'SyncToken', 'Name', 'Active', 'Taxable', 'SalesTaxRateList', 'PurchaseTaxRateList'},', '),
        'TaxRate' => String.join(new List<String>{ 'Id', 'SyncToken', 'Name', 'Active', 'RateValue', 'AgencyRef'},', '),
        'Invoice' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'DueDate', 'TotalAmt', 'Balance', 'LinkedTxn', 'SyncToken'},', '),
        'CreditMemo' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'DueDate', 'TotalAmt', 'RemainingCredit', 'SyncToken'},', '),
        'Payment' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'TotalAmt', 'UnappliedAmt', 'PaymentRefNum', 'SyncToken', 'PrivateNote'},', '),
        'JournalEntry' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'PrivateNote', 'SyncToken'},', '),
        'Item' => String.join(new List<String>{ 'Id', 'SyncToken', 'Name','Description','Active','Type'},', '),
        'Account' => String.join(new List<String>{'Id', 'Name', 'AcctNum', 'AccountType', 'Active', 'AccountSubType', 'TaxCodeRef'},', ')
    };
}
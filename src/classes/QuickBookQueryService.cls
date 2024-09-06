/**
 * Author: Rajat Jain
 * Since: Sept 19, 2018
 * Name: QuickBookQueryService
 * Description: Apex class to handle all operations related to QuickBook Query.
**/
public without sharing class QuickBookQueryService {
	public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
	
    public static String validateUniqueEntityValue(String entityType,String entityName, String entityValue, String operator) {
        String query = 'Select ' +  entityName + ' from ' + entityType + ' where ' + entityName + ' ' + operator + ' ' + entityValue ;
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        //HttpResponse res = QuickbookConnector.getRequestFromQuickBooks('query?query='+query, null);
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
		HttpResponse res = responseObj.Response;
		refreshToken = responseObj.RefreshToken;
		refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        Set<String> invoiceNumberSet = new Set<String>();
        if(res.getStatusCode() == 200){ 
            String resultJson = res.getBody();
            QueryResponseWrapper response = (QueryResponseWrapper)System.JSON.deserialize(resultJson, QueryResponseWrapper.class);
            if(response != null && response.QueryResponse != null && ((response.QueryResponse.TotalCount != null && response.QueryResponse.TotalCount > 0) || (response.QueryResponse.maxResults != null && response.QueryResponse.maxResults > 0))) {
            	if(operator == '=') {
            		if(entityType.equalsIgnoreCase('salesreceipt') || entityType.equalsIgnoreCase('refundreceipt') || entityType.equalsIgnoreCase('creditmemo') || entityType.equalsIgnoreCase('invoice')) {
            			return system.JSON.serialize(response);
            		}
            		return 'Duplicate';
            	} else {
            		if(entityType == 'Bill') {
            			for(QuickBooksEntity entity : response.QueryResponse.Bill ) {
		            		invoiceNumberSet.add(entity.DocNumber);
		            	}
            		}
            	}
            } else {
            	return 'Success';
            }
        } else {
          	return 'Error QuickBooks Online';
          	new LogService().createErrorLog('QuickBookQueryService', 'validateUniqueEntityValue()', res.getBody(), res.getStatusCode(), null, 
                                              entityName + LogService.METHOD_PARAM_SEPERATOR + entityValue, LogService.QUICKBOOKS, false);
        }
        return system.JSON.serialize(invoiceNumberSet);
    }

    public static ResponseQuickBooks getRecordsByFieldName(String entityType,String filterFieldName, String filterFieldValue, String operator, Integer pageNumber, Integer recordsPerPage) {
        String query = 'Select ';
        query += entityTypeToFieldsToQueryMap.containsKey(entityType) ? entityTypeToFieldsToQueryMap.get(entityType) : '*';
        query += ' from ' + entityType; 
        Integer pageSize = recordsPerPage != null ? recordsPerPage : 100;
        if(String.isNotBlank(filterFieldName)) {
           query += ' where ' + filterFieldName + ' ' + operator + filterFieldValue ;
        }
        if(pageNumber != null && pageNumber != 0){
            query += ' STARTPOSITION '+ ((pageNumber * pageSize) + 1);
        }
        
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        //HttpResponse res = QuickbookConnector.getRequestFromQuickBooks('query?query='+query, null);
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
		HttpResponse res = responseObj.Response;
		refreshToken = responseObj.RefreshToken;
		refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        if(res.getStatusCode() == 200){ 
            String resultJson = res.getBody();
            QueryResponseWrapper response = (QueryResponseWrapper)System.JSON.deserialize(resultJson, QueryResponseWrapper.class);
            if(response != null && response.QueryResponse != null && ((response.QueryResponse.TotalCount != null && response.QueryResponse.TotalCount > 0) || (response.QueryResponse.maxResults != null && response.QueryResponse.maxResults > 0))) {
                return response.QueryResponse;
            } else {
                return new ResponseQuickBooks();
            }
        } else {
            new LogService().createErrorLog('QuickBookQueryService', 'getRecordsByFieldName()', res.getBody(), res.getStatusCode(), null, 
                                              filterFieldName + LogService.METHOD_PARAM_SEPERATOR + filterFieldValue, LogService.QUICKBOOKS, false);
            return null;                                 
        }
    }
    
    public static ResponseQuickBooks getRecordsByFilter(String entityType, List<String> filterConditionList) {
        String query = 'Select ';
        query += entityTypeToFieldsToQueryMap.containsKey(entityType) ? entityTypeToFieldsToQueryMap.get(entityType) : '*';
        query += ' from ' + entityType; 
        
        if(filterConditionList != null && filterConditionList.size() > 0) {
        	String whereClause = '';
        	for(String filterCondition : filterConditionList) {
        		whereClause += ((whereClause.length() > 0) ? ' AND ' : ' WHERE ') + filterCondition ;
        	}
        	query += whereClause;
        }
        
        //query='Select Id, DocNumber, TxnDate, DueDate, TotalAmt, Balance from Invoice WHERE customerref = \'228\' AND balance != \'0\'';
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
     
        //HttpResponse res = QuickbookConnector.getRequestFromQuickBooks('query?query='+query, null);
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
		HttpResponse res = responseObj.Response;
		refreshToken = responseObj.RefreshToken;
		refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        if(res.getStatusCode() == 200) { 
            String resultJson = res.getBody();
            
            QueryResponseWrapper response = (QueryResponseWrapper)System.JSON.deserialize(resultJson, QueryResponseWrapper.class);
            if(response != null && response.QueryResponse != null && ((response.QueryResponse.TotalCount != null && response.QueryResponse.TotalCount > 0) || (response.QueryResponse.maxResults != null && response.QueryResponse.maxResults > 0))) {
                return response.QueryResponse;
            } else {
                return new ResponseQuickBooks();
            }
        } else {
            new LogService().createErrorLog('QuickBookQueryService', 'getRecordsByFieldName()', res.getBody(), res.getStatusCode(), null, 
                                              query, LogService.QUICKBOOKS, false);
            return null;                                 
        }
    }
    
    public static Map<String,String> entityTypeToFieldsToQueryMap = new Map<String,String>{
                                    'Customer' => String.join(new List<String>{ 'Id', 'SyncToken', 'DisplayName'},', '),
                                    'Vendor' => String.join(new List<String>{ 'Id', 'SyncToken', 'Active', 'DisplayName'},', '),
                                    'TaxCode' => String.join(new List<String>{ 'Id', 'SyncToken', 'Name', 'Active', 'Taxable', 'SalesTaxRateList', 'PurchaseTaxRateList'},', '),
                                    'TaxRate' => String.join(new List<String>{ 'Id', 'SyncToken', 'Name', 'Active', 'RateValue', 'AgencyRef'},', '),
                                    'Invoice' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'DueDate', 'TotalAmt', 'Balance', 'LinkedTxn'},', '),
                                    'CreditMemo' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'DueDate', 'TotalAmt', 'RemainingCredit'},', '),
                                    'Payment' => String.join(new List<String>{ 'Id', 'DocNumber', 'TxnDate', 'TotalAmt', 'UnappliedAmt', 'PaymentRefNum'},', ')
                                    };
    public class QueryResponseWrapper {
    	public ResponseQuickBooks QueryResponse;
    }
    public class ResponseQuickBooks {
        public List<QuickBooksEntity> Bill;
        public List<QuickBooksEntity> VendorCredit;
        public List<QuickBooksEntity> SalesReceipt;
        public List<QuickBooksEntity> RefundReceipt;
        public List<QuickBooksEntity> Invoice;
        public List<QuickBooksEntity> CreditMemo;
        public List<QuickBooksEntity> Payment;
        public List<CustomerService.QuickBooksCustomer> Customer;
        public List<VendorService.QuickBooksVendor> Vendor;
        public List<QBTaxCodeWrapper> TaxCode;
        public List<QBTaxRateWrapper> TaxRate;
        public Decimal TotalCount;
        public Decimal maxResults;
     }
     
    public class QuickBooksEntity {
        public String Id;
        public String SyncToken;
        public String DocNumber;
        public String TxnDate;
        public String DueDate;
        public String TotalAmt;
        public String Balance;
        public String RemainingCredit;
        public String UnappliedAmt;
        public String PrivateNote;
        public String PaymentRefNum;
        public List<QuickBooksLinkedTxn> LinkedTxn;
    }

    public class QuickBooksLinkedTxn {
        public String TxnId;
        public String TxnType;
    }
}
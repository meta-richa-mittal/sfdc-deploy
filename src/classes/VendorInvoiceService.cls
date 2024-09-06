/**
 * Author: Pooja Khandelwal
 * Since: Jan. 6, 2017
 * Name: VendorInvoiceService
 * Description: Service Class for Vendor Invoice (QB Integration)
**/
public without sharing class VendorInvoiceService {
    
    public static Boolean isSyncRecordContainsNonTaxableItem; 
    public static String syncingObjectType = '';
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncVIHeaders(Set<Id> VIHeaderIds){
        AccSync_VendorInvoice_Batch.runVIHeadersForSync(VIHeaderIds, 10);
    } 
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingVendorInvoice vendorInvoiceRecord, List<Vendor_Invoicing_Header__c> VIHeaderListToUpdate){
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            errorLogToInsert = syncToQuickBooks(vendorInvoiceRecord, VIHeaderListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    } 

    public static List<Log__c> syncToQuickBooks(AccountingVendorInvoice vendorInvoiceRecord, List<Vendor_Invoicing_Header__c> VIHeaderListToUpdate){
        Vendor_Invoicing_Header__c VIHeader = new Vendor_Invoicing_Header__c();
        VIHeader.Id = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderId;
        isSyncRecordContainsNonTaxableItem = false;
        List<Log__c> errorLogList = new List<Log__c>(); 
        try{
        	if(vendorInvoiceRecord.AccountingVIHeaderRec.TotalAmt < 0) {
        		syncingObjectType = QBUtil.VENDOR_CREDIT;
        	} else {
        		syncingObjectType = QBUtil.BILL;
        	}
            if(vendorInvoiceRecord.AccountingVIHeaderRec.SyncToken != null){
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks(syncingObjectType, vendorInvoiceRecord.AccountingVIHeaderRec.AccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB(syncingObjectType, vendorInvoiceRecord.AccountingVIHeaderRec.AccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    ResponseQuickBooksVendorInvoice vendorInvoice = (ResponseQuickBooksVendorInvoice)System.JSON.deserialize(getResponse.getBody(), ResponseQuickBooksVendorInvoice.class);
                    if(syncingObjectType == QBUtil.BILL) {
                    vendorInvoiceRecord.AccountingVIHeaderRec.SyncToken = vendorInvoice.Bill.SyncToken;
                } else {
                    	vendorInvoiceRecord.AccountingVIHeaderRec.SyncToken = vendorInvoice.VendorCredit.SyncToken;
                    }
                } else {
                	errorLogList.add(new LogService().createErrorLog('VendorInvoiceService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              vendorInvoiceRecord + LogService.METHOD_PARAM_SEPERATOR + VIHeaderListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            String VendorInvoiceJSONBody;
            if(syncingObjectType == QBUtil.BILL) {
            	QBVendorBillDTO QB_VI = new QBVendorBillDTO(vendorInvoiceRecord);
            	if(!Test.isRunningTest()) {
	                QB_VI.DueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate, 
	                                                                            vendorInvoiceRecord.AccountingVIHeaderRec.VendorAccountingId);
	                refreshToken = QBInvoiceDueDateService.refreshToken;
					refreshTokenExpiresIn = QBInvoiceDueDateService.refreshTokenExpiresIn;
	            } else {
	                QB_VI.DueDate = QB_VI.TxnDate;
	            }
	            VendorInvoiceJSONBody = system.JSON.serialize(QB_VI);
            } else {
            	VendorInvoiceJSONBody = system.JSON.serialize(new QBVendorCreditDTO(vendorInvoiceRecord));
            }
            
            
            system.debug('*************');
            system.debug('Richa'+ VendorInvoiceJSONBody);
            String response = VendorInvoiceJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks(syncingObjectType, VendorInvoiceJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB(syncingObjectType, VendorInvoiceJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            System.debug(res);
            if(res.getStatusCode() == 200){ 
                String resParams = res.getBody();
                ResponseQuickBooksVendorInvoice VendorInvoicePostResponse = (ResponseQuickBooksVendorInvoice)System.JSON.deserialize(resParams, ResponseQuickBooksVendorInvoice.class);
                if(syncingObjectType == QBUtil.BILL) {
                VIHeader.AccountingId__c = VendorInvoicePostResponse.Bill.Id;
                VIHeader.SyncToken__c = VendorInvoicePostResponse.Bill.SyncToken;
                } else {
                	VIHeader.AccountingId__c = VendorInvoicePostResponse.VendorCredit.Id;
                	VIHeader.SyncToken__c = VendorInvoicePostResponse.VendorCredit.SyncToken;
                }
                
                response += '\n\n'+resParams; 
                VIHeader.availForQBSync__c = false;
                VIHeader.accountingLastSyncTime__c = System.now(); 
            }else{
                response += '\n\n'+res.getBody();
                response += '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('VendorInvoiceService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                              vendorInvoiceRecord + LogService.METHOD_PARAM_SEPERATOR + VIHeaderListToUpdate, LogService.QUICKBOOKS, false));
            }
            VIHeader.AccountingResponse__c = QBUtil.truncateString(response, 131072);
        }catch(Exception e){
            VIHeader.availForQBSync__c = true;
            VIHeader.AccountingResponse__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('VendorInvoiceService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              vendorInvoiceRecord + LogService.METHOD_PARAM_SEPERATOR + VIHeaderListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(VIHeaderListToUpdate.size() > QBUtil.MAX_RECORDS_UPDATE_LIMIT){
            AccSync_VendorInvoice_Batch.updateVIHeaders(VIHeaderListToUpdate);
            VIHeaderListToUpdate = new List<Vendor_Invoicing_Header__c>();
        }
        VIHeaderListToUpdate.add(VIHeader); 
        return errorLogList;
    }

     public class ResponseQuickBooksVendorInvoice {
        public QBVendorBillDTO Bill;
        public QBVendorCreditDTO VendorCredit;
     }
}
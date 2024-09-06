/** 
* Author: Nidhi Sharma
* Since: Feb 16, 2022 
* Name: PreferredPaymentService 
* Description: Apex class which contains all service methods related to preferred payment.
**/
public without sharing class PreferredPaymentService {
	
	public static final String PREFERRED_PAYMENTS = 'Preferred Payments';
	
    public static List<PaymentTerminalWrapper> getAllActivePaymentTerminals() {
        List<PaymentTerminalWrapper> terminals = new List<PaymentTerminalWrapper>();
        String query = 'Select Id, Nickname__c, Preferred_Payment_Id__c FROM Payment_Terminal__c Where Status__c = \'Active\' AND Preferred_Payment_Id__c != null';
        for(Payment_Terminal__c terminalRec : (List<Payment_Terminal__c>)SOQLUtility.getQueryResults('Payment_Terminal__c', query)) {
            terminals.add(new PaymentTerminalWrapper(terminalRec));
        }
        return terminals;
    }
    
    public static ResponseWrapper saleTransaction(PaymentDetail paymentDetailObj) {
        paymentDetailObj.Amount = (paymentDetailObj.Amount != null && paymentDetailObj.Amount < 0) ? paymentDetailObj.Amount*-1 : paymentDetailObj.Amount;
        ResponseWrapper responseObj;
        try{
            paymentDetailObj.TxnId = PreferredPaymentIntegrationService.saleTransaction(paymentDetailObj);
            responseObj = new ResponseWrapper('Success', paymentDetailObj.TxnId);
        } catch(Exception e) {
            paymentDetailObj.APIErrorMsg = e.getMessage();
            responseObj = new ResponseWrapper('Error', paymentDetailObj.APIErrorMsg);
        }
        PreferredPaymentIntegrationService.updateValues();
        return responseObj;
    }


    //This is a payment of -ve amount, i.e. Refund in BP
    public static ResponseWrapper creditTransaction(PaymentDetail paymentDetailObj) {
        ResponseWrapper responseObj;
        try {
            paymentDetailObj.TxnId = PreferredPaymentIntegrationService.creditTransaction(paymentDetailObj);
            responseObj = new ResponseWrapper('Success', paymentDetailObj.TxnId);
        } catch(Exception e) {
            responseObj = new ResponseWrapper('Error', e.getMessage());
        }
        PreferredPaymentIntegrationService.updateValues();
        return responseObj;
    }

    //This is a reversal of existing payment in BP
    public static ResponseWrapper refundTransaction(String txnId, Decimal amount) {
        PaymentDetail paymentDetailObj = new PaymentDetail();
        paymentDetailObj.TxnId = txnId;
        paymentDetailObj.Amount = (amount != null && amount < 0) ? amount*-1 : amount;
        ResponseWrapper responseObj;
        try {
            PreferredPaymentIntegrationService.refundTransaction(paymentDetailObj);
            responseObj = new ResponseWrapper('Success', 'Transaction reverted successfully.');
        } catch(Exception e) {
            paymentDetailObj.APIErrorMsg = e.getMessage();
            responseObj = voidTransaction(paymentDetailObj);
        }
        PreferredPaymentIntegrationService.updateValues();
        return responseObj;
    }

    public static ResponseWrapper voidTransaction(PaymentDetail paymentDetailObj) {
        ResponseWrapper responseObj;
        try {
            PreferredPaymentIntegrationService.voidTransaction(paymentDetailObj);
            responseObj = new ResponseWrapper('Success', 'Transaction aborted manually.');
        } catch(Exception e) {
            responseObj = new ResponseWrapper('Error', e.getMessage());
        }
        return responseObj;
    }

    public static String getPublicKey() {
        IFW_IntegrationConfig__c parent = IntegrationServiceFactory.getIFWConfigByIntegrationName(PreferredPaymentIntegrationService.integrationName);
        return parent != null ? parent.Public_Key__c : '';
    }

    public static Decimal getRefundMaxCreditAmount() {
        List<Configuration_List__c> maxCreditAmountConfigList = [Select Value__c From Configuration_List__c Where Name = 'Max Credit Amount' Limit 1];
        if(maxCreditAmountConfigList.size() > 0) {
            try {
                return decimal.valueOf(maxCreditAmountConfigList[0].Value__c);
            } catch (Exception e) {
                return 0;
            }
        }
        return 0;
    }

    public class PaymentDetail {
        public String TerminalId;
        public Decimal Amount;
        public String TxnId;
        public String APIErrorMsg;
        public String Token;
    }
}
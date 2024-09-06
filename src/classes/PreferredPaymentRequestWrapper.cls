/**
 * Author: Nidhi Sharma
 * Since: Feb 02, 2022
 * Name: PreferredPaymentRequestWrapper
 * Description: Preferred payment integration request wrappper classes.
**/
public without sharing class PreferredPaymentRequestWrapper {
    
    //START : sale and Credit Payload
    public class ProcessPaymentWrapper {
        public PaymentWrapper payment;
        public AmountWrapper amount;

        public ProcessPaymentWrapper(PreferredPaymentService.PaymentDetail paymentDetailObj) {
            this.payment = new PaymentWrapper(paymentDetailObj.TerminalId, paymentDetailObj.Token);
            this.amount = new AmountWrapper(paymentDetailObj.Amount);
        }
    }

    public class PaymentWrapper {
        public TerminalWrapper terminal;
        public String token;

        public PaymentWrapper(String terminalId, String token) {
            if(String.isNotBlank(terminalId) && String.isBlank(token)) this.terminal = new TerminalWrapper(terminalId);
            if(String.isNotBlank(token)) this.token = token;
        }
    }

    public class TerminalWrapper {
        public String id;

        public TerminalWrapper(String terminalId) {
            this.id = terminalId;
        }
    }

    public class AmountWrapper {
        public Decimal value;

        public AmountWrapper(Decimal amount) {
            this.value = amount;
        }
    }
    //END : sale and Credit Payload

    public class VoidTransactionWrapper {
        public String transaction_id;
        public String reason;

        public VoidTransactionWrapper(PreferredPaymentService.PaymentDetail paymentDetailObj) {
            this.transaction_id = paymentDetailObj.TxnId;
            this.reason = paymentDetailObj.APIErrorMsg;
        }
    }

    public class RefundTransactionWrapper {
        public String transaction_id;
        public Decimal amount;

        public RefundTransactionWrapper(PreferredPaymentService.PaymentDetail paymentDetailObj) {
            this.transaction_id = paymentDetailObj.TxnId;
            this.amount = paymentDetailObj.Amount;
        }
    }
}
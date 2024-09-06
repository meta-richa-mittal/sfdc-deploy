/**
 * Author: Nidhi Sharma
 * Since: Feb 02, 2022
 * Name: PreferredPaymentResponseWrapper
 * Description: Preferred payment integration response wrappper class.
**/
public without sharing class PreferredPaymentResponseWrapper {

    public List<Terminal> terminals;
    public PaymentResponseWrapper authorizePaymentObj;
    
    public class Terminal {
        public String id;
        public String make;
        public String model;
        public String serial_number;
        public String nickname;
        public String status;
    }
    
    public class PaymentResponseWrapper {
        public String transaction_id;
        public String auth_code;
        public String response_code;
        public String response_text;
        public String latency;
        public MetadataWrapper metadata;
        public String request_id;
        public List<ErrorWrapper> errors;
    }

    public class MetadataWrapper {
        public String somestuff;
    }

    public class ErrorWrapper {
        public String type;
        public String message;
    }
}
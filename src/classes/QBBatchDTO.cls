public class QBBatchDTO {

    public List<BatchItemRequest> BatchItemRequest;
    public List<BatchItemResponse> BatchItemResponse;

    public class BatchItemRequest {
        public QBCustomerDTO Customer;
        public QBVendorDTO Vendor;
        public String operation;
        public String bId;
       
        public BatchItemRequest(Account accRec, String operation, String entityName) {
            this.bId = accRec.Id;
            this.operation = operation;
            if(entityName == IntegrationUtility.BATCH_CUSTOMER) {
                this.Customer = new QBCustomerDTO(new AccountingCustomer(accRec));
                this.Customer.SFId = null;
            } else if(entityName == IntegrationUtility.BATCH_VENDOR) {
                this.Vendor = new QBVendorDTO(new AccountingVendor(accRec));
                this.Vendor.SFId = null;
            }
        }
    }

    public class BatchItemResponse {
        public QBCustomerDTO Customer;
        public QBVendorDTO Vendor;
        public FaultWrapper Fault;
        public String bId;
    }

    public class FaultWrapper {
        public List<ErrorWrapper> Error;
        public String type;
        public String bId;
    }

    public class ErrorWrapper {
        public String Message;
        public String Detail;
        public String code;
    }
}
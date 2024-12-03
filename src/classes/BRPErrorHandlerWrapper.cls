public class BRPErrorHandlerWrapper {
    public String status;
    public String id;
    public String title;
    public BRPErrorMetaWrapper meta;

    public class BRPErrorMetaWrapper {
        public String service;
        public String detail;
        public BRPErrorPayloadWrapper payload;
    }

    public class BRPErrorPayloadWrapper {
        public List<BRPErrorDetailsWrapper> details;
        public List<BRPErrorDetailsWrapper> errors;
    }

    public class BRPErrorDetailsWrapper {
        public String message;
        public String title;
        public String code;
    }
}
public class BRPErrorWrapper {
    public String status;
    public String id;
    public String title;
    public ErrorMetaWrapper meta;

    public class ErrorMetaWrapper {
        public String service;
        public String detail;
        public ErrorPayloadWrapper payload;
    }

    public class ErrorPayloadWrapper {
        public List<ErrorDetailsWrapper> details;
        public List<ErrorDetailsWrapper> errors;
    }

    public class ErrorDetailsWrapper {
        public String message;
        public String title;
        public String code;
    }
}
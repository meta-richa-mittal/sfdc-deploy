public without sharing class WebhookWrapper {
    public Result result;
    public Meta meta;
    
    public class Result {
        public Data data;
        public List<Error> errors;
    }

    public class Error {
        public String message;
    }

    public class Data {
        public SOQLToSFTP soqlToSftp;
        public SOQLToFTP soqlToFtp;
        public SOMCreateJob somCreateJob;
    }
    
    public class SOQLToSFTP {
        public String status;
        public String filepath;
    }

    public class SOQLToFTP {
        public String status;
        public String filepath;
    }

    public class SOMCreateJob {
        public String invFileName;
        public String psiFileName;
        public String pooFileName;
        public Boolean includeAllSubmittedClaimItems;
        public String invStatus;
        public String psiStatus;
        public String pooStatus;
    }
    
    public class Meta {
        public String createdDate;
        public String finishedDate;
        public String jobId;
        public String jobName;
        public String vendorMasterId;
    }
}
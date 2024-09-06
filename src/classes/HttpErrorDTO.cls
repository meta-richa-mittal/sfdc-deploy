public without sharing class HttpErrorDTO {
    public String ErrorNumber {get; set;}
    public String Type {get; set;}
    public String Message {get; set;}

    public class QBErrorDTO {
        public QBFaultDTO Fault;
    }

    public class QBFaultDTO {
        public List<QBErrorMsgDTO> Error;
    }

    public class QBErrorMsgDTO {
        public String code;
        public String Detail;
    }
}
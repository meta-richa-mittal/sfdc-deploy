public without sharing class BRPResponseWrapper {
    public AcknowledgeWrapper AcknowledgePartsInventory;
    public AcknowledgeWrapper AcknowledgePartsInvoice;
    public AcknowledgeWrapper AcknowledgeRepairOrder;
    public AcknowledgeWrapper AcknowledgeRetailDeliveryReporting;
    public ConfirmBODWrapper ConfirmBOD;
    public BRPShowPartsMasterWrapper ShowPartsMaster;
    public AcknowledgeWrapper AcknowledgePartsOrder;
    
    public class AcknowledgeWrapper {
        public ApplicationArea ApplicationArea;
        public AcknowledgePartsInventoryDataArea AcknowledgePartsInventoryDataArea;
        public BRPPartsOrderingDTO.BRPAcknowledgePartsOrderDataAreaDTO AcknowledgePartsOrderDataArea;
    }
    
    public class ConfirmBODWrapper {
        public ApplicationArea ApplicationArea;
        public ConfirmBODDataArea ConfirmBODDataArea;
    }
    
    public class ApplicationArea {
        public Sender Sender;
        public String CreationDateTime;
        public String BODID;
        public Destination Destination;
    }
    
    public class Sender {
        public String ComponentID;
        public String ReferenceID;
        public String CreatorNameCode;
        public String SenderNameCode;
        public String SystemVersion;
        public String ServiceID;
    }
    
    public class Destination {
        public String DestinationNameCode;
        public String DealerNumberID;
    }
    
    public class AcknowledgePartsInventoryDataArea {
        public String Acknowledge;
    }
    
    public class ConfirmBODDataArea {
        public String Confirm;
        public BOD BOD;
    }
    
    public class BOD {
        public BODFailureMessage BODFailureMessage;
    }
    
    public class BODFailureMessage {
        public List<ErrorProcessMessage> ErrorProcessMessageList;
        public ErrorProcessMessage ErrorProcessMessage;
    }
    
    public class ErrorProcessMessage {
        public String Description;
        public String Type;
    }
    
    public class BRPFaultJSONWrapper {
    	public FaultWrapper fault;
    }
    
    public class FaultWrapper {
    	public String faultstring;
    	public DetailWrapper detail;
    }
    
    public class DetailWrapper {
    	public String errorcode;
    }
}
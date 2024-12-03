public without sharing class BRPPartsOrderingDTO {
	public ProcessPartsOrder ProcessPartsOrder;
	
	public class ProcessPartsOrder {
		public ProcessPartsOrderDataArea ProcessPartsOrderDataArea;
	}
	
	public class ProcessPartsOrderDataArea {
		public PartsOrder PartsOrder;
	}
	
    public class BRPAcknowledgePartsOrderDataAreaDTO {
	    public PartsOrder PartsOrder;
	}
	
	public class PartsOrder {
    	public PartsOrderHeader PartsOrderHeader;
    	public List<PartsOrderLine> PartsOrderLine;
    }
    
    public class PartsOrderHeader {
    	public List<AcknowledgementStatus> AcknowledgementStatus;
    }
    
    public class PartsOrderLine {
    	public String LineNumberString;
    	public String ItemIdDescription;
    	public List<AcknowledgementStatus> AcknowledgementStatus;
    	public ItemIdentificationGroup ItemIdentificationGroup;
    	public List<LineSplitPartsOrderLine> LineSplitPartsOrderLine;
    }
    
    public class LineSplitPartsOrderLine {
    	public String LineNumberString;
    	public List<AcknowledgementStatus> AcknowledgementStatus;
    }
    
    public class AcknowledgementStatus {
    	public String StatusTypeCode;
    	public String StatusCode;
    	public String StatusText;
    }
    
    public class ItemIdentificationGroup {
    	public List<ItemIdentification> ItemIdentification;
    }
    
    public class ItemIdentification {
    	public String ItemID;
		public String AgencyRoleCode;
    }
    
    public class ErrorMessage {
    	public String partNumber;
    	public String errorType;
    	public String errorText;
    	public String statusTypeCode;
    	
    	public ErrorMessage(String partNumber, String errorType, String errorText, String statusTypeCode) {
    		this.partNumber = partNumber;
    		this.errorType = errorType;
    		this.errorText = errorText;
    		this.statusTypeCode = statusTypeCode;
    	}
    }
}
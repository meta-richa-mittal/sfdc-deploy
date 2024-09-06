/**
 * Author: Manoj Sharma
 * Since: July 12, 2021
 * Name: BRPShowPartOrderResponseWrapper
 * Description: Wrapper class for BRP GetPartsOrder json creation for part order header only
**/
public without sharing class BRPShowPartOrderResponseWrapper {

    public ShowPartsOrder ShowPartsOrder;

    public class ShowPartsOrder {
        public ShowPartsOrderDataArea ShowPartsOrderDataArea;
    }
   
    public class ShowPartsOrderDataArea {
        public List<PartsOrder> PartsOrder;
    }

    public class PartsOrder {
        public PartsOrderHeader PartsOrderHeader;
    }

    public class PartsOrderHeader {
        public DocumentReferenceIdentificationGroup DocumentReferenceIdentificationGroup;
        public String OrderTypeCode;
        public List<AcknowledgementStatus> AcknowledgementStatus;
        public String RequestedShipDate;
    }

    public class DocumentReferenceIdentificationGroup {
        public List<DocumentIdentification> DocumentIdentification;
    }
  
    public class DocumentIdentification {
        public String DocumentID;
        public String AgencyRoleCode;
    }

    public class AcknowledgementStatus {
        public String StatusTypeCode;
        public String StatusText;
    }
}
/**
 * Author: Manoj Sharma
 * Since: July 12, 2021
 * Name: BRPShowPartOrderLinesResponseWrapper
 * Description: Wrapper class for BRP GetPartsOrder json creation for part order line items only
**/
public without sharing class BRPShowPartOrderLinesResponseWrapper {
    public ShowPartsOrder ShowPartsOrder;

    public class ShowPartsOrder {
        public ShowPartsOrderDataArea ShowPartsOrderDataArea;
    }

    public class ShowPartsOrderDataArea {
        public List<PartsOrder> PartsOrder;
    }

    public class PartsOrder {
        public List<PartsOrderLine> PartsOrderLine;
    }

    public class PartsOrderLine {
        public String ItemIdDescription;
        public List<AcknowledgementStatus> AcknowledgementStatus;
        public ItemIdentificationGroup ItemIdentificationGroup;
    }

    public class AcknowledgementStatus {
        public String StatusTypeCode;
        public String StatusText;
    }

    public class ItemIdentificationGroup {
        public List<ItemIdentification> ItemIdentification;
    }
  
    public class ItemIdentification {
        public String ItemID;
        public String AgencyRoleCode;
    }
}

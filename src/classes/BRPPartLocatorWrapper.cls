public without sharing class BRPPartLocatorWrapper {
    
    public String PartNumber;
    public String PartDescription;
    public String ManufacturerAvailableQty;
    public String AvailabiltyText;
    public String ManufacturerPhoneNumber;
    public List<PartInfoFromDealer> DealerNearList;
    public List<PartInfoFromDealer> AllDealerList;
    public List<PartInfoFromDealer> AllSupplierList;
    
    public BRPPartLocatorWrapper() {}

    public BRPPartLocatorWrapper(String partNumber, String description) {
        setDefaultValues(partNumber, description);
    }
    
    public BRPPartLocatorWrapper(String partNumber, String description, String availableQty, String availabiltyText, String phoneNumber) {
        setDefaultValues(partNumber, description);
        this.ManufacturerAvailableQty = availableQty;
        this.AvailabiltyText = availabiltyText;
        this.ManufacturerPhoneNumber = phoneNumber;
    }

    public void setDefaultValues(String partNumber, String description) {
        this.PartNumber = partNumber;
        this.PartDescription = description;
    }

    public class PartInfoFromDealer {
        public String AvailableQty;
        public String DealerName;
        public String DealerAddress;
        public String Distance;
        public String DealerPhoneNumber;
    }
}
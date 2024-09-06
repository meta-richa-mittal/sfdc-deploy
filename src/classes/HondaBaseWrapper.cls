public without sharing abstract class HondaBaseWrapper {
    public String DealerNumber;
    public String key;
    
    public HondaBaseWrapper() {
    	this.DealerNumber = HondaUtility.getDealerNumber();
        this.key = HondaUtility.getWebKeyNumber();
    }
}
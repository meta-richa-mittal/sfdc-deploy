public without sharing class XeroPaymentTermDTO {
    public BillWrapper Bills;
    public BillWrapper Sales;
    
    public class BillWrapper {
    	public Integer Day;
    	public String Type;
    }
}
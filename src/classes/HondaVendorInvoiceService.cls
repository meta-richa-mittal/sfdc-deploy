public without sharing class HondaVendorInvoiceService {
    
    public static List<String> getInvoices() {
        String body = System.JSON.serialize(new VendorInvoiceRequestWrapper(null), true);
        String responseBody = HondaUtility.sendRequest('Honda All Vendor Invoices', body);
        
        List<String> invoiceList = new List<String>();
        if(String.isNotBlank(responseBody)) {
            InvoicesResponseWrapper responseObj = (InvoicesResponseWrapper)System.JSON.deserialize(responseBody, InvoicesResponseWrapper.class);
            if(responseObj != null) {
                invoiceList = responseObj.InvoiceItems;
            }
        }
        return invoiceList;
    }
    
    public static InvoiceResponseWrapper getInvoiceData(String invoiceId) {
        String body = System.JSON.serialize(new VendorInvoiceRequestWrapper(invoiceId), true);
        String responseBody = HondaUtility.sendRequest('Honda Vendor Invoice', body);
        InvoiceResponseWrapper responseObj;
        if(String.isNotBlank(responseBody)) {
            responseObj = (InvoiceResponseWrapper)System.JSON.deserialize(responseBody, InvoiceResponseWrapper.class);
        }
        return responseObj;
    }
    
    public class InvoiceResponseWrapper {
        public String InvoiceNumber;
        public String CustomerReference;
        public String OrderType;
        public String OrderDate;
        public List<PartWrapper> HoosInvoiceItems;
    }
    
    public class PartWrapper {
        public String PartNumber;
        public String PartDescription;
        public Decimal PartQuantityAllocated;
        public Decimal WholesalePrice;
        public Decimal ListPrice;
    }
    
    public class VendorInvoiceRequestWrapper {
        public String key;
        public String dealer;
        public String ID;
        
        public VendorInvoiceRequestWrapper(String invoiceId) {
            this.dealer = HondaUtility.getDealerNumber();
            this.key = HondaUtility.getWebKeyNumber();
            this.ID = invoiceId;
        }
    }
    
    public class InvoicesResponseWrapper {
        public List<String> InvoiceItems;
    }
}
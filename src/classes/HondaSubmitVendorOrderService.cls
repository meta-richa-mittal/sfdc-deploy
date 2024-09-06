public without sharing class HondaSubmitVendorOrderService {
    
    public static Boolean send(String vendorOrderId, String orderType) {
        List<Vendor_Order_Header__c> voHeaderList = 
            [SELECT Name, (SELECT Part__r.Part_Number__c, Need__c FROM Vendor_Order_Line_Item_Groups__r) FROM Vendor_Order_Header__c 
                WHERE Id =: vendorOrderId];
        if(voHeaderList.size() == 0) {
            throw new BlackpurlException('Vendor order list is empty');
        }
        String body = System.JSON.serialize(new HondaVendorOrderWrapper(voHeaderList[0], orderType));
        HttpResponse response = HondaUtility.doCallout('Honda Vendor Order', body);
        Boolean isSuccessful = false;
        if(response != null && response.getStatusCode() == 200 && response.getBody().contains('Create order successfully.')) {
        	isSuccessful = true;
        }
        return isSuccessful;
    }
    
    public class HondaVendorOrderWrapper {
        public String dealer;
        public String key;
        public String dealer_reference;
        public String order_date;
        public String order_time;
        public String order_type;
        public String ship_address_id;
        public List<HondaVOGroupWrapper> lines;
        
        public HondaVendorOrderWrapper(Vendor_Order_Header__c voHeaderRec, String orderType) {
            this.dealer = HondaUtility.getDealerNumber();
            this.key = HondaUtility.getWebKeyNumber();
            this.dealer_reference = voHeaderRec.Name;
            this.order_date = DateTime.newInstance(system.today().year(), system.today().month(), system.today().day()).format('YYMMdd');
            this.order_time = system.now().format('HHmmss');
            this.order_type = (orderType == 'Daily order') ? 'D' : 'S';
            this.ship_address_id = '';
            
            this.lines = new List<HondaVOGroupWrapper>();
            for(Vendor_Order_Line_Item_Group__c voliGroupRec : voHeaderRec.Vendor_Order_Line_Item_Groups__r) {
                this.lines.add(new HondaVOGroupWrapper(voliGroupRec));
            }
        }
    }
    
    public class HondaVOGroupWrapper {
        public String part_number;
        public Integer order_quantity;
        public String backorder;
        
        public HondaVOGroupWrapper(Vendor_Order_Line_Item_Group__c voliGroupRec) {
            this.part_number = voliGroupRec.Part__r.Part_Number__c;
            this.order_quantity = Integer.valueOf(voliGroupRec.Need__c);
            this.backorder = 'N';
        }
    }
}
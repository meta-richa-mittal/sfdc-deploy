/**
 * Author: Balveer Choudhary
 * Since: July 21, 2022 
 * Name: ReallocateCOPartsWrapper
**/
public without sharing class ReallocateCOPartsWrapper {

    public class UnreceivedPartVOInfoWrapper {
        public String VOHeaderId;
        public String VONumber;
        public String OrderType;
        public String VOOrderedDate;
        public String VOExpectedDate;
        public Decimal UnreceivedOnOrderQty;
        public Boolean IsSelectedForReallocate;

        public UnreceivedPartVOInfoWrapper(Vendor_Order_Line_Item_Group__c voligRec) {
            this.VOHeaderId = voligRec.Vendor_Order_Header__c;
            this.VONumber = voligRec.Vendor_Order_Header__r.Name;
            this.OrderType = voligRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Code__c != null ? voligRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Code__c : ''; 
            this.VOOrderedDate = voligRec.Vendor_Order_Header__r.Ordered_Date__c != null ? BPUtility.getFormatedDateTime(voligRec.Vendor_Order_Header__r.Ordered_Date__c) : '';
            this.VOExpectedDate = voligRec.Vendor_Order_Header__r.Expected_Date__c != null ? BPUtility.getFormatedDateTime(voligRec.Vendor_Order_Header__r.Expected_Date__c) : '';
            this.UnreceivedOnOrderQty = 0;

            for(Vendor_Order_Line_Item__c voliRec : voligRec.Vendor_Order_Line_Items__r) {
                this.UnreceivedOnOrderQty += (voliRec.Qty_Needed__c != null ? voliRec.Qty_Needed__c : 0);
            }
            this.IsSelectedForReallocate = false;
        }
    }

    public class ReallocatePartWrapper {
        public String PartId;
        public String VendorId;
        public String VoHeaderId;
        public String ColiId;
        public Decimal RequiredQty;

        public ReallocatePartWrapper() {}
    }
}

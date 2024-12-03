/**
 * Author: Nidhi Sharma
 * Since: July 21, 2022 
 * Name: ReallocateVRPartsWrapper
**/
public without sharing class ReallocateVRPartsWrapper {

    public ReallocateOnOrderPartsWrapper ReallocateOnOrderPartsObj;
    public ReallocateOversoldPartsWrapper ReallocateOversoldPartsObj;

    public class ReallocateOnOrderPartsWrapper {
        public List<PartWrapper> PartList; 
        
        public ReallocateOnOrderPartsWrapper(List<Vendor_Receiving_Group__c> vrgList) {
            Map<Id, Part__c> partIdToRecMap = new Map<Id, Part__c>();
            Map<Id, Decimal> partIdToReceivedForStockQtyMap = new Map<Id, Decimal>();
            populatePartMaps(vrgList, partIdToRecMap, partIdToReceivedForStockQtyMap);

            if(!partIdToRecMap.isEmpty()) {
                partIdToRecMap.remove(null);
                Map<Id, List<Vendor_Order_Line_Item__c>> partIdToSpecialOrderListMap = getSortedPartIdToRequiredForCustVOLIMap(partIdToRecMap.keySet());
                                
                this.PartList = new List<PartWrapper>();
                for(Id partId : partIdToReceivedForStockQtyMap.keySet()) {
                    if(partIdToSpecialOrderListMap.containsKey(partId)) {
                        PartWrapper partDetailObj = new PartWrapper(partIdToRecMap.get(partId), 
                        partIdToReceivedForStockQtyMap.get(partId), partIdToSpecialOrderListMap.get(partId));
                        if(partDetailObj.SpecialOrderList != null && !partDetailObj.SpecialOrderList.isEmpty()) {
                            this.PartList.add(partDetailObj);
                        }
                    }
                }
            }
        }

        private Map<Id, List<Vendor_Order_Line_Item__c>> getSortedPartIdToRequiredForCustVOLIMap(Set<Id> partIdSet) {
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToSpecialOrderListMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToDealSJVOLIsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToCustomerSJVOLIsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToOtherSJVOLIsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToDealMerchVOLIsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            Map<Id, List<Vendor_Order_Line_Item__c>> partIdToMerchVOLIsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
            
            if(!AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            for(Vendor_Order_Line_Item__c voli : [Select Id, Part__c, CO_Line_Item__r.Deal__c, 
            	CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c, 
                CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Code_Label__c, 
                CO_Line_Item__r.CO_Header__r.Transaction_Type__r.Code_Label__c, 
                Qty_Needed__c, CO_Line_Item__r.CO_Header__r.Name, CO_Line_Item__r.CO_Header__r.Customer_Name__c
                FROM Vendor_Order_Line_Item__c WHERE Part__c IN: partIdSet AND Vendor_Order_Line_Item_Group__c = null AND Is_Received__c = false AND CO_Line_Item__c != null Order By CreatedDate]) {
                if(voli.CO_Line_Item__r.Service_Order_Line_Item__c != null) {
                    if(voli.CO_Line_Item__r.Deal__c != null || voli.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Deal Service') {
                        addVOLIToMap(partIdToDealSJVOLIsMap, voli);
                    } else if(voli.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Customer') {
                        addVOLIToMap(partIdToCustomerSJVOLIsMap, voli);
                    } else {
                        addVOLIToMap(partIdToOtherSJVOLIsMap, voli);
                    }
                } else {
                    if(voli.CO_Line_Item__r.Deal__c != null) {
                        addVOLIToMap(partIdToDealMerchVOLIsMap, voli);
                    } else {
                        addVOLIToMap(partIdToMerchVOLIsMap, voli);
                    }
                }
            }
            for(Id partId : partIdSet) {
                List<Vendor_Order_Line_Item__c> voliList = new List<Vendor_Order_Line_Item__c>();
                if(partIdToDealSJVOLIsMap.containsKey(partId)) {voliList.addAll(partIdToDealSJVOLIsMap.get(partId));}
                if(partIdToCustomerSJVOLIsMap.containsKey(partId)) {voliList.addAll(partIdToCustomerSJVOLIsMap.get(partId));}
                if(partIdToOtherSJVOLIsMap.containsKey(partId)) {voliList.addAll(partIdToOtherSJVOLIsMap.get(partId));}
                if(partIdToDealMerchVOLIsMap.containsKey(partId)) {voliList.addAll(partIdToDealMerchVOLIsMap.get(partId));}
                if(partIdToMerchVOLIsMap.containsKey(partId)) {voliList.addAll(partIdToMerchVOLIsMap.get(partId));}
                if(!voliList.isEmpty()) {
                    partIdToSpecialOrderListMap.put(partId, voliList);
                }
            }
            return partIdToSpecialOrderListMap;
        }

        private void addVOLIToMap(Map<Id, List<Vendor_Order_Line_Item__c>> partIdToVOLIsMap, Vendor_Order_Line_Item__c voli) {
            if(!partIdToVOLIsMap.containsKey(voli.Part__c)) {
                partIdToVOLIsMap.put(voli.Part__c, new List<Vendor_Order_Line_Item__c>{voli});
            } else {
                partIdToVOLIsMap.get(voli.Part__c).add(voli);
            }
        }
    }

    public class ReallocateOversoldPartsWrapper {
        public List<PartWrapper> PartList;

        public ReallocateOversoldPartsWrapper(List<Vendor_Receiving_Group__c> vrgList, Map<Id, Decimal> partIdToAlreadyAllocatedQtyMap) {
            Map<Id, Part__c> partIdToRecMap = new Map<Id, Part__c>();
            Map<Id, Decimal> partIdToReceivedForStockQtyMap = new Map<Id, Decimal>();
            populatePartMaps(vrgList, partIdToRecMap, partIdToReceivedForStockQtyMap);

            if(!partIdToRecMap.isEmpty()) {
                this.PartList = new List<PartWrapper>();
                for(Part__c partRec : partIdToRecMap.values()) {
                    Decimal remainingStockQty = partIdToReceivedForStockQtyMap.get(partRec.Id);
                    if(partIdToAlreadyAllocatedQtyMap != null && partIdToAlreadyAllocatedQtyMap.get(partRec.Id) != null) {
                        remainingStockQty -= partIdToAlreadyAllocatedQtyMap.get(partRec.Id);
                    }
                    if(partRec.Oversold_Qty__c != null && partRec.Oversold_Qty__c > 0 && remainingStockQty > 0) {
                        this.PartList.add(new PartWrapper(partRec, remainingStockQty));
                    }
                }
            }
        }
    }

    private static void populatePartMaps(List<Vendor_Receiving_Group__c> vrgList, Map<Id, Part__c> partIdToRecMap, Map<Id, Decimal> partIdToReceivedForStockQtyMap) {
        for(Vendor_Receiving_Group__c vrg : vrgList) {
            Decimal qty = 0;
            for(Vendor_Order_Line_Item__c stockVOLI : vrg.Vendor_Order_Line_Items__r) {
                qty += stockVOLI.Received__c;
            }
            for(Vendor_Receiving_Stock_Excess__c vrse : vrg.Vendor_Receiving_Stock_Excesses__r) {
                qty += vrse.Received_Qty__c;
            }
            if(qty > 0) {
                if(!partIdToRecMap.containsKey(vrg.Part__c)) {
                    partIdToRecMap.put(vrg.Part__c, vrg.Part__r);
                    partIdToReceivedForStockQtyMap.put(vrg.Part__c, 0);
                }
                partIdToReceivedForStockQtyMap.put(vrg.Part__c, partIdToReceivedForStockQtyMap.get(vrg.Part__c) + qty);
            }
        }
    }

    public class PartWrapper {
        public String Id;
        public String Item;
        public Decimal Oversold;
        public Decimal Received;
        public Boolean ResolveOversold;
        public Boolean UseReceivedToResolve;
        public List<SpecialOrderWrapper> SpecialOrderList;

		//Special order wrapper
		public PartWrapper(Part__c partRec, Decimal receivedQty, List<Vendor_Order_Line_Item__c> voliList) {
            if(partRec != null) {
            	this.Id = partRec.Id;
                this.Item = partRec.Part_Number__c + ' - ' + partRec.Description__c;
                this.Received = receivedQty;
                this.SpecialOrderList = new List<SpecialOrderWrapper>();
                if(voliList != null) {
                    for(Vendor_Order_Line_Item__c voli : voliList) {
                        this.SpecialOrderList.add(new SpecialOrderWrapper(voli));
                    }
                }
            }
        }
        
        //Oversold wrapper
        public PartWrapper(Part__c partRec, Decimal receivedQty) {
            if(partRec != null) {
                this.Id = partRec.Id;
                this.Item = partRec.Part_Number__c + ' - ' + partRec.Description__c;
                this.Oversold = partRec.Oversold_Qty__c;
                this.Received = receivedQty;
            }
        }
    }

    public class SpecialOrderWrapper {
        public String Info;
        public String Type;
        public String COLIId;
        public Decimal Needs;
        public Decimal Allocate;
        public String VRNumber;

        public SpecialOrderWrapper(Vendor_Order_Line_Item__c voli) {
            if(voli != null) {
                this.COLIId = voli.CO_Line_Item__c;
                this.Info = voli.CO_Line_Item__r.CO_Header__r.Name + ' - ' + voli.CO_Line_Item__r.CO_Header__r.Customer_Name__c;
                String section = (voli.CO_Line_Item__r.Service_Order_Line_Item__c != null ? 'Service' : (voli.CO_Line_Item__r.Deal__c != null ? 'Deal Merch' : 'Part sale'));
                String ttCodeLabel = voli.CO_Line_Item__r.Service_Order_Line_Item__c != null ? voli.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Code_Label__c : voli.CO_Line_Item__r.CO_Header__r.Transaction_Type__r.Code_Label__c;
                this.Type = section + (String.isNotBlank(ttCodeLabel) ? ' - ' + ttCodeLabel : '');
                this.Needs = voli.Qty_Needed__c;
            }
        }
    }    

}
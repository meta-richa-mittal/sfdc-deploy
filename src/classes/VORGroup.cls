/**
 * Author: Tarun Khandelwal
 * Since: Aug 19, 2015
 * Name: VORGroup
 * Description: Apex class to handle all operations related to Vendor Order Receiving Group record.
**/
public without sharing class VORGroup implements Comparable {
    
    // Id
    public String Id;
    
    // Part Number + Part desc
    public String ItemDesc;
    
    // Qty required by customer
    public String NeededFor;
      
    // Order 
    public String OrderType;
    
    // Qty Unit Type
    public String UnitType;
    
    // Order Value
    public Decimal OrderValue;
    
    // Received Order
    public Decimal ReceivedQty;
    
    // CO Line Item price per Qty
    public Decimal Cost;
    
    // Need * Cost
    public Decimal Total;
    
    // Part Id
    public String PartId;
    
    // Sublet Id
    public String SubletId;
    
    // Related VOLI
    public List<VendorOrderLineItem> VendorOrderLineItemList;
    
    // Is Excess
    public Boolean IsExcess;
    
    // Package Qty
    public Decimal PackageQty;
    
    // Need
    public Decimal Need;
    
    // List of Name of matching parts Vendor Order Header Name
    public List<String> OtherVOHeaderNameList;
    public String CreatedDate;

    //Part Number
    public String PartNumber;
    public Decimal Discount;
    public Decimal PartCost;
    public String MFGNo;
    
    // Constructor
    public VORGroup(Vendor_Receiving_Group__c vrGroupRec, Map<Id, List<String>> partIdToOtherVOHeaderNameListMap) {
        Boolean isReqForCustomerOrder = false;
        Boolean isReqForStock = false;
        this.VendorOrderLineItemList = new List<VendorOrderLineItem>();
        this.OtherVOHeaderNameList = new List<String>();
        this.IsExcess = false;
        this.CreatedDate = vrGroupRec.CreatedDate.format('yyyy/MM/dd hh:mm:ss');
        this.Id = vrGroupRec.Id;
        this.Need = 0;
        
        Map<Id, VendorOrderLineItem> voliIdToVOLIRecMap = new Map<Id, VendorOrderLineItem>();
        List<VendorReceivingLineItem> vrlis = new List<VendorReceivingLineItem>();
        for(Vendor_Order_Line_Item__c voliRec : vrGroupRec.Vendor_Order_Line_Items__r) {
            VendorOrderLineItem voli = new VendorOrderLineItem(voliRec);
            this.VendorOrderLineItemList.add(voli);
            if(voliRec.Is_Excess__c) {
                this.IsExcess = true;
            }  
            this.Need += voliRec.Qty_Needed__c;
            vrlis.add( new VendorReceivingLineItem(voliRec) );
            voliIdToVOLIRecMap.put(voliRec.Id, voli);
            voliRec.Is_required_For_Customer__c = (voliRec.Is_required_For_Customer__c != null) ? voliRec.Is_required_For_Customer__c : false;
            voliRec.Is_Service__c = (voliRec.Is_Service__c != null) ? voliRec.Is_Service__c : false;
            
            if(voliRec.Is_required_For_Customer__c || voliRec.Is_Service__c) {
                isReqForCustomerOrder = true;
            } else {
                isReqForStock = true;
            }
        }
        vrlis.sort();
        
        this.VendorOrderLineItemList.clear();
        for(VendorReceivingLineItem vrli : vrlis){
            this.VendorOrderLineItemList.add(voliIdToVOLIRecMap.get(vrli.voli.Id));
        }
        
        for(Vendor_Receiving_Stock_Excess__c vrseRec : vrGroupRec.Vendor_Receiving_Stock_Excesses__r) {
            this.VendorOrderLineItemList.add(new VendorOrderLineItem(vrseRec));
            isReqForCustomerOrder = false;
            isReqForStock = true;
            this.IsExcess = true;
        }
        
        Map<Id, Vendor_Order_Line_Item__c> voLineItemMap = new Map<Id, Vendor_Order_Line_Item__c>(vrGroupRec.Vendor_Order_Line_Items__r);
        
        if(vrGroupRec.Vendor_Order_Line_Items__r.size() > 1) {
            boolean isExcessRec = false;
            for(VendorOrderLineItem voliRec : VendorOrderLineItemList){
                if(voliRec.IsExcess != null && !voliRec.IsExcess ){
                    voliRec.NeededBy = BPUtility.getFormatedDateTime( ((Vendor_Order_Line_Item__c)(voLineItemMap.get(voliRec.Id))).CreatedDate.addDays(2));
                } else {
                    isExcessRec = true;
                }
            }
        }
        
        if(isReqForCustomerOrder) { 
            if(vrGroupRec.Vendor_Order_Line_Items__r.size() == 1) {
                this.NeededFor = vrGroupRec.Vendor_Order_Line_Items__r[0].CO_Header__r.Name;
            } else if(vrGroupRec.Vendor_Order_Line_Items__r.size() > 1) {
                this.NeededFor = 'Multiple Sources';
            }
        } else {
            this.NeededFor = 'Stock';
        }
        
        this.PartId = vrGroupRec.Part__c;
        this.SubletId = vrGroupRec.Sublet__c;
        
        if(vrGroupRec.Part__c != null) {
            setPartSpecificFields(vrGroupRec, partIdToOtherVOHeaderNameListMap);
        } else if(vrGroupRec.Sublet__c != null) {
            setSubletSpecificFields(vrGroupRec);
        }
        
        this.Cost = (this.Cost != null) ? this.Cost : 0;
        this.Discount = (this.Discount != null) ? this.Discount : 0;
        this.Total = (this.ReceivedQty != null) ? (((this.Cost * (1 - this.Discount/100)).setScale(2, RoundingMode.HALF_UP)) * this.ReceivedQty).setScale(2, RoundingMode.HALF_UP) : 0;
    }
    
    private void setPartSpecificFields(Vendor_Receiving_Group__c vrGroupRec, Map<Id, List<String>> partIdToOtherVOHeaderNameListMap) {
        this.ItemDesc = vrGroupRec.Part__r.Part_Number__c + ' - ' + vrGroupRec.Part__r.Description__c;
        this.PartNumber = vrGroupRec.Part__r.Part_Number__c;
        this.PartCost = vrGroupRec.Part__r.Calculated_Cost__c != null ? vrGroupRec.Part__r.Calculated_Cost__c : 0;
        if(vrGroupRec.Is_Packaged_Part__c && !vrGroupRec.Is_Order_As_Individual_Item__c) {
            this.Cost = vrGroupRec.Per_Unit_Cost__c != null ? vrGroupRec.Per_Unit_Cost__c : (vrGroupRec.Cost__c * vrGroupRec.Package_Qty__c);
            this.PartCost = vrGroupRec.Part__r.Calculated_Package_Cost__c;
        }  else if(vrGroupRec.Cost__c != null) {
            this.Cost = vrGroupRec.Cost__c;
        } else {
            this.Cost = this.PartCost;
        }
        this.Discount = vrGroupRec.Discount__c;
        this.UnitType = vrGroupRec.Package_Unit__c;
        this.OrderType = '';
        this.OrderValue = this.Need;
        
        if(vrGroupRec.Is_Order_As_Individual_Item__c) {
        	this.OrderType = 'Ordered as individual items';
        	this.UnitType = '';
        } else if(vrGroupRec.Is_Packaged_Part__c) {
            this.UnitType = (String.isBlank(vrGroupRec.Package_Unit__c) ? 'PKG' : vrGroupRec.Package_Unit__c);
            this.OrderValue = this.Need / vrGroupRec.Package_Qty__c;
            this.OrderType = 'Ordered as ' + vrGroupRec.Package_Qty__c + '/' + this.UnitType;
            if(vrGroupRec.Order_Lots__c > 1) {
                this.OrderType += ' in Lots of ' + vrGroupRec.Order_Lots__c;
            }
        } else if(vrGroupRec.Order_Lots__c > 1) {
            this.OrderType += 'Ordered as in Lots of ' + vrGroupRec.Order_Lots__c;
        }
        
        if(partIdToOtherVOHeaderNameListMap.containsKey(vrGroupRec.Part__c)) {
            this.OtherVOHeaderNameList = partIdToOtherVOHeaderNameListMap.get(vrGroupRec.Part__c);
        }
        
        if(vrGroupRec.Is_Packaged_Part__c && !vrGroupRec.Is_Order_As_Individual_Item__c) {
            this.ReceivedQty = (vrGroupRec.Recieved__c / vrGroupRec.Package_Qty__c);
        } else {
            this.ReceivedQty = vrGroupRec.Recieved__c;
        }
        this.PackageQty = vrGroupRec.Package_Qty__c;
        this.MFGNo = vrGroupRec.Part__r.MFG_Part__c;
    }
    
    private void setSubletSpecificFields(Vendor_Receiving_Group__c vrGroupRec) {
    	if(vrGroupRec.Service_Order_Line_Item__c != null) {
			this.ItemDesc = ((vrGroupRec.Service_Order_Line_Item__r.Item_Code__c != null) ? vrGroupRec.Service_Order_Line_Item__r.Item_Code__c : '') 
				+ ((vrGroupRec.Service_Order_Line_Item__r.Item_Code__c.length() > 0 && vrGroupRec.Service_Order_Line_Item__r.Item_Description__c.length() > 0) ? ' - ' : '' ) + 
				((vrGroupRec.Service_Order_Line_Item__r.Item_Description__c != null) ? vrGroupRec.Service_Order_Line_Item__r.Item_Description__c : '');
    	} else {
    		this.ItemDesc = vrGroupRec.Sublet__r.Product_Unique_Name__c;
    	}
    	this.Cost = vrGroupRec.Cost__c;
        this.Discount = vrGroupRec.Discount__c;
    	this.UnitType = '';
    	this.OrderType = '';
    	this.OrderValue = this.Need;
    	this.ReceivedQty = vrGroupRec.Recieved__c;
    }
    
    public static List<VORGroup> getPaginatedRecords(List<VORGroup> allrecords, Integer currentPage, integer pageSize) {
        List<VORGroup> objRecords = new List<VORGroup>();
        if(currentPage == null || currentPage == 0){
            currentPage = 1;
        }
        if(pageSize == null || pageSize == 0){
            pageSize = (Integer) General_Configurations__c.getInstance().Related_List_Page_Size__c;
        }
        
        for(Integer i = (currentPage * pageSize - pageSize); i < (currentPage * pageSize); i++){
            if(allrecords.size() > i){
                objRecords.add(allrecords.get(i));
            }
        }
        return objRecords;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){ 
        List<String> VORGroupFields = new List<String>{ 'Id',
                                                        'CreatedDate',
                                                        'Cost__c',
                                                        'Discount__c',
                                                        'Part__c', 
                                                        'Sublet__c',
                                                        'Sublet__r.Product_Unique_Name__c',
                                                        'Service_Order_Line_Item__r.Item_Code__c',
                                                        'Service_Order_Line_Item__r.Item_Description__c',
                                                        'Part__r.Name',
                                                        'Part__r.Part_Id__c',
                                                        'Part__r.Part_Number__c',
                                                        'Part__r.Description__c',
                                                        'Part__r.Package_Unit__c',
                                                        'Part__r.Packaged_Part__c',
                                                        'Part__r.Package_Qty__c',
                                                        'Part__r.MFG_Part__c',
                                                        'Part__r.Package_Cost__c',
                                                        'Part__r.Order_Lots__c',
                                                        'Part__r.Last_Cost__c',
                                                        'Part__r.Retail_Price__c',
                                                        'Part__r.Location__c',
                                                        'Part__r.Assigned_Location_1__c',
                                                		'Part__r.Assigned_Location_2__c',
                                                        'Part__r.Calculated_Cost__c',
                                                        'Vendor_Receiving_Header__c',
                                                        'Vendor_Receiving_Header__r.Vendor__c',
                                                        'Recieved__c',
                                                        'Is_Order_As_Individual_Item__c',
                                                        'Vendor_Receiving_Header__r.Vendor__r.Purchase_Tax__r.Rate__c',
                                                        'Vendor_Receiving_Header__r.Total_Line_Item__c',
                                                        'Vendor_Receiving_Header__r.Total_Received_Qty__c',
                                                        'Vendor_Receiving_Header__r.Is_Receiving_From_Invoice__c',
                                                        'Per_Unit_Cost__c',
                                                        'Part__r.Calculated_Package_Cost__c', 
                                                        'Package_Unit__c',
                                                        'Is_Packaged_Part__c',
                                                        'Package_Qty__c',
                                                        'Order_Lots__c'
                                                };
        return VORGroupFields;
    } 
    
    public Integer compareTo(object compareTo){ 
        VORGroup compareToWrapperObj = ((VORGroup)compareTo);
        String sortMapKey = VendorOrderReceivingCtrl.sortingMap.containsKey('ItemDesc') ? 'ItemDesc' : 'CreatedDate';
        
        Integer returnVal;
        if(sortMapKey == 'ItemDesc') {
        	returnVal = (compareToWrapperObj.ItemDesc > this.ItemDesc) ? 1 : ((compareToWrapperObj.ItemDesc == this.ItemDesc) ? 0 : -1);
        } else {
        	returnVal = (compareToWrapperObj.CreatedDate > this.CreatedDate) ? 1 : ((compareToWrapperObj.CreatedDate == this.CreatedDate) ? 0 : -1);
        }
        if( VendorOrderReceivingCtrl.sortingMap != null &&
            VendorOrderReceivingCtrl.sortingMap.containsKey(sortMapKey) &&
            VendorOrderReceivingCtrl.sortingMap.get(sortMapKey) == 'ASC'){
            returnVal *= -1;
        }
        
        return returnVal;
    }
}
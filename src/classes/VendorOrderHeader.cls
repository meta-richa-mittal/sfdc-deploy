/**
 * Author: Tarun Khandelwal
 * Since: July 22, 2015
 * Name: VendorOrderHeader
 * Description: Apex class to handle JSON related oprations of VO Header object.
**/
public without sharing class VendorOrderHeader implements Comparable{
    public String VOName;
    
    public String VendorName;
    
    public String VendorId;
    
    public String OwnerId;
    
    public String OwnerName;
    
    public String Status;
    
    public String Notes;
    
    public OrderTypeWrapper OrderType;
    
    public String OrderedDate;
    
    public String ExpectedDate;
    
    public String ReceivedDate;
    
    public String CreatedDate;
    
    // Variables required in Vendor Order Receiving page
    public String InProgressVR;
    public String InProgressVRId;
    public decimal QtyUnreceived;
    public List<VendorOrderLineItemGroup> VOLIGroups;
    public String Id;
    
    public Decimal PercentRecieved;
    public Decimal QtyReceived;
    public Decimal QtyNeeded;
    public String HondaDealerNumber;
    public Boolean IsVOAssociatedWithBRPVendor;
	public String BRPStatus;
    
	public String LastModifiedDate;
	public String CreatedBy;
	public String LastModifiedBy;
	public Decimal TotalReceived;

    // Constructor
    public VendorOrderHeader(Id voHeaderId) {
    	List<Vendor_Order_Header__c> voHeaders = SOQLUtil.getVendorOrderHeaderRecords('Id', voHeaderId, null, false);
		if(voHeaders.size() > 0){
			this.populateVendorOrder(voHeaders[0]);
			this.IsVOAssociatedWithBRPVendor = BRPUtility.isPartsMasterVendor(voHeaders[0].Vendor__c);
		}
    }
    
    // Constructor
    public VendorOrderHeader(Vendor_Order_Header__c voHeader) {
		this.populateVendorOrder(voHeader);
    }
    
    private void populateVendorOrder(Vendor_Order_Header__c voHeader){
    	this.Id = voHeader.Id;
    	VOName = voHeader.Name;
		VendorName = voHeader.Vendor__r.Name;
		VendorId = voHeader.Vendor__c;
		OwnerName = voHeader.Owner.Name;
		OwnerId = voHeader.OwnerId;
		Status = voHeader.Status__c;
		OrderType = new OrderTypeWrapper(voHeader.Purchase_Order_Type__c, voHeader.Purchase_Order_Type__r.Code__c, voHeader.Purchase_Order_Type__r.Lead_Time__c, voHeader.Purchase_Order_Type__r.Update_Current_Cost__c);
		Notes = voHeader.Notes__c;
		if(voHeader.Ordered_Date__c != null) {
			OrderedDate = BPUtility.getFormatedDateTime(datetime.newInstance(voHeader.Ordered_Date__c.year(), voHeader.Ordered_Date__c.month(),voHeader.Ordered_Date__c.day()));
		}
		if(voHeader.Expected_Date_Formula__c != null) {
			ExpectedDate = BPUtility.getFormatedDateTime(datetime.newInstance(voHeader.Expected_Date_Formula__c.year(), voHeader.Expected_Date_Formula__c.month(),voHeader.Expected_Date_Formula__c.day()));
		}
		if(voHeader.Received_Date__c != null) {
			ReceivedDate = BPUtility.getFormatedDateTime(datetime.newInstance(voHeader.Received_Date__c.year(), voHeader.Received_Date__c.month(),voHeader.Received_Date__c.day()));
		}
		CreatedDate = BPUtility.getFormatedDateTime(voHeader.CreatedDate);
		LastModifiedDate = BPUtility.getLastModifiedDateStr(voHeader);
		CreatedBy = voHeader.CreatedBy.Name != null ? voHeader.CreatedBy.Name : '';
		LastModifiedBy = BPUtility.getLastModifiedBy(voHeader);
		
		// Variables required in Vendor Order Receiving page
		for(In_Progress_VR__c inProgressVRRec : voHeader.In_Progress_VRs__r) {
			//system.assert(false, inProgressVRRec);
			InProgressVR = inProgressVRRec.Vendor_Receiving_Header__r.Name;
			InProgressVRId = inProgressVRRec.Vendor_Receiving_Header__c;
		}
		this.HondaDealerNumber = HondaUtility.getDealerNumber();
		this.TotalReceived = voHeader.Total_Recieved__c;
    }
    
    /**
     * Name: populateVendorOrderGroups
     * Desc: Method to populate vendor order groups records for this vendor header
     * @param:  (1) voHeader - Vendor_Order_Header__c 
     * @return: 
    **/
    public void populateVendorOrderGroups(Vendor_Order_Header__c voHeader){
    	QtyUnreceived = 0;
    	QtyReceived = 0;
    	VOLIGroups = new List<VendorOrderLineItemGroup>();
    	for(Vendor_Order_Line_Item_Group__c voliG : voHeader.Vendor_Order_Line_Item_Groups__r){
    		VendorOrderLineItemGroup voliGroup = new VendorOrderLineItemGroup(voliG, this);
    		QtyUnreceived += voliG.Unreceived_Qty__c;
    		QtyReceived += voliG.Received_Qty__c;
    		VOLIGroups.add(voliGroup);
    	}
    	if(QtyUnreceived < 0) {
    		QtyUnreceived = 0;
    		PercentRecieved =100;
    	} else {
    		PercentRecieved = (QtyReceived == 0) 
    						  ? 0
    						  : (QtyReceived / (QtyReceived + QtyUnreceived)) * 100;
    	}
    	
    	system.debug('QtyReceived  ' + QtyReceived  + '\nQtyUnreceived' + QtyUnreceived + '\nPercentRecieved ' + PercentRecieved);
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: VendorOrderHeader - Class Object
    **/
    public static VendorOrderHeader parse(String json) {
        return (VendorOrderHeader) System.JSON.deserialize(json, VendorOrderHeader.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> voHeaderFieldsList = new List<String>{	'Id', 
        													'Vendor__c',
        													'Vendor__r.Name', 
        													'Status__c',
        													'Notes__c',
        													'Received_Date__c', 
        													'Purchase_Order_Type__c',
        													'Purchase_Order_Type__r.Code__c',
        													'Purchase_Order_Type__r.Lead_Time__c',
															'Purchase_Order_Type__r.Update_Current_Cost__c', 
        													'Owner__c', 
        													'Ordered_Date__c', 
        													'Expected_Date__c', 
        													'Expected_Date_Formula__c', 
        													'CreatedDate',
        													'Name',
        													'Owner.Name',
        													'Owner.Id',
        													'In_Progress_VR__c',
        													'In_Progress_VR__r.Name',
															'LastModifiedDate',
															'Last_Modified_Date__c',
															'CreatedBy.Name',
															'LastModifiedBy.Name',
															'Last_Modified_By__r.Name',
															'Total_Recieved__c'
        												};
        return voHeaderFieldsList;
    }
    
    /**
     * Name: getPaginatedRecords
     * Desc: Method to paginate entity records list
     * @param:  
     * @return:
    **/
    public static List<VendorOrderHeader> getPaginatedRecords(List<VendorOrderHeader> allrecords, Integer currentPage, integer pageSize) {
    	List<VendorOrderHeader> objRecords = new List<VendorOrderHeader>();
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
     * Name: compareTo
     * Desc: Overrided Method to sort the collection to move all those vendor orders in last which are already part of any other vendor receiving records
     * @param:  
     * @return:
    **/
    public Integer compareTo(object compareTo){
        VendorOrderHeader compareToObj = ((VendorOrderHeader)compareTo);
        Integer returnVal = 0;
        					
		if(this.InProgressVRId == compareToObj.InProgressVRId && (this.InProgressVRId != null && compareToObj.InProgressVRId != null)){
			returnVal = (this.VOName == compareToObj.VOName)
						? 0
						:(
							(VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC')
							?	((this.VOName < compareToObj.VOName) ? -1 : 1)
							:	(VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'DESC')
								?	((this.VOName < compareToObj.VOName) ? 1 : -1)
								:	0
						);
        } else if(this.InProgressVRId == null && compareToObj.InProgressVRId == null) {
			DateTime todayDate = Datetime.now();
            DateTime currentExpDate = this.ExpectedDate == null ? null : HomeSearchFilterInterface.getDateFromString(this.ExpectedDate).date();
			DateTime compExpDate = compareToObj.ExpectedDate == null ? null : HomeSearchFilterInterface.getDateFromString(compareToObj.ExpectedDate).date();
			Integer ascSort = VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC' ? -1 : 1;
			Integer descSort = VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC' ? 1 : -1;
			boolean isAsc = VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC';

            returnVal = (currentExpDate == compExpDate || currentExpDate == null || compExpDate == null)
                		?(this.VOName == compareToObj.VOName)
                            ? 0
                            :(
                                (VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC')
                                ?	((this.VOName < compareToObj.VOName) ? -1 : 1)
                                :	(VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'DESC')
                                    ?	((this.VOName < compareToObj.VOName) ? 1 : -1)
                                    :	0
                            )
						:(currentExpDate == todayDate) ? isAsc ? ascSort :	(compExpDate < currentExpDate) ? 1 : -1 
														: (compExpDate == todayDate) ? isAsc ? descSort : (currentExpDate < compExpDate) ? -1 : 1
							:(currentExpDate < todayDate && compExpDate < todayDate)
            					?(currentExpDate > compExpDate) ? ascSort : descSort
                                : (currentExpDate > todayDate && compExpDate > todayDate)
            						?(currentExpDate < compExpDate) ? ascSort : descSort
                                	:(currentExpDate < todayDate) ? -1 : 1;
        } else if(this.InProgressVRId == null) {
			returnVal = (compareToObj.InProgressVRId == VendorOrderReceivingCtrl.Vendor_Order_Receiving_Id)
						?	1
						:	-1;
		} else if(compareToObj.InProgressVRId == null) {
			returnVal = (this.InProgressVRId == VendorOrderReceivingCtrl.Vendor_Order_Receiving_Id)
						?	-1
						:	1;
		} else {
			returnVal = (this.InProgressVRId == VendorOrderReceivingCtrl.Vendor_Order_Receiving_Id)
						?	-1
						:(
							(compareToObj.InProgressVRId == VendorOrderReceivingCtrl.Vendor_Order_Receiving_Id)
							?	1
							:(
								(VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'ASC')
								?	((this.VOName < compareToObj.VOName) ? -1 : 1)
								:	(VendorOrderReceivingCtrl.VO_Sort_Order.toUpperCase() == 'DESC')
									?	((this.VOName < compareToObj.VOName) ? 1 : -1)
									:	0
							)
						);
		}
        //System.debug('@@@\n' + this.InProgressVRId + '  ' + this.VOName + '\n' + compareToObj.InProgressVRId + '  ' + compareToObj.VOName + '\n' + returnVal + '\n' + VendorOrderReceivingCtrl.Vendor_Order_Receiving_Id);
        return returnVal;
    }
    
    // Order Type wrapper
    public class OrderTypeWrapper {
    	public String Id;
    	public String Name;
    	public Integer LeadTime;
		public Boolean UpdateCurrentCost;
    	
    	public OrderTypeWrapper(String Id, String Name, decimal LeadTime, Boolean updateCurrentCost){
    		this.Id = Id;
    		this.Name = Name;
    		this.LeadTime = (LeadTime == null) ? 0 : Integer.valueOf(LeadTime);
			this.UpdateCurrentCost = updateCurrentCost;
    	}
    }
}
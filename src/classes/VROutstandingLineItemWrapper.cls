/** 
 * Author: Raghav Khandelwal
 * Since: May 10, 2021
 * Name: VROutstandingLineItemWrapper
 * Description: Wrapper class to handle VR outstanding list
**/
public without sharing class VROutstandingLineItemWrapper implements Comparable{

    public String Id;
    public String Item;
    public String Description;
    public String CreatedDate;
    public String PartId;
    public String SubletId;
    public String UniqueKey;

    // Constructor
    public VROutstandingLineItemWrapper(Vendor_Order_Line_Item_Group__c voliGroupRec) {
        this.Id = voliGroupRec.Id;
        this.CreatedDate = voliGroupRec.CreatedDate.format('yyyy/MM/dd hh:mm:ss');
        if(voliGroupRec.Part__c != null) {
            this.Item = voliGroupRec.Part__r.Part_Number__c;
            this.Description = voliGroupRec.Part__r.Description__c;
        } else if(voliGroupRec.Sublet__c != null) {
            if(voliGroupRec.Vendor_Order_Line_Items__r.size() > 0) {
		    	this.Item = (voliGroupRec.Vendor_Order_Line_Items__r[0].Service_Order_Line_Item__r.Item_Code__c != null) ? voliGroupRec.Vendor_Order_Line_Items__r[0].Service_Order_Line_Item__r.Item_Code__c : '';
				this.Description = (voliGroupRec.Vendor_Order_Line_Items__r[0].Service_Order_Line_Item__r.Item_Description__c != null) ? 
					(voliGroupRec.Vendor_Order_Line_Items__r[0].Service_Order_Line_Item__r.Item_Description__c) : '';
        	} else {
        		this.Item = voliGroupRec.Sublet__r.Product_Unique_Name__c;
        	}
        }
        this.PartId = voliGroupRec.Part__c;
        this.SubletId = voliGroupRec.Sublet__c; 
        this.UniqueKey = '';
        if(this.PartId != null) {
        	this.UniqueKey = this.PartId + '_' + voliGroupRec.Is_Order_As_Individual_Item__c;
        } else if(this.SubletId != null) {
        	this.UniqueKey = this.Id;
        }
    }
    
    public static List<VROutstandingLineItemWrapper> getPaginatedRecords(List<VROutstandingLineItemWrapper> allrecords, Integer currentPage, integer pageSize) {
        List<VROutstandingLineItemWrapper> objRecords = new List<VROutstandingLineItemWrapper>();
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

    public Integer compareTo(object compareTo){
        VROutstandingLineItemWrapper compareToWrapperObj = ((VROutstandingLineItemWrapper)compareTo);
        Integer returnVal = -1;
        String sortMapKey = 'Items';
        if(VendorOrderLineItemWrapper.sectionNameToSortEntityMap != null &&
        	VendorOrderLineItemWrapper.sectionNameToSortEntityMap.containsKey(sortMapKey)) {
        		if(VendorOrderLineItemWrapper.sectionNameToSortEntityMap.get(sortMapKey) == 'Item') {
        			returnVal = (compareToWrapperObj.Item < this.Item) ? 1 : ((compareToWrapperObj.Item == this.Item) ? 0 : -1);
        		} else {
        			returnVal = (compareToWrapperObj.CreatedDate < this.CreatedDate) ? 1 : ((compareToWrapperObj.CreatedDate == this.CreatedDate) ? 0 : -1);
        		}
        } else {
        	returnVal = (compareToWrapperObj.Item < this.Item) ? 1 : ((compareToWrapperObj.Item == this.Item) ? 0 : -1);
        }
        
        if( VendorOrderLineItemWrapper.sortFieldMap != null &&
            VendorOrderLineItemWrapper.sortFieldMap.containsKey(sortMapKey) &&
            VendorOrderLineItemWrapper.sortFieldMap.get(sortMapKey) == 'DESC'){
            returnVal *= -1;
        }
        return returnVal;
    }
    
    public class SelectedRecordWrapper {
    	public String UniqueKey;
    	public String Id;
    	
    	public SelectedRecordWrapper(String uniqueKey, String id) {
    		this.UniqueKey = uniqueKey;
    		this.Id = id;
    	}
    }
}
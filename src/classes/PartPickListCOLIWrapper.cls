public without sharing class PartPickListCOLIWrapper {
    public Id PartId;
    public Id CoLineItemId;
    public String Item;
    public Decimal Qty;
    public Decimal QtyOrder;
    public String Status;
    public String Location;
    public String Pulled;
    public String DescriptiveNote;
    public Boolean IsSublet;
    public Boolean IsSpecialOrder;
    public String SpecialOrderBelongsTo;
   
    public PartPickListCOLIWrapper(CO_Line_Item__c coLineItemObj) {  
        List<String> locationList = new List<String>();
        this.IsSublet = false;
        this.IsSpecialOrder = false;
        this.PartId = coLineItemObj.Part__c;
        this.CoLineItemId = coLineItemObj.Id;      
        this.Item = coLineItemObj.Item_Code__c + ' - ' + coLineItemObj.Item_Description__c;
        this.Qty = (coLineItemObj.Qty__c == null) ? 1 : coLineItemObj.Qty__c;
        this.QtyOrder = (coLineItemObj.Qty_To_Order__c == null || coLineItemObj.Qty__c < 0) ? 0 : coLineItemObj.Qty_To_Order__c;
        if(coLineItemObj.Invoice_Number__c != null) {
            this.Status = 'Invoiced';
            this.DescriptiveNote = coLineItemObj.Invoice_Number__r.Invoice_Number__c;
            this.DescriptiveNote += (GeneralConfiguration.isRecordTrackingNumber() && coLineItemObj.Service_Order_Line_Item__c == null &&
            							coLineItemObj.Deal__c == null && String.isNotBlank(coLineItemObj.Tracking_Number__c)) ? 
            						' - Tracking# ' + coLineItemObj.Tracking_Number__c : '';
            this.DescriptiveNote += ' - Invoiced ' +((coLineItemObj.Invoice_Number__r.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(coLineItemObj.Invoice_Number__r.Invoice_Date__c) : '');                                 
        } else if(coLineItemObj.Oversold_Qty__c > 0) {
            this.Status = 'Oversold';
        } else if(coLineItemObj.Qty__c < 0) {
            this.Status = 'Return';
        } else if(String.isNotBlank(coLineItemObj.Merchandise_Commit_Order_controls__c) && coLineItemObj.Merchandise_Commit_Order_controls__c.equalsIgnoreCase('Uncommitted')) {
            this.Status = (coLineItemObj.Part__r.AvailableParts__c > 0) ? 'In Stock' : 'Required';
        } else if(String.isNotBlank(coLineItemObj.Merchandise_Commit_Order_controls__c) && coLineItemObj.Merchandise_Commit_Order_controls__c.equalsIgnoreCase('Commit only')) {
            this.Status = (coLineItemObj.Qty_To_Order__c > 0) ? 'Required' : 'In Stock';
        } else {
            this.Status = 'In Stock';
        }
        this.DescriptiveNote = (this.DescriptiveNote == null) ? '': this.DescriptiveNote;
        this.Pulled =(coLineItemObj.Pulled__c == null) ? '' : coLineItemObj.Pulled__c;
        this.Location = ((coLineItemObj.Part__r.Assigned_Location_1__c != null) ? coLineItemObj.Part__r.Assigned_Location_1__c : '') + ((coLineItemObj.Part__r.Assigned_Location_2__c != null) ? coLineItemObj.Part__r.Assigned_Location_2__c : '');
		locationList = this.Location.split(';');
		this.Location = '';
		for(String location : locationList) {
			if(String.isNotBlank(location)) {
				this.Location = this.Location + location + ', ';
			}
		}
		this.Location = this.Location.length() >= 2 ? this.Location.substring(0, this.Location.length()-2) : this.Location;
    }

    public PartPickListCOLIWrapper(List<COHeaderWrapper.SpecialOrder> specialOrderObjList) {
        if(specialOrderObjList.size() > 0) {
            this(specialOrderObjList[0]);
        }
        
        Set<String> statusSet = new Set<String>();
        for(Integer i = 0; i < specialOrderObjList.size(); i++) {
            statusSet.add(specialOrderObjList[i].Status);
            if(statusSet.size() > 1) {
                this.Status = 'Multiple';
            }
            if(i > 0) {
                this.DescriptiveNote += ('. ' + getDescriptiveNotes(specialOrderObjList[i]));
                this.QtyOrder += specialOrderObjList[i].QtyNeeded;
            }
        }
    }

    public PartPickListCOLIWrapper(COHeaderWrapper.SpecialOrder specialOrderObj) {  
        this.IsSublet = specialOrderObj.IsSublet;
        this.IsSpecialOrder = true;
        this.PartId = specialOrderObj.PartId;
        this.CoLineItemId = specialOrderObj.COLineItemId;      
        this.Item = specialOrderObj.Item;
        this.Qty = specialOrderObj.QtyNeededCOLI;
        this.QtyOrder = specialOrderObj.QtyNeeded;
        this.Location = specialOrderObj.Location;
        this.Pulled = specialOrderObj.Pulled;
        this.Status = specialOrderObj.Status;
        this.DescriptiveNote = getDescriptiveNotes(specialOrderObj);
        this.SpecialOrderBelongsTo = specialOrderObj.SpecialOrderBelongsTo;
    }
    
    public String getDescriptiveNotes(COHeaderWrapper.SpecialOrder specialOrderObj) {
        String note;
        if(specialOrderObj.Status == 'Required') {
            note = 'ETA if ordered today - ' + specialOrderObj.ExpectedDelivery;
        } else if(specialOrderObj.Status == 'Received') {
            note = specialOrderObj.VRNumber + ' - received ' + specialOrderObj.ExpectedDelivery;
        } else if(specialOrderObj.Status == 'Ordered'){
            note = specialOrderObj.PONumber + ' - expected ' + specialOrderObj.ExpectedDelivery;
        } else if(specialOrderObj.Status == 'Invoiced') {
            note = specialOrderObj.VRNumber + ' - Invoiced ' + specialOrderObj.ExpectedDelivery;
        } else {
            note = '';
        }
        return note;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> COLineItemFields = new List<String>{   'Id',
                                                            'Name', 
                                                            'Item_Code__c',
                                                            'Item_Description__c',
                                                            'Qty__c',
                                                            'Qty_To_Order__c',
                                                            'Part__c',
                                                            'Merchandise_Commit_Order_controls__c',
                                                            'Part__r.AvailableParts__c',
                                                            'Part__r.Assigned_Location_1__c',
                                                            'Part__r.Assigned_Location_2__c',
                                                            'Status__c',
                                                            'Pulled__c',
                                                            'Invoice_Number__r.Invoice_Number__c',
                                                            'Invoice_Number__r.Invoice_Date__c',
                                                            'Oversold_Qty__c',
                                                            'Tracking_Number__c',
                                                            'Service_Order_Line_Item__c',
                                                            'Deal__c'
                                                    };
        return COLineItemFields;
    }
}
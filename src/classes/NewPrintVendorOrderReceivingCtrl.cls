public without sharing class NewPrintVendorOrderReceivingCtrl {

    //public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
	public VendorOrderReceivingWrapper vendorOrderReceivingDetailObj {get; private set;}
	public List<VORGroupWrapper> vorGroupDetailObjList {get; private set;}
	public static Map<String, String> sortingMap;
    
    public NewPrintVendorOrderReceivingCtrl (){
    	vendorOrderReceivingDetailObj = new VendorOrderReceivingWrapper();
		
		Id vorHeaderId;
		String vorHeaderIdStr = ApexPages.currentPage().getParameters().get('id');
		String brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
		String groupItemsPageSortAttrsJSON = ApexPages.currentPage().getParameters().get('sortParams');
		//system.assert(false, vorHeaderIdStr);
		if(!String.isBlank(vorHeaderIdStr)) {
			try {
				vorHeaderId = Id.valueOf(vorHeaderIdStr);
				getVORDetails(BPUtility.getEncodedString(vorHeaderId), BPUtility.getEncodedString(brandingLocationId), groupItemsPageSortAttrsJSON);
			} catch(Exception e) {
				System.debug(e.getMessage());
			}
		}
    } 
    
    /**
     * Name: getVORDetails
     * Desc: 
     * @param:  (1) vorHeaderIdStr
     * @return: String - JSON String
    **/
    public void getVORDetails(String vorHeaderIdStr, String brandingLocationId, String groupItemsPageSortAttrsJSON) {
    	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	
		vorHeaderIdStr = BPUtility.getDecodedString(vorHeaderIdStr);
		brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
        Id vorHeaderId = vorHeaderIdStr;
        String fieldName = 'Id';
        String fieldValue = vorHeaderId;
        String query;   
        query = 'SELECT '; 
        for(String fieldAPIName : VORHeader.fieldsList()){
        	fieldAPIName = BPUtility.escapeSingleQuotes(fieldAPIName);
            query += fieldAPIName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Vendor_Receiving_Header__c WHERE '+ fieldName +' = \'' + fieldValue + '\'';
        
        List<Vendor_Receiving_Header__c> vorHeaders = Database.query(query);
        
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : VORGroup.fieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        
        // Child query
        query1 += '( SELECT ';
        for(String fieldsName : VendorOrderLineItem.fieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM ' + Constants.NAMESPACE + 'Vendor_Order_Line_Items__r ORDER BY CreatedDate ASC ), ';
        
        
        // 2 Child query
        query1 += '( SELECT ';
        for(String fieldsName : VendorOrderLineItem.stockExcessFieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length() - 2);
        query1 += ' FROM ' + Constants.NAMESPACE + 'Vendor_Receiving_Stock_Excesses__r ORDER BY CreatedDate ASC ) ';
        
        query1 += ' FROM ' + Constants.NAMESPACE + 'Vendor_Receiving_Group__c ';
        
        query1 += ' WHERE Vendor_Receiving_Header__c = \'' + fieldValue + '\'';
        
        query1 += 'ORDER BY CreatedDate DESC';
        
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Stock_Excess__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Vendor_Receiving_Group__c> vrGroupList = Database.query(query1);
        
        //List<Vendor_Receiving_Group__c> vrGroupList = SOQLUtil.getVORGroupsWithItems('Vendor_Receiving_Header__c', fieldValue);
		BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
		if(String.isBlank(brandingLocationId)) {
		   List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
		   brandingLocationObj.setDefaultBrandingLocation((businessProfileList.size() > 0 ? businessProfileList[0] : new Business_Profile__c()));
	   } else {
			for(Branding_Location__c brandingLocRec: BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(new Map<String, String>{'Id' => brandingLocationId})) {
				brandingLocationObj.setAllBrandingLocationFields(brandingLocRec);
			}
	   }
       
        if(vorHeaders.size() > 0){
        	VORHeader vorHeader = new VORHeader(vorHeaders[0]);
            Id vendorId = vorHeader.VendorId;
            List<Account> vendors = SOQLUtil.getVendorDetailRecord('Id', vendorId);
            vendorOrderReceivingDetailObj = new VendorOrderReceivingWrapper(vorHeaders[0], vendors[0], brandingLocationObj);
        }
        if(vrGroupList.size() > 0) {
        	System.debug('groups111');
        	System.debug(vrGroupList);
        	System.debug(vrGroupList[0].Vendor_Order_Line_Items__r);
        	System.debug(vrGroupList[0].Vendor_Receiving_Stock_Excesses__r);
        	vorGroupDetailObjList = new List<VORGroupWrapper>();
        	for(Vendor_Receiving_Group__c vorGroupRec : vrGroupList){
				vorGroupDetailObjList.add(new VORGroupWrapper(vorGroupRec));
			}
        }
		if(String.isNotBlank(groupItemsPageSortAttrsJSON)) {
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            PaginationSorting groupItemsPageSortAttrs = PaginationSorting.parsePageAttrs(groupItemsPageSortAttrsJSON);
            sortingMap = new Map<String, String>();
            if(groupItemsPageSortAttrs.sorting != null && groupItemsPageSortAttrs.sorting[0].sortDirection.length() != 0){
                sortingMap.put(groupItemsPageSortAttrs.sorting[0].FieldName, groupItemsPageSortAttrs.sorting[0].sortDirection);
                vorGroupDetailObjList.sort();
            }
        }
    }
    
    
    public class VendorOrderReceivingWrapper{
    	public String VORName {get; private set;}
	    
	    public String VendorId{get; private set;}
	    
	    public String OwnerId{get; private set;}
	    
	    public String OwnerName{get; private set;}
	    
	    public String Status{get; private set;}
	    
	    public String ReceivedDate{get; private set;}
	    
	    public VendorWrapper VendorInfo{get; private set;}
	    
	    public CustomerDetail.Company CompanyInfo{get; private set;}
	    
	    public Decimal ReceivedTotal{get; private set;}
	    
	    public VendorOrderReceivingWrapper(){
	    	
	    }
	    
	    public VendorOrderReceivingWrapper(Vendor_Receiving_Header__c vorHeader, Account vendorRec, BrandingLocationWrapper brandingLocationObj){
	    	VORName = (vorHeader.Packing_Slip_Number__c != null) ? vorHeader.Packing_Slip_Number__c : vorHeader.Name;
			VendorId = vorHeader.Vendor__c;
			OwnerName = vorHeader.Owner__r.Name;
			OwnerId = vorHeader.Owner__c;
			Status = vorHeader.Status__c;
			if(vorHeader.Finalized_Date__c != null) {
				ReceivedDate = BPUtility.getFormatedDateTime(datetime.newInstance(vorHeader.Finalized_Date__c.year(), vorHeader.Finalized_Date__c.month(),vorHeader.Finalized_Date__c.day()));
			} else {
				ReceivedDate = BPUtility.getFormatedDateTime(datetime.newInstance(system.today().year(), system.today().month(),system.today().day()));
				//ReceivedDate = system.today().format();
			}
			
			this.VendorInfo = new VendorWrapper(vendorRec);
			
			if(brandingLocationObj != null) {
                this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
            }
            this.CompanyInfo.BusinessPhone = formatphonenumber(this.CompanyInfo.BusinessPhone);
			
			this.ReceivedTotal = (vorHeader.Receiving_Total__c != null) ? vorHeader.Receiving_Total__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    }
    }
    
    public class VendorWrapper{
		// Customer Name
	    public String VendorName{get; private set;}
	    
	    // Vendor Code
	    public String VendorCode{get; private set;}
	    
	    // Home Eamil Address
	    public String HomeEmail{get; private set;}
	    
	    // Work Email Address
	    public String WorkEmail{get; private set;}
	    
	    // Home Number
	    public String HomeNumber{get; private set;}
	    
	    // Work Number
	    public String WorkNumber{get; private set;}
	    
	    // Preferred Email
	    public String PreferredEmail{get; private set;}
	    
	    // Preferred Phone
	    public String PreferredPhone{get; private set;}
	    
	    // Customer Number
	    public String VendorNumber{get; private set;}
	    
	    // Billing Address Fields
	    public String BillingStreet1{get; private set;}
	    public String BillingStreet2{get; private set;}
	    public String BillingCity{get; private set;}
	    public String BillingState{get; private set;}
	    public String BillingCountry{get; private set;}
	    public String BillingPostalCode{get; private set;}
        public Boolean IsForeignExchangeCostingEnabled{get; private set;}
		public Boolean IsForeignVendor{get; private set;}
        public String FXCurrencyCode{get; private set;}
	    
	    public VendorWrapper(Account vendorRec){
	    	this.VendorName = vendorRec.Name;
	    	this.VendorCode = vendorRec.Vendor_Code__c; 
	    	
	    	// Emails
    		this.HomeEmail = (vendorRec.Email__c == null) ? '' : vendorRec.Email__c;
	    	this.WorkEmail = (vendorRec.Work_Email__c == null) ? '' : vendorRec.Work_Email__c;
	    	
	    	// Phone
	    	this.HomeNumber = (vendorRec.Home_Number__c == null ) ? '' : formatphonenumber(vendorRec.Home_Number__c);
	    	this.WorkNumber = (vendorRec.Work_Number__c == null ) ? '' : formatphonenumber(vendorRec.Work_Number__c);
	    	
	    	// Phone And Email Preffered
	    	if(vendorRec.Preferred_Email__c != null) {
	    		if(vendorRec.Preferred_Email__c == vendorRec.Email__c) {
	    			this.PreferredEmail = 'HomeEmail';
	    		} else if(vendorRec.Preferred_Email__c == vendorRec.Work_Email__c) {
	    			this.PreferredEmail = 'WorkEmail';
	    		} else if(vendorRec.Preferred_Email__c == vendorRec.Other_Email__c) {
	    			this.PreferredEmail = 'OtherEmail';
	    		}
	    	} else {
	    		this.PreferredEmail = '';
	    	}
	    	
	    	if(vendorRec.Preferred_Phone__c != null) {
	    		if(vendorRec.Preferred_Phone__c == vendorRec.Home_Number__c) {
	    			this.PreferredPhone = 'HomeNumber';
	    		} else if(vendorRec.Preferred_Phone__c == vendorRec.Mobile__c) {
	    			this.PreferredPhone = 'OtherPhone';
	    		} else if(vendorRec.Preferred_Phone__c == vendorRec.Work_Number__c) {
	    			this.PreferredPhone = 'WorkNumber';
	    		}
	    	} else {
	    		this.PreferredPhone = '';
	    	}
	    	this.VendorNumber = vendorRec.Vendor_Number__c;
	    	
	    	// Billing Address fields
	    	String billingStreet = (vendorRec.BillingStreet == null ) ? '' : vendorRec.BillingStreet;
	    	List<String> bsList = billingStreet.split('\n');
	    	this.BillingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
	    	this.BillingStreet2 = (bsList.size() > 1) ? bsList[1] : '';
	    	this.BillingCity = (vendorRec.BillingCity == null) ? '' : vendorRec.BillingCity;
	    	this.BillingState = (vendorRec.BillingState == null) ? '' : vendorRec.BillingState;
	    	this.BillingCountry = (vendorRec.BillingCountry == null) ? '' : vendorRec.BillingCountry;
	    	this.BillingPostalCode = (vendorRec.BillingPostalCode == null) ? '' : vendorRec.BillingPostalCode;
            this.IsForeignExchangeCostingEnabled = GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c;
			this.IsForeignVendor = vendorRec.Is_Foreign_Vendor__c;
            if(this.IsForeignVendor) {
                this.FXCurrencyCode = (vendorRec.Country__c != null && String.isNotBlank(vendorRec.Country__r.Currency_Code__c))? vendorRec.Country__r.Currency_Code__c : '';
            }
	    }
    }
    
    public class VORGroupWrapper implements Comparable  {
    	
    	// Part Number + Part desc
	    public String ItemDesc{get; private set;}
	    
	    // Need - Qty Required 
	    public Decimal ReceivedQty{get; private set;}
	    
	    public String SubletId{get; private set;}
	    public String PartId{get; private set;}
	    // Qty Unit Type
    	public String UnitType{get; private set;}
    	
    	// CO Line Item price per Qty
	    public Decimal Cost{get; private set;}
	    
	    // Need * Cost
	    public Decimal Total{get; private set;}
		public String MFGNo{get; private set;}
		public String ItemCode{get; private set;}
        public String ItemDescription{get; private set;}
		public Boolean IsNonStockLineExists{get; private set;}
		public String Location{get; private set;}
        public String CreatedDate;
	    
	    public List<VOLIWrapper> vendorOrderLineItems{get; private set;}
	    
	    public VORGroupWrapper(Vendor_Receiving_Group__c vorGroupRec){
	    	if(vorGroupRec.Part__c != null) {
	    		this.PartId = vorGroupRec.Part__c;
		    	this.ItemDesc = vorGroupRec.Part__r.Part_Number__c + ' - ' + vorGroupRec.Part__r.Description__c;
				this.ItemCode = String.isNotBlank(vorGroupRec.Part__r.Part_Number__c) ? vorGroupRec.Part__r.Part_Number__c: '';
            	this.ItemDescription = String.isNotBlank(vorGroupRec.Part__r.Description__c) ? vorGroupRec.Part__r.Description__c: '';
	    		if(String.isBlank(vorGroupRec.Part__r.Package_Unit__c) && vorGroupRec.Part__r.Packaged_Part__c){
		    		this.UnitType = 'PKG';
		    	}else{
		    		this.UnitType = vorGroupRec.Part__r.Package_Unit__c;
		    	}
				this.MFGNo = vorGroupRec.Part__r.Mfg_Part__c;
	    	} else if(vorGroupRec.Sublet__c != null) {
	    		this.SubletId = vorGroupRec.Sublet__c;
	    		this.ItemDesc = ((vorGroupRec.Service_Order_Line_Item__r.Item_Code__c != null) ? vorGroupRec.Service_Order_Line_Item__r.Item_Code__c : '') 
	    			+ ((vorGroupRec.Service_Order_Line_Item__r.Item_Code__c.length() > 0 && vorGroupRec.Service_Order_Line_Item__r.Item_Description__c.length() > 0) ? ' - ' : '' ) + 
	    			((vorGroupRec.Service_Order_Line_Item__r.Item_Description__c != null) ? vorGroupRec.Service_Order_Line_Item__r.Item_Description__c : '');
	    		this.UnitType = 'EA';
				this.ItemCode = String.isNotBlank(vorGroupRec.Service_Order_Line_Item__r.Item_Code__c) ? vorGroupRec.Service_Order_Line_Item__r.Item_Code__c: '';
            	this.ItemDescription = String.isNotBlank(vorGroupRec.Service_Order_Line_Item__r.Item_Description__c) ? vorGroupRec.Service_Order_Line_Item__r.Item_Description__c: '';
	    	}
	    	if(!vorGroupRec.Part__r.Packaged_Part__c || vorGroupRec.Is_Order_As_Individual_Item__c) {
	        	this.ReceivedQty = (((vorGroupRec.Recieved__c.setscale(0)) - (vorGroupRec.Recieved__c)) == 0.00) ? vorGroupRec.Recieved__c.setscale(0) : vorGroupRec.Recieved__c.setscale(2, RoundingMode.HALF_UP);
	        	this.UnitType = 'EA';
	        } else if(vorGroupRec.Part__r.Packaged_Part__c) {
	        	this.ReceivedQty = (vorGroupRec.Recieved__c / vorGroupRec.Part__r.Package_Qty__c);
	        	this.ReceivedQty = (((this.ReceivedQty.setscale(0)) - (this.ReceivedQty)) == 0.00) ? this.ReceivedQty.setscale(0) : this.ReceivedQty.setscale(2, RoundingMode.HALF_UP);
	        }
	        
	    	if(vorGroupRec.Part__r.Packaged_Part__c && !vorGroupRec.Is_Order_As_Individual_Item__c){
				this.Cost = (vorGroupRec.Per_Unit_Cost__c != null ? vorGroupRec.Per_Unit_Cost__c : ((vorGroupRec.Cost__c != null ? vorGroupRec.Cost__c : 0) * vorGroupRec.Part__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
	    	} else if(vorGroupRec.Cost__c != null) {
	    		this.Cost = vorGroupRec.Cost__c.setscale(2, RoundingMode.HALF_UP);
	    	} else {
	        	this.Cost = vorGroupRec.Part__r.Last_Cost__c.setscale(2, RoundingMode.HALF_UP);
	        }

			if(vorGroupRec.Part__c != null) {
				this.Location = LocationManagementService.getLocationsListString(vorGroupRec.Part__r);
			}
	    	
	    	//this.Total = (vorGroupRec.Recieved__c != null) ? (this.Cost * this.ReceivedQty).setscale(2, RoundingMode.HALF_UP) : 0.00;
	    	this.Total = (this.Cost != null && this.ReceivedQty != null) ? (this.Cost * this.ReceivedQty).setscale(2, RoundingMode.HALF_UP) : 0.00;
	    	
	    	this.vendorOrderLineItems = new List<VOLIWrapper>();
			
			if(vorGroupRec.Vendor_Order_Line_Items__r.size() > 0) {
				for(Vendor_Order_Line_Item__c VendorOrderLineItemRec : vorGroupRec.Vendor_Order_Line_Items__r){
					this.vendorOrderLineItems.add(new VOLIWrapper(VendorOrderLineItemRec));
				}
			}
			
			if(vorGroupRec.Vendor_Receiving_Stock_Excesses__r.size() > 0) {
				for(Vendor_Receiving_Stock_Excess__c vrseRec : vorGroupRec.Vendor_Receiving_Stock_Excesses__r){
					this.vendorOrderLineItems.add(new VOLIWrapper(vrseRec));
				}
			}
			this.IsNonStockLineExists = false;
			for(VOLIWrapper voliRec : this.vendorOrderLineItems) {
				if(voliRec.NeededFor != 'Stock' && voliRec.NeededFor != 'Stock Excess' && voliRec.NeededFor != 'Excess Received') {
					this.IsNonStockLineExists = true;
					break;
				}
			}
			this.CreatedDate = vorGroupRec.CreatedDate.format('yyyy/MM/dd hh:mm:ss');			
	    }

		public Integer compareTo(object compareTo){ 
            VORGroupWrapper compareToWrapperObj = ((VORGroupWrapper)compareTo);
            String sortMapKey = sortingMap.containsKey('ItemDesc') ? 'ItemDesc' : 'CreatedDate';
            
            Integer returnVal;
            if(sortMapKey == 'ItemDesc') {
                returnVal = (compareToWrapperObj.ItemDesc > this.ItemDesc) ? 1 : ((compareToWrapperObj.ItemDesc == this.ItemDesc) ? 0 : -1);
            } else {
                returnVal = (compareToWrapperObj.CreatedDate > this.CreatedDate) ? 1 : ((compareToWrapperObj.CreatedDate == this.CreatedDate) ? 0 : -1);
            }

            if( sortingMap != null && sortingMap.containsKey(sortMapKey) && sortingMap.get(sortMapKey) == 'ASC'){
                returnVal *= -1;
            }
            return returnVal;
        }
    }
    
    public class VOLIWrapper{
    	public String NeededForReason {get; private set;}
    	public String NeededFor {get; private set;}
    	public Decimal ReceivedQty {get; private set;}
	    public VOLIWrapper(){
	    	
	    }
	    
	    public VOLIWrapper(Vendor_Order_Line_Item__c VendorOrderLineItemRec){
	    	if(VendorOrderLineItemRec.Is_required_For_Customer__c || VendorOrderLineItemRec.Is_Service__c) {
				String coType;
				if(VendorOrderLineItemRec.Is_Service__c) {
					if(VendorOrderLineItemRec.Service_Order_Line_Item__c != null) {
						coType = VendorOrderLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Deal__c != null ? 'Deal service - ': 'Service - ';
						coType += VendorOrderLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Name__c;
					} else {
						coType = VendorOrderLineItemRec.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Deal__c != null ? 'Deal service - ': 'Service - ';
						coType += VendorOrderLineItemRec.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Name__c;
					}
				} else {
					coType = VendorOrderLineItemRec.CO_Line_Item__r.Deal__c != null ? 'Deal merchandise': 'Part Sale';
				}
	        	this.NeededForReason = (VendorOrderLineItemRec.CO_Header__r.Name != null) ? (VendorOrderLineItemRec.CO_Header__r.Name + ' - ' + coType) : ''; 
	        	this.NeededFor = (VendorOrderLineItemRec.CO_Header__r.Customer_Name__c != null) ? VendorOrderLineItemRec.CO_Header__r.Customer_Name__c : '';
	        } else if(VendorOrderLineItemRec.Is_Excess__c) {
	        	this.NeededForReason = LocationManagementService.getLocationsListString(VendorOrderLineItemRec.Part__r);
	        	this.NeededFor = 'Stock Excess';
	        } else {
	        	this.NeededForReason = LocationManagementService.getLocationsListString(VendorOrderLineItemRec.Part__r);
	        	this.NeededFor = 'Stock';
	        }
	        
	        this.ReceivedQty = (((VendorOrderLineItemRec.Received__c.setscale(0)) - (VendorOrderLineItemRec.Received__c)) == 0.00) ? VendorOrderLineItemRec.Received__c.setscale(0) : VendorOrderLineItemRec.Received__c.setscale(2, RoundingMode.HALF_UP);
	    }
	    
	    public VOLIWrapper(Vendor_Receiving_Stock_Excess__c vrseRec){
	    	this.ReceivedQty = (((vrseRec.Received_Qty__c.setscale(0)) - (vrseRec.Received_Qty__c)) == 0.00) ? vrseRec.Received_Qty__c.setscale(0) : vrseRec.Received_Qty__c.setscale(2, RoundingMode.HALF_UP);
        	if(vrseRec.Vendor_Order_Line_Item_Group__c != null && vrseRec.Vendor_Order_Line_Item_Group__r.Part__c != null) {
        		this.NeededForReason = LocationManagementService.getLocationsListString(vrseRec.Vendor_Order_Line_Item_Group__r.Part__r);
			} else if(vrseRec.Vendor_Receiving_Group__c != null && vrseRec.Vendor_Receiving_Group__r.Part__c != null) {
        		this.NeededForReason = LocationManagementService.getLocationsListString(vrseRec.Vendor_Receiving_Group__r.Part__r);
			} else {
				this.NeededForReason = '';
			}
        	this.NeededFor = 'Excess Received';
	    }
    }
    
    public static String formatphonenumber(String cphone) {
		String fphone = cphone.replaceAll('\\D','');
		
		if (fphone.length() == 10) {
			fphone = formatphonenum(fphone);
			return fphone;
		}
		else {
			return cphone;
		}
		
	}
		
	static String formatphonenum (String s) {
		s = '(' + s.substring(0, 3) + ') ' + s.substring(3, 6) + '-' + s.substring(6);
		return s;
	}
}
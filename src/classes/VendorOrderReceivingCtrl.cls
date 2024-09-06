/**
 * Author: Ashish Garg
 * Since: Aug 6, 2015 
 * Name: VendorOrderReceivingCtrl
 * Description: Apex class to handle all operations related to Vendor Order Receiving Page.
**/
global without sharing class VendorOrderReceivingCtrl { 
    // Static variable to use current Vendor Order receiving Id
    public static Id Vendor_Order_Receiving_Id;
     
	// Vendor Orders sort order
    public static String VO_Sort_Order;  
    
    // Sort order map
    public static Map<String, String> sortingMap;
    public Decimal VRRelatedListPageSize { get{return GeneralConfiguration.getVRRelatedListPageSize();} private set;}
    public Decimal Related_List_Page_Size { get{return GeneralConfiguration.getRelatedListPageSize();} private set;}
    
    global VendorOrderReceivingCtrl (NewHomePageCtrl controller){}
    public VendorOrderReceivingCtrl() {}
    
    /**
     * Name: addVendor
     * Desc: Method to add selected vendor to vendor receiving order
     * @param:      (1) selectedVendorId - Id - Vendor Id
     *              (2) vorId - String - Vendor Order Receiving Id
     * @return: String - Vendor_Receiving_Header__c Id if successfully selected
    **/
    @RemoteAction
    global static String addVendor(String selectedVendorId, String vorId){
        try{
            selectedVendorId = BPUtility.getDecodedString(selectedVendorId);
            vorId = BPUtility.getDecodedString(vorId);
            Vendor_Receiving_Header__c vrHeader = new Vendor_Receiving_Header__c();
            if(vorId != null){
                vrHeader.Id = vorId;
            }
            vrHeader.Vendor__c = selectedVendorId;
            vrHeader.Owner__c = UserInfo.getUserId();
            vrHeader.Status__c = 'In Progress';
            
            try{
                DMLUtility.upsertSobjectList('Vendor_Receiving_Header__c', vrHeader);
                
                // After Insert, Update all Vendor Order Header for the vendor which are unreceived
                if(GeneralConfiguration.isAutoSelectOrdersInPartReceiving()){
                    updateVendorOrdersReceiving(vrHeader.Id, true);
                }
            } catch(Exception e){
                //system.assert(false, e);
                return BPUtility.getEncodedString(null);
            }
            return BPUtility.getEncodedString(vrHeader.Id);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getVORDetails
     * Desc: Method to get all page details for a Vendor Order Receiving record
     * @param:  (1) vorId - String - Vendor Order Receiving Id
     *          (2) gridName - String - Grid Name
     *          (3) lastEditedPartId - Id - Edited Part Id Recently
     *          (4) vendorOrdersPageSortAttrsJSON - String -Vendor Order Headers Grid Paging and sorting JSON
     *          (5) groupItemsPageSortAttrsJSON - String - Items Grid Paging and sorting JSON
     *          (6) outstandingVOGPageSortAttrsJSON - String - Outstanding Grid Paging and sorting JSON
     * @return: String - JSON String of all CO Line Items of CO Header Record
    **/
    @RemoteAction
    global static String getVORDetails( String vorId, 
                                        String gridName,
                                        String lastEditedPartId,
                                        String vendorOrdersPageSortAttrsJSON, 
                                        String groupItemsPageSortAttrsJSON, 
                                        String outstandingVOGPageSortAttrsJSON){
        
        try{
            vorId = BPUtility.getDecodedString(vorId);
            gridName = BPUtility.getDecodedString(gridName);
            lastEditedPartId = BPUtility.getDecodedString(lastEditedPartId);
            vendorOrdersPageSortAttrsJSON = BPUtility.getDecodedString(vendorOrdersPageSortAttrsJSON);
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            outstandingVOGPageSortAttrsJSON = BPUtility.getDecodedString(outstandingVOGPageSortAttrsJSON);
            
            Vendor_Order_Receiving_Id = vorId;
            PaginationSorting vendorOrdersPageSortAttrs = PaginationSorting.parsePageAttrs(vendorOrdersPageSortAttrsJSON);
            PaginationSorting groupItemsPageSortAttrs = PaginationSorting.parsePageAttrs(groupItemsPageSortAttrsJSON);
            PaginationSorting outstandingVOGPageSortAttrs = PaginationSorting.parsePageAttrs(outstandingVOGPageSortAttrsJSON);
            
            VendorOrderReceiving voReceiving = new VendorOrderReceiving(vorId, gridName, lastEditedPartId, vendorOrdersPageSortAttrs, groupItemsPageSortAttrs, outstandingVOGPageSortAttrs);
            return BPUtility.getEncodedString(System.JSON.serialize(voReceiving));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getVendorOrderList
     * Desc: Method to get all Vendor Order Records for a vendor
     * @param:  (1) vendorId - String - Vendor Id
     * @return: String - JSON String of all Vendor Order records
    **/
    @RemoteAction
    global static String getVendorOrderList( String vendorId) {
        try{
            vendorId = BPUtility.getDecodedString(vendorId);
            List<VendorOrderHeader> vendorOrdersList = VendorOrderReceivingService.getVendorOrderList(vendorId);
            return BPUtility.getEncodedString(System.JSON.serialize(vendorOrdersList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    /**
     * Name: updateVORHeaderDetails
     * Desc: Method to update various details of vendor receiving header
     * @param:  (1) vorId - String - Vendor Order Receiving Id
     *          (2) VORHeaderJSON- String - Vendor Receiving Header Records JSON String
     * @return:  JSON String of ids of Vendor Receiving Header Record
    **/
    @RemoteAction
    global static String updateVORHeaderDetails(String vorId, String VORHeaderJSON){
        vorId = BPUtility.getDecodedString(vorId);
        VORHeaderJSON = BPUtility.getDecodedString(VORHeaderJSON);
        
        VORHeader VORHeaderRec = VORHeader.parse(VORHeaderJSON);
        Vendor_Receiving_Header__c vorHeaderToUpdate = new Vendor_Receiving_Header__c(  Id = vorId,
                                                                                        Is_Receiving_From_Invoice__c = VORHeaderRec.IsReceivingFromInvoice,
                                                                                        Receiving_From_Invoice_Total__c = VORHeaderRec.ReceivingFromInvoiceTotal);
        try{
            Boolean isPacakgeSlipNumberValid = false;
            if(VORHeaderRec.IsReceivingFromInvoice) {
                if(String.isBlank(VORHeaderRec.PackagingSlipNumber) || (!VendorOrderReceivingService.isSimilarPackingSlipNumberExists(VORHeaderRec) && !VendorOrderReceivingService.isSimilarInvoiceNumberExists(VORHeaderRec))) {
                    isPacakgeSlipNumberValid = true;
                }
            } else {
                if(String.isBlank(VORHeaderRec.PackagingSlipNumber) || (!VendorOrderReceivingService.isSimilarPackingSlipNumberExists(VORHeaderRec))) {
                    isPacakgeSlipNumberValid = true;
                }
            }

            if(isPacakgeSlipNumberValid) {
                vorHeaderToUpdate.Packing_Slip_Number__c = VORHeaderRec.PackagingSlipNumber;
            }
            DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vorHeaderToUpdate);

            return BPUtility.getEncodedString(System.JSON.serialize(VORHeader.getVORDetails(vorId)));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String receiveVendorOrderItems(String voHeaderId, String vrHeaderId, Boolean isSelected){
        voHeaderId = BPUtility.getDecodedString(voHeaderId);
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        try {
            if(voHeaderId != null) {
                VendorOrderReceivingService.updateVOSelection(voHeaderId, vrHeaderId, isSelected);
                return BPUtility.getEncodedString('true');
            } else {
                return updateVendorOrdersReceiving(vrHeaderId, isSelected);
            }
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: updateVendorOrdersReceiving
     * Desc: Method to update selected vendor order items for receiving
     * @param:  (1) vorId - String - Vendor Order Receiving Id
     *          (2) isSelected - boolean  - is Selected or not
     * @return: String - boolean if successfully selected
    **/
    private static String updateVendorOrdersReceiving(String vrhId, boolean isSelected){
        List<In_Progress_VR__c> inProgressVRList = new List<In_Progress_VR__c>();
        if(AccessControl.ifObjectIsAccessible('In_Progress_VR__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}

        if(isSelected){
            List<In_Progress_VR__c> inProgressList = [select Vendor_Receiving_Header__c,
                                                           Vendor_Order_Header__c
                                                           from In_Progress_VR__c  
                                                           Where Vendor_Receiving_Header__r.Status__c = 'In Progress' 
                                                  ];
            List<Vendor_Receiving_Header__c> vorHeaderRecords = SOQLUtil.getVORDetails('Id', vrhId);
            if(vorHeaderRecords.size() > 0){
                Set<Id> inProgressVOIds = new Set<id>();
                for(In_Progress_VR__c ipvr : inProgressList){
                    inProgressVOIds.add(ipvr.Vendor_Order_Header__c);
                }
                
                List<Vendor_Order_Header__c> voList = SOQLUtil.getVendorOrderHeaderRecords('Vendor__c', vorHeaderRecords[0].Vendor__c, null, true);
                In_Progress_VR__c inProgressVRRec;
                for(Vendor_Order_Header__c vo : voList){
                    inProgressVRRec = new In_Progress_VR__c();
                    if( !inProgressVOIds.contains(vo.Id) ){
                        inProgressVRRec.Vendor_Order_Header__c = vo.Id;
                        inProgressVRRec.Vendor_Receiving_Header__c = vrhId;
                        inProgressVRList.add(inProgressVRRec);
                    }
                }
                if(inProgressVRList.size() > 0) {
                    DMLUtility.insertSobjectList('In_Progress_VR__c', inProgressVRList);
                }
            }
        } else {
            inProgressVRList = [SELECT Vendor_Order_Header__c FROM In_Progress_VR__c  
                                   WHERE Vendor_Receiving_Header__r.Status__c = 'In Progress' AND Vendor_Receiving_Header__c =: vrhId];
            
            // Remove any pending VR groups related to deselected VO
            VendorOrderReceivingService.unReceiveGroupsForDeselectedVendorOrders(vrhId, true, inProgressVRList);
            
            // Delete In Progress VR
            if(inProgressVRList.size() > 0) {
                if(!AccessControl.ifObjectIsDeletable('In_Progress_VR__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                delete inProgressVRList;
            }                                                      
        }
        return BPUtility.getEncodedString(String.valueOf(true));
    }
    
    @RemoteAction
    global static Boolean autoPopulateHondaInvoiceDetail(String vrHeaderId, String hondaInvoice) {
        return null;
    }
    
    @RemoteAction
    global static String autoPopulateHondaInvoiceDetails(String vrHeaderId, String hondaInvoice) {
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        hondaInvoice = BPUtility.getDecodedString(hondaInvoice);
        try {
            VendorOrderReceivingService.populatePackagingSlipNumber(vrHeaderId, hondaInvoice);
            return VendorOrderReceivingService.selectVOFromHondaResponse(vrHeaderId, hondaInvoice);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String createPartFromHondaIfNotExists(String hondaInvoice) {
        hondaInvoice = BPUtility.getDecodedString(hondaInvoice);
        try {
            return BPUtility.getEncodedString(VendorOrderReceivingService.createPartFromHondaIfNotExists(hondaInvoice));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getAllVOLIGroupItem(String vendorId, String vrHeaderId) {
    	return getAllVOLIGroupItemV2(vendorId, vrHeaderId, null);
    }
    
    @RemoteAction
    global static String getAllVOLIGroupItemV2(String vendorId, String vrHeaderId, String searchStr) {
        vendorId = BPUtility.getDecodedString(vendorId);
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        searchStr = BPUtility.getDecodedString(searchStr);
        
        Map<String, VROutstandingLineItemWrapper.SelectedRecordWrapper> selectedRecIdToObjMap = new Map<String, VROutstandingLineItemWrapper.SelectedRecordWrapper>();
        if(String.isNotBlank(vrHeaderId)) {
        	
        	String query = 'SELECT Part__c, Sublet__c, Cost__c, Vendor_Receiving_Group__c, Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c FROM Vendor_Order_Line_Item__c' +
	            	' WHERE Vendor_Receiving_Group__c = null AND Vendor_Order_Header__c IN (select Vendor_Order_Header__c FROM In_Progress_VR__c '+
            			' WHERE Vendor_Receiving_Header__r.Status__c = \'In Progress\' AND Vendor_Receiving_Header__c =: vrHeaderId)';
            if(String.isNotBlank(searchStr)) {
            	query += ' AND (Part__r.Part_Number__c LIKE \'%' + searchStr.trim() + '%\' OR Sublet__r.Code__c LIKE \'%' + searchStr.trim() + '%\')';
            }			
            List<Vendor_Order_Line_Item__c> voLineItems = Database.query(query);
            
            for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
            	String uniqueKey;
                if(voliRec.Part__c != null) {
                	if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                		uniqueKey = voliRec.Part__c + '_' + voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c;
                		if(!selectedRecIdToObjMap.containsKey(voliRec.Part__c)) {
                			selectedRecIdToObjMap.put(voliRec.Part__c, new VROutstandingLineItemWrapper.SelectedRecordWrapper(uniqueKey, voliRec.Part__c));
                		}
                	}
                } else if(voliRec.Sublet__c != null) {
                	if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                		uniqueKey = voliRec.Vendor_Order_Line_Item_Group__c;
                		if(!selectedRecIdToObjMap.containsKey(voliRec.Vendor_Order_Line_Item_Group__c)) {
                			selectedRecIdToObjMap.put(voliRec.Vendor_Order_Line_Item_Group__c, 
                										new VROutstandingLineItemWrapper.SelectedRecordWrapper(uniqueKey, voliRec.Vendor_Order_Line_Item_Group__c));
                		}
                	}
                }
            }
        }
        return BPUtility.getEncodedString(System.JSON.serialize(selectedRecIdToObjMap.values()));
    }
    
    @RemoteAction 
    global static String groupSelectedLineItems(String vrHeaderId, String selectedRecIds, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        try {
            vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
            selectedRecIds = BPUtility.getDecodedString(selectedRecIds);
            
            List<String> selectedRecIdList = (List<String>) System.JSON.deserialize(selectedRecIds, List<String>.class);
            List<In_Progress_VR__c> inProgressVRList = [select Vendor_Order_Header__c from In_Progress_VR__c where Vendor_Receiving_Header__c =: vrHeaderId
                                                                        AND Vendor_Receiving_Header__r.Status__c = 'In Progress'];
            List<Id> selectedVOHeaderIdList = new List<Id>();
            for(In_Progress_VR__c inProgressVrRec : inProgressVRList){
                selectedVOHeaderIdList.add(inProgressVrRec.Vendor_Order_Header__c); 
            }
                
            List<Vendor_Order_Line_Item__c> voLineItems = new List<Vendor_Order_Line_Item__c>();
            voLineItems = [select Id, Part__c, Qty_Needed__c, Sublet__c, Cost__c, Vendor_Receiving_Group__c, Service_Order_Line_Item__c,
                                        Vendor_Order_Line_Item_Group__r.Per_Unit_Cost__c, Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c,
                                        Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c, Vendor_Order_Line_Item_Group__r.Is_Order_Lot__c,
            							Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c, Vendor_Order_Line_Item_Group__r.Package_Qty__c,
                                        Part__r.Packaged_Part__c, Vendor_Order_Line_Item_Group__r.Total__c, Vendor_Order_Line_Item_Group__r.Package_Unit__c,
                                        Vendor_Order_Line_Item_Group__r.Need__c, Part__r.Package_Qty__c, Vendor_Order_Line_Item_Group__r.Order_Lots__c 
                                        from Vendor_Order_Line_Item__c where Vendor_Order_Header__c IN :selectedVOHeaderIdList 
                                        AND (Part__c IN : selectedRecIdList OR Vendor_Order_Line_Item_Group__c IN : selectedRecIdList)
                                        AND Vendor_Receiving_Group__c = null];
            
            List<Vendor_Receiving_Group__c> vrGroupList = [select Id, Part__c, Is_Order_As_Individual_Item__c 
            					from Vendor_Receiving_Group__c where Vendor_Receiving_Header__c = :vrHeaderId];
            
            Map<Id, Id> partIdToOrderAsIndividualItemVRGIdMap = new Map<Id, Id>();
            Map<Id, Id> partIdToVRGroupIdMap = new Map<Id, Id>();
            for(Vendor_Receiving_Group__c vrGroup : vrGroupList) {
                if(vrGroup.Part__c != null) {
                	if(vrGroup.Is_Order_As_Individual_Item__c) {
                		if(!partIdToOrderAsIndividualItemVRGIdMap.containsKey(vrGroup.Part__c)) {
	                        partIdToOrderAsIndividualItemVRGIdMap.put(vrGroup.Part__c, vrGroup.Id);
	                    }
                	} else {
                		if(!partIdToVRGroupIdMap.containsKey(vrGroup.Part__c)) {
	                        partIdToVRGroupIdMap.put(vrGroup.Part__c, vrGroup.Id);
	                    }
                	}
                }
            }
            
            List<Vendor_Receiving_Group__c> vrGroupListToInsert = new List<Vendor_Receiving_Group__c>(); 
            List<Id> subletVRGIdList = new List<Id>();
            //Create VOR if not already exists
            for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
                Vendor_Receiving_Group__c vrGroupRec = new Vendor_Receiving_Group__c();
                vrGroupRec.Discount__c = voliRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c;
                if(voliRec.Part__c != null) {
	                vrGroupRec.Part__c = voliRec.Part__c;
                    if(voliRec.Vendor_Order_Line_Item_Group__r.Per_Unit_Cost__c != null) {
                        vrGroupRec.Per_Unit_Cost__c = vrGroupRec.Cost__c = voliRec.Vendor_Order_Line_Item_Group__r.Per_Unit_Cost__c;
                        if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c && !voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                            vrGroupRec.Cost__c = (vrGroupRec.Per_Unit_Cost__c / voliRec.Vendor_Order_Line_Item_Group__r.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
                        }
                    } else {
                        vrGroupRec.Cost__c = voliRec.Cost__c;
                        if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c && !voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                            vrGroupRec.Per_Unit_Cost__c = (voliRec.Vendor_Order_Line_Item_Group__r.Total__c/(voliRec.Vendor_Order_Line_Item_Group__r.Need__c/voliRec.Vendor_Order_Line_Item_Group__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
                        } else {
                            vrGroupRec.Per_Unit_Cost__c = vrGroupRec.Cost__c;
                        }
                    }
                    vrGroupRec.Vendor_Receiving_Header__c = vrHeaderId;
                    vrGroupRec.Is_Packaged_Part__c = voliRec.Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c;
                    vrGroupRec.Is_Order_Lot__c = voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_Lot__c;
                    vrGroupRec.Package_Qty__c = voliRec.Vendor_Order_Line_Item_Group__r.Package_Qty__c;
                    vrGroupRec.Package_Unit__c = voliRec.Vendor_Order_Line_Item_Group__r.Package_Unit__c;
                    vrGroupRec.Order_Lots__c = voliRec.Vendor_Order_Line_Item_Group__r.Order_Lots__c;

                    
                	if(voliRec.Vendor_Order_Line_Item_Group__c != null && voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                		if(!partIdToOrderAsIndividualItemVRGIdMap.containsKey(voliRec.Part__c)) {
	                    	vrGroupRec.Is_Order_As_Individual_Item__c = true;
	                        vrGroupListToInsert.add(vrGroupRec);
	                        partIdToOrderAsIndividualItemVRGIdMap.put(voliRec.Part__c, null);
	                    }
                	} else {
                		if(!partIdToVRGroupIdMap.containsKey(voliRec.Part__c)) {
	                    	vrGroupRec.Is_Order_As_Individual_Item__c = false;
	                        vrGroupListToInsert.add(vrGroupRec);
	                        partIdToVRGroupIdMap.put(voliRec.Part__c, null);
	                    }
                	}
                } else if(voliRec.Sublet__c != null && voliRec.Vendor_Receiving_Group__c == null) {
                    vrGroupRec.Sublet__c = voliRec.Sublet__c;
                    if(voliRec.Vendor_Order_Line_Item_Group__r.Per_Unit_Cost__c != null) {
                        vrGroupRec.Per_Unit_Cost__c = vrGroupRec.Cost__c = voliRec.Vendor_Order_Line_Item_Group__r.Per_Unit_Cost__c;
                    } else {
                        vrGroupRec.Cost__c = voliRec.Cost__c;
                    }
                    vrGroupRec.Vendor_Receiving_Header__c = vrHeaderId;
                    vrGroupRec.Service_Order_Line_Item__c = voliRec.Service_Order_Line_Item__c;
                    vrGroupListToInsert.add(vrGroupRec);
                }
            }
            
            if(vrGroupListToInsert.size() > 0) {
                VendorReceivingGroupTriggerHelper.isForceStopTrigger = true;
                DMLUtility.insertSobjectList('Vendor_Receiving_Group__c', vrGroupListToInsert);
                VendorReceivingGroupTriggerHelper.isForceStopTrigger = false;
            }
            
            for(Vendor_Receiving_Group__c vrGroupRec : vrGroupListToInsert) {
                if(vrGroupRec.Sublet__c != null && vrGroupRec.Part__c == null) {
                    subletVRGIdList.add(vrGroupRec.Id);
                    
                } else if(vrGroupRec.Part__c != null) {
                	if(vrGroupRec.Is_Order_As_Individual_Item__c) {
                        partIdToOrderAsIndividualItemVRGIdMap.put(vrGroupRec.Part__c, vrGroupRec.Id);
                	} else {
                        partIdToVRGroupIdMap.put(vrGroupRec.Part__c, vrGroupRec.Id);
                	}
                }
            }
            
            Integer counter = 0;
            Set<String> vrGroupIdSetToRecalculatePrice = new Set<String>();
            for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
                if(voliRec.Part__c != null) {
                	if(voliRec.Vendor_Order_Line_Item_Group__c != null && voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                		voliRec.Vendor_Receiving_Group__c = partIdToOrderAsIndividualItemVRGIdMap.get(voliRec.Part__c);
                	} else {
                		voliRec.Vendor_Receiving_Group__c = partIdToVRGroupIdMap.get(voliRec.Part__c);
                	}
                	vrGroupIdSetToRecalculatePrice.add(voliRec.Vendor_Receiving_Group__c);
                } else if(voliRec.Sublet__c != null && voliRec.Vendor_Receiving_Group__c == null) {
                    voliRec.Vendor_Receiving_Group__c = subletVRGIdList[counter];
                    voliRec.Received__c = voliRec.Qty_Needed__c;
                    counter++;
                }
            }
            
            if(voLineItems.size() > 0) {
            	VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
                DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItems);
                VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
            }
            
            vrGroupList = [select Id, Recieved__c, (select Qty_Needed__c from Vendor_Order_Line_Items__r) from Vendor_Receiving_Group__c where 
									Id IN :vrGroupIdSetToRecalculatePrice OR Id IN :subletVRGIdList];
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
                Decimal need = 0;
                for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
                    need += voliRec.Qty_Needed__c;
                }
                vrgRec.Recieved__c = need;
            }

            if(vrGroupList.size() > 0) {
            	//Turning off VOLI trigger to avoid that trigger from VRG's trigger
            	VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupList);
                VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
            }
            return 'Success';
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: addToItemSubsection
     * Desc: Method to add/remove selected vendor order items for receiving
     * @param:  (1) vorId - Id - Selected vendor Receiving Id
     *          (2) partId - Id- Part Id
     *          (3) vendorId - String - Vendor Id
     *          (4) isFromSearchToAdd - Boolean - Search from Add
     *          (5) vendorOrdersPageSortAttrsJSON - String - Vendor Order Headers Grid Paging and sorting JSON
     *          (6) groupItemsPageSortAttrsJSON - String - Items Grid Paging and sorting JSON
     *          (7) outstandingVOGPageSortAttrsJSON - String - Outstanding Grid Paging and sorting JSON
     * @return: String - Json String of Vendor Receiving Header Records 
    **/
    @RemoteAction 
    global static String addToItemSubsection(String vorId, 
                                             String partId, 
                                             String vendorId,
                                             boolean isFromSearchToAdd,
                                             String vendorOrdersPageSortAttrsJSON, 
                                             String groupItemsPageSortAttrsJSON, 
                                             String outstandingVOGPageSortAttrsJSON
                                            ){
        try{
            vorId = BPUtility.getDecodedString(vorId);
            partId = BPUtility.getDecodedString(partId);
            vendorId = BPUtility.getDecodedString(vendorId);
            vendorOrdersPageSortAttrsJSON = BPUtility.getDecodedString(vendorOrdersPageSortAttrsJSON);
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            outstandingVOGPageSortAttrsJSON = BPUtility.getDecodedString(outstandingVOGPageSortAttrsJSON);
            vorId = BPUtility.escapeSingleQuotes(vorId);
            partId = BPUtility.escapeSingleQuotes(partId);
            vendorId = BPUtility.escapeSingleQuotes(vendorId);
            List<Vendor_Order_Line_Item__c> voLineItems = SOQLUtil.getVOLineItemsForGivenPartAndVendorReceiving(partId, vorId);
            if(voLineItems.size() == 0 && isFromSearchToAdd) {
                if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
                if(AccessControl.ifObjectIsAccessible('Vendor_Order_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
                voLineItems = [select Id from Vendor_Order_Line_Item__c where Vendor_Order_Header__r.In_Progress_VR__c != :vorId 
                                                                                AND Part__c =: partId 
                                                                                AND Vendor_Order_Header__r.Vendor__c =: vendorId
                                                                                ];
                if(voLineItems.size() > 0) {                                                                
                    PaginationSorting vendorOrdersPageSortAttrs = PaginationSorting.parsePageAttrs(vendorOrdersPageSortAttrsJSON);
                    PaginationSorting groupItemsPageSortAttrs = PaginationSorting.parsePageAttrs(groupItemsPageSortAttrsJSON);
                    PaginationSorting outstandingVOGPageSortAttrs = PaginationSorting.parsePageAttrs(outstandingVOGPageSortAttrsJSON);
                    
                    VendorOrderReceiving voReceiving = new VendorOrderReceiving(vorId, null, null, vendorOrdersPageSortAttrs, groupItemsPageSortAttrs, outstandingVOGPageSortAttrs);
                    voReceiving.isFoundPartInOtherVOHeader = true;
                    return BPUtility.getEncodedString(System.JSON.serialize(voReceiving));
                } else {
                    addToItemSubsectionAfterConfimation(BPUtility.getEncodedString(vorId),BPUtility.getEncodedString(partId), true, BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON),BPUtility.getEncodedString(groupItemsPageSortAttrsJSON),BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
                } 
            } else {
                return addToItemSubsectionAfterConfimation(BPUtility.getEncodedString(vorId),BPUtility.getEncodedString(partId), false,BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON),BPUtility.getEncodedString(groupItemsPageSortAttrsJSON),BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
            }
            return getVORDetails(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(partId), 
                                    BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON), 
                                    BPUtility.getEncodedString(groupItemsPageSortAttrsJSON), BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: addToItemSubsectionAfterConfimation
     * Desc: Method to add/remove slelected vendor order items for receiving
     * @param:  (1) vorId - Selected vendor Receiving Id
                (2) partId - Id- Part Id
     *          (3) isStockExcessGenerated - Boolean - Stock Excess or not 
     *          (4) vendorOrdersPageSortAttrsJSON - String - Vendor Order Headers Grid Paging and sorting JSON
     *          (5) groupItemsPageSortAttrsJSON - String - Items Grid Paging and sorting JSON
     *          (6) outstandingVOGPageSortAttrsJSON - String - Outstanding Grid Paging and sorting JSON
     * @return: String - Json String of Vendor Receiving Header Records
    **/
    @RemoteAction
    global static String addToItemSubsectionAfterConfimation(String vorId, String partId, Boolean isStockExcessGenerated, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON) {
        try{
            vorId = BPUtility.getDecodedString(vorId);
            partId = BPUtility.getDecodedString(partId);
            vendorOrdersPageSortAttrsJSON = BPUtility.getDecodedString(vendorOrdersPageSortAttrsJSON);
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            outstandingVOGPageSortAttrsJSON = BPUtility.getDecodedString(outstandingVOGPageSortAttrsJSON);
            
            VendorOrderReceivingService.addLineItemFromSTA(vorId, partId, isStockExcessGenerated, null);
            return getVORDetails(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(partId), 
                                BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON), BPUtility.getEncodedString(groupItemsPageSortAttrsJSON), 
                                BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String addLineItemFromSTA(String vorId, String partId, Boolean isStockExcessGenerated, Decimal receivedQty) {
        try{
            vorId = BPUtility.getDecodedString(vorId);
            partId = BPUtility.getDecodedString(partId);
            VendorOrderReceivingService.addLineItemFromSTA(vorId, partId, isStockExcessGenerated, receivedQty);
            return '{"IsSuccess" : true}';
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getBrandingLocationList() {
        try {
            List<BrandingLocationWrapper> brandingLocationObjList = BrandingLocationService.getBrandingLocationList();
            return BPUtility.getEncodedString(system.JSON.serialize(brandingLocationObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: updateItemsSection
     * Desc: Method to update VR Group record qty and cost.
     * @param:  (1) vorId - Vendor Receiving Header Id
     *          (2) partId - Part Id
     *          (3) vrGroupId - Vendor Receiving Group Id which is to be updated
     *          (4) qty - Qtantity Receiving
     *          (5) cost - Cost
     *          (6) vendorOrdersPageSortAttrsJSON - Vendor Order Headers Grid Paging and sorting JSON
     *          (7) groupItemsPageSortAttrsJSON - Items Grid Paging and sorting JSON
     *          (8) outstandingVOGPageSortAttrsJSON - Outstanding Grid Paging and sorting JSON
     * @return: String - JSON String
    **/
    @RemoteAction 
    global static String updateItemsSection(String vorId, String partId, String vrGroupId, Decimal qty, Decimal cost, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        partId = BPUtility.getDecodedString(partId);
        vrGroupId = BPUtility.getDecodedString(vrGroupId);
        
        try {
            VendorOrderReceivingService.updateItemsSection(vrGroupId, qty, cost, null);
            return getVORDetails(vorId, BPUtility.getEncodedString(null), BPUtility.getEncodedString(partId),
                                    vendorOrdersPageSortAttrsJSON, groupItemsPageSortAttrsJSON, outstandingVOGPageSortAttrsJSON);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction 
    global static String updateReceivingLineItem(String vrGroupId, Decimal qty, Decimal cost) {
        vrGroupId = BPUtility.getDecodedString(vrGroupId);
        
        try {
            VendorOrderReceivingService.updateItemsSection(vrGroupId, qty, cost, null);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void validateStatusBeforeUpdateOnVR(String vendorRecId){
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Receiving_Header__c> vRList = [ Select Id, Status__c From Vendor_Receiving_Header__c where Id =: vendorRecId and Status__c != 'In Progress'];
        if(vRList.size() > 0) {
            throw new BlackPurlException('Vendor Receiving is updated by some other process. Please refresh the page.');
        }
    }

    @RemoteAction 
    global static String updateVendorReceivingGroup(String jSONString) {
        jsonString = BPUtility.getDecodedString(jSONString);
        VORGroup vorGrpList = (VORGroup) System.JSON.deserialize(jSONString, VORGroup.class);
        try {
            if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Vendor_Receiving_Group__c> vRList = [Select Id, Vendor_Receiving_Header__r.Status__c From Vendor_Receiving_Group__c where Id =: vorGrpList.Id and Vendor_Receiving_Header__r.Status__c != 'In Progress'];
            if(vRList.size() > 0) {
                throw new BlackPurlException('Vendor Receiving is updated by some other process. Please refresh the page.');
            }
            VendorOrderReceivingService.updateItemsSection(vorGrpList.Id, vorGrpList.ReceivedQty, vorGrpList.Cost , vorGrpList.Discount);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: updateLineItemsOfItemsSection
     * Desc: Method to update VR Group line items (VOLIs) qty.
     * @param:  (1) vorId - Vendor Receiving Header Id
     *          (2) partId - Part Id
     *          (3) vrGroupId - Vendor Receiving Group Id which is to be updated
     *          (4) groupJSONString - JSON String of VR Group record.
     *          (5) vendorOrdersPageSortAttrsJSON - Vendor Order Headers Grid Paging and sorting JSON
     *          (6) groupItemsPageSortAttrsJSON - Items Grid Paging and sorting JSON
     *          (7) outstandingVOGPageSortAttrsJSON - Outstanding Grid Paging and sorting JSON
     * @return: String - JSON String
    **/
    @RemoteAction 
    global static String updateLineItemsOfItemsSection(String vorId, String partId, String vrGroupId, String groupJSONString, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        try{
            vorId = BPUtility.getDecodedString(vorId);
            partId = BPUtility.getDecodedString(partId);
            vrGroupId = BPUtility.getDecodedString(vrGroupId);
            groupJSONString = BPUtility.getDecodedString(groupJSONString);
            vendorOrdersPageSortAttrsJSON = BPUtility.getDecodedString(vendorOrdersPageSortAttrsJSON);
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            outstandingVOGPageSortAttrsJSON = BPUtility.getDecodedString(outstandingVOGPageSortAttrsJSON);
            
            List<VORGroup> vorGrpList = (List<VORGroup>) System.JSON.deserialize(groupJSONString, List<VORGroup>.class);
            Map<Id, Decimal> voliIdToReceivingQtyMap = new Map<Id, Decimal>();
            for(VORGroup vrgObj : vorGrpList) {
                for(VendorOrderLineItem voliRec : vrgObj.VendorOrderLineItemList) {
                    if(!voliIdToReceivingQtyMap.containsKey(voliRec.Id)) {
                        voliIdToReceivingQtyMap.put(voliRec.Id, voliRec.ReceivedQty);
                    } 
                }
            }
            
            if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            vrGroupId = BPUtility.escapeSingleQuotes(vrGroupId);
            List<Vendor_Receiving_Group__c> vrGroupList = [select Id, (select Id, Received__c from Vendor_Order_Line_Items__r) from Vendor_Receiving_Group__c where Id = :vrGroupId];
            
            List<Vendor_Order_Line_Item__c> voliListToUpdate = new List<Vendor_Order_Line_Item__c>();
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
                for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
                    if(voliIdToReceivingQtyMap.containsKey(voliRec.Id)) {
                        voliRec.Received__c = voliIdToReceivingQtyMap.get(voliRec.Id);
                        voliListToUpdate.add(voliRec);
                    }
                }
            }
            
            if(voliListToUpdate.size() > 0) {
                DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voliListToUpdate);
            }
            
            return getVORDetails(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(partId), 
                                    BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON), BPUtility.getEncodedString(groupItemsPageSortAttrsJSON), 
                                    BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    
    /**
     * Name: addAllLineItemsToItemSubsection
     * Desc: Method to add all vendor order items form outstanding Grid to Items Section
     * @param:  (1) vorId - Vendor Receiving Header Id
     *          (2) voHeaderId -  Vendor Order Header Record Id
     *          (3) voGroupId -  Vendor Order Group Record Id
     *          (4) vendorOrdersPageSortAttrsJSON - Vendor Order Headers Grid Paging and sorting JSON
     *          (5) groupItemsPageSortAttrsJSON - Items Grid Paging and sorting JSON
     *          (6) outstandingVOGPageSortAttrsJSON - Outstanding Grid Paging and sorting JSON
     * @return: String - Json String
    **/
    @RemoteAction 
    global static String addAllLineItemsToItemSubsection(String vorId, String voHeaderId, String voGroupId, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        try {
            vorId = BPUtility.getDecodedString(vorId);
            voHeaderId = BPUtility.getDecodedString(voHeaderId);
            voGroupId = BPUtility.getDecodedString(voGroupId);
            
            VendorOrderReceivingService.addAllLineItemsToItemSubsection(vorId, voHeaderId, voGroupId);
            return getVORDetails(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), 
                                vendorOrdersPageSortAttrsJSON, groupItemsPageSortAttrsJSON, outstandingVOGPageSortAttrsJSON);
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    
    /**
     * Name: removeItem
     * Desc: Method to remove VR Group Record
     * @param:  (1) vorId - Selected vendor Receiving Id
     *          (2) vrGroupId - VR Group Id which is to be removed
     *          (3) vendorOrdersPageSortAttrsJSON - Vendor Order Headers Grid Paging and sorting JSON
     *          (4) groupItemsPageSortAttrsJSON - Items Grid Paging and sorting JSON
     *          (5) outstandingVOGPageSortAttrsJSON - Outstanding Grid Paging and sorting JSON
     * @return: String - JSON String
    **/
    @RemoteAction 
    global static String removeItem(String vorId, String vrGroupId, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        try{
            vorId = BPUtility.getDecodedString(vorId);
            validateStatusBeforeUpdateOnVR(vorId);
            vrGroupId = BPUtility.getDecodedString(vrGroupId);
            
            if(AccessControl.ifObjectIsDeletable('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
            delete new Vendor_Receiving_Group__c(Id = vrGroupId);
            
            return 'Success';
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: removeAllItemsFromItemSubSection
     * Desc: Method to remove all VR Group
     * @param:  (1) vorId - Selected vendor Receiving Id
     *          (2) vendorOrdersPageSortAttrsJSON - Vendor Order Headers Grid Paging and sorting JSON
     *          (3) groupItemsPageSortAttrsJSON - Items Grid Paging and sorting JSON
     *          (4) outstandingVOGPageSortAttrsJSON - Outstanding Grid Paging and sorting JSON
     * @return: String - JSON String
    **/
    @RemoteAction 
    global static String removeAllItemsFromItemSubSection(String vorId, String vendorOrdersPageSortAttrsJSON, String groupItemsPageSortAttrsJSON, String outstandingVOGPageSortAttrsJSON){
        try{
            vorId = BPUtility.getDecodedString(vorId);
            vendorOrdersPageSortAttrsJSON = BPUtility.getDecodedString(vendorOrdersPageSortAttrsJSON);
            groupItemsPageSortAttrsJSON = BPUtility.getDecodedString(groupItemsPageSortAttrsJSON);
            outstandingVOGPageSortAttrsJSON = BPUtility.getDecodedString(outstandingVOGPageSortAttrsJSON);
            
            if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            vorId = BPUtility.escapeSingleQuotes(vorId);
            List<Vendor_Receiving_Group__c> vrGroupList = [select Id from Vendor_Receiving_Group__c where Vendor_Receiving_Header__c = :vorId];
            if(vrGroupList.size() > 0) {
                if(AccessControl.ifObjectIsDeletable('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                delete vrGroupList;
            }
            return getVORDetails(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), 
                                BPUtility.getEncodedString(vendorOrdersPageSortAttrsJSON), BPUtility.getEncodedString(groupItemsPageSortAttrsJSON), 
                                BPUtility.getEncodedString(outstandingVOGPageSortAttrsJSON));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    
    /**
     * Name: getPartByPartId
     * Desc: Method which give JSON string of part Record related to given part Id.
     * @param:  (1) partId - String - Part record Id
     * @return: String - JSON String of part Record.
    **/
    @RemoteAction
    global static String getPartByPartId(String partId){
        try{
            return ViewPartCtrl.getPartInfo(partId);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getCoHeaderById
     * Desc: Method which give JSOn string of CO Header Rec Related to Given CO Header Id
     * @param:  (1) coHeaderId - String - CO Header record Id
     * @return: String - JSON String of CO Header Record
    **/
    @RemoteAction
    global static String getCoHeaderById(String coHeaderId){
        try{
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            List<CO_Header__c> coHeaderList = SOQLUtil.getCOHeaderDetails(coHeaderId);
            List<COHeader> coHeaderObjList = new List<COHeader>();
            for(CO_Header__c coHeaderRec : coHeaderList) {
                coHeaderObjList.add(new COHeader(coHeaderRec));
            } 
            return BPUtility.getEncodedString(System.JSON.serialize(coHeaderObjList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getGroupRecDetail
     * Desc: Method which give JSOn string of CO Header Rec Related to Given CO Header Id
     * @param:  (1) coHeaderId - String - CO Header record Id
     * @return: String - JSON String of CO Header Record
    **/
    @RemoteAction
    global static String getGroupRecDetail(String vrGroupId){
        try{
            vrGroupId = BPUtility.getDecodedString(vrGroupId);
            List<Vendor_Receiving_Group__c> vrGroupList = SOQLUtil.getVORGroupsWithItems('Id', vrGroupId);
            List<VRGroupDetail> vrGroupDetailList = new List<VRGroupDetail>();
            for(Vendor_Receiving_Group__c vrGroupRec : vrGroupList) {
                vrGroupDetailList.add(new VRGroupDetail(vrGroupRec));
            } 
            return BPUtility.getEncodedString(System.JSON.serialize(vrGroupDetailList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String commitRecevingAction(String vrHeaderId){
        vrHeaderId = BPUtility.escapeSingleQuotes(BPUtility.getDecodedString(vrHeaderId));
        Savepoint sp = Database.setSavepoint();
        
        VendorOrderLineItemTriggerHelper.isCommitReceivingAction = true;    //To avoid co section logic to run everytime VOLI trigger executes
        List<Vendor_Receiving_Group__c> existingVRGroupList = 
	        [select Ignore_Current_Cost_Update__c, Cost_Update_Reviewed__c, Discount__c, Recieved__c, Cost__c, Part__c, Part__r.Qty_On_Order__c, Part__r.Last_Cost__c, Part__r.Qty_In_Stock__c,
                    Part__r.Packaged_Part__c, Part__r.Package_Qty__c, Part__r.Package_Unit__c, Part__r.Package_Cost__c, Vendor_Receiving_Header__r.Vendor__c, Sublet__c, Vendor_Receiving_Header__r.Is_Receiving_From_Invoice__c, 
                    Vendor_Receiving_Header__r.Packing_Slip_Number__c, Is_Order_As_Individual_Item__c, Vendor_Receiving_Header__r.Status__c, Part__r.Calculated_Cost__c, Part__r.Foreign_Cost__c, Part__r.Foreign_Pkg_Cost__c,
	                Vendor_Receiving_Header__r.Vendor__r.Is_Foreign_Vendor__c, Vendor_Receiving_Header__r.Vendor__r.Country__c,  Vendor_Receiving_Header__r.Vendor__r.Country__r.Conversion_Rate_With_Markup__c, per_Unit_Cost__c, 
    			(SELECT Received__c, Is_required_For_Customer__c, CO_Header__c, CO_Line_Item__c, Is_Service__c, Part__c, Sublet__c, Service_Order_Line_Item__c, 
                Vendor_Order_Header__r.Purchase_Order_Type__r.Update_Current_Cost__c, Vendor_Order_Header__c, Vendor_Order_Header__r.Purchase_Order_Type__c, 
                Vendor_Order_Header__r.Purchase_Order_Type__r.Id FROM Vendor_Order_Line_Items__r), 
                (Select Id FROM Vendor_Receiving_Stock_Excesses__r WHERE Received_Qty__c != null AND Received_Qty__c != 0 LIMIT 1)
	            FROM Vendor_Receiving_Group__c WHERE Vendor_Receiving_Header__c =: vrHeaderId];

        if(existingVRGroupList.isEmpty()) { 
            throw new BlackpurlException('Vendor Receiving has no items to finalize. Please refresh the page.'); 
        } else if(existingVRGroupList[0].Vendor_Receiving_Header__r.Status__c.equalsIgnoreCase('Stocked') || 
            existingVRGroupList[0].Vendor_Receiving_Header__r.Status__c.equalsIgnoreCase('Invoiced')) {
            throw new BlackpurlException('Vendor Receiving is already finalized. Please refresh the page.');
        }
        
        Decimal fxConversionRate = 0;
        String vendorId, invoiceNumber;
        Boolean isReceivingFromInvoice = false;
        Map<Id, Vendor_Order_Line_Item__c> existingVOLineItemMap = new Map<Id, Vendor_Order_Line_Item__c>();
        for(Vendor_Receiving_Group__c vrGroupRec : existingVRGroupList) {
            for(Vendor_Order_Line_Item__c voliRec : vrGroupRec.Vendor_Order_Line_Items__r) {
                voliRec.Line_Item_Cost__c = (vrGroupRec.Cost__c != null) ? vrGroupRec.Cost__c : 0;
                existingVOLineItemMap.put(voliRec.Id, voliRec);
            }
            if(String.isBlank(vendorId)) {
                vendorId = vrGroupRec.Vendor_Receiving_Header__r.Vendor__c;
                if(vrGroupRec.Vendor_Receiving_Header__r.Vendor__r.Is_Foreign_Vendor__c && vrGroupRec.Vendor_Receiving_Header__r.Vendor__r.Country__c != null) {
                    fxConversionRate = vrGroupRec.Vendor_Receiving_Header__r.Vendor__r.Country__r.Conversion_Rate_With_Markup__c;
                }
                isReceivingFromInvoice = vrGroupRec.Vendor_Receiving_Header__r.Is_Receiving_From_Invoice__c;
                invoiceNumber = vrGroupRec.Vendor_Receiving_Header__r.Packing_Slip_Number__c;
            }
        }
        Vendor_Receiving_Header__c vrHeaderRec = updateVRHeader(vrHeaderId, fxConversionRate);
        Map<String, Decimal> partIdToOldPackageCostMap = new Map<String, Decimal>();
        updatePart(existingVRGroupList, vrHeaderId, fxConversionRate, partIdToOldPackageCostMap);
        existingVOLineItemMap = updateRelatedCOLineItem(existingVOLineItemMap, vrHeaderId);
        if(existingVOLineItemMap.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', existingVOLineItemMap.values());
        }
        
        
        // Receiving in case of Stock 
        stockVOLIsReceiving(vrHeaderId);
        
        // Changes in VO Header -   1. Remove Extra In Progress VR List
        //                          2. Update VOLI Group Cost and Received Qty.
        //                          3. Set VO Status.
        
        // Update other VOLIG Cost with Status = "Open/Locked".
        changesRelatedToVOHeader(vrHeaderId, existingVRGroupList, partIdToOldPackageCostMap);
        updateOtherVOLIGCost(existingVRGroupList);
        
        VendorOrderLineItemTriggerHelper.setSpecialOrderStatusOnCO(existingVOLineItemMap.values());
        // Create Activity History.
        if(!Test.isRunningTest()) {
            ActivityHistory.createActivityHistory('Commit Vendor Receiving', 'Vendor Receiving', vrHeaderId, 'Vendor', vendorId, null);
        }
        
        if(isReceivingFromInvoice) {
            return BPUtility.getEncodedString(createVIFromCommitRecevingAction(vendorId, invoiceNumber, vrHeaderRec, existingVRGroupList));
        }
        // Return JSON Status and Finalized date of VR Header
        String vrFinalizedDate = vrHeaderRec.Finalized_Date__c != null ? BPUtility.getFormatedDateTime(vrHeaderRec.Finalized_Date__c) : '';
        return BPUtility.getEncodedString(createVRHeaderJSON(vrHeaderRec.Status__c, vrFinalizedDate));
    }
    
    private static string createVIFromCommitRecevingAction(String vendorId, String invoiceNumber, Vendor_Receiving_Header__c vrHeaderRec, List<Vendor_Receiving_Group__c> vrGroupList) {
        Vendor_Invoicing_Header__c viHeaderRec = new Vendor_Invoicing_Header__c();
        viHeaderRec.Vendor__c = vendorId;
        viHeaderRec.Owner__c = UserInfo.getUserId(); 
        viHeaderRec.Status__c = 'In Progress';
        viHeaderRec.Invoice_Number__c = invoiceNumber;
        DMLUtility.insertSobjectList('Vendor_Invoicing_Header__c', viHeaderRec);
        
        //Auto select vr on vi
        vrHeaderRec.In_Progress_VI__c = viHeaderRec.Id;
        DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vrHeaderRec);
    
        VendorInvoicingCtrl.createVIGFromVRG(viHeaderRec.Id, vrGroupList, vrHeaderRec.Id);
        VendorInvoicingCtrl.updateVendorInvoicingTotal(viHeaderRec.Id);
        return viHeaderRec.Id;
    }
    
    private static Vendor_Receiving_Header__c updateVRHeader(String vrHeaderId, Decimal fxConversionRate) {
        Vendor_Receiving_Header__c vrHeaderRec = new Vendor_Receiving_Header__c(Id = vrHeaderId);
        vrHeaderRec.Status__c = 'Stocked';
        vrHeaderRec.Finalized_VR_Conversion_Rate__c = fxConversionRate;
        vrHeaderRec.Finalized_Date__c = Date.today();
        if(vrHeaderId != null) {
            DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vrHeaderRec);
        }
        return vrHeaderRec;
    }
    
    private static void updatePart(List<Vendor_Receiving_Group__c> existingVRGroupList, String vrHeaderId, Decimal fxConversionRate, Map<String, Decimal> partIdToOldPackageCostMap) {
    	//2 Maps are created to maintain On order qty update on Part rec, as now there can be 2 VOR for 1 part.
        Map<Id, Part__c> partIdToPartToUpdateFirstMap = new Map<Id, Part__c>();
        Map<Id, Part__c> partIdToPartToUpdateSecondMap = new Map<Id, Part__c>();
        
        Map<Id, Vendor_Receiving_Group__c> partIdToVORGroupRecToUpdateFirstMap = new Map<Id, Vendor_Receiving_Group__c>();
        Map<Id, Vendor_Receiving_Group__c> partIdToVORGroupRecToUpdateSecondMap = new Map<Id, Vendor_Receiving_Group__c>();
        
        Part__c partRec;
        PO_Type__c vendorDefaultPOType;
        if(!existingVRGroupList.isEmpty()) {
            List<PO_Type__c> poTypeList = [SELECT Id, Update_Current_Cost__c FROM PO_Type__c WHERE Vendor__c =: existingVRGroupList[0].Vendor_Receiving_Header__r.Vendor__c AND IsDefault__c = true LIMIT 1];
            if(!poTypeList.isEmpty()) {
                vendorDefaultPOType = poTypeList[0];
            }
        }
        for(Vendor_Receiving_Group__c vrGroupRec : existingVRGroupList) {
            if(vrGroupRec.Part__c != null && vrGroupRec.Sublet__c == null) {
                partRec = new Part__c(Id = vrGroupRec.Part__c);
                if((vrGroupRec.Cost_Update_Reviewed__c && !vrGroupRec.Ignore_Current_Cost_Update__c) 
                        || (!vrGroupRec.Cost_Update_Reviewed__c && VendorOrderReceivingService.getCurrentCostUpdateSetting(vrGroupRec, vendorDefaultPOType))) {        
                    partRec.Last_Cost__c = (vrGroupRec.Cost__c != null) ? vrGroupRec.Cost__c : 0;
                    if(fxConversionRate != 0) {
                        partRec.Foreign_Cost__c = partRec.Last_Cost__c;
                        partRec.Last_Cost__c = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(partRec.Last_Cost__c, fxConversionRate); 
                    }
                
                    //Added by Nidhi- To update Package cost when changing cost on VendorReceiving
                    if(vrGroupRec.Part__r.Packaged_Part__c != null && vrGroupRec.Part__r.Packaged_Part__c) {
                        Decimal packageQty = (vrGroupRec.Part__r.Package_Qty__c != null) ? vrGroupRec.Part__r.Package_Qty__c : 1;
                        Decimal pckCost = vrGroupRec.per_Unit_Cost__c != null ? vrGroupRec.per_Unit_Cost__c : (partRec.Last_Cost__c * packageQty);
                        partRec.Package_Cost__c = pckCost;
                        if(fxConversionRate != 0) {
                            partRec.Foreign_Pkg_Cost__c = pckCost;
                            partRec.Package_Cost__c = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(pckCost, fxConversionRate);
                        }

                        partIdToOldPackageCostMap.put(vrGroupRec.Part__c, (vrGroupRec.Part__r.Package_Cost__c != null ? vrGroupRec.Part__r.Package_Cost__c : 0));
                    }
                }

                Decimal receiviedStockQty = 0;
                for(Vendor_Order_Line_Item__c voliRecord : vrGroupRec.Vendor_Order_Line_Items__r) {
                    if(!voliRecord.Is_required_For_Customer__c && !voliRecord.Is_Service__c) {
                        receiviedStockQty += ((voliRecord.Received__c != null) ? voliRecord.Received__c : 0);
                    }
                }
                Decimal currentQtyOnOrder = vrGroupRec.Part__r.Qty_On_Order__c;
                if(partIdToPartToUpdateFirstMap.containsKey(vrGroupRec.Part__c)) {
                	currentQtyOnOrder = partIdToPartToUpdateFirstMap.get(vrGroupRec.Part__c).Qty_On_Order__c;
                }
                
                partRec.Qty_On_Order__c = currentQtyOnOrder - receiviedStockQty;
                if(partRec.Qty_On_Order__c < 0) {
                    partRec.Qty_On_Order__c = 0;
                }
                partRec.Qty_In_Stock__c = vrGroupRec.Recieved__c; // This is Used for Creating In stock Qty of FIFO bucket.
                
                if(!partIdToPartToUpdateFirstMap.containsKey(partRec.Id)) {
                	partIdToPartToUpdateFirstMap.put(partRec.Id, partRec);
                	partIdToVORGroupRecToUpdateFirstMap.put(partRec.Id, vrGroupRec);
                } else {
                	partIdToPartToUpdateSecondMap.put(partRec.Id, partRec);
                	partIdToVORGroupRecToUpdateSecondMap.put(partRec.Id, vrGroupRec);
                }
            }
        }
        // Create FIFO Bucket AND Udpate Part Record
        if(partIdToPartToUpdateFirstMap.size() > 0) {
            FIFOTransaction.createFIFOBucketForVendorReceiving(partIdToPartToUpdateFirstMap, vrHeaderId, partIdToVORGroupRecToUpdateFirstMap, fxConversionRate);
        }
        if(partIdToPartToUpdateSecondMap.size() > 0) {
        	FIFOTransaction.createFIFOBucketForVendorReceiving(partIdToPartToUpdateSecondMap, vrHeaderId, partIdToVORGroupRecToUpdateSecondMap, fxConversionRate);
        }
    }
    
    // This method is for Only merch section.
    private static Map<Id, Vendor_Order_Line_Item__c> updateRelatedCOLineItem(Map<Id, Vendor_Order_Line_Item__c> existingVOLineItemMap, String vrHeaderId) {
        Set<Id> coliIdSet = new Set<Id>();
        Set<Id> subletSOLISet = new Set<Id>();
        Set<String> soliUnresolvedFulfilmentIdSet = new Set<String>();
    	Id dealId;
        Savepoint sp = Database.setSavepoint();
        for(Vendor_Order_Line_Item__c voliRec : existingVOLineItemMap.values()) {
            if(voliRec.Part__c != null) {
                coliIdSet.add(voliRec.CO_Line_Item__c);
            } else if(voliRec.Sublet__c != null) {
                subletSOLISet.add(voliRec.Service_Order_Line_Item__c);
            }
        }
        if(coliIdSet.size() == 0 && subletSOLISet.size() == 0) {
            return new Map<Id, Vendor_Order_Line_Item__c>();
        }
        List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
        List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
        List<Vendor_Order_Line_Item__c> voliListToInsert = new List<Vendor_Order_Line_Item__c>();
        if(subletSOLISet.size() > 0) {
            List<Service_Order_Line_Item__c> solineItemList = 
                    [SELECT Qty_Committed__c, Qty_Needed__c, Status__c,Deal__c,Service_Order_Header__c,Service_Order_Header__r.Deal__c, 
                            (select Vendor_Order_Line_Item_Group__c, Qty_Needed__c, Received__c, Is_Received__c, Vendor_Receiving_Group__r.Cost__c, 
                                Vendor_Receiving_Group__r.Vendor_Receiving_Header__c, Status__c, Vendor_Receiving_Group__r.Recieved__c from Vendor_Order_Line_Items__r 
                                where Is_Received__c = false)
                        FROM Service_Order_Line_Item__c WHERE Id IN: subletSOLISet];
            for(Service_Order_Line_Item__c soliRec : solineItemList) {
                Decimal receivedQty = 0;
                Decimal cost = 0;
                for(Vendor_Order_Line_Item__c voliRec : soliRec.Vendor_Order_Line_Items__r) {
                    if(voliRec.Vendor_Order_Line_Item_Group__c != null && voliRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__c == vrHeaderId) {
                        receivedQty = (voliRec.Vendor_Receiving_Group__r.Recieved__c != null) ? voliRec.Vendor_Receiving_Group__r.Recieved__c : 0;
                        cost = voliRec.Vendor_Receiving_Group__r.Cost__c != null ? voliRec.Vendor_Receiving_Group__r.Cost__c : 0;
                        if(existingVOLineItemMap.containsKey(voliRec.Id)) {
                            existingVOLineItemMap.get(voliRec.Id).Status__c = 'Received';
                            existingVOLineItemMap.get(voliRec.Id).Is_Received__c = true;
                        }
                    }
                }
                if(receivedQty > 0) {
                    Decimal previousQty = soliRec.Qty_Needed__c; 
                    soliRec.Qty_Committed__c = ((soliRec.Qty_Committed__c != null) ? (soliRec.Qty_Committed__c + receivedQty) : receivedQty);
                    soliRec.Qty_Needed__c = soliRec.Qty_Committed__c;
                    soliRec.Status__c = 'Ready';
                    soliRec.Cost__c = cost;
                    soliListToUpdate.add(soliRec);
                    if(soliRec.Service_Order_Header__r.Deal__c != null && receivedQty != previousQty){
		    			soliUnresolvedFulfilmentIdSet.add(soliRec.Id);
		    			dealId = soliRec.Service_Order_Header__r.Deal__c;
		    		}	
                }
            }
        }
        
        if(coliIdSet.size() > 0) {
            List<CO_Line_Item__c> colineItemList = 
                    [SELECT Qty__c, Qty_Committed__c, Special_Order__c, CO_Kit_Header__c, CO_Header__c, Part__c, Price__c, Tax__c, 
                            Service_Order_Line_Item__c, Vendor_Order_Header__c,
                            (select Vendor_Order_Line_Item_Group__c, CO_Header__c, Vendor_Receiving_Group__c, Vendor_Order_Header__c, CO_Line_Item__c, 
                                    Part__c, Qty_Needed__c, Received__c, Qty_Ordered__c, Is_Received__c, Is_Excess__c, Is_From_Search__c, 
                                    Is_required_For_Customer__c, Is_Service__c, Vendor_Receiving_Group__r.Vendor_Receiving_Header__c, 
                                    Vendor_Order_Line_Item_Group__r.VOG_Cost__c, Status__c, Line_Item_Cost__c from Vendor_Order_Line_Items__r 
                                where Is_Received__c = false)
                        FROM CO_Line_Item__c WHERE Id IN: coliIdSet];
        
            Decimal receivedQty;
            for(CO_Line_Item__c coliRec : colineItemList) {
                receivedQty = 0;
                for(Vendor_Order_Line_Item__c voliRec : coliRec.Vendor_Order_Line_Items__r) {
                    if(voliRec.Vendor_Order_Line_Item_Group__c != null && voliRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__c == vrHeaderId){
                        receivedQty += ((voliRec.Received__c != null) ? voliRec.Received__c : 0);
                    }
                }
                
                if(receivedQty > 0) {
                    coliRec.Qty_Committed__c = ((coliRec.Qty_Committed__c != null) ? (coliRec.Qty_Committed__c + receivedQty) : receivedQty);
                    if(coliRec.Qty__c == coliRec.Qty_Committed__c) {
                        coliRec.Status__c = 'In Stock';
                        coliRec.VO_Status__c = 'Received';
                    }
                    if(coliRec.Service_Order_Line_Item__c != null) {
                        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Id = coliRec.Service_Order_Line_Item__c);
                        soliRec.Qty_Committed__c = coliRec.Qty_Committed__c;
                        soliListToUpdate.add(soliRec);
                    }
                }
                
                // Breaking of VO Line Items in both case - In COLI, SOLI, CO Kit Header. Because now only VOLI is breaking, not COLI.
                List<Vendor_Order_Line_Item__c> relatedVOLineItemList = new List<Vendor_Order_Line_Item__c>();
                for(Vendor_Order_Line_Item__c voliRec : coliRec.Vendor_Order_Line_Items__r) {
                    if(voliRec.Vendor_Order_Line_Item_Group__c != null && voliRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__c == vrHeaderId) {
                        voliRec.Received__c = (voliRec.Received__c != null) ? voliRec.Received__c : 0;
                        
                        if(voliRec.Qty_Needed__c > voliRec.Received__c && voliRec.Received__c > 0) {
                            Vendor_Order_Line_Item__c voliCloneRec = voliRec.clone(false, false, false, false);
                            voliCloneRec.Received__c = 0;
                            voliCloneRec.Qty_Needed__c = (voliRec.Qty_Needed__c - voliRec.Received__c);
                            voliCloneRec.Status__c = 'Ordered';
                            voliListToInsert.add(voliCloneRec);
                            
                            // Reduce Qty Needed Same as Received Qty
                            voliRec.Qty_Needed__c = voliRec.Received__c;
                            voliRec.Status__c = 'Received';
                            voliRec.Is_Received__c = true;
                        
                            // Set Status of COLIs in case of Partial Receiving
                            coliRec.Status__c = 'Ordered';
                            coliRec.VO_Status__c = 'On Order';
                        }
                        relatedVOLineItemList.add(voliRec);
                    }
                }
                
                
                // Set VOLI status and Line Item Cost
                for(Vendor_Order_Line_Item__c voliRec : relatedVOLineItemList) {
                    if(voliRec.Qty_Needed__c == voliRec.Received__c) {
                        if(existingVOLineItemMap.containsKey(voliRec.Id)) {
                            existingVOLineItemMap.get(voliRec.Id).Status__c = 'Received';
                            existingVOLineItemMap.get(voliRec.Id).Is_Received__c = true;
                            existingVOLineItemMap.get(voliRec.Id).Qty_Needed__c = existingVOLineItemMap.get(voliRec.Id).Received__c;
                        }
                    }
                }
                
                // Set Status of COLI if there is already a required Line item present
                for(Vendor_Order_Line_Item__c voliRec : coliRec.Vendor_Order_Line_Items__r) {
                    if(voliRec.Vendor_Order_Line_Item_Group__c == null) {
                        coliRec.Status__c = 'Required';
                        coliRec.VO_Status__c = null;
                    }
                } 
                coliRec.Special_Order__c = false;
                coliListToUpdate.add(coliRec);
            }
        }
        
        if(soliListToUpdate.size() > 0) {
            ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
            COLineItemTriggerHelper.isVOLIInsertFromVRPage = false;
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);

            // To update Is Invoicable check box.
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
            //Creating unresolved Fulilment for Sublet if Any qty updated during VR
	        if(soliUnresolvedFulfilmentIdSet.size() > 0) {
	        	DealService.createDealUnresolvedFulfillment(new List<String>(soliUnresolvedFulfilmentIdSet), dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED);
	        }
        }
        
        if(coliListToUpdate.size() > 0) {
            COLineItemTriggerHelper.isTriggerExecute = false;
            COLineItemTriggerHelper.isVOLIInsertFromVRPage = false;
            
            DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);
        }
        
        if(voliListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Vendor_Order_Line_Item__c', voliListToInsert);
        }
        
        return existingVOLineItemMap;
    }
    
    private static void stockVOLIsReceiving(String vrHeaderId) {
        List<Vendor_Order_Line_Item__c> volis = 
                [SELECT Part__c, Sublet__c, CO_Header__c, Vendor_Order_Line_Item_Group__c, Line_Item_Cost__c, Vendor_Order_Header__c, Is_Service__c, Is_Excess__c, 
                        CO_Line_Item__c, CO_Line_Item__r.Qty_Committed__c, Is_required_For_Customer__c, Qty_Needed__c, Received__c, 
                        Vendor_Receiving_Group__c, Vendor_Order_Line_Item_Group__r.VOG_Cost__c, Cost__c 
                    FROM Vendor_Order_Line_Item__c Where Vendor_Receiving_Group__r.Vendor_Receiving_Header__c =: vrHeaderId];
        
        // Stocking Partial Receiving
        List<Vendor_Order_Line_Item__c> stockVOLIListToInsert = new List<Vendor_Order_Line_Item__c>();
        List<Vendor_Order_Line_Item__c> stockVOLIListToUpdate = new List<Vendor_Order_Line_Item__c>();
        for(Vendor_Order_Line_Item__c voliRec : volis) {
            if(voliRec.Part__c != null && voliRec.Sublet__c == null && !voliRec.Is_required_For_Customer__c && !voliRec.Is_Service__c && 
                    voliRec.Qty_Needed__c > voliRec.Received__c && voliRec.Received__c > 0) {
                        
                Vendor_Order_Line_Item__c newVoliRec = new Vendor_Order_Line_Item__c();
                newVoliRec = voliRec.clone(false, true, false, false);
                newVoliRec.Received__c = 0;
                newVoliRec.Line_Item_Cost__c = (voliRec.Vendor_Order_Line_Item_Group__r.VOG_Cost__c != null) ? 
                                                    voliRec.Vendor_Order_Line_Item_Group__r.VOG_Cost__c : voliRec.Cost__c;
                newVoliRec.Qty_Needed__c = voliRec.Qty_Needed__c - voliRec.Received__c;
                newVoliRec.Vendor_Receiving_Group__c = null;
                newVoliRec.Status__c = 'Ordered';
                stockVOLIListToInsert.add(newVoliRec);
                
                voliRec.Qty_Needed__c = voliRec.Received__c;
            }
            if(voliRec.Received__c == 0) {
                voliRec.Vendor_Receiving_Group__c = null;
                voliRec.Line_Item_Cost__c = (voliRec.Vendor_Order_Line_Item_Group__r.VOG_Cost__c != null) ? 
                                                voliRec.Vendor_Order_Line_Item_Group__r.VOG_Cost__c : voliRec.Cost__c;
            }
            stockVOLIListToUpdate.add(voliRec); 
        }
        
        for(Vendor_Order_Line_Item__c voliRec : stockVOLIListToUpdate) {
            if(voliRec.Received__c > 0 && voliRec.Qty_Needed__c == voliRec.Received__c) {
                voliRec.Status__c = 'Received';
                voliRec.Is_Received__c = true;
            }
        }
        
        if(stockVOLIListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Vendor_Order_Line_Item__c', stockVOLIListToInsert);
        } 
        
        if(stockVOLIListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', stockVOLIListToUpdate);
        }
    }
    
    private static void changesRelatedToVOHeader(String vrHeaderId, List<Vendor_Receiving_Group__c> existingVRGroupList, Map<String, Decimal> partIdToOldPackageCostMap) {
        List<In_Progress_VR__c> ipvrList = [SELECT Vendor_Order_Header__c from In_Progress_VR__c WHERE Vendor_Receiving_Header__c =: vrHeaderId];
        Set<Id> voHeaderIdSet = new Set<Id>();
        for(In_Progress_VR__c ipvrRec : ipvrList) {
            voHeaderIdSet.add(ipvrRec.Vendor_Order_Header__c);
        }
        
        // Add VO Header Ids from related VO Line Items records in case of STA - #12859
        for(Vendor_Receiving_Group__c vrGroup : existingVRGroupList) {
            for(Vendor_Order_Line_Item__c voliRec : vrGroup.Vendor_Order_Line_Items__r) {
                voHeaderIdSet.add(voliRec.Vendor_Order_Header__c);
            }
        }
        voHeaderIdSet.remove(null);
        
        // 1. Delete Extra generated In Progress VR records - Hips Issues - 05/21/2017
        Set<Id> extraVOHeaderIdSet = removeExtraInProgressVR(ipvrList, voHeaderIdSet, existingVRGroupList);
        
        // 2. Update VOLI Group Cost and Received Qty.
        if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = 
                [SELECT Vendor_Order_Header__c, Need__c, Received_Qty__c, Status__c, Cost__c, VOG_Cost__c, Per_Unit_Cost__c,
                            Part__r.Packaged_Part__c, Part__r.Package_Qty__c, Part__r.Package_Cost__c, Is_Order_As_Individual_Item__c, 
                            (Select Line_Item_Cost__c, Cost__c, Received__c, Qty_Needed__c, 
                            Vendor_Receiving_Group__r.Per_Unit_Cost__c from Vendor_Order_Line_Items__r) 
                        FROM Vendor_Order_Line_Item_Group__c 
                        WHERE Vendor_Order_Header__c IN :voHeaderIdSet AND Vendor_Order_Header__c NOT IN: extraVOHeaderIdSet];
                        
        Map<String, List<Vendor_Order_Line_Item_Group__c>> voIdToVOLineGroupListMap = new Map<String, List<Vendor_Order_Line_Item_Group__c>>();
        for(Vendor_Order_Line_Item_Group__c voliGroup : voliGroupList) {
            if(!voIdToVOLineGroupListMap.containsKey(voliGroup.Vendor_Order_Header__c)) {
                voIdToVOLineGroupListMap.put(voliGroup.Vendor_Order_Header__c, new List<Vendor_Order_Line_Item_Group__c>());
            }
            voIdToVOLineGroupListMap.get(voliGroup.Vendor_Order_Header__c).add(voliGroup);
        }
        
        Map<Id, Vendor_Order_Header__c> voHeaderMapToUpdate = new Map<Id, Vendor_Order_Header__c>();
        for(String voHeaderId : voIdToVOLineGroupListMap.keySet()) {
            Set<String> voliGroupStatusSet = new Set<String>();
	        for(Vendor_Order_Line_Item_Group__c volig : voIdToVOLineGroupListMap.get(voHeaderId)) {
	            Decimal voligTotalCost = 0;
	            Decimal receivedQty = 0;
	            Decimal neededQty = 0;
                Boolean isPkgPart = (volig.Part__c != null && volig.Part__r.Packaged_Part__c && !volig.Is_Order_As_Individual_Item__c);

	            for(Vendor_Order_Line_Item__c voliRec : volig.Vendor_Order_Line_Items__r) {
	                //Added by Nidhi - To update Cost on VOLIG when updating cost on VR page, 
	                // On voli cost is formula field so it gets automatically update, but volig should be updated to update total on home search
	                receivedQty += ((voliRec.Received__c != null) ? voliRec.Received__c : 0);
	                voliRec.Line_Item_Cost__c = (voliRec.Line_Item_Cost__c == null) ? 0 : voliRec.Line_Item_Cost__c;
	                voliRec.Received__c = (voliRec.Received__c == null) ? 0 : voliRec.Received__c;
	                voliRec.Qty_Needed__c = (voliRec.Qty_Needed__c == null) ? 0 : voliRec.Qty_Needed__c;
	                
	                if(voliRec.Qty_Needed__c == voliRec.Received__c) {
                        if(isPkgPart && voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c != null) {
                            voligTotalCost += (voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c * (voliRec.Received__c/volig.Part__r.Package_Qty__c));
                        } else {
                            voligTotalCost += (voliRec.Line_Item_Cost__c * voliRec.Received__c);
                        }
	                } else if((voliRec.Qty_Needed__c > voliRec.Received__c) && (voliRec.Received__c != 0)) {
                        if(isPkgPart && voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c != null) {
                            voligTotalCost += (((voliRec.Qty_Needed__c - voliRec.Received__c) * voliRec.Line_Item_Cost__c) + (voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c * (voliRec.Received__c/volig.Part__r.Package_Qty__c)));
                        } else {
                            voligTotalCost += (((voliRec.Qty_Needed__c - voliRec.Received__c) * voliRec.Line_Item_Cost__c) + (voliRec.Cost__c * voliRec.Received__c));
                        }
	                } else if(voliRec.Received__c == 0) {
                        if(volig.Per_Unit_Cost__c != null) {
                            voligTotalCost += ((isPkgPart ? volig.Per_Unit_Cost__c/volig.Part__r.Package_Qty__c : volig.Per_Unit_Cost__c) * voliRec.Qty_Needed__c);
                        } else if(volig.VOG_Cost__c != null) {
                            voligTotalCost += (volig.VOG_Cost__c * voliRec.Qty_Needed__c);
                        } else {
                            voligTotalCost += (voliRec.Line_Item_Cost__c * voliRec.Qty_Needed__c);
                        }
	                }
	                neededQty += (voliRec.Qty_Needed__c);
	            }
	            if(volig.Vendor_Order_Line_Items__r.size() > 0 && neededQty != 0) {
	                volig.Per_Unit_Cost__c = volig.Cost__c = (voligTotalCost / neededQty).setScale(2);
                    if(isPkgPart && volig.Part__r.Package_Qty__c != null && volig.Part__r.Package_Qty__c != 0) {
                    volig.Per_Unit_Cost__c = (voligTotalCost / (neededQty/volig.Part__r.Package_Qty__c)).setScale(2);
                    }
                    volig.Total__c = voligTotalCost;
	            }
	            volig.Received_Qty__c = receivedQty;
            
            	// Setting VO Status per VOLI Group. Since There may be multiple VO Header, So this should be in for Loop.
	            if(volig.Received_Qty__c == volig.Need__c) {
	                voliGroupStatusSet.add('Received');
	            } else if(volig.Received_Qty__c > 0 && volig.Status__c != 'Cancelled') {
	                voliGroupStatusSet.add('Partially Received');
	                
	            } else if(volig.Received_Qty__c == 0 && volig.Status__c != 'Cancelled') {
	                voliGroupStatusSet.add('On Order');
	            }
	        }
	        
	        if(voliGroupStatusSet.size() > 0) {
                String voStatus;
                List<String> voliGroupStatusList = new List<String>(voliGroupStatusSet);
                if(voliGroupStatusList.size() == 1) {
                    if(voliGroupStatusList[0] == 'Received' || voliGroupStatusList[0] == 'Partially Received') {
                        voStatus = voliGroupStatusList[0];
                    }
                } else if(voliGroupStatusList.size() > 1) {
                    voStatus = 'Partially Received';
                }
                
                if(String.isNotBlank(voStatus)) {
                    Vendor_Order_Header__c voHeaderRec = new Vendor_Order_Header__c(Id = voHeaderId);
                    voHeaderRec.Status__c = voStatus;
                    voHeaderMapToUpdate.put(voHeaderRec.Id, voHeaderRec);
                }
            }
        }
        
        if(voliGroupList.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voliGroupList);
        }
        
        if(voHeaderMapToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Header__c', voHeaderMapToUpdate.values());
        }
    }
    
    private static String createVRHeaderJSON(String vrHeaderStatus, String vrFinalizedDate) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Status', vrHeaderStatus); 
        gen.writeStringField('FinalizedDate', vrFinalizedDate);
        gen.writeEndObject();
        String jsonString = gen.getAsString();
        return jsonString;
    }
    
    private static Set<Id> removeExtraInProgressVR(List<In_Progress_VR__c> ipvrList, Set<Id> voHeaderIdSet, List<Vendor_Receiving_Group__c> vrGroupList) {
        List<In_Progress_VR__c> inProgressListToDelete = new List<In_Progress_VR__c>();
        Map<Id, Vendor_Order_Header__c> relatedVOHeaderMap = 
                    new Map<Id, Vendor_Order_Header__c>([select Id, (select Vendor_Receiving_Group__c from Vendor_Order_Line_Items__r 
                                                                    where Vendor_Receiving_Group__c IN: vrGroupList)
                                                            from Vendor_Order_Header__c where Id IN: voHeaderIdSet]);
                                                                
        Set<Id> vrgIdSet = new Set<Id>();
        for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
            vrgIdSet.add(vrgRec.Id);
        }
        
        Set<Id> extraVOHeaderIdSet = new Set<Id>();
        for(In_Progress_VR__c inProgressRec : ipvrList) {
            if(relatedVOHeaderMap.containsKey(inProgressRec.Vendor_Order_Header__c)) {
                Boolean isIvprDelete = true;
                for(Vendor_Order_Line_Item__c voliRec : relatedVOHeaderMap.get(inProgressRec.Vendor_Order_Header__c).Vendor_Order_Line_Items__r) {
                    if(vrgIdSet.contains(voliRec.Vendor_Receiving_Group__c)) {
                        isIvprDelete = false;
                        break;
                    }
                }
                if(isIvprDelete) {
                    extraVOHeaderIdSet.add(inProgressRec.Vendor_Order_Header__c);
                    inProgressListToDelete.add(inProgressRec);
                }
            }
        }
        
        if(inProgressListToDelete.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('In_Progress_VR__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete inProgressListToDelete;
        }
        extraVOHeaderIdSet.remove(null);
        return extraVOHeaderIdSet;
    }
    
    
    // Update other VOLIG Cost with Status = "Open/Locked".
    private static void updateOtherVOLIGCost(List<Vendor_Receiving_Group__c> vrGroupList) {
        // Create part Id Set
        Set<Id> partIdSet = new Set<Id>();
        for(Vendor_Receiving_Group__c vrGroupRec : vrGroupList) {
            partIdSet.add(vrGroupRec.Part__c);
        } 
        partIdSet.remove(null);
        if(partIdSet.size() == 0) {
            return;
        }
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = [Select Need__c, Part__r.Packaged_Part__c, Part__r.Package_Qty__c, 
        Is_Order_As_Individual_Item__c, Part__r.Calculated_Cost__c, Part__r.Calculated_Package_Cost__c 
                                from Vendor_Order_Line_Item_Group__c 
                                where Part__c IN: partIdSet AND 
                                    (Vendor_Order_Header__r.Status__c = 'Open' OR Vendor_Order_Header__r.Status__c = 'Locked')];
                                 
        for(Vendor_Order_Line_Item_Group__c voligRec : voliGroupList) {
            Decimal voligCost = 0;
            Decimal totalQty = 0;
            if(voligRec.Part__r.Packaged_Part__c && !voligRec.Is_Order_As_Individual_Item__c) {
                voligRec.Cost__c = voligRec.Part__r.Calculated_Cost__c;
                voligRec.Per_Unit_Cost__c = voligRec.Part__r.Calculated_Package_Cost__c;
            } else {
                voligRec.Per_Unit_Cost__c = voligRec.Cost__c = voligRec.Part__r.Calculated_Cost__c;
            }
        }
        if(voliGroupList.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voliGroupList);
        }
    }
    
    @RemoteAction
    global static String deleteVendorOrderRecieving(String vorId){
        try{ 
            vorId = BPUtility.getDecodedString(vorId);
            vorId = BPUtility.escapeSingleQuotes(vorId);
            if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            List<Vendor_Receiving_Header__c> vorHeaderRecList = [Select Status__c, In_Progress_VI__c, (Select Id From Vendor_Receiving_Groups__r) From Vendor_Receiving_Header__c  where ID =: vorId];
            
            String response = 'Error';
            if(vorHeaderRecList.size() > 0){
                if(vorHeaderRecList[0].Status__c == 'In Progress' && vorHeaderRecList[0].Vendor_Receiving_Groups__r.size() == 0){
                    Vendor_Receiving_Header__c viReceivingHeader = new Vendor_Receiving_Header__c(Id = vorHeaderRecList[0].Id);
                    
                    List<In_Progress_VR__c> IPVRList = [select Id from In_Progress_VR__c
                                                        Where Vendor_Receiving_Header__c = :vorId];
                    
                    if(AccessControl.ifObjectIsDeletable('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                    delete viReceivingHeader;
                    
                    if(AccessControl.ifObjectIsDeletable('In_Progress_VR__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                    if(IPVRList.size() > 0){
                        delete IPVRList;
                    }
                    response = 'Success';
                }
            }
            return BPUtility.getEncodedString(response);
            
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getLabelPrintingData(String vrHeaderId){
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        List<Vendor_Receiving_Group__c> vrGroupList = SOQLUtil.getVORGroupsWithItems('Vendor_Receiving_Header__c', vrHeaderId);
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        Business_Profile__c businessProfileRec = new Business_Profile__c();
        if(businessProfileList.size() > 0) {
            businessProfileRec = businessProfileList[0];
        }
        List<LabelPrinting> labelPrintingList = new List<LabelPrinting>();
        Boolean isPackagedPartAlreadyAddedAsStock;
        for(Vendor_Receiving_Group__c vrGroupRec : vrGroupList) {
            isPackagedPartAlreadyAddedAsStock = false;
            for(Vendor_Order_Line_Item__c voLineItemRec : vrGroupRec.Vendor_Order_Line_Items__r) {
                if(voLineItemRec.Part__c != null) {
                    if(!voLineItemRec.Is_required_For_Customer__c && !voLineItemRec.Is_Service__c && voLineItemRec.Part__r.Packaged_Part__c && isPackagedPartAlreadyAddedAsStock) {
                        continue;
                    } 
                    if(!voLineItemRec.Is_required_For_Customer__c && !voLineItemRec.Is_Service__c && voLineItemRec.Part__r.Packaged_Part__c) {
                        isPackagedPartAlreadyAddedAsStock = true;
                    }
                    labelPrintingList.add(new LabelPrinting(voLineItemRec, businessProfileRec));
                }
            }
            for(Vendor_Receiving_Stock_Excess__c vrStockExcessRec : vrGroupRec.Vendor_Receiving_Stock_Excesses__r) {
                if(vrStockExcessRec.Vendor_Receiving_Group__r.Part__c != null) {
                    if(vrStockExcessRec.Vendor_Receiving_Group__r.Part__r.Packaged_Part__c && isPackagedPartAlreadyAddedAsStock) {
                        continue;
                    }
                    if(vrStockExcessRec.Vendor_Receiving_Group__r.Part__r.Packaged_Part__c) {
                        isPackagedPartAlreadyAddedAsStock = true;
                    }
                    labelPrintingList.add(new LabelPrinting(vrStockExcessRec, businessProfileRec));
                }
            }
        }
        return BPUtility.getEncodedString(System.JSON.serialize(labelPrintingList));
    }
    
    @RemoteAction
    global static String getFilteredVRItemsByGridName(String vorId, String gridName, String searchStr, String pageSortAttr) {
        vorId = BPUtility.getDecodedString(vorId);
        gridName = BPUtility.getDecodedString(gridName);
        searchStr = BPUtility.getDecodedString(searchStr);
        pageSortAttr = BPUtility.getDecodedString(pageSortAttr);
        
        if(String.isNotBlank(vorId) && String.isNotBlank(gridName)) {
    		VendorOrderReceiving voReceiving = new VendorOrderReceiving(vorId, gridName, searchStr, PaginationSorting.parsePageAttrs(pageSortAttr));
    		return BPUtility.getEncodedString(System.JSON.serialize(voReceiving, true));
        }
        return '';
    }
    
    @RemoteAction
    global static String getSupercededPartsByVRId(String vrHeaderId){
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        Set<String> partIds = VendorOrderReceivingService.getVendorOrderReceivingPartIds(new Set<String>{vrHeaderId});
        return BPUtility.getEncodedString(System.JSON.serialize(SupersededPartService.getSupersededParts(partIds)));
    }

    @RemoteAction
    global static String getReallocatePartDetails(String vrHeaderId, String requestJson) {
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.getReallocatePartDetails(BPUtility.getDecodedString(vrHeaderId), BPUtility.getDecodedString(requestJson)), true));
    }

    //This method is deprecated
    @RemoteAction
    global static void reallocatePartsOnOrderQty(String reallocatePartsOnOrderJson) {}

    @RemoteAction
    global static String reallocatePartsOnSpecialOrderQty(String reallocatePartsOnOrderJson) {
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.reallocatePartsOnOrderQty(BPUtility.getDecodedString(reallocatePartsOnOrderJson))));
    }

    @RemoteAction
    global static String reallocatePartsOversoldQty(String vrHeaderId, String reallocatePartsOversoldJson) {
        return VendorOrderReceivingService.reallocatePartsOversoldQty(BPUtility.getDecodedString(vrHeaderId), BPUtility.getDecodedString(reallocatePartsOversoldJson));
    }
    
    @RemoteAction
    global static String supersedeVRPart(String vrHeaderId, String vrgId, String supersededPartId) {
        vrHeaderId = BPUtility.getDecodedString(vrHeaderId);
        validateStatusBeforeUpdateOnVR(vrHeaderId);
        vrgId = BPUtility.getDecodedString(vrgId);
        supersededPartId = BPUtility.getDecodedString(supersededPartId);
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.supersedeVRPart(vrHeaderId, vrgId, supersededPartId)));
    }

    @RemoteAction
    global static string getPartToSupersededPart(String partId) {
        partId = BPUtility.getDecodedString(partId);
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.getPartToSupersededPart(partId)));
    }

    @RemoteAction
    global static string validateSupersededVRPart(String partId, String supersededPartId) {
        partId = BPUtility.getDecodedString(partId);
        supersededPartId = BPUtility.getDecodedString(supersededPartId);
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.validateSupersededVRPart(partId, supersededPartId)));
    }

    @RemoteAction
    global static String getVRGsCurrentCostSetting(String vrHeaderId) {
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.getVRGsCurrentCostSetting(BPUtility.getDecodedString(vrHeaderId))));
    }

    @RemoteAction
    global static void saveVRGsCurrentCostSetting(String vrgCurrentCostSettingListStr) {
        VendorOrderReceivingService.saveVRGsCurrentCostSetting(BPUtility.getDecodedString(vrgCurrentCostSettingListStr));
    }

    @RemoteAction
    global static void savePartDetails(String partJson) {
        VendorOrderReceivingService.savePartDetails(BPUtility.getDecodedString(partJson));
    }
    
    @RemoteAction
    global static String getActiveVRCountByVendorId(String vendorId) {
    	return BPUtility.getEncodedString(VendorOrderReceivingService.getActiveVRCountByVendorId(BPUtility.getDecodedString(vendorId)));
    }
    
    @RemoteAction
    global static String getActiveVRsByVendorId(String filterJsonStr) {
        return BPUtility.getEncodedString(System.JSON.serialize(VendorOrderReceivingService.getActiveVRsByVendorId(BPUtility.getDecodedString(filterJsonStr))));
    }
    
    @RemoteAction
    global static String validateReopening(String vrId) {
        try {
        	return BPUtility.getEncodedString(System.JSON.serialize(new ReopenVRService().validateReopening(BPUtility.getDecodedString(vrId))));
        } catch(Exception e) {
            ReopenCOValidationWrapper reopenValidationWrapperObj = new ReopenCOValidationWrapper();
        	reopenValidationWrapperObj.ErrorMsg = e.getMessage();
            return BPUtility.getEncodedString(System.JSON.serialize(reopenValidationWrapperObj, true));
        }
    }

    @RemoteAction
    global static String reopenVR(String vrId) {
        vrId = BPUtility.getDecodedString(vrId);
        try {
        	return BPUtility.getEncodedString(System.JSON.serialize(new ReopenVRService().reopenVR(vrId), true));
        } catch(Exception e) {
            new LogService().createErrorLog('VendorOrderReceivingCtrl', 'reopenVR()', e.getMessage(), null, e.getStackTraceString(), 
            vrId, LogService.REOPEN_INVOICE, true, 'Info');
            return 'error';
        }
    }

    public class LabelPrinting {
        
        public String ProductDesc;
        public String Id;
        public Boolean IsSelected;
        public Decimal NoOfStockLabels;
        public Decimal NoOfCustomerLabels;
        public String BusinessName;
        public String PartId;
        public String PartDesc;
        public Decimal RetailPrice;
        public String PartLocation;
        public CustomerInfo CustomerDetail;
        
        public String Location;
        public String PartDesc1;
        public String PartDesc2;
        public String PartNumber;
        
        public Decimal NoOfLabelsToPrint;
        public String OrderType;
        public String NeededFor;
        public String OrderTypeOfSpecialOrder;
        public Boolean IsIncludePricesOnPartLabels;
        
        public LabelPrinting(Vendor_Order_Line_Item__c voliRec, Business_Profile__c businessProfileRec) {
            this.IsSelected = true;
            this.NoOfStockLabels = 0;
            this.NoOfCustomerLabels = 0;
            this.OrderType = '';

            if(voliRec.Is_required_For_Customer__c || voliRec.Is_Service__c) {
                if(voliRec.Part__r.Packaged_Part__c && !voliRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                    this.NoOfCustomerLabels = 1;
                } else {
                    this.NoOfCustomerLabels = ((voliRec.Received__c != null) ? voliRec.Received__c : 0);
                }
                this.NoOfLabelsToPrint = this.NoOfCustomerLabels;
                this.CustomerDetail = new CustomerInfo(voliRec);
                this.NeededFor = ((voliRec.Special_Order_Belongs_To__c == 'Deal Merchandise' || voliRec.Special_Order_Belongs_To__c == 'Merchandise') ? 'Merch' : 'Service') + (this.CustomerDetail.CustomerName != null ? ' - ' + CustomerDetail.CustomerName : '');
                if((voliRec.Service_Order_Line_Item__c != null && voliRec.Service_Order_Line_Item__r.Deal__c != null) || (voliRec.CO_Line_Item__c != null && voliRec.CO_Line_Item__r.Deal__c != null)) {
                    this.OrderTypeOfSpecialOrder = 'Deal';
                } else if (voliRec.CO_Line_Item__c != null && voliRec.CO_Line_Item__r.Deal__c == null && voliRec.Related_SOLI__c == null) {
                    this.OrderTypeOfSpecialOrder = 'Part sale';
                } else {
                    this.OrderTypeOfSpecialOrder = 'Service job';
                }   
            } else {
                if(voliRec.Part__r.Packaged_Part__c && !voliRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                    this.NoOfStockLabels = ((voliRec.Vendor_Receiving_Group__r.Recieved__c != null) ? (voliRec.Vendor_Receiving_Group__r.Recieved__c / ((voliRec.Part__r.Package_Qty__c != null && voliRec.Part__r.Package_Qty__c != 0) ? voliRec.Part__r.Package_Qty__c : 1))  : 0);
                } else {
                    this.NoOfStockLabels = ((voliRec.Received__c != null) ? voliRec.Received__c : 0);
                }
                this.NoOfLabelsToPrint = this.NoOfStockLabels;
                this.NeededFor = 'Stock';
                this.IsIncludePricesOnPartLabels = Configurations__c.getOrgDefaults().Include_Prices_On_Part_Labels__c;
            }
            
            if(voliRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                this.OrderType = 'Ordered as individual items';
            } else if(voliRec.Part__r.Packaged_Part__c) {
                this.OrderType = 'Ordered as ' + voliRec.Part__r.Package_Qty__c + '/' + (String.isBlank(voliRec.Part__r.Package_Unit__c) ? 'PKG' : voliRec.Part__r.Package_Unit__c);
                if(voliRec.Part__r.Order_Lots__c > 1) {
                    this.OrderType += ' in Lots of ' + voliRec.Part__r.Order_Lots__c;
                }
            } else if(voliRec.Part__r.Order_Lots__c > 1) {
                this.OrderType += 'Ordered as in Lots of ' + voliRec.Part__r.Order_Lots__c;
                }

            this.BusinessName = (businessProfileRec.Business_Name__c != null) ? businessProfileRec.Business_Name__c : '';
            this.BusinessName = (this.BusinessName.length() > 40) ? this.BusinessName.subString(0, 40) : this.BusinessName;
            setPartRelatedFields(voliRec.Part__r);
            }

        public LabelPrinting(Vendor_Receiving_Stock_Excess__c vrStockExcessRec, Business_Profile__c businessProfileRec) {
            Part__c partRec = vrStockExcessRec.Vendor_Receiving_Group__r.Part__r;
            this.IsSelected = true;
            this.NoOfStockLabels = 0;
            this.OrderType = '';

            if(partRec.Packaged_Part__c && !vrStockExcessRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                this.NoOfStockLabels = ((vrStockExcessRec.Vendor_Receiving_Group__r.Recieved__c != null) ? (vrStockExcessRec.Vendor_Receiving_Group__r.Recieved__c / ((partRec.Package_Qty__c != null && partRec.Package_Qty__c != 0) ? partRec.Package_Qty__c : 1))  : 0);
            } else {
                this.NoOfStockLabels = ((vrStockExcessRec.Received_Qty__c != null) ? vrStockExcessRec.Received_Qty__c  : 0);
            }

            if(vrStockExcessRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                this.OrderType = 'Ordered as individual items';
            } else if(partRec.Packaged_Part__c) {
                this.OrderType = 'Ordered as ' + partRec.Package_Qty__c + '/' + (String.isBlank(partRec.Package_Unit__c) ? 'PKG' : partRec.Package_Unit__c);
                if(partRec.Order_Lots__c > 1) {
                    this.OrderType += ' in Lots of ' + partRec.Order_Lots__c;
                }
            } else if(partRec.Order_Lots__c > 1) {
                this.OrderType += 'Ordered as in Lots of ' + partRec.Order_Lots__c;
            }

            this.NoOfLabelsToPrint = this.NoOfStockLabels;
            this.NeededFor = 'Stock';
            this.IsIncludePricesOnPartLabels = Configurations__c.getOrgDefaults().Include_Prices_On_Part_Labels__c;

            this.BusinessName = (businessProfileRec.Business_Name__c != null) ? businessProfileRec.Business_Name__c : '';
            this.BusinessName = (this.BusinessName.length() > 40) ? this.BusinessName.subString(0, 40) : this.BusinessName;
            setPartRelatedFields(partRec);
        }
            
        public void setPartRelatedFields(Part__c partRec) {
            this.Id = partRec.Id;
            this.ProductDesc = partRec.Part_Number__c + ' - ' + partRec.Description__c;
            this.PartId = partRec.Part_ID__c;
            this.PartDesc = partRec.Description__c;
            this.PartLocation = (partRec.Location__c != null) ? partRec.Location__c : '';
            this.RetailPrice = partRec.Retail_Price__c;
            this.PartNumber = partRec.Part_Number__c;
            this.PartDesc2 = '';
            
            this.Location = String.join(LocationManagementService.getLocationsList(partRec), ',');
            if(partRec.Description__c != null && GeneralConfiguration.getBarCodeLabelSize() == 'large') {
                if(partRec.Description__c.length() <= 40) {
                    this.PartDesc1 = partRec.Description__c;
                } else {
                    this.PartDesc1 = partRec.Description__c.subString(0, 40);
                    this.PartDesc2 = partRec.Description__c.subString(40, partRec.Description__c.length());
                    if(this.PartDesc2.length() > 40) {
                        this.PartDesc2 = this.PartDesc2.abbreviate(40);
                    }
                }
            } else if(partRec.Description__c != null && GeneralConfiguration.getBarCodeLabelSize() == 'small') {
                this.PartDesc2 = (partRec.Description__c.length() <= 40) ? partRec.Description__c : 
                                        partRec.Description__c.abbreviate(40);
                
                this.PartDesc1 = (partRec.Description__c.length() <= 30) ? partRec.Description__c : 
                                        partRec.Description__c.abbreviate(30);
            } 
        }
    }
    
    public class CustomerInfo {
        
        public String CONumber;
        public String CustomerName;
        public String PhoneNumber;
        public Decimal NoOfLabels;
        
        public CustomerInfo(Vendor_Order_Line_Item__c voliRec) {
            this.CONumber = voliRec.CO_Header__r.Name;
            if(voliRec.CO_Header__r.Customer__c != null) {
                this.CustomerName = voliRec.CO_Header__r.Customer__r.Type__c == 'Business'? voliRec.CO_Header__r.Customer_Name__c : voliRec.CO_Header__r.Customer__r.LastName__c;
            } else {
                this.CustomerName = voliRec.CO_Header__r.Customer_Name__c;
            }
            if(voliRec.CO_Header__r.Customer__r.Home_Number__c != null) {
                this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Formatted_Home_number__c;
                //this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Home_Number__c;
            } else if(voliRec.CO_Header__r.Customer__r.Mobile__c != null) {
                this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
                //this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Mobile__c;
            } else if(voliRec.CO_Header__r.Customer__r.Work_Number__c != null) {
                this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                //this.PhoneNumber = voliRec.CO_Header__r.Customer__r.Work_Number__c;
            }
            if(voliRec.Part__r.Packaged_Part__c && !voliRec.Vendor_Receiving_Group__r.Is_Order_As_Individual_Item__c) {
                this.NoOfLabels = 1;
            } else {
                this.NoOfLabels = ((voliRec.Received__c != null) ? voliRec.Received__c : 0);
            }
        }
    }
    
     /**
     * Name: VendorOrderReceiving
     * Description: Vendor Order Receiving Wrapper Class
     **/
    // Wrapper class for Vendor Order Receiving attributes
    public class VendorOrderReceiving {
        public VORHeader VOR_Header;
        public boolean isAllVOSelected;
        public Integer totalVendorOrders;
        public List<VendorOrderHeader> vendorOrdersList;
        public Set<String> SelectedVendorOrdersList;
        public Integer totalOutstandingItems;
        public List<VROutstandingLineItemWrapper> outstandingVOGList;
        public Integer totalGroupItems;
        public List<VORGroup> VORGroupList;
        public Decimal GroupTotalCost;
        public List<VIHistory> VIHistoryList;
        private transient Set<Id> vendorAllPartIdsSet;
        public Boolean isFoundPartInOtherVOHeader = false;
        public List<VORGroup> RecentlyEditedVORGroupList;
        public Decimal TotalReceivedQty;
	    public Decimal TotalReceivedLineItem;
        
        public VendorOrderReceiving(Id vorId, String gridName, String searchStr, PaginationSorting pageSortAttrs) {
        	if(String.isNotBlank(gridName)) {
            	setVRWrapper(vorId, gridName, searchStr, null, pageSortAttrs, pageSortAttrs, pageSortAttrs);  
            }
        }
        
        public VendorOrderReceiving(Id vorId, String gridName, Id lastEditedPartId,
                                    PaginationSorting vendorOrdersPageSortAttrs, 
                                    PaginationSorting groupItemsPageSortAttrs,
                                    PaginationSorting outstandingVOGPageSortAttrs
                                ){
            setVRWrapper(vorId, gridName, null, lastEditedPartId, vendorOrdersPageSortAttrs, groupItemsPageSortAttrs, outstandingVOGPageSortAttrs);                    	
        }
        
        private void setVRWrapper(Id vorId, String gridName, String searchStr, Id lastEditedPartId, PaginationSorting vendorOrdersPageSortAttrs, 
        					PaginationSorting groupItemsPageSortAttrs, PaginationSorting outstandingVOGPageSortAttrs) {
            vendorAllPartIdsSet = new Set<Id>();
            if(String.isNotBlank(vorId)) {
	            // populate vendor orders
	            if(String.isBlank(gridName) || gridName.equalsIgnoreCase('vendororder')) {
		            totalVendorOrders = 0;
		            isAllVOSelected = true;
		            vendorOrdersList = new List<VendorOrderHeader>();
		            SelectedVendorOrdersList = new Set<String>();
	            	VOR_Header = VORHeader.getVORDetails(vorId);
		            populateVendorOrderDetails(vorId, vendorOrdersPageSortAttrs);
	            }
		            
	            // populate outstanding vendor order groups list
	            if(String.isBlank(gridName) || gridName.equalsIgnoreCase('outstanding')) {
	                outstandingVOGList = new List<VROutstandingLineItemWrapper>();
	                populateOutstandingItems(vorId, searchStr, outstandingVOGPageSortAttrs);
	            }
	            
	            // populate outstanding vendor order groups list
	            if(String.isBlank(gridName) || gridName.equalsIgnoreCase('groupitems')) {
	                VORGroupList = new List<VORGroup>();
	                RecentlyEditedVORGroupList = new List<VORGroup>();
	            	GroupTotalCost = 0;
                    TotalReceivedQty = 0;
                    TotalReceivedLineItem = 0;
  	
	            	populateItemsSubsection(vorId, searchStr, groupItemsPageSortAttrs);
	        
	                for(VORGroup vrgObj : VORGroupList) {
	                    if(vrgObj.PartId == lastEditedPartId) {
	                        RecentlyEditedVORGroupList.add(vrgObj);
	    				}
	                    if(vrgObj.Total != null) {
		            		this.GroupTotalCost += vrgObj.Total.setScale(2, RoundingMode.HALF_UP);
	        			}
	        		}
	            	// Sort and paginate list
		            VORGroupList.sort();
	            	VORGroupList = VORGroup.getPaginatedRecords(VORGroupList, groupItemsPageSortAttrs.CurrentPage, groupItemsPageSortAttrs.PageSize);
	            }
	            if(String.isBlank(gridName) || gridName.equalsIgnoreCase('vihistory')) {
	            	VIHistoryList = new List<VIHistory>();
	            	populateVIHistoryList(vorId);
	        	}
            }
        }
        /**
         * Name: populateVendorOrderDetails
         * Desc: Method to populate only vendor Orders for vendor receiving
         * @param:  (1) vorId - String - Vendor Order Receiving Id
         *          (2) vendorOrdersPageSortAttrsJSON - PaginationSorting -Vendor Order Headers Grid Paging and sorting JSON
         * @return: 
        **/
        private void populateVendorOrderDetails(Id vorId, PaginationSorting vendorOrdersPageSortAttrs){
            // If there is a vendor assigned to VRO record, then populate the lists
            if(VOR_Header.VendorId != null){
                Map<String, String> sortFieldMap = new Map<String, String>();
                if(vendorOrdersPageSortAttrs.sorting != null && vendorOrdersPageSortAttrs.sorting[0].sortDirection.length() != 0){
                    sortFieldMap.put('Name', vendorOrdersPageSortAttrs.sorting[0].sortDirection);
                    VO_Sort_Order = vendorOrdersPageSortAttrs.sorting[0].sortDirection;
                }
                
                List<Vendor_Order_Header__c> voList = SOQLUtil.getVendorOrderHeaderRecords('Vendor__c', VOR_Header.VendorId, sortFieldMap, true);
                totalVendorOrders = voList.size();
                
                Integer rowCount = 0;
                
                for(Vendor_Order_Header__c vo : voList){
                    VendorOrderHeader voh = new VendorOrderHeader(vo);
                    vendorOrdersList.add(voh);
                    if(vo.In_Progress_VRs__r == null || vo.In_Progress_VRs__r.size() == 0){
                        isAllVOSelected = false;
                    } else {
                    	if(voh.InProgressVR != null && voh.InProgressVRId == vorId){
		                    SelectedVendorOrdersList.add(voh.VOName);
		                }
                    	for(In_Progress_VR__c inProgressVRRec : vo.In_Progress_VRs__r) {
	                        if(inProgressVRRec.Vendor_Receiving_Header__c != vorId) {
	                            isAllVOSelected = false;
	                            rowCount++;
	                            break;
	                        }
	                    }
                    }
                }
                if(isAllVOSelected == false && rowCount == voList.size()){
                    isAllVOSelected = null;
                }

                // get paginated records
                vendorOrdersList.sort();    // Sorting implication to move all those vendor orders in last which are already part of any other vendor receiving records
                vendorOrdersList = VendorOrderHeader.getPaginatedRecords(vendorOrdersList, vendorOrdersPageSortAttrs.CurrentPage, vendorOrdersPageSortAttrs.PageSize);
            }
            
        }
        
        private void populateOutstandingItems(String vorId, String searchStr, PaginationSorting outstandingVOGPageSortAttrs) {
	        if(String.isNotBlank(vorId)) {
	            
	            List<Vendor_Order_Line_Item_Group__c> voLineItemGroupList = VendorOrderReceivingSOQLUtil.getVROutstandingItemsByFilters(vorId, searchStr);
	            
	            Set<Id> orderAsIndPartIdSet = new Set<Id>();
	            Set<Id> partIdSet = new Set<Id>();
	            Set<Id> sublet = new Set<Id>();
	            
	            Set<Id> VOHeaderIdSet = new Set<Id>();
	            for(Vendor_Order_Line_Item_Group__c voliGroup : voLineItemGroupList) {
                    if(voliGroup.Vendor_Order_Line_Items__r.size() > 0) {
                        if(voliGroup.Part__c != null) {
                            Boolean partAlreadyAdded = true;
                            if(voliGroup.Is_Order_As_Individual_Item__c) {
                                if(!orderAsIndPartIdSet.contains(voliGroup.Part__c)) {
                                    partAlreadyAdded = false;
                                    orderAsIndPartIdSet.add(voliGroup.Part__c);
                                }
                            } else {
                                if(!partIdSet.contains(voliGroup.Part__c)) {
                                    partAlreadyAdded = false;
                                    partIdSet.add(voliGroup.Part__c);
                                }
                            }
                            if(!partAlreadyAdded) {
                                outstandingVOGList.add(new VROutstandingLineItemWrapper(voliGroup));
                            }
                        } else if(voliGroup.Sublet__c != null) {
                            outstandingVOGList.add(new VROutstandingLineItemWrapper(voliGroup));
                        }
                    }
	            }
	            
	            totalOutstandingItems = outstandingVOGList.size();
	            // Sort and paginate list
	            Map<String, String> sortFieldMap = new Map<String, String>{'Items' => ''};
	            if(outstandingVOGPageSortAttrs.Sorting != null && outstandingVOGPageSortAttrs.Sorting[0].SortDirection.length() != 0) {
	                sortFieldMap.put('Items', outstandingVOGPageSortAttrs.Sorting[0].SortDirection.toUpperCase());
	            }
	            VendorOrderLineItemWrapper.sortFieldMap = sortFieldMap;
	            outstandingVOGList.sort();
	            outstandingVOGList = VROutstandingLineItemWrapper.getPaginatedRecords(outstandingVOGList, outstandingVOGPageSortAttrs.CurrentPage, outstandingVOGPageSortAttrs.PageSize);
	        }
	    }
        
        private void populateItemsSubsection(String vorId, String searchStr, PaginationSorting groupItemsPageSortAttrs) {
            List<Vendor_Receiving_Group__c> vrGroupList = VendorOrderReceivingSOQLUtil.getVRItemsByFilters(vorId, searchStr);
            String vendorId;
            Set<Id> partIdSet = new Set<Id>();
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
            	if(vrgRec.Part__c != null) {
                	partIdSet.add(vrgRec.Part__c);
            	}
            	vendorId = vrgRec.Vendor_Receiving_Header__r.Vendor__c;
            }

            if(vrGroupList != null && vrGroupList.size() > 0){
                TotalReceivedLineItem = vrGroupList[0].Vendor_Receiving_Header__r.Total_Line_Item__c;
                TotalReceivedQty = vrGroupList[0].Vendor_Receiving_Header__r.Total_Received_Qty__c;
            }
            
            Map<Id, List<String>> partIdToOtherVOHeaderNameListMap = getPartIdToUnreceivedVOHNamesMap(vorId, partIdSet, vendorId);
            
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
                VORGroupList.add(new VORGroup(vrgRec, partIdToOtherVOHeaderNameListMap));
            } 
            
            VendorOrderReceivingCtrl.sortingMap = new Map<String, String>();
            if(groupItemsPageSortAttrs.sorting != null && groupItemsPageSortAttrs.sorting[0].sortDirection.length() != 0){
                VendorOrderReceivingCtrl.sortingMap.put(groupItemsPageSortAttrs.sorting[0].FieldName, groupItemsPageSortAttrs.sorting[0].sortDirection);
                VO_Sort_Order = groupItemsPageSortAttrs.sorting[0].sortDirection;
            }
            
            totalGroupItems = VORGroupList.size();
        }
        
        private Map<Id, List<String>> getPartIdToUnreceivedVOHNamesMap(String vorId, Set<Id> partIdSet, Id vendorId){
        	Map<Id, List<String>> partIdToVOHeaderNameListMap = new Map<Id, List<String>>();
            if(String.isBlank(vendorId) || partIdSet == null || partIdSet.size() == 0) {
        		return partIdToVOHeaderNameListMap;
        	}
            List<Id> vohIdsToExclude = new List<Id>();
            vendorId = BPUtility.escapeSingleQuotes(vendorId);
            if(AccessControl.ifObjectIsAccessible('In_Progress_VR__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            if(AccessControl.ifObjectIsAccessible('Vendor_Order_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            for(In_Progress_VR__c ivr : [SELECT Vendor_Order_Header__c 
                                                FROM In_Progress_VR__c 
                                                WHERE Vendor_Order_Header__r.Vendor__c =: vendorId]){
                vohIdsToExclude.add(ivr.Vendor_Order_Header__c);
            }

            if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            List<Vendor_Order_Line_Item_Group__c> voLineItemGroupList = 
                [SELECT Part__c, Vendor_Order_Header__r.Name
                    FROM Vendor_Order_Line_Item_Group__c WHERE Part__c IN: partIdSet 
                    AND Vendor_Order_Header__c NOT IN: vohIdsToExclude AND Vendor_Order_Header__r.Vendor__c =: vendorId AND Unreceived_Qty__c > 0
                    AND Vendor_Order_Header__r.Status__c IN ('On Order', 'Partially Received')];

            List<String> voHeaderNameList;
            for(Vendor_Order_Line_Item_Group__c voliGroupRec : voLineItemGroupList) {
                if(partIdToVOHeaderNameListMap.containsKey(voliGroupRec.Part__c)) {
                    voHeaderNameList = partIdToVOHeaderNameListMap.get(voliGroupRec.Part__c);
                    voHeaderNameList.add(voliGroupRec.Vendor_Order_Header__r.Name);
                } else {
                    voHeaderNameList = new List<String>();
                    voHeaderNameList.add(voliGroupRec.Vendor_Order_Header__r.Name);
                }
                partIdToVOHeaderNameListMap.put(voliGroupRec.Part__c, voHeaderNameList);
            }
            return partIdToVOHeaderNameListMap;
        }
        
        /**
         * Name: populateVIHistoryList
         * Desc: Method used to populate a map of vendor related parts Ids used in all Vendor Orders to all unreceived VO names
         * @param:  (1) vorId - Selected vendor Receiving Id
         * @return: Map<Id, List<String>>
        **/
        private void populateVIHistoryList(String vorId){
            vorId = BPUtility.escapeSingleQuotes(vorId);
            if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            List<Vendor_Receiving_Header__c> vrHeaderList = [select In_Progress_VI__c from Vendor_Receiving_Header__c where Id =: vorId];
            if(vrHeaderList.size() > 0 && vrHeaderList[0].In_Progress_VI__c != null) {
                List<Vendor_Invoicing_Header__c> viHeaderList = SOQLUtil.getVIHeaderDetailsByFieldName(new Map<String, String>{'Id' => vrHeaderList[0].In_Progress_VI__c});
                for(Vendor_Invoicing_Header__c viHeaderRec : viHeaderList) {
                    this.VIHistoryList.add(new VIHistory(viHeaderRec));
                }
            }
        }
    }
    
     /**
     * Name: VRGroupDetail
     * Description: Wrapper class for Needed For Pop Up
     **/
    public class VRGroupDetail {
        
        public Decimal RequriedForCustomer;
        public Decimal RequriedForStock;
        public Decimal TotalRequried;
        public Decimal OrderQty;
        public Decimal PackageQty;
        public String PackageUnit;
        public Decimal TotalExcess;
        
         /**
         * Name: VRGroupDetail
         * Desc: Constructor
         * @param:  (1) vrgRec - Vendor Receiving Group Record
         * @return:
         **/
        public VRGroupDetail(Vendor_Receiving_Group__c vrgRec) {
            this.RequriedForCustomer = 0;
            this.RequriedForStock = 0;
            this.PackageQty = 0;
            this.TotalExcess = 0;
            
            for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
                if(voliRec.Is_required_For_Customer__c) {
                    this.RequriedForCustomer += voliRec.Qty_Needed__c;
                } else if(!voliRec.Is_required_For_Customer__c && !voliRec.Is_Excess__c && !voliRec.Is_From_Search__c) {
                    this.RequriedForStock += voliRec.Qty_Needed__c;
                } else if(voliRec.Is_Excess__c) {
                    this.TotalExcess += voliRec.Qty_Needed__c;
                }
            }
            this.TotalRequried = this.RequriedForCustomer + this.RequriedForStock;
            if(vrgRec.Part__r.Packaged_Part__c) {
                if(vrgRec.Part__r.Package_Qty__c != 0) {
                    this.PackageQty = (this.TotalRequried + this.TotalExcess) / vrgRec.Part__r.Package_Qty__c;
                }
                this.PackageUnit = (String.isBlank(vrgRec.Part__r.Package_Unit__c) ? 'PKG' : vrgRec.Part__r.Package_Unit__c);
            }
            this.OrderQty = vrgRec.Part__r.Order_Lots__c;
        }
    }
    
     /**
     * Name: VIHistory
     * Description: Wrapper class for Vendor Invoice History Section
     **/
    public class VIHistory {
        
        public String InvoiceNumber;
        public String InvoiceDate;
        public String InvoicedByName;
        public String InvoicedById;
        public String VIHeaderId;
        public Decimal TotalLineItems;
        public Decimal TotalCost;
        public String Status;
        
         /**
         * Name: VIHistory
         * Desc: Constructor
         * @param:  (1) viHeaderRec -Vendor Invoice Header Record 
         * @return:
         **/
        public VIHistory(Vendor_Invoicing_Header__c viHeaderRec) {
            
            this.InvoiceNumber = ((viHeaderRec.Invoice_Number__c != null) && (viHeaderRec.Invoice_Number__c != '')) ? viHeaderRec.Invoice_Number__c : viHeaderRec.Name;
            if(viHeaderRec.Invoice_Date__c != null) {
                this.InvoiceDate = BPUtility.getFormatedDateTime(datetime.newInstance(viHeaderRec.Invoice_Date__c.year(), viHeaderRec.Invoice_Date__c.month(), viHeaderRec.Invoice_Date__c.day()));
            }
            this.InvoicedByName = viHeaderRec.Owner__r.Name;
            this.InvoicedById = viHeaderRec.Owner__c;
            this.VIHeaderId = viHeaderRec.Id;
            
            this.TotalLineItems = 0;
            this.TotalCost = 0;
            for(Vendor_Invoicing_Group__c viGroupRec : viHeaderRec.Vendor_Invoicing_Groups__r ) {
                this.TotalLineItems += 1;
                this.TotalCost += viGroupRec.VI_SubTotal__c;
            }
            this.TotalCost = this.TotalCost.setScale(2, RoundingMode.HALF_UP);
            this.Status = viHeaderRec.Status__c;
        }
    }
}
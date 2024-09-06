public without sharing class VendorOrderReceivingService {
    
    public static final String REALLOCATE_OVERSOLD_PARTS = 'Reallocate oversold parts';
    public static void updateVOSelection(String vohId, String vrhId, Boolean isSelected) {
        if(isSelected) {
            List<In_Progress_VR__c> inProgressVRList = [SELECT Vendor_Order_Header__r.Name, Vendor_Receiving_Header__r.Name FROM In_Progress_VR__c 
                                                            WHERE Vendor_Receiving_Header__c !=: vrhId AND Vendor_Order_Header__c =: vohId AND Vendor_Receiving_Header__r.Status__c = 'In Progress'];
            if(inProgressVRList.size() > 0) {
                throw new BlackPurlException('Vendor order ' + inProgressVRList[0].Vendor_Order_Header__r.Name + ' receiving in progress ' +  inProgressVRList[0].Vendor_Receiving_Header__r.Name);
            }
            DMLUtility.insertSobjectList('In_Progress_VR__c', createInProgressVR(vrhId, vohId));
        } else {
            List<In_Progress_VR__c> inProgressVRList = [SELECT Vendor_Order_Header__c FROM In_Progress_VR__c 
                                                            WHERE Vendor_Receiving_Header__c =: vrhId AND Vendor_Order_Header__c =: vohId];
            
            // Remove any pending VR groups related to deselected VO
            unReceiveGroupsForDeselectedVendorOrders(vrhId, false, inProgressVRList);
            
            // Delete In Progress VR
            if(inProgressVRList.size() > 0) {
                if(!AccessControl.ifObjectIsDeletable('In_Progress_VR__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                delete inProgressVRList;
            }
        }
    }
    
    // This method removes Vendor order line items Groups with Unreceiving the Vendor Order Line Items
    // This method should be called when deselecting VO(s) from VO listing
    public static void unReceiveGroupsForDeselectedVendorOrders(String vrhId, Boolean isDeselectAll, List<In_Progress_VR__c> inProgressVRList) {
        // Get related Vendor Order Ids
        Set<Id> voHeaderIdSet = new Set<Id>();
        for(In_Progress_VR__c inProgressVR : inProgressVRList) {
            voHeaderIdSet.add(inProgressVR.Vendor_Order_Header__c);
        }
        
        // Unreceive Vendor Order Line Items
        Set<Id> vrGroupIdSet = new Set<Id>();
        List<Vendor_Order_Line_Item__c> voLineItemList = 
            [SELECT Received__c, Vendor_Receiving_Group__c FROM Vendor_Order_Line_Item__c WHERE Vendor_Order_Header__c IN: voHeaderIdSet 
                  AND Vendor_Receiving_Group__c != null AND Vendor_Receiving_Group__r.Vendor_Receiving_Header__c =: vrhId];
        for(Vendor_Order_Line_Item__c voliRec : voLineItemList) {
            vrGroupIdSet.add(voliRec.Vendor_Receiving_Group__c);
            voliRec.Vendor_Receiving_Group__c = null;
            voliRec.Received__c = 0;
        }
        updateVOLineItemListWithTriggerHandling(voLineItemList, true);
        
        // Update related VR group if those are related to other VO groups
        // Delete related VR group records if groups items are only related to this group.
        List<Vendor_Receiving_Group__c> vrGroupList = [SELECT Recieved__c, (SELECT Received__c FROM Vendor_Order_Line_Items__r) 
                                                        FROM Vendor_Receiving_Group__c WHERE Id IN: vrGroupIdSet];
        if(vrGroupList.size() > 0) {
            List<Vendor_Receiving_Group__c> vrGroupListToDelete = new List<Vendor_Receiving_Group__c>();
            List<Vendor_Receiving_Group__c> vrGroupListToUpdate = new List<Vendor_Receiving_Group__c>();
            
            if(isDeselectAll) {
                vrGroupListToDelete.addAll(vrGroupList);
            } else {
                for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
	                Decimal received = 0;
	                if(vrgRec.Vendor_Order_Line_Items__r.size() > 0) {
	                    for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
	                        received += voliRec.Received__c;
	                    }
	                    vrgRec.Recieved__c = received;
	                    vrGroupListToUpdate.add(vrgRec);
	                } else {
	                    vrGroupListToDelete.add(vrgRec);
	                }
	            }
            }
            if(vrGroupListToUpdate.size() > 0) {
                VendorReceivingGroupTriggerHelper.isProcessed = true;
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupListToUpdate);
                VendorReceivingGroupTriggerHelper.isProcessed = false;
            }
            if(vrGroupListToDelete.size() > 0) {
                if(!AccessControl.ifObjectIsDeletable('Vendor_Receiving_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                VendorReceivingGroupTriggerHelper.isProcessed = true;
                delete vrGroupListToDelete;
                VendorReceivingGroupTriggerHelper.isProcessed = false;
            }
        }
    }
    
    public static void updateVOLineItemListWithTriggerHandling(List<Vendor_Order_Line_Item__c> voLineItemList, Boolean shouldStopTrigger) {
        if(voLineItemList.size() > 0) {
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = shouldStopTrigger;
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItemList);
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        }
    }
    
    public static Set<String> getVendorOrderReceivingPartIds(Set<String> vrHeaderIdSet) {
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Set<String> partIdSet = new Set<String>();
        for(Vendor_Receiving_Group__c vrGroup : [SELECT Part__c FROM Vendor_Receiving_Group__c 
                                                    WHERE Vendor_Receiving_Header__c IN: vrHeaderIdSet AND Part__c != null]) {
            partIdSet.add(vrGroup.Part__c);
        }
        return partIdSet;
    }
    
    public static void updateItemsSection(String vrGroupId, Decimal qty, Decimal cost, Decimal discount) {
        
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Receiving_Group__c> vrGroupList = 
               [SELECT Part__c, Is_Packaged_Part__c, Package_Qty__c, Sublet__c, Is_Order_As_Individual_Item__c,
                        (SELECT Vendor_Order_Line_Item_Group__c FROM Vendor_Order_Line_Items__r WHERE Sublet__c != null)
                    FROM Vendor_Receiving_Group__c WHERE Id =: vrGroupId];
        
        if(vrGroupList.size() > 0) {
            qty = (qty != null ? qty : 0);
            cost = (cost != null ? cost : 0);
            Vendor_Receiving_Group__c vrGroupRec = vrGroupList[0];
            if(qty <= 0) {
                if(!AccessControl.ifObjectIsDeletable('Vendor_Receiving_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                delete vrGroupRec;
            } else {
                discount = (discount != null ? discount: 0);
                vrGroupRec.Discount__c = discount;
                vrGroupRec.Per_Unit_Cost__c = cost;
                if(vrGroupRec.Part__c != null && vrGroupRec.Is_Packaged_Part__c && !vrGroupRec.Is_Order_As_Individual_Item__c) {
                    vrGroupRec.Recieved__c = qty * vrGroupRec.Package_Qty__c ;
                    if(vrGroupRec.Package_Qty__c != 0) {
                        vrGroupRec.Cost__c = cost / vrGroupRec.Package_Qty__c;
                    }
                } else {
                    vrGroupRec.Recieved__c = qty;
                    vrGroupRec.Cost__c = cost;
                    if(vrGroupRec.Sublet__c != null && vrGroupRec.Vendor_Order_Line_Items__r.size() > 0) {
                        Vendor_Order_Line_Item__c voliToUpdate = vrGroupRec.Vendor_Order_Line_Items__r[0];
                        voliToUpdate.Received__c = qty;
                        voliToUpdate.Qty_Needed__c = qty;
                        voliToUpdate.Line_Item_Cost__c = cost;
                        DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voliToUpdate);
                        
                        Vendor_Order_Line_Item_Group__c volig = new Vendor_Order_Line_Item_Group__c(Id = voliToUpdate.Vendor_Order_Line_Item_Group__c);
                        volig.Received_Qty__c = volig.Need__c = qty;
                        volig.Cost__c = volig.VOG_Cost__c = cost;
                        volig.Total__c = qty * cost;
                        DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', volig);
                    }
                }
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupRec);
            }
        }
    }
    
    public static String createPartFromHondaIfNotExists(String hondaInvoice) {
        HondaVendorInvoiceService.InvoiceResponseWrapper hondaInvoiceObj = (HondaVendorInvoiceService.InvoiceResponseWrapper)
                    System.JSON.deserialize(hondaInvoice, HondaVendorInvoiceService.InvoiceResponseWrapper.class);
        
        String partInfoString;
        if(hondaInvoiceObj.HoosInvoiceItems != null && hondaInvoiceObj.HoosInvoiceItems.size() > 0) {
            List<String> partNumberListFromHonda = getPartNumberListFromHondaInvoice(hondaInvoiceObj);
            String hondaVendorId = HondaUtility.getHondaVendorSFId();
            Map<String, Id> partNumberToPartIdMap = getExistingPartNumberMap(hondaVendorId, partNumberListFromHonda);
            
            List<Part__c> partListToInsert = new List<Part__c>();
            for(HondaVendorInvoiceService.PartWrapper partObj : hondaInvoiceObj.HoosInvoiceItems) {
                String partNumber = partObj.PartNumber.replaceAll('-', '');
                if(!partNumberToPartIdMap.containsKey(partNumber)) {
                    Part__c partRec = new Part__c(Vendor__c = hondaVendorId);
                    partRec.Part_Number__c = partNumber;
                    partRec.Description__c = partObj.PartDescription;
                    partRec.MSRP__c = partObj.ListPrice;
                    partRec.Retail_Price__c = partObj.ListPrice;
                    partRec.Last_Cost__c = partObj.WholesalePrice;
                    partListToInsert.add(partRec);
                }
            }
            if(partListToInsert.size() > 0) {
                DMLUtility.insertSobjectList('Part__c', partListToInsert);
                for(Part__c partRec : partListToInsert) {
                    partNumberToPartIdMap.put(partRec.Part_Number__c, partRec.Id);
                }
            }
            PartInfoWrapper partInfoObj = getPartInfoObj(hondaVendorId, hondaInvoiceObj, partNumberToPartIdMap);
            partInfoString = system.JSON.serialize(partInfoObj);
        }
        return partInfoString;     
    }
    
    public static PartInfoWrapper getPartInfoObj(String hondaVendorId, HondaVendorInvoiceService.InvoiceResponseWrapper hondaInvoiceObj, 
                                                    Map<String, Id> partNumberToPartIdMap) {
        PartInfoWrapper partInfoObj = new PartInfoWrapper(hondaVendorId);
        for(HondaVendorInvoiceService.PartWrapper partObj : hondaInvoiceObj.HoosInvoiceItems) {
            String partNumber = partObj.PartNumber.replaceAll('-', '');
            if(partNumberToPartIdMap.containsKey(partNumber)) {
                partInfoObj.PartList.add(new Part(partNumber, partNumberToPartIdMap.get(partNumber)));
            }
        }
        return partInfoObj;
    }
    
    public static List<String> getPartNumberListFromHondaInvoice(HondaVendorInvoiceService.InvoiceResponseWrapper hondaInvoiceObj) {
        List<String> partNumberListFromHonda = new List<String>();
        for(HondaVendorInvoiceService.PartWrapper partObj : hondaInvoiceObj.HoosInvoiceItems) {
            if(partObj.PartNumber != null) {
                partNumberListFromHonda.add(partObj.PartNumber.replaceAll('-', ''));
            }
        }
        return partNumberListFromHonda;
    }
    
    public static Map<String, Id> getExistingPartNumberMap(String hondaVendorId, List<String> partNumberListFromHonda) {
        List<Part__c> partList = [SELECT Part_Number__c FROM Part__c WHERE Part_Number__c IN: partNumberListFromHonda AND Vendor__c =: hondaVendorId];
        
        Map<String, Id> partNumberToPartIdMap = new Map<String, Id>();
        for(Part__c partRec : partList) {
            partNumberToPartIdMap.put(partRec.Part_Number__c, partRec.Id);
        }
        return partNumberToPartIdMap;
    }
    
    public static void populatePackagingSlipNumber(String vrHeaderId, String hondaInvoice) {
        HondaVendorInvoiceService.InvoiceResponseWrapper hondaInvoiceObj = (HondaVendorInvoiceService.InvoiceResponseWrapper)
                    System.JSON.deserialize(hondaInvoice, HondaVendorInvoiceService.InvoiceResponseWrapper.class);
           
        if(String.isNotBlank(hondaInvoiceObj.InvoiceNumber)) {
            Vendor_Receiving_Header__c vrHeaderRec = new Vendor_Receiving_Header__c(Id = vrHeaderId);
            vrHeaderRec.Packing_Slip_Number__c = hondaInvoiceObj.InvoiceNumber;
            DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vrHeaderRec);
        }                    
    }
    
    public static String selectVOFromHondaResponse(String vrHeaderId, String hondaInvoice) {
        HondaVendorInvoiceService.InvoiceResponseWrapper hondaInvoiceObj = (HondaVendorInvoiceService.InvoiceResponseWrapper)
                    System.JSON.deserialize(hondaInvoice, HondaVendorInvoiceService.InvoiceResponseWrapper.class);
        String selectedVOId;
        if(String.isNotBlank(hondaInvoiceObj.CustomerReference)) {
            selectedVOId = selectExistingVO(vrHeaderId, hondaInvoiceObj.CustomerReference);
        }
        return selectedVOId;
    }
    
    public static String selectExistingVO(String vrHeaderId, String voHeaderNameToSelect) {
        if(!AccessControl.ifObjectIsAccessible('In_Progress_VR__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<In_Progress_VR__c> inProgressList = [SELECT Vendor_Receiving_Header__c, Vendor_Order_Header__c
                                                    FROM In_Progress_VR__c  
                                                    WHERE Vendor_Receiving_Header__r.Status__c = 'In Progress'];
        List<Vendor_Receiving_Header__c> vrHeaderList = SOQLUtil.getVORDetails('Id', vrHeaderId);
        List<In_Progress_VR__c> inProgressVRList = new List<In_Progress_VR__c>();
        
        String selectedVOId;
        if(vrHeaderList.size() > 0) {
            Set<Id> inProgressVOIds = new Set<Id>();
            for(In_Progress_VR__c ipvr : inProgressList){
                inProgressVOIds.add(ipvr.Vendor_Order_Header__c);
            }
            inProgressVOIds.remove(null);
                
            List<Vendor_Order_Header__c> voList = [SELECT Id FROM Vendor_Order_Header__c 
                                                    WHERE Name =: voHeaderNameToSelect AND Id NOT IN: inProgressVOIds
                                                    AND (Status__c = 'On Order' OR Status__c = 'Partially Received')];
            if(voList.size() > 0) {
                // Delete already selected In progress VR List
                deleteNewlyAddedInProgressVR(vrHeaderId);
                
	            for(Vendor_Order_Header__c vo : voList) {
	                In_Progress_VR__c inProgressVRRec = new In_Progress_VR__c();
                    inProgressVRRec.Vendor_Order_Header__c = vo.Id;
                    inProgressVRRec.Vendor_Receiving_Header__c = vrHeaderId;
                    inProgressVRList.add(inProgressVRRec);
                    selectedVOId = vo.Id;
	            }
	            if(inProgressVRList.size() > 0) {
                    DMLUtility.insertSobjectList('In_Progress_VR__c', inProgressVRList);
	            }
            }
        }
        return selectedVOId;
    }

    public static List<VendorOrderHeader> getVendorOrderList(String vendorId) {
        List<Vendor_Order_Header__c> voList = SOQLUtil.getVendorOrderHeaderRecords('Vendor__c', vendorId, null, true);
        List<VendorOrderHeader> vendorOrdersList = new List<VendorOrderHeader>();
        for(Vendor_Order_Header__c vo : voList){
            VendorOrderHeader voh = new VendorOrderHeader(vo);
            vendorOrdersList.add(voh);
        }
        return vendorOrdersList;
    }
    
    private static void deleteNewlyAddedInProgressVR(String vrHeaderId) {
        List<In_Progress_VR__c> inProgressList = [SELECT Id FROM In_Progress_VR__c WHERE Vendor_Receiving_Header__c =: vrHeaderId];
        if(inProgressList.size() > 0) {
            DMLUtility.deleteSobjectList('In_Progress_VR__c', inProgressList);
        }
    }
    
    private static Vendor_Receiving_Group__c insertVRGroup(String vorId, Boolean isOrderedAsIndividualItem, Part__c partRec, Decimal receivedQty, 
    																	Boolean isStockExcessGenerated) {
    	Vendor_Receiving_Group__c vrGroupRec = new Vendor_Receiving_Group__c();
    	vrGroupRec.Cost__c = (partRec != null) ? partRec.Calculated_Cost__c : 0;
        vrGroupRec.Per_Unit_Cost__c = partRec.Packaged_Part__c ? partRec.Calculated_Package_Cost__c : vrGroupRec.Cost__c;
        vrGroupRec.Part__c = partRec.Id;
        vrGroupRec.Is_Order_As_Individual_Item__c = isOrderedAsIndividualItem;
        vrGroupRec.Vendor_Receiving_Header__c = vorId;
        vrGroupRec.Is_Packaged_Part__c = partRec.Packaged_Part__c;
        vrGroupRec.Is_Order_Lot__c = partRec.Is_OrderLot__c;
        vrGroupRec.Package_Qty__c = partRec.Package_Qty__c;
        vrGroupRec.Package_Unit__c = partRec.Package_Unit__c;
        vrGroupRec.Order_Lots__c = partRec.Order_Lots__c;
        if(isStockExcessGenerated) {
            vrGroupRec.Recieved__c = (receivedQty != null) ? receivedQty : 0;
            vrGroupRec.Order__c = 0;
        }
        DMLUtility.insertSobjectList('Vendor_Receiving_Group__c', vrGroupRec);
        return vrGroupRec;
    }
    
    public static void addLineItemFromSTA(String vorId, String partId, Boolean isStockExcessGenerated, Decimal receivedQty) {
        partId = BPUtility.escapeSingleQuotes(partId);
        vorId = BPUtility.escapeSingleQuotes(vorId);
        if(AccessControl.ifObjectIsCreateable('Vendor_Receiving_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
        if(!AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Group__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Receiving_Group__c> vrGroupList = [SELECT Discount__c, Cost__c, Recieved__c, Is_Order_As_Individual_Item__c, Part__r.Last_Cost__c, Part__r.Calculated_Cost__c, Is_Packaged_Part__c, 
                    Package_Qty__c FROM Vendor_Receiving_Group__c WHERE Part__c = :partId AND Vendor_Receiving_Header__c = :vorId];
        
        if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> partList = [SELECT Vendor__c, Last_Cost__c, Calculated_Cost__c, Packaged_Part__c, Package_Qty__c, Calculated_Package_Cost__c, Package_Unit__c, Is_OrderLot__c, Order_Lots__c FROM Part__c WHERE Id =: partId];
        
        Vendor_Receiving_Group__c vrGroupNotOrderAsIndividualRec = new Vendor_Receiving_Group__c();
        Vendor_Receiving_Group__c vrGroupOrderAsIndividualRec = new Vendor_Receiving_Group__c();
        if(vrGroupList.size() > 0) {
    		if(vrGroupList[0].Is_Order_As_Individual_Item__c) {
    			vrGroupOrderAsIndividualRec = vrGroupList[0];
	        } else {
    			vrGroupNotOrderAsIndividualRec = vrGroupList[0];
	        }
        
        	if(vrGroupList.size() > 1) {
        		if(vrGroupList[1].Is_Order_As_Individual_Item__c) {
        			vrGroupOrderAsIndividualRec = vrGroupList[1];
        		} else {
        			vrGroupNotOrderAsIndividualRec = vrGroupList[1];
        		}
        	}
        }
        Boolean populateDiscount = false;
        if(!isStockExcessGenerated) {
            String query = 'SELECT Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c, ' + String.join(VendorOrderLineItem.fieldsList(), ', ') + ' FROM Vendor_Order_Line_Item__c ' + 
                'WHERE Vendor_Order_Line_Item_Group__c != null AND Vendor_Order_Line_Item_Group__r.Status__c != \'Cancelled\' AND Part__c =: partId ' +
                'AND Vendor_Order_Header__r.Status__c IN (\'On Order\', \'Partially Received\') AND Vendor_Receiving_Group__c = null';
            List<Vendor_Order_Line_Item__c> voLineItems = Database.query(query);
            //List<Vendor_Order_Line_Item__c> voLineItems = SOQLUtil.getVOLineItemsForGivenPartAndVendorReceiving(partId, vorId);
            
            if(voLineItems.size() == 0) {
            	if(vrGroupNotOrderAsIndividualRec.Id == null && vrGroupOrderAsIndividualRec.Id == null) {
            		vrGroupNotOrderAsIndividualRec = insertVRGroup(vorId, false, partList[0], receivedQty, isStockExcessGenerated);
                    for(PO_Type__c poRec : [Select Discount__c FROM PO_Type__c WHERE Vendor__c =: partList[0].Vendor__c AND IsDefault__c = true AND Discount__c != null LIMIT 1]) {
                        vrGroupNotOrderAsIndividualRec.Discount__c = poRec.Discount__c;
                    }
                    vrGroupNotOrderAsIndividualRec.Recieved__c = (vrGroupNotOrderAsIndividualRec.Recieved__c == null || vrGroupNotOrderAsIndividualRec.Recieved__c == 0) ?  
                                            (vrGroupNotOrderAsIndividualRec.Is_Packaged_Part__c ? vrGroupNotOrderAsIndividualRec.Package_Qty__c : 1) : 0;
                    DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupNotOrderAsIndividualRec);               
            	}
        	} else {
	            List<Vendor_Order_Line_Item__c> orderAsIndividualVOLIList = new List<Vendor_Order_Line_Item__c>();
	            List<Vendor_Order_Line_Item__c> orderNotAsIndividualVOLIList = new List<Vendor_Order_Line_Item__c>();
	
            	for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
	            	if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
	            		orderAsIndividualVOLIList.add(voliRec);
	            	} else {
	            		orderNotAsIndividualVOLIList.add(voliRec);
            		}
	            }
	            
            	if(vrGroupOrderAsIndividualRec.Id == null && orderAsIndividualVOLIList.size() > 0) {
            		vrGroupOrderAsIndividualRec = insertVRGroup(vorId, true, partList[0], receivedQty, isStockExcessGenerated);
                    populateDiscount = true;
            	}
            	if(vrGroupNotOrderAsIndividualRec.Id == null && orderNotAsIndividualVOLIList.size() > 0) {
            		vrGroupNotOrderAsIndividualRec = insertVRGroup(vorId, false, partList[0], receivedQty, isStockExcessGenerated);
                    populateDiscount = true;
            	}
            	
            	Decimal orderAsIndividualQty = 0;
	            Decimal orderNotAsIndividualQty = 0;
    			for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
	            	if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
            			voliRec.Vendor_Receiving_Group__c = vrGroupOrderAsIndividualRec.Id;
                        if(populateDiscount && vrGroupOrderAsIndividualRec.Discount__c == null) vrGroupOrderAsIndividualRec.Discount__c = voliRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c;
            			orderAsIndividualQty += voliRec.Qty_Needed__c;
            		} else {
	            		voliRec.Vendor_Receiving_Group__c = vrGroupNotOrderAsIndividualRec.Id;
	            		if(populateDiscount && vrGroupNotOrderAsIndividualRec.Discount__c == null) vrGroupNotOrderAsIndividualRec.Discount__c = voliRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c;
            			orderNotAsIndividualVOLIList.add(voliRec);
            			orderNotAsIndividualQty += voliRec.Qty_Needed__c;
	            	}
	            }
	            
                if(voLineItems.size() > 0) {
                    DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItems);
                }
                
                if(orderAsIndividualVOLIList.size() > 0) {
                	vrGroupOrderAsIndividualRec.Recieved__c = (vrGroupOrderAsIndividualRec.Recieved__c == null) ? 0 : vrGroupOrderAsIndividualRec.Recieved__c;
	                vrGroupOrderAsIndividualRec.Recieved__c = vrGroupOrderAsIndividualRec.Recieved__c + orderAsIndividualQty;
	                vrGroupOrderAsIndividualRec.Cost__c = orderAsIndividualVOLIList[0].Line_Item_Cost__c;
                    vrGroupOrderAsIndividualRec.Per_Unit_Cost__c = vrGroupOrderAsIndividualRec.Cost__c;
            	}

                if(orderNotAsIndividualVOLIList.size() > 0) {
                	vrGroupNotOrderAsIndividualRec.Recieved__c = (vrGroupNotOrderAsIndividualRec.Recieved__c == null) ? 0 : vrGroupNotOrderAsIndividualRec.Recieved__c;
	                vrGroupNotOrderAsIndividualRec.Recieved__c = vrGroupNotOrderAsIndividualRec.Recieved__c + orderNotAsIndividualQty;
	                vrGroupNotOrderAsIndividualRec.Cost__c = orderNotAsIndividualVOLIList[0].Line_Item_Cost__c;
                    if(orderNotAsIndividualVOLIList[0].Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c) {
                        vrGroupOrderAsIndividualRec.Per_Unit_Cost__c = (orderNotAsIndividualVOLIList[0].Vendor_Order_Line_Item_Group__r.Total__c/(orderNotAsIndividualVOLIList[0].Vendor_Order_Line_Item_Group__r.Need__c/orderNotAsIndividualVOLIList[0].Vendor_Order_Line_Item_Group__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        vrGroupOrderAsIndividualRec.Per_Unit_Cost__c = vrGroupOrderAsIndividualRec.Cost__c;
                    }
                }
                
                List<Vendor_Receiving_Group__c> vrGroupListToUpsert = new List<Vendor_Receiving_Group__c>();
	            if(orderAsIndividualVOLIList.size() > 0 && vrGroupOrderAsIndividualRec.Id != null) {
	            	vrGroupListToUpsert.add(vrGroupOrderAsIndividualRec);
	            }
	            if(vrGroupNotOrderAsIndividualRec.Id != null) {
	            	vrGroupListToUpsert.add(vrGroupNotOrderAsIndividualRec);
	            }
	            
	            if(vrGroupListToUpsert.size() > 0) {
                    DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupListToUpsert);
	            }
            }
        } else {
        	vrGroupNotOrderAsIndividualRec = insertVRGroup(vorId, false, partList[0], receivedQty, isStockExcessGenerated);
            vrGroupList = [SELECT Recieved__c, Vendor_Receiving_Header__r.Vendor__c, Order_Lots__c, Part__r.Last_Cost__c, Is_Packaged_Part__c, Part__r.Calculated_Cost__c, Package_Qty__c, Part__r.Calculated_Package_Cost__c 
                                FROM Vendor_Receiving_Group__c WHERE Id =: vrGroupNotOrderAsIndividualRec.Id];
            if(vrGroupList.size() > 0) {
                if(vrGroupList[0].Is_Packaged_Part__c) {
                    if(vrGroupList[0].Order_Lots__c != null && vrGroupList[0].Order_Lots__c > 1) {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + (vrGroupList[0].Package_Qty__c * vrGroupList[0].Order_Lots__c);
                    } else {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + vrGroupList[0].Package_Qty__c;
                    }
                } else {
                    if(vrGroupList[0].Order_Lots__c != null && vrGroupList[0].Order_Lots__c > 1) {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + vrGroupList[0].Order_Lots__c;
                    } else {
                        vrGroupList[0].Recieved__c = (receivedQty != null) ? receivedQty : vrGroupList[0].Recieved__c + 1;
                    }
                }
                vrGroupList[0].Cost__c = vrGroupList[0].Part__r.Calculated_Cost__c;
                if(vrGroupList[0].Is_Packaged_Part__c) {
                    vrGroupList[0].Per_Unit_Cost__c = vrGroupList[0].Part__r.Calculated_Package_Cost__c;
                } else {
                    vrGroupList[0].Per_Unit_Cost__c = vrGroupList[0].Cost__c;
                }
                for(PO_Type__c poRec : [Select Discount__c FROM PO_Type__c WHERE Vendor__c =: vrGroupList[0].Vendor_Receiving_Header__r.Vendor__c AND IsDefault__c = true AND Discount__c != null LIMIT 1]) {
                    vrGroupList[0].Discount__c = poRec.Discount__c;
                }
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupList);
            }
        }
    }
    
    public static void addAllLineItemsToItemSubsection(String vorId, String voHeaderId, String voGroupId) {
        if(!AccessControl.ifObjectFieldIsUpdateable('Vendor_Receiving_Group__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        List<Vendor_Order_Line_Item__c> voLineItems = new List<Vendor_Order_Line_Item__c>();
        if(voHeaderId != null) {
            voLineItems = SOQLUtil.getVOLineItemByFieldValue(new Map<String, String> {'Vendor_Order_Header__c' => voHeaderId, 'Vendor_Receiving_Group__c' => null});
            checkAndCreateInProgressVRIfNotExists(vorId, voHeaderId);
            
        } else if(voGroupId != null) {
            voLineItems = SOQLUtil.getVOLineItemByFieldValue(new Map<String, String> {'Vendor_Order_Line_Item_Group__c' => voGroupId, 'Vendor_Receiving_Group__c' => null});
            if(voLineItems.size() > 0) {
                voHeaderId = voLineItems[0].Vendor_Order_Header__c;
                checkAndCreateInProgressVRIfNotExists(vorId, voHeaderId);
            }
        } else if(vorId != null) {
            if(!AccessControl.ifObjectIsAccessible('In_Progress_VR__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            
            List<In_Progress_VR__c> inProgressVRList = [SELECT Vendor_Order_Header__c FROM In_Progress_VR__c WHERE Vendor_Receiving_Header__c =: vorId AND Vendor_Receiving_Header__r.Status__c = 'In Progress'];
            List<String> voHeaderIdList = new List<String>();
            for(In_Progress_VR__c inProgreeVIRec : inProgressVRList) {
                voHeaderIdList.add(inProgreeVIRec.Vendor_Order_Header__c);
            }
            voLineItems = SOQLUtil.getVOLineItemByFieldValue(new Map<String, List<String>> {'Vendor_Order_Header__c' => voHeaderIdList});
            
            List<Vendor_Order_Line_Item__c> tempVOLIItems = new List<Vendor_Order_Line_Item__c>(voLineItems);
	        voLineItems.clear();
	        for(Vendor_Order_Line_Item__c voli : tempVOLIItems){
	            if(voli.Vendor_Receiving_Group__c == null){
	                voLineItems.add(voli);
	            }
	        }
        }
        
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Receiving_Group__c> vrGroupList = [SELECT Is_Order_As_Individual_Item__c, Part__c FROM Vendor_Receiving_Group__c WHERE 
                                            Vendor_Receiving_Header__c =: vorId];
        
        Map<Id, Id> partIdToOrderAsIndividualVRGroupIdMap = new Map<Id, Id>();
        Map<Id, Id> partIdToNotOrderAsIndividualVRGroupIdMap = new Map<Id, Id>();
        for(Vendor_Receiving_Group__c vrGroup : vrGroupList) {
            if(vrGroup.Is_Order_As_Individual_Item__c) {
                if(!partIdToOrderAsIndividualVRGroupIdMap.containsKey(vrGroup.Part__c)) {
                    partIdToOrderAsIndividualVRGroupIdMap.put(vrGroup.Part__c, vrGroup.Id);
                }
            } else {
                if(!partIdToNotOrderAsIndividualVRGroupIdMap.containsKey(vrGroup.Part__c)) {
                    partIdToNotOrderAsIndividualVRGroupIdMap.put(vrGroup.Part__c, vrGroup.Id);
                }
            }
        }
        
        List<Vendor_Receiving_Group__c> vrGroupListToInsert = new List<Vendor_Receiving_Group__c>(); 
        Vendor_Receiving_Group__c vrGroupRec;
        for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
            vrGroupRec = new Vendor_Receiving_Group__c();
            vrGroupRec.Part__c = voliRec.Part__c;
            vrGroupRec.Cost__c = voliRec.Cost__c;
            if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c && !voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                vrGroupRec.Per_Unit_Cost__c = (voliRec.Vendor_Order_Line_Item_Group__r.Total__c/(voliRec.Vendor_Order_Line_Item_Group__r.Need__c/voliRec.Vendor_Order_Line_Item_Group__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
            } else {
                vrGroupRec.Per_Unit_Cost__c = vrGroupRec.Cost__c;
            }
            vrGroupRec.Vendor_Receiving_Header__c = vorId;
            vrGroupRec.Is_Packaged_Part__c = voliRec.Vendor_Order_Line_Item_Group__r.Is_Packaged_Part__c;
            vrGroupRec.Is_Order_Lot__c = voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_Lot__c;
            vrGroupRec.Package_Qty__c = voliRec.Vendor_Order_Line_Item_Group__r.Package_Qty__c;
            vrGroupRec.Package_Unit__c = voliRec.Vendor_Order_Line_Item_Group__r.Package_Unit__c;
            vrGroupRec.Order_Lots__c = voliRec.Vendor_Order_Line_Item_Group__r.Order_Lots__c;
    
            if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                if(!partIdToOrderAsIndividualVRGroupIdMap.containsKey(voliRec.Part__c)) {
                    vrGroupRec.Is_Order_As_Individual_Item__c = true;
                    vrGroupListToInsert.add(vrGroupRec);
                    partIdToOrderAsIndividualVRGroupIdMap.put(voliRec.Part__c, null);
                }
            } else {
                if(!partIdToNotOrderAsIndividualVRGroupIdMap.containsKey(voliRec.Part__c)) {
                    vrGroupRec.Is_Order_As_Individual_Item__c = false;
                    vrGroupListToInsert.add(vrGroupRec);
                    partIdToNotOrderAsIndividualVRGroupIdMap.put(voliRec.Part__c, null);
                }
            }
        }
        
        if(vrGroupListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Vendor_Receiving_Group__c', vrGroupListToInsert);
        }
        Set<Id> newlyInsertedVRGIdSet = new Set<Id>();
        for(Vendor_Receiving_Group__c vrgRec : vrGroupListToInsert) {
            newlyInsertedVRGIdSet.add(vrgRec.Id);
            if(vrgRec.Is_Order_As_Individual_Item__c) {
                if(partIdToOrderAsIndividualVRGroupIdMap.containsKey(vrgRec.Part__c)) {
                    partIdToOrderAsIndividualVRGroupIdMap.put(vrgRec.Part__c, vrgRec.Id);
                }
            } else {
                if(partIdToNotOrderAsIndividualVRGroupIdMap.containsKey(vrgRec.Part__c)) {
                    partIdToNotOrderAsIndividualVRGroupIdMap.put(vrgRec.Part__c, vrgRec.Id);
                }
            }
        }
        
        for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
            if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
                voliRec.Vendor_Receiving_Group__c = partIdToOrderAsIndividualVRGroupIdMap.get(voliRec.Part__c);
            } else {
                voliRec.Vendor_Receiving_Group__c = partIdToNotOrderAsIndividualVRGroupIdMap.get(voliRec.Part__c);
            }
        }
        
        if(voLineItems.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItems);
        }
        
        vrGroupList = [SELECT Id, Recieved__c, (SELECT Qty_Needed__c, Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c FROM Vendor_Order_Line_Items__r) FROM Vendor_Receiving_Group__c WHERE Id IN: vrGroupListToInsert];
        for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
            Decimal need = 0;
            for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
                need += voliRec.Qty_Needed__c;
                if(newlyInsertedVRGIdSet.contains(vrgRec.Id)) {
                    vrgRec.Discount__c = voliRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Discount__c;
                    newlyInsertedVRGIdSet.remove(vrgRec.Id);
                }
            }
            vrgRec.Recieved__c = need;
        }
        
        if(vrGroupList.size() > 0) {
            DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrGroupList);
        }
    }
    
    public static void checkAndCreateInProgressVRIfNotExists(String vrhId, String voHeaderId) {
        List<In_Progress_VR__c> inProgressList = [SELECT Id FROM In_Progress_VR__c WHERE Vendor_Receiving_Header__c =: vrhId AND 
                                                    Vendor_Order_Header__c =: voHeaderId limit 1];
        if(inProgressList.size() == 0) {
            DMLUtility.insertSobjectList('In_Progress_VR__c', createInProgressVR(vrhId, voHeaderId));
        }
    }
    
    public static In_Progress_VR__c createInProgressVR(String vrhId, String voHeaderId) {
        In_Progress_VR__c inProgressVRRec = new In_Progress_VR__c();
        inProgressVRRec.Vendor_Receiving_Header__c = vrhId;
        inProgressVRRec.Vendor_Order_Header__c = voHeaderId;
        return inProgressVRRec;
    }

    public static ResponseWrapper supersedeVRPart(String vrHeaderId, String vrgId, String supersedeToPartId) {
        if(String.isBlank(vrgId)) throw new BlackPurlException('VR Header Id is missing.');
        if(String.isBlank(vrgId)) throw new BlackPurlException('Receiving group Id is missing.');
        if(String.isBlank(supersedeToPartId)) throw new BlackPurlException('Supersede Id is missing.');
        
        ResponseWrapper response = new ResponseWrapper(200, 'Success');
        List<Vendor_Receiving_Group__c> vrGroupList = [SELECT Id, Recieved__c, Part__c, Is_Order_As_Individual_Item__c, (SELECT Id, Vendor_Order_Line_Item_Group__c FROM Vendor_Receiving_Stock_Excesses__r), (SELECT Id, CO_Line_Item__c, Vendor_Order_Header__c FROM Vendor_Order_Line_Items__r) FROM Vendor_Receiving_Group__c 
																WHERE (Id = :vrgId OR Part__c =: supersedeToPartId) AND Vendor_Receiving_Header__c = :vrHeaderId AND Vendor_Receiving_Header__r.Status__c = 'In Progress'];
                
        //VRLI is as separate stock excess 
        if(!vrGroupList.isEmpty()) {
            Vendor_Receiving_Group__c oldPartVRGRec, newPartVRGRec;
            Boolean isOldPartOrderedAsIndividual = false;
            Set<String> voHeaderIdSet = new Set<String>();
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
                if(vrgRec.Id == vrgId) {
                    oldPartVRGRec =  vrgRec;
                    isOldPartOrderedAsIndividual = vrgRec.Is_Order_As_Individual_Item__c;
                    for(Vendor_Order_Line_Item__c voLineItemRec : oldPartVRGRec.Vendor_Order_Line_Items__r) {
                        if(voLineItemRec.CO_Line_Item__c != null) {
                            throw new BlackpurlException('Supersede_Part_On_VO_Validation');
                        }
                        voHeaderIdSet.add(voLineItemRec.Vendor_Order_Header__c);
                    }
                    break;
                }
            }
            for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
                if(vrgRec.Id != vrgId && vrgRec.Is_Order_As_Individual_Item__c == isOldPartOrderedAsIndividual) {
                    newPartVRGRec =  vrgRec;
                    response = new ResponseWrapper(202, 'Item is being merged with existing line on VR for the superseding part' );
                    break;
                }
            }
            if(!VendorOrderService.isPartAlreadyHavePartsAlternate(oldPartVRGRec.Part__c)) {
                VendorOrderService.createNewPartAlternate(oldPartVRGRec.Part__c, supersedeToPartId);
            }
            Part__c supersededPartRec, supersedeToPartRec;
            for(Part__c partRec : [SELECT Id, Part_Number__c, Description__c, Packaged_Part__c, Order_Lots__c, Package_Qty__c, Qty_On_Order__c, Vendor__c, Last_Cost__c FROM Part__c WHERE Id IN :(new List<String>{oldPartVRGRec.Part__c, supersedeToPartId})]) {
                if(partRec.Id == oldPartVRGRec.Part__c) { 
                    supersededPartRec = partRec;
                } else {
                    supersedeToPartRec = partRec;
                }
            }
            if(voHeaderIdSet.size() > 0) {
                supersedeRelatedVOParts(voHeaderIdSet, oldPartVRGRec.Part__c, supersedeToPartId, (newPartVRGRec != null ? newPartVRGRec.Id : oldPartVRGRec.Id));
            }
            
            // update parts On Order quantity
            PartService.updatePartOnOrderQty(new Set<Id>{oldPartVRGRec.Part__c, supersedeToPartId});
            
            Decimal finalReceivedQty = getReceivedQuantity(oldPartVRGRec, supersededPartRec, newPartVRGRec, supersedeToPartRec);
            if(newPartVRGRec != null) {
                newPartVRGRec.Recieved__c = finalReceivedQty;
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', newPartVRGRec);
                DMLUtility.deleteSobjectList('Vendor_Receiving_Group__c', oldPartVRGRec);
            } else {
                oldPartVRGRec.Cost__c = (supersedeToPartRec?.Last_Cost__c != null ? supersedeToPartRec.Last_Cost__c : 0);
                oldPartVRGRec.Part__c = supersedeToPartId;
                oldPartVRGRec.Recieved__c = finalReceivedQty;
                DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', oldPartVRGRec);
            }
        }
        return response;
    }

    private static ResponseWrapper supersedeRelatedVOParts(Set<String> voHeaderIdSet, String partId, String supersedeToPartId, String vrgId) {
        ResponseWrapper response = new ResponseWrapper(201, 'Success');
        if(String.isNotBlank(vrgId) && !voHeaderIdSet.isEmpty() && String.isNotBlank(partId) && String.isNotBlank(supersedeToPartId)) {
            List<Vendor_Order_Line_Item_Group__c> relatedVOGList = [SELECT Id, Unreceived_Qty__c, Vendor_Order_Header__c, Cost__c , Need__c, Received_Qty__c, 
            Part__c, Part__r.Qty_On_Order__c, Is_Order_As_Individual_Item__c, (Select Id, Qty_Needed__c, Needed_For__c, Part__c, Cost__c, 
            Vendor_Order_Header__c, CO_Line_Item__c FROM Vendor_Order_Line_Items__r WHERE Is_Received__c = false Order By CO_Line_Item__c Nulls Last) FROM Vendor_Order_Line_Item_Group__c 
            WHERE Vendor_Order_Header__c IN :voHeaderIdSet AND Unreceived_Qty__c > 0 AND Part__c IN :(new List<String>{partId, supersedeToPartId})];
            
            List<Vendor_Order_Line_Item_Group__c> oldVOGRecList = new List<Vendor_Order_Line_Item_Group__c>();
            Map<String, Vendor_Order_Line_Item_Group__c> newPartVOIdToVOGMap = new Map<String, Vendor_Order_Line_Item_Group__c>();
            for(Vendor_Order_Line_Item_Group__c vog : relatedVOGList) {
                if(vog.Part__c == partId) {
                    if(vog.Vendor_Order_Line_Items__r.isEmpty()) {
                        throw new BlackpurlException('No item to supersede.');
                    } else if(vog.Vendor_Order_Line_Items__r[0].CO_Line_Item__c != null) {
                        throw new BlackpurlException('Supersede_Part_On_VO_Validation');
                    }
                    oldVOGRecList.add(vog);
                } else {
                    response = new ResponseWrapper(202, 'Item is being merged with existing line on VO for the superseding part');
                    newPartVOIdToVOGMap.put(vog.Vendor_Order_Header__c, vog);
                }
            }
            if(!oldVOGRecList.isEmpty()) {
                Part__c supersededPartRec, supersedeToPartRec;
                for(Part__c partRec : [SELECT Id, Part_Number__c, Description__c, Packaged_Part__c, Order_Lots__c, Package_Qty__c, Qty_On_Order__c, Vendor__c, Last_Cost__c FROM Part__c WHERE Id IN :(new List<String>{partId, supersedeToPartId})]) {
                    if(partRec.Id == partId) { 
                        supersededPartRec = partRec;
                    } else {
                        supersedeToPartRec = partRec;
                    }
                }
                if(supersedeToPartRec != null) {
                    updateVOLIAndVOLIGForPart(oldVOGRecList, newPartVOIdToVOGMap, supersededPartRec, supersedeToPartRec, vrgId);
                }
            }
        }
        return response;
    }

	private static void updateVOLIAndVOLIGForPart(List<Vendor_Order_Line_Item_Group__c> oldVOGRecList, 
        Map<String, Vendor_Order_Line_Item_Group__c> newPartVOIdToExistingVOGMap, 
        Part__c supersededPartRec, Part__c supersedeToPartRec, String vrgId) {
        if(oldVOGRecList != null && supersedeToPartRec != null) {
            //Set<String> vogIdUpdateSet = new Set<String>();
            //Insert new VOG if not already exists
            Map<String, Vendor_Order_Line_Item_Group__c> newPartVOIdToVOGUpsertMap = new Map<String, Vendor_Order_Line_Item_Group__c>();
            for(Vendor_Order_Line_Item_Group__c vog : oldVOGRecList) {
                //If VOG is not partially received and no VOG for supersede to part exists
                if((vog.Received_Qty__c == null || vog.Received_Qty__c == 0) && !newPartVOIdToExistingVOGMap.containsKey(vog.Vendor_Order_Header__c)) {
                    vog.Part__c = supersedeToPartRec.Id;
                    vog.Cost__c = supersedeToPartRec.Last_Cost__c != null ? supersedeToPartRec.Last_Cost__c : 0;
                    newPartVOIdToVOGUpsertMap.put(vog.Vendor_Order_Header__c, vog);
                } else if(!(newPartVOIdToExistingVOGMap.containsKey(vog.Vendor_Order_Header__c) || newPartVOIdToVOGUpsertMap.containsKey(vog.Vendor_Order_Header__c))) {
                    Vendor_Order_Line_Item_Group__c volig = new Vendor_Order_Line_Item_Group__c();
                    volig.Vendor_Order_Header__c = vog.Vendor_Order_Header__c;
                    volig.Part__c = supersedeToPartRec.Id;
                    volig.Cost__c = supersedeToPartRec.Last_Cost__c != null ? supersedeToPartRec.Last_Cost__c : 0;
                    newPartVOIdToVOGUpsertMap.put(vog.Vendor_Order_Header__c, volig);
                }
            }
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item_Group__c', newPartVOIdToVOGUpsertMap.values());
            newPartVOIdToExistingVOGMap.putAll(newPartVOIdToVOGUpsertMap);

            //Create new VOLI with unrecived need under new Part's VOG, delete old part's unreceived VOLIs and update/delete VOG based on partially received or not 
            List<SObject> sobjectDeleteList = new List<SObject>();
            Map<String, Vendor_Order_Line_Item__c> newPartVOGIdToVOLIInsertMap = new Map<String, Vendor_Order_Line_Item__c>();
            for(Vendor_Order_Line_Item_Group__c vog : oldVOGRecList) {                
                Vendor_Order_Line_Item__c newVOLIInsertRec = new Vendor_Order_Line_Item__c();
                newVOLIInsertRec.Vendor_Receiving_Group__c = vrgId;
                newVOLIInsertRec.Part__c = supersedeToPartRec.Id;
                newVOLIInsertRec.Vendor_Order_Line_Item_Group__c = newPartVOIdToExistingVOGMap.get(vog.Vendor_Order_Header__c).Id;
                newVOLIInsertRec.Vendor_Order_Header__c = vog.Vendor_Order_Header__c;
                newVOLIInsertRec.Qty_Needed__c = getQuantityNeededBasedOnPartPackageSetting(vog, supersededPartRec, supersedeToPartRec);
                if(newVOLIInsertRec.Qty_Needed__c != null && newVOLIInsertRec.Qty_Needed__c != 0) {
                    newPartVOGIdToVOLIInsertMap.put(newVOLIInsertRec.Vendor_Order_Line_Item_Group__c, newVOLIInsertRec);
                }
                sobjectDeleteList.addAll((List<SObject>) vog.Vendor_Order_Line_Items__r);   //Deleting only volis which are not received, in query we have added filter of Is_Received__c = false
                if((vog.Received_Qty__c == null || vog.Received_Qty__c == 0) && vog.Id != newVOLIInsertRec.Vendor_Order_Line_Item_Group__c) {
                    sobjectDeleteList.add(vog);
                }
            }
            DMLUtility.insertSobjectList('Vendor_Order_Line_Item__c', newPartVOGIdToVOLIInsertMap.values());
            DMLUtility.deleteSobjectList('Vendor_Order_Line_Item_Group__c', sobjectDeleteList);

            List<Vendor_Order_Line_Item_Group__c> voligUpdateList = new List<Vendor_Order_Line_Item_Group__c>();
            for(AggregateResult aggResult : [Select Vendor_Order_Line_Item_Group__c VOLIGId, SUM(Qty_Needed__c) NeededQty FROM Vendor_Order_Line_Item__c 
            WHERE  Vendor_Order_Line_Item_Group__c != null AND (Vendor_Order_Line_Item_Group__c IN :newPartVOIdToExistingVOGMap.values() OR 
            Vendor_Order_Line_Item_Group__c IN :oldVOGRecList) Group By Vendor_Order_Line_Item_Group__c]) {
                voligUpdateList.add(new Vendor_Order_Line_Item_Group__c(
                    Id = String.valueOf(aggResult.get('VOLIGId')),
                    Need__c = aggResult.get('NeededQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('NeededQty'))) : 0
                ));
            }
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voligUpdateList);
        }
    }

    private static Decimal getQuantityNeededBasedOnPartPackageSetting(Vendor_Order_Line_Item_Group__c oldVOG, Part__c supersededPartRec, Part__c supersedeToPartRec) {
        Decimal need = oldVOG.Unreceived_Qty__c != null ? oldVOG.Unreceived_Qty__c : 0;
        if(supersededPartRec.Packaged_Part__c && !oldVOG.Is_Order_As_Individual_Item__c) {
            Long supersededPartPkgNeeded = (need / (supersededPartRec.Package_Qty__c * supersededPartRec.Order_Lots__c)).longValue();
            if(supersededPartPkgNeeded * (supersededPartRec.Package_Qty__c * supersededPartRec.Order_Lots__c) < need) {
                supersededPartPkgNeeded += 1;
            }
            need = supersededPartPkgNeeded * supersedeToPartRec.Package_Qty__c * supersedeToPartRec.Order_Lots__c;
        }
        return need;
    }

    private static Decimal getReceivedQuantity(Vendor_Receiving_Group__c oldVRGRec, Part__c supersededPartRec, Vendor_Receiving_Group__c newVRGRec, Part__c supersedeToPartRec) {
        Decimal oldNeed = (oldVRGRec?.Recieved__c != null ? oldVRGRec?.Recieved__c : 0);
        Decimal newNeed = (newVRGRec?.Recieved__c != null ? newVRGRec?.Recieved__c : 0);
        if(supersededPartRec.Packaged_Part__c && !oldVRGRec.Is_Order_As_Individual_Item__c) {
            Long supersededPartPkgNeeded = (oldNeed / (supersededPartRec.Package_Qty__c * supersededPartRec.Order_Lots__c)).longValue();
            if(supersededPartPkgNeeded * (supersededPartRec.Package_Qty__c * supersededPartRec.Order_Lots__c) < oldNeed) {
                supersededPartPkgNeeded += 1;
            }
            Long supersedeToPartPkgNeeded = (newNeed / (supersedeToPartRec.Package_Qty__c * supersedeToPartRec.Order_Lots__c)).longValue();
            if(supersedeToPartPkgNeeded * (supersedeToPartRec.Package_Qty__c * supersedeToPartRec.Order_Lots__c) < newNeed) {
                supersedeToPartPkgNeeded += 1;
            }
            newNeed = (supersededPartPkgNeeded + supersedeToPartPkgNeeded) * (supersedeToPartRec.Package_Qty__c * supersedeToPartRec.Order_Lots__c);
        } else {
            newNeed += oldNeed;
        }
        return newNeed;
    }

    public static SupersededPartService.PartModal getPartToSupersededPart(String partId) {
		return VendorOrderService.getPartToSupersededPart(partId);
	}

    public static ResponseWrapper validateSupersededVRPart(String partId, String supersededPartId) {
        return VendorOrderService.validateSupersededVOPart(partId, supersededPartId);
    }

    public static ReallocateVRPartsWrapper getReallocatePartDetails(String vrHeaderId, String requestJson) {
        ReallocatePartRequestWrapper requestObj = requestJson != null ? (ReallocatePartRequestWrapper) System.Json.deserialize(requestJson, ReallocatePartRequestWrapper.class) : new ReallocatePartRequestWrapper();
        if(String.isBlank(vrHeaderId)) throw new BlackpurlException('Vendor receiving id cannot be blank');
        ReallocateVRPartsWrapper reallocateVRPartsObj = new ReallocateVRPartsWrapper();

        List<Vendor_Receiving_Group__c> vrgList = getVRGListByVRId(vrHeaderId);
        if(requestObj.ModalName == null || requestObj.ModalName.equalsIgnoreCase('Reallocate stock parts')) {
            reallocateVRPartsObj.ReallocateOnOrderPartsObj = new ReallocateVRPartsWrapper.ReallocateOnOrderPartsWrapper(vrgList);
            if(reallocateVRPartsObj.ReallocateOnOrderPartsObj.PartList == null || reallocateVRPartsObj.ReallocateOnOrderPartsObj.PartList.isEmpty()) {
                reallocateVRPartsObj.ReallocateOversoldPartsObj = new ReallocateVRPartsWrapper.ReallocateOversoldPartsWrapper(vrgList, requestObj.PartIdToAllocatedQtyMapJson);
            }
        } else if(requestObj.ModalName.equalsIgnoreCase(REALLOCATE_OVERSOLD_PARTS)) {
            reallocateVRPartsObj.ReallocateOversoldPartsObj = new ReallocateVRPartsWrapper.ReallocateOversoldPartsWrapper(vrgList, requestObj.PartIdToAllocatedQtyMapJson);
        }
        return reallocateVRPartsObj;
    }

    private static List<Vendor_Receiving_Group__c> getVRGListByVRId(String vrHeaderId) {
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return [Select Id, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Part__r.Oversold_Qty__c, Recieved__c, 
        (Select Id, Received__c FROM Vendor_Order_Line_Items__r WHERE Is_required_For_Customer__c = false AND Is_Service__c = false AND Received__c != null), 
        (Select Id, Received_Qty__c FROM Vendor_Receiving_Stock_Excesses__r WHERE Received_Qty__c != null) FROM Vendor_Receiving_Group__c 
        WHERE Vendor_Receiving_Header__c =: vrHeaderId AND Part__c != null Order By Part__r.Part_Number__c]; 
    }

    public static Map<Id, Decimal> reallocatePartsOnOrderQty(String reallocatePartsOnOderJson) {
        List<ReallocateVRPartsWrapper.PartWrapper> reallocatePartObjList = (List<ReallocateVRPartsWrapper.PartWrapper>) System.Json.deserialize(reallocatePartsOnOderJson, List<ReallocateVRPartsWrapper.PartWrapper>.class);
        Map<Id, Decimal> coliIdToQtyAllocatedMap = validateAndPrepareMap(reallocatePartObjList);
        
        system.debug('coliIdToQtyAllocatedMap::'+coliIdToQtyAllocatedMap);
        Map<Id, Decimal> partIdToQtyAllocatedMap = new Map<Id, Decimal>();
        Map<Id, CO_Line_Item__c> coliIdToRecMap = new Map<Id, CO_Line_Item__c>();

        if(coliIdToQtyAllocatedMap != null && !coliIdToQtyAllocatedMap.isEmpty()) {
            List<CO_Line_Item__c> coliUpdateList = new List<CO_Line_Item__c>();
            List<Service_Order_Line_Item__c> soliUpdateList = new List<Service_Order_Line_Item__c>();
            for(CO_Line_Item__c coliRec : [Select Id, Part__c, Service_Order_Line_Item__c, Service_Order_Line_Item__r.Qty_Committed__c, Qty_To_Order__c, Qty_Committed__c, CO_Header__c, Item_ID__c FROM CO_Line_Item__c WHERE Id IN: coliIdToQtyAllocatedMap.keySet() AND Part__c != null]) {
                if(coliIdToQtyAllocatedMap.get(coliRec.Id) != null && coliIdToQtyAllocatedMap.get(coliRec.Id) > 0 && coliRec.Qty_To_Order__c >= coliIdToQtyAllocatedMap.get(coliRec.Id)) {
                    coliRec.Qty_Committed__c = coliRec.Qty_Committed__c != null ? coliRec.Qty_Committed__c : 0;
                    coliRec.Qty_Committed__c += coliIdToQtyAllocatedMap.get(coliRec.Id);
                    if(coliRec.Service_Order_Line_Item__c != null) {
                        Service_Order_Line_Item__c soliRec = coliRec.Service_Order_Line_Item__r;
                        soliRec.Qty_Committed__c = coliRec.Qty_Committed__c;
                        soliUpdateList.add(soliRec);
                    } else {
                        coliUpdateList.add(coliRec);
                    }
                    if(!partIdToQtyAllocatedMap.containsKey(coliRec.Part__c)) {
                        partIdToQtyAllocatedMap.put(coliRec.Part__c, 0);
                    }
                    partIdToQtyAllocatedMap.put(coliRec.Part__c, partIdToQtyAllocatedMap.get(coliRec.Part__c) + coliIdToQtyAllocatedMap.get(coliRec.Id));
                    coliIdToRecMap.put(coliRec.Id, coliRec);
                }
            }
            system.debug('soliUpdateList::'+soliUpdateList);
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliUpdateList);

            system.debug('coliUpdateList::'+coliUpdateList);
            DMLUtility.updateSobjectList('CO_Line_Item__c', coliUpdateList);

            // Add internal comment on CO
            addInternalCommentOnCO(coliIdToRecMap, reallocatePartObjList[0].SpecialOrderList[0].VRNumber);
        }
        return partIdToQtyAllocatedMap;
    }
    
    private static void addInternalCommentOnCO(Map<Id, CO_Line_Item__c> coliIdToRecMap, String VRNumber) {
        InternalCommentWrapper commentObj;
        List<InternalCommentWrapper> commentObjList = new List<InternalCommentWrapper>();
        for(Id coliId : coliIdToRecMap.keySet()) {
            commentObj = new InternalCommentWrapper();
            commentObj.CoHeaderId = coliIdToRecMap.get(coliId).CO_Header__c;
            commentObj.Comment = 'Special order need for ' + coliIdToRecMap.get(coliId).Item_ID__c + ' was fulfilled by ' + VRNumber;
            commentObjList.add(commentObj);
        }

        InternalCommentService.saveInternalCommentOnCOInBulk(system.JSON.serialize(commentObjList));
    }

    private static Map<Id, Decimal> validateAndPrepareMap(List<ReallocateVRPartsWrapper.PartWrapper> partObjList) {
		Map<Id, Decimal> coliIdToQtyAllocatedMap = new Map<Id, Decimal>();
		if(partObjList != null) {
			for(ReallocateVRPartsWrapper.PartWrapper partReallocateObj : partObjList) {
	            Decimal allocated = 0;
	            for(ReallocateVRPartsWrapper.SpecialOrderWrapper specialOrderObj : partReallocateObj.SpecialOrderList) {
	                specialOrderObj.Allocate = specialOrderObj.Allocate != null && specialOrderObj.Allocate > 0 ? specialOrderObj.Allocate : 0;
	                if(specialOrderObj.COLIId != null && specialOrderObj.Allocate > 0) {
	                    if(!coliIdToQtyAllocatedMap.containsKey(specialOrderObj.COLIId)) {coliIdToQtyAllocatedMap.put(specialOrderObj.COLIId, 0);}
	                    coliIdToQtyAllocatedMap.put(specialOrderObj.COLIId, coliIdToQtyAllocatedMap.get(specialOrderObj.COLIId) + specialOrderObj.Allocate);
	                }
	                allocated += specialOrderObj.Allocate;
	            }
	            if(allocated > partReallocateObj.Received) {
	                throw new BlackPurlException('Total allocated qty for a part cannot be greater than its received qty.');
	            }
	        }
        }
        return coliIdToQtyAllocatedMap;
    }

	public static String reallocatePartsOversoldQty(String vrHeaderId, String reallocatePartsOversoldJson) {
		try{
            List<ReallocateVRPartsWrapper.PartWrapper> partObjList = (List<ReallocateVRPartsWrapper.PartWrapper>)System.JSON.deserialize(reallocatePartsOversoldJson, List<ReallocateVRPartsWrapper.PartWrapper>.class); 
            List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList =  new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
            Decimal maxPartAdjustCount = PartFIFOAdjustmentService.getMaxPartAdjustCount();
            // Do count Adjustment to resolved oversold
            createCountAdjustmentToResolveOversold(partObjList, maxPartAdjustCount, partFIFOBucketLineItemList);
            // Do Stock Adjustment using VR
            createStockAdjustment(partObjList, vrHeaderId, maxPartAdjustCount, partFIFOBucketLineItemList);
            //perform bulk insertion to save DML operation time 
            DMLUtility.insertSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', partFIFOBucketLineItemList);
	      	return BPUtility.getEncodedString('Success');
		} catch(exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
   	}

    public static void createCountAdjustmentToResolveOversold(List<ReallocateVRPartsWrapper.PartWrapper> partObjList, Decimal maxPartAdjustCount, List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList) {
        // Create set of part ids where Resolve Oversold flag is true
        Set<String> partIdSet = new Set<String>();
        for(ReallocateVRPartsWrapper.PartWrapper partObj : partObjList) {
            if(partObj.ResolveOversold != null && partObj.ResolveOversold) {
                partIdSet.add(partObj.Id);
            }
        }
        partIdSet.remove(null);
        if(partIdSet.size() <= 0) throw new BlackPurlException('No item selected.');

        // Get FIFO for Oversold parts
        if(!AccessControl.ifObjectFieldIsAccessible('Part_FIFO_Bucket__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String query = 'SELECT ' + String.join(PartFifoBucket.getPartFIFOBucketList(), ',') + ' FROM Part_FIFO_Bucket__c'
                                + ' WHERE Is_FIFO_Bucket__c = true AND Part__c IN: partIdSet AND Remaining_Qty__c < 0 AND Source_Name__c = \'Oversold\' ORDER BY CreatedDate ASC'; 
        
        List<Part_FIFO_Bucket__c> partFIFOList = Database.query(query);
        List<PartFifoBucket> PartFifoObjList = new List<PartFifoBucket>();
        for(Part_FIFO_Bucket__c partFIFORec : partFIFOList) {
            PartFifoObjList.add(new PartFifoBucket(partFIFORec));
        }
        if(PartFifoObjList.size() <= 0) throw new BlackPurlException('There is no oversold for any of selected parts.');
        
        createCountAdjustment(partIdSet, PartFifoObjList, maxPartAdjustCount, partFIFOBucketLineItemList);
    }

    public static void createCountAdjustment(Set<String> partIdSet, List<PartFifoBucket> partFIFOList, Decimal maxPartAdjustCount, List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList) {
        // Create count adjustment for parts
        Map<Id,Part_FIFO_Bucket__c> partIdToPartFIFORecMap = new Map<Id,Part_FIFO_Bucket__c>();
        for(String partId : partIdSet) {
            Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
            maxPartAdjustCount++;
            partBucketRec.Source_Name__c = 'Count Adjust';			
            partBucketRec.Reference__c = 'Count Adjustment';
            partBucketRec.Part__c = partId;
            partBucketRec.Part_Adjust_Number__c = maxPartAdjustCount;
            partIdToPartFIFORecMap.put(partId, partBucketRec);
        }
        DMLUtility.insertSobjectList('Part_FIFO_Bucket__c', partIdToPartFIFORecMap.values());
        
        // Create FIFO Line Item for oversold parts                
        for(PartFifoBucket partFIFORec : partFIFOList) {
            Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
            partActivityLineItemRec.Part_Adjustment__c = partIdToPartFIFORecMap.get(partFIFORec.PartId).Id;
            partActivityLineItemRec.Part_FIFO_Bucket__c = partFIFORec.FIFOBucketId;
            partActivityLineItemRec.Reference__c = 'Count Adjustment';
            partActivityLineItemRec.Qty_Out__c = partFIFORec.RemainingQty;
            partFIFOBucketLineItemList.add(partActivityLineItemRec);
        }
    }

    public static void createStockAdjustment(List<ReallocateVRPartsWrapper.PartWrapper> partObjList, String vrHeaderId, Decimal maxPartAdjustCount, List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList) {
        Set<String> partIdSet = new Set<String>();
        Map<String, ReallocateVRPartsWrapper.PartWrapper> partIdToReallocatePartObj = new Map<String, ReallocateVRPartsWrapper.PartWrapper>();
        //Create set of parts on which Use Received To Resolve flag true (uses vr to do stock adjustment).
        //Create map of part id to wrapper object
        for(ReallocateVRPartsWrapper.PartWrapper partObj : partObjList) {
            if(partObj.UseReceivedToResolve != null && partObj.UseReceivedToResolve) {
                partIdToReallocatePartObj.put(partObj.Id, partObj);
                partIdSet.add(partObj.Id);
            }
        }
        partIdSet.remove(null);
        if(partIdSet.size() <= 0) return;

        // Get FIFO for VR parts
        if(!AccessControl.ifObjectFieldIsAccessible('Part_FIFO_Bucket__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part_FIFO_Bucket__c> partFIFOList = [SELECT Id, Part__c FROM Part_FIFO_Bucket__c
                        WHERE Is_FIFO_Bucket__c = true AND Part__c IN: partIdSet AND Vendor_Receiving_Header__c =: vrHeaderId AND Source_Name__c = 'Vendor Receiving' ORDER BY createdDate DESC];
        if(partFIFOList.size() <= 0) return;

        // Create stock adjustment for parts
        Map<Id,Part_FIFO_Bucket__c> partIdToPartFIFORecMap = new Map<Id,Part_FIFO_Bucket__c>();
        for(String partId : partIdSet) {
            Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
            maxPartAdjustCount++;
            partBucketRec.Source_Name__c = 'Stock Adjust';			
            partBucketRec.Part_Adjust_Number__c = maxPartAdjustCount;
            partBucketRec.Reference__c = 'Stock Adjustment';
            partBucketRec.Qty_In__c = 0;
            partBucketRec.Cost__c = 0;
            partBucketRec.VRCost__c = 0;
            partBucketRec.Part__c = partId;
            partBucketRec.Is_FIFO_Bucket__c = false;
            partIdToPartFIFORecMap.put(partId, partBucketRec);
        }
        DMLUtility.insertSobjectList('Part_FIFO_Bucket__c', partIdToPartFIFORecMap.values());

        // Create FIFO Line Item for stock adjustment 
        for(Part_FIFO_Bucket__c partFIFORec : partFIFOList) {
            Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
            partActivityLineItemRec.Part_Adjustment__c = partIdToPartFIFORecMap.get(partFIFORec.Part__c).Id;
            partActivityLineItemRec.Part_FIFO_Bucket__c = partFIFORec.Id;
            partActivityLineItemRec.Reference__c = 'Count Adjustment';
            partActivityLineItemRec.Qty_Out__c = partIdToReallocatePartObj.get(partFIFORec.Part__c).Oversold >= partIdToReallocatePartObj.get(partFIFORec.Part__c).Received 
                                                        ? partIdToReallocatePartObj.get(partFIFORec.Part__c).Received : partIdToReallocatePartObj.get(partFIFORec.Part__c).Oversold;
            partFIFOBucketLineItemList.add(partActivityLineItemRec);
        }
    }
    
    public static void saveVRGsCurrentCostSetting(String vrgCurrentCostSettingListStr) {
        if(vrgCurrentCostSettingListStr != null) {
            List<VRGCurrentCostSettingWrapper> vrgCurrentCostObjSettingList = (List<VRGCurrentCostSettingWrapper>) System.Json.deserialize(vrgCurrentCostSettingListStr, List<VRGCurrentCostSettingWrapper>.class);
            List<Vendor_Receiving_Group__c> vrgRecUpdateList = new List<Vendor_Receiving_Group__c>();
            for(VRGCurrentCostSettingWrapper vrgOj : vrgCurrentCostObjSettingList) {
                if(vrgOj.VRGId != null) {
                    vrgRecUpdateList.add(new Vendor_Receiving_Group__c(Id = vrgOj.VRGId, Ignore_Current_Cost_Update__c = !(vrgOj.IsUpdateCurrentCost != null && vrgOj.IsUpdateCurrentCost), Cost_Update_Reviewed__c = true));
                }
            }
            VendorReceivingGroupTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Vendor_Receiving_Group__c', vrgRecUpdateList);
            VendorReceivingGroupTriggerHelper.isForceStopTrigger = false;
        }
    }

    public static List<VRGCurrentCostSettingWrapper> getVRGsCurrentCostSetting(String vrHeaderId) {
        List<VRGCurrentCostSettingWrapper> vrgCurrentCostObjSettingList = new List<VRGCurrentCostSettingWrapper>();
        if(String.isNotBlank(vrHeaderId)) {
            List<Vendor_Receiving_Group__c> vrgList = [Select Id, Ignore_Current_Cost_Update__c, Cost_Update_Reviewed__c, Is_Order_As_Individual_Item__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Vendor_Receiving_Header__r.Vendor__c, 
                (Select Id, Vendor_Order_Header__r.Purchase_Order_Type__r.Update_Current_Cost__c FROM Vendor_Order_Line_Items__r 
                WHERE Received__c != null AND Received__c != 0 AND Vendor_Order_Header__r.Purchase_Order_Type__r.Update_Current_Cost__c = true LIMIT 1), 
                (Select Id FROM Vendor_Receiving_Stock_Excesses__r WHERE Received_Qty__c != null AND Received_Qty__c != 0 LIMIT 1) FROM Vendor_Receiving_Group__c 
                                                        WHERE Vendor_Receiving_Header__c =: vrHeaderId AND Part__c != null Order By Part__r.Part_Number__c];
            
            PO_Type__c vendorDefaultPOType;
            if(!vrgList.isEmpty()) {
                List<PO_Type__c> poTypeList = [SELECT Id, Update_Current_Cost__c FROM PO_Type__c WHERE Vendor__c =: vrgList[0].Vendor_Receiving_Header__r.Vendor__c AND IsDefault__c = true LIMIT 1];
                if(!poTypeList.isEmpty()) {
                    vendorDefaultPOType = poTypeList[0];
                }
            }
            for(Vendor_Receiving_Group__c vrGroup : vrgList) {
                vrgCurrentCostObjSettingList.add(new VRGCurrentCostSettingWrapper(vrGroup, vendorDefaultPOType));
            }
        }
        return vrgCurrentCostObjSettingList;
    }

    public static Boolean isSimilarPackingSlipNumberExists(VORHeader VORHeaderRec) {
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        Integer sizeOfVORList = [SELECT Id FROM Vendor_Receiving_Header__c WHERE Vendor__c =: VORHeaderRec.VendorId AND Packing_Slip_Number__c =: VORHeaderRec.PackagingSlipNumber LIMIT 1].size();
        return sizeOfVORList > 0;
    }

    public static Boolean isSimilarInvoiceNumberExists(VORHeader VORHeaderRec) {
        if(!VORHeaderRec.IsReceivingFromInvoice) return false;
        if(!AccessControl.ifObjectIsAccessible('Vendor_Invoicing_Header__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        Integer sizeOfVIList = [SELECT Id FROM Vendor_Invoicing_Header__c WHERE Vendor__c =: VORHeaderRec.VendorId AND Invoice_Number__c =: VORHeaderRec.PackagingSlipNumber LIMIT 1].size();
        return sizeOfVIList > 0;
    }

    public static Boolean getCurrentCostUpdateSetting(Vendor_Receiving_Group__c vrGroup, PO_Type__c vendorDefaultPOType) {
        Boolean updateCurrentCost = false;
        if(vrGroup != null && vrGroup.Part__c != null) {
            for(Vendor_Order_Line_Item__c voliRec : vrGroup.Vendor_Order_Line_Items__r) {
                if(voliRec.Vendor_Order_Header__c != null && voliRec.Vendor_Order_Header__r.Purchase_Order_Type__c != null && voliRec.Vendor_Order_Header__r.Purchase_Order_Type__r.Update_Current_Cost__c) {
                    updateCurrentCost = true;
                    break;
                }
            }
            if(!(updateCurrentCost || vrGroup.Vendor_Receiving_Stock_Excesses__r.isEmpty())) {
                updateCurrentCost = (vendorDefaultPOType != null)? vendorDefaultPOType.Update_Current_Cost__c : false;
            }
        }
        return updateCurrentCost;
    } 

    public static Map<Id, Vendor_Receiving_Group__c> getVRGIdToRecMap(List<Vendor_Invoicing_Group__c> vigList) {
        Set<Id> vrgIdSet = new Set<Id>();
        for(Vendor_Invoicing_Group__c vig : vigList) {
            vrgIdSet.add(vig.Vendor_Receiving_Group__r.Id);
        }
        Map<Id, Vendor_Receiving_Group__c> vrgIdToRecMap = new Map<Id, Vendor_Receiving_Group__c>([SELECT Part__c, Vendor_Receiving_Header__r.Vendor__c, 
                        (SELECT Vendor_Order_Header__c, Vendor_Order_Header__r.Purchase_Order_Type__c, Vendor_Order_Header__r.Purchase_Order_Type__r.Update_Current_Cost__c FROM Vendor_Order_Line_Items__r), 
                        (SELECT Id FROM Vendor_Receiving_Stock_Excesses__r WHERE Received_Qty__c != null AND Received_Qty__c != 0 LIMIT 1)
                        FROM Vendor_Receiving_Group__c WHERE Id IN: vrgIdSet]);
        return vrgIdToRecMap;
    }

    public static void savePartDetails(String partJson) {
        PartDetail partDetailObj = (PartDetail)System.JSON.deserialize(partJson, PartDetail.class);
        Part__c partRec = new Part__c(Id = partDetailObj.Id, MSRP__c = partDetailObj.MSRP, Retail_Price__c = partDetailObj.Retail, 
                                        Sale_Price__c = partDetailObj.SalePrice, 
                                        Last_Edited__c = system.now(), Last_Edited_By__c = UserInfo.getUserId());
        if(partDetailObj.AssignedLocations != null && partDetailObj.AssignedLocations.size() > 0) {
            List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(partDetailObj.AssignedLocations);
            if(locationStrListForFields.size() == 2) {
                partRec.Assigned_Location_1__c = locationStrListForFields[0];
                partRec.Assigned_Location_2__c = locationStrListForFields[1];
            }
        } else {
            partRec.Assigned_Location_1__c = partRec.Assigned_Location_2__c = '';
        }
        DMLUtility.updateSobjectList('Part__c', partRec);
    }
    
    public static String getActiveVRCountByVendorId(String vendorId) {
    	String query = 'SELECT Count(Id) VRCount FROM Vendor_Receiving_Header__c WHERE Vendor__c = \''+ BPUtility.escapeSingleQuotes(vendorId) + '\' AND Status__c = \'In Progress\'';
    	List<AggregateResult> aggList = SOQLUtility.getQueryResults('Vendor_Receiving_Header__c', query);
    	return String.valueOf((aggList.size() > 0) ? (Integer) aggList[0].get('VRCount') : 0);
    }

    public static GlobalSearchResultsWrapper getActiveVRsByVendorId(String filterJson) {
        GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj = (GlobalSearchResultsWrapper.COOpenOrderFilterJSON) System.JSON.deserialize(filterJson, 
                                                                        GlobalSearchResultsWrapper.COOpenOrderFilterJSON.class);
        
        String query = 'SELECT Name, Vendor__r.Name, Packing_Slip_Number__c, Receiving_Total__c, LastModifiedDate, Last_Modified_Date__c, Status__c FROM Vendor_Receiving_Header__c WHERE Vendor__c = \'' + BPUtility.escapeSingleQuotes(filterObj.VendorId) + 
            			'\' AND Status__c = \'In Progress\' ORDER BY Name Desc ' + 
            			SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);

        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Receiving_Header__c> vrHeaderList = Database.query(query);
        return new GlobalSearchResultsWrapper(vrHeaderList.size(), vrHeaderList);
    }

    public class PartInfoWrapper {
        public List<Part> PartList;
        public String VendorId;
        
        public PartInfoWrapper(String vendorId) {
            this.PartList = new List<Part>();
            this.VendorId = vendorId;
        }
    }
    
    public class Part {
        public String PartNumber;
        public String PartId;
        
        public Part(String partNumber, String partId) {
            this.PartNumber = partNumber;
            this.PartId = partId;
        }
    }

    public class ReallocatePartRequestWrapper {
        public String ModalName;
        public Map<Id, Decimal> PartIdToAllocatedQtyMapJson;
    }
}
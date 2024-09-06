public without sharing class VendorOrderReceivingService {
    
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
    
    public static void updateItemsSection(String vrGroupId, Decimal qty, Decimal cost) {
        
        if(!AccessControl.ifObjectIsAccessible('Vendor_Receiving_Group__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Receiving_Group__c> vrGroupList = 
               [SELECT Part__c, Part__r.Packaged_Part__c, Part__r.Package_Qty__c, Part__r.Package_Cost__c, Sublet__c, Is_Order_As_Individual_Item__c,
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
                if(vrGroupRec.Part__c != null && vrGroupRec.Part__r.Packaged_Part__c && !vrGroupRec.Is_Order_As_Individual_Item__c) {
                    vrGroupRec.Recieved__c = qty * vrGroupRec.Part__r.Package_Qty__c ;
                    if(vrGroupRec.Part__r.Package_Qty__c != 0) {
                        vrGroupRec.Cost__c = cost / vrGroupRec.Part__r.Package_Qty__c;
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
    	vrGroupRec.Cost__c = (partRec != null) ? partRec.Last_Cost__c : 0;
        vrGroupRec.Part__c = partRec.Id;
        vrGroupRec.Is_Order_As_Individual_Item__c = isOrderedAsIndividualItem;
        vrGroupRec.Vendor_Receiving_Header__c = vorId;
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
        List<Vendor_Receiving_Group__c> vrGroupList = [SELECT Cost__c, Recieved__c, Is_Order_As_Individual_Item__c, Part__r.Last_Cost__c, Part__r.Packaged_Part__c, 
                    Part__r.Package_Qty__c FROM Vendor_Receiving_Group__c WHERE Part__c = :partId AND Vendor_Receiving_Header__c = :vorId];
        
        if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> partList = [SELECT Last_Cost__c, Packaged_Part__c, Package_Qty__c FROM Part__c WHERE Id =: partId];
        
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
        if(!isStockExcessGenerated) {
            String query = 'SELECT ' + String.join(VendorOrderLineItem.fieldsList(), ', ') + ' FROM Vendor_Order_Line_Item__c ' + 
                'WHERE Vendor_Order_Line_Item_Group__c != null AND Vendor_Order_Line_Item_Group__r.Status__c != \'Cancelled\' AND Part__c =: partId ' +
                'AND Vendor_Order_Header__r.Status__c IN (\'On Order\', \'Partially Received\') AND Vendor_Receiving_Group__c = null';
            List<Vendor_Order_Line_Item__c> voLineItems = Database.query(query);
            //List<Vendor_Order_Line_Item__c> voLineItems = SOQLUtil.getVOLineItemsForGivenPartAndVendorReceiving(partId, vorId);
            
            if(voLineItems.size() == 0) {
            	if(vrGroupNotOrderAsIndividualRec.Id == null && vrGroupOrderAsIndividualRec.Id == null) {
            		vrGroupNotOrderAsIndividualRec = insertVRGroup(vorId, false, partList[0], receivedQty, isStockExcessGenerated);
                    vrGroupNotOrderAsIndividualRec.Recieved__c = (vrGroupNotOrderAsIndividualRec.Recieved__c == null || vrGroupNotOrderAsIndividualRec.Recieved__c == 0) ?  
                                            (PartList[0].Packaged_Part__c ? PartList[0].Package_Qty__c : 1) : 0;
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
            	}
            	if(vrGroupNotOrderAsIndividualRec.Id == null && orderNotAsIndividualVOLIList.size() > 0) {
            		vrGroupNotOrderAsIndividualRec = insertVRGroup(vorId, false, partList[0], receivedQty, isStockExcessGenerated);
            	}
            	
            	Decimal orderAsIndividualQty = 0;
	            Decimal orderNotAsIndividualQty = 0;
    			for(Vendor_Order_Line_Item__c voliRec : voLineItems) {
	            	if(voliRec.Vendor_Order_Line_Item_Group__r.Is_Order_As_Individual_Item__c) {
            			voliRec.Vendor_Receiving_Group__c = vrGroupOrderAsIndividualRec.Id;
            			orderAsIndividualQty += voliRec.Qty_Needed__c;
            		} else {
	            		voliRec.Vendor_Receiving_Group__c = vrGroupNotOrderAsIndividualRec.Id;
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
            	}

                if(orderNotAsIndividualVOLIList.size() > 0) {
                	vrGroupNotOrderAsIndividualRec.Recieved__c = (vrGroupNotOrderAsIndividualRec.Recieved__c == null) ? 0 : vrGroupNotOrderAsIndividualRec.Recieved__c;
	                vrGroupNotOrderAsIndividualRec.Recieved__c = vrGroupNotOrderAsIndividualRec.Recieved__c + orderNotAsIndividualQty;
	                vrGroupNotOrderAsIndividualRec.Cost__c = orderNotAsIndividualVOLIList[0].Line_Item_Cost__c;
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
            vrGroupList = [SELECT Recieved__c, Part__r.Order_Lots__c, Part__r.Last_Cost__c, Part__r.Packaged_Part__c, Part__r.Package_Qty__c 
                                FROM Vendor_Receiving_Group__c WHERE Id =: vrGroupNotOrderAsIndividualRec.Id];
            if(vrGroupList.size() > 0) {
                if(vrGroupList[0].Part__r.Packaged_Part__c) {
                    if(vrGroupList[0].Part__r.Order_Lots__c != null && vrGroupList[0].Part__r.Order_Lots__c > 1) {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + (vrGroupList[0].Part__r.Package_Qty__c * vrGroupList[0].Part__r.Order_Lots__c);
                    } else {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + vrGroupList[0].Part__r.Package_Qty__c;
                    }
                } else {
                    if(vrGroupList[0].Part__r.Order_Lots__c != null && vrGroupList[0].Part__r.Order_Lots__c > 1) {
                        vrGroupList[0].Recieved__c = vrGroupList[0].Recieved__c + vrGroupList[0].Part__r.Order_Lots__c;
                    } else {
                        vrGroupList[0].Recieved__c = (receivedQty != null) ? receivedQty : vrGroupList[0].Recieved__c + 1;
                    }
                }
                vrGroupList[0].Cost__c = vrGroupList[0].Part__r.Last_Cost__c;
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
            vrGroupRec.Vendor_Receiving_Header__c = vorId;
            
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
        
        for(Vendor_Receiving_Group__c vrgRec : vrGroupListToInsert) {
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
        
        vrGroupList = [SELECT Id, Recieved__c, (SELECT Qty_Needed__c FROM Vendor_Order_Line_Items__r) FROM Vendor_Receiving_Group__c WHERE Id IN: vrGroupListToInsert];
        for(Vendor_Receiving_Group__c vrgRec : vrGroupList) {
            Decimal need = 0;
            for(Vendor_Order_Line_Item__c voliRec : vrgRec.Vendor_Order_Line_Items__r) {
                need += voliRec.Qty_Needed__c;
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
}
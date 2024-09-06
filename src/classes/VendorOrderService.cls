/** 
 * Author: Richa Mittal
 * Since: June 14, 2021
 * Name: VendorOrderService 
 * Description: service class which contains all methods related to Vendor Order Ctrl.
**/
global without sharing class VendorOrderService {
    
    public static String processBRPPartsOrder(String voHeaderId, String vendorId, String orderActionCode) {
    	HttpResponse response = new HttpResponse();
    	ResponseWrapper resObj;
        try {
            if(BRPUtility.isPartsMasterVendor(vendorId)) {
            	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            	List<Vendor_Order_Header__c> voHeaderList = [select Id, Name, Expected_Date_Formula__c, (SELECT Id, Need__c, Part__r.Package_Qty__c, 
																Part__r.Packaged_Part__c, Part__r.Package_Unit__c, Part__r.Part_Number__c 
																FROM Vendor_Order_Line_Item_Groups__r WHERE Part__c != null) 
													    		FROM Vendor_Order_Header__c WHERE Id =:voHeaderId];
            	
            	BRPPartsOrderService.orderActionCode = orderActionCode;
            	if(voHeaderList.size() > 0 && voHeaderList[0].Vendor_Order_Line_Item_Groups__r.size() > 0) {
            		String requestBody = BRPPartsOrderService.createRequestBody(voHeaderList[0]);
            		response = BRPUtility.syncToBRP('BRPPartsOrder', requestBody, 'POST');
            		Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeToErrorListMap = BRPPartsOrderService.handleValidatePartsOrderResponse(requestBody, response.getBody(), orderActionCode);
            		
            		if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
            			if(AccessControl.ifObjectFieldIsCreateable('WebService_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
			            insert BaseIntegration.webServiceLogs;
			        }
            		
            		// update BRP error Json in VO header
            		resObj = updateBRPResponse(voHeaderId, errorTypeToErrorListMap, orderActionCode);
            	}
            } else {
            	resObj = new ResponseWrapper(200, 'success');
            }
        } catch(Exception e) {
            BRPLogService obj = new BRPLogService('Validate Parts Order', null, null, null, null, 
			    				e.getMessage() + ' - ' + response.getBody(), 'Error', 'VendorOrderService', 'validateBRPPartsOrder');
			obj.createLog();
			resObj = new ResponseWrapper(500, e.getMessage());
        }
        return (resObj != null ? System.JSON.serialize(resObj, true) : null);
    }
    
    public static String getBRPPartsOrderDetails(String voHeaderId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Vendor_Order_Header__c> voHeaderList = [SELECT BRP_Response__c FROM Vendor_Order_Header__c WHERE Id =:voHeaderId];
    	return (voHeaderList.size() > 0 ? voHeaderList[0].BRP_Response__c : '');
    }
    
    private static ResponseWrapper updateBRPResponse(String voHeaderId, Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeToErrorListMap, String orderActionCode) {
    	ResponseWrapper resObj;
    	Vendor_Order_Header__c voHeaderToUpdate = new Vendor_Order_Header__c(Id = voHeaderId);
		if(errorTypeToErrorListMap != null && errorTypeToErrorListMap.size() > 0) {
			if(errorTypeToErrorListMap.containsKey('Error') && errorTypeToErrorListMap.get('Error').size() > 0) {
				voHeaderToUpdate.BRP_Response__c = System.JSON.serialize(errorTypeToErrorListMap);
				resObj = new ResponseWrapper(400, 'error');
			} else if(errorTypeToErrorListMap.containsKey('Success') && errorTypeToErrorListMap.get('Success').size() > 0) {
				voHeaderToUpdate.BRP_Response__c = null;
    			resObj = new ResponseWrapper(200, 'success');
			} else if(errorTypeToErrorListMap.containsKey('Warning') && errorTypeToErrorListMap.get('Warning').size() > 0) {
				if(orderActionCode == 'Create') {
					voHeaderToUpdate.BRP_Response__c = null;
    				resObj = new ResponseWrapper(200, 'success');
				} else {
					voHeaderToUpdate.BRP_Response__c = System.JSON.serialize(errorTypeToErrorListMap);
					resObj = new ResponseWrapper(400, 'error');
				}
			}
		} else {
			voHeaderToUpdate.BRP_Response__c = null;
    		resObj = new ResponseWrapper(200, 'success');
		}
		
		DMLUtility.updateSobjectList('Vendor_Order_Header__c', voHeaderToUpdate);
		return resObj;
    }

	 /**
     * Name: groupAllSimilarVOLineItem
     * Desc: Method to merge all similar VO Line item and make one VO Line Item Group record to dispaly in Items subsection
     * @param:  (1) VendorId - String - Vendor Id
     *          (2) partId - String - Part Id
     *          (3) voHeaderId - String - voHeader Id
    **/
    global static void groupAllSimilarVOLineItem(String vendorId, String partId, String voHeaderId) {
        List<Vendor_Order_Line_Item__c> voLineItemsWithSimilarParts = SOQLUtil.getVOLineItemWithSimilarParts(null, partId, voHeaderId);
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = SOQLUtil.getVOLIGroupByFieldName('Part__c', partId, voHeaderId);
        Vendor_Order_Line_Item_Group__c voliGroupRec = new Vendor_Order_Line_Item_Group__c();
        List<Part__c> partRecList = SOQLUtil.getPartDetailRecordsByFieldName('Id', partId);
        
        Decimal alreadyOrderedQty = 0;
        Boolean isOrderAsIndividualLineItem = voliGroupList.size() > 0 ? voliGroupList[0].Is_Order_As_Individual_Item__c : false;

        
        if(voliGroupList.size() > 0) {
            voliGroupRec.Id = voliGroupList[0].Id;
            for(Vendor_Order_Line_Item__c voli : voliGroupList[0].Vendor_Order_Line_Items__r) {
                if(!(voli.Is_required_For_Customer__c || voli.Is_Service__c)) {
                    alreadyOrderedQty += voli.Qty_Needed__c;
                } 
            }
        } else if(voLineItemsWithSimilarParts.size() > 0) {
            voliGroupRec.Part__c = partId;
            voliGroupRec.Vendor_Order_Header__c = voHeaderId;
            if(!partRecList.isEmpty()) {
                voliGroupRec.Is_Packaged_Part__c = partRecList[0].Packaged_Part__c;
                voliGroupRec.Package_Qty__c = partRecList[0].Package_Qty__c;
                voliGroupRec.Package_Unit__c = partRecList[0].Package_Unit__c;
                voliGroupRec.Is_Order_Lot__c = partRecList[0].Is_OrderLot__c;
                voliGroupRec.Order_Lots__c = partRecList[0].Order_Lots__c;
            }
            voliGroupList.add(voliGroupRec);
        }

        Decimal needForVOLineItem = 0;
        Vendor_Order_Line_Item__c voLineItemForExcessStock;
        for(Vendor_Order_Line_Item__c voliRec : voLineItemsWithSimilarParts) {
            needForVOLineItem += voliRec.Qty_Needed__c;
            if(voliRec.Is_Excess__c) {
                voLineItemForExcessStock = voliRec;
            }
        }
        // Topping Up Need
        Decimal need = VendorOrderCtrl.toppingUpNeed(voliGroupList, needForVOLineItem, isOrderAsIndividualLineItem);
        
        voliGroupRec.Need__c = need;
        if(voliGroupRec != null) {
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item_Group__c', voliGroupRec);
        }
        
        if(need > needForVOLineItem) {
            Decimal execessNeed = need - needForVOLineItem;
            if(voLineItemForExcessStock == null){
                voLineItemForExcessStock = new Vendor_Order_Line_Item__c();
            }
            voLineItemForExcessStock.Qty_Needed__c = execessNeed;
            voLineItemForExcessStock.Part__c = partId;
            voLineItemForExcessStock.Is_Excess__c = true;
            voLineItemForExcessStock.Vendor_Order_Header__c = voHeaderId;
            voLineItemForExcessStock.Vendor_Order_Line_Item_Group__c = voliGroupRec.Id;
        }
        
        for(Vendor_Order_Line_Item__c voliRec : voLineItemsWithSimilarParts) {
            voliRec.Vendor_Order_Header__c = voHeaderId;
            voliRec.Vendor_Order_Line_Item_Group__c = voliGroupRec.Id;
        }
        if(voLineItemForExcessStock != null && voLineItemForExcessStock.Id == null) {
            voLineItemsWithSimilarParts.add(voLineItemForExcessStock);
        }
        if(voLineItemsWithSimilarParts.size() > 0) {
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voLineItemsWithSimilarParts);
        }
        VendorOrderCtrl.updatePartOrderedQty(vendorId, voHeaderId, new Map<Id, Decimal>{voliGroupRec.Id => alreadyOrderedQty});
    }

	//Below method will not be used for VO supersession, vrgId is handled but we are using seperated method in VendorOrderReccivingService.cls for VR Supersession 
    public static ResponseWrapper supersedeVOPart(Set<String> voHeaderIdSet, String partId, String supersedeToPartId, String vrgId) {
        ResponseWrapper response = new ResponseWrapper(201, 'Success');
		if(!voHeaderIdSet.isEmpty() && String.isNotBlank(partId) && String.isNotBlank(supersedeToPartId)) {
            List<Vendor_Order_Line_Item__c> relatedVOLineItemList = [SELECT Id, Part__c, Part__r.Qty_On_Order__c, Qty_Needed__c, Needed_For__c, 
            Vendor_Order_Line_Item_Group__r.Part__c, Vendor_Order_Line_Item_Group__r.Need__c, Vendor_Order_Line_Item_Group__r.Cost__c, 
            Vendor_Order_Line_Item_Group__r.Received_Qty__c, Vendor_Order_Header__c, CO_Line_Item__c FROM Vendor_Order_Line_Item__c 
            WHERE Vendor_Order_Header__c IN :voHeaderIdSet AND Is_Received__c = false AND Part__c IN :(new List<String>{partId, supersedeToPartId})];

            List<Vendor_Order_Line_Item__c> oldPartVOLIList = new List<Vendor_Order_Line_Item__c>();
            Map<String, List<Vendor_Order_Line_Item__c>> newPartVOIdToVOLIListMap = new Map<String, List<Vendor_Order_Line_Item__c>>();
            for(Vendor_Order_Line_Item__c voli : relatedVOLineItemList) {
                if(voli.Part__c == partId) {
                    if(voli.CO_Line_Item__c != null) {
                        throw new BlackpurlException('Supersede_Part_On_VO_Validation');
                    }
                    oldPartVOLIList.add(voli);
                } else {
                    response = new ResponseWrapper(202, 'Item is being merged with existing line on VO for the superseding part');
                    if(!newPartVOIdToVOLIListMap.containsKey(voli.Vendor_Order_Header__c)) {
                        newPartVOIdToVOLIListMap.put(voli.Vendor_Order_Header__c, new List<Vendor_Order_Line_Item__c>());
                    }
                    newPartVOIdToVOLIListMap.get(voli.Vendor_Order_Header__c).add(voli);
                }
            }
            List<Part__c> supersedeToPartList = [SELECT Id, Part_Number__c, Description__c, Packaged_Part__c, Order_Lots__c, Package_Qty__c, Qty_On_Order__c, Vendor__c, Last_Cost__c, Calculated_Cost__c FROM Part__c WHERE Id = :supersedeToPartId LIMIT 1];
            if(!isPartAlreadyHavePartsAlternate(partId)) {
                createNewPartAlternate(partId, supersedeToPartId);
            }
            if(!(oldPartVOLIList.isEmpty() || supersedeToPartList.isEmpty())) {
                updateVOLIAndVOLIGForPart(oldPartVOLIList, newPartVOIdToVOLIListMap, supersedeToPartList[0], vrgId);
            }
            if(String.isBlank(vrgId) && supersedeToPartList[0].Vendor__c != null) {
                // Delete previously created stock excess and create new
                updateStockExcessOnVO(voHeaderIdSet, supersedeToPartList);
            }
            // update parts On Order quantity
            PartService.updatePartOnOrderQty(new Set<Id>{partId, supersedeToPartId});
        }
		return response;
    }

    public static Boolean isPartAlreadyHavePartsAlternate(String partId) {
        return !([SELECT Id FROM Part_Alternates__c WHERE Part_ID__c = :partId AND Relation__c = 'Replaced By' LIMIT 1].isEmpty());
    }

    public static void createNewPartAlternate(String partId, String supersedeToPartId) {
        List<Part_Alternates__c> partAlternateList = new List<Part_Alternates__c>();
        partAlternateList.add(new Part_Alternates__c(Part_ID__c = partId, Alternate_Part_ID__c = supersedeToPartId, Relation__c = 'Replaced By'));
        partAlternateList.add(new Part_Alternates__c(Part_ID__c = supersedeToPartId, Alternate_Part_ID__c = PartId, Relation__c = 'Replaces'));                                             
		DMLUtility.insertSobjectList('Part_Alternates__c', partAlternateList);

		ViewPartRelatedListCtrl.updateSupersededFieldsOnPart(partId, supersedeToPartId, 'Replaced By');
    }
    
    private static void updateVOLIAndVOLIGForPart(List<Vendor_Order_Line_Item__c> voLineItemList, 
        Map<String, List<Vendor_Order_Line_Item__c>> newPartVOIdToVOLIListMap, Part__c supersedeToPartRec, String vrgId) {
        if(voLineItemList != null && supersedeToPartRec != null) {
            Set<String> vogIdUpdateSet = new Set<String>();
            Map<String, Vendor_Order_Line_Item_Group__c> voIdToVOLIGToUpsertMap = new Map<String, Vendor_Order_Line_Item_Group__c>();
            Map<String, Vendor_Order_Line_Item_Group__c> voligDeleteMap = new Map<String, Vendor_Order_Line_Item_Group__c>();
            Boolean isPartiallyReceivedExists = false;
            for(Vendor_Order_Line_Item__c voLineItem : voLineItemList) {
                voLineItem.Part__c = supersedeToPartRec.Id;
                voLineItem.Line_Item_Cost__c = (supersedeToPartRec.Calculated_Cost__c != null ? supersedeToPartRec.Calculated_Cost__c : 0);
                if(String.isNotBlank(vrgId)) {
                    voLineItem.Vendor_Receiving_Group__c = vrgId;
                }
                //If VOG already exists for supersede to Part
                if(newPartVOIdToVOLIListMap.containsKey(voLineItem.Vendor_Order_Header__c) && !newPartVOIdToVOLIListMap.get(voLineItem.Vendor_Order_Header__c).isEmpty()) {
                    if(voLineItem.Vendor_Order_Line_Item_Group__r.Received_Qty__c == null || voLineItem.Vendor_Order_Line_Item_Group__r.Received_Qty__c <= 0) {
                        voligDeleteMap.put(voLineItem.Vendor_Order_Line_Item_Group__c, voLineItem.Vendor_Order_Line_Item_Group__r);
                    } else {
                        vogIdUpdateSet.add(voLineItem.Vendor_Order_Line_Item_Group__c);
                    }
                    voLineItem.Vendor_Order_Line_Item_Group__c = newPartVOIdToVOLIListMap.get(voLineItem.Vendor_Order_Header__c)[0].Vendor_Order_Line_Item_Group__c;
                    vogIdUpdateSet.add(voLineItem.Vendor_Order_Line_Item_Group__c);
                //If VOG not exists for supersede to Part
                } else if(!voIdToVOLIGToUpsertMap.containsKey(voLineItem.Vendor_Order_Header__c)) {
                    Vendor_Order_Line_Item_Group__c volig = new Vendor_Order_Line_Item_Group__c(Vendor_Order_Header__c = voLineItem.Vendor_Order_Header__c);
                    if(voLineItem.Vendor_Order_Line_Item_Group__r.Received_Qty__c != null && voLineItem.Vendor_Order_Line_Item_Group__r.Received_Qty__c > 0) {
                        isPartiallyReceivedExists = true;
                    } else {
                        volig.Id = voLineItem.Vendor_Order_Line_Item_Group__c;
                    }
                    vogIdUpdateSet.add(voLineItem.Vendor_Order_Line_Item_Group__c);
                    
                    volig.Part__c = supersedeToPartRec.Id;
                    volig.Cost__c = voLineItem.Line_Item_Cost__c;
                    voIdToVOLIGToUpsertMap.put(voLineItem.Vendor_Order_Header__c, volig);
                }
                vogIdUpdateSet.add(voLineItem.Vendor_Order_Line_Item_Group__c);
            }
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item_Group__c', voIdToVOLIGToUpsertMap.values());
            if(isPartiallyReceivedExists) {
                for(Vendor_Order_Line_Item__c voLineItem : voLineItemList) {
                    voLineItem.Part__c = supersedeToPartRec.Id;
                    voLineItem.Line_Item_Cost__c = (supersedeToPartRec.Calculated_Cost__c != null ? supersedeToPartRec.Calculated_Cost__c : 0);
                    voLineItem.Vendor_Order_Line_Item_Group__c = voIdToVOLIGToUpsertMap.get(voLineItem.Vendor_Order_Header__c).Id;
                    vogIdUpdateSet.add(voLineItem.Vendor_Order_Line_Item_Group__c);
                }
            }
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItemList);
            DMLUtility.deleteSobjectList('Vendor_Order_Line_Item_Group__c', voligDeleteMap.values());

            if(!vogIdUpdateSet.isEmpty()) {
                List<Vendor_Order_Line_Item_Group__c> voligUpdateList = new List<Vendor_Order_Line_Item_Group__c>();
                for(AggregateResult aggResult : [Select Vendor_Order_Line_Item_Group__c VOLIGId, SUM(Qty_Needed__c) NeededQty FROM Vendor_Order_Line_Item__c WHERE Vendor_Order_Line_Item_Group__c IN :vogIdUpdateSet Group By Vendor_Order_Line_Item_Group__c]) {
                    voligUpdateList.add(new Vendor_Order_Line_Item_Group__c(
                        Id = String.valueOf(aggResult.get('VOLIGId')),
                        Need__c = aggResult.get('NeededQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('NeededQty'))) : 0
                    ));
                }
                DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voligUpdateList);
            }
        }
    }

    public static void updateStockExcessOnVO(Set<String> voHeaderIdSet, List<Part__c> supersedeToPartList) {
        Map<Id, Part__c> partIdToPartRecMap = new Map<Id, Part__c>{supersedeToPartList[0].Id => supersedeToPartList[0]};
        Set<Id> newInsertedVOLineItemIdSet = new Set<Id>();
        List<Vendor_Order_Line_Item__c> voliListToDelete = new List<Vendor_Order_Line_Item__c>();
        List<Vendor_Order_Line_Item__c> voLineItemList = [SELECT Id, Part__r.Qty_On_Order__c, Is_Excess__c, Qty_Needed__c, Needed_For__c, Vendor_Order_Line_Item_Group__r.Part__c, Vendor_Order_Line_Item_Group__r.Need__c, Vendor_Order_Line_Item_Group__r.Cost__c, CO_Line_Item__r.Id, CO_Line_Item__r.Part__c FROM Vendor_Order_Line_Item__c 
																WHERE Vendor_Order_Header__c IN :voHeaderIdSet AND Part__c = :supersedeToPartList[0].Id];
        
	    for(Vendor_Order_Line_Item__c voliRec : voLineItemList) {
            if(voliRec.Is_Excess__c){
                voliListToDelete.add(voliRec);
            } else {
                newInsertedVOLineItemIdSet.add(voliRec.Id);
            }
	    }
        DMLUtility.deleteSobjectList('Vendor_Order_Line_Item__c', voliListToDelete);
        VendorOrderCtrl.updateStockExcessOnVO((new list<string>(voHeaderIdSet))[0], partIdToPartRecMap, null, newInsertedVOLineItemIdSet);
    }

	public static SupersededPartService.PartModal getPartToSupersededPart(String partId) {
		if(isPartAlreadyHavePartsAlternate(partId)) {
            Part__c supersededPart = SupersededPartService.getSupersededPart(partId);
            if(supersededPart != null) {
                return new SupersededPartService.PartModal(supersededPart);
            }
        }
        return null;
	}

    public static ResponseWrapper validateSupersededVOPart(String partId, String supersededPartId) {
        List<Part_Alternates__c> partAlternateList = [SELECT Id, Alternate_Part_ID__r.Part_Number__c FROM Part_Alternates__c WHERE Part_ID__c = :supersededPartId AND Relation__c = 'Replaced By' LIMIT 1];
        if(partAlternateList.size() > 0) {
            return new ResponseWrapper(202, 'Selected part has already been superseded to ' + partAlternateList[0].Alternate_Part_ID__r.Part_Number__c + '.');
        } else {
            Set<Id> partIdSet = new Set<Id>{partId, supersededPartId};
            List<Part__c> partList = [SELECT Id, Non_Inventory_Part__c, Packaged_Part__c FROM Part__c WHERE Id IN :partIdSet];
            if(partList.size() > 1) {
                if(partList[0].Packaged_Part__c != partList[1].Packaged_Part__c) {
                    return new ResponseWrapper(202, 'Parts have different package types, cannot be supercede.');
                } else if((partList[0].Id == supersededPartId && partList[0].Non_Inventory_Part__c) || partList[1].Non_Inventory_Part__c) {
                    return new ResponseWrapper(202, 'Part cannot be supercede with a non-inventory part.');
                }
            }
            return new ResponseWrapper(201, 'Success');
        }
    }

    public static String saveCustomVOExport(String customVOExportJSON){
        GenericExportWrapper customVOExportObj = (GenericExportWrapper)System.JSON.deserialize(customVOExportJSON, GenericExportWrapper.class);
        customVOExportObj.ObjectAPIName = 'Vendor_Order_Line_Item_Group__c';
        customVOExportObj.OrderByClause = 'Part__r.Part_Number__c';
        customVOExportObj.ExportType = 'VO';
        GE_File_Config__c customVOExportRec = GenericExportService.upsertGenericExportFormat(customVOExportObj);

		if(customVOExportRec.Vendor__c == null) throw new BlackPurlException('Invalid vendor Id');
        CustomerTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Account', new Account(Id = customVOExportRec.Vendor__c, Default_Export_Format__c = customVOExportRec.Id));
        CustomerTriggerHelper.isForceStopTrigger = false;
        return customVOExportRec.Id;
	}

    public static String getVOExportByVendorId(String vendorId) {
        List<GE_File_Config__c> fileConfigList = GenericExportUtil.getFileConfigUsingFilter(new Map<String, Object>{'Vendor__c' => vendorId}, true);
        if(fileConfigList.size() == 0) return '{}';
        return System.JSON.serialize(new GenericExportWrapper(fileConfigList[0]));
	}

    public static String saveDefaultVOExportFormat(String vendorId, String exportFormatId) {
        CustomerTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Account', new Account(Id = vendorId, Default_Export_Format__c = exportFormatId));
        CustomerTriggerHelper.isForceStopTrigger = false;
        return 'Success';
    }
    
    public static String getActiveVOCountByVendorId(String vendorId) {
    	String query = 'SELECT Count(Id) VOCount FROM Vendor_Order_Header__c WHERE Vendor__c = \''+ BPUtility.escapeSingleQuotes(vendorId) + '\' AND Status__c IN (\'Open\', \'Locked\')';
    	List<AggregateResult> aggList = SOQLUtility.getQueryResults('Vendor_Order_Header__c', query);
    	return String.valueOf((aggList.size() > 0) ? (Integer) aggList[0].get('VOCount') : 0);
    }

    public static GlobalSearchResultsWrapper getActiveVendorOrdersByVendorId(String filterJson) {
        GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj = (GlobalSearchResultsWrapper.COOpenOrderFilterJSON) System.JSON.deserialize(filterJson, 
                                                                        GlobalSearchResultsWrapper.COOpenOrderFilterJSON.class);
        
        String query = 'SELECT Name, Vendor__r.Name, Purchase_Order_Type__r.Code__c, Total__c, LastModifiedDate, Last_Modified_Date__c, Ordered_Date__c, Status__c FROM Vendor_Order_Header__c WHERE Vendor__c = \'' + BPUtility.escapeSingleQuotes(filterObj.VendorId) + 
            			'\' AND Status__c IN (\'Open\', \'Locked\') ORDER BY Name Desc ' + 
            			SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);

        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Order_Header__c> voHeaderList = Database.query(query);
        return new GlobalSearchResultsWrapper(voHeaderList.size(), voHeaderList);
    }

    global static void removeGroupFromOrder(String voLineItemGroupId, String voHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = [select Id, (select Vendor_Order_Header__c, Is_From_Search__c, Is_Excess__c from Vendor_Order_Line_Items__r), (select Vendor_Order_Header__c, Is_From_Search__c, Is_Excess__c from Cancelled_VOLIs__r)  from Vendor_Order_Line_Item_Group__c where Id = :voLineItemGroupId];
        List<Vendor_Order_Line_Item__c> voliListToUpdate = new List<Vendor_Order_Line_Item__c>();
        
        if(voliGroupList.size() > 0) {
            List<sObject> lineItemsToDel = new List<sObject>();
            for(Vendor_Order_Line_Item__c voliRec : voliGroupList[0].Vendor_Order_Line_Items__r) {
                if(voliRec.Is_From_Search__c || voliRec.Is_Excess__c){
                    lineItemsToDel.add(voliRec);
                } else {
                    voliRec.Vendor_Order_Header__c = null;
                    voliListToUpdate.add(voliRec);
                }
            }
            if(voliListToUpdate.size() > 0) {
                DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voliListToUpdate);
            }
            
            List<Vendor_Order_Line_Item__c> voliList = new List<Vendor_Order_Line_Item__c>();
            
            List<Vendor_Order_Line_Item_Group__c> voliGroupListToUpdate = SOQLUtil.getVOLIGroupByFieldName('Id', voLineItemGroupId, voHeaderId);
            for(Vendor_Order_Line_Item_Group__c VogRec : voliGroupListToUpdate ){
                voliList.addall(VogRec.Vendor_Order_Line_Items__r);
            }
            
            if(lineItemsToDel.size() > 0) {
                if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                VendorOrderLineItemTriggerHelper.shouldTriggerRun = false;
                delete lineItemsToDel;
            }
            
            if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete voliGroupList[0];
            
            VendorOrderCtrl.updatePartOrderedQtyInCaseOfRemovingOfGroup(voliList, voHeaderId);
        }
    }

    public static String createVR(String vendorId, String voHeaderId) {
        Vendor_Receiving_Header__c vrHeader = new Vendor_Receiving_Header__c();
        if(String.isNotBlank(vendorId) && String.isNotBlank(voHeaderId)) {
            vrHeader.Vendor__c = vendorId;
            vrHeader.Status__c = 'In Progress';
            DMLUtility.insertSobjectList('Vendor_Receiving_Header__c', vrHeader);
            
            In_Progress_VR__c ipvrRec = new In_Progress_VR__c();
            ipvrRec.Vendor_Receiving_Header__c = vrHeader.Id;
            ipvrRec.Vendor_Order_Header__c = voHeaderId;
            DMLUtility.insertSobjectList('In_Progress_VR__c', ipvrRec);
            
            Map<String, Vendor_Order_Line_Item_Group__c> voligMap = new Map<String, Vendor_Order_Line_Item_Group__c>(
                VendorOrderReceivingSOQLUtil.getVROutstandingItemsByFilters(vrHeader.Id, null));
            VendorOrderReceivingCtrl.groupSelectedLineItems(BPUtility.getEncodedString(vrHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(new List<String>(voligMap.keySet()))), null, null, null);
        }
        return vrHeader.Id;
    }

    public static void updateVOLIG(String payload) {
        if(payload != null) {
            VendorOrderLineItemGroup voligObj = (VendorOrderLineItemGroup) System.JSON.deserialize(payload, VendorOrderLineItemGroup.class);
            if(String.isNotBlank(voligObj.Id) && voligObj.Cost != null) {
                Vendor_Order_Line_Item_Group__c voligRec = new Vendor_Order_Line_Item_Group__c(Id = voligObj.Id, Per_Unit_Cost__c = voligObj.Cost);
                DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voligRec);

                if(String.isNotBlank(voligObj.SubletId)) {
                    List<Service_Order_Line_Item__c> soliUpdateList = new List<Service_Order_Line_Item__c>();
                    for(Vendor_Order_Line_Item__c voli : [Select Id, Service_Order_Line_Item__c FROM Vendor_Order_Line_Item__c WHERE Vendor_Order_Line_Item_Group__c =: voligObj.Id]) {
                        soliUpdateList.add(new Service_Order_Line_Item__c(Id = voli.Service_Order_Line_Item__c, Cost__c = voligObj.Cost));
                    }
                    ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
                    DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliUpdateList);
                    ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
                }
            }
        }
    }
}
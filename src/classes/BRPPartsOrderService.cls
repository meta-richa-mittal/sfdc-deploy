/**
 * Author: Richa Mittal
 * Since: March 25, 2021
 * Name: BRPPartsOrderService
 * Description: Service class for BRP parts order xml creation
**/
public without sharing class BRPPartsOrderService {
	public static String methodType = 'ProcessPartsOrder';
	public static String orderActionCode = 'Validate';
	private static BRP_Dealers__c brpDealerDetailRec = BRPUtility.getBRPDealerDetail();
	
	public static void processPartsOrderRequest(String voHeaderId) {
		List<Vendor_Order_Header__c> voHeaderList = [select Id, Name, Expected_Date_Formula__c, (SELECT Id, Need__c, 
    		Part__r.Part_Number__c FROM Vendor_Order_Line_Item_Groups__r WHERE Part__c != null) 
    		FROM Vendor_Order_Header__c WHERE Id =:voHeaderId];
    	
    	if(voHeaderList.size() > 0 && voHeaderList[0].Vendor_Order_Line_Item_Groups__r.size() > 0) {
    		String requestBody = createRequestBody(voHeaderList[0]);
    		HttpResponse response = BRPUtility.syncToBRP('BRPPartsOrder', requestBody);
    		system.debug('validateBRPPartsOrder*******');
    		system.debug(requestBody);
    		system.debug(response.getBody());
    		system.debug(response.getStatusCode());
    	}
	}
	
	public static String createRequestBody(Vendor_Order_Header__c voHeaderRec) {
		BRPUtility.release = '5.11.4';
		return createXMLPayload(voHeaderRec);
	}
	
	private static String createXMLPayload(Vendor_Order_Header__c voHeaderRec) {
    	DOM.Document doc = new DOM.Document();
    	dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, methodType);
    	createProcessPartsOrderDataAreaNode(root, voHeaderRec);
        return doc.toXmlString();
    }
    
    private static void createProcessPartsOrderDataAreaNode(dom.XmlNode root, Vendor_Order_Header__c voHeaderRec) {
    	dom.XmlNode partsOrderDataArea = BRPUtility.addChildElement(root, 'ProcessPartsOrderDataArea');
        BRPUtility.addChildElement(partsOrderDataArea, 'Process');
        dom.XmlNode partsOrderNode = BRPUtility.addChildElement(partsOrderDataArea, 'PartsOrder');
        createPartsOrderHeaderNode(partsOrderNode, voHeaderRec);
    }
    
    private static void createPartsOrderHeaderNode(dom.XmlNode partsOrderNode, Vendor_Order_Header__c voHeaderRec) {
    	dom.XmlNode partsOrderHeaderNode = BRPUtility.addChildElement(partsOrderNode, 'PartsOrderHeader');
    	dom.XmlNode documentIdentificationGroupNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'DocumentIdentificationGroup');
        dom.XmlNode documentIdentificationNode = BRPUtility.addChildElement(documentIdentificationGroupNode, 'DocumentIdentification');

        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'DocumentID', MethodType);
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'AgencyRoleCode', 'Dealer');

        String orderTypeCode = 'STK';
        String shipmentCarrierServiceLevelCode = '1 Day';
        String shipmentCarrierDeliveryCode;
        if(brpDealerDetailRec != null && brpDealerDetailRec.Care_Of__c != null) {
        	List<String> careOfStrList = brpDealerDetailRec.Care_Of__c.split(BRPUtility.careOfFieldDelimiter);
        	
        	orderTypeCode = careOfStrList.size() > 0 ? careOfStrList[0] : orderTypeCode;
        	shipmentCarrierServiceLevelCode = careOfStrList.size() > 2 ? careOfStrList[2] : shipmentCarrierServiceLevelCode;
        	
        	if(careOfStrList.size() > 4 && String.isNotBlank(careOfStrList[4])) {
        		shipmentCarrierDeliveryCode = careOfStrList[4];
        	}
        }
        
        BRPUtility.addChildElementWithValue(partsOrderHeaderNode, 'OrderTypeCode', orderTypeCode);
        
        if(brpDealerDetailRec != null && brpDealerDetailRec.Address_ID__c != null) {
        	dom.XmlNode shipToPartyNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'ShipToParty');
        	BRPUtility.addChildElementWithValue(shipToPartyNode, 'PartyID', brpDealerDetailRec.Address_ID__c);
        }
        
        BRPUtility.addChildElementWithValue(partsOrderHeaderNode, 'OrderActionCode', orderActionCode);
        if(voHeaderRec.Expected_Date_Formula__c != null) {
        	Date expectedDate = voHeaderRec.Expected_Date_Formula__c;
        	BRPUtility.addChildElementWithValue(partsOrderHeaderNode, 'RequestedShipDate', 
        			DateTime.newInstance(expectedDate.year(), expectedDate.month(), expectedDate.day()).format('yyyy-MM-dd'));
        }
        dom.XmlNode shipmentCarrierDetailNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'ShipmentCarrierDetail');
        BRPUtility.addChildElementWithValue(shipmentCarrierDetailNode, 'ShipmentCarrierServiceLevelCode', shipmentCarrierServiceLevelCode);
        
        if(shipmentCarrierDeliveryCode != null) {
        	BRPUtility.addChildElementWithValue(shipmentCarrierDetailNode, 'ShipmentCarrierDeliveryCode', shipmentCarrierDeliveryCode);
        }

		dom.XmlNode documentReferenceIdentificationGroupNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'DocumentReferenceIdentificationGroup');
		dom.XmlNode documentRefIdentificationNode = BRPUtility.addChildElement(documentReferenceIdentificationGroupNode, 'DocumentIdentification');
        
		// This is for Update Order
		if(orderActionCode.equalsIgnoreCase('Update')) {
			BRPUtility.addChildElementWithValue(documentRefIdentificationNode, 'DocumentID', GuidUtil.generateGuid());
        	BRPUtility.addChildElementWithValue(documentRefIdentificationNode, 'AgencyRoleCode', 'OEM Order Number');
		} else {
			BRPUtility.addChildElementWithValue(documentRefIdentificationNode, 'DocumentID', voHeaderRec.Name); // EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 32)
        	BRPUtility.addChildElementWithValue(documentRefIdentificationNode, 'AgencyRoleCode', 'Customer Purchase Order Number');
		}

        dom.XmlNode freeFormTextGroupNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'FreeFormTextGroup');
        BRPUtility.addChildElementWithValue(freeFormTextGroupNode, 'Note', 'Simple Text Delivery Order');
        BRPUtility.addChildElementWithValue(freeFormTextGroupNode, 'Description', 'Shipping Instruction');
        
        for(Vendor_Order_Line_Item_Group__c voligRec: voHeaderRec.Vendor_Order_Line_Item_Groups__r) {
        	createPartsOrderLineNode(partsOrderNode, voligRec);
        }
    }
    
    private static void createPartsOrderLineNode(dom.XmlNode partsOrderNode, Vendor_Order_Line_Item_Group__c voligRec) {
    	Decimal qtyNeeded = voligRec.Need__c != null ? voligRec.Need__c : 1;
    	dom.XmlNode partsOrderLineNode = BRPUtility.addChildElement(partsOrderNode, 'PartsOrderLine');
    	BRPUtility.addChildElementWithValue(partsOrderLineNode, 'LineNumberString', GuidUtil.generateGuid());
    	BRPUtility.addChildElementWithAttribute(partsOrderLineNode, 'OrderQuantity', BRPUtility.prependZerosToString(String.valueOf(qtyNeeded), 3), 'unitCode', 'ea');
    	dom.XmlNode itemIdentificationGroupNode = BRPUtility.addChildElement(partsOrderLineNode, 'ItemIdentificationGroup');
    	dom.XmlNode itemIdentificationManufacNode = BRPUtility.addChildElement(itemIdentificationGroupNode, 'ItemIdentification');
    	BRPUtility.addChildElementWithValue(itemIdentificationManufacNode, 'ItemID', voligRec.Part__r.Part_Number__c);
    	BRPUtility.addChildElementWithValue(itemIdentificationManufacNode, 'AgencyRoleCode', 'Manufacturer'); // 'Manufacturer' should be from parts master
    	
    	// Added for test case BRPI-01-SPO-06
    	/*dom.XmlNode itemIdentificationDealerNode = BRPUtility.addChildElement(itemIdentificationGroupNode, 'ItemIdentification');
    	BRPUtility.addChildElementWithValue(itemIdentificationDealerNode, 'ItemID', voligRec.Part__r.Part_Number__c);
    	BRPUtility.addChildElementWithValue(itemIdentificationDealerNode, 'AgencyRoleCode', 'Dealer');*/
    }
    
    public static Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> handleValidatePartsOrderResponse(String requestBody, String responseBody, String orderActionCode) {
    	Map<String, String> lineNumberStrToPartNumberMap;
    	if(responseBody.contains('AcknowledgePartsOrder')) {
    		// Map for LineNumberString(UUID) to BP Part Number created from req body as LineNumberString is returned in every response body with status 200
    		lineNumberStrToPartNumberMap = getLineNumberStrToPartNumberMapFromReqBody(requestBody);
    	} else if(responseBody.contains('ConfirmBOD')) {
    		// if there is some error then handling of list of errors if present (deserialize nodes as array not used as BRPResponseWrapper handles it this way)
    		responseBody = BRPUtility.getUpdatedResBodyIfMultipleErrors(responseBody);
    	}
    	
    	// deserialize response body to response wrapper with set of nodes that may present multiple time except ErrorProcessMessage
    	
    	BRPResponseWrapper responseObj = BRPUtility.parseXMLResponse(responseBody, new Set<String>{'PartsOrderLine', 'AcknowledgementStatus', 'LineSplitPartsOrderLine', 'ItemIdentification'});
    	Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeErrorListMap = new Map<String, List<BRPPartsOrderingDTO.ErrorMessage>>();
    	
    	if(responseBody.contains('AcknowledgePartsOrder')) {
    		errorTypeErrorListMap = createErrorMapFromAckResponse(responseObj, lineNumberStrToPartNumberMap, orderActionCode);
    	} else if(responseBody.contains('ConfirmBOD')) {
    		errorTypeErrorListMap = createErrorMapFromConfirmBODResponse(responseObj);
    	} else {
    		throw new BlackPurlException('Some error occurred while parsing BRP response');
    	}
    	
    	return errorTypeErrorListMap;
    }
    
    private static Map<String, String> getLineNumberStrToPartNumberMapFromReqBody(String requestBody) {
    	requestBody = requestBody.substringBefore('<star:ApplicationArea>') + requestBody.substringAfter('</star:ApplicationArea>');
    	BRPPartsOrderingDTO reqObj = 
    			(BRPPartsOrderingDTO)new XMLSerializer().deSerialize(requestBody, BRPPartsOrderingDTO.class, new Set<String>{'PartsOrderLine', 'ItemIdentification'});
    	
    	Map<String, String> lineNumberStrToPartNumberMap = new Map<String, String>();
    	if(reqObj != null && reqObj.ProcessPartsOrder != null && reqObj.ProcessPartsOrder.ProcessPartsOrderDataArea != null && 
    		reqObj.ProcessPartsOrder.ProcessPartsOrderDataArea.PartsOrder != null && reqObj.ProcessPartsOrder.ProcessPartsOrderDataArea.PartsOrder.PartsOrderLine != null) {
    			List<BRPPartsOrderingDTO.PartsOrderLine> reqPartsOrderList = reqObj.ProcessPartsOrder.ProcessPartsOrderDataArea.PartsOrder.PartsOrderLine;
    			for(BRPPartsOrderingDTO.PartsOrderLine reqPartLineObj: reqPartsOrderList) {
    				if(reqPartLineObj.LineNumberString != null && reqPartLineObj != null && reqPartLineObj.ItemIdentificationGroup != null && 
    					reqPartLineObj.ItemIdentificationGroup.ItemIdentification != null) {
						if(reqPartLineObj.ItemIdentificationGroup.ItemIdentification.size() == 1) {
							lineNumberStrToPartNumberMap.put(reqPartLineObj.LineNumberString, reqPartLineObj.ItemIdentificationGroup.ItemIdentification[0].ItemID);
						} else {
							for(BRPPartsOrderingDTO.ItemIdentification itemIdentificationObj: reqPartLineObj.ItemIdentificationGroup.ItemIdentification) {
	    						if(itemIdentificationObj.ItemID != null && itemIdentificationObj.AgencyRoleCode == 'Manufacturer') {
									lineNumberStrToPartNumberMap.put(reqPartLineObj.LineNumberString, itemIdentificationObj.ItemID);
									break;
								}
							}
						}
					}
				}
			}
    	return lineNumberStrToPartNumberMap;
    }
    
    private static Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> createErrorMapFromAckResponse(BRPResponseWrapper responseObj, Map<String, String> lineNumberStrToPartNumberMap, 
    																						String orderActionCode) {
    	Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeErrorListMap = new Map<String, List<BRPPartsOrderingDTO.ErrorMessage>>();
    	if(responseObj.AcknowledgePartsOrder != null && responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea != null && 
			responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea.PartsOrder != null) {
			// handling of any error present in header node
			if(responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea.PartsOrder.PartsOrderHeader != null) {
				BRPPartsOrderingDTO.PartsOrderHeader partsOrderHeaderObj = responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea.PartsOrder.PartsOrderHeader;
				createErrorMsgJson(errorTypeErrorListMap, partsOrderHeaderObj.AcknowledgementStatus, null, orderActionCode);
			}
			
			// handling of any error present in parts line item node
			if(responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea.PartsOrder.PartsOrderLine != null) {
				List<BRPPartsOrderingDTO.PartsOrderLine> partsOrderList = 
								responseObj.AcknowledgePartsOrder.AcknowledgePartsOrderDataArea.PartsOrder.PartsOrderLine;
				for(BRPPartsOrderingDTO.PartsOrderLine partsOrderRec: partsOrderList) {
					if(partsOrderRec != null) {
						String partNumber = lineNumberStrToPartNumberMap != null && partsOrderRec.LineNumberString != null ? 
										lineNumberStrToPartNumberMap.get(partsOrderRec.LineNumberString) : null;
						createErrorMsgJson(errorTypeErrorListMap, partsOrderRec.AcknowledgementStatus, partNumber, orderActionCode);
					
						if(partsOrderRec.LineSplitPartsOrderLine != null) {
							for(BRPPartsOrderingDTO.LineSplitPartsOrderLine splitPartsOrderRec: partsOrderRec.LineSplitPartsOrderLine) {
								createErrorMsgJson(errorTypeErrorListMap, splitPartsOrderRec.AcknowledgementStatus, partNumber, orderActionCode);
							}
						}
					}
				}
			}
		}
		return errorTypeErrorListMap;
    }
    
    private static Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> createErrorMapFromConfirmBODResponse(BRPResponseWrapper responseObj) {
    	Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeErrorListMap = new Map<String, List<BRPPartsOrderingDTO.ErrorMessage>>();
    	
    	if(responseObj.ConfirmBOD != null && responseObj.confirmBOD.ConfirmBODDataArea != null && responseObj.confirmBOD.ConfirmBODDataArea.BOD != null 
    				&& responseObj.confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage != null) {
    		errorTypeErrorListMap.put('Error', new List<BRPPartsOrderingDTO.ErrorMessage>());
			if(responseObj.confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessage != null) {
				BRPResponseWrapper.ErrorProcessMessage errorMsg = responseObj.confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessage;
				errorTypeErrorListMap.get('Error').add(new BRPPartsOrderingDTO.ErrorMessage(null, errorMsg.Type, errorMsg.Description, 'Error'));
			} else if(responseObj.confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessageList != null) {
				List<BRPResponseWrapper.ErrorProcessMessage> errorMsgList = responseObj.confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessageList;
				for(BRPResponseWrapper.ErrorProcessMessage errorMsg: errorMsgList) {
					errorTypeErrorListMap.get('Error').add(new BRPPartsOrderingDTO.ErrorMessage(null, errorMsg.Type, errorMsg.Description, 'Error'));
				}
			}
    	}
    	return errorTypeErrorListMap;
    }
    
    private static void createErrorMsgJson(Map<String, List<BRPPartsOrderingDTO.ErrorMessage>> errorTypeErrorListMap, 
    																	List<BRPPartsOrderingDTO.AcknowledgementStatus> ackStatusObjList, 
    																	String partNumber, String orderActionCode) {
    	if(ackStatusObjList != null) {
    		for(BRPPartsOrderingDTO.AcknowledgementStatus ackStatusObj: ackStatusObjList) {
				if(ackStatusObj.StatusTypeCode == 'Error' || (orderActionCode == 'Validate' && ackStatusObj.StatusTypeCode == 'Warning')  || 
				(orderActionCode == 'Create' && ackStatusObj.StatusTypeCode == 'Success')) {
					if(!errorTypeErrorListMap.containsKey(ackStatusObj.StatusTypeCode)) {
						errorTypeErrorListMap.put(ackStatusObj.StatusTypeCode, new List<BRPPartsOrderingDTO.ErrorMessage>());
					}
					errorTypeErrorListMap.get(ackStatusObj.StatusTypeCode).add(new BRPPartsOrderingDTO.ErrorMessage(partNumber, ackStatusObj.StatusCode, 
																				ackStatusObj.StatusText, ackStatusObj.StatusTypeCode));
				}
			}
    	}
    }
}
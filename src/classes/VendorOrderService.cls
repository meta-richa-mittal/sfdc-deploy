/** 
 * Author: Richa Mittal
 * Since: June 14, 2021
 * Name: VendorOrderService 
 * Description: service class which contains all methods related to Vendor Order Ctrl.
**/
public without sharing class VendorOrderService {
    
    public static String processBRPPartsOrder(String voHeaderId, String vendorId, String orderActionCode) {
    	HttpResponse response = new HttpResponse();
    	ResponseWrapper resObj;
        try {
            if(BRPUtility.isPartsMasterVendor(vendorId)) {
            	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            	List<Vendor_Order_Header__c> voHeaderList = [select Id, Name, Expected_Date_Formula__c, (SELECT Id, Need__c, 
													    		Part__r.Part_Number__c FROM Vendor_Order_Line_Item_Groups__r WHERE Part__c != null) 
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
}
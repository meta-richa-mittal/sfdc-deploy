/** 
* Author: Hitesh Gupta
* Since: Nov 3, 2017 
* Name: UnitOrderingCtrl 
* Description: Apex class which contains all remoted methods related to Unit Ordering Page.
**/
global without sharing class UnitOrderingCtrl {
    global UnitOrderingCtrl (NewHomePageCtrl controller){}
    public UnitOrderingCtrl() {}
    
    @RemoteAction
    global static String getVendorsList() {
        List<UnitOrderingWrapper.VendorWrapper> vendorList = UnitOrderingService.getVendorsList();
        return BPUtility.getEncodedString(system.JSON.serialize(vendorList));
    }
    
    @RemoteAction
    global static String getUnitCategoryList() {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitOrderingService.getUnitCategoryList()));
    }
    
    @RemoteAction
    global static String getVendorDetails(String vendorId){
        vendorId = BPUtility.getDecodedString(vendorId);
        UnitOrderingWrapper.VendorWrapper vendorObj = UnitOrderingService.getVendorDetailsById(vendorId);
        return BPUtility.getEncodedString(system.JSON.serialize(vendorObj));
        
    }
    
    @RemoteAction
    global static String SetUnitPurchaseFlagForVendor(String vendorId){
        vendorId = BPUtility.getDecodedString(vendorId);
        UnitOrderingService.SetUnitPurchaseFlagForVendor(vendorId);
        return getVendorsList();
    }
    
    @RemoteAction
    global static String getActiveOrderList(String vendorId){
        vendorId = BPUtility.getDecodedString(vendorId);
        List<UnitOrderingWrapper.UnitOrderWrapper> unitList = UnitOrderingService.getActiveOrderList(vendorId);
        return BPUtility.getEncodedString(system.JSON.serialize(unitList));
    }
    
    @RemoteAction
    global static String applySortingOnActiveOrderList(String vendorId, String jSONString){
        vendorId = BPUtility.getDecodedString(vendorId);
        jSONString = BPUtility.getDecodedString(jSONString);
        
        List<UnitOrderingWrapper.UnitOrderWrapper> unitList = UnitOrderingService.getActiveOrderList(vendorId, jSONString);
        return BPUtility.getEncodedString(system.JSON.serialize(unitList));
    }
    
    @RemoteAction
    global static String removeOrderUnit(String unitId, String vendorId){
        unitId = BPUtility.getDecodedString(unitId);
        UnitOrderingService.cancelOrderedUnit(unitId);
        return getActiveOrderList(vendorId); 
    }
    
    @RemoteAction
    global static String getOrderHistoryList(String filterJson){
        filterJson = BPUtility.getDecodedString(filterJson);
        List<UnitOrderingWrapper.UnitOrderWrapper> unitList = UnitOrderingService.getOrderHistoryList(filterJson, null);
        return BPUtility.getEncodedString(system.JSON.serialize(unitList));
    }
    
    @RemoteAction
    global static String applySortingOnOrderHistoryList(String filterJson, String jSONString){
        filterJson = BPUtility.getDecodedString(filterJson);
        jSONString = BPUtility.getDecodedString(jSONString);
        
        List<UnitOrderingWrapper.UnitOrderWrapper> unitList = UnitOrderingService.getOrderHistoryList(filterJson, jSONString);
        return BPUtility.getEncodedString(system.JSON.serialize(unitList));
    }
    
    @RemoteAction
    global static String getUnitDetails(String unitId){
        unitId = BPUtility.getDecodedString(unitId);
        List<UnitOrderingWrapper.UnitDetailsWrapper> couObjList = UnitOrderingService.getUnitDetails(unitId);
        return BPUtility.getEncodedString(system.JSON.serialize(couObjList));
    }
    
    
    @RemoteAction
    global static String saveUnitDetails(String jSONString) {
    	try {
	        jSONString = BPUtility.getDecodedString(jSONString);
	        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	        if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	        String unitId = UnitOrderingService.saveUnitDetails(jSONString);
	        if(unitId == 'Duplicate Stock Number') {
	            return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Duplicate Stock Number"}');   
	        } else if(unitId == 'Duplicate VIN Number') {
	            return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Duplicate VIN Number"}');   
	        } else {
	            return getUnitDetails(BPUtility.getEncodedString(unitId));
	        }
    	} catch(Exception e) {
    		throw new BlackPurlException(e.getMessage());
    	}
    }
    
    /**
    * Name: savePriceAndCost
    * Desc: Method to save unit price and cost in Database 
    * @param:(1) jSONString - String - Unit price and cost JSON string
    * @return: String - json result string
    **/
    @RemoteAction
    global static String savePriceAndCost(String unitId, String jSONString) {
        jSONString = BPUtility.getDecodedString(jSONString);
        UnitOrderingService.savePriceAndCost(BPUtility.getDecodedString(unitId), jSONString);
        return getUnitDetails(unitId);
    }
    
    @RemoteAction
    global static String validateUnitInvoiceNumberForQB(String jsonUnits) {
        jsonUnits = BPUtility.getDecodedString(jsonUnits);
        List<UnitOrderingWrapper.UnitOrderWrapper> orderedUnits = (List<UnitOrderingWrapper.UnitOrderWrapper>) System.JSON.deserialize(jsonUnits, List<UnitOrderingWrapper.UnitOrderWrapper>.class);
        String values = ' (';
        
        for(UnitOrderingWrapper.UnitOrderWrapper unit : orderedUnits) {
            values += ' \'' + unit.InvoiceNumber + '\', ' ;
        }
        
        values = values.substring(0, values.length()-2);
        values += ' )';
        
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
        if(integrationConfigList == null || integrationConfigList.isEmpty()) throw new BlackpurlException('QB config is not defind.');
        
        List<String> filterConditions = new List<String>{'DocNumber IN ' + values};
        try{
            QBQueryResponseWrapper.QBResponseWrapper qbResponse = QBCalloutManager.getDataAndUpdateRecords(IntegrationUtility.BILL, filterConditions, integrationConfigList[0]);  
            return BPUtility.getEncodedString(QBUtil.isInvoiceNumberDuplicate(IntegrationUtility.BILL, 'IN', qbResponse));
        } catch (Exception e) {
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Error while validating unit invoice number from QB. Please contact your administrator.')));
        }      
    }
    
    /**
     * Name: removeCOURecord
     * Desc: Remove Record with given Id
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String removePriceAndCost(String unitId, String recordId) {
        recordId = BPUtility.getDecodedString(recordId);
        UnitOrderingService.removePriceAndCost(recordId);
        return getUnitDetails(unitId);
    }
    
    @RemoteAction
    global static String saveUnitReceiving() {
        //TODO add implementation
        return 'SUCCESS'; 
    }
    
    /**
     * Name: saveUnitReceiving
     * Desc: Receive Ordered Units, and create Stock Units
     * @param: (1) jSONString - String - List of Units to be Received
     * @return: String 
    **/
    @RemoteAction
    global static String receiveUnit(String jSONString) {
        return UnitOrderingService.receiveUnits(BPUtility.getDecodedString(jSONString));
    }
    
    @RemoteAction
    global static String checkDuplicateVIN(String vin) {
        return BPUtility.getEncodedString(UnitOrderingService.checkDuplicateVIN(BPUtility.getDecodedString(vin)));
    }
	
	@RemoteAction 
    global static String getVehicleSpecification(String vin) {
    	try {
            return BPUtility.getEncodedString(BRPAPIManager.getVehicleSpecification(BPUtility.getDecodedString(vin)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @remoteAction
    global static String getBasePriceAndCostByMMSId(String makeId, String modelId, String subModelId) {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getBasePriceAndCostByMMSId(BPUtility.getDecodedString(makeId), BPUtility.getDecodedString(modelId), BPUtility.getDecodedString(subModelId))));
    }
    
    @remoteAction
    global static String getDefaultFactoryOptionsByUnitId(String unitId, String makeId, String modelId, String subModelId) {
    	return BPUtility.getEncodedString(UnitPricingService.getDefaultFactoryOptionsByRecId(BPUtility.getDecodedString(unitId), 
    											BPUtility.getDecodedString(makeId), BPUtility.getDecodedString(modelId), BPUtility.getDecodedString(subModelId)));
    }
	
	//To create bulk specified number of units that are replica of passed unitId
	@RemoteAction
    global static String createBulkUnits(String unitId, Integer numberOfUnits) {
        return BPUtility.getEncodedString(
            system.JSON.serialize(
                UnitOrderingService.createBulkUnits(BPUtility.getDecodedString(unitId), numberOfUnits)
            )
        );
    }
    /**
     * Name: getAllPurchaseTaxList
     * Desc: Method to get all active purchase tax list 
     * @param: Vendor purchase tax id as default
     * @return: String 
    **/
    @RemoteAction
    global static String getAllPurchaseTaxList(String vendorPurchaseTaxId) {
        return BPUtility.getEncodedString(UnitOrderingService.getAllPurchaseTaxList(BPUtility.getDecodedString(vendorPurchaseTaxId)));
    }

    /**
     * Name: setUnitsPurchaseTax
     * Desc: Set purchase tax on ordered units while receiving units
     * @param: (1) jSONString -Set of ordered units id set (2) Purchase tax id to which to be set
     * @return: String - Json of receiving units
    **/
    @RemoteAction
    global static String setUnitsPurchaseTax(String unitIdSetJson, String purchaseTaxId) {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitOrderingService.setUnitsPurchaseTax((Set<String>) JSON.deserialize(BPUtility.getDecodedString(unitIdSetJson), Set<String>.class), BPUtility.getDecodedString(purchaseTaxId))));
    }
    
    /**
     * Name: getRequiredUnitListForOrder
     * Desc: get required status ordered units
     * @param: 
     * @return: String - List of unit Wrapper
    **/
    @RemoteAction
    global static String getRequiredUnitListForOrder() {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitOrderingService.getRequiredUnitListForOrder()));
    }

    /**
     * Name: removeOrderUnitExistOnCO
     * Desc: Change status of order unit from On Order to Required
     * @param: 
     * @return: String - Sucess/ Error
    **/
    @RemoteAction
    global static String removeOrderUnitExistOnCO(String unitId, String vendorId){
        UnitOrderingService.removeOrderUnitExistOnCO(BPUtility.getDecodedString(unitId));
        return getActiveOrderList(vendorId); 
    }

    @RemoteAction
    public static String getAllStampDutyList() {
        return BPUtility.getEncodedString(System.JSON.serialize(StampDutyService.getAllStampDutyList()));
    }

    @RemoteAction
    global static String getStampDutyCalcMethodPickListValues(){
        return BPUtility.getEncodedString(Utility.getPicklistValues('Stamp_duty_calculators__c.Calculation_method__c'));
    }
}
/**
 * Author: Reena Singh
 * Since: December 31, 2020
 * Name: UnitPricingCtrl
 * Description: Conroller class for Unit pricing page
**/
global without sharing class UnitPricingCtrl {
    global UnitPricingCtrl(NewHomePageCtrl controller) {}
    public UnitPricingCtrl(){}
    
    @remoteAction
    global static String getUnassignedUnitPricingMakeList() {
       return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getAllUnitMakes(false), true));
    }
    
    @remoteAction
    global static String enableUnitPricingOnMake(String makeId) {
        return BPUtility.getEncodedString(UnitPricingService.enableUnitPricingOnMake(BPUtility.getDecodedString(makeId)));
    }
    
    @remoteAction
    global static String getAssignedUnitPricingMakeList() {
       return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getAllUnitMakes(true), true));
    }
    
    @remoteAction
    global static String createFactoryOption(String factoryOptionJson) {
        return BPUtility.getEncodedString(UnitPricingService.createFactoryOption(BPUtility.getDecodedString(factoryOptionJson)));
    }
       
    @remoteAction
    global static String getMakePricingAndOptionsDetails(String makeId) {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getMakePricingAndOptionsDetails(BPUtility.getDecodedString(makeId)), true));
    }

    @remoteAction
    global static String getAllFactoryOptionsListByMakeId(String makeId) {
    	return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getAllFactoryOptionsListByMakeId(BPUtility.getDecodedString(makeId)), true));
    }

    @RemoteAction
    global static String deleteFactoryOption(String factoryOptionId) {
    	return BPUtility.getEncodedString(UnitPricingService.deleteFactoryOption(BPUtility.getDecodedString(factoryOptionId)));
    }

    @remoteAction
    global static String getModelPricingAndOptionsDetails(String filterJson) {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getModelPricingAndOptionsDetails(BPUtility.getDecodedString(filterJson)), true));
    }

    @remoteAction
    global static String saveSubModel(String subModelJson) {
        return  BPUtility.getEncodedString(UnitPricingService.saveSubModel(BPUtility.getDecodedString(subModelJson)));
    }
    
    @RemoteAction
    global static String deleteSubModelFactoryOption(String subModelFactoryOptionId) {
    	return  BPUtility.getEncodedString(UnitPricingService.deleteSubModelFactoryOption(BPUtility.getDecodedString(subModelFactoryOptionId)));
    }

    @remoteAction
    global static String getAllFactoryOptionsListByRecId(String recId) {
    	return BPUtility.getEncodedString(system.JSON.serialize(UnitPricingService.getAllFactoryOptionsListByRecId(BPUtility.getDecodedString(recId)), true));
    }

    @remoteAction
    global static String saveSubModelFactoryOption(String subModelFactoryOptionJson) {
        return BPUtility.getEncodedString(UnitPricingService.saveSubModelFactoryOption(BPUtility.getDecodedString(subModelFactoryOptionJson)));
    }

    @remoteAction
    global static String addSubModelFactoryOption(String subModelFactoryOptionJson, String recIdJson) {
        return BPUtility.getEncodedString(UnitPricingService.addSubModelFactoryOption(BPUtility.getDecodedString(subModelFactoryOptionJson), BPUtility.getDecodedString(recIdJson)));
    }
}
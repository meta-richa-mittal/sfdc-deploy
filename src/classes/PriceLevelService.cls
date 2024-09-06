/**
 * Author: Tarun Khandelwal
 * Since: Jan 08, 2019
 * Name: PriceLevelService
 * Description: Service class for Price Level
**/
public without sharing class PriceLevelService {
    
    /**
     * Name: getInternalDefaultPriceLevel
     * Desc: Method to get Default Price Level In system
     * @param: 
     * @return:  List<Price_Level__c> - List of default price level. Ideally size of list - 1 
    **/
    public static List<Price_Level__c> getInternalDefaultPriceLevel() {
        String defaultPriceLevelId_Internal = GeneralConfiguration.getDefaultPriceLevelOnInternalService();
        if(String.isNotBlank(defaultPriceLevelId_Internal)) {
            if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Price_Level__c> priceLevelList = [Select Part_Price_Base__c, Discount_Markup__c, Labour_Rate__c from Price_Level__c 
                                                        where Id =: defaultPriceLevelId_Internal];
            return priceLevelList;
        }
        return null;
    }
    
    public static Id getDefaultPriceLevelId() {
    	List<Price_Level__c> defaultPriceLevelList = getDefaultPriceLevel();
    	return (defaultPriceLevelList.size() > 0 ? defaultPriceLevelList[0].Id : null);
    }
    
    public static List<Price_Level__c> getDefaultPriceLevel() {
        if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Price_Level__c> defaultPriceLevel = [SELECT Part_Price_Base__c, Discount_Markup__c, Labour_Rate__c from Price_Level__c 
                                                    WHERE Default__c = true];
        return defaultPriceLevel;
    }
    
    public static List<PriceLevel> getAllPriceLevel() {
        List<Price_Level__c> priceLevelList = SOQLUtility.getAllPriceLevel();
		
		List<PriceLevel> plWrapperObjList = new List<PriceLevel>();
		for(Price_Level__c priceLevelRec : priceLevelList) {
			plWrapperObjList.add(new PriceLevel(priceLevelRec));
		}
        return plWrapperObjList;
    }
    
    public static void savePriceLevel(String priceLevelRecJson) {
    	if(AccessControl.ifObjectFieldIsCreateable('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            
    	PriceLevel plWrapperObj = (PriceLevel) System.JSON.deserialize(priceLevelRecJson, PriceLevel.class);
    	
		if(String.isNotBlank(plWrapperObj.PriceLevelName)) {
			Price_Level__c priceLevelRec = setPriceLevelFields(plWrapperObj);
			upsert priceLevelRec;
		} else {
			throw new BlackpurlException('Price level name cannot be blank');
		}
    }
    
    private static Price_Level__c setPriceLevelFields(PriceLevel plWrapperObj) {
    	Price_Level__c priceLevelRec = new Price_Level__c(Id = plWrapperObj.Id);
    	priceLevelRec.Name__c = plWrapperObj.PriceLevelName;
    	priceLevelRec.Default__c = plWrapperObj.IsDefault;
    	if(plWrapperObj.IsActive != null) {
    		priceLevelRec.Active__c = plWrapperObj.IsActive;
    	}
    	priceLevelRec.Description__c = plWrapperObj.Description;
    	priceLevelRec.Part_Price_Base__c = plWrapperObj.PartPriceBase;
    	priceLevelRec.Discount_Markup__c = plWrapperObj.Discount;
    	priceLevelRec.Labour_Rate__c = plWrapperObj.LabourRate;
    	return priceLevelRec;
    }
    
    public static void deletePriceLevelById(String priceLevelRecId) {
    	if(AccessControl.ifObjectIsDeletable('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    	delete new Price_Level__c(Id = priceLevelRecId);
    }

    public static Map<String, String> priceLevelFieldToPartFieldAPINameMap = new Map<String, String> {
        'Price' => 'Retail_Price__c',
        'MSRP' => 'MSRP__c',
        'Cost' => 'Last_Cost__c',
        'Average Cost' => 'Average_Cost__c'
    };
}
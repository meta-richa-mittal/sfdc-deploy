/**
 * Author: Reena Singh
 * Since: December 31, 2020
 * Name: UnitPricingService
 * Description: Service class for Unit pricing page
**/
public without sharing class UnitPricingService {
    
    public static List<UnitMakeWrapper> getAllUnitMakes(Boolean includeNonAddedPricing) {
        List<UnitMakeWrapper> makeList = new List<UnitMakeWrapper>();
        for(Unit_Make__c unitMakeRec : UnitPricingSOQLUtil.getAllUnitMakes(includeNonAddedPricing)) {
            makeList.add(new UnitMakeWrapper(unitMakeRec));
        }
        return makeList;
    }
    
    public static String enableUnitPricingOnMake(String makeId) { 
       if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Make__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }  
        if(String.isNotBlank(makeId)) {
            Unit_Make__c makeRec = new Unit_Make__c(Id = makeId);
            makeRec.Enable_Unit_Pricing__c = true;
            update makeRec;
        }
        return 'Success';
    }
    
    public static MakePricingAndOptionWrapper getMakePricingAndOptionsDetails(String makeId) {
    	List<Unit_Model__c> unitModelList = UnitPricingSOQLUtil.getActiveModelsByMakeId(makeId);
    	List<AggregateResult> aggregateResults = [Select Count(Id) Total from Factory_Option__c where Unit_Make__c =: makeId];
    	Integer totalFactoryOptions = aggregateResults.size() > 0 ? (Integer) aggregateResults[0].get('Total') : 0;
    	Unit_Make__c unitMake = new Unit_Make__c(Id = makeId);
    	if(unitModelList.size() == 0) {
    		unitMake = [Select Name from Unit_Make__c where Id =: makeId];
    	} else {
    		unitMake.Name = unitModelList[0].Unit_Make__r.Name;
    	}
        return new MakePricingAndOptionWrapper(unitMake, totalFactoryOptions, unitModelList);
    }
    
    public static String createFactoryOption(String factoryOptionJson) {
    	FactoryOptionWrapper factOptionObj = (FactoryOptionWrapper) System.JSON.deserialize(factoryOptionJson, FactoryOptionWrapper.class);
    	Factory_Option__c factOptionRec = FactoryOptionWrapper.getFactoryOptionRecFromObj(factOptionObj);
        upsert factOptionRec;
        return factOptionRec.Id;
    }

    public static List<FactoryOptionWrapper> getAllFactoryOptionsListByMakeId(String makeId) {
    	List<FactoryOptionWrapper> factoryOptionList = new List<FactoryOptionWrapper>();
        for(Factory_Option__c factoryOptionRec : UnitPricingSOQLUtil.getAllFactoryOptionsListByMakeId(makeId)) {
            factoryOptionList.add(new FactoryOptionWrapper(factoryOptionRec));
        }
        return factoryOptionList;
    }

    public static String deleteFactoryOption(String factoryOptionId) {
        if(AccessControl.ifObjectIsDeletable('Factory_Option__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete new Factory_Option__c(Id = factoryOptionId);
        return 'Success';
    }
    
    public static FactoryOptionModelWrapper getModelPricingAndOptionsDetails(String filterJson) {
        UnitSubmodelFilterWrapper filterObj = (UnitSubmodelFilterWrapper) System.JSON.deserialize(filterJson, UnitSubmodelFilterWrapper.class);
        List<Unit_Sub_Model__c> unitSubModelList = UnitPricingSOQLUtil.getActiveSubModelsByModelId(filterObj);
        List<Unit_Model__c> unitModelList = UnitPricingSOQLUtil.getActiveModelsByModelId(filterObj.ModelId);
        if(unitModelList.size() == 0){
            throw new BlackPurlException('No model exist with id ' + filterObj.ModelId);
        }
        return new FactoryOptionModelWrapper(unitModelList[0], unitSubModelList, (filterObj.StartIndex == null || filterObj.StartIndex == 0));
    }
   
    public static String saveSubModel(String subModelJson) {    
        UnitSubModelWrapper unitSubModelObj = (UnitSubModelWrapper) System.JSON.deserialize(subModelJson, UnitSubModelWrapper.class);   
        validateBaseUnitPriceAndCost(unitSubModelObj.Price, unitSubModelObj.Cost, false);
        if(unitSubModelObj.Holdback != null && unitSubModelObj.Holdback < 0 ) {
            throw new BlackPurlException('Holdback cannot be less than zero.');
        }
        Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c();
        String recordId; 
        if(String.isNotBlank(unitSubModelObj.Id) && ((Id)unitSubModelObj.Id).getSObjectType() == Schema.Unit_Sub_Model__c.SObjectType) {
            if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Sub_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            subModelRec.Id = unitSubModelObj.Id;
            subModelRec.Cost__c = unitSubModelObj.Cost;
            subModelRec.Holdback__c = unitSubModelObj.Holdback;
            subModelRec.Price__c = unitSubModelObj.Price;
            update subModelRec;
            recordId = subModelRec.Id;
        } else if(String.isNotBlank(unitSubModelObj.Id) && ((Id)unitSubModelObj.Id).getSObjectType() == Schema.Unit_Model__c.SObjectType) {
            Unit_Model__c modelRec = new Unit_Model__c();
            if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Model__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            modelRec.Id = unitSubModelObj.Id;
            modelRec.Default_Cost__c = unitSubModelObj.Cost;
            modelRec.Default_Holdback__c = unitSubModelObj.Holdback;
            modelRec.Default_Price__c = unitSubModelObj.Price;
            update modelRec;
            recordId = modelRec.Id;
        }
        return recordId;
     }

     public static String deleteSubModelFactoryOption(String subModelFactoryOptionId) {
        if(!AccessControl.ifObjectIsDeletable('Submodel_Factory_Option_Junction__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete new Submodel_Factory_Option_Junction__c(Id = subModelFactoryOptionId);
        return 'Success';
    }

    public static List<FactoryOptionWrapper> getAllFactoryOptionsListByRecId(String recId) {
    	List<FactoryOptionWrapper> factoryOptionList = new List<FactoryOptionWrapper>();
        for(Submodel_Factory_Option_Junction__c factoryOptionRec : UnitPricingSOQLUtil.getAllFactoryOptionsListByRecId(recId)) {
            factoryOptionList.add(new FactoryOptionWrapper(factoryOptionRec));
        }
        return factoryOptionList;
    }

    public static String saveSubModelFactoryOption(String subModelFactoryOptionJson) { 
         
        FactoryOptionWrapper subModelFactoryOptionObj = (FactoryOptionWrapper) System.JSON.deserialize(subModelFactoryOptionJson, FactoryOptionWrapper.class);
        validateBaseUnitPriceAndCost(subModelFactoryOptionObj.Price, subModelFactoryOptionObj.Cost, true);
        Submodel_Factory_Option_Junction__c subModelFOJRec = new Submodel_Factory_Option_Junction__c();
        if(!AccessControl.ifObjectFieldIsUpdateable('Submodel_Factory_Option_Junction__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(String.isNotBlank(subModelFactoryOptionObj.Id)) {
            subModelFOJRec.Id = subModelFactoryOptionObj.Id;
            subModelFOJRec.Cost__c = subModelFactoryOptionObj.Cost;
            subModelFOJRec.Price__c = subModelFactoryOptionObj.Price;
            update subModelFOJRec;
        }
        return subModelFOJRec.Id;
    }

    public static String addSubModelFactoryOption(String subModelFactoryOptionJson, String recIdJson) { 
        Set<String> recIdSet = (Set<String>) System.JSON.deserialize(recIdJson, Set<String>.class);
        recIdSet.remove(null);
        
        List<FactoryOptionWrapper> subModelFactoryOptionList = (List<FactoryOptionWrapper>) System.JSON.deserialize(subModelFactoryOptionJson, List<FactoryOptionWrapper>.class);  
        
        List<Submodel_Factory_Option_Junction__c> sofjList = [Select Id, Factory_Option__c, Unit_Sub_Model__c, Unit_Model__c from Submodel_Factory_Option_Junction__c where Unit_Sub_Model__c IN: recIdSet OR Unit_Model__c IN: recIdSet]; 
        Map<String, Set<String>> recIdToFactoryOptionIdSet =  new Map<String, Set<String>>();
        List<Submodel_Factory_Option_Junction__c> sofjListToInsert = new List<Submodel_Factory_Option_Junction__c>();
        for(Submodel_Factory_Option_Junction__c sofjRec : sofjList) {
            if(sofjRec.Unit_Model__c != null){
                if(!recIdToFactoryOptionIdSet.containsKey(sofjRec.Unit_Model__c)) {
                    recIdToFactoryOptionIdSet.put(sofjRec.Unit_Model__c, new Set<String>());
                }
                recIdToFactoryOptionIdSet.get(sofjRec.Unit_Model__c).add(sofjRec.Factory_Option__c);
            } else {
                if(!recIdToFactoryOptionIdSet.containsKey(sofjRec.Unit_Sub_Model__c)) {
                    recIdToFactoryOptionIdSet.put(sofjRec.Unit_Sub_Model__c, new Set<String>());
                }
                recIdToFactoryOptionIdSet.get(sofjRec.Unit_Sub_Model__c).add(sofjRec.Factory_Option__c);
            }
            
        }
        for(String recId : recIdSet) {
            for(FactoryOptionWrapper subModelFactoryOptionObj : subModelFactoryOptionList) {
                if(!recIdToFactoryOptionIdSet.containsKey(recId)) {
                    recIdToFactoryOptionIdSet.put(recId, new Set<String>());
                }
                if(!recIdToFactoryOptionIdSet.get(recId).contains(subModelFactoryOptionObj.FactoryOptionId)){
                    validateBaseUnitPriceAndCost(subModelFactoryOptionObj.Price, subModelFactoryOptionObj.Cost, true);
                    Submodel_Factory_Option_Junction__c subModelFOJRec = new Submodel_Factory_Option_Junction__c();
                    subModelFOJRec.Cost__c = subModelFactoryOptionObj.Cost;
                    subModelFOJRec.Price__c = subModelFactoryOptionObj.Price;
                    if(((Id)recId).getSObjectType() == Schema.Unit_Model__c.SObjectType){
                        subModelFOJRec.Unit_Model__c = recId;
                    } else {
                        subModelFOJRec.Unit_Sub_Model__c = recId;
                    }
                    subModelFOJRec.Factory_Option__c = subModelFactoryOptionObj.FactoryOptionId;
                    sofjListToInsert.add(subModelFOJRec);
                }
            }
        }
        if(sofjListToInsert.size() > 0){
            insert sofjListToInsert;
        }
        return 'Success';
    }

    public static void validateBaseUnitPriceAndCost(Decimal price, Decimal cost, Boolean isFactoryOption) { 
        if(price != null && price < 0) {
            throw new BlackPurlException((isFactoryOption ? 'Price' : 'Base unit price') + ' cannot be less than zero.');
        } else if(cost != null && cost < 0) {   
            throw new BlackPurlException('Cost cannot be less than zero.');
        } else if(price != null && cost != null && price < cost && !isFactoryOption) {   
            throw new BlackPurlException('Base unit price cannot be less than Cost.');
        }
    }

    public static String getDefaultFactoryOptionsByRecId(String recId, String makeId, String modelId, String subModelId) {
    	if(String.isBlank(recId)) throw new BlackPurlException('Unit Id can not be blank.');
    	if(String.isBlank(makeId)) throw new BlackPurlException('Make can not be blank.');
    	if(String.isBlank(modelId)) throw new BlackPurlException('Model can not be blank.');
    	if(!isUnitPricingEnabledForMake(makeId)) return '{"IsUnitPricingEnabledForMake" : false}';
    	
    	String sObjectType = ((Id)recId).getSObjectType().getDescribe().getName();
    	Set<String> alreadyAddedFOPTSet = getAlreadyAddedFOPTIdSet(sObjectType, recId);
    	
    	Map<String, FactoryOptionWrapper> factoryOptionIdToFOPTObjMap = new Map<String, FactoryOptionWrapper>();
    	for(Submodel_Factory_Option_Junction__c subModelFOPTJunRec: UnitPricingSOQLUtil.getAllModelAndSubModelFactoryOptionsList(modelId, subModelId, alreadyAddedFOPTSet)) {
    		if(subModelFOPTJunRec.Factory_Option__c != null) {
				alreadyAddedFOPTSet.add(subModelFOPTJunRec.Factory_Option__c);
				if(!factoryOptionIdToFOPTObjMap.containsKey(subModelFOPTJunRec.Factory_Option__c) || subModelFOPTJunRec.Unit_Sub_Model__c != null) {
					factoryOptionIdToFOPTObjMap.put(subModelFOPTJunRec.Factory_Option__c, new FactoryOptionWrapper(subModelFOPTJunRec));
				}
			}
    	}
    	
    	for(Factory_Option__c factoryOptionRec : UnitPricingSOQLUtil.getAllFactoryOptionsListByMakeId(makeId, alreadyAddedFOPTSet)) {
    		factoryOptionIdToFOPTObjMap.put(factoryOptionRec.Id, new FactoryOptionWrapper(factoryOptionRec));
        }
        
        String returnMessage = '';
        if(alreadyAddedFOPTSet.size() == 0 && factoryOptionIdToFOPTObjMap.size() == 0) returnMessage = 'Default factory options not defined';
        if(alreadyAddedFOPTSet.size() > 0 && factoryOptionIdToFOPTObjMap.size() == 0) returnMessage = 'All options have already been added';
        return '{"IsUnitPricingEnabledForMake" : true, "Message" : "' + returnMessage + '", "FactoryOptionsList" : ' + system.JSON.serialize(factoryOptionIdToFOPTObjMap.values(), true) + '}';
    }
    
    public static Boolean isUnitPricingEnabledForMake(String makeId) {
    	if(!AccessControl.ifObjectFieldIsAccessible('Unit_Make__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    	return [SELECT Enable_Unit_Pricing__c FROM Unit_Make__c WHERE Id =: makeId].Enable_Unit_Pricing__c;
    }
    
    private static Set<String> getAlreadyAddedFOPTIdSet(String sObjectType, String recId) {
    	List<SObject> sobjRecList = UnitPricingSOQLUtil.getAlreadyAddedFOPTList(sObjectType, recId);
    	Set<String> alreadyAddedFOPTSet = new Set<String>();
    	for(SObject sobjRec: sobjRecList) {
    		String facOptValue = ((sobjRec.get(Constants.NAMESPACE +'Factory_Option__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Factory_Option__c')) : null);
    		if(sobjRec.get(Constants.NAMESPACE +'Factory_Option__c') != null) {
				alreadyAddedFOPTSet.add(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Factory_Option__c')));
			}
    	} 
    	return alreadyAddedFOPTSet;
    }

    public static UnitPriceAndCostWrapper getBasePriceAndCostByMMSId(String makeId, String modelId, String subModelId) {
        if(String.isBlank(makeId) || !UnitPricingService.isUnitPricingEnabledForMake(makeId)) {
    		return new UnitPriceAndCostWrapper();
        }
        if(String.isNotBlank(subModelId)) {
            List<Unit_Sub_Model__c> unitSubModelList = UnitPricingSOQLUtil.getCostAndPriceBySubModelId(subModelId);
            return unitSubModelList.size() > 0 ? new UnitPriceAndCostWrapper(unitSubModelList[0]) : new UnitPriceAndCostWrapper();
        } else if(String.isNotBlank(modelId)) {
            List<Unit_Model__c> unitModelList = UnitPricingSOQLUtil.getCostAndPriceByModelId(modelId);
            return unitModelList.size() > 0 ? new UnitPriceAndCostWrapper(unitModelList[0]) : new UnitPriceAndCostWrapper();
        }
        return new UnitPriceAndCostWrapper();  
    }

    public class UnitMakeWrapper {
        public String Id;
        public String MakeName;
        public Integer ActiveModelsCount;
        
        public UnitMakeWrapper(Unit_Make__c unitMakeRec) {
            this.Id = unitMakeRec.Id;
            this.MakeName = unitMakeRec.Name;
            this.ActiveModelsCount = unitMakeRec.Unit_Models__r.size();
        }
    }

    public class UnitSubModelWrapper {
        public String Id;
        public Decimal Cost;
        public Decimal Price;
        public Decimal Holdback;
        public String UnitModelId;        
        
        public UnitSubModelWrapper(Unit_Sub_Model__c unitSubModelRec) {
            this.Id = unitSubModelRec.Id;
            this.Cost = unitSubModelRec.Cost__c != null ? unitSubModelRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Price = unitSubModelRec.Price__c != null ? unitSubModelRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Holdback = unitSubModelRec.Holdback__c != null ? unitSubModelRec.Holdback__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }
    }
    
    public class UnitPriceAndCostWrapper {
    	public Decimal Cost;
        public Decimal Price;
        
        public UnitPriceAndCostWrapper() {
            this.Cost = 0;
            this.Price = 0;
        }
        
        public UnitPriceAndCostWrapper(SObject sobjRec) {
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            if(objectName == Constants.NAMESPACE + 'Unit_Sub_Model__c') {
                this.Cost =  ((sobjRec.get(Constants.NAMESPACE +'Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Cost__c'))) : 0);
                this.Price =  ((sobjRec.get(Constants.NAMESPACE +'Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Price__c'))) : 0);  
            } else if(objectName == Constants.NAMESPACE + 'Unit_Model__c') {
                this.Cost =  ((sobjRec.get(Constants.NAMESPACE +'Default_Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Default_Cost__c'))) : 0);
                this.Price =  ((sobjRec.get(Constants.NAMESPACE +'Default_Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Default_Price__c'))) : 0);  
            } 
        }
    }

    public class UnitSubmodelFilterWrapper {
        public Integer StartIndex;
        public Integer RecordCount;
        public String SearchKeyword;
        public String ModelId;
    }
}
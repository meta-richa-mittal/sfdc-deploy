/**
 * Author: Nidhi Sharma
 * Since: January 04, 2021
 * Name: MakePricingAndOptionWrapper
 * Description: MakePricingAndOptionWrapper
**/
public without sharing class MakePricingAndOptionWrapper {
    public String Id;
    public String MakeName;
    public Integer FactoryOptionCount;
    public List<UnitModelWrapper> ActiveModelList;
    
    public MakePricingAndOptionWrapper(Unit_Make__c unitMakeRec, Integer factoryOptionCount, List<Unit_Model__c> unitModelList) {
        this.Id = unitMakeRec.Id;
        this.MakeName = unitMakeRec.Name;
        this.FactoryOptionCount = factoryOptionCount;
        
        this.ActiveModelList = new List<UnitModelWrapper>();
        for(Unit_Model__c unitModelRec : unitModelList) {
            ActiveModelList.add(new UnitModelWrapper(unitModelRec));
        }
    }
    
    public class UnitModelWrapper {
        public String Id;
        public String ModelName;
        public Integer ActiveSubModelsCount;
        
        public UnitModelWrapper(Unit_Model__c unitModelRec) {
            this.Id = unitModelRec.Id;
            this.ModelName = unitModelRec.Name__c;
            this.ActiveSubModelsCount = unitModelRec.Unit_Sub_Models__r.size();
        }
    }
}
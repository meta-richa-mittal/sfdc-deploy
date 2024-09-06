/**
 * Author: Reena Singh
 * Since: January 15, 2021
 * Name: FactoryOptionModelWrapper
 * Description: FactoryOptionModelWrapper
**/
public without sharing class FactoryOptionModelWrapper {
    public String Id;
    public String ModelName;
    public List<UnitSubModelWrapper> ActiveSubModelList;
    
    public FactoryOptionModelWrapper(Unit_Model__c unitModelRec, List<Unit_Sub_Model__c> unitSubModelList) {
        this.Id = unitModelRec.Id;
        this.ModelName = unitModelRec.Name__c;
        
        this.ActiveSubModelList = new List<UnitSubModelWrapper>{new UnitSubModelWrapper(unitModelRec)};
        for(Unit_Sub_Model__c unitSubModelRec : unitSubModelList) {
            ActiveSubModelList.add(new UnitSubModelWrapper(unitSubModelRec));
        }
    }
    
    public class UnitSubModelWrapper {
        public String Id;
        public String SubModelName;
        public Decimal Cost;
        public Decimal Price;
        public Decimal Holdback;
        public Integer FactoryOptionCount;
        
        public UnitSubModelWrapper(Unit_Sub_Model__c unitSubModelRec) {
            this.Id = unitSubModelRec.Id;
            this.SubModelName = unitSubModelRec.Sub_Model_Name__c;
            this.Cost = unitSubModelRec.Cost__c != null ? unitSubModelRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Price = unitSubModelRec.Price__c != null ? unitSubModelRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Holdback = unitSubModelRec.Holdback__c != null ? unitSubModelRec.Holdback__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.FactoryOptionCount = unitSubModelRec.Submodel_Factory_Option_Junctions__r.size();
        }

        public UnitSubModelWrapper(Unit_Model__c unitModelRec) {
            this.Id = unitModelRec.Id;
            this.SubModelName = 'No sub-model';
            this.Cost = unitModelRec.Default_Cost__c != null ? unitModelRec.Default_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Price = unitModelRec.Default_Price__c != null ? unitModelRec.Default_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Holdback = unitModelRec.Default_Holdback__c != null ? unitModelRec.Default_Holdback__c.setScale(2, RoundingMode.HALF_UP) : 0;
            this.FactoryOptionCount = unitModelRec.Submodel_Factory_Option_Junctions__r.size();
        }
    }
}
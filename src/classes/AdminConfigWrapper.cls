/**
 * Author: Balveer Choudhary
 * Since: Dec 07, 2022
 * Name: AdminConfigWrapper
**/
public without sharing class AdminConfigWrapper {
    
    public class UnitDataFieldConfigWrapper {
        Public String Id;
        public String Name;
        public String DisplayLabel;
    
        public UnitDataFieldConfigWrapper(String recordId, String name, String displayLabel) {
            this.Id = recordId;
            this.Name = Name;
            this.DisplayLabel = displayLabel;
        }
    }
    
    public class FeatueToggleWrapper {
        public String Id;
        public String Name;
        public Boolean IsEnabled;
    
        public FeatueToggleWrapper(Configuration_List__c configRec) {
            if(configRec != null) {
                this.Id = configRec.Id;
                this.Name = configRec.Name;
                this.IsEnabled = String.isNotBlank(configRec.Value__c) ? Boolean.valueOf(configRec.Value__c) : false;   // Currenly supporting only true/false values
            }
        }
    }
}

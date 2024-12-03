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
        public Boolean IsConversionInProgress;
    
        public UnitDataFieldConfigWrapper(String recordId, String name, String displayLabel) {
            this.Id = recordId;
            this.Name = Name;
            this.DisplayLabel = displayLabel;
        }

        public UnitDataFieldConfigWrapper(Unit_Data_Field_Config__c unitDataFieldConfig) {
            this.Id = unitDataFieldConfig.Id;
            this.Name = AdminConfigUtil.unitDataFieldNameMap.get(unitDataFieldConfig.Name);
            this.DisplayLabel = unitDataFieldConfig.Display_Label__c;
            if(unitDataFieldConfig.Field_Conversion_Json__c != null) {
                try {
                    UnitFieldConversionWrapper conversionObj = (UnitFieldConversionWrapper) System.Json.deserialize(unitDataFieldConfig.Field_Conversion_Json__c, UnitFieldConversionWrapper.class);
                    this.IsConversionInProgress = (conversionObj.ConversionJobId != null);
                } catch(Exception e) {
                    system.debug('Exception - ' + e.getMessage());
                    system.debug('unitDataFieldConfig.Field_Conversion_Json__c - ' + unitDataFieldConfig.Field_Conversion_Json__c);
                }
            }
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
    
    public class UnitFieldConversionWrapper {
        public String ConversionJobId;
        public String ConvertToAPIName;
    
        public UnitFieldConversionWrapper(String jobId, String unitfieldAPIName) {
            this.ConversionJobId = jobId;
            this.ConvertToAPIName = unitfieldAPIName;
        }
    }
}
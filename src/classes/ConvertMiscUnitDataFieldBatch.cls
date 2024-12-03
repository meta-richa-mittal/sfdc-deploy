/**
 * Author: Nidhi Sharma
 * Since: October 25, 2024
 * Name: ConvertMiscUnitDataFieldBatch
**/
global without sharing class ConvertMiscUnitDataFieldBatch implements Database.Batchable<SObject> {
    
    private static final string DELIMITER = ';';
    private UnitFieldConversionWrapper conversionObj;
    private Boolean isBatchfailed = false;

    global ConvertMiscUnitDataFieldBatch(UnitFieldConversionWrapper conversionObj) {
        this.conversionObj = conversionObj;

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(Constants.NAMESPACE + 'Customer_Owned_Unit__c');
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        this.conversionObj.MaxLength = fieldMap.get(Constants.NAMESPACE + this.conversionObj.COUFieldApiName) != null ? (fieldMap.get(Constants.NAMESPACE + this.conversionObj.COUFieldApiName)).getDescribe().getLength() : null;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery;
        if(String.isNotBlank(this.conversionObj.UnitDataFieldAPIName) && String.isNotBlank(this.conversionObj.COUFieldApiName)) {
            strQuery = 'SELECT Id, ' + this.conversionObj.UnitDataFieldAPIName + ',' + this.conversionObj.COUFieldApiName + ' FROM Customer_Owned_Unit__c';
        } else {
            strQuery = 'SELECT Id FROM Customer_Owned_Unit__c WHERE Id = null LIMIT 1';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<SObject> sobjList) {
        List<Customer_Owned_Unit__c> couList = (List<Customer_Owned_Unit__c>) sobjList;
        try {
            for(Customer_Owned_Unit__c couRec : couList) {
                if(couRec.get(this.conversionObj.UnitDataFieldAPIName) != null) {
                    String newValue = ((couRec.get(this.conversionObj.COUFieldApiName) != null) ? 
                    String.valueOf(couRec.get(this.conversionObj.COUFieldApiName)) + DELIMITER : '') +
                                    String.valueOf(couRec.get(this.conversionObj.UnitDataFieldAPIName));
                    newValue = newValue.length() > this.conversionObj.MaxLength ? newValue.substring(0, this.conversionObj.MaxLength) : newValue;
                    couRec.put(this.conversionObj.COUFieldApiName, newValue);
                    couRec.put(this.conversionObj.UnitDataFieldAPIName, null);
                }
            }
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couList);
        } catch (Exception e) {
            this.isBatchfailed = true;
            new LogService().createErrorLog('ConvertMiscUnitDataFieldBatch', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                        couList.toString(), 'Conversion tool', true);
        }
    }

    global void finish(Database.batchableContext bc) {
        if(!this.isBatchfailed) {
            updateGEColumnAPINames();
            update new Unit_Data_Field_Config__c(Id = this.conversionObj.UnitDataFieldId, Display_Label__c = null, Field_Conversion_Json__c = null);
        }
    }

    private void updateGEColumnAPINames() {
        List<GE_File_Detail__c> geFileDetailsList = new List<GE_File_Detail__c>();
        try {
            for(GE_File_Detail__c geFileDetailsRec : [SELECT Id, Field_API_Name__c FROM GE_File_Detail__c WHERE Data_Type__c = 'Text']) {
                if(String.isNotBlank(geFileDetailsRec.Field_API_Name__c) && geFileDetailsRec.Field_API_Name__c.equalsIgnoreCase(this.conversionObj.UnitDataFieldAPIName)) {
                    geFileDetailsRec.Field_API_Name__c = this.conversionObj.COUFieldApiName;
                    geFileDetailsList.add(geFileDetailsRec);
                }
            }
            DMLUtility.updateSobjectList('GE_File_Detail__c', geFileDetailsList);
        } catch (Exception e) {
            new LogService().createErrorLog('ConvertMiscUnitDataFieldBatch', 'updateGEColumnAPINames()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                        geFileDetailsList.toString(), 'Conversion tool', true);
        }
    }

    global class UnitFieldConversionWrapper {
        public String UnitDataFieldId;
        public String UnitDataFieldAPIName;
        public String COUFieldApiName;
        public Integer MaxLength;
    }
}
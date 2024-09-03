/**
 * Author: Tarun Khandelwal
 * Since: April 03, 2020
 * Name: GenerateExportFileForStockUnitsBatch
 * Description: Batch class to used to generate Inventory export file
**/
global without sharing class GenerateExportFileForStockUnitsBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts {
    
    public String fileData;
    public String exportType;
    public Integer executeNumber = 0;
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GenerateExportFileForStockUnitsBatch(exportType));
    }
    
    global GenerateExportFileForStockUnitsBatch(String exportType) {
        this.exportType = exportType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        fileData = '';
        String query = 'SELECT VIN_Number__c, Stock_Id__c, Engine_Serial_No__c, Unit_Make__r.Name, Unit_Model__r.Name__c, Sub_Model__r.Sub_Model_Name__c, ' +  
                        'Year__c, Colour__c, Interior_Colour__c, Total_Price__c, Mileage_Value__c, Mileage_Type__c, Notes__c, New_Unit__c, ' + 
                        'Date_Stocked_In__c, LastModifiedDate ';
        
        // 15 Generic fields
        for(Integer i = 1; i <= 15; i++) {
            query += ', Unit_Data_' + (i < 10 ? ('0' + i) : '' + i) + '__c'; 
        }
        query += ' FROM Customer_Owned_Unit__c WHERE Unit_Type__c = \'STOCK\' AND Status__c = \'Available\' AND Publish_in_feeds__c = true ORDER BY Name ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> stockUnitList) {
        try {
            executeNumber++;
            Map<Id, Customer_Owned_Unit__c> stockUnitsMap = new Map<Id, Customer_Owned_Unit__c>(
                        [SELECT Id, (SELECT Public_Image_URL__c FROM Documents__r Order by Is_Primary__c DESC, CreatedDate ASC) 
                            FROM Customer_Owned_Unit__c WHERE Id IN: stockUnitList]);
            
            if(this.exportType == ExportStockUnitUtil.MOTORLOT_EXPORT) {
                fileData += ExportStockUnitUtil.motorlotTypeExport(stockUnitList, stockUnitsMap);
                
            } else if(this.exportType == ExportStockUnitUtil.RV_TRADER_EXPORT) {
                fileData += ExportStockUnitUtil.rvTraderTypeExport(stockUnitList, stockUnitsMap);
                
            } else if(this.exportType == ExportStockUnitUtil.RVT_EXPORT) {
                fileData += ExportStockUnitUtil.rvtTypeExport(stockUnitList, stockUnitsMap);
            } else if(this.exportType == ExportStockUnitUtil.GENERIC_EXPORT) {
                fileData += ExportStockUnitUtil.genericTypeExport(stockUnitList, stockUnitsMap);
            } 
        } catch (Exception e) {
            new LogService().createErrorLog('GenerateExportFileForStockUnitsBatch', 'execute() number ' + executeNumber, e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), null, null, true);
        }
    }
    
    global void finish(Database.batchableContext bc) {
        String header = ExportStockUnitUtil.getHeaders(exportType);
        String attId = ExportStockUnitUtil.createAttachment((header + ExportStockUnitUtil.newLineSeparator + fileData), exportType);
        System.enqueueJob(new FilePostToFTPQueueable(exportType, attId));
    }
}
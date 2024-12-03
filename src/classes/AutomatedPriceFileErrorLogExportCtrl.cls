public without sharing class AutomatedPriceFileErrorLogExportCtrl {
    
    public String fileContent {get; private set;}
    
    public AutomatedPriceFileErrorLogExportCtrl() {
        String query = 'SELECT Error_Field_Name__c, Error_Messages__c, Part_Number__c FROM Price_File_Error_Log__c ';
        if(!GeneralConfiguration.getBooleanValueOfConfigurationByName(GeneralConfiguration.ENABLE_MANUAL_APF)) {
            String summaryLogId = ApexPages.currentPage().getParameters().get('summaryLogId');
            if(String.isNotBlank(summaryLogId)) {
                query += ' WHERE Summary_Log__c =: summaryLogId';
            }
        } else {
            String lastNumber = ApexPages.currentPage().getParameters().get('lastNumber');
            String priceFileMappingId = ApexPages.currentPage().getParameters().get('mappingId');
            query += ' WHERE Vendor__c != null AND CreatedById = \'' + UserInfo.getUserId() + '\'';
            if(String.isNotBlank(lastNumber)) {
                query += ' AND Name >: lastNumber';
            }
            if(String.isNotBlank(priceFileMappingId)) {
                query += ' AND Price_File_Mapping__c =: priceFileMappingId';
            }
        }
        query += ' ORDER BY CreatedDate ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(!AccessControl.ifObjectFieldIsAccessible('Price_File_Error_Log__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        setExportFileData(Database.query(query));
    }
    
    private void setExportFileData(List<Price_File_Error_Log__c> errorLogList) {
        Map<String, Price_File_Error_Log__c> partNumberToErrorLogMap = getPartNoToRecentErrorLogRec(errorLogList);
        fileContent = 'Part#,Field Name,Error Message\n';
        for(Price_File_Error_Log__c errorLogRec : errorLogList) {
            Price_File_Error_Log__c recentErrorLogRec = String.isBlank(errorLogRec.Part_Number__c) ? errorLogRec : partNumberToErrorLogMap.get(errorLogRec.Part_Number__c);
            partNumberToErrorLogMap.remove(errorLogRec.Part_Number__c);

            if(recentErrorLogRec != null) {
                fileContent += (recentErrorLogRec.Part_Number__c != null ? recentErrorLogRec.Part_Number__c.escapeCsv() : '') + ',';
                fileContent += (recentErrorLogRec.Error_Field_Name__c != null ? recentErrorLogRec.Error_Field_Name__c.escapeCsv() : '') + ',';
                fileContent += (recentErrorLogRec.Error_Messages__c != null ? recentErrorLogRec.Error_Messages__c.escapeCsv() : '') + '\n';
            }
        }
    }

    private static Map<String, Price_File_Error_Log__c> getPartNoToRecentErrorLogRec(List<Price_File_Error_Log__c> errorLogList) {
        Map<String, Price_File_Error_Log__c> partNumberToErrorLogMap = new Map<String, Price_File_Error_Log__c>();
        for(Price_File_Error_Log__c errorLogRec : errorLogList) {
            if(String.isNotBlank(errorLogRec.Part_Number__c)) partNumberToErrorLogMap.put(errorLogRec.Part_Number__c, errorLogRec);
        }
        return partNumberToErrorLogMap;
    }
}